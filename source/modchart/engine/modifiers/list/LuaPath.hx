package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.engine.PlayField;

/**
 * A path modifier whose nodes are intended to be provided at runtime (Lua/HScript).
 *
 * Usage:
 * - Add with `addModifier('luapath')`
 * - Set nodes via Lua callback `setModifierPath('luapath', nodes, field)`
 */
class LuaPath extends PathModifier {
	public function new(pf:PlayField) {
		super(pf, []);
		pathOffset.setTo(WIDTH * 0.5, HEIGHT * 0.5, 0);
	}

	private static inline function wrapToBound(value:Float, bound:Float):Float {
		if (bound <= 0)
			return 0;
		var m = value % bound;
		if (m < 0)
			m += bound;
		return m;
	}

	override function render(pos:Vector3, params:ModifierParameters) {
		final perc = getPercent('luapath', params.player);
		if (perc == 0)
			return pos;

		// NotITG-like treadmill:
		// - The "head" (receptors) advances along the path over time.
		// - Notes/holds add their scroll distance so they populate the whole curve behind the head.
		final bound = getPathBound();
		final scrollSpeed = Adapter.instance.getCurrentScrollSpeed();
		final base = params.songTime * scrollSpeed;
		final trail = Math.max(0, params.distance * scrollSpeed);
		final rawProgress = base + (params.isTapArrow ? trail : 0);
		final progress = wrapToBound(rawProgress, bound);

		final driveParams:ModifierParameters = {
			songTime: params.songTime,
			hitTime: params.hitTime,
			distance: progress,
			curBeat: params.curBeat,
			lane: params.lane,
			player: params.player,
			isTapArrow: params.isTapArrow
		};

		pathOffset.z = pos.z;
		return computePath(pos, driveParams, perc);
	}
}
