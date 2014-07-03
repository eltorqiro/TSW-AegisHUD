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
	private var m__LinkedDragProxy:MovieClip;
	
	// movieclip owner for visual elements
	private var __parentMC:MovieClip;
	
	// user configurable option
	private var __hideDefaultSwapButtons:Boolean = true;
	private var __linkBars:Boolean = true;
	private var __layoutStyle:Number = 1;
	private var __showWeapons:Boolean = true;
	private var __showWeaponGlow:Boolean = true;
	private var __showBarBackground:Boolean = true;
	private var __showXPBars:Boolean = false;
	private var __showTooltips:Boolean = true;

	// position restoration for windows
	private var __ConfigPos:Point;
	private var __PrimaryPos:Point;
	private var __SecondaryPos:Point;

	// utility objects
	private var __character:Character;
	private var __inventory:Inventory;
	

	// constructor
	public function AegisHUD(parentMC:MovieClip)
	{
		// handle if the toon has not unlocked the AEGIS system, but does so during the session
		Lore.SignalTagAdded.Connect(SlotTagAdded, this);
		
		// host movie clip, that all AegisHUD content will be placed into
		__parentMC = parentMC.createEmptyMovieClip( "m_AegisHUD", parentMC.getNextHighestDepth() );
		
		CreateHUD();
	}


	// module activated (i.e. its distributed value set to 1)
	// saved config data is passed in
	function OnModuleActivated(archive:Archive)
	{
		UtilsBase.PrintChatText("AEGIS.HUD activated");
		
		// visual settings
		//__showWeapons = __archive.FindEntry( "ShowWeapons", __showWeapons );
		//__showWeapons = __archive.FindEntry( "ShowWeaponGlow", __showWeaponGlow );
		//__showWeapons = __archive.FindEntry( "ShowBarBackground", __showBarBackground );
		//__showWeapons = __archive.FindEntry( "ShowXPBars", __showXPBars );
		//__showWeapons = __archive.FindEntry( "ShowTooltips", __showTooltips );

		// layout & position settings
		//__LayoutStyle = archive.FindEntry( "LayoutStyle", __LayoutStyle );
		//__PrimaryPos = new Point( __archive.FindEntry("PrimaryX", __PrimaryPos.x), __archive.FindEntry("PrimaryY", __PrimaryPos.y) );
		//__SecondaryPos = new Point( __archive.FindEntry("SecondaryX", __SecondaryPos.x), __archive.FindEntry("SecondaryY", __SecondaryPos.y) );
		//__ConfigPos = new Point( __archive.FindEntry("ConfigyX", __ConfigPos.x), __archive.FindEntry("ConfigY", __ConfigPos.y) );

		// config options
		//__hideDefaultSwapButtons = __archive.FindEntry("HideDefaultSwapButtons", __hideDefaultSwapButtons );
		//__linkBars = __archive.FindEntry( "LinkBars", __linkBars );
	}


	// pseudo-destructor, should be called immediately before deleting the object
	function Destroy():Void
	{
		// clean up elements
		__parentMC.removeMovieClip();
		
		// restore default buttons -- this forced behaviour may not be desirable, the host project may want them to remain hidden
		hideDefaultSwapButtons = false;
	}


	// main activation routine for creating and initialising the bars
	// abstracted away from other startup functions so it can be called if AEGIS
	// is unlocked during a play session rather than being already unlocked at the start
	function CreateHUD():Void
	{
		// do nothing at all if AEGIS system is not unlocked
		if ( Lore.IsLocked(AEGIS_SLOT_ACHIEVEMENT) ) return;
		
		var __character:Character = Character.GetClientCharacter();
		var __inventory:Inventory = new Inventory( new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, Character.GetClientCharID().GetInstance()) );

		// create bars
		m_PrimaryBar = __parentMC.attachMovie("AegisBar", "m_PrimaryBar", __parentMC.getNextHighestDepth()).init( AegisBar.AEGIS_GROUP_PRIMARY, __character, __inventory );
		m_PrimaryBar.handleDrag = false;
		m_PrimaryBar.showXPBar = __showXPBars;

		m_SecondaryBar = __parentMC.attachMovie("AegisBar", "m_SecondaryBar", __parentMC.getNextHighestDepth()).init( AegisBar.AEGIS_GROUP_SECONDARY, __character, __inventory );
		m_SecondaryBar.handleDrag = false;
		m_SecondaryBar.showXPBar = __showXPBars;

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
	function Layout():Void
	{
		// set default positions to simulate the default buttons
		// ... surprised this worked without some localToGlobal() usage
		if (m_PrimaryBar._x == 0 && m_PrimaryBar._y == 0)
		{
			m_PrimaryBar._x = Stage.visibleRect.width / 2 - m_PrimaryBar._width - 5;
			m_SecondaryBar._x = m_PrimaryBar._x + m_PrimaryBar._width + 10;
			m_PrimaryBar._y = m_SecondaryBar._y = _root.passivebar._y - m_PrimaryBar._height - 5;
		}
	}


	// handler for unlocking AEGIS system during session
	function SlotTagAdded(tag:Number)
	{
		if (tag == AEGIS_SLOT_ACHIEVEMENT)
		{
			CreateHUD();
		}
	}

	// Move Drag Handler
	function MoveDragHandler(bar:MovieClip):Void
	{
		// since flash can only drag one item at a time with startDrag(), create a proxy drag object to drag around
		if ( this.linkBars )
		{
			m__LinkedDragProxy = __parentMC.createEmptyMovieClip("m__LinkedDragProxy", __parentMC.getNextHighestDepth());
			__parentMC.onMouseMove = DragLinkedBarsHandler;
			m__LinkedDragProxy.startDrag();
		}
		
		else bar.startDrag();
	}

	// move handler for dragging both bars as one
	function DragLinkedBarsHandler():Void
	{
		m_PrimaryBar._x += m__LinkedDragProxy._x - m__LinkedDragProxy.__prevX;
		m_PrimaryBar._y += m__LinkedDragProxy._y - m__LinkedDragProxy.__prevY;
		m_SecondaryBar._x += m__LinkedDragProxy._x - m__LinkedDragProxy.__prevX;
		m_SecondaryBar._y += m__LinkedDragProxy._y - m__LinkedDragProxy.__prevY;
		
		m__LinkedDragProxy.__prevX = m__LinkedDragProxy._x;
		m__LinkedDragProxy.__prevY = m__LinkedDragProxy._y;
	}

	//Move Drag Release
	function MoveDragReleaseHandler(bar:MovieClip):Void
	{
		// destroy proxy drag object
		if ( this.linkBars )
		{
			m__LinkedDragProxy.stopDrag();
			__parentMC.onMouseMove = undefined;
			m__LinkedDragProxy.removeMovieClip();
		}
		
		else bar.stopDrag();
	}

	// hide or show default buttons
	private function HideDefaultSwapButtons():Void
	{
		// hide buttons
		if ( __hideDefaultSwapButtons )
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
		return __hideDefaultSwapButtons;
	}
	public function set hideDefaultSwapButtons(value:Boolean) {
		__hideDefaultSwapButtons = value;
		HideDefaultSwapButtons();
	}
		
	// link bars together when being dragged
	public function get linkBars():Boolean {
		return __linkBars;
	}
	public function set linkBars(value:Boolean) {
		__linkBars = value;
	}

	public function get primaryBar():AegisBar {
		return m_PrimaryBar;
	}
	
	public function get secondaryBar():AegisBar {
		return m_SecondaryBar;
	}
	
}
