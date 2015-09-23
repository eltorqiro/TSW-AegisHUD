

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.AddonUtils.MovieClipHelper {
	
	private function MovieClipHelper() { }
	
	/**
	 * creates an empty movieclip from a class, without needing it to be linked to a symbol in the library
	 * - class definitions used by this method must contain a public static string __className which uniquely identifies the class, minus the "__Packages." prefix
	 * - instances created this way fully support duplicateMovieClip
	 * - the class can attach its own internal movieclips to display visual elements
	 * 
	 * @param	symbol		symbol linkage id to attach inside the newly created movie, called m_Symbol
	 * @param	classRef	must contain a static var __className containing the fully qualified path of the class
	 * @param	name
	 * @param	parent
	 * @param	depth
	 * @param	initObj
	 * 
	 * @return
	 */
	public static function createMovieWithClass( classRef:Function, name:String, parent:MovieClip, depth:Number, initObj:Object ) : Object {
		
		if ( parent == undefined || classRef.__className == undefined ) return;
		if ( depth == undefined ) depth = parent.getNextHighestDepth();
		if ( name == undefined || name == "" ) name = classRef.__className.split(".").join("_") + "_" + parent.getNextHighestDepth();
		
		Object.registerClass( "__Packages." + classRef.__className, classRef );
		return parent.attachMovie( "__Packages." + classRef.__className, name, depth, initObj );
		
	}

	/**
	 * attaches a symbol from the library, and links it to a class
	 * - instances created this way do not support duplicateMovieClip, which will duplicate a raw movieclip (or whatever class the symbol was originally linked to in the library)
	 * 
	 * @param	id
	 * @param	classRef
	 * @param	name
	 * @param	parent
	 * @param	depth
	 * @param	initObj
	 * 
	 * @return
	 */
	public static function attachMovieWithClass( id:String, classRef:Function, name:String, parent:MovieClip, depth:Number, initObj:Object ) : Object {
		
		var mc:MovieClip = parent.attachMovie( id, name, depth, initObj );
		mc.__proto__ = classRef.prototype;
		
		// trigger constructor
		classRef.apply(mc);
		
		// trigger onLoad, since the timeline has already called onLoad on the originally attached movieclip and won't do so again
		mc.onLoad();

		return mc;
   }

	
	/*
	 * internal variables
	 */

	/*
	 * properties
	 */
	
}