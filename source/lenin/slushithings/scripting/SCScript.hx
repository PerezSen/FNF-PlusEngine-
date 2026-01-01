package lenin.slushithings.scripting;

import lenin.slushithings.scripting.base.HScriptSC;
import psychlua.LuaUtils;

/**
 * Slushi Custom HScript implementation
 */
class SCScript extends flixel.FlxBasic
{
	public static function presetVariables():#if haxe3 Map<String, Dynamic> #else Hash<Dynamic> #end
	{
		return [
			// Haxe related stuff
			"Std" => Std,
			"Math" => Math,
			"Reflect" => Reflect,
			"StringTools" => StringTools,
			"Json" => haxe.Json,

			// OpenFL & Lime related stuff
			"Assets" => openfl.utils.Assets,
			"Application" => lime.app.Application,
			"Main" => Main,
			"window" => lime.app.Application.current.window,

			// Flixel related stuff
			"FlxG" => flixel.FlxG,
			"FlxSprite" => flixel.FlxSprite,
			"FlxBasic" => flixel.FlxBasic,
			"FlxCamera" => flixel.FlxCamera,
			"state" => flixel.FlxG.state,
			"FlxEase" => flixel.tweens.FlxEase,
			"FlxTween" => flixel.tweens.FlxTween,
			"FlxSound" => flixel.sound.FlxSound,
			"FlxAssets" => flixel.system.FlxAssets,
			"FlxMath" => flixel.math.FlxMath,
			"FlxGroup" => flixel.group.FlxGroup,
			"FlxTypedGroup" => flixel.group.FlxGroup.FlxTypedGroup,
			"FlxSpriteGroup" => flixel.group.FlxSpriteGroup,
			"FlxText" => flixel.text.FlxText,
			"FlxTimer" => flixel.util.FlxTimer,

			// Engine related stuff
			// Backend
			#if ACHIEVEMENTS_ALLOWED
			"Achievements" => backend.Achievements,
			#end
			"Conductor" => backend.Conductor,
			"ClientPrefs" => backend.ClientPrefs,
			"CoolUtil" => backend.CoolUtil,
			#if DISCORD_ALLOWED
			"Discord" => backend.Discord.DiscordClient,
			#end
			"Mods" => backend.Mods,
			"Paths" => backend.Paths,
			"PsychCamera" => backend.PsychCamera,
			
			// Objects
			"Alphabet" => objects.Alphabet,
			"AttachedSprite" => objects.AttachedSprite,
			"AttachedText" => objects.AttachedText,
			"Boyfriend" => objects.Character, // for compatibility
			"BGSprite" => objects.BGSprite,
			"Character" => objects.Character,
			"HealthIcon" => objects.HealthIcon,
			"Note" => objects.Note,
			"StrumNote" => objects.StrumNote,
			
			// States
			"FreeplayState" => states.FreeplayState,
			"MainMenuState" => states.MainMenuState,
			"PlayState" => states.PlayState,
			"StoryMenuState" => states.StoryMenuState,
			"TitleState" => states.TitleState,
			
			// SubStates
			"GameOverSubstate" => substates.GameOverSubstate,
			"PauseSubState" => substates.PauseSubState,

			// PsychLua
			#if LUA_ALLOWED
			"FunkinLua" => psychlua.FunkinLua,
			#end
			
			// Shaders
			"ColorSwap" => shaders.ColorSwap
		];
	}

	public var hsCode:HScriptSC;

	public function new()
	{
		super();
	}

	public function loadScript(path:String)
	{
		hsCode = new HScriptSC(path);
		presetScript();
	}

	public function callFunc(func:String, ?args:Array<Dynamic>):Dynamic
	{
		if (hsCode == null || !active || !exists) return null;
		if (args == null) args = [];
		var result = hsCode.call(func, args);
		return result != null ? result.funcReturn : null;
	}

	public function executeFunc(func:String = null, args:Array<Dynamic> = null):Dynamic
	{
		if (hsCode == null || !active || !exists) return null;
		return hsCode.call(func, args);
	}

	public function setVar(key:String, value:Dynamic):Void
	{
		if (hsCode == null || !active || !exists) return;
		hsCode.set(key, value, false);
	}

	public function getVar(key:String):Dynamic
	{
		if (hsCode == null || !active || !exists) return null;
		return hsCode.get(key);
	}

	public function existsVar(key:String):Bool
	{
		if (hsCode == null || !active || !exists) return false;
		return hsCode.exists(key);
	}

	public function presetScript()
	{
		if (hsCode == null || !active || !exists) return;

		for (k => e in presetVariables())
			setVar(k, e);

		setVar("disableScript", () -> {
			active = false;
		});
		setVar("__script__", this);

		setVar("playDadSing", true);
		setVar("playBFSing", true);

		// Functions & Variables
		setVar('setVar', function(name:String, value:Dynamic) {
			if (PlayState.instance != null)
				PlayState.instance.variables.set(name, value);
		});
		
		setVar('getVar', function(name:String) {
			if (PlayState.instance != null && PlayState.instance.variables.exists(name))
				return PlayState.instance.variables.get(name);
			return null;
		});
		
		setVar('removeVar', function(name:String) {
			if (PlayState.instance != null && PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});

		// Keyboard & Gamepads
		setVar('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		setVar('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		setVar('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		setVar('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
		setVar('anyGamepadPressed', function(name:String) return FlxG.gamepads.anyPressed(name));
		setVar('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

		setVar('keyJustPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch (name)
			{
				case 'left':
					return Controls.instance.NOTE_LEFT_P;
				case 'down':
					return Controls.instance.NOTE_DOWN_P;
				case 'up':
					return Controls.instance.NOTE_UP_P;
				case 'right':
					return Controls.instance.NOTE_RIGHT_P;
				default:
					return Controls.instance.justPressed(name);
			}
			return false;
		});
		
		setVar('keyPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch (name)
			{
				case 'left':
					return Controls.instance.NOTE_LEFT;
				case 'down':
					return Controls.instance.NOTE_DOWN;
				case 'up':
					return Controls.instance.NOTE_UP;
				case 'right':
					return Controls.instance.NOTE_RIGHT;
				default:
					return Controls.instance.pressed(name);
			}
			return false;
		});
		
		setVar('keyReleased', function(name:String = '') {
			name = name.toLowerCase();
			switch (name)
			{
				case 'left':
					return Controls.instance.NOTE_LEFT_R;
				case 'down':
					return Controls.instance.NOTE_DOWN_R;
				case 'up':
					return Controls.instance.NOTE_UP_R;
				case 'right':
					return Controls.instance.NOTE_RIGHT_R;
				default:
					return Controls.instance.justReleased(name);
			}
			return false;
		});

		#if LUA_ALLOWED
		setVar('doLua', function(code:String = null) {
			if (code != null) new psychlua.FunkinLua(code);
		});
		#end

		setVar('buildTarget', psychlua.LuaUtils.getBuildTarget());
		setVar('customSubstate', psychlua.CustomSubstate.instance);
		setVar('customSubstateName', psychlua.CustomSubstate.name);
		setVar('Function_Stop', psychlua.LuaUtils.Function_Stop);
		setVar('Function_Continue', psychlua.LuaUtils.Function_Continue);
		setVar('Function_StopLua', psychlua.LuaUtils.Function_StopLua);
		setVar('Function_StopHScript', psychlua.LuaUtils.Function_StopHScript);
		setVar('Function_StopAll', psychlua.LuaUtils.Function_StopAll);

		setVar('add', FlxG.state.add);
		setVar('insert', FlxG.state.insert);
		setVar('remove', FlxG.state.remove);

		if (PlayState.instance != null)
		{
			setVar('addBehindGF', PlayState.instance.addBehindGF);
			setVar('addBehindDad', PlayState.instance.addBehindDad);
			setVar('addBehindBF', PlayState.instance.addBehindBF);
		}
	}

	override public function destroy()
	{
		if (hsCode != null)
			hsCode.destroy();
		super.destroy();
	}
}
