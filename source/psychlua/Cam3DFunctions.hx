package psychlua;

class Cam3DFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		var game = PlayState.instance;

		// Set 3D Curve effect on camera
		Lua_helper.add_callback(lua, "setCam3DX", function(camera:String, value:Float) {
			if(game == null) return false;
			
			var curveEffect = getCurveEffect(camera);
			if(curveEffect != null) {
				curveEffect.curveX = value;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "setCam3DY", function(camera:String, value:Float) {
			if(game == null) return false;
			
			var curveEffect = getCurveEffect(camera);
			if(curveEffect != null) {
				curveEffect.curveY = value;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getCam3DX", function(camera:String) {
			if(game == null) return 0.0;
			
			var curveEffect = getCurveEffect(camera);
			if(curveEffect != null) {
				return curveEffect.curveX;
			}
			return 0.0;
		});

		Lua_helper.add_callback(lua, "getCam3DY", function(camera:String) {
			if(game == null) return 0.0;
			
			var curveEffect = getCurveEffect(camera);
			if(curveEffect != null) {
				return curveEffect.curveY;
			}
			return 0.0;
		});

		// Apply/Remove 3D effect on camera
		Lua_helper.add_callback(lua, "setCam3DEnabled", function(camera:String, enabled:Bool) {
			if(game == null) return false;
			if(!ClientPrefs.data.shaders) return false;

			#if !flash
			var cam:FlxCamera = getCameraFromString(camera);
			var curveEffect = getCurveEffect(camera);
			
			if(cam != null && curveEffect != null) {
				if(enabled) {
					cam.setFilters([new openfl.filters.ShaderFilter(curveEffect.shader)]);
				} else {
					cam.setFilters([]);
				}
				return true;
			}
			#end
			return false;
		});

		// Tween functions for 3D Curve effect
		Lua_helper.add_callback(lua, "doTweenCam3DX", function(tag:String, camera:String, value:Float, duration:Float, ?ease:String = 'linear') {
			if(game == null) return null;

			var curveEffect = getCurveEffect(camera);
			if(curveEffect == null) {
				FunkinLua.luaTrace('doTweenCam3DX: Invalid camera: $camera', false, false, FlxColor.RED);
				return null;
			}

			var variables = MusicBeatState.getVariables();
			if(tag != null) {
				var originalTag:String = tag;
				tag = LuaUtils.formatVariable('tween_$tag');
				variables.set(tag, FlxTween.tween(curveEffect, {curveX: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						variables.remove(tag);
						if(game != null) game.callOnLuas('onTweenCompleted', [originalTag, camera]);
					}
				}));
				return tag;
			}
			return null;
		});

		Lua_helper.add_callback(lua, "doTweenCam3DY", function(tag:String, camera:String, value:Float, duration:Float, ?ease:String = 'linear') {
			if(game == null) return null;

			var curveEffect = getCurveEffect(camera);
			if(curveEffect == null) {
				FunkinLua.luaTrace('doTweenCam3DY: Invalid camera: $camera', false, false, FlxColor.RED);
				return null;
			}

			var variables = MusicBeatState.getVariables();
			if(tag != null) {
				var originalTag:String = tag;
				tag = LuaUtils.formatVariable('tween_$tag');
				variables.set(tag, FlxTween.tween(curveEffect, {curveY: value}, duration, {
					ease: LuaUtils.getTweenEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						variables.remove(tag);
						if(game != null) game.callOnLuas('onTweenCompleted', [originalTag, camera]);
					}
				}));
				return tag;
			}
			return null;
		});
	}

	static function getCurveEffect(camera:String):shaders.CurveEffect {
		var game = PlayState.instance;
		if(game == null) return null;

		switch(camera.toLowerCase()) {
			case 'camgame' | 'game':
				return game.curveEffectGame;
			case 'camhud' | 'hud':
				return game.curveEffectHUD;
			case 'camother' | 'other':
				return game.curveEffectOther;
		}
		return null;
	}

	static function getCameraFromString(camera:String):FlxCamera {
		var game = PlayState.instance;
		if(game == null) return null;

		switch(camera.toLowerCase()) {
			case 'camgame' | 'game':
				return game.camGame;
			case 'camhud' | 'hud':
				return game.camHUD;
			case 'camother' | 'other':
				return game.camOther;
		}
		return null;
	}
}
