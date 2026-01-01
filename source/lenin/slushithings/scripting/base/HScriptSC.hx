package lenin.slushithings.scripting.base;

import _hscript.Interp;
import _hscript.Parser;
import _hscript.Expr;
import haxe.io.Path;
#if sys
import sys.io.File;
#end

typedef SCCall =
{
	var funcName:String;
	var funcValue:Dynamic;
	var funcReturn:Dynamic;
}

/**
 * Class serves as base for SCScript.
 */
class HScriptSC
{
	public var interp:Interp;
	public var parser:Parser;
	public var block:Expr;

	public var path:String;
	public var fileName:String;
	public var scriptStr:String;

	public var extension:String;

	public var modFolder:String;

	public var logErrors:Bool = true;

	public function new(path:String)
	{
		this.extension = Path.extension(path);
		this.path = path;
		#if sys
		this.scriptStr = #if MODS_ALLOWED File.getContent(path) #else openfl.utils.Assets.getText(path) #end;
		#else
		this.scriptStr = openfl.utils.Assets.getText(path);
		#end
		this.fileName = Path.withoutDirectory(path);

		#if MODS_ALLOWED
		var myFolder:Array<String> = path.split('/');
		if (myFolder[0] + '/' == Paths.mods()
			&& (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) // is inside mods folder
			this.modFolder = myFolder[1];
		#end

		parser = new Parser();
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;

		interp = new Interp();
		try
		{
			block = parser.parseString(scriptStr);
			interp.execute(block);
		}
		catch (e:haxe.Exception)
		{
			trace('Error on loading script $fileName: ${e.message}');
			return;
		}
	}

	public function call(func:String, ?args:Array<Dynamic> = null):SCCall
	{
		if (interp == null) return null;
		if (args == null) args = [];

		try
		{
			var fnc:Dynamic = variables().get(func);
			if (fnc != null && Reflect.isFunction(fnc))
			{
				final call = Reflect.callMethod(null, fnc, args);
				return {funcName: func, funcValue: fnc, funcReturn: call};
			}
		}
		catch (e:haxe.Exception)
		{
			if (logErrors) trace('Error calling function $func: ${e.message}');
		}

		return null;
	}

	public function executeFunction(func:String = null, args:Array<Dynamic> = null):Dynamic
	{
		if (func == null || !exists(func)) return null;
		return call(func, args);
	}

	public function set(key:String, value:Dynamic, overrideVar:Bool = true):Void
	{
		if (interp == null) return;
		try
		{
			if (overrideVar || !variables().exists(key)) variables().set(key, value);
		}
		catch (e:haxe.Exception)
		{
			if (logErrors) trace('Error setting variable $key: ${e.message}');
		}
	}

	public function get(key:String):Dynamic
	{
		if (interp == null) return null;
		try
		{
			return variables().get(key);
		}
		catch (e:haxe.Exception)
		{
			if (logErrors) trace('Error getting variable $key: ${e.message}');
		}
		return null;
	}

	public function exists(key:String):Bool
	{
		if (interp == null) return false;
		try
		{
			return variables().exists(key);
		}
		catch (e:haxe.Exception)
		{
			if (logErrors) trace('Error checking variable $key: ${e.message}');
		}
		return false;
	}

	public function variables()
	{
		return interp.variables;
	}

	public function destroy()
	{
		if (interp != null)
		{
			interp.variables.clear();
			interp = null;
		}
		if (parser != null) parser = null;
		if (block != null) block = null;
	}
}
