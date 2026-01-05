# 🔧 Technical Guide: Extending the Context System

For developers who want to add more fields or improvements to the system.


---

## 🏗️ System Architecture

```
┌───────────────────────────────────────────────────────────┐
│ USER INPUT: "Why?" │
└─────────────────────┬──────────────────────────────────────┘
│

▼ 

┌───────────────────────┐ 
│ GeminiService │ 
│ sendMessage() │ 
└─────────┬─────────────┘ 
│ 
▼ 
┌──────────────────────────────────┐ 
│AssistantFunctions│ 
│ evaluateUserResponse() │ 
└──────────┬───────────────────────┘ 
│ 
▼ 
┌────────────────────────────────┐ 
│ _evaluateLocationValue() │ 
│ detects: isWhy = true │ 
└──────────┬─────────────────────┘ 
│ 
▼ 
┌────────────────────────────────┐ 
│ GeminiService sendMessage() │ 
│ check: decision['isWhy'] │ 
└──────────┬─────────────────────┘ 
│ 
▼ 
┌────────────────────────────────┐ 
│ MigozzContext │ 
│ getWhyExplanation() │ 
└──────────┬─────────────────────┘ 
│ 
▼ 
┌────────────────────────────────┐
│ IAChatScreen │

│ Shows explanation │

│ Follow-up question │

└────────────────────────────────┘
```

---

## 📝 Step 1: Add Context

### Location: `lib/core/services/ai/migozz_context.dart`

### Complete Structure
```dart
final Map<String, Map<String, String>> fieldContextES = {
'myNewField': {
'purpose': 'Purpose of the Field',

'why': 'Explanation of why we need it. Minimum 1-2 sentences.',

'benefit': 'Direct benefit to the creator.',

/ Optional fields:

'examples': 'Example 1: ... Example 2: ...',

'security': 'Information about privacy and security',

'psychology': 'Relevant psychological aspects',

'research': 'Supporting data or research',

'brands': 'Brand/company perspective',

'key': 'Critical information if applicable',

}
};
```

### Minimal Example (2 fields)
```dart
'myNewField': {
'purpose': 'My Purpose',
'why': 'Because we need it to...',
'benefit': 'It allows you to...',
}
```

### Full Example (All fields)
```dart
'avatarUrl': {
'purpose': 'Visual Identity',
'why': 'Your photo makes your profile recognizable and trustworthy. Creators with photos receive 3x more leads than those without.',
'benefit': 'Increases leads and opportunities.' A good professional photo communicates that you are serious about your work.',

'examples': 'A profile with a professional photo vs. one without a photo: the former receives 3 times more messages from brands.',

'research': 'Studies show that profiles with photos are seen as more trustworthy and professional.',
}
```

---

## 🔍 Step 2: Detect "Why" Questions

### Option A: Use existing `_isWhyQuestion()` function

In the corresponding evaluation function:

```dart
static Map<String, dynamic> _evaluateMyNewField(
String normalized,
String original,
RegisterCubit cubit, // If needed
) {
final isSpanish = _getIsSpanish(cubit);

// FIRST: Detect why
final isWhy = _isWhyQuestion(normalized, isSpanish);

if (isWhy) { 
return { 
"step": "regProgress.myNewField", 
"valid": false, 
"isWhy": true, 
"field": "myNewField", 
}; 
} 

// AFTER: your normal evaluation logic 
//... 

return { 
"step": "regProgress.myNewField", 
"valid": true, 
"userResponse": original.trim(), 
};
}
```

### Option B: Manual Implementation

``dart
// For simple fields without cubit
final isWhy = 
normalized == 'why' || 
normalized == 'why?' || 
normalized.contains('why ') || 
normalized.contains('why') || 
normalized.contains('what for');
```

---

## ⚙️ Step 3: Integration into GeminiService

### It is not necessary to modify `gemini_service.dart`

The existing code in sendMessage() handles this automatically:

```dart
if (decision['isWhy'] == true) {
final explanation = MigozzContext.getWhyExplanation(fieldKey, language);

return {
"text": explanation,

"options": const <String>[],

"step": 'regProgress.$currentStepKey',

"keepTalk": true,

"explainAndRepeat": true,

};

}
```

---

## 🧪 Step 4: Testing

### Unit Test Example

```dart
test('_isWhyQuestion detects questions in Spanish', () {
expect(_isWhyQuestion('por qué', true), true);
expect(_isWhyQuestion('para qué', true), true);
expect(_isWhyQuestion('mi nombre es juan', true), false);
});

test('_isWhyQuestion detects questions in English', () {
expect(_isWhyQuestion('why do you need', false), true);
expect(_isWhyQuestion('why?', false), true);

expect(_isWhyQuestion('my name is john', false), false);
});

test('MigozzContext returns explanation'correct', () {
final explanation = MigozzContext.getShortExplanation('location', 'is');
expect(explanation.isNotEmpty, true);
expect(explanation.contains('location'), true);

});
```

### Test Manual

1. Open the app
2. Navigate to the field you added
3. Ask: "Why?"

4. Verify that your explanation appears

---

## 📊 Existing Fields with Context

These fields already have full support:

| Field | Location function | Status |

|-------|-------------------|--------|

| fullName | _evaluateFullName | ✅ isWhy detected |

| username | _evaluateUsername | ✅ isWhy detected |

| location | _evaluateLocation | ✅ isWhy detected |

| sendOTP | _evaluateSendOTP | ✅ isWhy detected |

| otpInput | _evaluateOTP | ✅ isWhy detected |

| phone | Does not exist yet | ⏳ Pending |

| voiceNoteUrl | Does not exist yet | ⏳ Pending |

| avatarUrl | Does not exist yet | ⏳ Pending |

| socialEcosystem | Does not exist yet | ⏳ Pending |

---

## 🚀 Complete Example: Adding Context for "Gender"

### Step 1: Adding Context
```dart
// In migozz_context.dart - fieldContextES
'gender': {
'purpose': 'Demographic Information',
'why': 'Gender helps us personalize the experience and recommend relevant collaborations.',
'benefit': 'It allows us to recommend brands and creators with similar interests.',
'examples': 'Women's fashion brands are looking for female influencers; fitness brands look for diversity.', 
'brands': 'Brands use this information to find creators aligned with their target audience.',
}

// In fieldContextEN
'gender': { 
'purpose': 'Demographic Information', 
'why': 'Gender helps us personalize your experience and recommend relevant collaborations.', 
'benefit': 'Allows us to suggest brands and creators aligned with your interests.', 
'examples': 'Fashion brands look for female influencers; fitness brands seek diversity.', 
'brands': 'Brands use this to find creators aligned with their target audience.',
}
```

### Step 2: Improve Evaluation
``dart
static Map<String, dynamic> _evaluateGender( 
String normalized, 
original string,
) { 
// NEW: Detect why 
final isWhy = _isWhyQuestion(normalized, false); 
if (isWhy) { 
return { 
"step": "regProgress.gender", 
"valid": false, 
"isWhy": true, 
"field": "gender", 
}; 
} 

// Existing logic... 
if (normalized == 'male' || normalized == 'male' || normalized == 'man') { 
return { 
"step": "regProgress.gender", 
"valid": true, 
"userResponse": "Male", 
}; 
} 

// ... rest of the options
}
```

### Step 3: Done!
- GeminiService will automatically handle the explanation
- You don't need to change anything else

---

## 🔐 Best Practices

### ✅ DO

1. **Always detect "why" FIRST**
```dart

if (isWhy) return { "isWhy": true, ... };

``````````````````````````````````````````````````
... // After validating a normal response

``

2. **Use clear and accessible language**

- ❌ "We need your location to optimize geolocation"

- ✅ "Your location allows brands in your area to find you"

3. **Provide business context**

- Show how it benefits the creator

- Explain the brand's perspective

- Give real-world examples

4. **Maintain consistent tone**

- Professional but friendly

- Educational but concise

- Spanish/English equivalents

### ❌ DON'T (Do Not Do)

1. **Don't make overly long explanations**

- Max 3-4 sections per explanation

- Each section: 1-2 sentences

2. **Don't mix languages**

- Pure Spanish in the ES version

- Pure English in the EN version

3. **Don't ignore edge cases**

- "Por que" without an accent mark

- "WHY???" with multiple signs

- Question variations

4. **Don't change decision structure**

- Always return `{ "step": "...", "valid": ..., ...}`

- Maintain consistency with other fields

---

## 🐛 Troubleshooting

### Problem: `_isWhyQuestion` not found
**Solution:** Ensure the function is in `assistant_functions.dart` line ~650

### Problem: Explanation not appearing
**Solution:**
1. Verify that fieldKey is correct
2. Verify that context exists in `fieldContextES/EN`
3. Check logs for "isWhy"

### Problem: Incorrect language
**Solution:** Verify that `language` is correctly detected from `registerCubit.state.language`

### Problem: Flow breaks
**Solution:** Ensure `keepTalk: true` and `explainAndRepeat: true` in the response

---

## 📈 Success Metrics

These metrics indicate that the system is working correctly:

```
✅ User asks "why"

↓
✅ System detects isWhy = true

↓
✅ Explanation appears in 2-3 seconds

↓
✅ User sees relevant context

↓
✅ Bot automatically asks follow-up

↓
✅ User completes the field

↓
✅ Registration continues
```

---

## 📚 References

- **Main file:** `lib/core/services/ai/migozz_context.dart`
- **Detection function:** `_isWhyQuestion()` in `assistant_functions.dart`
- **Orchestrator:** `sendMessage()` in `gemini_service.dart`
- **Documentation:** `MIGOZZ_CONTEXT_SYSTEM.md`

---

##💡 Improvement Ideas

### Level 1: Dynamic Context
```dart
// Instead of fixed strings, use user data
final followerCount = registerCubit.state.socialEcosystem['instagram']['followers'];

// Customize explanation: "With ${followerCount} followers..."
```

### Level 2: A/B Testing
```dart
// Test two versions of the explanation
final version = Random().nextBool() ? explanationA : explanationB;

// Measure which one converts better
```

### Level 3: Analytics
```dart
// Track which fields generate the most "why" questions
debugPrint('why_question: $fieldKey');

// Identifies confusing fields
```

---

## 🎯 Conclusion

The system is designed to be:
- **Simple:** Just add strings + detect why
- **Scalable:** Applies to any field
- **Flexible:** Easy to modify explanations
- **Maintainable:** Clean and documented code

For questions, check `MIGOZZ_CONTEXT_SYSTEM.md` or contact the team.

---

**Version:** 1.0
**For developers:** Senior+
**Estimated time to add 1 field:** 5-10 minutes