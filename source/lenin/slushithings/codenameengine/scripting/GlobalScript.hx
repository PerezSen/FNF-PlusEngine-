package lenin.slushithings.codenameengine.scripting;

import backend.Conductor;
import flixel.FlxState;
import backend.Mods;

#if HSCRIPT_ALLOWED
/**
 * Class for THE Global Script, aka script that runs in the background at all times.
 */
class GlobalScript
{
	public static var codeNameScripts:ScriptPack;

	public static function init()
	{
		FlxG.signals.focusGained.add(function() {
			call("focusGained");
		});
		
		FlxG.signals.focusLost.add(function() {
			call("focusLost");
		});
		
		FlxG.signals.gameResized.add(function(w:Int, h:Int) {
			call("gameResized", [w, h]);
		});
		
		FlxG.signals.postDraw.add(function() {
			call("postDraw");
		});
		
		FlxG.signals.postGameReset.add(function() {
			call("postGameReset");
		});
		
		FlxG.signals.postGameStart.add(function() {
			call("postGameStart");
		});
		
		FlxG.signals.postStateSwitch.add(function() {
			call("postStateSwitch");
		});
		
		FlxG.signals.postUpdate.add(function() {
			call("postUpdate", [FlxG.elapsed]);
			if (FlxG.keys.justPressed.F5)
			{
				if (codeNameScripts != null && codeNameScripts.scripts.length > 0)
				{
					trace('Reloading global scripts...');
					for (script in codeNameScripts.scripts)
						if (script != null && script.active) script.reload();
					trace('Global scripts successfully reloaded.');
				}
			}
		});
		
		FlxG.signals.preDraw.add(function() {
			call("preDraw");
		});
		
		FlxG.signals.preGameReset.add(function() {
			call("preGameReset");
		});
		
		FlxG.signals.preGameStart.add(function() {
			call("preGameStart");
		});
		
		FlxG.signals.preStateCreate.add(function(state:FlxState) {
			call("preStateCreate", [state]);
		});
		
		FlxG.signals.preStateSwitch.add(function() {
			call("preStateSwitch", []);
		});
		
		FlxG.signals.preUpdate.add(function() {
			call("preUpdate", [FlxG.elapsed]);
			call("update", [FlxG.elapsed]);
		});
		
		// Load global scripts
		loadGlobalScripts();
	}

	public static function loadGlobalScripts()
	{
		codeNameScripts = new ScriptPack("GlobalScripts");
		
		#if MODS_ALLOWED
		var scriptPath:String = 'scripts/global';
		var paths:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), scriptPath);
		
		for (folder in paths)
		{
			#if sys
			if (sys.FileSystem.exists(folder) && sys.FileSystem.isDirectory(folder))
			{
				for (file in sys.FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.hx') || file.endsWith('.hscript') || file.endsWith('.hsc') || file.endsWith('.hxs'))
					{
						var fullPath = haxe.io.Path.join([folder, file]);
						trace('Loading global script: $fullPath');
						var script = Script.create(fullPath);
						if (script != null)
						{
							codeNameScripts.add(script);
							script.load();
						}
					}
				}
			}
			#end
		}
		#end
		
		trace('Loaded ${codeNameScripts.scripts.length} global script(s)');
	}

	public static function call(name:String, ?args:Array<Dynamic>)
	{
		if (codeNameScripts != null && codeNameScripts.scripts.length > 0)
		{
			for (script in codeNameScripts.scripts)
			{
				if (script != null && script.active) script.call(name, args);
			}
		}
	}
}
#end
