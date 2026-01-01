package lenin.slushithings.codenameengine.scripting;

/**
 * ScriptPack - Manages multiple scripts as a single unit
 */
class ScriptPack extends Script
{
	public var scripts:Array<Script> = [];
	public var additionalDefaultVariables:Map<String, Dynamic> = [];
	public var publicVariables:Map<String, Dynamic> = [];
	public var parent:Dynamic = null;

	public override function load()
	{
		for (e in scripts)
		{
			e.load();
		}
	}

	public function contains(path:String)
	{
		for (e in scripts)
			if (e.path == path) return true;
		return false;
	}

	public function new(name:String)
	{
		additionalDefaultVariables["importScript"] = importScript;
		super(name);
	}

	public function getByPath(name:String)
	{
		for (s in scripts)
			if (s.path == name) return s;
		return null;
	}

	public function getByName(name:String)
	{
		for (s in scripts)
			if (s.fileName == name) return s;
		return null;
	}

	public function importScript(path:String):Script
	{
		var script:Script = Script.create(path);
		if (script != null)
		{
			add(script);
			script.load();
		}
		return script;
	}

	public override function call(name:String, ?args:Array<Dynamic>):Dynamic
	{
		var returnVal:Dynamic = null;
		for (s in scripts)
		{
			if (s != null && s.active)
			{
				var val = s.call(name, args);
				if (val != null)
					returnVal = val;
			}
		}
		return returnVal;
	}

	public override function set(name:String, val:Dynamic)
	{
		for (e in scripts)
			e.set(name, val);
	}

	public override function setPublicMap(map:Map<String, Dynamic>)
	{
		publicVariables = map;
		for (e in scripts)
			e.setPublicMap(map);
	}

	public override function setParent(parent:Dynamic)
	{
		this.parent = parent;
		for (e in scripts)
			e.setParent(parent);
	}

	public override function destroy()
	{
		super.destroy();
		for (e in scripts)
			e.destroy();
	}

	public override function onCreate(path:String) {}

	public function add(script:Script)
	{
		scripts.push(script);
		__configureNewScript(script);
	}

	public function remove(script:Script)
	{
		scripts.remove(script);
	}

	public function insert(pos:Int, script:Script)
	{
		scripts.insert(pos, script);
		__configureNewScript(script);
	}

	private function __configureNewScript(script:Script)
	{
		if (parent != null) script.setParent(parent);
		script.setPublicMap(publicVariables);
		for (k => e in additionalDefaultVariables)
			script.set(k, e);
	}
}
