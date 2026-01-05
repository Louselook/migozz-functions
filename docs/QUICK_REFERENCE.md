# 🎯 Quick Guide: Intelligent Context System

## What's Changed?

Before, when a user asked, "Why do you need my location?", the AI ​​would respond with an error.

**Now**, the AI ​​responds with in-depth context about:
- 💡 Why Migozz needs that information
- 🎯 How it benefits the creator
- 📍 Real-world use cases
- 🏢 Brand/business perspective

---

## How It Works

```
User asks: "Why do you need my location?"

↓
System detects the "WHY" question

↓
Gets context from MigozzContext

↓
Responds with explanation + follow-up question

↓
Flow continues naturally
```

---

## Real Example in Conversation

### Step 1: Bot Asks
```
Bot: "Is your location correct?"
Mountain View, California, United States
[Yes] [No] [Incorrect location]
```

### Step 2: User Asks "Why"
```
User: "Why do you need my location?"
```

### Step 3: Bot Explains (NEW)
```
Bot: 💡 Context about "Geographic Location":

Why?: Brands and companies are looking for creators in your region.

Your location allows people interested in your services to discover you

who are near you.

✅ Benefit: Increases local opportunities. Many businesses prefer to work with creators in their area because it facilitates in-person collaborations and they better understand the local market.

📍 Examples: An agency in Mexico City will look for influencers in Mexico City.

An e-commerce business in Barcelona will look for creators in Catalonia.

🏢 For Brands: Brands ALWAYS look for creators in their region because:
- It facilitates in-person collaborations
- They better understand the local market
- ​​They can find your portfolio

🔑 IMPORTANT: This is critical information for finding you.

``

### Step 4: Bot Follow-up Question
```
Bot: "Now, is your location correct?"

``` [Yes] [No] [Incorrect Location]
```

---

## Fields with Context

✅ **fullName** - Your identity
✅ **username** - Your unique username
✅ **location** - Your region
✅ **phone** - Direct contact
✅ **voiceNoteUrl** - Introduction
✅ **avatarUrl** - Profile picture
✅ **socialEcosystem** - Your networks

---

## For Developers

### Detecting a "Why" Question
```dart
final isWhy = _isWhyQuestion(normalized, isSpanish);

if (isWhy) {

return { "isWhy": true, "field": "location" };

}
```

### Getting the Explanation
```dart
final explanation = MigozzContext.getWhyExplanation('location', 'es');
// Returns the full explanation
```

### Add Explanation for a Field
1. Edit `migozz_context.dart`
2. Add `fieldContextES` or `fieldContextEN` to the map
3. Done, it works automatically

---

## Supported Languages

- 🇪🇸 Spanish
- 🇺🇸 English

Detection is automatic based on `registerCubit.state.language`

---

## New/Modified Files

- ✨ `migozz_context.dart` - NEW (centralized context)
- 📝 `assistant_functions.dart` - Improved (why detection)
- 🔧 `gemini_service.dart` - Improved (why handling)

---

## Use Cases

### ✅ Detects
- "Why?"

- "What for?"

- "Why?" (without accent)
- "Why do you need..."
- "Why is this important?"

### ❌ Doesn't detect (correct)
- "My name is..." (normal response)
- "Yes, that's correct" (confirmation)
- "Another suggestion" (specific request)

---

## Recommended Tests

1. **Question in Spanish:**

- "Why do you need my location?"

- "What do you want my phone for?"

- "Why are you asking for my name?"

2. **Question in English:**

- "Why do you need my phone?"

- "Why is location important?"

3. **Complete Conversation:**

- User asks → Bot explains → User continues registration

---

## Direct Benefits

| For User | For Business | For Development |

|---|---|---|

Understand transparency | Build trust | Scalable code |

Learn about Migozz | Increase conversions | Easy to maintain |

Feel heard | Fewer rejections | Reusable |

---

## FAQ

**Q: Does it work offline?**
A: No, it needs to connect to the Gemini API.

**Q: Can the context be customized?**
A: Yes, edit `MigozzContext` in `migozz_context.dart`.

**Q: How much does it impact performance?**
A: Minimal, it only reads pre-loaded strings.

**Q: Does it work in other languages?**
A: Only ES/EN for now. Adding new ones is easy.

---

**Status: ✅ ACTIVE**
**Version: 1.0**
**Last updated: 2025**