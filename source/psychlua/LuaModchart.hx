package psychlua;

import modchart.Manager;
import modchart.backend.standalone.Adapter;
import modchart.engine.modifiers.list.PathModifier;
import modchart.engine.modifiers.list.PathModifier.PathNode;
import psychlua.FunkinLua;
import flixel.tweens.FlxEase;

class LuaModchart
{
    public static function implement(funk:FunkinLua) {
        var lua:State = funk.lua;
        
        // Add modifier
        Lua_helper.add_callback(lua, "addModifier", function(name:String, ?field:Int = -1) {
            if (Manager.instance != null)
                Manager.instance.addModifier(name, field);
        });
        
        // Set modifier percent
        Lua_helper.add_callback(lua, "setPercent", function(name:String, value:Float, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance != null)
                Manager.instance.setPercent(name, value, player, field);
        });
        
        // Get modifier percent
        Lua_helper.add_callback(lua, "getPercent", function(name:String, ?player:Int = 0, ?field:Int = 0):Float {
            if (Manager.instance != null)
                return Manager.instance.getPercent(name, player, field);
            return 0.0;
        });
        
        // Set modifier raw value
        Lua_helper.add_callback(lua, "setRawValue", function(name:String, value:Float, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance != null)
                Manager.instance.setRawValue(name, value, player, field);
        });
        
        // Get modifier raw value
        Lua_helper.add_callback(lua, "getRawValue", function(name:String, ?player:Int = 0, ?field:Int = 0):Float {
            if (Manager.instance != null)
                return Manager.instance.getRawValue(name, player, field);
            return 0.0;
        });
        
        // Set a value at a specific beat
        Lua_helper.add_callback(lua, "set", function(name:String, beat:Float, value:Float, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance != null)
                Manager.instance.set(name, beat, value, player, field);
        });
        
        // Ease a modifier
        Lua_helper.add_callback(lua, "ease", function(name:String, beat:Float, length:Float, value:Float, easeName:String, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance != null) {
                var easeFunc = getEaseFunction(easeName);
                Manager.instance.ease(name, beat, length, value, easeFunc, player, field);
            }
        });
        
        // Add with easing
        Lua_helper.add_callback(lua, "add", function(name:String, beat:Float, length:Float, value:Float, easeName:String, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance != null) {
                var easeFunc = getEaseFunction(easeName);
                Manager.instance.add(name, beat, length, value, easeFunc, player, field);
            }
        });
        
        // SetAdd helper
        Lua_helper.add_callback(lua, "setAdd", function(name:String, beat:Float, value:Float, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance != null)
                Manager.instance.setAdd(name, beat, value, player, field);
        });
        
        // Add new playfield
        Lua_helper.add_callback(lua, "addPlayfield", function() {
            if (Manager.instance != null)
                Manager.instance.addPlayfield();
        });
        
        // Create alias for a modifier
        Lua_helper.add_callback(lua, "alias", function(name:String, aliasName:String, field:Int) {
            if (Manager.instance != null)
                Manager.instance.alias(name, aliasName, field);
        });
        
        // Useful constants
        Lua_helper.add_callback(lua, "getHoldSize", function():Float {
            return Manager.HOLD_SIZE;
        });
        
        Lua_helper.add_callback(lua, "getHoldSizeDiv2", function():Float {
            return Manager.HOLD_SIZEDIV2;
        });
        
        Lua_helper.add_callback(lua, "getArrowSize", function():Float {
            return Manager.ARROW_SIZE;
        });
        
        Lua_helper.add_callback(lua, "getArrowSizeDiv2", function():Float {
            return Manager.ARROW_SIZEDIV2;
        });
        
        // Callback event: execute a function on a specific beat
        Lua_helper.add_callback(lua, "callback", function(beat:Float, funcName:String, ?field:Int = -1) {
            if (Manager.instance != null) {
                Manager.instance.callback(beat, function(event) {
                    funk.call(funcName, []); // Do not pass the event object to Lua
                }, field);
            }
        });
        
        // Schedule a callback to run once on a specific beat (alias for callback)
        Lua_helper.add_callback(lua, "scheduleCallback", function(beat:Float, funcName:String, ?field:Int = -1) {
            if (Manager.instance != null) {
                Manager.instance.scheduleCallback(beat, function(event) {
                    funk.call(funcName, []); // Do not pass the event object to Lua
                }, field);
            }
        });
        
        // Repeater event: execute a function repeatedly for a duration
        Lua_helper.add_callback(lua, "repeater", function(beat:Float, length:Float, funcName:String, ?field:Int = -1) {
            if (Manager.instance != null) {
                Manager.instance.repeater(beat, length, function(event) {
                    funk.call(funcName, []); // Do not pass the event object to Lua
                }, field);
            }
        });
        
        // Add scripted (custom) modifier
        Lua_helper.add_callback(lua, "addScriptedModifier", function(name:String, modifierInstance:Dynamic, ?field:Int = -1) {
            if (Manager.instance != null && modifierInstance != null) {
                // `modifierInstance` must be an instance of `Modifier` created via Lua/HScript
                Manager.instance.addScriptedModifier(name, modifierInstance, field);
            }
        });
        
        // Create a node: bind inputs and outputs through a function
        Lua_helper.add_callback(lua, "node", function(inputs:Array<String>, outputs:Array<String>, funcName:String, ?field:Int = -1) {
            if (Manager.instance != null) {
                Manager.instance.node(inputs, outputs, function(curInput:Array<Float>, curOutput:Int):Array<Float> {
                    // Call the Lua function with the input values
                    var result:Dynamic = funk.call(funcName, [curInput]);
                    // Return result as an array of floats, or an array with `curOutput` if missing
                    if (result != null && Std.isOfType(result, Array)) {
                        return cast result;
                    }
                    return [curOutput]; // Default to an array containing `curOutput`
                }, field);
            }
        });

		// PathModifier helpers (works for any modifier that extends PathModifier, e.g. arrowshape, luapath)
		Lua_helper.add_callback(lua, "setModifierPath", function(modName:String, nodes:Array<Dynamic>, ?field:Int = 0) {
			if (Manager.instance == null)
				return;
			final pf = Manager.instance.playfields[field];
			if (pf == null) {
				FunkinLua.luaTrace('setModifierPath: invalid playfield index: ' + field, false, false);
				return;
			}

			final mod = pf.modifiers.modifiers.get(modName.toLowerCase());
			if (mod == null) {
				FunkinLua.luaTrace('setModifierPath: modifier not found: ' + modName, false, false);
				return;
			}
			if (!Std.isOfType(mod, PathModifier)) {
				FunkinLua.luaTrace('setModifierPath: modifier is not a PathModifier: ' + modName, false, false);
				return;
			}

			final parsed = parsePathNodes(nodes);
			cast(mod, PathModifier).loadPath(parsed);
		});

		Lua_helper.add_callback(lua, "setModifierPathOffset", function(modName:String, x:Float, y:Float, ?z:Float = 0, ?field:Int = 0) {
			if (Manager.instance == null)
				return;
			final pf = Manager.instance.playfields[field];
	 		if (pf == null) {
				FunkinLua.luaTrace('setModifierPathOffset: invalid playfield index: ' + field, false, false);
				return;
			}

			final mod = pf.modifiers.modifiers.get(modName.toLowerCase());
			if (mod == null || !Std.isOfType(mod, PathModifier)) {
				FunkinLua.luaTrace('setModifierPathOffset: PathModifier not found: ' + modName, false, false);
				return;
			}

			cast(mod, PathModifier).pathOffset.setTo(x, y, z);
		});

		Lua_helper.add_callback(lua, "setModifierPathBound", function(modName:String, bound:Float, ?field:Int = 0) {
			if (Manager.instance == null)
				return;
			final pf = Manager.instance.playfields[field];
			if (pf == null) {
				FunkinLua.luaTrace('setModifierPathBound: invalid playfield index: ' + field, false, false);
				return;
			}

			final mod = pf.modifiers.modifiers.get(modName.toLowerCase());
			if (mod == null || !Std.isOfType(mod, PathModifier)) {
				FunkinLua.luaTrace('setModifierPathBound: PathModifier not found: ' + modName, false, false);
				return;
			}

			cast(mod, PathModifier).setPathBound(bound);
		});
        
        // Get current beat from Conductor
        Lua_helper.add_callback(lua, "getCurrentBeat", function():Float {
            return Conductor.songPosition / Conductor.crochet;
        });
        
        // Get current step from Conductor
        Lua_helper.add_callback(lua, "getCurrentStep", function():Float {
            return Conductor.songPosition / Conductor.stepCrochet;
        });
        
        // Get song position in milliseconds
        Lua_helper.add_callback(lua, "getSongPosition", function():Float {
            return Conductor.songPosition;
        });
        
        // Get current BPM
        Lua_helper.add_callback(lua, "getBPM", function():Float {
            return Conductor.bpm;
        });
        
        // Get player/playfield count
        Lua_helper.add_callback(lua, "getPlayerCount", function():Int {
            return Adapter.instance.getPlayerCount();
        });
    }
    
    // Helper: convert easing name to function
    private static function getEaseFunction(easeName:String) {
        return LuaUtils.getTweenEaseByString(easeName);
    }

    private static inline function toFloat(value:Dynamic, defaultValue:Float = 0):Float {
        if (value == null)
            return defaultValue;
        if (Std.isOfType(value, Float) || Std.isOfType(value, Int))
            return value;
        final f = Std.parseFloat(Std.string(value));
        return Math.isNaN(f) ? defaultValue : f;
    }

    private static function parsePathNodes(nodes:Array<Dynamic>):Array<PathNode> {
        final out:Array<PathNode> = [];
        if (nodes == null)
            return out;

        for (node in nodes) {
            if (node == null)
                continue;

            var x = 0.0;
            var y = 0.0;
            var z = 0.0;

            if (Std.isOfType(node, Array)) {
                final arr:Array<Dynamic> = cast node;
                // Try both 0-based and 1-based indexing (Lua tables can vary depending on bridge)
                x = toFloat(arr.length > 0 ? arr[0] : null, 0);
                y = toFloat(arr.length > 1 ? arr[1] : null, 0);
                z = toFloat(arr.length > 2 ? arr[2] : null, 0);
                if (x == 0 && y == 0 && z == 0 && arr.length >= 4) {
                    x = toFloat(arr[1], 0);
                    y = toFloat(arr[2], 0);
                    z = toFloat(arr[3], 0);
                }
            } else {
                x = toFloat(Reflect.field(node, 'x'), 0);
                y = toFloat(Reflect.field(node, 'y'), 0);
                z = toFloat(Reflect.field(node, 'z'), 0);
            }

            out.push({x: x, y: y, z: z});
        }
        return out;
    }
}