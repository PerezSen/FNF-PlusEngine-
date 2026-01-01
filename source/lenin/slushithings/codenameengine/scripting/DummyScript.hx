package lenin.slushithings.codenameengine.scripting;

/**
 * Dummy script class for unsupported file types
 */
class DummyScript extends Script
{
	public function new(path:String)
	{
		super(path);
		trace('DummyScript created for: $path (unsupported file type)');
	}

	override public function load()
	{
		// Do nothing
	}

	override public function reload()
	{
		// Do nothing
	}

	override public function set(name:String, val:Dynamic)
	{
		// Do nothing
	}

	override public function get(name:String):Dynamic
	{
		return null;
	}

	override public function call(name:String, ?args:Array<Dynamic>):Dynamic
	{
		return null;
	}

	override public function loadFromString(str:String):Script
	{
		return this;
	}
}
