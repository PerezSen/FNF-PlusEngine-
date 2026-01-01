package backend;

import flixel.FlxState;
import backend.PsychCamera;
import debug.TraceDisplay;

class MusicBeatState extends FlxState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	public var controls(get, never):Controls;
	private function get_controls()
	{
		return Controls.instance;
	}

	public var touchPad:TouchPad;
	public var touchPadCam:FlxCamera;
	public var mobileControls:IMobileControls;
	public var mobileControlsCam:FlxCamera;

	public function addTouchPad(DPad:String, Action:String)
	{
		touchPad = new TouchPad(DPad, Action);
		add(touchPad);
	}

	public function removeTouchPad()
	{
		if (touchPad != null)
		{
			remove(touchPad);
			touchPad = FlxDestroyUtil.destroy(touchPad);
		}

		if(touchPadCam != null)
		{
			FlxG.cameras.remove(touchPadCam);
			touchPadCam = FlxDestroyUtil.destroy(touchPadCam);
		}
	}

	public function addMobileControls(defaultDrawTarget:Bool = false):Void
	{
		var extraMode = MobileData.extraActions.get(ClientPrefs.data.extraButtons);

		switch (MobileData.mode)
		{
			case 0: // RIGHT_FULL
				mobileControls = new TouchPad('RIGHT_FULL', 'NONE', extraMode);
			case 1: // LEFT_FULL
				mobileControls = new TouchPad('LEFT_FULL', 'NONE', extraMode);
			case 2: // CUSTOM
				mobileControls = MobileData.getTouchPadCustom(new TouchPad('RIGHT_FULL', 'NONE', extraMode));
			case 3: // HITBOX
				mobileControls = new Hitbox(extraMode);
		}

		mobileControls.instance = MobileData.setButtonsColors(mobileControls.instance);
		mobileControlsCam = new FlxCamera();
		mobileControlsCam.bgColor.alpha = 0;
		FlxG.cameras.add(mobileControlsCam, defaultDrawTarget);

		mobileControls.instance.cameras = [mobileControlsCam];
		mobileControls.instance.visible = false;
		add(mobileControls.instance);
	}

	public function removeMobileControls()
	{
		if (mobileControls != null)
		{
			remove(mobileControls.instance);
			mobileControls.instance = FlxDestroyUtil.destroy(mobileControls.instance);
			mobileControls = null;
		}

		if (mobileControlsCam != null)
		{
			FlxG.cameras.remove(mobileControlsCam);
			mobileControlsCam = FlxDestroyUtil.destroy(mobileControlsCam);
		}
	}

	public function addTouchPadCamera(defaultDrawTarget:Bool = false):Void
	{
		if (touchPad != null)
		{
			touchPadCam = new FlxCamera();
			touchPadCam.bgColor.alpha = 0;
			FlxG.cameras.add(touchPadCam, defaultDrawTarget);
			touchPad.cameras = [touchPadCam];
		}
	}

	override function destroy()
	{
		removeTouchPad();
		removeMobileControls();
		
		// Clear state scripts
		#if HSCRIPT_ALLOWED
		StateScriptHandler.callOnStateScripts('onDestroy', []);
		StateScriptHandler.clearStateScripts();
		#end
		
		// Cleanup TraceDisplay si esta es la última instancia
		if(traceDisplay != null) {
			// Solo destruir si no hay otros estados activos
			// En la práctica, el TraceDisplay debe persistir entre estados
		}
		
		super.destroy();
	}

	var _psychCameraInitialized:Bool = false;

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var videoHandlers:Map<String, Dynamic> = new Map<String, Dynamic>(); // Separar videos de variables normales

	/**
	 * Categorized variable system for State-specific scripts (StateScriptHandler)
	 * This is used ONLY by State scripts, NOT by PlayState mod scripts
	 * Categories: Video, Text, Camera, Character, Icon, Sound, Graphic, Tween, Timer, Custom, Instance, Shader, Save, Group
	 **/
	public var stateVariables:Map<String, Map<String, Dynamic>> = [
		"Video" => new Map<String, Dynamic>(),
		"Text" => new Map<String, Dynamic>(),
		"Camera" => new Map<String, Dynamic>(),
		"Character" => new Map<String, Dynamic>(),
		"Icon" => new Map<String, Dynamic>(),
		"Sound" => new Map<String, Dynamic>(),
		"Graphic" => new Map<String, Dynamic>(),
		"Tween" => new Map<String, Dynamic>(),
		"Timer" => new Map<String, Dynamic>(),
		"Custom" => new Map<String, Dynamic>(),
		"Instance" => new Map<String, Dynamic>(),
		"Shader" => new Map<String, Dynamic>(),
		"Save" => new Map<String, Dynamic>(),
		"Group" => new Map<String, Dynamic>()
	];

	public static var traceDisplay:TraceDisplay;
	
	// Helper functions for PlayState mod scripts (simple system)
	public static function getVariables()
		return getState().variables;
		
	public static function getVideoHandlers()
		return getState().videoHandlers;
	
	// Helper functions for State scripts (categorized system)
	public static function getStateVariables(?type:String = "Custom")
		return getState().stateVariables.get(type);
	
	public static function getStateVariable(obj:String, ?types:Array<String> = null):Dynamic
	{
		if (types == null) types = getStateVariableTypes();
		for (varType in types)
		{
			if (getStateVariables(varType).exists(obj))
				return getStateVariables(varType).get(obj);
		}
		return null;
	}
	
	public static function setStateVariable(name:String, value:Dynamic, ?category:String = null):Void
	{
		if (category == null)
		{
			// Auto-detect category
			var className = value != null ? Type.getClassName(Type.getClass(value)) : null;
			category = "Custom";
			
			if (className != null) {
				if (className.contains("VideoSprite") || className.contains("VideoHandler") || className.contains("MP4Handler"))
					category = "Video";
				else if (className.contains("FlxText") || className.contains("Alphabet"))
					category = "Text";
				else if (className.contains("Camera"))
					category = "Camera";
				else if (className.contains("Character"))
					category = "Character";
				else if (className.contains("HealthIcon"))
					category = "Icon";
				else if (className.contains("FlxSound"))
					category = "Sound";
				else if (className.contains("FlxSprite") || className.contains("FlxAnimate"))
					category = "Graphic";
				else if (className.contains("FlxTween"))
					category = "Tween";
				else if (className.contains("FlxTimer"))
					category = "Timer";
				else if (className.contains("Shader"))
					category = "Shader";
				else if (className.contains("Group"))
					category = "Group";
			}
		}
		
		getStateVariables(category).set(name, value);
	}
	
	public static function getStateVariableTypes():Array<String>
	{
		var list:Array<String> = [];
		for (key in getState().stateVariables.keys())
			list.push(key);
		return list;
	}

	override function create() {
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if(!_psychCameraInitialized) initPsychCamera();
		
		// Inicializar TraceDisplay si no existe
		if(traceDisplay == null && TraceDisplay.instance == null) {
			traceDisplay = new TraceDisplay();
			if(FlxG.stage != null) {
				FlxG.stage.addChild(traceDisplay);
			}
		} else if (TraceDisplay.instance != null) {
			// Usar la instancia existente
			traceDisplay = TraceDisplay.instance;
		}

		// Load state-specific scripts
		#if HSCRIPT_ALLOWED
		var stateName:String = Type.getClassName(Type.getClass(this)).split('.').pop();
		StateScriptHandler.loadStateScripts(stateName);
		#end

		super.create();

		if(!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
	}

	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		//trace('initialized psych camera ' + Sys.cpuTime());
		return camera;
	}

	public static var timePassedOnState:Float = 0;
	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		updateCurStep();
		updateBeat();

		// Update state scripts
		#if HSCRIPT_ALLOWED
		StateScriptHandler.updateStateScripts(elapsed);
		#end

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = backend.WindowMode.borderlessFullscreen;
		
		// Screenshot support with F5
		#if desktop
		if (FlxG.keys.justPressed.F5)
		{
			Screenshot.capture();
		}
		#end
		
		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null) {
		if(nextState == null) nextState = FlxG.state;
		if(nextState == FlxG.state)
		{
			resetState();
			return;
		}

		if(FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState() {
		if(FlxTransitionableState.skipNextTransIn) FlxG.resetState();
		else startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if(nextState == null)
			nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.7, false));
		if(nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public static function getState():MusicBeatState {
		return cast (FlxG.state, MusicBeatState);
	}

	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		#if HSCRIPT_ALLOWED
		StateScriptHandler.setOnStateScripts('curStep', curStep);
		StateScriptHandler.setOnStateScripts('curDecStep', curDecStep);
		StateScriptHandler.callOnStateScripts('onStepHit', []);
		#end

		if (curStep % 4 == 0)
			beatHit();
	}

	public var stages:Array<BaseStage> = [];
	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
		stagesFunc(function(stage:BaseStage) {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});

		#if HSCRIPT_ALLOWED
		StateScriptHandler.setOnStateScripts('curBeat', curBeat);
		StateScriptHandler.setOnStateScripts('curDecBeat', curDecBeat);
		StateScriptHandler.callOnStateScripts('onBeatHit', []);
		#end
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		stagesFunc(function(stage:BaseStage) {
			stage.curSection = curSection;
			stage.sectionHit();
		});

		#if HSCRIPT_ALLOWED
		StateScriptHandler.setOnStateScripts('curSection', curSection);
		StateScriptHandler.callOnStateScripts('onSectionHit', []);
		#end
	}

	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if(stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}