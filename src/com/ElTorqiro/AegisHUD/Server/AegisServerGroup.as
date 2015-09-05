import com.ElTorqiro.AegisHUD.Server.AegisServerSlot;
import com.Utils.Signal;


/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.Server.AegisServerGroup {
	
	public function AegisServerGroup( id:String, type:String ) {
		
		this.id = id;
		this.type = type;
		this.slots = new Object();
		
		var slotList:Array = [ "item", "aegis1", "aegis2", "aegis3" ];
		for ( var s:String in slotList ) {
			this.slots[ slotList[s] ] = new AegisServerSlot( slotList[s], this );
		}
		
		SignalSelectedSlotChanged = new Signal();
	}

	/**
	 * cleans up object resources
	 */
	public function dispose() : Void {

		SignalSelectedSlotChanged = null;
		
		for ( var s:String in slots ) {
			slots[s].dispose();
		}
		
		slots = null;
		selectedSlot = null;
	}
	
	/*
	 * internal variables
	 */
	
	/*
	 * properties
	 */

	public var id:String;
	public var type:String;
	public var slots:Object;

	public var activeSlot:AegisServerSlot;
	
	private var _selectedSlot:AegisServerSlot;
	public function get selectedSlot() : AegisServerSlot { return _selectedSlot; }
	public function set selectedSlot( value:AegisServerSlot ) : Void {
		_selectedSlot = value;
		SignalSelectedSlotChanged.Emit();
	}
	
	public var SignalSelectedSlotChanged:Signal;
}