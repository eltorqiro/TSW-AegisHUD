import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.Utils.ID32;
import com.Utils.Signal;

import com.ElTorqiro.AegisHUD.Server.AegisServerGroup;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.Server.AegisServerSlot {
	
	public function AegisServerSlot( id:String, group:AegisServerGroup ) {

		this.id = id;
		this.group = group;
		
		SignalSelectedChanged = new Signal();
		SignalItemChanged = new Signal();
		SignalXPChanged = new Signal();
	}

	/**
	 * cleans up object resources
	 */
	public function dispose() : Void {
		
		SignalSelectedChanged = null;
		SignalItemChanged = null;
		SignalXPChanged = null;
		
		item = null;
		inventoryID = null;
	}
	
	/*
	 * internal variables
	 */


	/*
	 * properties
	 */

	public var id:String;
	public var group:AegisServerGroup;
	
	public var type:String;
	
	public var item:InventoryItem;
	public var inventoryID:ID32;
	public var position:Number;
	
	public var aegisTypeName:String;
	
	public var xpRaw:Number;
	public var xpPercent:Number;

	public var next:String;
	public var prev:String;
	
	public var _selected:Boolean;
	public function get selected() : Boolean { return _selected; }
	public function set selected( value:Boolean ) : Void {
		_selected = value;
		SignalSelectedChanged.Emit();
	}
	
	public var SignalSelectedChanged:Signal;
	public var SignalItemChanged:Signal;
	public var SignalXPChanged:Signal;
}