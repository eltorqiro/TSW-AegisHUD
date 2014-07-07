import com.Components.WinComp;
import com.GameInterface.Tooltip.TooltipData;
import com.Utils.Point;
import gfx.core.UIComponent;
import mx.utils.Delegate;
import com.GameInterface.Chat;
import com.GameInterface.DistributedValue;
import com.Utils.Archive;
import com.GameInterface.UtilsBase;

import com.GameInterface.Inventory;
import com.Utils.ID32;
import com.GameInterface.Game.Character;
import com.GameInterface.Tooltip.TooltipDataProvider;
import com.GameInterface.Lore
import com.GameInterface.Game.Shortcut;
import flash.filters.GlowFilter

import com.ElTorqiro.AegisHUD.AegisBar;
import com.ElTorqiro.AegisHUD.ConfigWindowContent;
import com.ElTorqiro.AegisHUD.Enums.AegisBarLayoutStyles;

class com.ElTorqiro.AegisHUD.AegisHUD
{
	// constants
	private static var AEGIS_SLOT_ACHIEVEMENT:Number = 6817;	// The Lore number that unlocks the AEGIS system
																// 6817 is pulled straight from Funcom's PassiveBar

	// movie clip elements
	private var m_PrimaryBar:AegisBar;
	private var m_SecondaryBar:AegisBar;
	private var m_ConfigWindow:WinComp;
	private var m_LinkedDragProxy:MovieClip;
	
	// movieclip owner for visual elements
	private var _hostMC:MovieClip;
	
	// user configurable option
	private var _hideDefaultSwapButtons:Boolean = true;
	private var _linkBars:Boolean = true;
	private var _layoutStyle:Number = 0;
	private var _showWeapons:Boolean = true;
	private var _showWeaponHighlight:Boolean = true;
	private var _showBarBackground:Boolean = true;
	private var _showXPBars:Boolean = false;
	private var _showTooltips:Boolean = false;
	private var _primaryBarWeaponFirst:Boolean = true;
	private var _secondaryBarWeaponFirst:Boolean = true;
	private var _enableDrag = true;

	private var _slotSize:Number = 30;
	private var _barPadding:Number = 5;
	private var _slotSpacing:Number = 4;
	private var _hudScale:Number = 100;
	
	// position restoration for windows
	// *** never use the getter for these positions internally, only use them directly ***
	private var _primaryBarPosition:Point;
	private var _secondaryBarPosition:Point;

	// utility objects
	private var _character:Character;
	private var _inventory:Inventory;
	private var _iconLoader:MovieClipLoader;
	private var _findPassiveBarThrashCount:Number = 0;
	
	// external distributed value listeners
	private var _showAegisSwapDV:DistributedValue;


	/**
	 * constructor
	 * @param	parentMC The parent movieclip the HUD should be placed under
	 * @param	hostMCName Name of the movieclip that will be created under the parent to host all AEGIS content -- default "m_AegisHUD"
	 * @param	deferCreate Don't create the HUD immedately -- handy if a lot of visual parameters need to be set prior to HUD creation to prevent a heap of Layouts
	 */
	public function AegisHUD(parentMC:MovieClip, hostMCName:String, initObj:Object, deferCreate:Boolean)
	{
		// if no parentMC is provided, do nothing at all
		if (parentMC == undefined) return;
		
		// establish initialisation values
		for (var i:String in initObj)
		{
			this[i] = initObj[i];
		}
		
		// handle if the toon has not unlocked the AEGIS system, but might do so during the session
		if ( Lore.IsLocked(AEGIS_SLOT_ACHIEVEMENT) )  Lore.SignalTagAdded.Connect(SlotTagAdded, this);

		// handle the TSW user config option for showing/hiding AEGIS HUD UI
		_showAegisSwapDV = DistributedValue.Create( "ShowAegisSwapUI" );
		_showAegisSwapDV.SignalChanged.Connect( SlotShowAegisSwapChanged, this);

		// reserve host movie clip that all AegisHUD content will be placed into
		_hostMC = ( hostMCName == undefined || hostMCName == "") ? parentMC : parentMC.createEmptyMovieClip( "m_AegisHUD", parentMC.getNextHighestDepth() );
		
		// immediately create HUD unless instructed otherwise
		if (deferCreate == undefined || deferCreate == false )  CreateHUD();
	}

	// pseudo-destructor, should be called immediately before deleting the object
	public function Destroy():Void
	{	
		// clean up listeners
		Lore.SignalTagAdded.Disconnect(SlotTagAdded, this);
		_showAegisSwapDV.SignalChanged.Disconnect( SlotShowAegisSwapChanged, this );

		m_PrimaryBar.Destroy();
		m_SecondaryBar.Destroy();
		
		// clean up movie clips
		_hostMC.removeMovieClip();
		
		// restore default buttons -- this forced behaviour may not be desirable, the host project may want them to remain hidden
		hideDefaultSwapButtons = false;
	}
	
	/**
	 * main activation routine for creating and initialising the bars
	 * abstracted away from other startup functions so it can be called if AEGIS is unlocked during a play session rather than being already unlocked at the start
	 */
	public function CreateHUD():Void
	{
		// do nothing at all if AEGIS system is not unlocked or HUD is not set visible
		if ( Lore.IsLocked(AEGIS_SLOT_ACHIEVEMENT) ) return;
		
		// remove any existing bars, saving their positions first
		if ( m_PrimaryBar ) {
			primaryBarPosition = new Point(m_PrimaryBar._x, m_PrimaryBar._y);
			m_PrimaryBar.removeMovieClip();
		}
		if ( m_SecondaryBar ) {
			secondaryBarPosition = new Point(m_SecondaryBar._x, m_SecondaryBar._y);
			m_SecondaryBar.removeMovieClip();
		}
		
		// only continue loading if the HUD is set visible in TSW options
		if ( !Boolean(_showAegisSwapDV.GetValue()) ) return;
		
		var _character:Character = Character.GetClientCharacter();
		var _inventory:Inventory = new Inventory( new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, Character.GetClientCharID().GetInstance()) );

		// create bars
		m_PrimaryBar = _hostMC.attachMovie("AegisBar", "m_PrimaryBar", _hostMC.getNextHighestDepth()).init( AegisBar.AEGIS_GROUP_PRIMARY, _character, _inventory );
		m_PrimaryBar.handleDrag = false;
		m_PrimaryBar.showBackground = this.showBarBackground;
		m_PrimaryBar.showXPBar = this.showXPBars;
		m_PrimaryBar.weaponFirst = this.primaryBarWeaponFirst;
		m_PrimaryBar.showWeapon = this.showWeapons;
		m_PrimaryBar.showWeaponHighlight = this.showWeaponHighlight;
		m_PrimaryBar.layoutStyle = this.layoutStyle;

		m_SecondaryBar = _hostMC.attachMovie("AegisBar", "m_SecondaryBar", _hostMC.getNextHighestDepth()).init( AegisBar.AEGIS_GROUP_SECONDARY, _character, _inventory );
		m_SecondaryBar.handleDrag = false;
		m_SecondaryBar.showBackground = this.showBarBackground;
		m_SecondaryBar.showXPBar = this.showXPBars;
		m_SecondaryBar.weaponFirst = this.secondaryBarWeaponFirst;
		m_SecondaryBar.showWeapon = this.showWeapons;
		m_SecondaryBar.showWeaponHighlight = this.showWeaponHighlight;
		m_SecondaryBar.layoutStyle = this.layoutStyle;

		// config options
		HideDefaultSwapButtons();

		// wire up signals
		m_PrimaryBar.SignalStartDrag.Connect(MoveDragHandler, this);
		m_PrimaryBar.SignalStopDrag.Connect(MoveDragReleaseHandler, this);
		m_SecondaryBar.SignalStartDrag.Connect(MoveDragHandler, this);
		m_SecondaryBar.SignalStopDrag.Connect(MoveDragReleaseHandler, this);
		
		
		// layout bars on screen per user preferences
		Layout();
	}

	// layout bar positions on the screen
	public function Layout():Void
	{
		// can't layout if there is nothing to layout
		if ( m_PrimaryBar == undefined )  return;

		if ( _primaryBarPosition )
		{
			// Despite Point.x being a number, the +0 below is a quicker way of doing Math.round() on the Point.x property.
			// If not doing this, then the number prints out as "xxx", but seems to get sent to the _x property as "xxx.0000000000"
			// which the _x setter fails to interpret for some reason and does not set.
			m_PrimaryBar._x = _primaryBarPosition.x + 0;
			m_PrimaryBar._y = _primaryBarPosition.y + 0;
			
			m_SecondaryBar._x = _secondaryBarPosition.x + 0;
			m_SecondaryBar._y = _secondaryBarPosition.y + 0;
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
		m_PrimaryBar._x = Math.round( Stage["visibleRect"].width / 2 - m_PrimaryBar._width - 3 );
		m_SecondaryBar._x = Math.round( m_PrimaryBar._x + m_PrimaryBar._width + 6 );
		m_PrimaryBar._y = m_SecondaryBar._y = Math.round( (_root.passivebar._y != undefined ? _root.passivebar._y : Stage["visibleRect"].bottom - 75) - m_PrimaryBar._height - 3 );
	}

	// handler for situation where AEGIS system becomes unlocked during play session
	private function SlotTagAdded(tag:Number)
	{
		if (tag == AEGIS_SLOT_ACHIEVEMENT)
		{
			Lore.SignalTagAdded.Disconnect(SlotTagAdded, this);
			CreateHUD();
		}
	}

	// handle user changing AEGIS swap visibility in control panel
	function SlotShowAegisSwapChanged()
	{
		CreateHUD();
	}
	
	// Move Drag Handler
	private function MoveDragHandler(bar:MovieClip):Void
	{
		if ( !enableDrag ) return;

		// highlight bars to indicate which one(s) will drag
		var filter_glow:GlowFilter = new GlowFilter(
			0x0099ff, 	/* glow_color */
			0.8, 		/* glow_alpha */
			10, 		/* glow_blurX */
			10, 		/* glow_blurY */
			2,			/* glow_strength */
			3, 			/* glow_quality */
			false, 		/* glow_inner */
			false 		/* glow_knockout */
		);
		
		// since flash can only drag one item at a time with startDrag(), create a proxy drag object to drag around
		if ( linkBars )
		{
			m_PrimaryBar.filters = [filter_glow];
			m_SecondaryBar.filters = [filter_glow];
			
			m_LinkedDragProxy = _hostMC.createEmptyMovieClip("m_LinkedDragProxy", _hostMC.getNextHighestDepth());
			_hostMC.onMouseMove = DragLinkedBarsHandler;
			m_LinkedDragProxy.startDrag();
		}
		
		else
		{
			bar.startDrag();
			bar.filters = [filter_glow];
		}
	}

	// move handler for dragging both bars as one
	private function DragLinkedBarsHandler():Void
	{
		m_PrimaryBar._x += m_LinkedDragProxy._x - m_LinkedDragProxy._prevX;
		m_PrimaryBar._y += m_LinkedDragProxy._y - m_LinkedDragProxy._prevY;
		m_SecondaryBar._x += m_LinkedDragProxy._x - m_LinkedDragProxy._prevX;
		m_SecondaryBar._y += m_LinkedDragProxy._y - m_LinkedDragProxy._prevY;
		
		m_LinkedDragProxy._prevX = m_LinkedDragProxy._x;
		m_LinkedDragProxy._prevY = m_LinkedDragProxy._y;
	}

	//Move Drag Release
	private function MoveDragReleaseHandler(bar:MovieClip):Void
	{
		// destroy proxy drag object
		if ( linkBars )
		{
			// remove highlight
			m_PrimaryBar.filters = [];
			m_SecondaryBar.filters = [];
			
			m_LinkedDragProxy.stopDrag();
			_hostMC.onMouseMove = undefined;
			m_LinkedDragProxy.removeMovieClip();
		}
		
		else
		{
			bar.stopDrag();
			bar.filters = [];
		}
	}

	// hide or show default buttons
	private function HideDefaultSwapButtons():Void
	{
		// hack to wait for the passivebar to be loaded, as it actually gets unloaded during teleports etc, not just deactivated
		if ( !_root.passivebar.LoadAegisButtons )
		{
			if (_findPassiveBarThrashCount++ == 10)
			{
				UtilsBase.PrintChatText("ElTorqiro_AegisHUD: Could not find default AEGIS swap buttons in a reasonable time, stopping the search.");
				_findPassiveBarThrashCount = 0;
			}

			else
			{
				_global.setTimeout( Delegate.create(this, HideDefaultSwapButtons), 300);
			}
			
			return;
		}
		_findPassiveBarThrashCount = 0;
		
		// hide buttons
		if ( hideDefaultSwapButtons )
		{
			// note that none of these removal methods work after zoning if the module is set to GMF_DONT_UNLOAD
			// as the default inbuilt HUD does get reloaded on zoning, not just deactivated, so _root.passivebar wouldn't exist
			// when this function gets called
			// 
			// if for some reason the module must be GMF_DONT_UNLOAD then some kind of polling routine will need to be
			// used to checek for the existence of _root.passivebar
			
			// this is very hacky, it's the only way I can prevent the default swap buttons being loaded
			// refer to GUI.HUD.PassiveBar.LoadAegisButtons()
			_root.passivebar.AEGIS_SLOT_ACHIEVEMENT = null;
			_root.passivebar.LoadAegisButtons();
			
			// seems like this would be a race condition, but it seems to reliably clean up any clips that get through
			// BUT ONLY ON INITIAL LOAD, not on signal triggered loads
			// these lines are currently taken care of by _root.passivebar.LoadAegisButtons()
			//			_root.passivebar.m_PrimaryAegisSwap.removeMovieClip();
			//			_root.passivebar.m_SecondaryAegisSwap.removeMovieClip();
			
			
			/* none of the below methods solve the problem reliably, kept here for reference
			 * 
				delete _root.passivebar.LoadAegisButtons;	// actually does delete the function, but next time it is called it comes back and runs
				_root.passivebar.LoadAegisButtons = function() { UtilsBase.PrintChatText("test"); };	// can't overwrite function, unlike javascript

				delete _root.passivebar.m_Inventory; // actually does delete the property, and prevents the icon loading, but the movieclip still gets added so it remains a clickable empty square
				
				_root.passivebar.m_PrimaryAegisSwap._visible = false;	// race condition, same reason as the above removeMovieClip() only works on initial load
			
				_root.passivebar.attachMovie("AegisButton", "m_PrimaryAegisSwap", getNextHighestDespth() ); // can't block by taking the name first, also a race condition anyway
			*/
				
		}

		// restore default buttons if they have been previously disabled
		// having the conditional check on the current _root.passivebar.AEGIS_SLOT_ACHIEVEMENT value is necessary
		// otherwise on initial load the button icons don't load because LoadAegisButtons() is called too quickly back to back and the icon loader hasn't finished loading
		else if ( _root.passivebar.AEGIS_SLOT_ACHIEVEMENT != AEGIS_SLOT_ACHIEVEMENT )
		{
			_root.passivebar.AEGIS_SLOT_ACHIEVEMENT = AEGIS_SLOT_ACHIEVEMENT;
			_root.passivebar.LoadAegisButtons();
		}
	}
	
	
	// getters & setters
	
	// prevents the default aegis swap buttons in PassiveBar from being shown
	public function get hideDefaultSwapButtons():Boolean {
		return _hideDefaultSwapButtons;
	}
	public function set hideDefaultSwapButtons(value:Boolean) {
		_hideDefaultSwapButtons = value;
		HideDefaultSwapButtons();
	}
		
	// link bars together when being dragged
	public function get linkBars():Boolean {
		return _linkBars;
	}
	public function set linkBars(value:Boolean) {
		_linkBars = value;
	}

	public function get showWeapons():Boolean {
		return _showWeapons;
	}
	public function set showWeapons(value:Boolean) {
		_showWeapons = value;
		
		m_PrimaryBar.showWeapon = _showWeapons;
		m_SecondaryBar.showWeapon = _showWeapons;
	}
	
	public function get showWeaponHighlight():Boolean {
		return _showWeaponHighlight;
	}
	public function set showWeaponHighlight(value:Boolean) {
		_showWeaponHighlight = value;
		
		m_PrimaryBar.showWeaponHighlight = _showWeaponHighlight;
		m_SecondaryBar.showWeaponHighlight = _showWeaponHighlight;
	}
	
	public function get showBarBackground():Boolean {
		return _showBarBackground;
	}
	public function set showBarBackground(value:Boolean) {
		_showBarBackground = value;
		
		m_PrimaryBar.showBackground = _showBarBackground;
		m_SecondaryBar.showBackground = _showBarBackground;
	}
	
	public function get showXPBars():Boolean {
		return _showXPBars;
	}
	public function set showXPBars(value:Boolean) {
		_showXPBars = value;
		
		m_PrimaryBar.showXPBar = true;
		m_SecondaryBar.showXPBar = true;
	}
	
	public function get showTooltips():Boolean {
		return _showTooltips;
	}
	public function set showTooltips(value:Boolean) {
		_showTooltips = value;
	}
	
	// readonly
	public function get primaryBar():AegisBar {
		return m_PrimaryBar;
	}
	
	// readonly
	public function get secondaryBar():AegisBar {
		return m_SecondaryBar;
	}
	
	public function get primaryBarPosition():Point {
		if ( m_PrimaryBar ) return new Point(m_PrimaryBar._x, m_PrimaryBar._y);
		return _primaryBarPosition;
	}
	public function set primaryBarPosition(value:Point) {
		_primaryBarPosition = value;
	}

	public function get secondaryBarPosition():Point {
		if (m_SecondaryBar ) return new Point(m_SecondaryBar._x, m_SecondaryBar._y);
		return _secondaryBarPosition;
	}
	public function set secondaryBarPosition(value:Point) {
		_secondaryBarPosition = value;
	}

	public function get primaryBarWeaponFirst():Boolean {
		return _primaryBarWeaponFirst;
	}
	public function set primaryBarWeaponFirst(value:Boolean) {
		_primaryBarWeaponFirst = value;
		primaryBar.weaponFirst = _primaryBarWeaponFirst;
	}

	public function get secondaryBarWeaponFirst():Boolean {
		return _secondaryBarWeaponFirst;
	}
	public function set secondaryBarWeaponFirst(value:Boolean) {
		_secondaryBarWeaponFirst = value;
		secondaryBar.weaponFirst = _secondaryBarWeaponFirst;
	}

	public function get enableDrag():Boolean {
		return _enableDrag;
	}
	public function set enableDrag(value:Boolean) {
		_enableDrag = value;
	}
	
	
	public function get layoutStyle():Number {
		return _layoutStyle;
	}	
	// TODO: some sanity checking to make sure this is in a valid range of available styles, although AegisBar currently filters that
	public function set layoutStyle(value:Number) {
		_layoutStyle = value;
		m_PrimaryBar.layoutStyle = _layoutStyle;
		m_SecondaryBar.layoutStyle = _layoutStyle;
	}
}
