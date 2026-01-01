package _hscript;

class Config
{
  // Enables support for custom classes in these packages.
  public static final ALLOWED_CUSTOM_CLASSES = ["flixel"];

  // Enables support for abstracts/enums in these packages.
  public static final ALLOWED_ABSTRACT_AND_ENUM = ["flixel", "openfl", "haxe.xml", "haxe.CallStack"];

  // If any of your files fail, you can blacklist specific module names here.
  public static final DISALLOW_CUSTOM_CLASSES = [];

  public static final DISALLOW_ABSTRACT_AND_ENUM = [];
}
