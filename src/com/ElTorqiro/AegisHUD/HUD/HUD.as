import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Inventory;
import com.GameInterface.UtilsBase;
import flash.geom.Point;
import gfx.core.UIComponent;
import com.GameInterface.Lore;
import mx.data.encoders.Bool;
import com.GameInterface.Input;
import gfx.ui.InputDetails;
import gfx.managers.InputDelegate;
import flash.geom.ColorTransform;
import com.ElTorqiro.AddonUtils.AddonUtils;
import com.GameInterface.InventoryItem;
import com.Utils.ID32;
import com.Utils.LDBFormat;
import com.GameInterface.Tooltip.*;
import mx.utils.Delegate;
import com.ElTorqiro.AegisHUD.Enums.AegisBarLayoutStyles;
import com.ElTorqiro.AegisHUD.Enums.SlotBackgroundBehaviour;
import com.ElTorqiro.AegisHUD.Enums.ActiveAegisBackgroundTintBehaviour;
import com.ElTorqiro.AegisHUD.Enums.XPIndicatorStyles;
import flash.filters.GlowFilter;
import gfx.motion.Tween;
import mx.transitions.easing.Bounce;
import com.ElTorqiro.AegisHUD.AddonInfo;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.HUD extends UIComponent {

	// aegis xp token ids			(107 = one of the demonics (the 10% chance to do 30 damage one), with icon id 8447954
	public static var e_AegisTokenID_Min:Number = 103;
	public static var e_AegisTokenID_Max:Number = 108;
	
	private var _slotSize:Number;
	private var _barPadding:Number;
	private var _slotSpacing:Number;
	private var _hudScale:Number;
	public  var maxHUDScale:Number;
	public  var minHUDScale:Number;
	
	private var _barStyle:Number;
	private var _neonGlowEntireBar:Boolean;
	private var _lockBars:Boolean;
	private var _attachToPassiveBar:Boolean;
	private var _animateMovementsToDefaultPosition:Boolean;
	
	private var _showBarBackground:Boolean;
	private var _tintBarBackgroundByActiveAegis:Boolean;
	private var _neonGlowBarBackground:Boolean;

	private var _showWeapons:Boolean;
	private var _primaryWeaponFirst:Boolean;
	private var _secondaryWeaponFirst:Boolean;
	
	private var _showWeaponBackgroundBehaviour:Number;	// SlotBackgroundBehaviour
	private var _tintWeaponBackgroundByActiveAegis:Boolean;
	private var _tintWeaponIconByActiveAegis:Boolean;
	private var _neonGlowWeapon:Boolean;
	
	private var _showXP:Boolean;
	private var _showXPProgressBackground:Boolean;
	private var _xpIndicatorStyle:Number;
	private var _hideXPWhenFull:Boolean;
	private var _fetchXPAntiSpamInterval:Number; // milliseconds

	private var _showTooltips:Boolean;
	private var _suppressTooltipsInCombat:Boolean;

	private var _showAegisBackgroundBehaviour:Number;	// SlotBackgroundBehaviour
	private var _tintAegisBackgroundByType:Boolean;
	private var _tintAegisIconByType:Boolean;
	private var _showActiveAegisBackground:Boolean;
	private var _tintActiveAegisBackgroundBehaviour:Number;	// ActiveAegisBackgroundTintBehaviour
	private var _neonGlowAegis:Boolean;
	
	private var _neonEnabled:Boolean;

	public  var dualSelectWithModifier:Boolean;
	public  var dualSelectWithButton:Boolean;
	private var _dualSelectByDefault:Boolean;
	private var _dualSelectFromHotkey:Boolean;
	
	private var _tints:Object = { none: 0xffffff };
	
	
	// position restoration for windows
	private var _primaryPosition:Point;
	private var _secondaryPosition:Point;
	

	// utility objects
	private var _character:Character;
	private var _inventory:Inventory;
	private var _iconLoader:MovieClipLoader;
    private var _tooltip:TooltipInterface;
	private var _tooltipTimeoutID:Number;
	private var _tooltipSlot:Object;
	private var _fetchXPAntiSpamTimeoutID:Number;
	private var _lastXPFetchTime:Number = 0;
	private var _findPassiveBarThrashCount:Number = 0;
	private var _findPassiveBarTimeoutID:Number;
	private var _swapTimeoutID:Number;
	private var _postSwapCatchupInterval:Number = 500;
	
	// internal movieclips
	private var m_Primary:MovieClip;
	private var m_Secondary:MovieClip;
	private var m_Background:MovieClip;
	private var m_DragProxy:MovieClip;	// not in flash, instantiated dynamically during drag events

	// internal shortcuts
	private var _primary:Object = {};
	private var _secondary:Object = {};
	private var _sides:Object = { primary: _primary, secondary: _secondary };
	private var _itemSlots:Object = { };
	
	// internal states
	private var _dragging:Boolean = false;
	private var _mouseDown:Number = -1;
	
	// collection of drag objects used by drag proxy to move as one
	private var _dragObjects:Array;
	
	// behaviour modifier keys
	public var dualDragModifier:Number = Key.CONTROL;
	public var dualDragButton:Number = 0;

	public var singleDragModifier:Number = Key.CONTROL;
	public var singleDragButton:Number = 1;
	
	public var scaleModifier:Number = Key.CONTROL;
	public var scaleResetModifier:Number = Key.SHIFT;

	public var dualSelectModifier:Number = Key.SHIFT;
	public var dualSelectButton:Number = 1;
	
	public var singleSelectButton:Number = 0;

	// swap AEGIS RPC DV used as part of hotkey hijacking
	private var _swapAegisRPC:DistributedValue;
	
	// parameters passed in through initObj of attachMovie( ..., initObj)
	private var settings:Object;

	
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
		
		// apply default settings pack
		ApplySettingsPack( HUD.defaultSettingsPack );
		
		// apply on top any settings passed in during init
		ApplySettingsPack( settings );
		delete settings;
		
		// wire up hotkey hijacking listener
		_swapAegisRPC = DistributedValue.Create( AddonInfo.Name + "_Swap" );
		_swapAegisRPC.SignalChanged.Connect( SwapAegisRPCHandler, this );
	}
	
	public function onUnload():Void
	{
		super.onUnload();

		// close any open tooltip
		CloseTooltip();

		// undo passivebar attachment
		AttachToPassiveBar( false );

		// unwire signal listeners
		_character.SignalStatChanged.Disconnect( SlotStatChanged, this);
	    _inventory.SignalItemAdded.Disconnect( SlotItemAdded, this);
		_inventory.SignalItemAdded.Disconnect( SlotItemLoaded, this);
		_inventory.SignalItemMoved.Disconnect( SlotItemMoved, this);
		_inventory.SignalItemRemoved.Disconnect( SlotItemRemoved, this);
		_inventory.SignalItemChanged.Disconnect( SlotItemChanged, this);
		_inventory.SignalItemStatChanged.Disconnect( SlotItemStatChanged, this);

		_character.SignalTokenAmountChanged.Disconnect( SlotTokenAmountChanged, this );
		
		_swapAegisRPC.SignalChanged.Disconnect( SwapAegisRPCHandler, this );
		
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
		_primary.selectedAegisEquipLocation = _character.GetStat( pActiveAegisStat );
		_primary.weaponSlot = _itemSlots[pWeapon]; 
		_primary.slots   = [ _itemSlots[pWeapon], _itemSlots[pAegis1], _itemSlots[pAegis2], _itemSlots[pAegis3] ];
		
		_itemSlots[sAegis1] = { side: _secondary, type: "aegis", equip: sAegis1, mc: _secondary.mc.m_Aegis1, next: sAegis2, prev: sAegis3, dualSelectPartner: pAegis1 };
		_itemSlots[sAegis2] = { side: _secondary, type: "aegis", equip: sAegis2, mc: _secondary.mc.m_Aegis2, next: sAegis3, prev: sAegis1, dualSelectPartner: pAegis2 };
		_itemSlots[sAegis3] = { side: _secondary, type: "aegis", equip: sAegis3, mc: _secondary.mc.m_Aegis3, next: sAegis1, prev: sAegis2, dualSelectPartner: pAegis3 };
		_itemSlots[sWeapon] = { side: _secondary, type: "weapon", equip: sWeapon, mc: _secondary.mc.m_Weapon };
		_secondary.activeAegisStat = sActiveAegisStat;
		_secondary.activeAegisEquipLocation = null;
		_secondary.selectedAegisEquipLocation = _character.GetStat( sActiveAegisStat );
		_secondary.weaponSlot = _itemSlots[sWeapon];
		_secondary.slots = [ _itemSlots[sWeapon], _itemSlots[sAegis1], _itemSlots[sAegis2], _itemSlots[sAegis3] ];

		// wire up button mouse handlers
		for ( var s:String in _itemSlots ) {
			if ( _itemSlots[s].type == "aegis" ) {
				SetupButtonHandlers( _itemSlots[s].mc );
			}
		}
		
		// wire up background mouse handlers
		SetupGlobalMouseHandlers( m_Primary.m_Background );
		SetupGlobalMouseHandlers( m_Secondary.m_Background );
		SetupGlobalMouseHandlers( m_Primary.m_Weapon );
		SetupGlobalMouseHandlers( m_Secondary.m_Weapon );
		SetupGlobalMouseHandlers( m_Background );
		
		// layout bar internals
		LayoutBars();
		
		// position HUD elements
		PositionHUD();
		
		// initial load of equipment into slots
		LoadEquipment();

		// update active aegis values
		UpdateActiveAegis();

		// fetch initial aegis xp values
		UpdateAegisXP();
		
		// wire up signal listeners
		_character.SignalStatChanged.Connect( SlotStatChanged, this);
	    _inventory.SignalItemAdded.Connect( SlotItemAdded, this);
		_inventory.SignalItemAdded.Connect( SlotItemLoaded, this);
		_inventory.SignalItemMoved.Connect( SlotItemMoved, this);
		_inventory.SignalItemRemoved.Connect( SlotItemRemoved, this);
		_inventory.SignalItemChanged.Connect( SlotItemChanged, this);
		_inventory.SignalItemStatChanged.Connect( SlotItemStatChanged, this);

		// aegis xp listener
		_character.SignalTokenAmountChanged.Connect( SlotTokenAmountChanged, this );
		
		// attach to passivebar if needed
		AttachToPassiveBar( _attachToPassiveBar );
		
		// wire up event listener
		this.addEventListener("select", this, "AegisSelectHandler");
		this.addEventListener("rollover", this, "AegisRollOverHandler");
		this.addEventListener("rollout", this, "AegisRollOutHandler");
		
		this.addEventListener("dragStart", this, "DragStartHandler");
		this.addEventListener("dragEnd", this, "DragEndHandler");
		
		this.addEventListener("scale", this, "ScaleHandler");
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
			
			var firstButton:MovieClip = this["_" + s + "WeaponFirst"] ? (_showWeapons ? bar.m_Weapon : bar.m_Aegis1) : bar.m_Aegis1;
			var lastButton:MovieClip = this["_" + s + "WeaponFirst"] ? bar.m_Aegis3 : (_showWeapons ? bar.m_Weapon : bar.m_Aegis3);
			
			// position and resize background to wrap buttons
			bar.m_Background._x = bar.m_Background._y = 0;
			bar.m_Background._width = lastButton._x + lastButton._width + (_barPadding);
			bar.m_Background._height = lastButton._y + lastButton._height + (_barPadding);
		}
		
		// if hud is attached to passivebar, reset to default swap button position
		if ( _attachToPassiveBar ) {
			MoveToDefaultPosition();
		}
	}
	
	// position HUD elements on the screen
	private function PositionHUD():Void
	{
		// apply scale
		//m_Primary._xscale = m_Primary._yscale = _hudScale;
		//m_Secondary._xscale = m_Secondary._yscale = _hudScale;
		
		if ( _primaryPosition )
		{
			// Despite Point.x being a number, the +0 below is a quick way to ensure the ._x accepts the Point.x property.
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
			MoveToDefaultPosition();
		}
	}

	/**
	 * layout bars in same location as default passivebar swap buttons
	 */
	public function MoveToDefaultPosition(userTriggered:Boolean):Void
	{
		if ( _root.passivebar.m_Bar != undefined ) {

			var pb = _root.passivebar;
			
			var pbx:Number = pb.m_BaseWidth / 2 + pb.m_Button._x; // - 4;
			var pby:Number = pb.m_Bar._y; // - 5;
			
			var globalPassiveBarPos:Point = new Point( pbx, pby );
			pb.localToGlobal( globalPassiveBarPos );
			this.globalToLocal( globalPassiveBarPos );

			var primaryDefaultPosition = new Point( globalPassiveBarPos.x - m_Primary._width - 2, globalPassiveBarPos.y - m_Primary._height - 3 );
			var secondaryDefaultPosition = new Point( globalPassiveBarPos.x + 2, globalPassiveBarPos.y - m_Secondary._height - 3 );
			
			// userTriggered parameter needed to prevent the annoying pop-in when first loading into an area
			// when the bars are initially positioned
			if( userTriggered && _animateMovementsToDefaultPosition ) {
			
				m_Primary.tweenTo(1, {
						_x: primaryDefaultPosition.x,
						_y: primaryDefaultPosition.y
					},
					Bounce.easeOut
				);
				
				m_Secondary.tweenTo(1, {
						_x: secondaryDefaultPosition.x,
						_y: secondaryDefaultPosition.y
					},
					Bounce.easeOut
				);
				
			}
			else {
				m_Primary._x = primaryDefaultPosition.x;
				m_Primary._y = primaryDefaultPosition.y;
				m_Secondary._x = secondaryDefaultPosition.x;
				m_Secondary._y = secondaryDefaultPosition.y;
			}
			
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
	

	// restore default tints
	public function ApplyDefaultTints():Void {
		
		var defaults:Object = HUD.defaultSettingsPack;
		
		tintAegisPsychic = defaults.tintAegisPsychic;
		tintAegisCybernetic = defaults.tintAegisCybernetic;
		tintAegisDemonic = defaults.tintAegisDemonic;
		tintAegisEmpty = defaults.tintAegisEmpty;
		tintAegisStandard = defaults.tintAegisStandard;

		tintXPBackground = defaults.tintXPBackground;
		tintXPProgress = defaults.tintXPProgress;
		tintXPFull = defaults.tintXPFull;
		
		tintBarStandard = defaults.tintBarStandard;
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
		if ( item.m_Name == undefined || item.m_Name == "" ) item = undefined;
		
		slot.item = item;
		if ( slot.type == "aegis") {
			slot.aegisType = "empty";
			slot.aegisXP = undefined;
		}
		
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
				
				// if XP is being shown, fetch just this item's XP, the rest can wait for their own events
				UpdateAegisSlotXP(slot);
			}
			
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
			AddonUtils.Colorize( barMC.m_Background, _tintBarBackgroundByActiveAegis ? barTint : _tints.barStandard );
			barMC.m_Background.gotoAndStop("white");
			
			// neon glow entire bar
			if ( _neonEnabled && _neonGlowEntireBar ) {
				var entireGlow:GlowFilter = new GlowFilter(
					barTint, 	/* glow_color */
					0.8, 		/* glow_alpha */
					10, 		/* glow_blurX */
					10, 		/* glow_blurY */
					2,			/* glow_strength */
					3, 			/* glow_quality */
					false, 		/* glow_inner */
					false 		/* glow_knockout */
				);
				
				barMC.filters = [ entireGlow ];
			}
			else barMC.filters = [];
			
			// neon glow bar background
			if ( _neonEnabled && _neonGlowBarBackground ) {
				barMC.m_Background.gotoAndStop("black");

				// two different methods available here
				
				// option 1, bolder colour than #2
				// AddonUtils.Colorize( barMC.m_Background.m_Black, barTint );
				// AddonUtils.Colorize( barMC.m_Background, barTint );
				
				// option 2
				AddonUtils.Colorize( barMC.m_Background, barTint );

				// this happens regardless
				barMC.m_Background.m_White._visible = false;
				barMC.m_Background.m_Black._visible = true;
				
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
			
			// handle weapon slot
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
			var weaponTint:Number = _tintWeaponBackgroundByActiveAegis ? barTint : _tints.none;
			AddonUtils.Colorize( weaponSlotMC.m_Background, weaponTint );
			
			// tint weapon icon
			var weaponIconTint:Number = _tintWeaponIconByActiveAegis ? barTint : _tints.none;
			AddonUtils.Colorize( weaponSlotMC.m_Icon, weaponIconTint );
				
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

			// iterate through aegis slots
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

				// tint aegis icon
				var iconTint:Number = _tintAegisIconByType ? slotTint : _tints.none;
				AddonUtils.Colorize( slotMC.m_Icon, iconTint );
				
				// show xp display
				if ( !_showXP || slot.item == undefined ) {
					slotMC.m_XPBar._visible = slotMC.m_XPTextProgress._visible = slotMC.m_XPTextFull._visible = false;
				}
				else {

					// use text display
					if ( _xpIndicatorStyle == XPIndicatorStyles.Numbers ) {
						slotMC.m_XPBar._visible = false;

						if( slot.aegisXP >= 100 ) {
							slotMC.m_XPTextProgress._visible = false;
							slotMC.m_XPTextFull._visible = !_hideXPWhenFull;
						}
						else {
							slotMC.m_XPTextProgress._visible = true;
							slotMC.m_XPTextFull._visible = false;
						}
						
						AddonUtils.Colorize( slotMC.m_XPTextFull, _tints.xpFull );
						AddonUtils.Colorize( slotMC.m_XPTextProgress, _tints.xpProgress );
					}
					
					// use progress bar display
					else {
						slotMC.m_XPTextProgress._visible = false;
						slotMC.m_XPTextFull._visible = false;
						
						AddonUtils.Colorize( slotMC.m_XPBar.m_Background, _tints.xpBackground );						
						AddonUtils.Colorize( slotMC.m_XPBar.m_Progress, _tints.xpProgress );
						AddonUtils.Colorize( slotMC.m_XPBar.m_Full, _tints.xpFull );

						slotMC.m_XPBar._visible = true;

						if( slot.aegisXP >= 100 ) {
							slotMC.m_XPBar.m_Progress._visible = false;
							slotMC.m_XPBar.m_Background._visible = false;
							slotMC.m_XPBar.m_Full._visible = !_hideXPWhenFull;
						}
						else {
							slotMC.m_XPBar.m_Progress._visible = true;
							slotMC.m_XPBar.m_Background._visible = _showXPProgressBackground;
							slotMC.m_XPBar.m_Full._visible = false;
						}
					}
				}

				// show aegis background
				slotMC.m_Background._visible = _showAegisBackgroundBehaviour == SlotBackgroundBehaviour.ALWAYS
					|| ( _showAegisBackgroundBehaviour == SlotBackgroundBehaviour.WHEN_SLOTTED && slot.item != undefined );
				
				// tint aegis background
				AddonUtils.Colorize( slotMC.m_Background, _tintAegisBackgroundByType ? slotTint : _tints.none );

				// take neon glow off slot before the active check
				slotMC.filters = [];
				
				// handle active aegis higlighting
				if ( slot.equip == bar.activeAegisEquipLocation ) {

					// show aegis background
					slotMC.m_Background._visible = _showActiveAegisBackground;
					
					// tint aegis background
					switch( _tintActiveAegisBackgroundBehaviour ) {
						
						case ActiveAegisBackgroundTintBehaviour.NEVER: 		AddonUtils.Colorize( slotMC.m_Background, _tints.none ); break;
						case ActiveAegisBackgroundTintBehaviour.STANDARD: 	AddonUtils.Colorize( slotMC.m_Background, _tints.standard ); break;
						case ActiveAegisBackgroundTintBehaviour.AEGIS_TYPE:	AddonUtils.Colorize( slotMC.m_Background, slotTint ); break;
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

					// bring active aegis to front
					if ( slotMC.getDepth() < _itemSlots[slot.prev].mc.getDepth() ) slotMC.swapDepths( _itemSlots[slot.prev].mc );
					if ( slotMC.getDepth() < _itemSlots[slot.next].mc.getDepth() ) slotMC.swapDepths( _itemSlots[slot.next].mc );
				}
				
			}
		}	
	}
	
	// set the current active aegis stat straight from the game
	// note that this will NOT cause an invalidate() so no redraw will occur
	private function UpdateActiveAegis():Void
	{
		_primary.activeAegisEquipLocation = _character.GetStat( _primary.activeAegisStat );
		_secondary.activeAegisEquipLocation = _character.GetStat( _secondary.activeAegisStat );
		
		// if this happens when the selection catchup timer isn't running, update the selected as well
		if ( _swapTimeoutID == undefined ) {
			SyncSelectedWithActive();
		}
	}

	// swap to an aegis slot
	// -- note that slotNumber is equipment location in the inventory
	private function SwapToAegisSlot(equipLocation:Number, dualSelect:Boolean)
	{
		// do nothing if no slot location provided
		if ( equipLocation == undefined) return;
		
		var side = _itemSlots[equipLocation].side;

		// switch forward?
		if ( _itemSlots[ side.selectedAegisEquipLocation ].next == equipLocation )
		{
			// first param is first/second aegis, second param is forward/back
			Character.SwapAegisController( side == _primary, true);
		}
		
		// or switch back? (doing the extra check instead of a raw else prevents double-jumps with the switch latency)
		else if ( _itemSlots[ side.selectedAegisEquipLocation ].prev == equipLocation )
		{
			Character.SwapAegisController( side == _primary, false);
		}
		
		// clear existing post-swap callback
		PostSwapCatchup(true);
		
		// important to update the internal pointer for the aegis location
		// even before we find out if the swap was successful
		// otherwise rapid clicks can cause the selection to jump 2 spots
		side.selectedAegisEquipLocation = equipLocation;
		
		// select other side partner slot if dualSelect in use
		if ( dualSelect ) {
			SwapToAegisSlot( _itemSlots[equipLocation].dualSelectPartner );
		}
	}

	// post-swap callback that will catch up the selectedAegisEquipLocation for each side
	// this is needed in case of users going bonkers with very rapid clicks, which can
	// get out of sync with the server if the server drops one of the request packets
	// (yes it happens often under command spam)
	private function PostSwapCatchup(restart:Boolean):Void {
		if ( _swapTimeoutID != undefined ) {
			_global.clearTimeout( _swapTimeoutID );
			_swapTimeoutID = undefined;
		}
		
		// if restarting, not actioning, set up timer again
		if ( restart ) {
			_swapTimeoutID = setTimeout( Delegate.create(this, PostSwapCatchup), _postSwapCatchupInterval );
		}
		
		// otherwise action the catchup
		else {
			SyncSelectedWithActive();
		}
	}
	
	private function SyncSelectedWithActive():Void {
		
		if ( _primary.selectedAegisEquipLocation != _primary.activeAegisEquipLocation || _secondary.selectedAegisEquipLocation != _secondary.activeAegisEquipLocation ) {
			_primary.selectedAegisEquipLocation = _primary.activeAegisEquipLocation;
			_secondary.selectedAegisEquipLocation = _secondary.activeAegisEquipLocation;
			
			invalidate();
		}
	}
	
	// handle mouse clicks that select an aegis
	private function AegisSelectHandler(event:Object):Void {
		SwapToAegisSlot( event.itemSlot.equip, event.dualSelect );
	}

	// handle mouse rolling over an aegis
	private function AegisRollOverHandler(event:Object):Void {
		// prepare tooltip data
		if ( event.itemSlot.item != undefined ) {
			_tooltipSlot = event.itemSlot;
			StartTooltipTimeout();
		}
	}

	private function AegisRollOutHandler(event:Object):Void {
		StopTooltipTimeout();
		CloseTooltip();
	}
	
	private function StartTooltipTimeout():Void {
		if (_tooltipTimeoutID != undefined) return

		var delay:Number = DistributedValue.GetDValue("HoverInfoShowDelay");

		if( delay <= 0 ) OpenTooltip();
		else _tooltipTimeoutID = _global.setTimeout( Delegate.create( this, OpenTooltip ), delay * 1000 );
	}

	private function StopTooltipTimeout():Void {
		if ( _tooltipTimeoutID != undefined) {
			_global.clearTimeout( _tooltipTimeoutID );
			_tooltipTimeoutID = undefined;
		}
	}
    
    private function OpenTooltip():Void {
		// close any existing tooltip
		CloseTooltip();
		
		// don't show anything if setting disabled OR if the hud elements are currently being dragged
		if ( !_showTooltips || _dragging || (!_suppressTooltipsInCombat && _character.IsInCombat()) ) return;

        if ( _tooltipSlot.item != undefined ) {
            var tooltipData:TooltipData = TooltipDataProvider.GetInventoryItemTooltip( _inventory.GetInventoryID(), _tooltipSlot.equip );			
			_tooltip = TooltipManager.GetInstance().ShowTooltip( _tooltipSlot.mc, TooltipInterface.e_OrientationVertical, 0, tooltipData );
		}
    }
    
    private function CloseTooltip():Void {
		StopTooltipTimeout();
        if (_tooltip != undefined) {
            _tooltip.Close();
			_tooltip = undefined;
        }
    }

	// handle move / drag start of one or both bars
	private function DragStartHandler(event:Object):Void {

		// do nothing if scale and movement is prevented
		if ( _lockBars || _attachToPassiveBar ) return;
		
		// close any open tooltip
		CloseTooltip();
		
		// instantiate the drag proxy
		m_DragProxy = this.createEmptyMovieClip("m_DragProxy", this.getNextHighestDepth());

		if ( event.dual ) {
			_dragObjects = [ _primary.mc, _secondary.mc ];
		}
		else {
			_dragObjects = [ event.bar ];
		}
		
		this.onMouseMove = DragMovementHandler;
		m_DragProxy.startDrag();
		
	}
	
	private function DragMovementHandler():Void {
		
		for ( var i:Number = 0; i < _dragObjects.length; i++ ) {
			
			var moveObject:MovieClip = _dragObjects[i];
			moveObject._x += m_DragProxy._x - m_DragProxy._prevX;
			moveObject._y += m_DragProxy._y - m_DragProxy._prevY;
			
		}
		
		m_DragProxy._prevX = m_DragProxy._x;
		m_DragProxy._prevY = m_DragProxy._y;		
	}
	
	private function DragEndHandler(event:Object):Void {

		_dragObjects = undefined;
		
		this.onMouseMove = undefined;
		m_DragProxy.stopDrag();
		m_DragProxy.unloadMovie();
		m_DragProxy.removeMovieClip();
	}
	
	private function handleMousePress(controllerIdx:Number, keyboardOrMouse:Number, button:Number):Void {
		// only allow one mouse button to be pressed at once
		if ( _mouseDown != -1 ) return;
		_mouseDown = button;

		// TODO: check if no modifiers held down, and only fire click if that is the case, otherwise fire appropriate start drag etc
		if ( Key.isDown( dualDragModifier ) && button == dualDragButton ) {
			_dragging = true;
			dispatchEvent( { type:"dragStart", modifier:dualDragModifier, button:button, dual:true, bar: getBarMouseOver() } );
		}
		else if ( Key.isDown( singleDragModifier ) && button == singleDragButton ) {
			_dragging = true;
			dispatchEvent( { type:"dragStart", modifier:singleDragModifier, button:button, dual:false, bar: getBarMouseOver() } );
		}
		else {
			// check if an aegis selector button was involved
			var slot:Object = getItemSlotMouseOver();
			
			if ( slot.type == "aegis" ) {
				var dual:Boolean;
				if ( _dualSelectByDefault ) {
					dual = !(dualSelectWithModifier && Key.isDown(dualSelectModifier)) && !(dualSelectWithButton && button == dualSelectButton);
				}
				else {
					dual = (dualSelectWithModifier && Key.isDown(dualSelectModifier)) || (dualSelectWithButton && button == dualSelectButton);
				}

				dispatchEvent({ type:"select", modifier:dualSelectModifier, button:button, itemSlot:slot, dualSelect:dual });
			}
		}
	}
	
	private function handleMouseRelease(controllerIdx:Number, keyboardOrMouse:Number, button:Number):Void {
		// only propogate if the release is associated with the originally held down button
		if ( _mouseDown != button ) return;
		_mouseDown = -1;

		if( _dragging ) dispatchEvent({type:"dragEnd", button:button});
	}
	
	private function handleReleaseOutside(controllerIdx:Number, button:Number):Void {
		handleMouseRelease(controllerIdx, 0, button);
	}

	private function handleRollOver(mouseIdx:Number):Void {
		// check which aegis selector button was involved
		var slot:Object = getItemSlotMouseOver();
		dispatchEvent( { type:"rollover", itemSlot:slot } );
	}

	private function handleRollOut(mouseIdx:Number):Void {
		dispatchEvent( { type:"rollout" } );
	}
	
	private function handleMouseWheel(delta:Number, targetPath:String):Void {
		if( Key.isDown(scaleResetModifier) ) dispatchEvent( { type:"scale", delta:delta, targetPath:targetPath, reset:true } );
		else if ( Key.isDown(scaleModifier) ) dispatchEvent( { type:"scale", delta:delta, targetPath:targetPath, reset:false } );
	}

	
	private function getItemSlotMouseOver():Object {

		var slot;
		for ( var s:String in _itemSlots ) {
			if ( _itemSlots[s].mc.hitTest(_root._xmouse, _root._ymouse, true, true) ) {
				slot = _itemSlots[s];
				break;
			}
		}
		
		return slot;
	}
	
	private function getBarMouseOver():MovieClip {
		
		for ( var s:String in _sides ) {
			if ( _sides[s].mc.hitTest(_root._xmouse, _root._ymouse, true, true) ) return _sides[s].mc;
		}
		
		return undefined;
	}
	
	/**
	 * Sets up mouse event handlers for hud or bar movement
	 * 
	 * @param	mc Movieclip to configure move handlers on
	 */
	private function SetupGlobalMouseHandlers(mc:MovieClip) {
		
		if ( !mc ) return;
		
		mc.onPress = Delegate.create(this, handleMousePress);
		mc.onRelease = Delegate.create(this, handleMouseRelease);
		mc.onReleaseOutside = Delegate.create(this, handleReleaseOutside);
		mc["onPressAux"] = mc.onPress;
		mc["onReleaseAux"] = mc.onRelease;
		mc["onReleaseOutsideAux"] = mc.onReleaseOutside;
		
		mc["onMouseWheel"] = Delegate.create( this, handleMouseWheel );
	}
	
	
	/**
	 * Sets up mouse event handlers for aegis selector buttons
	 * 
	 * @param	mc Movieclip to configure rollovers on
	 */
	private function SetupButtonHandlers(mc:MovieClip) {

		if ( !mc ) return;
		
		SetupGlobalMouseHandlers( mc );
		
		mc.onRollOver = Delegate.create(this, handleRollOver);
		mc.onRollOut = Delegate.create(this, handleRollOut);
		mc.onDragOut = mc.onRollOut;
		mc.onDragOutAux = mc.onRollOut;
	}

	private function ScaleHandler(event:Object):Void {
		
		// simplified scale handler which doesn't bother scaling around centre of entire hud, unlike previous version

		// do nothing if scale and movement is prevented
		if ( _lockBars ) return;

		// scale in 5% increments
		if ( event.reset ) {
			hudScale = 100;
		}
		else {
			hudScale += event.delta * 5;
		}
	}

	
	// fetch aegis XP for each slotted controller, using tooltip data as the source of the values
	private function UpdateAegisXP():Void {
		
		// do nothing if XP isn't being shown
		if ( !_showXP ) {
			if ( _fetchXPAntiSpamTimeoutID != undefined) _global.clearTimeout( _fetchXPAntiSpamTimeoutID );
			_fetchXPAntiSpamTimeoutID = undefined;
			
			return;
		}
		
		// calculate interval values
		var now:Number = Number(new Date());
		var timeSinceFetch:Number = now - _lastXPFetchTime;

		// if within the spam interval since last successful fetch, start the timer or just wait for an existing one to finish
		if ( timeSinceFetch < _fetchXPAntiSpamInterval ) {
			if ( _fetchXPAntiSpamTimeoutID == undefined) {
				_fetchXPAntiSpamTimeoutID = _global.setTimeout( Delegate.create(this, UpdateAegisXP), _fetchXPAntiSpamInterval ); // Math.max(_fetchXPAntiSpamInterval - timeSinceFetch, 100) );
			}
			return;
		}
		
		// otherwise cancel any outstanding timer
		else if ( _fetchXPAntiSpamTimeoutID != undefined) _global.clearTimeout( _fetchXPAntiSpamTimeoutID );

		_fetchXPAntiSpamTimeoutID = undefined;

		// update last run time
		_lastXPFetchTime = now;
		
		// for each aegis controller, get the tooltip data and extract the XP value
		for ( var s:String in _itemSlots ) {
			UpdateAegisSlotXP( _itemSlots[s] );
		}

	}
	
	// update aegis xp for a single item
	private function UpdateAegisSlotXP(slot:Object):Void {
		
		// do nothing if there is nothing sensible to act on
		// important clause in there for efficiency -- the only way to get a slotted item away from 100 is to unslot it
		// which will clear the xp value, this when it gets reslotted after being upgraded it won't be on 100 anymore... :)
		if ( !_showXP || slot == undefined || slot.type != "aegis" || slot.item == undefined || slot.aegisXP == 100) return;

		var slotMC:MovieClip = slot.mc;
		
		// fetch tooltip for item
		var tooltipData:TooltipData = TooltipDataProvider.GetInventoryItemTooltip( _inventory.GetInventoryID(), slot.equip );

		// break out xp value
		var xpString:String = tooltipData.m_Descriptions[2];
		xpString = xpString.substring( xpString.indexOf(":") + 2, xpString.indexOf("%") );

		// strip the remaining HTML formatting
		var istart;
		while ((istart = xpString.indexOf("<")) != -1)
		{
			xpString = xpString.split(xpString.substr(istart, xpString.indexOf(">")-istart+1)).join("");
		}

		var xp:Number = Math.floor( Number(xpString) );

		// put xp value into slot and publish into component
		slot.aegisXP = xp == Number.NaN ? undefined : xp;

		// text display being used
		slotMC.m_XPTextProgress.m_Text.text = slotMC.m_XPTextFull.m_Text.text = xp == Number.NaN ? "?" : xp;
		
		// progress bar being used
		slot.mc.m_XPBar.m_Progress._xscale = xp == Number.NaN ? 150: xp;
		
		// when reaching 100, redraw to show the "Full" elements
		if ( xp >= 100 ) invalidate()
	}
	
	
	// signal handlers for inventory and character stat changes
	// I think some of these are not necessary just for Aegis or Weapon swapping, but they are the complete list
	// used by the default CharacterSheetController, as I'd rather cover everything than have
	// something not work in an unforeseen situation
	
	// handles active aegis being swapped
	private function SlotStatChanged(statID:Number):Void {
		// only proceed if stat is to do with aegis selector
		if ( !(statID == _primary.activeAegisStat || statID == _secondary.activeAegisStat) ) return;
		UpdateActiveAegis();	
		// TODO: play with the hotkeys to better manage this, there is a race condition and infinite loop of events happening otherwise
		/*
		if ( _dualSelectByDefault && _dualSelectFromHotkey ) {

			if ( statID == _primary.activeAegisStat ) {
				SwapToAegisSlot( _primary.activeAegisEquipLocation, true );
			}
			
			else {
				SwapToAegisSlot( _secondary.activeAegisEquipLocation, true );
			}
		}
		*/
		//UpdateActiveAegis();		
		invalidate();
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
	
	// aegis xp listener
	private function SlotTokenAmountChanged( tokenID:Number, newValue:Number, oldNumber:Number ) {
		if ( tokenID >= e_AegisTokenID_Min && tokenID <= e_AegisTokenID_Max ) UpdateAegisXP();
	}
	
	
	// separating this from AttachToPassiveBar to ensure only one of them runs at once, given how quickly it could be called in succession at startup
	private function FindPassiveBarToAttach(attach:Boolean):Void {
		if ( _root.passivebar.m_Bar.onTweenComplete == undefined ) {
			// if the thrash count is exceeded, reset count and do nothing
			if (_findPassiveBarThrashCount++ == 30) {
				_findPassiveBarThrashCount = 0;
				_findPassiveBarTimeoutID = undefined;
			}
			// otherwise try again
			else _findPassiveBarTimeoutID = _global.setTimeout( Delegate.create(this, AttachToPassiveBar), 100, attach );
			
			return;
		}

		// if we reached this far, reset thrash count
		_findPassiveBarThrashCount = 0;
		_findPassiveBarTimeoutID = undefined;
		
		AttachToPassiveBar( attach );
	}
	
	// hooks into the passivebar to set up proxies for open/close
	private function AttachToPassiveBar(attach:Boolean):Void {
		
		if ( _findPassiveBarTimeoutID != undefined ) return;
		
		var passivebar = _root.passivebar;
		
		// set up proxies and force HUD into position
		if ( attach ) {
			
			// make sure not to "re-attach"
			if( passivebar.m_Bar.onTweenComplete_AegisHUD_Saved == undefined ) {
				passivebar.m_Bar.onTweenComplete_AegisHUD_Saved = passivebar.m_Bar.onTweenComplete;
				// break the link
				passivebar.m_Bar.onTweenComplete = undefined;
				passivebar.m_Bar.onTweenComplete = Delegate.create(this, PassiveBarOnTweenCompleteProxy);
				
				MoveToDefaultPosition();
			}
		}
		
		// remove proxy and restore original function -- make sure not to "detach when not attached"
		else if( passivebar.m_Bar.onTweenComplete_AegisHUD_Saved != undefined ) {
			passivebar.m_Bar.onTweenComplete = passivebar.m_Bar.onTweenComplete_AegisHUD_Saved;
			passivebar.m_Bar.onTweenComplete_AegisHUD_Saved = undefined;
		}
	}
	
	// proxy function for hooking into the passivebar onTweenComplete listener that fires after each open/close
	private function PassiveBarOnTweenCompleteProxy():Void {
		// let the original function run
		_root.passivebar.m_Bar.onTweenComplete_AegisHUD_Saved();
		MoveToDefaultPosition(true);
	}

	
	// apply a bundle of settings all at once
	public function ApplySettingsPack(pack:Object) {
		
		for ( var s:String in pack ) {
			// TODO : implement something equivalent to AS3's .hasOwnProperty(name)
			this[s] = pack[s];
		}
	}

	/**
	 * handler for the swap AEGIS RPC calls
	 * 
	 * format of message is specific:
	 * <primary|secondary>.<next|prev>.<sequence>
	 * 
	 * sequence is just a unique number that forces the DValue SignalChanged to fire (becaues the value has changed)
	 * so if the same command is sent twice in a row it still triggers
	 * 
	 */
	
	private function SwapAegisRPCHandler():Void {
		
		// split message into component parts
		var parts:Array = String(_swapAegisRPC.GetValue()).split('.');
		
		if ( parts[0] == "primary" || parts[0] == "secondary" ) {
			
			var side:Object = this['_' + parts[0]];
			
			if ( parts[1] == "next" || parts[1] == "prev" ) {
				var direction:String = parts[1];
				
				SwapToAegisSlot( _itemSlots[ side.selectedAegisEquipLocation ][direction], _dualSelectByDefault && _dualSelectFromHotkey);
			}
		}
	}
	
	// getters & setters
	public function get showWeapons():Boolean { return _showWeapons; }
	public function set showWeapons(value:Boolean) {
		if( _showWeapons != value) {
			_showWeapons = value;
			LayoutBars();
		}
	}
	
	public function get showBarBackground():Boolean { return _showBarBackground; }
	public function set showBarBackground(value:Boolean) {
		if( _showBarBackground != value) {
			_showBarBackground = value;
			invalidate();
		}
	}
	
	public function get showXP():Boolean { return _showXP; }
	public function set showXP(value:Boolean) {
		if( _showXP != value ) {
			_showXP = value;
			
			if (_showXP) UpdateAegisXP();
			
			invalidate();
		}
	}
	
	public function get showTooltips():Boolean { return _showTooltips; }
	public function set showTooltips(value:Boolean) { _showTooltips = value; }
	
	public function get primaryPosition():Point { return new Point(m_Primary._x, m_Primary._y); }
	public function set primaryPosition(value:Point) { _primaryPosition = value; }

	public function get secondaryPosition():Point { return new Point(m_Secondary._x, m_Secondary._y); }
	public function set secondaryPosition(value:Point) { _secondaryPosition = value; }

	// overall hud scale
	public function get hudScale():Number { return _hudScale; }
	public function set hudScale(scale:Number) {
		if ( _hudScale == scale || lockBars ) return;

		if ( scale < minHUDScale ) _hudScale = minHUDScale;
		else if ( scale > maxHUDScale ) _hudScale = maxHUDScale;
		else if ( scale == Number.NaN ) _hudScale = 100;
		else _hudScale = scale;
		
		// apply scale to bars
		m_Primary._xscale = m_Primary._yscale = _hudScale;
		m_Secondary._xscale = m_Secondary._yscale = _hudScale;
		
		// if attached to passivebar, reset position
		if ( _attachToPassiveBar ) {
			MoveToDefaultPosition();
		}
	}
	

	public function get primaryWeaponFirst():Boolean { return _primaryWeaponFirst; }
	public function set primaryWeaponFirst(value:Boolean) {
		if( _primaryWeaponFirst != value ) {
			_primaryWeaponFirst = value;
			LayoutBars();
		}
	}

	public function get secondaryWeaponFirst():Boolean { return _secondaryWeaponFirst; }
	public function set secondaryWeaponFirst(value:Boolean) {
		if( _secondaryWeaponFirst != value ) {
			_secondaryWeaponFirst = value;
			LayoutBars();
		}
	}

	public function get lockBars():Boolean { return _lockBars; }
	public function set lockBars(value:Boolean) { _lockBars = value; }
		
	public function get barStyle():Number { return _barStyle; }	
	public function set barStyle(value:Number) {
		if ( _barStyle != value ) {
			_barStyle = value;
			LayoutBars();
		}
	}
	
	public function get neonGlowEntireBar():Boolean { return _neonGlowEntireBar; }
	public function set neonGlowEntireBar(value:Boolean):Void {
		if ( _neonGlowEntireBar != value ) {
			_neonGlowEntireBar = value;
			invalidate();
		}
	}
	
	public function get attachToPassiveBar():Boolean { return _attachToPassiveBar; }
	public function set attachToPassiveBar(value:Boolean):Void {
		_attachToPassiveBar = value;
		AttachToPassiveBar(_attachToPassiveBar);
	}
	
	public function get tintBarBackgroundByActiveAegis():Boolean { return _tintBarBackgroundByActiveAegis; }
	public function set tintBarBackgroundByActiveAegis(value:Boolean):Void {
		if ( _tintBarBackgroundByActiveAegis != value ) {
			_tintBarBackgroundByActiveAegis = value;
			invalidate();
		}
	}
	
	public function get neonGlowBarBackground():Boolean { return _neonGlowBarBackground; }
	public function set neonGlowBarBackground(value:Boolean):Void {
		if ( _neonGlowBarBackground != value ) {
			_neonGlowBarBackground = value;
			invalidate();
		}
	}
	
	public function get showWeaponBackgroundBehaviour():Number { return _showWeaponBackgroundBehaviour; }
	public function set showWeaponBackgroundBehaviour(value:Number):Void {
		if ( _showWeaponBackgroundBehaviour != value) {
			_showWeaponBackgroundBehaviour = value;
			invalidate();
		}
	}
	
	public function get tintWeaponBackgroundByActiveAegis():Boolean { return _tintWeaponBackgroundByActiveAegis; }
	public function set tintWeaponBackgroundByActiveAegis(value:Boolean):Void {
		if ( _tintWeaponBackgroundByActiveAegis != value) {
			_tintWeaponBackgroundByActiveAegis = value;
			invalidate();
		}
	}
	
	public function get tintWeaponIconByActiveAegis():Boolean { return _tintWeaponIconByActiveAegis; }
	public function set tintWeaponIconByActiveAegis(value:Boolean):Void {
		if( _tintWeaponIconByActiveAegis != value ) {
			_tintWeaponIconByActiveAegis = value;
			invalidate();
		}
	}
	
	public function get neonGlowWeapon():Boolean { return _neonGlowWeapon; }
	public function set neonGlowWeapon(value:Boolean):Void {
		if( _neonGlowWeapon != value ) {
			_neonGlowWeapon = value;
			invalidate();
		}
	}
	
	public function get showAegisBackgroundBehaviour():Number { return _showAegisBackgroundBehaviour; }
	public function set showAegisBackgroundBehaviour(value:Number):Void {
		if ( _showAegisBackgroundBehaviour != value ) {
			_showAegisBackgroundBehaviour = value;
			invalidate();
		}
	}
	
	public function get tintAegisBackgroundByType():Boolean { return _tintAegisBackgroundByType; }
	public function set tintAegisBackgroundByType(value:Boolean):Void {
		if( _tintAegisBackgroundByType != value ) {
			_tintAegisBackgroundByType = value;
			invalidate();
		}
	}
	
	public function get showActiveAegisBackground():Boolean { return _showActiveAegisBackground; }
	public function set showActiveAegisBackground(value:Boolean):Void {
		if( _showActiveAegisBackground != value ) {
			_showActiveAegisBackground = value;
			invalidate();
		}
	}
	
	public function get tintActiveAegisBackgroundBehaviour():Number { return _tintActiveAegisBackgroundBehaviour; }
	public function set tintActiveAegisBackgroundBehaviour(value:Number):Void {
		if( _tintActiveAegisBackgroundBehaviour != value ) {
			_tintActiveAegisBackgroundBehaviour = value;
			invalidate();
		}
	}
	
	public function get neonGlowAegis():Boolean { return _neonGlowAegis; }
	public function set neonGlowAegis(value:Boolean):Void {
		if( _neonGlowAegis != value ) {
			_neonGlowAegis = value;
			invalidate();
		}
	}
	
	public function get neonEnabled():Boolean { return _neonEnabled; }
	public function set neonEnabled(value:Boolean):Void {
		if( _neonEnabled != value ) {
			_neonEnabled = value;
			invalidate();
		}
	}
	public function get xpIndicatorStyle():Number { return _xpIndicatorStyle; }
	public function set xpIndicatorStyle(value:Number):Void {
		if ( _xpIndicatorStyle != value ) {
			_xpIndicatorStyle = value;
			if( showXP ) invalidate();
		}
	}
	public function get showXPProgressBackground():Boolean { return _showXPProgressBackground; }
	public function set showXPProgressBackground(value:Boolean):Void 
	{
		if ( _showXPProgressBackground != value ) {
			_showXPProgressBackground = value;
			
			if ( showXP && xpIndicatorStyle == XPIndicatorStyles.ProgressBar ) invalidate();
		}
	}
	public function get fetchXPAntiSpamInterval():Number { return _fetchXPAntiSpamInterval; }
	public function set fetchXPAntiSpamInterval(value:Number):Void 
	{
		if ( _fetchXPAntiSpamInterval != value) {
			_fetchXPAntiSpamInterval = value;
		}
	}

	public function get animateMovementsToDefaultPosition():Boolean { return _animateMovementsToDefaultPosition; }
	public function set animateMovementsToDefaultPosition(value:Boolean):Void {
		_animateMovementsToDefaultPosition = value;
	}

	public function get dualSelectByDefault():Boolean { return _dualSelectByDefault; }
	public function set dualSelectByDefault(value:Boolean):Void { _dualSelectByDefault = value; }

	public function get dualSelectFromHotkey():Boolean { return _dualSelectFromHotkey; }
	public function set dualSelectFromHotkey(value:Boolean):Void { _dualSelectFromHotkey = value; }

	public function get tintAegisIconByType():Boolean { return _tintAegisIconByType; }
	public function set tintAegisIconByType(value:Boolean):Void {
		if ( _tintAegisIconByType != value ) {
			_tintAegisIconByType = value;
			invalidate();
		}
	}


	/**
	 * I tried to use a static var here, but then whenever anything used it, it would create a reference to the property and was updating the values!!
	 * 
	 * readonly
	 */
	public static function get defaultSettingsPack():Object {
		
		return new Object( {
		
			slotSize: 30,
			barPadding: 5,
			slotSpacing: 4,
			hudScale: 100,
			maxHUDScale: 150,
			minHUDScale: 50,
			
			primaryPosition: undefined,
			secondaryPosition: undefined,
			
			barStyle: 0,
			neonGlowEntireBar: false,
			lockBars: false,
			attachToPassiveBar: false,
			animateMovementsToDefaultPosition: true,
			
			showBarBackground: true,
			tintBarBackgroundByActiveAegis: true,
			neonGlowBarBackground: true,

			showWeapons: true,
			primaryWeaponFirst: false,
			secondaryWeaponFirst: true,
			
			showWeaponBackgroundBehaviour: 0,
			tintWeaponBackgroundByActiveAegis: false,
			tintWeaponIconByActiveAegis: false,
			neonGlowWeapon: false,
			
			showXP: true,
			showXPProgressBackground: true,
			xpIndicatorStyle: 1,
			hideXPWhenFull: false,
			fetchXPAntiSpamInterval: 1000,

			showTooltips: true,
			suppressTooltipsInCombat: true,

			showAegisBackgroundBehaviour: 0,
			tintAegisBackgroundByType: false,
			tintAegisIconByType: false,
			showActiveAegisBackground: true,
			tintActiveAegisBackgroundBehaviour: 0,
			neonGlowAegis: true,
			
			neonEnabled: true,

			dualSelectWithModifier: true,
			dualSelectWithButton: true,
			dualSelectByDefault: true,
			dualSelectFromHotkey: true,
			
			tintAegisPsychic:		0xbf00ff,
			tintAegisCybernetic:	0x0099ff,
			tintAegisDemonic:		0xdd0000,
			tintAegisEmpty:			0x999999,
			tintAegisStandard:		0x006AFF,

			tintXPBackground:		0xffffff,
			tintXPProgress:			0x00ff88,		/* 0x00E5A3 */
			tintXPFull:				0xff6600,		/* // 0x4EE500 // 0x19FDFF */
			
			tintBarStandard:		0x000000
		});
	}
	
	public function get slotSize():Number { return _slotSize; }
	public function set slotSize(value:Number):Void {
		if( _slotSize != value ) {
			_slotSize = value;
			LayoutBars();
		}
	}
	public function get barPadding():Number { return _barPadding; }
	public function set barPadding(value:Number):Void {
		if( _barPadding != value ) {
			_barPadding = value;
			LayoutBars();
		}
	}
	public function get slotSpacing():Number { return _slotSpacing; }
	public function set slotSpacing(value:Number):Void {
		if ( _slotSpacing != value ) {
			_slotSpacing = value;
			LayoutBars();
		}
	}

	public function get tintAegisPsychic():Number { return _tints.psychic };
	public function set tintAegisPsychic(value:Number):Void {
		if ( _tints.psychic != value && AddonUtils.isRGB(value)) {
			_tints.psychic = value;
			invalidate();
		}
	}
	
	public function get tintAegisCybernetic():Number { return _tints.cyber };
	public function set tintAegisCybernetic(value:Number):Void {
		if ( _tints.cyber != value && AddonUtils.isRGB(value)) {
			_tints.cyber = value;
			invalidate();
		}
	}

	public function get tintAegisDemonic():Number { return _tints.demonic };
	public function set tintAegisDemonic(value:Number):Void {
		if ( _tints.demonic != value && AddonUtils.isRGB(value)) {
			_tints.demonic = value;
			invalidate();
		}
	}

	public function get tintAegisEmpty():Number { return _tints.empty };
	public function set tintAegisEmpty(value:Number):Void {
		if ( _tints.empty != value && AddonUtils.isRGB(value)) {
			_tints.empty = value;
			invalidate();
		}
	}

	public function get tintAegisStandard():Number { return _tints.standard };
	public function set tintAegisStandard(value:Number):Void {
		if ( _tints.standard != value && AddonUtils.isRGB(value)) {
			_tints.standard = value;
			invalidate();
		}
	}
	
	public function get tintXPBackground():Number { return _tints.xpBackground };
	public function set tintXPBackground(value:Number):Void {
		if ( _tints.xpBackground != value && AddonUtils.isRGB(value)) {
			_tints.xpBackground = value;
			invalidate();
		}
	}

	public function get tintXPProgress():Number { return _tints.xpProgress };
	public function set tintXPProgress(value:Number):Void {
		if ( _tints.xpProgress != value && AddonUtils.isRGB(value)) {
			_tints.xpProgress = value;
			invalidate();
		}
	}

	public function get tintXPFull():Number { return _tints.xpFull };
	public function set tintXPFull(value:Number):Void {
		if ( _tints.xpFull != value && AddonUtils.isRGB(value)) {
			_tints.xpFull = value;
			invalidate();
		}
	}

	public function get tintBarStandard():Number { return _tints.barStandard };
	public function set tintBarStandard(value:Number):Void {
		if ( _tints.barStandard != value && AddonUtils.isRGB(value)) {
			_tints.barStandard = value;
			invalidate();
		}
	}

	public function get hideXPWhenFull():Boolean { return _hideXPWhenFull; }
	public function set hideXPWhenFull(value:Boolean):Void {
		if ( _hideXPWhenFull != value ) {
			_hideXPWhenFull = value;
			
			if ( showXP ) invalidate();
		}
		
	}

}