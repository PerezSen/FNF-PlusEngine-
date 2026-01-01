package;

/**
 * Enum for different script types supported by the engine
 * - SC: Slushi Custom HScript
 * - CODENAME: CodeName Engine HScript (advanced)
 * - IRIS: Psych Engine HScript (standard)
 * - LUA: Lua scripts
 */
enum abstract ScriptType(String) to String from String
{
	var SC = "SCHS";
	var CODENAME = "CODENAMEHS";
	var IRIS = "HSCRIPT-IRIS";
	var LUA = "LUA";
}
