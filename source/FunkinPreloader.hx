import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxBar;
import haxe.Timer;
import backend.shaders.VFDOverlay;
import backend.MusicBeatState;
import backend.WeekData;
import backend.Paths;
import backend.CoolUtil;

/**
 * Global preloader for the engine
 * Enhanced asset preloader with parsing stages similar to base game
 * Uses MusicBeatState for desktop compatibility
 */
class FunkinPreloader extends MusicBeatState
{
	public function new()
	{
		super();
	}
	
	var vfdOverlay:FlxSprite;
	var vfdShader:VFDOverlay;
	var loadingBar:FlxBar;
	var loadedText:FlxText;
	var stageText:FlxText;
	
	var assetsToLoad:Array<{song:String, modFolder:String}> = [];
	var currentAsset:Int = 0;
	var totalAssets:Int = 0;
	
	var loadedAssets:Int = 0;
	var failedAssets:Int = 0;
	
	// Preload states
	var currentState:PreloaderState = PreloaderState.CachingAssets;
	var stateStartTime:Float = 0;
	var stateProgress:Float = 0;

	// Map of preloaded instrumentals by song name -> Sound
	public static var preloadedInsts:Map<String, Dynamic> = new Map<String, Dynamic>();

	// Preview control
	public static var previewSound:Dynamic = null;
	public static var previewTimer:Timer = null;

	// Remember if music was playing before preview so we can resume
	public static var prevMusicWasPlaying:Bool = false;

	public static function startPreview(song:String, ?volume:Float = 0.6, ?durationMs:Int = 30000):Bool
	{
		if (!preloadedInsts.exists(song)) return false;
		try
		{
			// stop any existing preview
			stopPreview();
			var snd = preloadedInsts.get(song);
			if(snd == null) return false;
			// Pause main music if it's playing, remember state
			if (FlxG.sound.music != null && FlxG.sound.music.playing)
			{
				prevMusicWasPlaying = true;
				try { FlxG.sound.music.pause(); } catch(e:Dynamic) {}
			}
			// play as non-music sound so it doesn't override music channel
			previewSound = FlxG.sound.play(snd, volume);
			if(durationMs > 0)
			{
				previewTimer = Timer.delay(function() {
					stopPreview();
				}, durationMs);
			}
			return true;
		}
		catch(e:Dynamic)
		{
			trace('Error starting preview: $e');
			return false;
		}
	}

	public static function stopPreview():Void
	{
		try
		{
			if(previewTimer != null) { previewTimer.stop(); previewTimer = null; }
			if(previewSound != null) { previewSound.stop(); previewSound = null; }

			// Resume main music if it was playing before preview
			if (prevMusicWasPlaying && FlxG.sound.music != null)
			{
				try { FlxG.sound.music.resume(); } catch(e:Dynamic) {}
				prevMusicWasPlaying = false;
			}
		}
		catch(e:Dynamic)
		{
			trace('Error stopping preview: $e');
		}
	}
	
	
	override function create():Void
	{
		super.create();

		// Ensure WeekData is loaded
		WeekData.reloadWeekFiles(false);
		
		// Black background
		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.scrollFactor.set();
		add(bg);
		
		// VFD overlay shader effect (replaces funkay logo)
		vfdOverlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		vfdOverlay.scrollFactor.set();
		vfdShader = new VFDOverlay();
		vfdOverlay.shader = vfdShader;
		add(vfdOverlay);
		
		// Loading bar
		loadingBar = new FlxBar(0, FlxG.height - 50, LEFT_TO_RIGHT, Std.int(FlxG.width * 0.8), 20, this, 'stateProgress', 0, 1);
		loadingBar.screenCenter(X);
		loadingBar.createFilledBar(0xFF000000, 0xFF00FF00);
		add(loadingBar);
		
		// Stage text (what we're currently doing)
		stageText = new FlxText(0, loadingBar.y - 55, FlxG.width, "Initializing...", 20);
		stageText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.YELLOW, CENTER);
		add(stageText);
		
		// Loading text (current item)
		loadedText = new FlxText(0, loadingBar.y - 30, FlxG.width, "Loading...", 16);
		loadedText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		add(loadedText);
		
		// Collect assets
		collectAssets();
		stateStartTime = 0;
	}
	
	function collectAssets():Void
	{
		trace('Collecting assets to preload...');

		// Base game songs
		#if (MODS_ALLOWED)
		for (weekName in WeekData.weeksList)
		{
			var week:WeekData = WeekData.weeksLoaded.get(weekName);
			if (week != null)
			{
				var modFolder = week.folder != null ? week.folder : '';
				trace('[Preloader]: Week "$weekName" - Mod: ${modFolder != '' ? modFolder : "BASE_GAME"}');
				for (song in week.songs)
				{
					if (song != null && song.length > 0)
					{
						var songName = song[0]; // song[0] is the song name
						trace('[Preloader]:   Song: "$songName" from week "$weekName" (Mod: $modFolder)');
						
						// Check if already added
						var alreadyExists = false;
						for (asset in assetsToLoad)
						{
							if (asset.song == songName)
							{
								alreadyExists = true;
								break;
							}
						}
						
						if (!alreadyExists)
						{
							assetsToLoad.push({song: songName, modFolder: modFolder});
						}
					}
				}
			}
		}
		#else
		for (weekName in WeekData.weeksList)
		{
			var week:WeekData = WeekData.weeksLoaded.get(weekName);
			if (week != null)
			{
				for (song in week.songs)
				{
					if (song != null && song.length > 0)
					{
						var alreadyExists = false;
						for (asset in assetsToLoad)
						{
							if (asset.song == song[0])
							{
								alreadyExists = true;
								break;
							}
						}
						
						if (!alreadyExists)
						{
							assetsToLoad.push({song: song[0], modFolder: ''});
						}
					}
				}
			}
		}
		#end

		totalAssets = assetsToLoad.length;
		trace('Total assets to load: $totalAssets');
	}
	
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		// Update VFD shader animation
		if (vfdShader != null)
			vfdShader.update(elapsed);
		
		stateStartTime += elapsed;
		
		switch (currentState)
		{
			case PreloaderState.CachingAssets:
				// Load instrumentals one per frame for smooth animation
				if (currentAsset < totalAssets)
				{
					var asset = assetsToLoad[currentAsset];
					var songName:String = asset.song;
					var modFolder:String = asset.modFolder;
					
					stageText.text = 'Caching Instrumentals... (${currentAsset + 1}/$totalAssets)';
					loadedText.text = 'Loading: $songName';
					
					// Set the current mod directory before loading
					#if MODS_ALLOWED
					var oldModDirectory = Mods.currentModDirectory;
					if (modFolder != null && modFolder.length > 0)
					{
						Mods.currentModDirectory = modFolder;
						trace('[Preloader]: Setting mod directory to: $modFolder');
					}
					#end
					
					// Attempt to load the instrumental
					var formattedPath = Paths.formatToSongPath(songName);
					var soundKey = '$formattedPath/Inst';
					
					trace('[Preloader]: Attempting to load inst for: $songName');
					trace('[Preloader]: Formatted path: $formattedPath');
					trace('[Preloader]: Sound key: $soundKey');
					trace('[Preloader]: Mod folder: ${modFolder != '' ? modFolder : "BASE_GAME"}');
					
					// Get the full file path to see where it's searching
					var fullPath = Paths.getPath('$soundKey.${Paths.SOUND_EXT}', SOUND, 'songs', true);
					trace('[Preloader]: Full path attempt: $fullPath');
					
					var loadedInst = Paths.returnSound(soundKey, 'songs', true, false);
					
					#if MODS_ALLOWED
					// Restore old mod directory
					Mods.currentModDirectory = oldModDirectory;
					#end
					
					if (loadedInst != null)
					{
						preloadedInsts.set(songName, loadedInst);
						trace('[Preloader]: ✓ Cached inst: $songName');
						loadedAssets++;
					}
					else
					{
						// Only log as failed if truly not found (null returned)
						trace('[Preloader]: ✗ Inst not found: $songName');
						failedAssets++;
					}
					
					currentAsset++;
					stateProgress = currentAsset / totalAssets;
				}
				else
				{
					// Move to next state
					currentState = PreloaderState.ParsingCharacters;
					stateStartTime = 0;
					stateProgress = 0;
					trace('Assets cached! Moving to parsing characters...');
					
					// Clear the assets array to free memory
					assetsToLoad = null;
					
					// Force garbage collection if available
					#if cpp
					cpp.vm.Gc.run(true);
					#elseif hl
					hl.Gc.major();
					#end
				}
			
			case PreloaderState.ParsingCharacters:
				stageText.text = 'Parsing Characters...';
				loadedText.text = 'Validating character metadata...';
				
				parseCharacters();
				
				currentState = PreloaderState.ParsingStages;
				stateStartTime = 0;
				stateProgress = 0.33;
			
			case PreloaderState.ParsingStages:
				stageText.text = 'Parsing Stages...';
				loadedText.text = 'Validating stage metadata...';
				
				parseStages();
				
				currentState = PreloaderState.ParsingSongs;
				stateStartTime = 0;
				stateProgress = 0.66;
			
			case PreloaderState.ParsingSongs:
				stageText.text = 'Parsing Songs...';
				loadedText.text = 'Counting song metadata...';
				
				parseSongs();
				
				currentState = PreloaderState.Complete;
				stateStartTime = 0;
				stateProgress = 1.0;
			
			case PreloaderState.Complete:
				stageText.text = 'Complete!';
				loadedText.text = 'Ready!';
				trace('Complete! Loaded: $loadedAssets / Failed: $failedAssets');
				
				// Wait a bit then go to TitleState
				if (stateStartTime > 0.5)
				{
					FlxG.switchState(new states.TitleState());
				}
		}
		
		// Allow skipping with ENTER
		if (FlxG.keys.justPressed.ENTER && stateProgress >= 0.5)
		{
			FlxG.switchState(new states.TitleState());
		}
	}
	
	function parseCharacters():Void
	{
		trace('Parsing character metadata...');
		// Only validate file existence, don't load JSONs to RAM
		// The base game only parses metadata, not full character data
		try
		{
			var characterList:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));
			trace('Found ${characterList.length} characters to validate');
		}
		catch (e:Dynamic)
		{
			trace('No characterList.txt found (this is optional)');
		}
	}
	
	function parseStages():Void
	{
		trace('Parsing stage metadata...');
		// Only validate file existence, don't load JSONs to RAM
		try
		{
			var stageList:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));
			trace('Found ${stageList.length} stages to validate');
		}
		catch (e:Dynamic)
		{
			trace('No stageList.txt found (this is optional)');
		}
	}
	
	function parseSongs():Void
	{
		trace('Parsing song metadata...');
		// The base game only counts songs, doesn't load full chart data to RAM
		// Loading all charts would cause massive RAM usage
		try
		{
			var songCount:Int = 0;
			for (weekName in WeekData.weeksList)
			{
				var week:WeekData = WeekData.weeksLoaded.get(weekName);
				if (week != null)
				{
					songCount += week.songs.length;
				}
			}
			trace('Found $songCount songs across ${WeekData.weeksList.length} weeks');
		}
		catch (e:Dynamic)
		{
			trace('Error counting songs: $e');
		}
	}
	
	override function destroy():Void
	{
		super.destroy();
		
		// Clean up
		vfdOverlay = null;
		vfdShader = null;
		loadingBar = null;
		loadedText = null;
		stageText = null;
		assetsToLoad = null;
		
		// Note: preloadedInsts is static and should persist for FreeplayState to use
	}
}

/**
 * Preloader states enum
 */
enum PreloaderState
{
	CachingAssets;
	ParsingCharacters;
	ParsingStages;
	ParsingSongs;
	Complete;
}
