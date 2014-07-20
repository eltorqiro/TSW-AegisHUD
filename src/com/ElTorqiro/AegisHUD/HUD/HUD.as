import com.Components.FCButton;
import com.Components.ItemSlot;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Inventory;
import com.GameInterface.UtilsBase;
import flash.geom.Point;
import gfx.core.UIComponent;
import com.GameInterface.Lore;

import flash.geom.ColorTransform;
import com.ElTorqiro.Utils;
import com.GameInterface.InventoryItem;
import com.Utils.ID32;
import com.Utils.LDBFormat;
import com.GameInterface.Tooltip.*;
import mx.utils.Delegate;
//import com.ElTorqiro.AegisHUD.HUD.Bar;
import com.ElTorqiro.AegisHUD.Enums.AegisBarLayoutStyles;
import com.ElTorqiro.AegisHUD.Enums.SlotBackgroundBehaviour;
import com.ElTorqiro.AegisHUD.Enums.ActiveAegisBackgroundTintBehaviour;
import flash.filters.GlowFilter;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.HUD extends UIComponent {

	private var _slotSize:Number = 30;
	private var _barPadding:Number = 5;
	private var _slotSpacing:Number = 4;
	private var _hudScale:Number = 100;
	
	private var _barStyle:Number = 0;
	private var _neonGlowEntireBar:Boolean = true;
	private var _lockBars:Boolean = false;
	private var _attachToPassiveBar:Boolean = true;
	
	private var _showBarBackground:Boolean = true;
	private var _tintBarBackgroundByActiveAegis:Boolean = true;
	private var _neonGlowBarBackground:Boolean = true;

	private var _showWeapons:Boolean = true;
	private var _primaryWeaponFirst:Boolean = false;
	private var _secondaryWeaponFirst:Boolean = true;
	
	private var _showWeaponBackgroundBehaviour:Number = 0;	// SlotBackgroundBehaviour
	private var _tintWeaponBackgroundByActiveAegis:Boolean = false;
	private var _tintWeaponIconByActiveAegis:Boolean = false;
	private var _neonGlowWeapon:Boolean = true;
	
	private var _showXPBars:Boolean = false;
	private var _showTooltips:Boolean = true;

	private var _showAegisBackgroundBehaviour:Number = 1;	// SlotBackgroundBehaviour
	private var _tintAegisBackgroundByType:Boolean = false;
	private var _showActiveAegisBackground:Boolean = true;
	private var _tintActiveAegisBackgroundBehaviour:Number = 0;	// ActiveAegisBackgroundTintBehaviour
	private var _neonGlowAegis:Boolean = true;
	
	private var _neonEnabled:Boolean = true;

	private var _tints:Object = {};
	
	
	private var _findPassiveBarThrashCount:Number = 0;
	
	// position restoration for windows
	private var _primaryPosition:Point;
	private var _secondaryPosition:Point;
	

	// utility objects
	private var _character:Character;
	private var _inventory:Inventory;
	private var _iconLoader:MovieClipLoader;
	
	// internal movieclips
	private var m_Primary:MovieClip;
	private var m_Secondary:MovieClip;
	private var m_Background:MovieClip;

	// internal shortcuts
	private var _primary:Object = {};
	private var _secondary:Object = {};
	private var _sides:Object = { primary: _primary, secondary: _secondary };
	private var _itemSlots:Object = { };
	
	// internal states
	private var _dragging:Boolean = false;
	private var _mouseDown:Number = -1;
	
	// behaviour modifier keys
	public var dualDragModifier:Number = Key.CONTROL;
	public var dualDragButton:Number = 0;

	public var singleDragModifier:Number = Key.CONTROL;
	public var singleDragButton:Number = 1;
	
	public var scaleModifier:Number = Key.CONTROL;

	public var dualSelectModifier:Number = Key.SHIFT;
	public var dualSelectButton:Number = 0;
	
	/**
	 * constructor
	 */
	public function HUD() {
		super();

		_character = Character.GetClientCharacter();
		_inventory = new Inventory( new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, Character.GetClientCharID().GetInstance()) );

		// other objects that need creating
		_iconLoader = new MovieClipLoader();
		_iconLoader.addListener(this);
		
		_tints.psychic = 0xbf00ff;
		_tints.cyber   = 0x0099ff;
		_tints.demonic = 0xdd0000;
		_tints.empty   = 0x999999;
		_tints.none    = 0xffffff;
		_tints.standard = 0x006AFF;
	}
	

	public function onUnload():Void
	{
		super.onUnload();
		
		// unwire signal listeners
		_character.SignalStatChanged.Disconnect( SlotStatChanged, this);
	    _inventory.SignalItemAdded.Disconnect( SlotItemAdded, this);
		_inventory.SignalItemAdded.Disconnect( SlotItemLoaded, this);
		_inventory.SignalItemMoved.Disconnect( SlotItemMoved, this);
		_inventory.SignalItemRemoved.Disconnect( SlotItemRemoved, this);
		_inventory.SignalItemChanged.Disconnect( SlotItemChanged, this);
		_inventory.SignalItemStatChanged.Disconnect( SlotItemStatChanged, this);

		_character = undefined;
		_inventory = undefined;
		
		// remove event listeners
		this.removeAllEventListeners();
	}
	
	public function configUI():Void {
		super.configUI();
		
		// define item slots
		var pWeapon = _global.Enums.ItemEquipLocation.e_Wear_First_WeaponSlot;
		var pAegis1 = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_1;
		var pAegis2 = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_1_2;
		var pAegis3 = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_1_3;
		var pActiveAegisStat = _global.Enums.Stat.e_FirstActiveAegis;

		var sWeapon = _global.Enums.ItemEquipLocation.e_Wear_Second_WeaponSlot;
		var sAegis1 = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_2;
		var sAegis2 = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_2_2;
		var sAegis3 = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_2_3;
		var sActiveAegisStat = _global.Enums.Stat.e_SecondActiveAegis;

		_primary.mc = m_Primary;
		_secondary.mc = m_Secondary;
		
		_itemSlots = { };
		
		_itemSlots[pAegis1] = { side: _primary, type: "aegis", equip: pAegis1, mc: _primary.mc.m_Aegis1, next: pAegis2, prev: pAegis3, dualSelectPartner: sAegis1 };
		_itemSlots[pAegis2] = { side: _primary, type: "aegis", equip: pAegis2, mc: _primary.mc.m_Aegis2, next: pAegis3, prev: pAegis1, dualSelectPartner: sAegis2 };
		_itemSlots[pAegis3] = { side: _primary, type: "aegis", equip: pAegis3, mc: _primary.mc.m_Aegis3, next: pAegis1, prev: pAegis2, dualSelectPartner: sAegis3 };
		_itemSlots[pWeapon] = { side: _primary, type: "weapon", equip: pWeapon, mc: _primary.mc.m_Weapon };
		_primary.activeAegisStat = pActiveAegisStat;
		_primary.activeAegisEquipLocation = null;
		_primary.weaponSlot = _itemSlots[pWeapon]; 
		_primary.slots   = [ _itemSlots[pWeapon], _itemSlots[pAegis1], _itemSlots[pAegis2], _itemSlots[pAegis3] ];
		
		_itemSlots[sAegis1] = { side: _secondary, type: "aegis", equip: sAegis1, mc: _secondary.mc.m_Aegis1, next: sAegis2, prev: sAegis3, dualSelectPartner: pAegis1 };
		_itemSlots[sAegis2] = { side: _secondary, type: "aegis", equip: sAegis2, mc: _secondary.mc.m_Aegis2, next: sAegis3, prev: sAegis1, dualSelectPartner: pAegis2 };
		_itemSlots[sAegis3] = { side: _secondary, type: "aegis", equip: sAegis3, mc: _secondary.mc.m_Aegis3, next: sAegis1, prev: sAegis2, dualSelectPartner: pAegis3 };
		_itemSlots[sWeapon] = { side: _secondary, type: "weapon", equip: sWeapon, mc: _secondary.mc.m_Weapon };
		_secondary.activeAegisStat = sActiveAegisStat;
		_secondary.activeAegisEquipLocation = null;
		_secondary.weaponSlot = _itemSlots[sWeapon];
		_secondary.slots = [ _itemSlots[sWeapon], _itemSlots[sAegis1], _itemSlots[sAegis2], _itemSlots[sAegis3] ];

		// wire up button mouse handlers
		for ( var s:String in _itemSlots ) {
			if ( _itemSlots[s].type == "aegis" ) {
				SetupButtonHandlers( _itemSlots[s].mc );
			}
			
		}
		
		// wire up background mouse handlers
		SetupMoveHandlers( m_Primary.m_Background );
		SetupMoveHandlers( m_Secondary.m_Background );
		SetupMoveHandlers( m_Background );
		
		// layout bar internals
		LayoutBars();
		
		// position HUD elements
		PositionHUD();
		
		// initial load of equipment into slots
		LoadEquipment();

		// update active aegis values
		UpdateActiveAegis();
		
		// wire up signal listeners
		_character.SignalStatChanged.Connect( SlotStatChanged, this);
	    _inventory.SignalItemAdded.Connect( SlotItemAdded, this);
		_inventory.SignalItemAdded.Connect( SlotItemLoaded, this);
		_inventory.SignalItemMoved.Connect( SlotItemMoved, this);
		_inventory.SignalItemRemoved.Connect( SlotItemRemoved, this);
		_inventory.SignalItemChanged.Connect( SlotItemChanged, this);
		_inventory.SignalItemStatChanged.Connect( SlotItemStatChanged, this);

		// attach to passivebar if needed
		AttachToPassiveBar( _attachToPassiveBar );
		
		// wire up event listener
		this.addEventListener("select", this, "AegisSelectHandler");
	}

	function AegisSelectHandler(event:Object):Void {
		SwapToAegisSlot( event.itemSlot.equip, event.dualSelect );
	}

	
	// layout bar internally
	private function LayoutBars():Void
	{
		for ( var s:String in _sides )
		{
			var bar = _sides[s].mc;
			
			// place all elements in top left
			for (var prop in bar)
			{
				if (bar[prop] instanceof MovieClip)
				{
					bar[prop]._x = bar[prop]._y = _barPadding;
				}
			}
			
			// resize buttons
			bar.m_Aegis1._width = bar.m_Aegis1._height = _slotSize;
			bar.m_Aegis2._width = bar.m_Aegis2._height = _slotSize;
			bar.m_Aegis3._width = bar.m_Aegis3._height = _slotSize;
			bar.m_Weapon._width = bar.m_Weapon._height = _slotSize;
			
			// horizontal and vertical can be done with combined code
			// other more custom styles would need to be handled with a switch later in the function
			if ( _barStyle == AegisBarLayoutStyles.VERTICAL || _barStyle == AegisBarLayoutStyles.HORIZONTAL )
			{
				// layout direction property
				var propStart:String = _barStyle == AegisBarLayoutStyles.HORIZONTAL ? "_x" : "_y";
				var propSpan:String = _barStyle == AegisBarLayoutStyles.HORIZONTAL ? "_width" : "_height";

				// move weapon first if necessary
				if ( this["_" + s + "WeaponFirst"] && _showWeapons )  bar.m_Aegis1[propStart] = bar.m_Weapon[propStart] + bar.m_Weapon[propSpan] + (_slotSpacing * 3);
				
				bar.m_Aegis2[propStart] = bar.m_Aegis1[propStart] + bar.m_Aegis1[propSpan] + _slotSpacing;
				bar.m_Aegis3[propStart] = bar.m_Aegis2[propStart] + bar.m_Aegis2[propSpan] + _slotSpacing;

				// move weapon last if necessary
				if ( !this["_" + s + "WeaponFirst"] && _showWeapons )  bar.m_Weapon[propStart] = bar.m_Aegis3[propStart] + bar.m_Aegis3[propSpan] + (_slotSpacing * 3);
				
				// weapon slot visibility
				bar.m_Weapon._visible = _showWeapons;
			}
			
			var firstButton:MovieClip = this["_" + s + "WeaponFirst"] ? bar.m_Weapon : bar.m_Aegis1;
			var lastButton:MovieClip = this["_" + s + "WeaponFirst"] ? bar.m_Aegis3 : bar.m_Weapon;
			
			// position and resize background to wrap buttons
			bar.m_Background._x = bar.m_Background._y = 0;
			bar.m_Background._width = lastButton._x + lastButton._width + (_barPadding);
			bar.m_Background._height = lastButton._y + lastButton._height + (_barPadding);
		}
	}
	
	// position HUD elements on the screen
	public function PositionHUD():Void
	{
		// apply scale
		m_Primary._xscale = m_Primary._yscale = _hudScale;
		m_Secondary._xscale = m_Secondary._yscale = _hudScale;
		
		if ( _primaryPosition )
		{
			// Despite Point.x being a number, the +0 below is a quicker way of doing Math.round() on the Point.x property.
			// If not doing this, then the number prints out as "xxx", but seems to get sent to the _x property as "xxx.0000000000"
			// which the _x setter fails to interpret for some reason and does not set.
			m_Primary._x = _primaryPosition.x + 0;
			m_Primary._y = _primaryPosition.y + 0;
			
			m_Secondary._x = _secondaryPosition.x + 0;
			m_Secondary._y = _secondaryPosition.y + 0;
		}
		
		// set default positions to simulate the default buttons
		else
		{
			SetDefaultPosition();
		}
	}

	/**
	 * layout bars in same location as default passivebar swap buttons
	 */
	public function SetDefaultPosition():Void
	{
		// ... surprised this worked without some localToGlobal() usage

		
		if ( _root.passivebar.m_Bar != undefined ) {

			var pb = _root.passivebar;
			
			var pbx:Number = pb.m_BaseWidth / 2 + pb.m_Button._x; // - 4;
			var pby:Number = pb.m_Bar._y; // - 5;
			
			var globalPassiveBarPos:Point = new Point( pbx, pby );
			pb.localToGlobal( globalPassiveBarPos );
			this.globalToLocal( globalPassiveBarPos );
			
			m_Primary._x = globalPassiveBarPos.x - m_Primary._width - 2;
			m_Secondary._x = globalPassiveBarPos.x + 2;
			m_Primary._y = m_Secondary._y = globalPassiveBarPos.y - m_Primary._height - 3;
		}
		
		else {
			// align to stage method
		//	m_Primary._x = Math.round( (Stage["visibleRect"].width / 2) - m_Primary._width - 3 );
		//	m_Secondary._x = Math.round( m_Primary._x + m_Primary._width + 6 );
		//	m_Primary._y = m_Secondary._y = Math.round( Stage["visibleRect"].height - 75 - m_Primary._height - 3 );
		}
		
		// TODO: reliable way to lock to default swap buttons position, even during passivebar open/close
		/*
		if ( _root.passivebar )
		{
			// align to passivebar method
			var middle:Object = { x: _root.passivebar.m_Bar.m_Background };
			
			m_Primary._x = Math.round( _root.passivebar._x + _root.passivebar.m_Bar.m_Background._x + (_root.passivebar.m_Bar.m_Background._width / 2) - m_Primary._width - 3 );
			m_Secondary._x = Math.round( m_Primary._x + m_Primary._width + 6 );
			m_Primary._y = m_Secondary._y = Math.round( _root.passivebar._y - m_Primary._height - 3 );
		}
		
		else
		{
		}
		*/
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
		var slot = _itemSlots[equipLocation];
		if (slot == undefined) return;	// only do something if there is something to do

		var slotMC:MovieClip = slot.mc;
		var item:InventoryItem = _inventory.GetItemAt( equipLocation );

		slot.item = item;
		if( slot.type == "aegis") slot.aegisType = "empty";
		
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

			// establish aegis type
			if( slot.type == "aegis" ) {
				if ( item.m_Name.indexOf("yb") >= 0 ) {
					slot.aegisType = "cyber";
				}
				
				else if ( item.m_Name.indexOf("mon") >= 0 ) {
					slot.aegisType = "demonic";
				}

				else if ( item.m_Name.indexOf("Psy") >= 0 ) {
					slot.aegisType = "psychic";
				}
			}
			
			//slotMC.SetTooltipText(LDBFormat.LDBGetText("GenericGUI", "SwapAegis"));
			//slotMC.SetTooltipMaxWidth(275);
			
		}
		
		invalidate();
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
	private function draw():Void 
	{
		// do for both aegis sides
		for ( var s:String in _sides )
		{
			var bar = _sides[s];
			var barMC:MovieClip = bar.mc;
			
			// establish bar tint value
			var barTint = _tints[ _itemSlots[bar.activeAegisEquipLocation].aegisType ];

			// show or hide background (must use alpha so it remains a hit target for mouse)
			barMC.m_Background._alpha = _showBarBackground ? 100 : 0;

			// tint bar background
			Utils.Colorize( barMC.m_Background, _tintBarBackgroundByActiveAegis ? barTint : 0x000000 );
			
			// neon glow entire bar
			if ( _neonEnabled && _neonGlowBarBackground ) {
				var barGlow:GlowFilter = new GlowFilter(
					barTint, 	/* glow_color */
					0.8, 		/* glow_alpha */
					10, 		/* glow_blurX */
					10, 		/* glow_blurY */
					2,			/* glow_strength */
					3, 			/* glow_quality */
					false, 		/* glow_inner */
					false 		/* glow_knockout */
				);
				
				barMC.m_Background.filters = [ barGlow ];
			}
			else barMC.m_Background.filters = [];
			
			// handle weaponj slot
			var weaponSlot = bar.weaponSlot;
			var weaponSlotMC = weaponSlot.mc;

			// show or hide weapon icon
			if ( weaponSlot.item == undefined ) {
				weaponSlotMC.m_Watermark._visible = true;
				weaponSlotMC.m_Icon._visible = false;
			}
			else {
				weaponSlotMC.m_Watermark._visible = false;
				weaponSlotMC.m_Icon._visible = true;
			}
			
			// show weapon background
			weaponSlotMC.m_Background._visible = _showWeaponBackgroundBehaviour == SlotBackgroundBehaviour.ALWAYS
				|| ( _showWeaponBackgroundBehaviour == SlotBackgroundBehaviour.WHEN_SLOTTED && weaponSlot.item != undefined );
			
			// tint weapon background
			if ( _tintWeaponBackgroundByActiveAegis ) {
				Utils.Colorize( weaponSlotMC.m_Background, barTint );
			}
			
			// tint weapon icon
			if ( _tintWeaponIconByActiveAegis ) {
				Utils.Colorize( weaponSlotMC.m_Icon, barTint );
			}
			
			// neon glow weapon
			if ( _neonEnabled && _neonGlowWeapon ) {
				var weaponGlow = new GlowFilter(
					barTint, 	/* glow_color */
					1, 			/* glow_alpha */
					10, 		/* glow_blurX */
					10, 		/* glow_blurY */
					3,			/* glow_strength */
					3, 			/* glow_quality */
					false, 		/* glow_inner */
					false 		/* glow_knockout */
				);
				
				weaponSlotMC.filters = [ weaponGlow ];
			}
			else weaponSlotMC.filters = [];
			

			// iterate each aegis slot
			for ( var a:String in bar.slots ) {
				var slot = bar.slots[a];
				
				if ( slot.type != "aegis" ) continue;
				
				var slotMC = slot.mc;
				var slotTint = _tints[ slot.aegisType ];
				
				// show or hide aegis icon
				if ( slot.item == undefined ) {
					slotMC.m_Watermark._visible = true;
					slotMC.m_Icon._visible = false;
				}
				else {
					slotMC.m_Watermark._visible = false;
					slotMC.m_Icon._visible = true;
				}
				
				// show xp bars
				slotMC.m_XPBar._visible = _showXPBars && slot.item != undefined;
				
				// show aegis background
				slotMC.m_Background._visible = _showAegisBackgroundBehaviour == SlotBackgroundBehaviour.ALWAYS
					|| ( _showAegisBackgroundBehaviour == SlotBackgroundBehaviour.WHEN_SLOTTED && slot.item != undefined );
				
				// tint aegis background
				Utils.Colorize( slotMC.m_Background, _tintAegisBackgroundByType ? slotTint : _tints.none );

				// take neon glow off slot before the active check
				slotMC.filters = [];
				
				// handle active aegis higlighting
				if ( slot.equip == bar.activeAegisEquipLocation ) {

					// show aegis background
					slotMC.m_Background._visible = _showActiveAegisBackground;
					
					// tint aegis background
					switch( _tintActiveAegisBackgroundBehaviour ) {
						
						case ActiveAegisBackgroundTintBehaviour.NEVER: 		break;
						case ActiveAegisBackgroundTintBehaviour.STANDARD: 	Utils.Colorize( slotMC.m_Background, _tints.standard ); break;
						case ActiveAegisBackgroundTintBehaviour.AEGIS_TYPE:	Utils.Colorize( slotMC.m_Background, slotTint ); break;
					}
					
					// neon glow aegis
					if ( _neonEnabled && _neonGlowAegis ) {
						var aegisGlow = new GlowFilter(
							slotTint, 	/* glow_color */
							1, 			/* glow_alpha */
							10, 		/* glow_blurX */
							10, 		/* glow_blurY */
							3,			/* glow_strength */
							3, 			/* glow_quality */
							false, 		/* glow_inner */
							false 		/* glow_knockout */
						);
						
						slotMC.filters = [ aegisGlow ];
					}

					
					// TODO: bring active aegis button to the front
					if ( slotMC.getDepth() < _itemSlots[slot.prev].mc.getDepth() ) slotMC.swapDepths( _itemSlots[slot.prev].mc );
					if ( slotMC.getDepth() < _itemSlots[slot.next].mc.getDepth() ) slotMC.swapDepths( _itemSlots[slot.next].mc );
				}
			}
		}	
	}
	
	
	private function UpdateActiveAegis():Void
	{
		_primary.activeAegisEquipLocation = _character.GetStat( _primary.activeAegisStat );
		_secondary.activeAegisEquipLocation = _character.GetStat( _secondary.activeAegisStat );
		
		invalidate();
	}

	// swap to an aegis slot
	// -- note that slotNumber is equipment location in the inventory
	public function SwapToAegisSlot(equipLocation:Number, dualSelect:Boolean)
	{
		// do nothing if no slot location provided
		if ( equipLocation == undefined) return;
		
		var side = _itemSlots[equipLocation].side;

		// switch forward?
		if ( _itemSlots[ side.activeAegisEquipLocation ].next == equipLocation )
		{
			// first param is first/second aegis, second param is forward/back
			Character.SwapAegisController( side == _primary, true);
		}
		
		// or switch back? (doing the extra check instead of a raw else prevents double-jumps with the switch latency)
		else if ( _itemSlots[ side.activeAegisEquipLocation ].prev == equipLocation )
		{
			Character.SwapAegisController( side == _primary, false);
		}
		
		// important to update the internal pointer for the aegis location
		// even before we find out if the swap was successful
		// otherwise rapid clicks can cause the selection to jump 2 spots
		side.activeAegisEquipLocation = equipLocation;
		
		// select other side partner slot if dualSelect in use
		if ( dualSelect ) {
			SwapToAegisSlot( _itemSlots[equipLocation].dualSelectPartner );
		}
	}

	
	private function handleMousePress(controllerIdx:Number, keyboardOrMouse:Number, button:Number):Void {
		// only allow one mouse button to be pressed at once
		if ( _mouseDown != -1 ) return;
		_mouseDown = button;

		// TODO: check if no modifiers held down, and only fire click if that is the case, otherwise fire appropriate start drag etc
		if ( Key.isDown( dualDragModifier ) && button == dualDragButton ) {
			_dragging = true;
			dispatchEvent( { type:"dualDrag", modifier:dualDragModifier, button:button } );
		}
		else if ( Key.isDown( singleDragModifier ) && button == singleDragButton ) {
			_dragging = true;
			dispatchEvent( { type:"drag", modifier:singleDragModifier, button:button } );
		}
		else {
			// check if an aegis selector button was involved
			var slot:MovieClip = getItemSlotMouseOver();
			
			if( slot == undefined || slot.type == "weapon" ) {}
			else if ( Key.isDown( dualSelectModifier ) && button == dualSelectButton ) {
				dispatchEvent({ type:"select", modifier:dualSelectModifier, button:button, itemSlot:slot, dualSelect:true });
			}
			else {
				dispatchEvent({ type:"select", button:button, itemSlot:slot, dualSelect:false });
			}
		}
	}
	

	private function handleMouseRelease(controllerIdx:Number, keyboardOrMouse:Number, button:Number):Void {
		// only propogate if the release is associated with the originally held down button
		if ( _mouseDown != button ) return;
		_mouseDown = -1;

		if( _dragging ) dispatchEvent({type:"stopDrag", button:button});
	}
	

	private function handleReleaseOutside(controllerIdx:Number, button:Number):Void {
		handleMouseRelease(controllerIdx, 0, button);
	}

	
	private function handleRollOver(mouseIdx:Number):Void {
		// check which aegis selector button was involved
		var buttonMC:MovieClip = getItemSlotMouseOver();
		dispatchEvent( { type:"rollover", target:buttonMC } );
	}

	private function handleRollOut(mouseIdx:Number):Void {
		dispatchEvent( { type:"rollout" } );
	}
	

	private function getItemSlotMouseOver():MovieClip {

		var slot;
		for ( var s:String in _itemSlots ) {
			if ( _itemSlots[s].mc.hitTest(_root._xmouse, _root._ymouse, true) ) {
				slot = _itemSlots[s];
				break;
			}
		}
		
		return slot;
	}
	
	/**
	 * Sets up mouse event handlers for hud or bar movement
	 * 
	 * @param	mc Movieclip to configure move handlers on
	 */
	private function SetupMoveHandlers(mc:MovieClip) {
		
		if ( !mc ) return;
		
		mc.onPress = Delegate.create(this, handleMousePress);
		mc.onRelease = Delegate.create(this, handleMouseRelease);
		mc.onReleaseOutside = Delegate.create(this, handleReleaseOutside);
		mc["onPressAux"] = mc.onPress;
		mc["onReleaseAux"] = mc.onRelease;
		mc["onReleaseOutsideAux"] = mc.onReleaseOutside;
	}
	
	
	/**
	 * Sets up mouse event handlers for aegis selector buttons
	 * 
	 * @param	mc Movieclip to configure rollovers on
	 */
	private function SetupButtonHandlers(mc:MovieClip) {

		if ( !mc ) return;
		
		SetupMoveHandlers( mc );
		
		mc.onRollOver = Delegate.create(this, handleRollOver);
		mc.onRollOut = Delegate.create(this, handleRollOut);
		mc.onDragOut = mc.onRollOut;
	}
	

	// signal handlers for inventory and character stat changes
	// I think some of these are not necessary just for Aegis or Weapon swapping, but they are the complete list
	// used by the default CharacterSheetController, as I'd rather cover everything than have
	// something not work in an unforeseen situation
	
	// handles active aegis being swapped
	private function SlotStatChanged(statID:Number):Void {
		if ( statID == _primary.activeAegisStat || statID == _secondary.activeAegisStat ) UpdateActiveAegis();
	}

	//Slot Item Added
	private function SlotItemAdded(inventoryID:com.Utils.ID32, itemPos:Number):Void {
		LoadItem(itemPos);
	}

	private function SlotItemLoaded(inventoryID:com.Utils.ID32, itemPos:Number):Void {
		SlotItemAdded(inventoryID, itemPos);
	}

	//Slot Item Moved
	private function SlotItemMoved(inventoryID:com.Utils.ID32, fromPos:Number, toPos:Number):Void {
		//LoadEquipment();
	}

	//Slot Item Removed
	private function SlotItemRemoved(inventoryID:com.Utils.ID32, itemPos:Number, moved:Boolean):Void {
		LoadItem(itemPos);
	}
	 
	//Slot Item Changed
	private function SlotItemChanged(inventoryID:com.Utils.ID32, itemPos:Number):Void {
		LoadItem(itemPos);
	}

	private function SlotItemStatChanged(inventoryID:com.Utils.ID32, itemPos:Number, stat:Number, newValue:Number ) {
		SlotItemChanged(inventoryID, itemPos);
	}
	

	// hooks into the passivebar to set up proxies for open/close
	private function AttachToPassiveBar(attach:Boolean):Void {
		
		if ( _root.passivebar.m_Bar.onTweenComplete == undefined ) {
			// if the thrash count is exceeded, reset count and do nothing
			if (_findPassiveBarThrashCount++ == 30)  _findPassiveBarThrashCount = 0;
			// otherwise try again
			else _global.setTimeout( Delegate.create(this, AttachToPassiveBar), 100, attach );
			
			return;
		}

		// if we reached this far, reset thrash count
		_findPassiveBarThrashCount = 0;
		
		var passivebar = _root.passivebar;
		
		// set up proxies and force HUD into position
		if ( attach ) {
			
			if( passivebar.m_Bar.onTweenComplete_AegisHUD_Saved == undefined ) {
				passivebar.m_Bar.onTweenComplete_AegisHUD_Saved = passivebar.m_Bar.onTweenComplete;
				// break the link
				passivebar.m_Bar.onTweenComplete = undefined;
				passivebar.m_Bar.onTweenComplete = Delegate.create(this, PassiveBarOnTweenCompleteProxy);
			}
		}
		
		// remove proxy and restore original function
		else if( passivebar.m_Bar.onTweenComplete_AegisHUD_Saved != undefined ) {
			passivebar.m_Bar.onTweenComplete = passivebar.m_Bar.onTweenComplete_AegisHUD_Saved;
			passivebar.m_Bar.onTweenComplete_AegisHUD_Saved = undefined;
		}
	}
	
	// proxy function for hooking into the passivebar onTweenComplete listener that fires after each open/close
	private function PassiveBarOnTweenCompleteProxy():Void {
		// let the original function run
		_root.passivebar.m_Bar.onTweenComplete_AegisHUD_Saved();
		SetDefaultPosition();
	}

	
	// getters & setters
	public function get showWeapons():Boolean {
		return _showWeapons;
	}
	public function set showWeapons(value:Boolean) {
		_showWeapons = value;
	}
	
	public function get showBarBackground():Boolean {
		return _showBarBackground;
	}
	public function set showBarBackground(value:Boolean) {
		_showBarBackground = value;
	}
	
	public function get showXPBars():Boolean {
		return _showXPBars;
	}
	public function set showXPBars(value:Boolean) {
		_showXPBars = value;
	}
	
	public function get showTooltips():Boolean {
		return _showTooltips;
	}
	public function set showTooltips(value:Boolean) {
		_showTooltips = value;
	}
	
	// readonly
	public function get primaryBar():MovieClip {
		return m_Primary;
	}
	
	// readonly
	public function get secondaryBar():MovieClip {
		return m_Secondary;
	}
	
	public function get primaryPosition():Point {
		return new Point(m_Primary._x, m_Primary._y);
	}
	public function set primaryPosition(value:Point) {
		_primaryPosition = value;
	}

	public function get secondaryPosition():Point {
		return new Point(m_Secondary._x, m_Secondary._y);
	}
	public function set secondaryPosition(value:Point) {
		_secondaryPosition = value;
	}

	// overall hud scale
	public function get hudScale():Number {
		return _hudScale;
	}
	public function set hudScale(scale:Number) {
		_hudScale = scale;
	}
	
	public function get primaryWeaponFirst():Boolean {
		return _primaryWeaponFirst;
	}
	public function set primaryWeaponFirst(value:Boolean) {
		_primaryWeaponFirst = value;
	}

	public function get secondaryWeaponFirst():Boolean {
		return _secondaryWeaponFirst;
	}
	public function set secondaryWeaponFirst(value:Boolean) {
		_secondaryWeaponFirst = value;
	}

	public function get lockBars():Boolean {
		return _lockBars;
	}
	public function set lockBars(value:Boolean) {
		_lockBars = value;
	}
		
	public function get barStyle():Number {
		return _barStyle;
	}	
	// TODO: some sanity checking to make sure this is in a valid range of available styles, although Bar currently filters that
	public function set barStyle(value:Number) {
		_barStyle = value;
	}
	
}