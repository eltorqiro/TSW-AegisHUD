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
	private var _layoutStyle:Number = 1;
	private var _showWeapons:Boolean = true;
	private var _showWeaponGlow:Boolean = true;
	private var _showBarBackground:Boolean = true;
	private var _showXPBars:Boolean = false;
	private var _showTooltips:Boolean = true;

	// position restoration for windows
	private var _primaryStart:Point;
	private var _secondaryStart:Point;

	// utility objects
	private var _character:Character;
	private var _inventory:Inventory;
	

	/**
	 * constructor
	 * @param	parentMC The parent movieclip the HUD should be placed under
	 * @param	hostMCName Name of the movieclip that will be created under the parent to host all AEGIS content -- if no name given, HUD will be placed directly into parent
	 * @param	deferCreate Don't create the HUD immedately -- handy if a lot of visual parameters need to be set prior to HUD creation to prevent a heap of Layouts
	 */
	public function AegisHUD(parentMC:MovieClip, hostMCName:String, deferCreate:Boolean)
	{
		// if no parentMC is provided, do nothing at all
		if (parentMC == undefined) return;
		
		// handle if the toon has not unlocked the AEGIS system, but does so during the session
		Lore.SignalTagAdded.Connect(SlotTagAdded, this);
		
		// reserve host movie clip that all AegisHUD content will be placed into
		_hostMC = ( hostMCName == undefined || hostMCName == "") ? parentMC : parentMC.createEmptyMovieClip( "m_AegisHUD", parentMC.getNextHighestDepth() );
		
		// immediately create HUD unless instructed otherwise
		if (deferCreate == undefined || deferCreate == false )  CreateHUD();
	}

	// pseudo-destructor, should be called immediately before deleting the object
	public function Destroy():Void
	{
		// clean up elements
		_hostMC.removeMovieClip();
		
		// restore default buttons -- this forced behaviour may not be desirable, the host project may want them to remain hidden
		hideDefaultSwapButtons = false;
	}
	

	// module activated (i.e. its distributed value set to 1)
	// saved config data is passed in
	function OnModuleActivated(archive:Archive)
	{
		UtilsBase.PrintChatText("AEGIS.HUD activated");
		
		// visual settings
		//_showWeapons = _archive.FindEntry( "ShowWeapons", _showWeapons );
		//_showWeapons = _archive.FindEntry( "ShowWeaponGlow", _showWeaponGlow );
		//_showWeapons = _archive.FindEntry( "ShowBarBackground", _showBarBackground );
		//_showWeapons = _archive.FindEntry( "ShowXPBars", _showXPBars );
		//_showWeapons = _archive.FindEntry( "ShowTooltips", _showTooltips );

		// layout & position settings
		//_LayoutStyle = archive.FindEntry( "LayoutStyle", _LayoutStyle );
		//_PrimaryPos = new Point( _archive.FindEntry("PrimaryX", _PrimaryPos.x), _archive.FindEntry("PrimaryY", _PrimaryPos.y) );
		//_SecondaryPos = new Point( _archive.FindEntry("SecondaryX", _SecondaryPos.x), _archive.FindEntry("SecondaryY", _SecondaryPos.y) );
		//_ConfigPos = new Point( _archive.FindEntry("ConfigyX", _ConfigPos.x), _archive.FindEntry("ConfigY", _ConfigPos.y) );

		// config options
		//_hideDefaultSwapButtons = _archive.FindEntry("HideDefaultSwapButtons", _hideDefaultSwapButtons );
		//_linkBars = _archive.FindEntry( "LinkBars", _linkBars );
	}

	// main activation routine for creating and initialising the bars
	// abstracted away from other startup functions so it can be called if AEGIS
	// is unlocked during a play session rather than being already unlocked at the start
	public function CreateHUD():Void
	{
		// do nothing at all if AEGIS system is not unlocked
		if ( Lore.IsLocked(AEGIS_SLOT_ACHIEVEMENT) ) return;
		
		// remove any existing bars
		if ( m_PrimaryBar != undefined ) m_PrimaryBar.removeMovieClip();
		if ( m_SecondaryBar != undefined )  m_SecondaryBar.removeMovieClip();
		
		var _character:Character = Character.GetClientCharacter();
		var _inventory:Inventory = new Inventory( new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, Character.GetClientCharID().GetInstance()) );

		// create bars
		m_PrimaryBar = _hostMC.attachMovie("AegisBar", "m_PrimaryBar", _hostMC.getNextHighestDepth()).init( AegisBar.AEGIS_GROUP_PRIMARY, _character, _inventory );
		m_PrimaryBar.handleDrag = false;
		m_PrimaryBar.showXPBar = _showXPBars;

		m_SecondaryBar = _hostMC.attachMovie("AegisBar", "m_SecondaryBar", _hostMC.getNextHighestDepth()).init( AegisBar.AEGIS_GROUP_SECONDARY, _character, _inventory );
		m_SecondaryBar.handleDrag = false;
		m_SecondaryBar.showXPBar = _showXPBars;

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
		
		// set default positions to simulate the default buttons
		if (m_PrimaryBar._x == 0 && m_PrimaryBar._y == 0)
		{
			// ... surprised this worked without some localToGlobal() usage
			m_PrimaryBar._x = Stage.visibleRect.width / 2 - m_PrimaryBar._width - 5;
			m_SecondaryBar._x = m_PrimaryBar._x + m_PrimaryBar._width + 10;
			m_PrimaryBar._y = m_SecondaryBar._y = (_root.passivebar._y != undefined ? _root.passivebar._y : Stage.visibleRect.bottom - 75) - m_PrimaryBar._height - 5;
		}
	}


	// handler for situation where AEGIS system becomes unlocked during play session
	private function SlotTagAdded(tag:Number)
	{
		if (tag == AEGIS_SLOT_ACHIEVEMENT)  CreateHUD();
	}

	// Move Drag Handler
	private function MoveDragHandler(bar:MovieClip):Void
	{
		// since flash can only drag one item at a time with startDrag(), create a proxy drag object to drag around
		if ( linkBars )
		{
			m_LinkedDragProxy = _hostMC.createEmptyMovieClip("m_LinkedDragProxy", _hostMC.getNextHighestDepth());
			_hostMC.onMouseMove = DragLinkedBarsHandler;
			m_LinkedDragProxy.startDrag();
		}
		
		else bar.startDrag();
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
			m_LinkedDragProxy.stopDrag();
			_hostMC.onMouseMove = undefined;
			m_LinkedDragProxy.removeMovieClip();
		}
		
		else bar.stopDrag();
	}

	// hide or show default buttons
	private function HideDefaultSwapButtons():Void
	{
		// hide buttons
		if ( _hideDefaultSwapButtons )
		{
			
			// this is very hacky, it's the only way I can prevent the default swap buttons being loaded
			// refer to GUI.HUD.PassiveBar.LoadAegisButtons()
			_root.passivebar.AEGIS_SLOT_ACHIEVEMENT = undefined;
			
			// seems like this would be a race condition, but it seems to reliably clean up any clips that get through
			// BUT ONLY ON INITIAL LOAD, not on signal triggered loads
			_root.passivebar.m_PrimaryAegisSwap.removeMovieClip();
			_root.passivebar.m_SecondaryAegisSwap.removeMovieClip();
			
			
			/* none of the below solve the problem reliably, kept here for reference
			 * 
				delete _root.passivebar.LoadAegisButtons;	// actually does delete the function, but next time it is called it comes back and runs
				_root.passivebar.LoadAegisButtons = function() { UtilsBase.PrintChatText("test"); };	// can't overwrite function, unlike javascript

				delete _root.passivebar.m_Inventory; // actually does delete the property, and prevents the icon loading, but the movieclip still gets added so it remains a clickable empty square
				
				_root.passivebar.m_PrimaryAegisSwap._visible = false;	// race condition, same reason as the above removeMovieClip() only works on initial load
			
				_root.passivebar.attachMovie("AegisButton", "m_PrimaryAegisSwap", getNextHighestDespth() ); // can't block by taking the name first, also a race condition anyway
			*/
				
		}

		// restore default buttons
		else
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
	
	public function get showWeaponGlow():Boolean {
		return _showWeaponGlow;
	}
	public function set showWeaponGlow(value:Boolean) {
		_showWeaponGlow = value;
		
		m_PrimaryBar.showWeaponGlow = _showWeaponGlow;
		m_SecondaryBar.showWeaponGlow = _showWeaponGlow;
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
		return _showBarBackground;
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
	
}
