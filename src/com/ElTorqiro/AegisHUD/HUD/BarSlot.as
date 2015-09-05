import com.ElTorqiro.AegisHUD.Server.AegisServerSlot;
import com.Utils.ID32;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import gfx.core.UIComponent;

import com.ElTorqiro.AegisHUD.Enums;
import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.Preferences;

import com.GameInterface.UtilsBase;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.BarSlot extends UIComponent {

	public function BarSlot() {

		UtilsBase.PrintChatText("barslot constructor");
		
		// setup icon loader
		clipLoader = new MovieClipLoader();
		clipLoader.addListener( this );
		
		m_Icon._visible = false;
	}
	
	public function draw() : Void {
		
	}
	
	public function dispose() : Void {
		
		clipLoader = null;
		removeAllEventListeners();
	}
	
	public function onUnload() : Void {
		dispose();
		super.onUnload();
	}
	
	private function configUI() : Void {
		
		//UtilsBase.PrintChatText("barslot configUI");
		
		// add right click handling
		this["onPressAux"] = onPress;
	}

	/**
	 * refreshes item from the server
	 */
	public function refreshItem() : Void {
		/*
		var slot:AegisServerSlot = AegisServer.getSlot( groupID, slotID );
		var item:InventoryItem = slot.item;

		if ( item ) {
		
			m_Watermark._visible = false;
			
			if ( item.m_AegisItemType && Preferences.getValue("ui.icons.type") == Enums.e_IconTypeInbuilt ) {
				
				attachMovie( slot.type + "-" + slot.aegisTypeName, "m_Icon", m_Icon.getDepth() );
				m_Icon._width = m_Icon._height = 24;
			}
			
			else {
				var iconRef:ID32 = item.m_Icon;
				clipLoader.loadClip( com.Utils.Format.Printf( "rdb:%.0f:%.0f", iconRef.GetType(), iconRef.GetInstance() ), m_Icon );
			}
		}
			
		else {
			m_Icon._visible = false;
			m_Watermark._visible = true;
		}
		
		invalidate();
		*/
	}
	
	private function onLoadStart() : Void {
		//UtilsBase.PrintChatText("onloadstart");
	}
	
	private function onLoadInit( target:MovieClip ) : Void {
		// set proper scale of target element
		target._width = target._height = 24;
	}

	private function onLoadError( target:MovieClip, errorCode:String ) : Void {
		//UtilsBase.PrintChatText("onloaderror");
	}
		
	private function onRollOver( mouseIdx:Number ) : Void {
		dispatchEvent( { type:"mouseOver" } );
	}

	private function onRollOut( mouseIdx:Number ) : Void {
		dispatchEvent( { type:"mouseOut" } );
	}
	
	/**
	 * internal variables
	 */
	
	public var m_Icon:MovieClip;
	public var m_Watermark:MovieClip;
	
	private var clipLoader:MovieClipLoader;
	
	public var groupID:String;
	public var slotID:String;

	
	/**
	 * properties
	 */
	
	// the watermark symbol name for the slot
	private var _watermark:String;
	public function get watermark() : String { return _watermark; }
	public function set watermark( value:String ) : Void {
		_watermark = value;
		
		// apply watermark to slot if present
		if ( value ) {
			attachMovie( value, "m_Watermark", m_Watermark.getDepth() );
			refreshItem();
		}
	}
	
}