If you don't want to use haxe and want to do it only from lua, which by the way is better to do it in lua since it doesn't alter the mechanics much, look [here](https://github.com/LeninAsto/FNF-PlusEngine/blob/main/docs/scripts/DocLuaModchart.md)

```haxe
function onInitModchart() {
    //From here, I'll explain how to use it. There are several things that might blow your mind...
    //De aquí te explicaré cómo usarlo. Hay varias cosas que pueden confundirte...
    //Let's start with the scripts you can use
    //Empecemos con los scripts que puedes utilizar

    instance.addModifier(mod, field);
    /*
     * Adds or rewrites the percent of `mod` and sets it to `value`
     * Añade o sobrescribe el porcentaje de `mod` y lo establece en `value`
     *
     * mod:String   The modifier name string
     *              El nombre del modificador (cadena)
     * value:Float  The value to be assigned to the modifier.
     *              El valor que se asignará al modificador.
     * field:Int    The playfield number  (-1 by default)
     *              El número de campo de juego (-1 por defecto)
    */
    instance.setPercent(mod, value, field);
    /*
     * Returns the percent of `mod`
     * Devuelve el porcentaje de `mod`
     *
     * mod:String   The modifier name string
     *              El nombre del modificador (cadena)
     * field:Int    The playfield number  (-1 by default)
     *              El número de campo de juego (-1 por defecto)
     *
     * returns: Float
     *          Devuelve: Float
    */
    instance.getPercent(mod, field);
    /*
     * Registers a new modifier in the name of `modN`
     * Registra un nuevo modificador con el nombre `modN`
     *
     * modN:String  The modifier name string
     *              El nombre del nuevo modificador (cadena)
     * mod:Modifier The custom modifier class instance.
     *              La instancia de la clase modificador personalizada.
    */
    instance.registerModifier(modN, mod);

    /* Events Section */
    /* Sección de eventos */
    /*
     * Adds or rewrites the percentage of `mod` and sets it to `value`
     * when the specified beat is reached.
     * Añade o sobrescribe el porcentaje de `mod` y lo establece en `value`
     * cuando se alcanza el beat especificado.
     *
     * mod:String   The modifier name string
     *              El nombre del modificador (cadena)
     * beat:Float   The beat number where the event will be executed.
     *              El número de beat donde se ejecutará el evento.
     * value:Float  The value to be assigned to the modifier.
     *              El valor que se asignará al modificador.
     * player:Int   The player/strumline number (-1 by default)
     *              El número de jugador/strumline (-1 por defecto)
     * field:Int    The playfield number  (-1 by default)
     *              El número de campo de juego (-1 por defecto)
    */
    instance.set(mod, beat, value, player, field);
    /*
     * Tweens the percentage of `mod` from its current value to `value`
     * over the specified duration, using the provided easing function.
     * Interpola el porcentaje de `mod` desde su valor actual hasta `value`
     * durante la duración especificada, usando la función de easing proporcionada.
     *
     * mod:String   The modifier name string
     *              El nombre del modificador (cadena)
     * beat:Float   The beat number where the event will be executed.
     *              El número de beat donde se ejecutará el evento.
     * length:Float The tween duration in beats.
     *              La duración de la interpolación en beats.
     * ease:F->F    The ease function (Float to Float)
     *              La función de easing (Float a Float)
     * value:Float  The value to be assigned to the modifier.
     *              El valor que se asignará al modificador.
     * player:Int   The player/strumline number (-1 by default)
     *              El número de jugador/strumline (-1 por defecto)
     * field:Int    The playfield number  (-1 by default)
     *              El número de campo de juego (-1 por defecto)
    */
    instance.ease(mod, beat, length, value, ease, player, field);
    /*
     * Execute the callback function when the specified beat is reached.
     * Ejecuta la función callback cuando se alcanza el beat especificado.
     *
     * beat:Float   The beat number where the event will be executed.
     *              El número de beat donde se ejecutará el evento.
     * func:V->V    The callback function to execute
     *              La función callback a ejecutar
     * field:Int    The playfield number  (-1 by default)
     *              El número de campo de juego (-1 por defecto)
    */
    instance.callback(beat, func, field);
    /*
     * Repeats the execution of the callback function for the specified duration,
     * starting at the given beat.
     * Repite la ejecución de la función callback durante la duración especificada,
     * comenzando en el beat dado.
     *
     * beat:Float   The beat number where the event will be executed.
     *              El número de beat donde se ejecutará el evento.
     * length:Float The repeater duration in beats.
     *              La duración del repetidor en beats.
     * func:V->V    The callback function to execute
     *              La función callback a ejecutar
     * field:Int    The playfield number  (-1 by default)
     *              El número de campo de juego (-1 por defecto)
    */
    instance.repeater(beat, length, func, field);
    /*
     * Adds a custom event.
     * Añade un evento personalizado.
     *
     * event:Event  The custom event to be added.
     *              El evento personalizado a añadir.
     * field:Int    The playfield number  (-1 by default)
     *              El número de campo de juego (-1 por defecto)
    */
    instance.addEvent(event, field);

    /* Playfield Section */
    /* Sección de campos de juego */
    /*
     * Adds a new playfield.
     * Añade un nuevo campo de juego.
     *
     * WARNING: If you add a playfield after adding modifiers, you will have to add them again to the new playfield.
     * ADVERTENCIA: Si añades un campo de juego después de añadir modificadores, tendrás que añadirlos de nuevo al nuevo campo.
    */
    instance.addPlayfield();
}
```
# Este modifier es el que talvez buscabas y no encontrabas =p
# This modifier is maybe what you were looking for and couldn't find =p

- LuaPath - luapath
        - Español (cómo usar las variables):
            - `pathBound`: controla qué tan “separadas” aparecen las notas/receptores sobre la ruta. Si está muy bajo, todo se junta; si está alto, queda más distribuido.
            - `pathOffset`: mueve el origen de la ruta (por ejemplo al centro de la pantalla).
            - `nodes`: lista de puntos `{x, y, z}` que forman la ruta; `z` es opcional y sirve para profundidad.
            - Se configura desde Lua con:
                - `setModifierPathBound('luapath', bound, field)`
                - `setModifierPathOffset('luapath', x, y, z, field)`
                - `setModifierPath('luapath', nodes, field)`
        - English (how to use the variables):
            - `pathBound`: controls how “spread out” notes/receptors are along the path. Too low = they bunch up; higher = more evenly distributed.
            - `pathOffset`: moves the path origin (for example, to the screen center).
            - `nodes`: list of `{x, y, z}` points that define the path; `z` is optional and can be used for depth.
            - Configure it from Lua with:
                - `setModifierPathBound('luapath', bound, field)`
                - `setModifierPathOffset('luapath', x, y, z, field)`
                - `setModifierPath('luapath', nodes, field)`

## Faltan mas modificadores pero estos son algunos de ellos, este codigo esta en desarrollo sorry XD