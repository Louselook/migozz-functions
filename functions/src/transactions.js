const admin = require("firebase-admin")
const { FieldValue } = require("firebase-admin/firestore");
const { onDocumentCreated } = require("firebase-functions/firestore")

/*TRANSACTION CONTROLLER*/
/*
    Depending on the created transaction type we Increment the gains or expenses in the wallet
    The "Increment" FieldValue is perfect for the case because it orders multiple requests and doesn't make calculation mistakes
*/

const transactionsController = onDocumentCreated('/wallets/{walletId}/transactions/{transactionId}', async(data) => {
    let transaction = data.data.data()
    let updates = {}
    const createdAt = transaction.created.toDate();
    const dayId = `${createdAt.getFullYear()}-${String(createdAt.getMonth() + 1).padStart(2, '0')}-${String(createdAt.getDate()).padStart(2, '0')}`;
    let isGain = false
    let dayUpdates = {}

    try {
        switch (transaction.type) {
            case 1:
                updates = {
                    totalBalance: FieldValue.increment(transaction.amount),
                    totalGains: FieldValue.increment(transaction.amount)
                }

                isGain = true
            break;

            case 2:
            case 3:
                updates = {
                    totalBalance: FieldValue.increment(-transaction.amount),
                    totalExpense: FieldValue.increment(transaction.amount)
                }
                isGain = false
            break;
        }

        await admin.firestore().collection("wallets").doc(transaction.walletTo).update(updates)

        if (isGain) {
            dayUpdates = {
                totalGains: FieldValue.increment(transaction.amount),
                lastUpdate: admin.firestore.Timestamp.now()
            };
        }

        await admin.firestore().collection("wallets").doc(transaction.walletTo).collection("record").doc(dayId).set(dayUpdates, { merge: true });

    } catch (err) {
        admin.firestore().collection("transactions_errors_tracking").add({
            error: err.toString(),
            created: admin.firestore.Timestamp.now()
        })
    }
    return
})

module.exports = {
    transactionsController
}