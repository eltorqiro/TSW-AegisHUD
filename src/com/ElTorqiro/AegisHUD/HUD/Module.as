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
	var settings = { test: "hello" };
	
	g_HUD = HUD( this.attachMovie("com.ElTorqiro.AegisHUD.HUD.HUD", "m_HUD", this.getNextHighestDepth(), { settings: settings }) );

	// wire up RPC listener
	g_RPC = DistributedValue.Create(AddonInfo.Name + "_RPC");
	g_RPC.SignalChanged.Connect(RPCListener, this);
	
	HideDefaultSwapButtons(g_hideDefaultSwapButtons);
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
	saveData.AddEntry( "showXP", g_HUD.showXP );
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
function HideDefaultSwapButtons(hide:Boolean):Void
{
	// hack to wait for the passivebar to be loaded, as it actually gets unloaded during teleports etc, not just deactivated
	if ( _root.passivebar.LoadAegisButtons == undefined )
	{
		// if the thrash count is exceeded, reset count and do nothing
		if (g_findPassiveBarThrashCount++ == 10)  g_findPassiveBarThrashCount = 0;
		// otherwise try again
		else _global.setTimeout( HideDefaultSwapButtons, 300, hide );
		
		return;
	}
	// if we reached this far, reset thrash count
	g_findPassiveBarThrashCount = 0;

	// hide buttons
	if ( hide )
	{
		if ( _root.passivebar.LoadPrimaryAegisButton_AegisHUD_Saved == undefined ) {
			_root.passivebar.LoadPrimaryAegisButton_AegisHUD_Saved = _root.passivebar.LoadPrimaryAegisButton;
			// break the link
			_root.passivebar.LoadPrimaryAegisButton = undefined;
			_root.passivebar.LoadPrimaryAegisButton = function() { };

			_root.passivebar.LoadSecondaryAegisButton_AegisHUD_Saved = _root.passivebar.LoadSecondaryAegisButton;
			// break the link
			_root.passivebar.LoadSecondaryAegisButton = undefined;
			_root.passivebar.LoadSecondaryAegisButton = function() { };
			
			// remove any existing movieclips
			_root.passivebar.m_PrimaryAegisSwap.unloadMovie();
			_root.passivebar.m_PrimaryAegisSwap.removeMovieClip();
			
			_root.passivebar.m_SecondaryAegisSwap.unloadMovie();
			_root.passivebar.m_SecondaryAegisSwap.removeMovieClip();
		}
	}

	// restore default buttons if they have been previously disabled
	else if ( _root.passivebar.LoadPrimaryAegisButton_AegisHUD_Saved != undefined )
	{
		_root.passivebar.LoadPrimaryAegisButton = _root.passivebar.LoadPrimaryAegisButton_AegisHUD_Saved;
		_root.passivebar.LoadPrimaryAegisButton_AegisHUD_Saved = undefined;

		_root.passivebar.LoadSecondaryAegisButton = _root.passivebar.LoadSecondaryAegisButton_AegisHUD_Saved;
		_root.passivebar.LoadSecondaryAegisButton_AegisHUD_Saved = undefined;
		
		// do a load to restore buttons naturally if they need to be visible
		_root.passivebar.LoadAegisButtons();
	}
}
