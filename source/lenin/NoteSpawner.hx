package lenin;

import flixel.FlxG;
import objects.Note;
import states.PlayState;

/**
 * Sistema de spawning dinámico para notas
 * Convierte PreloadedChartNote a Note solo cuando está cerca de ser ejecutada
 */
class NoteSpawner
{
	/**
	 * Spawnea notas que están cerca de ser ejecutadas
	 * @param unspawnNotes Array de notas sin spawnar
	 * @param notesAddedCount Índice actual de notas agregadas
	 * @param gameplayGroup Grupo donde agregar las notas (notas normales o sustains)
	 * @param playState Instancia de PlayState
	 * @return Índice actualizado de notas agregadas
	 */
	public static function spawnNotes(
		unspawnNotes:Array<PreloadedChartNote>,
		notesAddedCount:Int,
		gameplayGroup:flixel.group.FlxTypedGroup<Note>,
		playState:PlayState
	):Int
	{
		if (unspawnNotes.length == 0 || notesAddedCount >= unspawnNotes.length)
			return notesAddedCount;

		var NOTE_SPAWN_TIME:Float = 
			(ClientPrefs.getGameplaySetting('dynamicSpawnTime', false) ? 
				(1600 / playState.songSpeed) : 
				1600 * ClientPrefs.getGameplaySetting('noteSpawnTime', 0.5));

		var targetNote:PreloadedChartNote = unspawnNotes[notesAddedCount];
		var currentIndex:Int = notesAddedCount;

		while (currentIndex < unspawnNotes.length && targetNote != null)
		{
			targetNote = unspawnNotes[currentIndex];
			if (targetNote == null) break;

			// Solo spawnea si la nota está dentro del rango visible
			if (targetNote.strumTime - Conductor.songPosition < (NOTE_SPAWN_TIME / targetNote.multSpeed))
			{
				// Crear nota visual y transferir datos
				var newNote:Note = new Note(targetNote.strumTime, targetNote.noteData, null);
				newNote.gfNote = targetNote.gfNote;
				newNote.animSuffix = targetNote.animSuffix;
				newNote.mustPress = targetNote.mustPress;
				newNote.isOpponentMode = targetNote.isOpponentMode;
				newNote.sustainLength = targetNote.sustainLength;
				newNote.noteType = targetNote.noteType;
				newNote.isSustainNote = targetNote.isSustainNote;
				
				gameplayGroup.add(newNote);
				currentIndex++;
			}
			else
			{
				// Si no está en rango, no hay razón para seguir checando
				break;
			}
		}

		return currentIndex;
	}

	/**
	 * Skippea notas que debían ser ejecutadas pero el jugador está adelantado
	 */
	public static function skipSpawnedNotes(
		unspawnNotes:Array<PreloadedChartNote>,
		notesAddedCount:Int,
		currentTime:Float
	):Int
	{
		var skippedCount:Int = 0;
		var currentIndex:Int = notesAddedCount;

		while (currentIndex < unspawnNotes.length)
		{
			var targetNote:PreloadedChartNote = unspawnNotes[currentIndex];
			if (targetNote == null) break;

			if (targetNote.strumTime <= currentTime)
			{
				targetNote.wasHit = true;
				currentIndex++;
				skippedCount++;
			}
			else
			{
				break;
			}
		}

		return skippedCount > 0 ? currentIndex : notesAddedCount;
	}

	/**
	 * Convierte un array de Note en PreloadedChartNote para heavy charts
	 */
	public static function convertNotesToPreloaded(notes:Array<Note>):Array<PreloadedChartNote>
	{
		var preloaded:Array<PreloadedChartNote> = [];

		for (note in notes)
		{
			var preNote:PreloadedChartNote = new PreloadedChartNote();
			preNote.strumTime = note.strumTime;
			preNote.noteData = note.noteData;
			preNote.mustPress = note.mustPress;
			preNote.gfNote = note.gfNote;
			preNote.noteType = note.noteType;
			preNote.animSuffix = note.animSuffix;
			preNote.sustainLength = note.sustainLength;
			preNote.isSustainNote = note.isSustainNote;
			preNote.isOpponentMode = note.isOpponentMode;
			preNote.multSpeed = note.multSpeed;

			preloaded.push(preNote);
		}

		return preloaded;
	}
}
