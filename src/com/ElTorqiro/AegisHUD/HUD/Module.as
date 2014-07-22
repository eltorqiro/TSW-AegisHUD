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

import com.GameInterface.Input;

import com.ElTorqiro.AddonUtils.AddonUtils;
import com.ElTorqiro.AegisHUD.HUD.HUD;
import com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker;
import com.ElTorqiro.AegisHUD.Enums.*;
import com.ElTorqiro.AegisHUD.AddonInfo;

// the AegisHUD instance
var g_HUD:HUD;

// settings persistence objects
var g_settings:Object;	// visual / HUD type settings
var g_options:Object;	// options

// RPC DValue for receiving settings changes from other modules  (e.g. the Config module)
var g_RPC:DistributedValue;
var g_RPCFilter:Object;

// TSW user setting that shows/hides the swap UI
var g_showAegisSwapUI:DistributedValue;

// constants
var AEGIS_SLOT_ACHIEVEMENT:Number = 6817;	// The Lore number that unlocks the AEGIS system
											// 6817 is pulled straight from Funcom's PassiveBar

// internal state variables
var g_findPassivebarThrashCount:Number = 0;


//Init
function onLoad():Void {
	// default values for settings
	g_settings = HUD.defaultSettingsPack;

	// create initial settings values
	g_options = {
		hideDefaultSwapButtons: true
	};
	
	// RPC permissable settings/commands
	g_RPCFilter = {
		settings: { },

		commands: {
			MoveToDefaultPosition: true
		},
		
		options: {
			hideDefaultSwapButtons: true
		}
	};
	
	// poulate allowed RPC filter settings - for now just allow every possible setting provided by HUD
	for ( var s:String in HUD.defaultSettingsPack ) {
		g_RPCFilter.settings[s] = true;
	}
	
	// hijack hotkeys
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_PrimaryAegisNext, "com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker.HotkeyPrimaryAegisNext", _global.Enums.Hotkey.eHotkeyDown , 0 );
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_PrimaryAegisPrev, "com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker.HotkeyPrimaryAegisPrev", _global.Enums.Hotkey.eHotkeyDown , 0 );
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_SecondaryAegisNext, "com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker.HotkeySecondaryAegisNext", _global.Enums.Hotkey.eHotkeyDown , 0 );
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_SecondaryAegisPrev, "com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker.HotkeySecondaryAegisPrev", _global.Enums.Hotkey.eHotkeyDown , 0 );
}

function onUnload():Void {

	// release hijacked hotkeys
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_PrimaryAegisNext, "", _global.Enums.Hotkey.eHotkeyDown , 0 );
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_PrimaryAegisPrev, "", _global.Enums.Hotkey.eHotkeyDown , 0 );
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_SecondaryAegisNext, "", _global.Enums.Hotkey.eHotkeyDown , 0 );
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_SecondaryAegisPrev, "", _global.Enums.Hotkey.eHotkeyDown , 0 );
}

// module activated (i.e. its distributed value set to 1)
function OnModuleActivated():Void {

	// handle the TSW user config option for showing/hiding AEGIS HUD UI
	g_showAegisSwapUI = DistributedValue.Create( "ShowAegisSwapUI" );
	g_showAegisSwapUI.SignalChanged.Connect( ShowAegisSwapUIChanged, this);
	
	// wire up handler if the toon has not unlocked the AEGIS system, but might do so during the session
	if ( Lore.IsLocked(AEGIS_SLOT_ACHIEVEMENT) )  Lore.SignalTagAdded.Connect(SlotTagAdded, this);
	
	// load settings values
	LoadData();
	
	// instantiate HUD
	ShowHUD();

	// hide default swap buttons if specified
	HideDefaultSwapButtons( g_options.hideDefaultSwapButtons );
	
	// wire up RPC listener
	g_RPC = DistributedValue.Create(AddonInfo.Name + "_RPC");
	g_RPC.SignalChanged.Connect(RPCListener, this);
	
}

// module deactivated (i.e. its distributed value set to 0)
function OnModuleDeactivated():Void {

	// clean up game related listeners
	Lore.SignalTagAdded.Disconnect(SlotTagAdded, this);
	g_showAegisSwapUI.SignalChanged.Disconnect( ShowAegisSwapUIChanged, this );
	
	// disconnect from internal DValues
	g_RPC.SignalChanged.Disconnect(RPCListener, this);

	// close HUD
	ShowHUD( false );
	
	// persist settings (must happen after HUD is closed to make sure most up to date values are available)
	SaveData();

	// restore regular default swap button behaviour
	HideDefaultSwapButtons( false );
}

// prepare settings for saving by TSW
function SaveData():Void {

	// because LoginPrefs.xml has a reference to these DValues, the contents will be saved whenever the game thinks it is necessary
	// (e.g. closing the game, reloadui etc)
	
	// store HUD settings
	UpdateSettingsFromHUD();	
	var saveData:Archive = new Archive();

	for ( var s:String in g_settings ) {
		saveData.AddEntry( s, g_settings[s] );
	}
	DistributedValue.SetDValue(AddonInfo.Name + "_HUD_Settings", saveData);

	// store module options
	saveData = new Archive();
	for ( var s:String in g_options ) {
		saveData.AddEntry( s, g_options[s] );
	}
	DistributedValue.SetDValue(AddonInfo.Name + "_HUD_Options", saveData);
}

// restore settings from DValue (initially populated by TSW)
function LoadData():Void {
	
	// restore HUD settings
	var loadData:Archive = DistributedValue.GetDValue(AddonInfo.Name + "_HUD_Settings");
	if( loadData != undefined ) {
		for ( var s:String in g_settings ) {
			g_settings[s] = loadData.FindEntry( s, g_settings[s] );
		}
	}
	
	// restore module options
	loadData = DistributedValue.GetDValue(AddonInfo.Name + "_HUD_Options");
	if( loadData != undefined ) {
		for ( var s:String in g_options ) {
			g_options[s] = loadData.FindEntry( s, g_options[s] );
		}
	}
}

// RPC listener
function RPCListener():Void {
	var rpcData:Archive = g_RPC.GetValue();

	// HUD settings
	for ( var s:String in g_RPCFilter.settings ) {
		var value = rpcData.FindEntry( s, null );
		if ( value != null && g_RPCFilter.settings[s] ) g_HUD[s] = value;
	}
	
	// HUD commands
	for ( var s:String in g_RPCFilter.commands ) {
		var value = rpcData.FindEntry( s, null );		
		//if ( g_RPCFilter.commands[s] ) g_HUD[s]( value );
	}
	
	// module options
	for ( var s:String in g_RPCFilter.options ) {
		//if ( g_RPCFilter.options[s] ) g_options[s] = value;
	}
	
	// a setting may have changed, update the persistence object
	SaveData();
}

// handle user changing AEGIS swap visibility in control panel
function ShowAegisSwapUIChanged():Void {
	ShowHUD( g_showAegisSwapUI.GetValue() );
}

// handler for situation where AEGIS system becomes unlocked during play session
function SlotTagAdded(tag:Number):Void {
	if (tag == AEGIS_SLOT_ACHIEVEMENT) {
		Lore.SignalTagAdded.Disconnect(SlotTagAdded, this);
		ShowHUD( g_showAegisSwapUI.GetValue() );
	}
}


// HUD load / destroy
function ShowHUD(show:Boolean):Void {
	
	// if no variable passed, check automatically
	if ( show == undefined ) {
		show = g_showAegisSwapUI.GetValue() && !Lore.IsLocked(AEGIS_SLOT_ACHIEVEMENT);
	}
	
	// attach HUD
	if( show ) {
		g_HUD = HUD( this.attachMovie("com.ElTorqiro.AegisHUD.HUD.HUD", "m_HUD", this.getNextHighestDepth(), { settings: g_settings }) );
	}

	// destroy HUD
	else if( g_HUD != undefined ) {
		UpdateSettingsFromHUD();
		g_HUD.unloadMovie();
		g_HUD.removeMovieClip();
		g_HUD = undefined;
	}
}

function UpdateSettingsFromHUD():Void {
	// retrieve current settings directly from HUD to make sure we have the most up to date values
	if ( g_HUD == undefined ) return;
	
	for ( var s:String in g_settings ) {
		g_settings[s] = g_HUD[s];
	}
}

// hide or show default buttons
function HideDefaultSwapButtons(hide:Boolean):Void {
	// hack to wait for the passivebar to be loaded, as it actually gets unloaded during teleports etc, not just deactivated
	if ( _root.passivebar.LoadAegisButtons == undefined ) {
		// if the thrash count is exceeded, reset count and do nothing
		if (g_findPassiveBarThrashCount++ == 10)  g_findPassiveBarThrashCount = 0;
		// otherwise try again
		else _global.setTimeout( HideDefaultSwapButtons, 300, hide );
		
		return;
	}
	// if we reached this far, reset thrash count
	g_findPassiveBarThrashCount = 0;

	// hide buttons
	if ( hide ) {
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
	else if ( _root.passivebar.LoadPrimaryAegisButton_AegisHUD_Saved != undefined ) {
		_root.passivebar.LoadPrimaryAegisButton = _root.passivebar.LoadPrimaryAegisButton_AegisHUD_Saved;
		_root.passivebar.LoadPrimaryAegisButton_AegisHUD_Saved = undefined;

		_root.passivebar.LoadSecondaryAegisButton = _root.passivebar.LoadSecondaryAegisButton_AegisHUD_Saved;
		_root.passivebar.LoadSecondaryAegisButton_AegisHUD_Saved = undefined;
		
		// do a load to restore buttons naturally if they need to be visible
		_root.passivebar.LoadAegisButtons();
	}
}
