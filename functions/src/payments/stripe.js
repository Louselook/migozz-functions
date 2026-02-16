const admin = require("firebase-admin")
const { onCall, HttpsError, onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require('firebase-functions/params');


const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');
const stripeWebhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');

//Request to create a payment in stripe
exports.createStripePayment = onCall({
    secrets: [stripeSecretKey],
    invoker: 'public'
}, async (request) => {

    try {
        const stripe = require('stripe')(stripeSecretKey.value());
        const amount = request.data.amount * 100

        const paymentIntent = await stripe.paymentIntents.create({
            amount: amount,
            currency: request.data.currency || 'usd',
            automatic_payment_methods: { enabled: true },
            metadata: {
                wallet: request.data.wallet,
                transactionType: request.data.transactionType,
                migozz: request.data.amount
            }
        });

        return {
            clientSecret: paymentIntent.client_secret,
        };
    } catch (error) {
        await admin.firestore().collection("error_tracking").add({
            error: error.message,
            stack: error.stack,
            created: admin.firestore.Timestamp.now(),
            requestData: request.data
        });

        console.error("Error registrado en DB:", error.message);
        throw new HttpsError('internal', error.message);
    }
});

//Webhook for stripes, this help us track the transaction state, so we can confirm it and save de migozz
exports.stripeWebhook = onRequest({
    secrets: [stripeSecretKey, stripeWebhookSecret]
}, async (req, res) => {
    const sig = req.headers["stripe-signature"];
    const wh = stripeWebhookSecret.value();
    const sk = stripeSecretKey.value();
    const stripe = require('stripe')(sk);

    if (!sig || !req.rawBody) {
        console.error("Falta firma o rawBody");
        return res.status(400).send("Faltan datos de Stripe");
    }

    let event;

    try {
        event = stripe.webhooks.constructEvent(req.rawBody, sig, wh);
    } catch (error) {
        await admin.firestore().collection("error_tracking").add({
            source: "Webhook Signature",
            error: error.message,
            created: admin.firestore.Timestamp.now(),
        });
        return res.status(400).send(`Webhook Error: ${error.message}`);
    }

    if (event.type === 'payment_intent.succeeded') {
        const paymentIntent = event.data.object;
        const wallet = paymentIntent.metadata.wallet;
        const amount = parseFloat(paymentIntent.metadata.migozz);

        if (wallet) {
            try {
                const transaction = {
                    id: crypto.randomUUID(),
                    fromName: "Migozz",
                    toName: "You",
                    walletTo: wallet,
                    amount: amount,
                    type: 1,
                    created: admin.firestore.Timestamp.now()
                }

                await admin.firestore().collection('wallets').doc(wallet).collection("transactions").doc(transaction.id).set(transaction);
            
            } catch (error) {
                await admin.firestore().collection("error_tracking").add({
                    source: "Firestore Update",
                    walletId: wallet,
                    error: error.message,
                    created: admin.firestore.Timestamp.now(),
                });
            }
        }
    }

    res.json({ received: true });
});