const admin = require("firebase-admin")
const { FieldValue } = require("firebase-admin/firestore");
const { onDocumentCreated } = require("firebase-functions/firestore")

/*
    WALLET ESTRUCTURE:
    {
        id: string,
        user: string (userId),
        totalBalance: number,
        totalGains: number,
        totalExpense: number
    }
*/

//We create the wallet for the new users
const asociateWalletToNewUser = onDocumentCreated("/users/{userId}", async (data) => {
    let userId = data.params.userId

    let wallet = {
        id: crypto.randomUUID(),
        user: userId,
        totalBalance: 0,
        totalGains: 0,
        totalExpense: 0
    }

    try {
        await Promise.all([
            admin.firestore().collection("wallets").doc(wallet.id).set(wallet),
            admin.firestore().collection("users").doc(userId).update({
                wallet: wallet.id
            }),
        ])
    } catch (err) {
        admin.firestore().collection("wallets_errors_tracking").add({
            error: err.toString(),
            created: admin.firestore.Timestamp.now()
        })
    }
    return null
})

module.exports = {
    asociateWalletToNewUser
}