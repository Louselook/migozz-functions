# Changes: Mandatory Social Media Validation During Registration

## Summary
Mandatory validation has been added so that users MUST add at least one social media profile during registration. If they don't, they can't:
- ❌ Press the Android/iOS back button
- ❌ Exit the screen
- ❌ Continue to the next step
- ✅ Only friendly validation messages are displayed

---

## Changes Made

### 1. **more_user_details.dart**
#### Added: WillPopScope
```dart
return WillPopScope(
onWillPop: () async {

/ Prevent back navigation in register mode if no social network is added

if (widget.mode == MoreUserDetailsMode.register) {

final registerState = context.read<RegisterCubit>().state;

final socialEcosystem = registerState.socialEcosystem ?? [];

if (socialEcosystem.isEmpty) { 
ScaffoldMessenger.of(context).showSnackBar( 
SnackBar( 
content: Text('addSocials.validation.atLeastOne'.tr()), 
backgroundColor: Colors.orange, 
duration: const Duration(seconds: 2), 
), 
); 
return false; // ← Prevents pop 
} 
} 
return true; 
}, 
child: Scaffold(...)
);
```

**Effect**: When the user presses the system back button (Android/iOS), if no social networks are added:
- The pop-up is prevented
- An orange SnackBar with the validation message is displayed
- The user remains on the screen

**Added Imports**:
- `import 'package:easy_localization/easy_localization.dart';`
- `import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';`

---

### 2. **social_ecosystem_simple_step.dart**
#### Added: WillPopScope to the simple screen
```dart
return WillPopScope(
onWillPop: () async {
// Prevent back navigation if no network is added
final cubit = context.read<RegisterCubit>();
final socialEcosystem = cubit.state.socialEcosystem ?? []; 

if (socialEcosystem.isEmpty) { 
CustomSnackbar.show( 
context: context, 
message: 'addSocials.validation.atLeastOne'.tr(), 
type: SnackbarType.warning, 
); 
return false; // ← Prevents pop 
} 

return true; 
}, 
child: SafeArea( 
top: false, 
child: Scaffold(...) 
),
);
```

**Effect**: Same behavior in the simple social network view

---

### 3. **social_ecosystem_step_v3.dart**
#### Added: WillPopScope to the v3 screen (full view)
```dart
return WillPopScope(
onWillPop: () async {
// If we are in registration mode, validate that there is at least one social network
if (widget.mode == MoreUserDetailsMode.register) {
final socialEcosystem =
context.read<RegisterCubit>().state.socialEcosystem ?? [];

if (socialEcosystem.isEmpty) {
CustomSnackbar.show(
context: context,
message: 'addSocials.validation.atLeastOne'.tr(),
type: SnackbarType.warning,

);
return false; // ← Prevents pop 
} 
} 

return true; 
}, 
child: GestureDetector( 
onTap: () => FocusScope.of(context).unfocus(), 
child: SafeArea(...) 
),
);
```

**Effect**: Validation in the full social media view

---

## Expected Behavior

### When NO social media networks are added:
1. ❌ User presses back button → Displays message "You must add at least one social network"
2. ❌ User tries to continue → Validation is performed, but the user does not continue
3. ❌ User tries to go back within the PageView → The user is prevented from doing so

### When at least one social network IS added:
1. ✅ User presses back button → Functions normally
2. ✅ User presses continue → Advances to the next step (Interests)
3. ✅ User can navigate freely

---

## Validation Flow

```
User on the Social Media screen

↓
Does the user press back or continue without adding networks?

↓
NO → WillPopScope/Validation intervenes
↓
Is there at least 1 social network?

↓ NO → Displays message + Blocks navigation

↓ YES → Allows continue/back
```

---

## Modified Files
1. `more_user_details.dart` - Main container
2. `social_ecosystem_simple_step.dart` - Simple view
3. `social_ecosystem_step_v3.dart` - Full view

---

## Technical Notes
- `WillPopScope` is used to intercept the system's back button
- Validation occurs BEFORE allowing navigation
- Messages are multilingual using `.tr()`
- The SnackBar color is orange (warning) to provide visual feedback