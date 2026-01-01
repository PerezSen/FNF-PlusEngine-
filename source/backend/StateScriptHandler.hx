package backend;

import flixel.FlxG;
import sys.FileSystem;
import backend.Paths;
import backend.Mods;

#if HSCRIPT_ALLOWED
import psychlua.HScript;
import crowplexus.iris.Iris;
import lenin.slushithings.scripting.SCScript;
import lenin.slushithings.codenameengine.scripting.Script;
import lenin.slushithings.codenameengine.scripting.ScriptPack;
#end

/**
 * Handles loading and management of state-specific scripts
 * Scripts are loaded from:
 * - scripts/states/[StateName]/ (Psych HScript & SC)
 * - scripts/states/[StateName]/advanced/ (CodeName HScript)
 */
class StateScriptHandler
{
	#if HSCRIPT_ALLOWED
	public static var stateHScripts:Array<HScript> = [];
	public static var stateSCScripts:Array<SCScript> = [];
	public static var stateCodeNameScripts:ScriptPack = new ScriptPack("StateScripts");
	#end
	
	/**
	 * Loads all scripts for a specific state
	 * @param stateName Name of the state (e.g., "MainMenuState", "FreeplayState")
	 */
	public static function loadStateScripts(stateName:String):Void
	{
		#if HSCRIPT_ALLOWED
		clearStateScripts();
		
		var haxeExtensions:Array<String> = ["hx", "hscript", "hsc", "hxs"];
		var stateFolder:String = 'scripts/states/$stateName/';
		var advancedFolder:String = 'scripts/states/$stateName/advanced/';
		
		// Load Psych HScript & SC from main folder
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), stateFolder))
		{
			if (!FileSystem.exists(folder)) continue;
			
			for (file in FileSystem.readDirectory(folder))
			{
				var fullPath:String = folder + file;
				
				// Skip advanced subfolder
				if (FileSystem.isDirectory(fullPath)) continue;
				
				// Check for HScript files
				for (ext in haxeExtensions)
				{
					if (file.toLowerCase().endsWith('.$ext'))
					{
						// Check if it should be SC script (has /sc/ in path or .sc. in name)
						if (folder.contains('/sc/') || file.contains('.sc.'))
							loadSCScript(fullPath, stateName);
						else
							loadHScript(fullPath, stateName);
						break;
					}
				}
			}
		}
		
		// Load SC scripts from sc/ subfolder
		var scFolder:String = 'scripts/states/$stateName/sc/';
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), scFolder))
		{
			if (!FileSystem.exists(folder)) continue;
			
			for (file in FileSystem.readDirectory(folder))
			{
				var fullPath:String = folder + file;
				if (FileSystem.isDirectory(fullPath)) continue;
				
				for (ext in haxeExtensions)
				{
					if (file.toLowerCase().endsWith('.$ext'))
					{
						loadSCScript(fullPath, stateName);
						break;
					}
				}
			}
		}
		
		// Load CodeName HScript from advanced/ folder
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), advancedFolder))
		{
			if (!FileSystem.exists(folder)) continue;
			
			for (file in FileSystem.readDirectory(folder))
			{
				var fullPath:String = folder + file;
				if (FileSystem.isDirectory(fullPath)) continue;
				
				for (ext in haxeExtensions)
				{
					if (file.toLowerCase().endsWith('.$ext'))
					{
						loadCodeNameScript(fullPath, stateName);
						break;
					}
				}
			}
		}
		
		// Call onCreate on all loaded scripts
		callOnStateScripts('onCreate', []);
		#end
	}
	
	#if HSCRIPT_ALLOWED
	private static function loadHScript(path:String, stateName:String):Void
	{
		try
		{
			if (Iris.instances.exists(path))
			{
				trace('[$stateName][HScript] Script already loaded: $path');
				return;
			}
			
			var script:HScript = new HScript(null, path);
			if (script != null)
			{
				// Inject helper functions
				injectScriptHelpers(script, path);
				stateHScripts.push(script);
				trace('[$stateName][HScript] Script loaded: $path');
			}
		}
		catch (e:Dynamic)
		{
			trace('[$stateName][HScript] Error loading script: $path - $e');
		}
	}
	
	private static function loadSCScript(path:String, stateName:String):Void
	{
		try
		{
			var script:SCScript = new SCScript();
			script.loadScript(path);
			// SC scripts already have helper functions
			stateSCScripts.push(script);
			trace('[$stateName][SCScript] Script loaded: $path');
		}
		catch (e:Dynamic)
		{
			trace('[$stateName][SCScript] Error loading script: $path - $e');
		}
	}
	
	private static function loadCodeNameScript(path:String, stateName:String):Void
	{
		try
		{
			// Create HScript directly to inject variables BEFORE parsing
			if (path.toLowerCase().endsWith('.hx') || path.toLowerCase().endsWith('.hscript') || 
				path.toLowerCase().endsWith('.hsc') || path.toLowerCase().endsWith('.hxs'))
			{
				var hscript:lenin.slushithings.codenameengine.scripting.HScript = 
					new lenin.slushithings.codenameengine.scripting.HScript(path);
				
				// Inject variables BEFORE loadFromString is called
				injectCodeNameScriptHelpers(hscript, path);
				
				// Now load and parse
				if (!(hscript is lenin.slushithings.codenameengine.scripting.DummyScript))
				{
					stateCodeNameScripts.add(hscript);
					hscript.load();
					trace('[$stateName][CodeNameScript] Script loaded: $path');
				}
			}
			else
			{
				// Fall back to generic Script.create for non-HScript files
				var script = Script.create(path);
				if (!(script is lenin.slushithings.codenameengine.scripting.DummyScript))
				{
					injectCodeNameScriptHelpers(script, path);
					stateCodeNameScripts.add(script);
					script.load();
					trace('[$stateName][CodeNameScript] Script loaded: $path');
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('[$stateName][CodeNameScript] Error loading script: $path - $e');
		}
	}
	
	/**
	 * Injects helper functions into HScript
	 */
	private static function injectScriptHelpers(script:HScript, scriptPath:String):Void
	{
		// Global variables and classes
		script.set('FlxG', FlxG);
		script.set('FlxSprite', flixel.FlxSprite);
		script.set('FlxText', flixel.text.FlxText);
		script.set('FlxColor', psychlua.HScript.CustomFlxColor);
		script.set('FlxTimer', flixel.util.FlxTimer);
		script.set('FlxTween', flixel.tweens.FlxTween);
		script.set('FlxEase', flixel.tweens.FlxEase);
		script.set('FlxCamera', flixel.FlxCamera);
		script.set('PsychCamera', backend.PsychCamera);
		script.set('FlxFlicker', flixel.effects.FlxFlicker);
		script.set('FlxAxes', psychlua.HScript.CustomFlxAxes);
		script.set('FlxSpriteGroup', flixel.group.FlxSpriteGroup);
		script.set('FlxTypedGroup', flixel.group.FlxTypedGroup);
		script.set('FlxGroup', flixel.group.FlxGroup);
		script.set('Alphabet', objects.Alphabet);
		script.set('StringTools', StringTools);
		script.set('Math', Math);
		script.set('Type', Type);
		
		// Text alignment and styling constants
		script.set('LEFT', flixel.text.FlxText.FlxTextAlign.LEFT);
		script.set('CENTER', flixel.text.FlxText.FlxTextAlign.CENTER);
		script.set('RIGHT', flixel.text.FlxText.FlxTextAlign.RIGHT);
		script.set('JUSTIFY', flixel.text.FlxText.FlxTextAlign.JUSTIFY);
		script.set('OUTLINE', flixel.text.FlxText.FlxTextBorderStyle.OUTLINE);
		script.set('SHADOW', flixel.text.FlxText.FlxTextBorderStyle.SHADOW);
		script.set('OUTLINE_FAST', flixel.text.FlxText.FlxTextBorderStyle.OUTLINE_FAST);
		
		// Game state shortcuts
		script.set('game', FlxG.state);
		script.set('state', FlxG.state);
		
		script.set('setVar', function(name:String, value:Dynamic) {
			if (FlxG.state != null && Std.isOfType(FlxG.state, MusicBeatState))
			MusicBeatState.getStateVariables('Custom').set(name, value);
	});
	
	script.set('getVar', function(name:String):Dynamic {
		if (FlxG.state != null && Std.isOfType(FlxG.state, MusicBeatState))
		{
			var map = MusicBeatState.getStateVariables('Custom');
			if (map.exists(name))
				return map.get(name);
		}
		return null;
	});
	
	script.set('removeVar', function(name:String):Bool {
		if (FlxG.state != null && Std.isOfType(FlxG.state, MusicBeatState))
		{
			var map = MusicBeatState.getStateVariables('Custom');
			if (map.exists(name))
			{
				map.remove(name);
				return true;
			}
		}
		return false;
	});
		
		// Keyboard helpers
		script.set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		script.set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		script.set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));
		
		// Gamepad helpers
		script.set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
		script.set('anyGamepadPressed', function(name:String) return FlxG.gamepads.anyPressed(name));
		script.set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));
	}
	
	/**
	 * Injects helper functions and global variables into CodeName Script
	 * This includes actual class types that can be extended in scripts
	 */
	private static function injectCodeNameScriptHelpers(script:Script, scriptPath:String):Void
	{
		// For HScript, inject directly into interp.variables before parsing
		var hscript:lenin.slushithings.codenameengine.scripting.HScript = null;
		if (Std.isOfType(script, lenin.slushithings.codenameengine.scripting.HScript))
		{
			hscript = cast(script, lenin.slushithings.codenameengine.scripting.HScript);
		}
		
		// Helper function to set variables
		var setVar = function(key:String, value:Dynamic) {
			script.set(key, value);
			// Also set in HScript interp if available
			if (hscript != null && hscript.interp != null)
				hscript.interp.variables.set(key, value);
		};
		
		// Actual Haxe classes for inheritance support
		setVar('FlxSprite', flixel.FlxSprite);
		setVar('FlxText', flixel.text.FlxText);
		setVar('FlxGroup', flixel.group.FlxGroup);
		setVar('FlxSpriteGroup', flixel.group.FlxSpriteGroup);
		setVar('FlxTypedGroup', flixel.group.FlxTypedGroup);
		setVar('FlxBasic', flixel.FlxBasic);
		setVar('FlxObject', flixel.FlxObject);
		setVar('FlxCamera', flixel.FlxCamera);
		setVar('Alphabet', objects.Alphabet);
		
		// Static classes and utilities
		setVar('FlxG', FlxG);
		setVar('FlxTimer', flixel.util.FlxTimer);
		setVar('FlxTween', flixel.tweens.FlxTween);
		setVar('FlxEase', flixel.tweens.FlxEase);
		setVar('PsychCamera', backend.PsychCamera);
		setVar('FlxFlicker', flixel.effects.FlxFlicker);
		setVar('StringTools', StringTools);
		setVar('Math', Math);
		setVar('Type', Type);
		setVar('Std', Std);
		setVar('Reflect', Reflect);
		
		// Color and styling wrappers
		setVar('FlxColor', psychlua.HScript.CustomFlxColor);
		setVar('FlxAxes', psychlua.HScript.CustomFlxAxes);
		
		// Text formatting constants
		setVar('LEFT', flixel.text.FlxText.FlxTextAlign.LEFT);
		setVar('CENTER', flixel.text.FlxText.FlxTextAlign.CENTER);
		setVar('RIGHT', flixel.text.FlxText.FlxTextAlign.RIGHT);
		setVar('JUSTIFY', flixel.text.FlxText.FlxTextAlign.JUSTIFY);
		setVar('OUTLINE', flixel.text.FlxText.FlxTextBorderStyle.OUTLINE);
		setVar('SHADOW', flixel.text.FlxText.FlxTextBorderStyle.SHADOW);
		setVar('OUTLINE_FAST', flixel.text.FlxText.FlxTextBorderStyle.OUTLINE_FAST);
		
		// Game state shortcuts
		setVar('game', FlxG.state);
		setVar('state', FlxG.state);
		
		// Helper functions for variable management
		setVar('setVar', function(name:String, value:Dynamic) {
			if (FlxG.state != null && Std.isOfType(FlxG.state, MusicBeatState))
			MusicBeatState.getStateVariables('Custom').set(name, value);
	});
	
	setVar('getVar', function(name:String):Dynamic {
		if (FlxG.state != null && Std.isOfType(FlxG.state, MusicBeatState))
		{
			var map = MusicBeatState.getStateVariables('Custom');
			if (map.exists(name))
				return map.get(name);
		}
		return null;
	});
	
	setVar('removeVar', function(name:String):Bool {
		if (FlxG.state != null && Std.isOfType(FlxG.state, MusicBeatState))
		{
			var map = MusicBeatState.getStateVariables('Custom');
			if (map.exists(name))
			{
				map.remove(name);
				return true;
			}
		}
		return false;
	});
		
		// Keyboard helpers
		setVar('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		setVar('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		setVar('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));
		
		// Gamepad helpers
		setVar('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
		setVar('anyGamepadPressed', function(name:String) return FlxG.gamepads.anyPressed(name));
		setVar('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));
	}
	#end
	
	/**
	 * Calls a function on all loaded state scripts
	 */
	public static function callOnStateScripts(funcName:String, args:Array<Dynamic> = null):Dynamic
	{
		#if HSCRIPT_ALLOWED
		if (args == null) args = [];
		var returnVal:Dynamic = psychlua.LuaUtils.Function_Continue;
		
		// Call on Psych HScripts
		for (script in stateHScripts)
		{
			if (script == null || !script.exists(funcName)) continue;
			
			try
			{
				var ret:Dynamic = script.call(funcName, args);
				if (ret != null && ret != psychlua.LuaUtils.Function_Continue)
					returnVal = ret;
			}
			catch (e:Dynamic)
			{
				trace('[HScript] Error in function "$funcName": $e');
			}
		}
		
		// Call on SC Scripts
		for (script in stateSCScripts)
		{
			if (script == null || !script.active || !script.exists) continue;
			
			try
			{
				var ret:Dynamic = script.callFunc(funcName, args);
				if (ret != null && ret != psychlua.LuaUtils.Function_Continue)
					returnVal = ret;
			}
			catch (e:Dynamic)
			{
				trace('[SCScript] Error in function "$funcName": $e');
			}
		}
		
		// Call on CodeName Scripts
		if (stateCodeNameScripts != null)
		{
			try
			{
				// CodeName HScript runs its own onCreate during load; avoid calling it twice.
				if (funcName != 'onCreate')
				{
					var ret:Dynamic = stateCodeNameScripts.call(funcName, args);
					if (ret != null && ret != psychlua.LuaUtils.Function_Continue)
						returnVal = ret;
				}
			}
			catch (e:Dynamic)
			{
				trace('[CodeNameScript] Error in function "$funcName": $e');
			}
		}
		
		return returnVal;
		#else
		return psychlua.LuaUtils.Function_Continue;
		#end
	}
	
	/**
	 * Sets a variable on all loaded state scripts
	 */
	public static function setOnStateScripts(varName:String, value:Dynamic):Void
	{
		#if HSCRIPT_ALLOWED
		// Set on Psych HScripts
		for (script in stateHScripts)
		{
			if (script != null)
				script.set(varName, value);
		}
		
		// Set on SC Scripts
		for (script in stateSCScripts)
		{
			if (script != null && script.active && script.exists)
				script.setVar(varName, value);
		}
		
		// Set on CodeName Scripts
		if (stateCodeNameScripts != null)
			stateCodeNameScripts.set(varName, value);
		#end
	}
	
	/**
	 * Clears all loaded state scripts
	 */
	public static function clearStateScripts():Void
	{
		#if HSCRIPT_ALLOWED
		// Destroy Psych HScripts
		for (script in stateHScripts)
		{
			if (script != null)
				script.destroy();
		}
		stateHScripts = [];
		
		// Destroy SC Scripts
		for (script in stateSCScripts)
		{
			if (script != null)
				script.destroy();
		}
		stateSCScripts = [];
		
		// Destroy CodeName Scripts
		if (stateCodeNameScripts != null)
		{
			for (script in stateCodeNameScripts.scripts)
			{
				if (script != null)
					script.destroy();
			}
			stateCodeNameScripts.scripts = [];
		}
		#end
	}
	
	/**
	 * Updates all state scripts
	 */
	public static function updateStateScripts(elapsed:Float):Void
	{
		callOnStateScripts('onUpdate', [elapsed]);
		callOnStateScripts('onUpdatePost', [elapsed]);
	}
}
