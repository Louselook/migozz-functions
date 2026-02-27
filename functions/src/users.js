const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");

initializeApp();

const generateTokens = (data, userId) => {
    const indexSet = new Set();
    const addTokens = (text) => {
        if (!text || typeof text !== 'string') return;
        const clean = text.toLowerCase().trim();
        
        for (let i = 1; i <= clean.length; i++) {
            indexSet.add(clean.substring(0, i));
        }

        const words = clean.split(/[\s@.]+/);
        words.forEach(word => {
            for (let i = 1; i <= word.length; i++) {
                indexSet.add(word.substring(0, i));
            }
        });
    };

    addTokens(data.displayName);
    addTokens(data.email);
    addTokens(userId);

    return Array.from(indexSet);
};

exports.createSearchQueryForNewUser = onDocumentCreated("users/{userId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return null;

    const userId = event.params.userId;
    const data = snapshot.data();
    const querySearch = generateTokens(data, userId);

    return snapshot.ref.set({ querySearch }, { merge: true });
});


exports.createSearchQueryOnUserUpdated = onDocumentUpdated("users/{userId}", async (event) => {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();

    if (newData.displayName === oldData.displayName && 
        newData.email === oldData.email && 
        newData.querySearch) {
        return null;
    }

    const userId = event.params.userId;
    const querySearch = generateTokens(newData, userId);

    return event.data.after.ref.set({ querySearch }, { merge: true });
});