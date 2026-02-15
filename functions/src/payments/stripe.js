const admin = require("firebase-admin")
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require('firebase-functions/params');

// 1. Definir el secreto
const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');

// 2. Exportar con el array de secrets
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