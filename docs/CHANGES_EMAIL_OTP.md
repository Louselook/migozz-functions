# Implementation: Email Change in OTP Registration Flow

## Problem Description
When a user was registering a new account and reached the email confirmation question (`sendOTP`), if they pressed "No," the system only repeated the same question without allowing them to change the email address.


## Solution Implemented

The functionality now works as follows:

1. **User says "Yes"** → OTP is sent to the current email address
2. **User says "No"** → A new email address is requested
3. **User enters new email address** → Confirmation is requested again with the new email address
4. **User confirms new email address** → OTP is sent to the new email address

## Modified Files

### 1. **list_queries.dart**
- ✅ Added new `"emailChange"` question in **Spanish**:
```dart
"emailChange": {
"text": "Please enter your new email address:",
"options": [],
"step": "regProgress.emailChange",
"keepTalk": false,
"keyboardType": "email",

},
```

- ✅ Added new `"emailChange"` question in **English**: 
``dart 
"emailChange": { 
"text": "Please enter your new email address:", 
"options": [], 
"step": "regProgress.emailChange", 
"keepTalk": false, 
"keyboardType": "email", 
}, 
```

### 2. **assistant_functions.dart**
- ✅ Added `'emailChange'` case in `evaluateUserResponse()` method: 
``dart 
case 'emailChange': // NEW: Change email 
return _evaluateEmailChange(normalized, userInput); 
```

- ✅ Created the `_evaluateEmailChange()` function that:

- Validates email format using regular expressions

- Returns `valid: true` if the email is valid

- Returns `valid: false` if it is invalid

### 3. **chat_validation_min.dart**
- ✅ Updated the `RegisterStatusProgress.sendOTP` case:

- If `isValid == true`: Sends OTP normally

- If `isValid == false`: Returns `changeEmail": true` to display the login screen

- ✅ Added a new `RegisterStatusProgress.emailChange` case:

- If `isValid == true`: Saves the new email using `registerCubit.setEmail()`

- Returns `emailChanged": true` to confirm again

- If `isValid == false`: Returns "invalid email" error

- ✅ Updated `_parseStep()` to include mapping of `emailchange`:
```dart

if (raw.contains('emailchange')) return RegisterStatusProgress.emailChange;

``

### 4. **gemini_service.dart**
- ✅ Added special logic in `sendMessage()` after `processBotResponse()`:

**When `changeEmail == true`:**
```dart

if (processResult != null && processResult['changeEmail'] == true) {

return {

"text": "Please enter your new email address:",

"step": "regProgress.emailChange",

"keyboardType": "email",

};

} 
``` 

**When `emailChanged == true`:** 
``dart 
if (processResult != null && processResult['emailChanged'] == true) { 
// Return to sendOTP to confirm new email 
final emailQuestion = AssistantFunctions.getCurrentQuestion( 
questionFlow, 
questionFlow.indexOf('sendOTP'), 
registerCubit, 
); 
return await _prepareQuestion(emailQuestion, registerCubit); 
}
```

### 5. **register_state.dart**
- ✅ Added `emailChange` to the `RegisterStatusProgress` enum:
```dart
enum RegisterStatusProgress {
emty,
language,
fullName,
username,
gender,
socialEcosystem,
location,
sendOTP,
emailChange, // ← NEW
emailVerification,
...

}
```

## Execution Flow

```
1. User is at "sendOTP"

├─ Question: "Your email is {email}. Is that correct?"

├─ Option A: User says "Yes"

│ └─ → Sends OTP → Follows "emailVerification"

│
└─ Option B: User says "No"

└─ → evaluateUserResponse returns valid: false

└─ → processBotResponse returns changeEmail: true

└─ → gemini_service displays "emailChange"

└─ → User enters new email

└─ → _evaluateEmailChange validates email

└─ → processBotResponse saves email with setEmail()

└─ → Returns emailChanged: true

└─ → Displays again "sendOTP" with new email

└─ → User confirms or rejects again
```

## Recommended Tests

1. ✅ **Normal Flow**: User says Yes in sendOTP

- Expected: OTP is sent and proceeds to emailVerification

2. ✅ **Change Email**: User says No, enters a new valid email

- Expected: New email is saved and confirmation is requested again

3. ✅ **Invalid Email**: User enters an invalid format in emailChange

- Expected: Error is displayed and the user is asked to enter again

4. ✅ **Complete Cycle**: User says No, changes email, says Yes

- Expected: OTP is sent to the new email

## Variables Used

- `changeEmail: true` - Flag to indicate email change
- `emailChanged: true` - Flag to indicate that the email was updated
- `currentOTP` - This is retained so it can be sent to the new email address.

## Important Notes

- ✅ Email validation uses regex: `r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'`
- ✅ The flow automatically supports Spanish and English.
- ✅ The new `emailChange` step is NOT in the main flow; it is inserted dynamically.
- ✅ Consistency is maintained with the existing `RegisterCubit`.