import flash.geom.ColorTransform;

import com.GameInterface.UtilsBase;


/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.AddonUtils.CommonUtils {
	
	private function CommonUtils() { }
	
	/**
	 * find an element
	 * 
	 * @param	id			custom id used by the caller to uniquely identify their call
	 * @param	path		path to the "thing" - will be eval'd to discover if it exists
	 * @param	interval
	 * @param	timeout
	 * @param	success		callback if thing is found
	 * @param	failure		callback if thing isn't found after timeout has passed
	 * 
	 * @return	
	 */
	public static function findThing( id:String, path:String, interval:Number, timeout:Number, success:Function, failure:Function ) : Void {
	
		// setup search memory if it doesn't exist or an external source is asking it to be restarted
		if ( findThingTimers[id] == undefined || path != undefined ) {
			
			cancelFindThing( id );
			
			findThingTimers[id] = {
				id: id,
				path: path,
				interval: interval,
				timeout: timeout,
				success: success,
				failure: failure,
				
				start: new Date(),
				timerId: undefined
			};
		}
		
		var timer:Object = findThingTimers[id];
		
		// try to find element at path
		var thing = eval( timer.path );

		// if thing is found, trigger success callback
		if ( thing != undefined ) {
			timer.success( timer.id, thing, true );
			delete findThingTimers[id];
		}

		// if it isn't found
		else {
			
			// if timer should hasn't expired, look again
			if ( (new Date()) - timer.start < timer.timeout ) {
				timer.timerId = setTimeout( findThing, timer.interval, timer.id );
			}
			
			// otherwise trigger failure, thing wasn't found in time
			else {
				timer.failure( timer.id, timer.path, false );
				delete findThingTimers[id];
				
			}
			
		}

	}
	
	/**
	 * cancel a running findThing instance
	 * 
	 * @param	id
	 */
	public static function cancelFindThing( id:String ) : Void {
		
		clearTimeout( findThingTimers[id].timerId );
		delete findThingTimers[id];
	}
	
	/**
	 * Colorize movieclip using color multiply method rather than flat color
	 * 
	 * Courtesy of user "bummzack" at http://gamedev.stackexchange.com/a/51087
	 * 
	 * @param	object The object to colorizee
	 * @param	color Color to apply
	 */	
	public static function colorize(object:MovieClip, color:Number):Void {
		// get individual color components 0-1 range
		var r:Number = ((color >> 16) & 0xff) / 255;
		var g:Number = ((color >> 8) & 0xff) / 255;
		var b:Number = ((color) & 0xff) / 255;

		// get the color transform and update its color multipliers
		var ct:ColorTransform = object.transform.colorTransform;
		ct.redMultiplier = r;
		ct.greenMultiplier = g;
		ct.blueMultiplier = b;

		// assign transform back to sprite/movieclip
		object.transform.colorTransform = ct;
	}	
	
	/**
	 * Scans the _global.Enums object for an Enum with the "path" containing the find string
	 * 
	 * @param	find	string to find in the entire Enum path, leave empty to print the entire nested list
	 */
	public static function findGlobalEnum(find:String) {
		
		if ( find == "" ) find = undefined;
		
		var enumPaths:Array = [ "" ];
		var enums:Array = [ _global.Enums ];
		
		var theEnum = _global.Enums;
		var enumPath = "";
		
		var foundCount:Number = 0;
		
		var findText:String = find != undefined ? find : "[all names]";
		UtilsBase.PrintChatText('<br />');
		UtilsBase.PrintChatText('In _global.Enums, matching <font color="#00ccff">' + findText + "</font><br /><br />");
		
		while ( enums.length ) {
		
			for ( var s:String in theEnum ) {
				
				// push onto stack if it is another Enum blob node
				if ( theEnum[s] instanceof Object ) {
					enums.push( theEnum[s] );
					enumPaths.push( enumPath + "." + s );
				}
				
				// handle value node
				else {
					var varName = enumPath + "." + s;
					// case-insensitive find
					if ( find == undefined || varName.toLowerCase().indexOf( find.toLowerCase() ) > -1 ) {
						foundCount++;
						UtilsBase.PrintChatText( varName + ": " + theEnum[s] );
					}
					
				}
			}
			
			theEnum = enums.pop();
			enumPath = enumPaths.pop();
		}

		UtilsBase.PrintChatText("<br />");		
		UtilsBase.PrintChatText('Found <font color="#00ff00">' + foundCount + '</font> matching <font color="#00ccff">' + findText + '</font>');
	}
	
	/*
	 * internal variables
	 */

	private static var findThingTimers:Object = { };
	
	/*
	 * properties
	 */
	
}