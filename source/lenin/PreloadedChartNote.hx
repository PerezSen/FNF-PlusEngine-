package lenin;

/**
 * Estructura ligera para almacenar datos de notas sin crear el objeto visual Note
 * Esto permite cargar charts pesados sin problemas de memoria
 * 
 * Solo se convierten a notas visuales (Note.hx) cuando están cerca de ser ejecutadas
 */
@:structInit
class PreloadedChartNote
{
	public var strumTime:Float = 0;
	public var noteData:Int = 0;
	public var mustPress:Bool = false;
	public var gfNote:Bool = false;
	public var noteType:String = "";
	public var animSuffix:String = "";
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var parent:PreloadedChartNote = null;
	public var wasHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var lowPriority:Bool = false;
	public var multSpeed:Float = 1;
	public var isOpponentMode:Bool = false;
	
	public function new() {}
	
	/**
	 * Limpia los datos de la nota para liberar memoria
	 */
	public function dispose():Void
	{
		for (field in Reflect.fields(this))
			Reflect.setField(this, field, null);
	}
}
