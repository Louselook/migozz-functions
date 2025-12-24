# Cambios: Validación Obligatoria de Redes Sociales en Registro

## Resumen
Se agregó validación obligatoria para que los usuarios DEBEN agregar al menos una red social durante el registro. Si no lo hacen, no pueden:
- ❌ Presionar el botón atrás de Android/iOS
- ❌ Salir de la pantalla
- ❌ Continuar al siguiente paso
- ✅ Solo se muestran mensajes de validación amigables

---

## Cambios Realizados

### 1. **more_user_details.dart**
#### Añadido: WillPopScope
```dart
return WillPopScope(
  onWillPop: () async {
    // Prevent back navigation in register mode if no social network is added
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
        return false;  // ← Previene el pop
      }
    }
    return true;
  },
  child: Scaffold(...)
);
```

**Efecto**: Cuando el usuario presiona el botón atrás del sistema (Android/iOS), si no hay redes sociales agregadas:
- El pop se previene
- Se muestra un SnackBar naranja con el mensaje de validación
- El usuario se mantiene en la pantalla

**Importaciones agregadas**:
- `import 'package:easy_localization/easy_localization.dart';`
- `import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';`

---

### 2. **social_ecosystem_simple_step.dart**
#### Añadido: WillPopScope a la pantalla simple
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
      return false;  // ← Previene el pop
    }

    return true;
  },
  child: SafeArea(
    top: false,
    child: Scaffold(...)
  ),
);
```

**Efecto**: Mismo comportamiento en la vista simple de redes sociales

---

### 3. **social_ecosystem_step_v3.dart**
#### Añadido: WillPopScope a la pantalla v3 (vista completa)
```dart
return WillPopScope(
  onWillPop: () async {
    // Si estamos en modo registro, validar que haya al menos una red social
    if (widget.mode == MoreUserDetailsMode.register) {
      final socialEcosystem =
          context.read<RegisterCubit>().state.socialEcosystem ?? [];

      if (socialEcosystem.isEmpty) {
        CustomSnackbar.show(
          context: context,
          message: 'addSocials.validation.atLeastOne'.tr(),
          type: SnackbarType.warning,
        );
        return false;  // ← Previene el pop
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

**Efecto**: Validación en la vista completa de redes sociales

---

## Comportamiento Esperado

### Cuando NO hay redes sociales agregadas:
1. ❌ Usuario presiona botón atrás → Muestra mensaje "Debes agregar al menos una red social"
2. ❌ Usuario intenta continuar → Se valida y no continúa
3. ❌ Usuario intenta hacer back en el PageView → Se previene

### Cuando SÍ hay al menos una red social:
1. ✅ Usuario presiona botón atrás → Funciona normalmente
2. ✅ Usuario presiona continuar → Avanza al siguiente paso (Intereses)
3. ✅ Usuario puede navegar libremente

---

## Flujo de Validación

```
Usuario en pantalla de Redes Sociales
    ↓
¿Presiona atrás o continúa sin agregar redes?
    ↓
    NO → WillPopScope/Validación interviene
    ↓
    ¿Hay al menos 1 red social?
    ↓
    NO → Muestra mensaje + Bloquea navegación
    ↓
    SÍ → Permite continuar/volver
```

---

## Archivos Modificados
1. `more_user_details.dart` - Container principal
2. `social_ecosystem_simple_step.dart` - Vista simple
3. `social_ecosystem_step_v3.dart` - Vista completa

---

## Notas Técnicas
- Se usa `WillPopScope` para interceptar el botón atrás del sistema
- La validación ocurre ANTES de permitir la navegación
- Los mensajes son multilengua usando `.tr()`
- El color del SnackBar es naranja (warning) para dar feedback visual
