import com.Components.WinComp;
import com.GameInterface.Tooltip.TooltipData;

//import com.Utils.Point;
import flash.geom.Point;

import gfx.core.UIComponent;
import mx.utils.Delegate;
import com.GameInterface.Chat;
import com.GameInterface.DistributedValue;
import com.Utils.Archive;
import com.GameInterface.UtilsBase;
import com.GameInterface.Game.Shortcut;

import com.GameInterface.Inventory;
import com.Utils.ID32;
import com.GameInterface.Game.Character;
import com.GameInterface.Tooltip.TooltipDataProvider;
import com.GameInterface.Lore

import com.ElTorqiro.Utils;
import com.ElTorqiro.AegisHUD.HUD.HUD;
import com.ElTorqiro.AegisHUD.Enums.*;

// the AegisHUD instance
var g_HUD:HUD;

// settings persistence objects
var g_settings:Object;	// visual / HUD type settings
var g_options:Object;	// options

// RPC DValue for receiving settings changes from other modules  (e.g. the Config module)
var g_RPC:DistributedValue;
var g_RPCFilter:Object;

// event listeners for Aegis unlocks
var g_showAegisSwapUI:DistributedValue;

var AEGIS_SLOT_ACHIEVEMENT:Number = 6817;	// The Lore number that unlocks the AEGIS system
											// 6817 is pulled straight from Funcom's PassiveBar

// internal variables
var g_findPassivebarThrashCount:Number = 0;
var g_hideDefaultSwapButtons:Boolean = true;


//Init
function onLoad()
{
	// default values for settings
	g_settings = {
		primaryPosition:		new Point( -1, -1 ),
		secondaryPosition:		new Point( -1, -1 ),
		scale:					100,
		
		hideDefaultSwapButtons: true,
		barStyle:				AegisBarLayoutStyles.HORIZONTAL,
		showWeapons:			true,
		showWeaponHighlight:	true,
		showBarBackground:		true,
		showXPBars:				false,
		showTooltips:			false,
		primaryWeaponFirst:		true,
		secondaryWeaponFirst:	true,
		hudScale:				100,
		lockBars:				false
	};
	
	// RPC permissable settings/commands
	g_RPCFilter = {
		/* settings */
		hideDefaultSwapButtons: "setting",
		barStyle:				"setting",
		showWeapons:			"setting",
		showWeaponHighlight:	"setting",
		showBarBackground:		"setting",
		showXPBars:				"setting",
		showTooltips:			"setting",
		primaryWeaponFirst:		"setting",
		secondaryWeaponFirst:	"setting",
		lockBars:				"setting",
		
		/* commands */
		SetDefaultPosition:		"command"
	};
}

function onUnload()
{
}

// module activated (i.e. its distributed value set to 1)
function OnModuleActivated()
{

	// handle the TSW user config option for showing/hiding AEGIS HUD UI
	g_showAegisSwapUI = DistributedValue.Create( "ShowAegisSwapUI" );
	g_showAegisSwapUI.SignalChanged.Connect( ShowAegisSwapUIChanged, this);
	
	// wire up handler if the toon has not unlocked the AEGIS system, but might do so during the session
	if ( Lore.IsLocked(AEGIS_SLOT_ACHIEVEMENT) )  Lore.SignalTagAdded.Connect(SlotTagAdded, this);
	
	// load settings values
	var hudData = DistributedValue.GetDValue(AddonInfo.Name + "_Data");
	for (var s:String in g_settings)
	{
		g_settings[s] = hudData.FindEntry( s, g_settings[s] );
	}
	
	// instantiate HUD
	g_HUD = HUD( this.attachMovie("com.ElTorqiro.AegisHUD.HUD.HUD", "m_HUD", this.getNextHighestDepth()) );

	// wire up RPC listener
	g_RPC = DistributedValue.Create(AddonInfo.Name + "_RPC");
	g_RPC.SignalChanged.Connect(RPCListener, this);
	
	HideDefaultSwapButtons();
}


// module deactivated (i.e. its distributed value set to 0)
function OnModuleDeactivated()
{
	// clean up listeners game related listeners
	Lore.SignalTagAdded.Disconnect(SlotTagAdded, this);
	g_showAegisSwapUI.SignalChanged.Disconnect( ShowAegisSwapUIChanged, this );
	
	// disconnect from internal DValues
	g_RPC.SignalChanged.Disconnect(RPCListener, this);

	// persist settings
	SaveData();

	// clean up elements
	g_HUD.unloadMovie();
	g_HUD.removeMovieClip();
}

function SaveData():Void
{
	// save module settings
	var saveData:Archive = new Archive();

	saveData.AddEntry( "hideDefaultSwapButtons", g_hideDefaultSwapButtons );
	saveData.AddEntry( "primaryPosition", g_HUD.primaryPosition );
	saveData.AddEntry( "secondaryPosition", g_HUD.secondaryPosition );
	saveData.AddEntry( "barStyle", g_HUD.barStyle );
	saveData.AddEntry( "showWeapons", g_HUD.showWeapons );
//	saveData.AddEntry( "showWeaponHighlight", g_HUD.showWeaponHighlight );
	saveData.AddEntry( "showBarBackground", g_HUD.showBarBackground );
	saveData.AddEntry( "showXPBars", g_HUD.showXPBars );
	saveData.AddEntry( "showTooltips", g_HUD.showTooltips );
	saveData.AddEntry( "primaryWeaponFirst", g_HUD.primaryWeaponFirst );
	saveData.AddEntry( "secondaryWeaponFirst", g_HUD.secondaryWeaponFirst );
	saveData.AddEntry( "hudScale", g_HUD.hudScale );
	saveData.AddEntry( "lockBars", g_HUD.lockBars );

	// because LoginPrefs.xml has a reference to this DValue, the contents will be saved whenever the game thinks it is necessary (e.g. closing the game, reloadui etc)
	DistributedValue.SetDValue(AddonInfo.Name + "_Data", saveData);
}

// RPC listener
function RPCListener():Void
{	
	var rpcData = g_RPC.GetValue();

	for ( var s:String in g_RPCFilter )
	{
		var value = rpcData.FindEntry( s, undefined );
		if ( value != undefined )
		{
			switch( g_RPCFilter[s] )
			{
				case "setting":
					g_HUD[s] = value;
				break;
				
				case "command":
					g_HUD[s](value);
				break;
			}
		}
	}
	
	// a setting may have changed, update the persistence object
	SaveData();
}


// handle user changing AEGIS swap visibility in control panel
function ShowAegisSwapUIChanged()
{
	//CreateHUD();
}

// handler for situation where AEGIS system becomes unlocked during play session
function SlotTagAdded(tag:Number)
{
	if (tag == AEGIS_SLOT_ACHIEVEMENT)
	{
		Lore.SignalTagAdded.Disconnect(SlotTagAdded, this);
		//CreateHUD();
	}
}


// hide or show default buttons
function HideDefaultSwapButtons():Void
{
	// hack to wait for the passivebar to be loaded, as it actually gets unloaded during teleports etc, not just deactivated
	if ( _root.passivebar.LoadAegisButtons == undefined )
	{
		// if the thrash count is exceeded, reset count and do nothing
		if (g_findPassiveBarThrashCount++ == 10)  g_findPassiveBarThrashCount = 0;

		// otherwise try again
		else _global.setTimeout( HideDefaultSwapButtons, 300 );
		
		return;
	}

	// if we reached this far, reset thrash count
	g_findPassiveBarThrashCount = 0;

	
	// hide buttons
	if ( g_hideDefaultSwapButtons )
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
