# English
# Modchart System - Complete Documentation

## 📚 Index
1. [Event System](#event-system)
2. [Modchart Functions](#modchart-functions)
3. [Practical Examples](#practical-examples)

---

## Event System

### **What is an Event?**

An **event** is a scheduled action that is executed automatically when the song reaches a specific beat. The system manages these events through the `EventManager`, which:

1. **Organizes events by name and player** - Uses a HashMap for fast lookup
2. **Sorts events by beat** - Guarantees execution in the correct order
3. **Updates every frame** - Compares the current beat with pending events
4. **Executes callbacks** - When `curBeat >= event.beat`

### **Available Event Types**

#### **1. SetEvent** - Instant Change
```lua
set('reverse', 32, 1, 0, -1)
```
- **What it does:** Sets a modifier's value instantly
- **When it runs:** Exactly at the specified beat
- **Typical use:** Abrupt changes, resets, instant transitions

**Internal functioning:**
```haxe
// When curBeat >= beat:
setModPercent(name, target, player); // Assigns the value directly
fired = true; // Marks as executed (does not repeat)
```

#### **2. EaseEvent** - Smooth Transition
```lua
ease('drunk', 16, 8, 0.5, 'cubeInOut', 0, -1)
```
- **What it does:** Interpolates gradually from the current value to the target
- **When it runs:** Continuously from `beat` until `beat + length`
- **Typical use:** Smooth transitions, fluid animations

**Internal functioning:**
```haxe
// Each frame while curBeat < endBeat:
var progress = (curBeat - startBeat) / beatLength; // 0.0 to 1.0
var easedProgress = easeFunction(progress); // Applies easing curve
var value = lerp(startValue, targetValue, easedProgress);
setModPercent(name, value, player);
```

**Special characteristics:**
- Gets the previous value from the last event (prevents visual jumps)
- If the previous event was an Ease, uses its easing function to calculate the final value
- `mercy = true` - Executes every frame, not just once

#### **3. AddEvent** - Gradual Addition
```lua
add('drunk', 48, 8, 0.25, 'linear', 0, -1)
```
- **What it does:** ADDS a value to the current percentage, does not replace it
- **When it runs:** Continuously from `beat` until `beat + length`
- **Typical use:** Accumulating effects, intensifying modifiers

**Difference from Ease:**
```lua
-- If drunk is at 50%:
ease('drunk', 0, 4, 0.75, 'linear', 0, -1) -- Goes from 50% to 75% (replaces)
add('drunk', 0, 4, 0.25, 'linear', 0, -1)  -- Goes from 50% to 75% (50% + 25% = 75%)
```

#### **4. RepeaterEvent** - Continuous Execution
```lua
repeater(80, 16, 'myRepeaterFunc', -1)

function myRepeaterFunc()
    -- This code runs EVERY FRAME
    local beat = (getSongPosition() / 1000) / (60 / bpm) * 4
    debugPrint('Beat: ' .. beat)
end
```
- **What it does:** Executes a function repeatedly every frame
- **When it runs:** Each frame while `beat <= curBeat < beat + length`
- **Typical use:** Real-time based effects, complex animations

**Characteristics:**
- `fired = false` after each execution (stays active)
- Useful for audio sync or creating complex patterns

#### **5. CallbackEvent** - Single Execution
```lua
callback(64, 'myCallbackFunc', -1)

function myCallbackFunc()
    debugPrint('We reached beat 64!')
    setPercent('tipsy', 0.75, 0, -1)
end
```
- **What it does:** Executes a function ONLY ONCE
- **When it runs:** Exactly when `curBeat >= beat`
- **Typical use:** Triggers, specific changes, logs

---

## Modchart Functions

```lua
-- Everything must be inside this function to work correctly
function onInitModchart()

    -- ============================================
    -- [Modifiers Section] - Modifier Management
    -- ============================================

    -- Searches for and adds a modifier by name
    -- mod:String   Name of the modifier (e.g., 'drunk', 'reverse', 'tipsy')
    -- field:Int    Playfield number (-1 = all, 0 = player, 1 = opponent)
    addModifier(mod, field);

    -- Sets a modifier's percentage immediately (without events)
    -- mod:String   Name of the modifier
    -- value:Float  Value to assign (0.0 = 0%, 1.0 = 100%)
    -- player:Int   Target player (-1 = all)
    -- field:Int    Target playfield (-1 = all)
    setPercent(mod, value, player, field);

    -- Gets the current percentage of a modifier
    -- mod:String   Name of the modifier
    -- player:Int   Player to query (default 0)
    -- field:Int    Playfield to query (default 0)
    -- returns: Float (the modifier's current value)
    local currentValue = getPercent(mod, player, field);

    -- Registers a new custom modifier (Haxe only)
    -- modN:String  Name of the new modifier
    -- mod:Modifier Instance of the Modifier class (only from Haxe)
    registerModifier(modN, mod);

    -- ============================================
    -- [Events Section] - Event System
    -- ============================================

    -- SET: Sets a value instantly on a specific beat
    -- mod:String   Name of the modifier
    -- beat:Float   Beat where it will execute (e.g., 32.0, 64.5)
    -- value:Float  Target value (typically 0.0 to 1.0)
    -- player:Int   Target player (-1 = all, 0 = player, 1 = opponent)
    -- field:Int    Target playfield (-1 = all)
    set(mod, beat, value, player, field);

    -- EASE: Smoothly interpolates from current value to target value
    -- mod:String   Name of the modifier
    -- beat:Float   Start beat
    -- length:Float Duration in beats (e.g., 4.0 = 4 beats)
    -- value:Float  Final target value
    -- ease:String  Easing function ('linear', 'cubeInOut', 'backOut', etc.)
    -- player:Int   Target player (-1 = all)
    -- field:Int    Target playfield (-1 = all)
    ease(mod, beat, length, value, ease, player, field);

    -- ADD: Adds a value gradually (accumulates, does not replace)
    -- Parameters identical to ease()
    -- Difference: If drunk = 50%, add(..., 25%) will reach 75% (50% + 25%)
    --            while ease() would go directly to 25%
    add(mod, beat, length, value, ease, player, field);

    -- SETADD: Sets value + addition on a specific beat
    -- Combines set() with addition: sets (currentValue + value)
    -- mod:String   Name of the modifier
    -- beat:Float   Beat where it will execute
    -- value:Float  Value to ADD to the current one
    -- player:Int   Target player (-1 = all)
    -- field:Int    Target playfield (-1 = all)
    setAdd(mod, beat, value, player, field);

    -- CALLBACK: Executes a function ONCE on a specific beat
    -- beat:Float     Beat where it will execute
    -- funcName:String Name of the Lua function to call (as a string)
    -- field:Int      Target playfield (-1 = all)
    callback(beat, 'myCallbackFunction', field);

    -- REPEATER: Executes a function EVERY FRAME for a period
    -- beat:Float      Start beat
    -- length:Float    Duration in beats
    -- funcName:String Name of the Lua function to call (as a string)
    -- field:Int       Target playfield (-1 = all)
    repeater(beat, length, 'myRepeaterFunction', field);

    -- ============================================
    -- [Playfield Section] - Playfield Management
    -- ============================================
    
    -- Adds a new playfield (additional game field)
    -- WARNING: If you add a playfield AFTER adding modifiers,
    -- you will have to add the modifiers again to the new playfield
    addPlayfield();

    -- ============================================
    -- [Alias Section] - Alternate Names
    -- ============================================
    
    -- Creates an alias (alternate name) for a modifier
    -- name:String      Original modifier name
    -- aliasName:String Alternate name/alias
    -- field:Int        Target playfield
    alias(name, aliasName, field);

    -- ============================================
    -- [Constants] - Useful Constants
    -- ============================================
    
    -- Hold note size
    local holdSize = getHoldSize();        -- Full size
    local holdSizeDiv2 = getHoldSizeDiv2(); -- Size / 2

    -- Arrow size
    local arrowSize = getArrowSize();       -- Full size (160)
    local arrowSizeDiv2 = getArrowSizeDiv2(); -- Size / 2 (80)
end
```

---

## Path Modifiers (PathModifier / luapath)

These helpers let you drive any modifier that extends `PathModifier` (recommended: `luapath`) by providing a custom path from Lua.

### Functions

```lua
setModifierPath(modName, nodes, field)
setModifierPathOffset(modName, x, y, z, field)
setModifierPathBound(modName, bound, field)
```

### How to use the variables

- `nodes`: An array of points that define the path. Each point can be a table like `{x=..., y=..., z=...}` (or an array like `{x, y, z}`). These points are relative offsets from `pathOffset`.
- `pathOffset` (via `setModifierPathOffset`): The world-space origin of the path. Usually you want this at the screen center so the path is centered.
- `pathBound` (via `setModifierPathBound`): The distance range that maps to one full traversal of the path. Larger values spread notes/receptors over more distance (less bunching). Smaller values pack them closer.

### Minimal example

```lua
function onInitModchart()
    addModifier('luapath', 0)

    -- Bigger bound = less bunching
    setModifierPathBound('luapath', 7000, 0)

    -- Center the path (z is optional)
    setModifierPathOffset('luapath', screenWidth * 0.5, screenHeight * 0.5, 0, 0)

    local nodes = {
        {x = 0,    y = 0,   z = 0},
        {x = 200,  y = -80, z = 40},
        {x = -200, y = -80, z = 80},
    }
    setModifierPath('luapath', nodes, 0)

    -- 0 = off, 1 = full effect
    setPercent('luapath', 1, -1, 0)
end
```

---

## Practical Examples

### **Example 1: Basic Modchart**
```lua
function onInitModchart()
    -- Add modifiers we'll use
    addModifier('reverse', -1)
    addModifier('drunk', -1)
    addModifier('tipsy', -1)
    
    -- Beat 0-16: No effects
    
    -- Beat 16: Activate reverse instantly
    set('reverse', 16, 1, 0, -1) -- Only player
    
    -- Beat 32-48: Drunk gradually increases
    ease('drunk', 32, 16, 0.5, 'cubeInOut', -1, -1) -- Both players
    
    -- Beat 64: Reset everything
    callback(64, 'resetModchart', -1)
end

function resetModchart()
    debugPrint('Resetting modchart!')
    setPercent('reverse', 0, -1, -1)
    setPercent('drunk', 0, -1, -1)
end
```

### **Example 2: Cumulative Effects**
```lua
function onInitModchart()
    addModifier('invert', -1)
    
    -- Every 16 beats, increase invert by 10%
    set('invert', 16, 0.1, -1, -1)      -- 10%
    setAdd('invert', 32, 0.1, -1, -1)   -- 10% + 10% = 20%
    setAdd('invert', 48, 0.1, -1, -1)   -- 20% + 10% = 30%
    setAdd('invert', 64, 0.1, -1, -1)   -- 30% + 10% = 40%
end
```

### **Example 3: Repeater for Pulsing Effects**
```lua
local bpm = 140

function onInitModchart()
    addModifier('zoom', -1)
    
    -- Pulse effect from beat 32 to 64
    repeater(32, 32, 'pulseEffect', -1)
end

function pulseEffect()
    -- Calculate current beat with decimals
    local beat = (getSongPosition() / 1000) / (60 / bpm) * 4
    local beatFraction = beat % 1 -- 0.0 to 1.0 within the beat
    
    -- Pulse to the rhythm: larger at start of beat, smaller at end
    local pulseAmount = 1.0 - beatFraction
    setPercent('zoom', pulseAmount * 0.2, -1, -1) -- Maximum 20% zoom
end
```

### **Example 4: Callback for Drastic Changes**
```lua
function onInitModchart()
    addModifier('reverse', -1)
    addModifier('flip', -1)
    addModifier('invert', -1)
    
    -- Prepare smooth effects
    ease('reverse', 0, 32, 0.5, 'linear', 0, -1)
    
    -- At beat 32: Drastic change
    callback(32, 'dropEffect', -1)
    
    -- Reset at beat 64
    callback(64, 'resetAll', -1)
end

function dropEffect()
    debugPrint('DROP!')
    -- Activate multiple effects instantly
    setPercent('flip', 1, -1, -1)
    setPercent('invert', 1, -1, -1)
    setPercent('reverse', 1, -1, -1)
end

function resetAll()
    setPercent('flip', 0, -1, -1)
    setPercent('invert', 0, -1, -1)
    setPercent('reverse', 0, -1, -1)
end
```

### **Example 5: Different Effects per Player**
```lua
function onInitModchart()
    addModifier('drunk', -1)
    addModifier('reverse', -1)
    
    -- Player (0): Drunk grows
    ease('drunk', 16, 16, 0.8, 'cubeOut', 0, -1)
    
    -- Opponent (1): Reverse active
    set('reverse', 16, 1, 1, -1)
    
    -- Beat 48: Swap effects
    ease('drunk', 48, 8, 0, 'cubeIn', 0, -1)      -- Player loses drunk
    ease('drunk', 48, 8, 0.8, 'cubeOut', 1, -1)   -- Opponent gains drunk
    set('reverse', 48, 0, 1, -1)                   -- Opponent loses reverse
    set('reverse', 48, 1, 0, -1)                   -- Player gains reverse
end
```

---

## 🔧 Available Easing Functions

You can use these strings in `ease()` and `add()`:

**Smooth:**
- `'linear'` - No easing, constant speed
- `'smoothStepIn'` / `'smoothStepOut'` / `'smoothStepInOut'`
- `'smootherStepIn'` / `'smootherStepOut'` / `'smootherStepInOut'`

**Quadratic:**
- `'quadIn'` / `'quadOut'` / `'quadInOut'`
- `'cubeIn'` / `'cubeOut'` / `'cubeInOut'`
- `'quartIn'` / `'quartOut'` / `'quartInOut'`
- `'quintIn'` / `'quintOut'` / `'quintInOut'`

**Special:**
- `'sineIn'` / `'sineOut'` / `'sineInOut'` - Sinusoidal movement
- `'circIn'` / `'circOut'` / `'circInOut'` - Circular
- `'expoIn'` / `'expoOut'` / `'expoInOut'` - Exponential
- `'backIn'` / `'backOut'` / `'backInOut'` - Overshoots and returns
- `'bounceIn'` / `'bounceOut'` / `'bounceInOut'` - Bounce
- `'elasticIn'` / `'elasticOut'` / `'elasticInOut'` - Elastic

---

## ⚠️ Important Notes

1. **`player` vs `field`:**
   - `player`: Player/Strumline (0 = player, 1 = opponent, -1 = all)
   - `field`: Playfield/Game field (normally -1 unless using multiple playfields)

2. **Event timing:**
   - Events are evaluated each frame based on `Conductor.songPosition`
   - Beats are floats: `32.5` is valid (half of beat 32)

3. **Execution order:**
   - `onInitModchart()` is called BEFORE the song starts
   - Events are automatically sorted by beat
   - Multiple events on the same beat execute in creation order

4. **Performance:**
   - `repeater` runs every frame, use with care
   - `callback` runs once and is cleaned up automatically
   - `ease` and `add` events only calculate while active

---

## 🎯 Tips and Tricks

**1. Use callbacks for debugging:**
```lua
callback(32, 'debugBeat32', -1)
function debugBeat32(event)
    debugPrint('Drunk state: ' .. getPercent('drunk', 0, -1))
end
```

**2. Combine ease with different players:**
```lua
-- Mirror effect: one goes up while the other goes down
ease('drunk', 16, 16, 0.8, 'cubeInOut', 0, -1)
ease('drunk', 16, 16, 0, 'cubeInOut', 1, -1)
```

**3. Use repeater for perfect sync:**
```lua
repeater(0, 999, 'beatSync', -1) -- For the entire song
function beatSync()
    local pos = getSongPosition() / 1000
    local beat = pos / (60 / bpm) * 4
    if beat % 4 < 0.1 then -- Every 4 beats
        setPercent('zoom', 0.2, -1, -1)
    else
        setPercent('zoom', 0, -1, -1)
    end
end
```

**4. Typical modifier values:**
- `0.0` = Disabled (0%)
- `0.5` = Medium effect (50%)
- `1.0` = Full effect (100%)
- Some modifiers accept negative values or >1.0

---

## 🚨 Common Errors

1. **"Manager.instance is null"**
   - Cause: Modcharting disabled in options
   - Solution: Enable "Modcharting" in ClientPrefs

2. **Events don't execute**
   - Cause: They are not inside `onInitModchart()`
   - Solution: Place all events inside the function

3. **Callback doesn't work**
   - Cause: Function name as string is incorrect
   - Solution: `callback(32, 'myFunc', -1)` with quotes

4. **Modifier doesn't exist**
   - Cause: You didn't add the modifier with `addModifier()`
   - Solution: Always use `addModifier()` before using the modifier

---

**Last updated:** October 2025 | **Version:** Plus Engine 1.0

# Español
# Sistema de Modchart - Documentación Completa

## 📚 Índice
1. [Sistema de Eventos](#sistema-de-eventos)
2. [Funciones de Modchart](#funciones-de-modchart)
3. [Ejemplos Prácticos](#ejemplos-prácticos)

---

## Sistema de Eventos

### **¿Qué es un Evento?**

Un **evento** es una acción programada que se ejecuta automáticamente cuando la canción alcanza un beat específico. El sistema gestiona estos eventos a través del `EventManager`, que:

1. **Organiza eventos por nombre y jugador** - Usa un HashMap para búsqueda rápida
2. **Ordena eventos por beat** - Garantiza ejecución en orden correcto
3. **Actualiza cada frame** - Compara el beat actual con los eventos pendientes
4. **Ejecuta callbacks** - Cuando `curBeat >= event.beat`

### **Tipos de Eventos Disponibles**

#### **1. SetEvent** - Cambio Instantáneo
```lua
set('reverse', 32, 1, 0, -1)
```
- **Qué hace:** Establece el valor de un modificador instantáneamente
- **Cuándo se ejecuta:** Exactamente en el beat especificado
- **Uso típico:** Cambios abruptos, resets, transiciones instantáneas

**Funcionamiento interno:**
```haxe
// Cuando curBeat >= beat:
setModPercent(name, target, player); // Asigna el valor directamente
fired = true; // Marca como ejecutado (no se repite)
```

#### **2. EaseEvent** - Transición Suave
```lua
ease('drunk', 16, 8, 0.5, 'cubeInOut', 0, -1)
```
- **Qué hace:** Interpola gradualmente desde el valor actual hasta el objetivo
- **Cuándo se ejecuta:** Continuamente desde `beat` hasta `beat + length`
- **Uso típico:** Transiciones suaves, animaciones fluidas

**Funcionamiento interno:**
```haxe
// Cada frame mientras curBeat < endBeat:
var progress = (curBeat - startBeat) / beatLength; // 0.0 a 1.0
var easedProgress = easeFunction(progress); // Aplica curva de easing
var value = lerp(startValue, targetValue, easedProgress);
setModPercent(name, value, player);
```

**Características especiales:**
- Obtiene el valor previo del último evento (evita saltos visuales)
- Si el evento anterior era un Ease, usa su función de easing para calcular el valor final
- `mercy = true` - Se ejecuta cada frame, no solo una vez

#### **3. AddEvent** - Suma Gradual
```lua
add('drunk', 48, 8, 0.25, 'linear', 0, -1)
```
- **Qué hace:** SUMA un valor al porcentaje actual, no lo reemplaza
- **Cuándo se ejecuta:** Continuamente desde `beat` hasta `beat + length`
- **Uso típico:** Acumular efectos, intensificar modificadores

**Diferencia con Ease:**
```lua
-- Si drunk está en 50%:
ease('drunk', 0, 4, 0.75, 'linear', 0, -1) -- Va de 50% a 75% (reemplaza)
add('drunk', 0, 4, 0.25, 'linear', 0, -1)  -- Va de 50% a 75% (50% + 25% = 75%)
```

#### **4. RepeaterEvent** - Ejecución Continua
```lua
repeater(80, 16, 'myRepeaterFunc', -1)

function myRepeaterFunc()
    -- Este código se ejecuta CADA FRAME
    local beat = (getSongPosition() / 1000) / (60 / bpm) * 4
    debugPrint('Beat: ' .. beat)
end
```
- **Qué hace:** Ejecuta una función repetidamente cada frame
- **Cuándo se ejecuta:** Cada frame mientras `beat <= curBeat < beat + length`
- **Uso típico:** Efectos basados en tiempo real, animaciones complejas

**Características:**
- `fired = false` después de cada ejecución (se mantiene activo)
- Útil para sincronizar con audio o crear patrones complejos

#### **5. CallbackEvent** - Ejecución Única
```lua
callback(64, 'myCallbackFunc', -1)

function myCallbackFunc()
    debugPrint('¡Llegamos al beat 64!')
    setPercent('tipsy', 0.75, 0, -1)
end
```
- **Qué hace:** Ejecuta una función UNA SOLA VEZ
- **Cuándo se ejecuta:** Exactamente cuando `curBeat >= beat`
- **Uso típico:** Triggers, cambios puntuales, logs

---

## Funciones de Modchart

```lua
-- Todo debe estar dentro de esta función para funcionar correctamente
function onInitModchart()

    -- ============================================
    -- [Modifiers Section] - Gestión de Modificadores
    -- ============================================

    -- Busca y agrega un modificador por nombre
    -- mod:String   Nombre del modificador (ej: 'drunk', 'reverse', 'tipsy')
    -- field:Int    Número del playfield (-1 = todos, 0 = jugador, 1 = oponente)
    addModifier(mod, field);

    -- Establece el porcentaje de un modificador inmediatamente (sin eventos)
    -- mod:String   Nombre del modificador
    -- value:Float  Valor a asignar (0.0 = 0%, 1.0 = 100%)
    -- player:Int   Jugador objetivo (-1 = todos)
    -- field:Int    Playfield objetivo (-1 = todos)
    setPercent(mod, value, player, field);

    -- Obtiene el porcentaje actual de un modificador
    -- mod:String   Nombre del modificador
    -- player:Int   Jugador a consultar (por defecto 0)
    -- field:Int    Playfield a consultar (por defecto 0)
    -- returns: Float (el valor actual del modificador)
    local currentValue = getPercent(mod, player, field);

    -- Registra un nuevo modificador personalizado (solo Haxe)
    -- modN:String  Nombre del nuevo modificador
    -- mod:Modifier Instancia de la clase Modifier (solo desde Haxe)
    registerModifier(modN, mod);

    -- ============================================
    -- [Events Section] - Sistema de Eventos
    -- ============================================

    -- SET: Establece un valor instantáneamente en un beat específico
    -- mod:String   Nombre del modificador
    -- beat:Float   Beat donde se ejecutará (ej: 32.0, 64.5)
    -- value:Float  Valor objetivo (0.0 a 1.0 típicamente)
    -- player:Int   Jugador objetivo (-1 = todos, 0 = jugador, 1 = oponente)
    -- field:Int    Playfield objetivo (-1 = todos)
    set(mod, beat, value, player, field);

    -- EASE: Interpola suavemente de valor actual a valor objetivo
    -- mod:String   Nombre del modificador
    -- beat:Float   Beat de inicio
    -- length:Float Duración en beats (ej: 4.0 = 4 beats)
    -- value:Float  Valor objetivo final
    -- ease:String  Función de easing ('linear', 'cubeInOut', 'backOut', etc.)
    -- player:Int   Jugador objetivo (-1 = todos)
    -- field:Int    Playfield objetivo (-1 = todos)
    ease(mod, beat, length, value, ease, player, field);

    -- ADD: Suma un valor gradualmente (acumula, no reemplaza)
    -- Parámetros idénticos a ease()
    -- Diferencia: Si drunk = 50%, add(..., 25%) llegará a 75% (50% + 25%)
    --            mientras que ease() iría directamente a 25%
    add(mod, beat, length, value, ease, player, field);

    -- SETADD: Establece valor + suma en un beat específico
    -- Combina set() con suma: establece (valorActual + value)
    -- mod:String   Nombre del modificador
    -- beat:Float   Beat donde se ejecutará
    -- value:Float  Valor a SUMAR al actual
    -- player:Int   Jugador objetivo (-1 = todos)
    -- field:Int    Playfield objetivo (-1 = todos)
    setAdd(mod, beat, value, player, field);

    -- CALLBACK: Ejecuta una función UNA VEZ en un beat específico
    -- beat:Float     Beat donde se ejecutará
    -- funcName:String Nombre de la función Lua a llamar (como string)
    -- field:Int      Playfield objetivo (-1 = todos)
    callback(beat, 'myCallbackFunction', field);

    -- REPEATER: Ejecuta una función CADA FRAME durante un período
    -- beat:Float      Beat de inicio
    -- length:Float    Duración en beats
    -- funcName:String Nombre de la función Lua a llamar (como string)
    -- field:Int       Playfield objetivo (-1 = todos)
    repeater(beat, length, 'myRepeaterFunction', field);

    -- ============================================
    -- [Playfield Section] - Gestión de Playfields
    -- ============================================
    
    -- Agrega un nuevo playfield (campo de juego adicional)
    -- ADVERTENCIA: Si agregas un playfield DESPUÉS de añadir modificadores,
    -- tendrás que añadir los modificadores nuevamente al nuevo playfield
    addPlayfield();

    -- ============================================
    -- [Alias Section] - Nombres Alternativos
    -- ============================================
    
    -- Crea un alias (nombre alternativo) para un modificador
    -- name:String      Nombre del modificador original
    -- aliasName:String Nombre alternativo/alias
    -- field:Int        Playfield objetivo
    alias(name, aliasName, field);

    -- ============================================
    -- [Constants] - Constantes Útiles
    -- ============================================
    
    -- Tamaño de las hold notes
    local holdSize = getHoldSize();        -- Tamaño completo
    local holdSizeDiv2 = getHoldSizeDiv2(); -- Tamaño / 2

    -- Tamaño de las flechas
    local arrowSize = getArrowSize();       -- Tamaño completo (160)
    local arrowSizeDiv2 = getArrowSizeDiv2(); -- Tamaño / 2 (80)
end
```

---

## Modificadores de Ruta (PathModifier / luapath)

Estas funciones te permiten controlar cualquier modificador que extienda `PathModifier` (recomendado: `luapath`) pasando una ruta personalizada desde Lua.

### Funciones

```lua
setModifierPath(modName, nodes, field)
setModifierPathOffset(modName, x, y, z, field)
setModifierPathBound(modName, bound, field)
```

### Cómo usar las variables

- `nodes`: Un arreglo de puntos que definen la ruta. Cada punto puede ser una tabla `{x=..., y=..., z=...}` (o un arreglo `{x, y, z}`). Estos puntos son offsets relativos desde `pathOffset`.
- `pathOffset` (con `setModifierPathOffset`): El origen de la ruta en coordenadas de pantalla/mundo. Normalmente se usa el centro de la pantalla para centrar la ruta.
- `pathBound` (con `setModifierPathBound`): El rango de distancia que equivale a recorrer la ruta completa. Valores grandes separan más las notas/receptores (menos “juntas”). Valores chicos las juntan.

### Ejemplo mínimo

```lua
function onInitModchart()
    addModifier('luapath', 0)

    -- Bound más grande = menos “juntas”
    setModifierPathBound('luapath', 7000, 0)

    -- Centrar la ruta (z es opcional)
    setModifierPathOffset('luapath', screenWidth * 0.5, screenHeight * 0.5, 0, 0)

    local nodes = {
        {x = 0,    y = 0,   z = 0},
        {x = 200,  y = -80, z = 40},
        {x = -200, y = -80, z = 80},
    }
    setModifierPath('luapath', nodes, 0)

    -- 0 = apagado, 1 = efecto completo
    setPercent('luapath', 1, -1, 0)
end
```

---

## Ejemplos Prácticos

### **Ejemplo 1: Modchart Básico**
```lua
function onInitModchart()
    -- Agregar modificadores que usaremos
    addModifier('reverse', -1)
    addModifier('drunk', -1)
    addModifier('tipsy', -1)
    
    -- Beat 0-16: Sin efectos
    
    -- Beat 16: Activar reverse instantáneamente
    set('reverse', 16, 1, 0, -1) -- Solo jugador
    
    -- Beat 32-48: Drunk aumenta gradualmente
    ease('drunk', 32, 16, 0.5, 'cubeInOut', -1, -1) -- Ambos jugadores
    
    -- Beat 64: Reset todo
    callback(64, 'resetModchart', -1)
end

function resetModchart()
    debugPrint('¡Reseteando modchart!')
    setPercent('reverse', 0, -1, -1)
    setPercent('drunk', 0, -1, -1)
end
```

### **Ejemplo 2: Efectos Acumulativos**
```lua
function onInitModchart()
    addModifier('invert', -1)
    
    -- Cada 16 beats, aumentar invert en 10%
    set('invert', 16, 0.1, -1, -1)      -- 10%
    setAdd('invert', 32, 0.1, -1, -1)   -- 10% + 10% = 20%
    setAdd('invert', 48, 0.1, -1, -1)   -- 20% + 10% = 30%
    setAdd('invert', 64, 0.1, -1, -1)   -- 30% + 10% = 40%
end
```

### **Ejemplo 3: Repeater para Efectos Pulsantes**
```lua
local bpm = 140

function onInitModchart()
    addModifier('zoom', -1)
    
    -- Efecto de pulso del beat 32 al 64
    repeater(32, 32, 'pulseEffect', -1)
end

function pulseEffect()
    -- Calcular beat actual con decimales
    local beat = (getSongPosition() / 1000) / (60 / bpm) * 4
    local beatFraction = beat % 1 -- 0.0 a 1.0 dentro del beat
    
    -- Pulsar al ritmo: más grande al inicio del beat, más pequeño al final
    local pulseAmount = 1.0 - beatFraction
    setPercent('zoom', pulseAmount * 0.2, -1, -1) -- Máximo 20% zoom
end
```

### **Ejemplo 4: Callback para Cambios Drásticos**
```lua
function onInitModchart()
    addModifier('reverse', -1)
    addModifier('flip', -1)
    addModifier('invert', -1)
    
    -- Preparar efectos suaves
    ease('reverse', 0, 32, 0.5, 'linear', 0, -1)
    
    -- En beat 32: Cambio drástico
    callback(32, 'dropEffect', -1)
    
    -- Reset en beat 64
    callback(64, 'resetAll', -1)
end

function dropEffect()
    debugPrint('¡DROP!')
    -- Activar múltiples efectos instantáneamente
    setPercent('flip', 1, -1, -1)
    setPercent('invert', 1, -1, -1)
    setPercent('reverse', 1, -1, -1)
end

function resetAll()
    setPercent('flip', 0, -1, -1)
    setPercent('invert', 0, -1, -1)
    setPercent('reverse', 0, -1, -1)
end
```

### **Ejemplo 5: Efectos Diferentes por Jugador**
```lua
function onInitModchart()
    addModifier('drunk', -1)
    addModifier('reverse', -1)
    
    -- Player (0): Drunk crece
    ease('drunk', 16, 16, 0.8, 'cubeOut', 0, -1)
    
    -- Opponent (1): Reverse activo
    set('reverse', 16, 1, 1, -1)
    
    -- Beat 48: Intercambiar efectos
    ease('drunk', 48, 8, 0, 'cubeIn', 0, -1)      -- Player pierde drunk
    ease('drunk', 48, 8, 0.8, 'cubeOut', 1, -1)   -- Opponent gana drunk
    set('reverse', 48, 0, 1, -1)                   -- Opponent pierde reverse
    set('reverse', 48, 1, 0, -1)                   -- Player gana reverse
end
```

---

## 🔧 Funciones de Easing Disponibles

Puedes usar estos strings en `ease()` y `add()`:

**Suaves:**
- `'linear'` - Sin easing, velocidad constante
- `'smoothStepIn'` / `'smoothStepOut'` / `'smoothStepInOut'`
- `'smootherStepIn'` / `'smootherStepOut'` / `'smootherStepInOut'`

**Cuadráticas:**
- `'quadIn'` / `'quadOut'` / `'quadInOut'`
- `'cubeIn'` / `'cubeOut'` / `'cubeInOut'`
- `'quartIn'` / `'quartOut'` / `'quartInOut'`
- `'quintIn'` / `'quintOut'` / `'quintInOut'`

**Especiales:**
- `'sineIn'` / `'sineOut'` / `'sineInOut'` - Movimiento sinusoidal
- `'circIn'` / `'circOut'` / `'circInOut'` - Circular
- `'expoIn'` / `'expoOut'` / `'expoInOut'` - Exponencial
- `'backIn'` / `'backOut'` / `'backInOut'` - Sobrepasa y vuelve
- `'bounceIn'` / `'bounceOut'` / `'bounceInOut'` - Rebote
- `'elasticIn'` / `'elasticOut'` / `'elasticInOut'` - Elástico

---

## ⚠️ Notas Importantes

1. **`player` vs `field`:**
   - `player`: Jugador/Strumline (0 = jugador, 1 = oponente, -1 = todos)
   - `field`: Playfield/Campo de juego (normalmente -1 a menos que uses múltiples playfields)

2. **Timing de eventos:**
   - Los eventos se evalúan cada frame basándose en `Conductor.songPosition`
   - Los beats son flotantes: `32.5` es válido (mitad del beat 32)

3. **Orden de ejecución:**
   - `onInitModchart()` se llama ANTES de que empiece la canción
   - Los eventos se ordenan automáticamente por beat
   - Múltiples eventos en el mismo beat se ejecutan en orden de creación

4. **Performance:**
   - Los `repeater` se ejecutan cada frame, úsalos con cuidado
   - Los `callback` se ejecutan una vez y se limpian automáticamente
   - Los eventos `ease` y `add` solo calculan mientras están activos

---

## 🎯 Tips y Trucos

**1. Usar callbacks para debug:**
```lua
callback(32, 'debugBeat32', -1)
function debugBeat32(event)
    debugPrint('Estado drunk: ' .. getPercent('drunk', 0, -1))
end
```

**2. Combinar ease con diferentes jugadores:**
```lua
-- Efecto espejo: uno sube mientras otro baja
ease('drunk', 16, 16, 0.8, 'cubeInOut', 0, -1)
ease('drunk', 16, 16, 0, 'cubeInOut', 1, -1)
```

**3. Usar repeater para sincronización perfecta:**
```lua
repeater(0, 999, 'beatSync', -1) -- Durante toda la canción
function beatSync()
    local pos = getSongPosition() / 1000
    local beat = pos / (60 / bpm) * 4
    if beat % 4 < 0.1 then -- Cada 4 beats
        setPercent('zoom', 0.2, -1, -1)
    else
        setPercent('zoom', 0, -1, -1)
    end
end
```

**4. Valores típicos de modificadores:**
- `0.0` = Desactivado (0%)
- `0.5` = Efecto medio (50%)
- `1.0` = Efecto completo (100%)
- Algunos modificadores aceptan valores negativos o >1.0

---

## 🚨 Errores Comunes

1. **"Manager.instance is null"**
   - Causa: Modcharting deshabilitado en opciones
   - Solución: Activa "Modcharting" en ClientPrefs

2. **Eventos no se ejecutan**
   - Causa: No están dentro de `onInitModchart()`
   - Solución: Coloca todos los eventos dentro de la función

3. **Callback no funciona**
   - Causa: Nombre de función como string incorrecto
   - Solución: `callback(32, 'myFunc', -1)` con comillas

4. **Modificador no existe**
   - Causa: No agregaste el modificador con `addModifier()`
   - Solución: Siempre usa `addModifier()` antes de usar el modificador

---

**Última actualización:** Octubre 2025 | **Versión:** Plus Engine 1.0
