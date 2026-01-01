package lenin;

/**
 * Gestor del sistema de Heavy Charts
 * Controla la activación y desactivación del modo de charts pesados
 * 
 * MEMORIA DINÁMICA:
 * - Cachea notas agresivamente basado en RAM disponible
 * - Usa ~0.5MB por nota aproximadamente
 * - Permite usar hasta 75% de RAM disponible para caché de notas
 */
class HeavyChartManager
{
	/**
	 * Determina si el heavy chart mode debe activarse
	 */
	public static function shouldUseHeavyCharts():Bool
	{
		// Verificar si está activado en las preferencias del cliente
		return ClientPrefs.data.heavyCharts == true;
	}

	/**
	 * Obtiene la memoria total disponible en bytes
	 */
	private static function getTotalMemory():Int
	{
		// Obtener RAM total disponible del sistema
		return Std.int(openfl.system.System.totalMemory);
	}

	/**
	 * Obtiene la memoria actual en bytes usando el GC de Haxe
	 */
	private static function getCurrentMemory():Int
	{
		#if cpp
		return Std.int(cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE));
		#else
		// Fallback para otras plataformas
		return Std.int(openfl.system.System.totalMemory * 0.5);
		#end
	}

	/**
	 * Calcula el límite dinámico de notas basado en RAM disponible
	 * Esto permite cachear más notas si el sistema tiene más RAM
	 */
	public static function getDynamicNoteLimit():Int
	{
		if (!shouldUseHeavyCharts())
			return 150; // Límite normal si heavy charts está desactivado

		// Obtener RAM total disponible del sistema
		var totalRAM:Int = getTotalMemory();
		
		// Calcular cuánta RAM se puede usar para caché de notas (50% del total)
		// Ya que necesitamos espacio para otros procesos
		// Estimación: ~500KB por nota (incluyendo struct + overhead)
		var ramForNoteCache:Int = Std.int(totalRAM * 0.5);
		var bytesPerNote:Int = 500; // Bytes aproximados por nota
		
		// Calcular el límite dinámico
		var dynamicLimit:Int = Std.int(ramForNoteCache / bytesPerNote);
		
		// Mínimo 200 notas, máximo 2000 notas (evitar extremos)
		dynamicLimit = Std.int(Math.min(2000, Math.max(200, dynamicLimit)));
		
		var totalRAMMB:Int = Std.int(totalRAM / (1024 * 1024));
		var cacheBudgetMB:Int = Std.int(ramForNoteCache / (1024 * 1024));
		
		return dynamicLimit;
	}

	/**
	 * Obtiene el límite de notas renderizadas simultáneamente (fallback estático)
	 */
	public static function getNoteRenderLimit():Int
	{
		// Mayor límite para heavy charts
		return shouldUseHeavyCharts() ? 300 : 150;
	}

	/**
	 * Obtiene el tiempo de spawn dinámico de notas
	 */
	public static function getDynamicSpawnTime():Bool
	{
		return ClientPrefs.getGameplaySetting('dynamicSpawnTime', true) == true;
	}

	/**
	 * Obtiene el multiplicador de tiempo de spawn
	 */
	public static function getNoteSpawnTimeMultiplier():Float
	{
		return ClientPrefs.getGameplaySetting('noteSpawnTime', 0.5);
	}

	/**
	 * Calcula el uso de memoria estimado de las notas
	 * Estimación: ~500KB por nota (struct + overhead de Flixel)
	 */
	public static function estimateMemoryUsage(noteCount:Int):String
	{
		// 500 bytes por nota aproximadamente
		var bytes:Float = noteCount * 500;
		var mb:Float = bytes / (1024 * 1024);
		return Math.round(mb * 100) / 100 + " MB";
	}

	/**
	 * Logea información sobre el chart cargado
	 */
	public static function logChartInfo(songName:String, noteCount:Int, useHeavy:Bool):Void
	{
		if (useHeavy)
		{
			var totalRAM:Int = getTotalMemory();
			var totalRAMMB:Int = Std.int(totalRAM / (1024 * 1024));
			var cacheBudgetMB:Int = Std.int((totalRAM * 0.5) / (1024 * 1024));
		}
	}

	/**
	 * Limpia las notas precargadas para liberar memoria
	 */
	public static function cleanupPreloadedNotes(unspawnNotes:Array<PreloadedChartNote>):Void
	{
		for (note in unspawnNotes)
		{
			if (note != null)
				note.dispose();
		}
		unspawnNotes = [];
		openfl.system.System.gc();
	}

	/**
	 * Obtiene estadísticas del chart actual
	 */
	public static function getChartStats(unspawnNotes:Array<PreloadedChartNote>):Dynamic
	{
		var stats = {
			totalNotes: unspawnNotes.length,
			normalNotes: 0,
			sustainNotes: 0,
			avgDensity: 0.0,
			maxDensity: 0.0
		};

		var densitySum:Float = 0;

		for (note in unspawnNotes)
		{
			if (note.isSustainNote)
				stats.sustainNotes++;
			else
				stats.normalNotes++;

			densitySum += 1;
			if (stats.maxDensity < 1)
				stats.maxDensity = 1;
		}

		if (stats.totalNotes > 0)
			stats.avgDensity = Math.round((densitySum / stats.totalNotes) * 100) / 100;

		return stats;
	}
}
