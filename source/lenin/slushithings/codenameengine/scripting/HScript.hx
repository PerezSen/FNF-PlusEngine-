package lenin.slushithings.codenameengine.scripting;

import haxe.io.Path;
import _hscript.Interp;
import _hscript.Parser;
import _hscript.Expr;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

/**
 * CodeName Engine HScript implementation
 */
class HScript extends Script
{
	public var interp:Interp;
	public var parser:Parser;
	public var expr:Expr;
	public var code:String;

	var __importedPaths:Array<String>;

	public static function initParser()
	{
		var p = new Parser();
		p.allowJSON = p.allowMetadata = p.allowTypes = true;
		return p;
	}

	public override function onCreate(path:String)
	{
		super.onCreate(path);

		interp = new Interp();

		try
		{
			#if sys
			if (FileSystem.exists(rawPath))
				code = File.getContent(rawPath);
			#else
			code = openfl.utils.Assets.getText(path);
			#end
		}
		catch (e)
		{
			trace('Error while reading $path: ${Std.string(e)}');
		}
		
		parser = initParser();
		__importedPaths = [path];

		interp.errorHandler = _errorHandler;
		interp.importFailedCallback = importFailedCallback;
		interp.staticVariables = Script.staticVariables;
		interp.allowStaticVariables = interp.allowPublicVariables = true;

		// Inject default variables (Flixel classes, etc.)
		for (k => v in Script.getDefaultVariables(this))
			interp.variables.set(k, v);

		interp.variables.set("trace", Reflect.makeVarArgs((args) -> {
			var v:String = Std.string(args.shift());
			for (a in args)
				v += ", " + Std.string(a);
			script_trace(v);
		}));

		if (GlobalScript != null)
			GlobalScript.call("onScriptCreated", [this, "hscript"]);
		
		loadFromString(code);
	}

	public override function loadFromString(code:String)
	{
		try
		{
			if (code != null && code.trim() != "")
				expr = parser.parseString(code, Path.withoutDirectory(fileName));
		}
		catch (e:Dynamic)
		{
			trace('Error parsing script: ${Std.string(e)}');
		}

		return this;
	}

	private function importFailedCallback(cl:Array<String>):Bool
	{
		#if sys
		var assetsPath = 'mods/scripts/${cl.join("/")}';
		for (hxExt in ["hx", "hscript", "hsc", "hxs"])
		{
			var p = '$assetsPath.$hxExt';
			if (__importedPaths.contains(p)) return true; // already imported
			if (FileSystem.exists(p))
			{
				var code = File.getContent(p);
				var expr:Expr = null;
				try
				{
					if (code != null && code.trim() != "")
						expr = parser.parseString(code, Path.withoutDirectory(cl.join("/") + "." + hxExt));
				}
				catch (e:Dynamic)
				{
					_errorHandler(e);
				}
				if (expr != null)
				{
					@:privateAccess
					interp.exprReturn(expr);
					__importedPaths.push(p);
				}
				return true;
			}
		}
		#end
		return false;
	}

	private function _errorHandler(error:Dynamic)
	{
		var errorMsg = Std.string(error);
		trace('Script Error in $fileName: $errorMsg');
		
		#if HSCRIPT_ALLOWED
		if (PlayState.instance != null)
			PlayState.instance.addTextToDebug('Script Error in $fileName: $errorMsg', 0xFFFF0000);
		#end
	}

	public override function setParent(parent:Dynamic)
	{
		// Set parent for script context (scriptObject in CodenameEngine)
		interp.scriptObject = parent;
	}

	public override function onLoad()
	{
		@:privateAccess
		interp.execute(parser.mk(EBlock([]), 0, 0));
		if (expr != null)
		{
			try
			{
				interp.execute(expr);
				call("onCreate", []);
			}
			catch (e:Dynamic)
			{
				_errorHandler(e);
			}
		}
	}

	public override function reload()
	{
		// Save variables
		interp.allowStaticVariables = interp.allowPublicVariables = false;
		var savedVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
		if (interp != null && interp.variables != null)
		{
			for (k in interp.variables.keys())
			{
				var e = interp.variables.get(k);
				if (!Reflect.isFunction(e))
					savedVariables.set(k, e);
			}
		}
		
		var oldParent = interp != null ? interp.scriptObject : null;
		onCreate(path);

		// Re-inject default variables after recreating the interpreter
		for (k => v in Script.getDefaultVariables(this))
			interp.variables.set(k, v);

		load();
		if (oldParent != null) setParent(oldParent);

		for (k in savedVariables.keys())
			interp.variables.set(k, savedVariables.get(k));
		
		interp.allowStaticVariables = interp.allowPublicVariables = true;
	}

	public override function call(funcName:String, ?parameters:Array<Dynamic>):Dynamic
	{
		if (interp == null) return null;
		if (funcName == null || !interp.variables.exists(funcName)) return null;

		var func = interp.variables.get(funcName);
		if (func != null && Reflect.isFunction(func))
		{
			if (parameters == null) parameters = [];
			try
			{
				return Reflect.callMethod(null, func, parameters);
			}
			catch (e:Dynamic)
			{
				_errorHandler(e);
			}
		}

		return null;
	}

	public override function get(val:String):Dynamic
	{
		return interp.variables.get(val);
	}

	public override function set(val:String, value:Dynamic)
	{
		interp.variables.set(val, value);
	}

	public override function setPublicMap(map:Map<String, Dynamic>)
	{
		for (k => v in map)
			interp.variables.set(k, v);
	}

	override public function destroy()
	{
		if (interp != null && interp.variables != null)
			interp.variables.clear();
		
		interp = null;
		parser = null;
		expr = null;
		code = null;
		
		super.destroy();
	}
}
