import mx.utils.Delegate;
import gfx.core.UIComponent;

import com.Utils.Signal;
import com.GameInterface.Game.Character;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.GameInterface.Chat;
import com.Utils.ID32;
import com.Utils.Format;
import com.GameInterface.UtilsBase;
import com.Utils.LDBFormat;
import com.ElTorqiro.AegisHUD.Enums.AegisBarLayoutStyles;

class com.ElTorqiro.AegisHUD.AegisBar extends UIComponent
{
	// constants
	public static var AEGIS_GROUP_PRIMARY:Number = 0;
	public static var AEGIS_GROUP_SECONDARY:Number = 1;
	
	// movie clip elements
	private var m_Background:MovieClip;
	private var m_ButtonContainer:MovieClip;
	
	// movie clip shortcuts
	private var __aegisMC1:MovieClip;
	private var __aegisMC2:MovieClip;
	private var __aegisMC3:MovieClip;
	private var __weaponMC:MovieClip;
	private var __backgroundMC:MovieClip;
	private var __buttonContainerMC:MovieClip;
	
	// slot configuration values
	private var __aegisGroup:Number;
	private var __activeAegisStat:Number;
	private var __itemSlots:Object = { };

	// layout parameters
	private var __enableLayout:Boolean = true;
	private var __slotSize:Number = 30;
	private var __barPadding:Number = 5;
	private var __slotPadding:Number = 4;
	private var __weaponFirst:Boolean = true;
	private var __showBackground:Boolean = true;
	private var __showWeapon:Boolean = true;
	private var __showXPBar:Boolean = true;
	private var __showTooltip:Boolean = true;
	private var __layoutStyle:Number = 1;

	// behaviour parameters
	private var __handleDrag:Boolean = true;
	
	// utility objects
	private var __character:Character;
	private var __inventory:Inventory;
	private var __iconLoader:MovieClipLoader;
	private var __activeAegisSlot:Number;
	
	// signals
	public var SignalStartDrag:Signal;
	public var SignalStopDrag:Signal;
	
	
	// constructor
	public function AegisBar()
	{
		super();

		// visually the raw bar is quite ugly until init()
		// and besides won't do anything interesting until then, so hide it for now
		this._visible = false;
		
		// drag & click handlers
		this.onPress =  Delegate.create(this, PressHandler);
		this.onRelease = this.onReleaseOutside  = Delegate.create(this, ReleaseHandler);
		
		// movieclip shortcuts
		__aegisMC1 = m_ButtonContainer.m_Aegis1;
		__aegisMC2 = m_ButtonContainer.m_Aegis2;
		__aegisMC3 = m_ButtonContainer.m_Aegis3;
		__weaponMC = m_ButtonContainer.m_Weapon;
		__backgroundMC = m_Background;
		__buttonContainerMC = m_ButtonContainer;

		// other objects that need creating
		__iconLoader = new MovieClipLoader();
		__iconLoader.addListener(this);

		SignalStartDrag = new Signal;
		SignalStopDrag = new Signal;
	}

	// init -- call as a pseudo-constructor immediately after attachMovie
	// e.g.  var x = attachMovie("AegisBar", "m_PrimaryBar", getNextHighestDepth()).init( aegisGroup, character, inventory );
	// this is to bypass the problem of MovieClip inherited class constructors not allowing parameters
	public function init(aegisGroup:Number, character:Character, inventory:Inventory)
	{
		// assign properties
		__aegisGroup = aegisGroup;
		__character = character;
		__inventory = inventory;
		
		// wire up signal listeners
		__character.SignalStatChanged.Connect( SlotStatChanged, this);
	    __inventory.SignalItemAdded.Connect( SlotItemAdded, this);
		__inventory.SignalItemAdded.Connect( SlotItemLoaded, this);
		__inventory.SignalItemMoved.Connect( SlotItemMoved, this);
		__inventory.SignalItemRemoved.Connect( SlotItemRemoved, this);
		__inventory.SignalItemChanged.Connect( SlotItemChanged, this);
		__inventory.SignalItemStatChanged.Connect( SlotItemStatChanged, this);

		// load the initial equipment locations
		MapGroupEquipment();
		Layout();
		
		// reveal bar
		this._visible = true;
		
		return this;
	}
	

	// layout bar internally
	public function Layout():Void
	{
		// place all elements in top left
		for (var prop in this)
		{
			if (this[prop] instanceof MovieClip)
			{
				this[prop]._x = this[prop]._y = 0;
			}
		}
		
		// resize buttons
		__aegisMC1._width = __aegisMC1._height = slotSize;
		__aegisMC2._width = __aegisMC2._height = slotSize;
		__aegisMC3._width = __aegisMC3._height = slotSize;
		__weaponMC._width = __weaponMC._height = slotSize;

		
		// horizontal and vertical can be done with combined code
		// other more custom styles would need to be handled with a switch later in the function
		if ( layoutStyle == AegisBarLayoutStyles.VERTICAL || layoutStyle == AegisBarLayoutStyles.HORIZONTAL )
		{
			// layout direction property
			var propStart:String = layoutStyle == AegisBarLayoutStyles.HORIZONTAL ? "_x" : "_y";
			var propSpan:String = layoutStyle == AegisBarLayoutStyles.HORIZONTAL ? "_width" : "_height";

			// move weapon first if necessary
			if ( weaponFirst && showWeapon )	__aegisMC1[propStart] = __weaponMC[propStart] + __weaponMC[propSpan] + (slotPadding * 3);
			
			__aegisMC2[propStart] = __aegisMC1[propStart] + __aegisMC1[propSpan] + slotPadding;
			__aegisMC3[propStart] = __aegisMC2[propStart] + __aegisMC2[propSpan] + slotPadding;

			// move weapon last if necessary
			if ( !weaponFirst && showWeapon )	__weaponMC[propStart] = __aegisMC3[propStart] + __aegisMC3[propSpan] + (slotPadding * 3);

			// hide weapon if necessary
			if ( !showWeapon )	__weaponMC._visible = false;
			
		}
		
		
		// position and resize background to wrap buttons
		if ( showBackground )
		{
			__backgroundMC._width = __buttonContainerMC._width + (barPadding * 2);
			__backgroundMC._height = __buttonContainerMC._height + (barPadding * 2);
		}
		
		else
		{
			__backgroundMC._visible = false;
		}

		__buttonContainerMC._x = __buttonContainerMC._y = barPadding;
	}

	// map defaults for primary/secondary groups onto internal equipment list
	private function MapGroupEquipment():Void
	{
		var weapon:Number;
		var aegis1:Number;
		var aegis2:Number;
		var aegis3:Number;
		var activeStat:Number;

		switch( __aegisGroup )
		{
			case AEGIS_GROUP_PRIMARY:
				weapon = _global.Enums.ItemEquipLocation.e_Wear_First_WeaponSlot;
				aegis1 = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_1;
				aegis2 = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_1_2;
				aegis3 = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_1_3;
				activeStat = _global.Enums.Stat.e_FirstActiveAegis;
			break;
			
			case AEGIS_GROUP_SECONDARY:
				weapon = _global.Enums.ItemEquipLocation.e_Wear_Second_WeaponSlot;
				aegis1 = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_2;
				aegis2 = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_2_2;
				aegis3 = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_2_3;
				activeStat = _global.Enums.Stat.e_SecondActiveAegis;
			break;
			
			default:
			
			break;
		}
		
		SetEquipment( weapon, aegis1, aegis2, aegis3, activeStat);
	}
	
	// map equipment locations to slots
	// could be made public to allow for custom setup of equipment
	private function SetEquipment(weapon:Number, aegis1:Number, aegis2:Number, aegis3:Number, activeStat:Number):Void
	{
		__activeAegisStat = activeStat;
		
		// handy reverse mapping of item location ids onto slots
		__itemSlots = { };
		__itemSlots[aegis1] = { type: "aegis", equip: aegis1, mcName: "__aegisMC1", next: aegis2, prev: aegis3 };
		__itemSlots[aegis2] = { type: "aegis", equip: aegis2, mcName: "__aegisMC2", next: aegis3, prev: aegis1 };
		__itemSlots[aegis3] = { type: "aegis", equip: aegis3, mcName: "__aegisMC3", next: aegis1, prev: aegis2 };
		__itemSlots[weapon] = { type: "weapon", equip: weapon, mcName: "__weaponMC" };
		
		LoadEquipment();
	}
	
	
	// load slot icons and presence
	private function LoadEquipment():Void
	{
		for (var i:String in __itemSlots)
		{
			LoadItem(i);
		}
	}

	// load a single slot
	private function LoadItem(equipLocation:Number):Void
	{
		var slotMC:MovieClip = this[ __itemSlots[equipLocation].mcName ];
		if (slotMC == undefined) return;	// only do something if there is something to do
		
		var item:InventoryItem = __inventory.GetItemAt( equipLocation );
		
		// if an item is slotted, show it
		if ( item != undefined)
		{
			// load icon into button
			var iconRef:ID32 = item.m_Icon;
			if (iconRef != undefined && iconRef.GetType() != 0 && iconRef.GetInstance() != 0)
			{
				var iconString:String = com.Utils.Format.Printf( "rdb:%.0f:%.0f", iconRef.GetType(), iconRef.GetInstance() );			
				__iconLoader.loadClip( iconString, slotMC.m_Icon );
			}

			slotMC.m_Watermark._visible = false;
			slotMC.m_Icon._visible = true;
			slotMC.m_XPBar._visible = showXPBar;

			slotMC.disableFocus = true;
			slotMC.SetTooltipText(LDBFormat.LDBGetText("GenericGUI", "SwapAegis"));
			slotMC.SetTooltipMaxWidth(275);
			
		}
		
		// otherwise hide it if there is no item in the location
		else
		{
			slotMC.m_Watermark._visible = true;
			slotMC.m_Background._visible = false;
			slotMC.m_Icon._visible = false;
			slotMC.m_XPBar._visible = false;
		}
		
		// if an active aegis, or a slotted weapon, highlight it
		// -- this needs to be outside the if() to allow for highlighting aegis slots with no controller slotted
		slotMC.m_Background._visible =  equipLocation == __character.GetStat(__activeAegisStat) || ( __itemSlots[equipLocation].type == "weapon" && item != undefined );

		// set internal tracking of active aegis slot
		if ( equipLocation == __character.GetStat(__activeAegisStat) )
		{
			__activeAegisSlot = equipLocation;
		}
	}
	
	// handler for MovieClipLoader.loadClip
	private function onLoadInit(target:MovieClip)
	{
		// set proper scale of target element
		// -- seems to be the right size if these values are the same as the width/height of the symbol in the library
		target._xscale = 40;
		target._yscale = 40;
	}	
	

	// highlight active aegis slot
	private function UpdateActiveAegis():Void 
	{
		for (var i:String in __itemSlots)
		{
			if (__itemSlots[i].type == "aegis" )
			{
				if ( __itemSlots[i].equip == __character.GetStat( __activeAegisStat ) )
				{
					this[ __itemSlots[i].mcName ].m_Background._visible = true;
					__activeAegisSlot = i;
				}
				else
				{
					this[ __itemSlots[i].mcName ].m_Background._visible = false;
				}
			}
		}

	}
	
	
	// swap to an aegis slot
	// -- note that slotNumber is equipment location in the inventory
	public function SwapToAegisSlot(equipLocation:Number)
	{
		// switch forward?
		if ( __itemSlots[__activeAegisSlot].next == equipLocation)
		{
			// first param is first/second aegis, second param is forward/back
			Character.SwapAegisController( __activeAegisStat == _global.Enums.Stat.e_FirstActiveAegis, true);
		}
		
		// or switch back?
		else if ( __itemSlots[__activeAegisSlot].prev == equipLocation)
		{
			Character.SwapAegisController( __activeAegisStat == _global.Enums.Stat.e_FirstActiveAegis, false);
		}
		
		__activeAegisSlot = equipLocation;
	}
	
	// Move Drag and Click Handler
	// note that this has to be done in a single onPress because there is no event bubbling in Flash
	// -- if this needed to be more complex, use EventDispatcher similar to e.g. http://peterelst.com/blog/2006/01/07/Event-Bubbling
	private function PressHandler():Void
	{
		// drag handler
		if (Key.isDown(Key.CONTROL))
		{
			if ( handleDrag ) this.startDrag();
			SignalStartDrag.Emit(this);
		}
		
		// click button handler
		else
		{
			for ( var i:String in __itemSlots )
			{
				if ( __itemSlots[i].type == "aegis" && this[ __itemSlots[i].mcName ].hitTest(_root._xmouse, _root._ymouse, true) )
				{
					SwapToAegisSlot(i);
					break;
				}
			}
			
		}
	}

	//Move Drag Release
	private function ReleaseHandler():Void
	{
		if (handleDrag) this.stopDrag();

		SignalStopDrag.Emit(this);
	}

	
	// signal handlers for inventory and character stat changes
	// I think several of these are not necessary just for Aegis or Weapon swapping, but they are the complete list
	// used by the default CharacterSheetController, as I'd rather cover everything than have
	// something not work in an unforeseen situation
	
	// handles active aegis being swapped
	private function SlotStatChanged(statID:Number):Void
	{
		if ( statID == __activeAegisStat )
		{
			UpdateActiveAegis();
		}
	}

	//Slot Item Added
	private function SlotItemAdded(inventoryID:com.Utils.ID32, itemPos:Number):Void
	{
		//UtilsBase.PrintChatText("SlotItemAdded");
		LoadItem(itemPos);
	}

	private function SlotItemLoaded(inventoryID:com.Utils.ID32, itemPos:Number):Void
	{
		//UtilsBase.PrintChatText("SlotItemLoaded");
		SlotItemAdded(inventoryID, itemPos);
	}

	//Slot Item Moved
	private function SlotItemMoved(inventoryID:com.Utils.ID32, fromPos:Number, toPos:Number):Void
	{
		//UtilsBase.PrintChatText("SlotItemMoved");
		//LoadEquipment();
	}

	//Slot Item Removed
	private function SlotItemRemoved(inventoryID:com.Utils.ID32, itemPos:Number, moved:Boolean):Void
	{
		//UtilsBase.PrintChatText("SlotItemRemoved");
		LoadItem(itemPos);
	}
	 
	//Slot Item Changed
	private function SlotItemChanged(inventoryID:com.Utils.ID32, itemPos:Number):Void
	{
		//UtilsBase.PrintChatText("SlotItemChanged");
		LoadItem(itemPos);
	}

	private function SlotItemStatChanged(inventoryID:com.Utils.ID32, itemPos:Number, stat:Number, newValue:Number )
	{
		//UtilsBase.PrintChatText("SlotItemStatChanged");
		SlotItemChanged(inventoryID, itemPos);
	}
	
	
	// getters & setters
	public function get slotSize():Number {
		return __slotSize;
	}
	public function set slotSize(size:Number) {
		__slotSize = size;
		Layout();
	}

	public function get barPadding():Number {
		return __barPadding;
	}
	public function set barPadding(padding:Number) {
		__barPadding = padding;
		Layout();
	}

	public function get slotPadding() {
		return __slotPadding;
	}
	public function set slotPadding(padding:Number) {
		__slotPadding = padding;
		Layout();
	}
	
	public function get weaponFirst():Boolean {
		return __weaponFirst;
	}
	public function set weaponFirst(value:Boolean) {
		__weaponFirst = value;
		Layout();
	}
	
	public function get showBackground():Boolean {
		return __showBackground;
	}
	public function set showBackground(value:Boolean) {
		__showBackground = value;
		Layout();
	}
	
	public function get showWeapon():Boolean {
		return __showWeapon;
	}
	public function set showWeapon(value:Boolean) {
		__showWeapon = value;
		Layout();
	}
	
	public function get showXPBar():Boolean {
		return __showXPBar;
	}
	public function set showXPBar(value:Boolean) {
		__showXPBar = value;
		LoadEquipment();
	}
	
	public function get showTooltip():Boolean {
		return __showTooltip;
	}
	public function set showTooltip(value:Boolean) {
		__showTooltip = value;
		LoadEquipment();
	}
	
	public function get layoutStyle():Number {
		return __layoutStyle;
	}
	public function set layoutStyle(value:Number) {
		// set it to passed value only if it is a valid style option
		if ( AegisBarLayoutStyles.list(value) != undefined )
		{
			__layoutStyle = value;
			Layout();
		}
	}
	
	public function get handleDrag():Boolean {
		return __handleDrag;
	}
	public function set handleDrag(value:Boolean) {
		__handleDrag = value;
	}
}