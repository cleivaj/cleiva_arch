# Refactorización v2.2 - Código Modular

## 🎯 Objetivo

Simplificar `init.sh` dividiéndolo en módulos limpios y reutilizables.

## 📁 Nueva Estructura

```
arch_installer/
├── init.sh                          # 183 líneas (era 600+)
├── lib/
│   ├── common.sh                    # Logging y utilidades
│   ├── api.sh                       # API de paquetes
│   ├── steps.sh                     # Todos los pasos de instalación
│   └── menus/
│       ├── packages.sh              # Menús de selección de paquetes
│       └── system_config.sh         # Menús de configuración del sistema
├── decide/
│   ├── packages.sh                  # Árbol de decisión de paquetes
│   ├── partition.sh                 # Lógica de particionado
│   └── install.sh                   # Generador de script de instalación
└── detect/
    └── *.sh                         # 11 módulos de detección
```

## 🔧 Módulos Creados

### 1. `lib/steps.sh` (272 líneas)

Contiene todas las funciones de los pasos de instalación:

```bash
step_detect()              # Paso 1: Detección de hardware
step_system_config()       # Paso 2: Configuración del sistema
step_packages()            # Paso 3: Selección de paquetes
step_partition()           # Paso 4: Configuración de particiones
step_validate()            # Paso 5: Validación de paquetes
step_generate()            # Paso 6: Generación de script
view_report()              # Ver reporte
clean_output()             # Limpiar archivos
generate_report()          # Generar reporte Markdown
```

### 2. `lib/menus/system_config.sh` (110 líneas)

Menús de configuración del sistema:

```bash
menu_select_hostname()                   # Selector de hostname
menu_select_keyboard()                   # 12 layouts de teclado
menu_select_locale()                     # 10 locales
menu_select_timezone()                   # 14 zonas horarias
show_system_config_summary()             # Resumen de configuración
```

### 3. `lib/menus/packages.sh` (114 líneas)

Menús de selección de paquetes:

```bash
menu_select_extra_packages()             # Lista de 17 paquetes
add_extra_packages_to_tree()             # Agregar al árbol de decisión
```

## 📊 Comparación de Tamaños

| Archivo | Antes | Después | Reducción |
|---------|-------|---------|-----------|
| `init.sh` | 624 líneas | 183 líneas | **70% menos** |
| Total código | 624 líneas | 679 líneas | Modularizado |

## ✨ Beneficios

### 1. **Mantenibilidad**
- Cada módulo tiene una responsabilidad clara
- Fácil encontrar y modificar funcionalidad
- Pruebas independientes por módulo

### 2. **Reusabilidad**
- Funciones de menú reutilizables
- Steps independientes
- Fácil crear nuevos flujos de trabajo

### 3. **Legibilidad**
- `init.sh` solo contiene lógica de orquestación
- Funciones con nombres descriptivos
- Menos scrolling para encontrar código

### 4. **Escalabilidad**
- Fácil agregar nuevos menús en `lib/menus/`
- Nuevos steps en `lib/steps.sh`
- Sin tocar `init.sh` principal

## 🔄 Migración

### Código Anterior (init.sh monolítico)

```bash
#!/usr/bin/env bash
# 624 líneas...

# step_system_config() aquí (100 líneas)
# step_packages() aquí (150 líneas)
# step_partition() aquí (80 líneas)
# etc...
```

### Código Nuevo (init.sh modular)

```bash
#!/usr/bin/env bash

# Setup básico
source lib/common.sh
source lib/steps.sh

# Banner y utilidades
show_banner() { ... }
main_menu() { ... }
full_auto_install() { ... }

# Main loop
main() { ... }
main "$@"
```

## 🎯 Uso de los Módulos

### Ejemplo 1: Agregar nuevo paquete

Antes: Editar `init.sh` línea 200-400

Ahora:
```bash
# Editar lib/menus/packages.sh
# Agregar línea en menu_select_extra_packages()
# Agregar case en add_extra_packages_to_tree()
```

### Ejemplo 2: Agregar nuevo paso

Antes: Insertar función en medio de `init.sh`

Ahora:
```bash
# Crear step_nuevo() en lib/steps.sh
# Llamar desde full_auto_install() en init.sh
```

### Ejemplo 3: Modificar menú de keyboard

Antes: Buscar en 624 líneas de `init.sh`

Ahora:
```bash
# Editar lib/menus/system_config.sh
# Función menu_select_keyboard() línea 15
```

## 📝 Archivos Modificados

### Nuevos
- ✅ `lib/steps.sh`
- ✅ `lib/menus/packages.sh`
- ✅ `lib/menus/system_config.sh`

### Reemplazados
- ✅ `init.sh` (simplificado 70%)

### Sin cambios
- ✅ `lib/common.sh`
- ✅ `lib/api.sh`
- ✅ `decide/*.sh`
- ✅ `detect/*.sh`
- ✅ `main.sh`

## 🧪 Testing

```bash
./test_interactive.sh
# ✓ All Tests Passed!
# ✓ 39 packages in Hyprland profile
# ✓ Detection works
# ✓ Partition generation works
```

## 🚀 Próximas Mejoras

### Posibles módulos adicionales:

```
lib/menus/
├── system_config.sh     # ✅ Implementado
├── packages.sh          # ✅ Implementado
├── partitions.sh        # 🔜 Menú avanzado de particiones
├── users.sh             # 🔜 Creación de usuarios
└── services.sh          # 🔜 Selección de servicios

lib/
├── steps.sh             # ✅ Implementado
├── validation.sh        # 🔜 Validaciones complejas
└── postinstall.sh       # 🔜 Helpers post-instalación
```

## 📖 Guía de Estilo

### Nombres de Funciones

```bash
# Menús (retornan selección)
menu_select_*()          # Muestra menú, retorna valor

# Steps (ejecutan acción completa)
step_*()                 # Paso de instalación completo

# Utilidades (operaciones internas)
generate_*()             # Genera archivos
validate_*()             # Valida datos
show_*()                 # Muestra información
```

### Ubicación de Código

```bash
# UI/Menús → lib/menus/
# Lógica de steps → lib/steps.sh
# Utilidades generales → lib/common.sh
# API externa → lib/api.sh
# Decisiones → decide/
# Detección → detect/
```

## 💡 Ejemplos de Uso

### Crear un nuevo menú personalizado

```bash
# 1. Crear lib/menus/mi_menu.sh
#!/usr/bin/env bash

menu_select_mi_opcion() {
    local choice
    choice=$(whiptail --title "Mi Menú" \
        --menu "Selecciona:" 15 60 5 \
        "opt1" "Opción 1" \
        "opt2" "Opción 2" \
        3>&1 1>&2 2>&3)
    echo "$choice"
}

# 2. Usar en step (lib/steps.sh)
step_mi_nuevo_paso() {
    source lib/menus/mi_menu.sh
    local sel=$(menu_select_mi_opcion)
    # ... procesar selección
}

# 3. Llamar desde init.sh
case "$choice" in
    10) step_mi_nuevo_paso ;;
esac
```

## 🎉 Resumen

**Antes:**
- ❌ Archivo monolítico de 624 líneas
- ❌ Difícil navegar y mantener
- ❌ Todo mezclado

**Ahora:**
- ✅ Módulos separados por responsabilidad
- ✅ init.sh limpio (183 líneas)
- ✅ Fácil agregar funcionalidad
- ✅ Código más legible y mantenible

**Resultado:**
- 🎯 Mismo comportamiento
- 📦 Mejor organización
- 🚀 Más escalable
- 🧹 Código más limpio
