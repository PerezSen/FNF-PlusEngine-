package lenin.slushithings.codenameengine.scripting;

import haxe.io.Path;
import flixel.FlxBasic;
#if sys
import sys.FileSystem;
#end

/**
 * Base class for CodeName Engine scripting system
 */
class Script extends FlxBasic
{
	/**
	 * Use "static var thing = true;" in hscript to use those!!
	 * are reset every mod switch so once you're done with them make sure to make them null!!
	 */
	public static var staticVariables:Map<String, Dynamic> = [];

	/**
	 * Currently executing script.
	 */
	public static var curScript:Script = null;

	/**
	 * Returns the default variables injected into HScript context
	 * @param script Optional script instance for context-specific variables
	 * @return Map of variable names to their values
	 */
	public static function getDefaultVariables(?script:Script):Map<String, Dynamic>
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
			"FlxColor" => psychlua.HScript.CustomFlxColor,
		];
	}

	/**
	 * Script name (with extension)
	 */
	public var fileName:String;

	/**
	 * Script Extension
	 */
	public var extension:String;

	/**
	 * Path to the script.
	 */
	public var path:String = null;

	private var rawPath:String = null;

	private var didLoad:Bool = false;

	public var remappedNames:Map<String, String> = [];

	public var modFolder:String;

	/**
	 * Creates a script from the specified asset path. The language is automatically determined.
	 * @param path Path in assets
	 */
	public static function create(path:String):Script
	{
		#if sys
		if (FileSystem.exists(path))
		{
			return switch (Path.extension(path).toLowerCase())
			{
				case "hx" | "hscript" | "hsc" | "hxs":
					new HScript(path);
				default:
					new DummyScript(path);
			}
		}
		#end
		return new DummyScript(path);
	}

	/**
	 * Creates a script from the string. The language is determined based on the path.
	 * @param code code
	 * @param path filename
	 */
	public static function fromString(code:String, path:String):Script
	{
		return switch (Path.extension(path).toLowerCase())
		{
			case "hx" | "hscript" | "hsc" | "hxs":
				new HScript(path).loadFromString(code);
			default:
				new DummyScript(path).loadFromString(code);
		}
	}

	/**
	 * Creates a new instance of the script class.
	 * @param path
	 */
	public function new(path:String)
	{
		super();

		rawPath = path;
		fileName = Path.withoutDirectory(path);
		extension = Path.extension(path);
		this.path = path;
		onCreate(path);
		
		#if MODS_ALLOWED
		var myFolder:Array<String> = path.split('/');
		if (myFolder[0] + '/' == Paths.mods()
			&& (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1])))
			this.modFolder = myFolder[1];
		#end
	}

	/**
	 * Loads the script
	 */
	public function load()
	{
		if (didLoad) return;

		var oldScript = curScript;
		curScript = this;
		onLoad();
		curScript = oldScript;

		didLoad = true;
	}

	/**
	 * Reloads the script (HSCRIPT ONLY FOR NOW!!)
	 */
	public function reload()
	{
		trace("Script.reload() is not implemented for " + Type.getClassName(Type.getClass(this)));
	}

	/**
	 * Trace function for scripts to use
	 */
	public function script_trace(text:Dynamic)
	{
		trace('[${fileName}] ${Std.string(text)}');
	}

	/**
	 * Calls the `create` function in scripts.
	 */
	public function onCreate(path:String) {}

	/**
	 * Calls the `load` function in scripts.
	 */
	public function onLoad() {}

	/**
	 * Sets a variable
	 * @param name Variable name
	 * @param val Value
	 */
	public function set(name:String, val:Dynamic) {}

	/**
	 * Gets a variable
	 * @param name Variable name
	 * @return Value (or null if it doesn't exist)
	 */
	public function get(name:String):Dynamic
	{
		return null;
	}

	/**
	 * Calls a function within the script
	 * @param name Function name
	 * @param args Optional arguments
	 */
	public function call(name:String, ?args:Array<Dynamic>):Dynamic
	{
		return null;
	}

	/**
	 * Loads the script from a string
	 * @param str Code
	 */
	public function loadFromString(str:String):Script
	{
		return this;
	}

	/**
	 * Sets the parent of the script
	 */
	public function setParent(parent:Dynamic) {}

	/**
	 * Adds a global public variable
	 * @param name Variable name
	 * @param val Value
	 */
	public function setPublicMap(map:Map<String, Dynamic>) {}

	override public function destroy()
	{
		super.destroy();
	}
}
