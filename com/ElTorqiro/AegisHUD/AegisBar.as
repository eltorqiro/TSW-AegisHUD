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
	private var _aegisMC1:MovieClip;
	private var _aegisMC2:MovieClip;
	private var _aegisMC3:MovieClip;
	private var _weaponMC:MovieClip;
	private var _backgroundMC:MovieClip;
	private var _buttonContainerMC:MovieClip;
	
	// slot configuration values
	private var _aegisGroup:Number;
	private var _activeAegisStat:Number;
	private var _itemSlots:Object = { };

	// layout parameters
	private var _enableLayout:Boolean = true;
	private var _slotSize:Number = 30;
	private var _barPadding:Number = 5;
	private var _slotPadding:Number = 4;
	private var _weaponFirst:Boolean = true;
	private var _showBackground:Boolean = true;
	private var _showWeapon:Boolean = true;
	private var _showWeaponHighlight:Boolean = true;
	private var _showXPBar:Boolean = true;
	private var _showTooltip:Boolean = true;
	private var _layoutStyle:Number = 1;

	// behaviour parameters
	private var _handleDrag:Boolean = true;
	
	// utility objects
	private var _character:Character;
	private var _inventory:Inventory;
	private var _iconLoader:MovieClipLoader;
	private var _activeAegisSlot:Number;
	
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
		_aegisMC1 = m_ButtonContainer.m_Aegis1;
		_aegisMC2 = m_ButtonContainer.m_Aegis2;
		_aegisMC3 = m_ButtonContainer.m_Aegis3;
		_weaponMC = m_ButtonContainer.m_Weapon;
		_backgroundMC = m_Background;
		_buttonContainerMC = m_ButtonContainer;

		// other objects that need creating
		_iconLoader = new MovieClipLoader();
		_iconLoader.addListener(this);

		SignalStartDrag = new Signal;
		SignalStopDrag = new Signal;
	}

	// init -- call as a pseudo-constructor immediately after attachMovie
	// e.g.  var x = attachMovie("AegisBar", "m_PrimaryBar", getNextHighestDepth()).init( aegisGroup, character, inventory );
	// this is to bypass the problem of MovieClip inherited class constructors not allowing parameters
	public function init(aegisGroup:Number, character:Character, inventory:Inventory)
	{
		// assign properties
		_aegisGroup = aegisGroup;
		_character = character;
		_inventory = inventory;
		
		// wire up signal listeners
		_character.SignalStatChanged.Connect( SlotStatChanged, this);
	    _inventory.SignalItemAdded.Connect( SlotItemAdded, this);
		_inventory.SignalItemAdded.Connect( SlotItemLoaded, this);
		_inventory.SignalItemMoved.Connect( SlotItemMoved, this);
		_inventory.SignalItemRemoved.Connect( SlotItemRemoved, this);
		_inventory.SignalItemChanged.Connect( SlotItemChanged, this);
		_inventory.SignalItemStatChanged.Connect( SlotItemStatChanged, this);

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
		_aegisMC1._width = _aegisMC1._height = slotSize;
		_aegisMC2._width = _aegisMC2._height = slotSize;
		_aegisMC3._width = _aegisMC3._height = slotSize;
		_weaponMC._width = _weaponMC._height = slotSize;

		
		// horizontal and vertical can be done with combined code
		// other more custom styles would need to be handled with a switch later in the function
		if ( layoutStyle == AegisBarLayoutStyles.VERTICAL || layoutStyle == AegisBarLayoutStyles.HORIZONTAL )
		{
			// layout direction property
			var propStart:String = layoutStyle == AegisBarLayoutStyles.HORIZONTAL ? "_x" : "_y";
			var propSpan:String = layoutStyle == AegisBarLayoutStyles.HORIZONTAL ? "_width" : "_height";

			// move weapon first if necessary
			if ( weaponFirst && showWeapon )	_aegisMC1[propStart] = _weaponMC[propStart] + _weaponMC[propSpan] + (slotPadding * 3);
			
			_aegisMC2[propStart] = _aegisMC1[propStart] + _aegisMC1[propSpan] + slotPadding;
			_aegisMC3[propStart] = _aegisMC2[propStart] + _aegisMC2[propSpan] + slotPadding;

			// move weapon last if necessary
			if ( !weaponFirst && showWeapon )	_weaponMC[propStart] = _aegisMC3[propStart] + _aegisMC3[propSpan] + (slotPadding * 3);

			// weapon slot visibility
			_weaponMC._visible = showWeapon;
			
		}
		
		
		// position and resize background to wrap buttons
		if ( showBackground )
		{
			_backgroundMC._width = _buttonContainerMC._width + (barPadding * 2);
			_backgroundMC._height = _buttonContainerMC._height + (barPadding * 2);
		}
		_backgroundMC._visible = showBackground;
		
		_buttonContainerMC._x = _buttonContainerMC._y = barPadding;
	}

	// map defaults for primary/secondary groups onto internal equipment list
	private function MapGroupEquipment():Void
	{
		var weapon:Number;
		var aegis1:Number;
		var aegis2:Number;
		var aegis3:Number;
		var activeStat:Number;

		switch( _aegisGroup )
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
		_activeAegisStat = activeStat;
		
		// handy reverse mapping of item location ids onto slots
		_itemSlots = { };
		_itemSlots[aegis1] = { type: "aegis", equip: aegis1, mcName: "_aegisMC1", next: aegis2, prev: aegis3 };
		_itemSlots[aegis2] = { type: "aegis", equip: aegis2, mcName: "_aegisMC2", next: aegis3, prev: aegis1 };
		_itemSlots[aegis3] = { type: "aegis", equip: aegis3, mcName: "_aegisMC3", next: aegis1, prev: aegis2 };
		_itemSlots[weapon] = { type: "weapon", equip: weapon, mcName: "_weaponMC" };
		
		LoadEquipment();
	}
	
	
	// load slot icons and presence
	private function LoadEquipment():Void
	{
		for (var i:String in _itemSlots)
		{
			LoadItem(i);
		}
	}

	// load a single slot
	private function LoadItem(equipLocation:Number):Void
	{
		var slotMC:MovieClip = this[ _itemSlots[equipLocation].mcName ];
		if (slotMC == undefined) return;	// only do something if there is something to do
		
		var item:InventoryItem = _inventory.GetItemAt( equipLocation );
		
		// if an item is slotted, show it
		if ( item != undefined)
		{
			// load icon into button
			var iconRef:ID32 = item.m_Icon;
			if (iconRef != undefined && iconRef.GetType() != 0 && iconRef.GetInstance() != 0)
			{
				var iconString:String = com.Utils.Format.Printf( "rdb:%.0f:%.0f", iconRef.GetType(), iconRef.GetInstance() );			
				_iconLoader.loadClip( iconString, slotMC.m_Icon );
			}

			slotMC.m_Watermark._visible = false;
			slotMC.m_Background._visible = this.showWeaponHighlight;
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
		slotMC.m_Background._visible =  equipLocation == _character.GetStat(_activeAegisStat) || ( _itemSlots[equipLocation].type == "weapon" && item != undefined && showWeaponHighlight);

		// set internal tracking of active aegis slot
		if ( equipLocation == _character.GetStat(_activeAegisStat) )
		{
			_activeAegisSlot = equipLocation;
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
		for (var i:String in _itemSlots)
		{
			if (_itemSlots[i].type == "aegis" )
			{
				if ( _itemSlots[i].equip == _character.GetStat( _activeAegisStat ) )
				{
					this[ _itemSlots[i].mcName ].m_Background._visible = true;
					_activeAegisSlot = i;
				}
				else
				{
					this[ _itemSlots[i].mcName ].m_Background._visible = false;
				}
			}
		}

	}
	
	
	// swap to an aegis slot
	// -- note that slotNumber is equipment location in the inventory
	public function SwapToAegisSlot(equipLocation:Number)
	{
		// switch forward?
		if ( _itemSlots[_activeAegisSlot].next == equipLocation)
		{
			// first param is first/second aegis, second param is forward/back
			Character.SwapAegisController( _activeAegisStat == _global.Enums.Stat.e_FirstActiveAegis, true);
		}
		
		// or switch back?
		else if ( _itemSlots[_activeAegisSlot].prev == equipLocation)
		{
			Character.SwapAegisController( _activeAegisStat == _global.Enums.Stat.e_FirstActiveAegis, false);
		}
		
		_activeAegisSlot = equipLocation;
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
			for ( var i:String in _itemSlots )
			{
				if ( _itemSlots[i].type == "aegis" && this[ _itemSlots[i].mcName ].hitTest(_root._xmouse, _root._ymouse, true) )
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
	// I think some of these are not necessary just for Aegis or Weapon swapping, but they are the complete list
	// used by the default CharacterSheetController, as I'd rather cover everything than have
	// something not work in an unforeseen situation
	
	// handles active aegis being swapped
	private function SlotStatChanged(statID:Number):Void
	{
		if ( statID == _activeAegisStat )
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
		return _slotSize;
	}
	public function set slotSize(size:Number) {
		_slotSize = size;
		Layout();
	}

	public function get barPadding():Number {
		return _barPadding;
	}
	public function set barPadding(padding:Number) {
		_barPadding = padding;
		Layout();
	}

	public function get slotPadding() {
		return _slotPadding;
	}
	public function set slotPadding(padding:Number) {
		_slotPadding = padding;
		Layout();
	}
	
	public function get weaponFirst():Boolean {
		return _weaponFirst;
	}
	public function set weaponFirst(value:Boolean) {
		_weaponFirst = value;
		Layout();
	}
	
	public function get showBackground():Boolean {
		return _showBackground;
	}
	public function set showBackground(value:Boolean) {
		_showBackground = value;
		Layout();
	}
	
	public function get showWeapon():Boolean {
		return _showWeapon;
	}
	public function set showWeapon(value:Boolean) {
		_showWeapon = value;
		Layout();
	}

	public function get showWeaponHighlight():Boolean {
		return _showWeaponHighlight;
	}
	public function set showWeaponHighlight(value:Boolean) {
		_showWeaponHighlight = value;
		_weaponMC.m_Background._visible = _showWeaponHighlight;
	}
	
	public function get showXPBar():Boolean {
		return _showXPBar;
	}
	public function set showXPBar(value:Boolean) {
		_showXPBar = value;
		LoadEquipment();
	}
	
	public function get showTooltip():Boolean {
		return _showTooltip;
	}
	public function set showTooltip(value:Boolean) {
		_showTooltip = value;
		LoadEquipment();
	}
	
	public function get layoutStyle():Number {
		return _layoutStyle;
	}
	public function set layoutStyle(value:Number) {
		// set it to passed value only if it is a valid style option
		if ( AegisBarLayoutStyles.list(value) != undefined )
		{
			_layoutStyle = value;
			Layout();
		}
	}
	
	public function get handleDrag():Boolean {
		return _handleDrag;
	}
	public function set handleDrag(value:Boolean) {
		_handleDrag = value;
	}
}