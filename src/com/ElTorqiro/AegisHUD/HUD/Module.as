import com.Components.WinComp;
import com.GameInterface.Tooltip.TooltipData;

//import com.Utils.Point;
import flash.geom.Point;

import gfx.core.UIComponent;
import mx.utils.Delegate;
import com.GameInterface.Chat;
import com.GameInterface.DistributedValue;
import com.Utils.Archive;
import com.ElTorqiro.AddonUtils.PublicArchive;
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
var g_data:Object;
var g_playfieldMemoryBlacklist:Object;

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

// for checking offensive target change
var g_character:Character;
var g_autoHideTimeoutID:Number;
var g_autoHideHidden:Boolean;


//Init
function onLoad():Void {
	
	// default values for settings
	g_data = {
		settings: HUD.defaultSettingsPack,
		
		options: {
			hideDefaultSwapButtons: true,
			hudEnabled: true,
			playfieldMemoryEnabled: true,
			autoHide: false,
			autoHideTimeout: 5
		}
	};
}



function onUnload():Void {}

// module activated (i.e. its distributed value set to 1)
function OnModuleActivated():Void {

	// hijack hotkeys
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_PrimaryAegisNext, "com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker.HotkeyPrimaryAegisNext", _global.Enums.Hotkey.eHotkeyDown , 0 );
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_PrimaryAegisPrev, "com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker.HotkeyPrimaryAegisPrev", _global.Enums.Hotkey.eHotkeyDown , 0 );
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_SecondaryAegisNext, "com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker.HotkeySecondaryAegisNext", _global.Enums.Hotkey.eHotkeyDown , 0 );
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_SecondaryAegisPrev, "com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker.HotkeySecondaryAegisPrev", _global.Enums.Hotkey.eHotkeyDown , 0 );

	// load settings values
	LoadData();
	LoadPlayfieldMemory();

	
	
	
	
	/********************************************* remove me */
	UtilsBase.PrintChatText(" autohide set to false ");
	g_data.options.autoHide = false;
	
	
	
	
	
	
	// check autohide playfield
	CheckPlayfieldMemory();
	DistributedValue.SetDValue( AddonInfo.Name + "_HUD_Enabled", g_data.options.hudEnabled );	

	// handle the TSW user config option for showing/hiding AEGIS HUD UI
	g_showAegisSwapUI = DistributedValue.Create( "ShowAegisSwapUI" );
	g_showAegisSwapUI.SignalChanged.Connect( ShowAegisSwapUIChanged, this);
	
	// wire up handler if the toon has not unlocked the AEGIS system, but might do so during the session
	if ( Lore.IsLocked(AEGIS_SLOT_ACHIEVEMENT) )  Lore.SignalTagAdded.Connect(SlotTagAdded, this);

	// instantiate HUD
	ShowHUD();

	// hide default swap buttons if specified
	hideDefaultSwapButtons( g_data.options.hideDefaultSwapButtons );
	
	// wire up the watchers for the auto-hide feature
	g_character = Character.GetClientCharacter();
	g_character.SignalOffensiveTargetChanged.Connect( OffensiveTargetChangeHandler, this );
	g_character.SignalToggleCombat.Connect( CombatToggledHandler, this );
	
	
	// if autohide is on, immediately try to fade out
	if ( g_data.options.autoHide ) AutoHideHide();
}

function OffensiveTargetChangeHandler(targetID:ID32):Void {
	
	if ( !g_data.options.autoHide ) return;

	// no current target?
	if ( targetID.IsNull() ) {
		// hud is already hidden? do nothing
		
		// else hud is visible
		if ( !g_autoHideHidden ) {
			if ( !g_character.IsInCombat() && !g_autoHideHidden ) StartAutoHideTimeout(); 
		}
	}
	
	// there is a target
	else {
		
		// does player have a target?
		var target:Character = Character.GetCharacter( targetID );
		
		// and does it have shields?	
		var psychicShield:Number = target.GetStat(_global.Enums.Stat.e_CurrentPinkShield, 2);
		var cyberShield:Number = target.GetStat(_global.Enums.Stat.e_CurrentBlueShield, 2);
		var demonicShield:Number = target.GetStat(_global.Enums.Stat.e_CurrentRedShield, 2);

		// no shield
		if ( !(psychicShield || cyberShield || demonicShield) ) {
			// hud is already hidden? do nothing
			
			// else hud is visible
			if ( !g_autoHideHidden) {
				if ( !g_character.IsInCombat() && !g_autoHideHidden ) StartAutoHideTimeout();
			}
		}

		// has shield
		else {
			// if hud hidden
			if ( g_autoHideHidden ) {
				// bring up hud
				Do( "option.hudEnabled", true );
				g_autoHideHidden = false;				
			}
			
			// else hud is visible
			else {
				StopAutoHideTimeout();
			}
		}
	}
	
}

function CombatToggledHandler(isInCombat):Void {

	// do nothing if autohide not enabled
	if ( !g_data.options.autoHide ) return;
	
	// left combat
	if( !isInCombat ) {
		// if hud is visible
		if ( !g_autoHideHidden ) {
			// no target selected now
			if ( g_character.GetOffensiveTarget().IsNull() ) {
				StartAutoHideTimeout();
			}
		}
	}
	
	// entered combat
	else {
		// if hud is visible
		if ( !g_autoHideHidden ) {
			// no target selected now
			if ( g_character.GetOffensiveTarget().IsNull() ) {
				StopAutoHideTimeout();
			}
		}
	}
	
}

// setter response for the autohide
function autoHide(enabled:Boolean):Void {
	
	// enabling
	if ( enabled ) {
		// start autohide timer
		StartAutoHideTimeout();
		g_autoHideHidden = false;
	}
	
	// disabling
	else {
		// stop timer
		StopAutoHideTimeout();
		
		// enable window if it is hidden
		if ( g_autoHideHidden ) {
			Do( "option.hudEnabled", true );
			g_autoHideHidden = false;			
		}
		
	}
	
}

function StartAutoHideTimeout():Void {
	StopAutoHideTimeout();
	g_autoHideTimeoutID = _global.setTimeout( Delegate.create( this, AutoHideHide), g_data.options.autoHideTimeout * 1000 );
}

function StopAutoHideTimeout():Void {
	if ( g_autoHideTimeoutID != undefined ) {
		_global.clearTimeout( g_autoHideTimeoutID );
		g_autoHideTimeoutID = undefined;
	}
}

function AutoHideHide():Void {
	// clear any existing timeout
	StopAutoHideTimeout();
	
	// final sanity check to make sure there is no target with shields selected
	if ( OffensiveTargetHasShields() ) return;
	
	// hide the hud
	Do( "option.hudEnabled", false );
	g_autoHideHidden = true;
}

function OffensiveTargetHasShields():Boolean {

	var targetID:ID32 = g_character.GetOffensiveTarget();
	
	// has a target
	if( !targetID.IsNull() ) {

		// does player have a target?
		var target:Character = Character.GetCharacter( targetID );
		
		// and does it have shields?	
		var psychicShield:Number = target.GetStat(_global.Enums.Stat.e_CurrentPinkShield, 2);
		var cyberShield:Number = target.GetStat(_global.Enums.Stat.e_CurrentBlueShield, 2);
		var demonicShield:Number = target.GetStat(_global.Enums.Stat.e_CurrentRedShield, 2);

		// no shield
		if ( psychicShield || cyberShield || demonicShield ) {
			return true;
		}
	}

	return false;
}


// module deactivated (i.e. its distributed value set to 0)
function OnModuleDeactivated():Void {

	// release hijacked hotkeys
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_PrimaryAegisNext, "", _global.Enums.Hotkey.eHotkeyDown , 0 );
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_PrimaryAegisPrev, "", _global.Enums.Hotkey.eHotkeyDown , 0 );
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_SecondaryAegisNext, "", _global.Enums.Hotkey.eHotkeyDown , 0 );
	Input.RegisterHotkey( HotkeyHijacker.e_Hotkey_SecondaryAegisPrev, "", _global.Enums.Hotkey.eHotkeyDown , 0 );
	
	// clean up game related listeners
	Lore.SignalTagAdded.Disconnect(SlotTagAdded, this);
	g_showAegisSwapUI.SignalChanged.Disconnect( ShowAegisSwapUIChanged, this );
	g_character.SignalOffensiveTargetChanged.Disconnect( OffensiveTargetChangeHandler, this );
	g_character.SignalToggleCombat.Disconnect( CombatToggledHandler, this );
	
	// stop autohide timer
	StopAutoHideTimeout();
	g_autoHideHidden = false;
	
	// close HUD
	ShowHUD( false );
	
	// persist settings (must happen after HUD is closed to make sure most up to date values are available)
	SaveData();

	// restore regular default swap button behaviour
	hideDefaultSwapButtons( false );	
}

// prepare settings for saving by TSW
function SaveData():Void {

	var saveData:Archive = new Archive();
	
	// store HUD settings
	UpdateSettingsFromHUD();
	for ( var s:String in g_data.settings ) {
		saveData.AddEntry( 'setting.' + s, g_data.settings[s] );
	}
	
	// store HUD options
	for ( var s:String in g_data.options ) {
		saveData.AddEntry( 'option.' + s, g_data.options[s] );
	}

	// persistence object
	// because LoginPrefs.xml has a reference to these DValues, the contents will be saved whenever the game thinks it is necessary
	// (e.g. closing the game, reloadui etc)
	DistributedValue.SetDValue(AddonInfo.Name + "_HUD_Data", saveData);
	

	// push into persistence object
	var saveData:Archive = new Archive();
	for ( var s:String in g_playfieldMemoryBlacklist ) {
		saveData.AddEntry( "blacklist", s );
	}
	DistributedValue.SetDValue(AddonInfo.Name + "_HUD_PlayfieldMemory", saveData);

}

// restore settings from DValue (initially populated by TSW)
function LoadData():Void {

	// restore HUD settings
	var loadData:Archive = DistributedValue.GetDValue(AddonInfo.Name + "_HUD_Data");

	if( loadData != undefined ) {

		// restore HUD settings
		for ( var s:String in g_data.settings ) {
			g_data.settings[s] = loadData.FindEntry( 'setting.' + s, g_data.settings[s] );
		}
		
		// restore HUD options
		for ( var s:String in g_data.options ) {
			g_data.options[s] = loadData.FindEntry( 'option.' + s, g_data.options[s] );
		}
	}
}

// options router for actions (setting values, performing commands), in lieu of a getter/setter model -- this is the setter
function Do(name:String, value) {
	
	// split name into constituent parts
	var node:Array = name.split( '.' );
	var type:String = node[0];
	var key:String = node[1];
	
	if ( type == undefined || key == undefined ) return;
	
	switch( type ) {
		
		// settings are routed through to the HUD if it exists
		case "setting":
			g_data.settings[key] = value;
			if ( g_HUD != undefined ) {
				g_HUD[key] = value;
				UpdateSettingsFromHUD();
			}
		break;


		// commands are routed through to the HUD if it exists
		case "command":
			if ( g_HUD != undefined ) {
				g_HUD[key]( value );
				UpdateSettingsFromHUD();				
			}
		break;
		
		
		// options are handled here in the module
		case "option":
			for (var s:String in g_data.options) {
				if ( s == key ) {
					g_data.options[key] = value;
					break;
				}
			}
			if( this[key] instanceof Function ) this[key]( value );
		break;
	}
	
}


// load auto hide playfields from persistence
function LoadPlayfieldMemory():Void {
	
	var loadData:Archive = DistributedValue.GetDValue(AddonInfo.Name + "_HUD_PlayfieldMemory");
	var storedPlayfields:Array = loadData.FindEntryArray( "blacklist" );

	g_playfieldMemoryBlacklist = {};
	
	// unique the playfield visibility blacklist
	for( var i in storedPlayfields ) {
		g_playfieldMemoryBlacklist[ storedPlayfields[i] ] = true;
	}
}

// checks current playfield to automatically set enabled state
// should only be called during OnModuleActivated
function CheckPlayfieldMemory():Void {
	
	// only restore setting if memory system is enabled
	if ( g_data.options.playfieldMemoryEnabled ) g_data.options.hudEnabled = g_playfieldMemoryBlacklist[ Character.GetClientCharacter().GetPlayfieldID() ] == true ? false : true;
}

function SetPlayfieldMemory(show:Boolean):Void {

	// only change setting if memory system is enabled
	if ( !g_data.options.playfieldMemoryEnabled ) return;
	
	var currentPlayfield:Number = Character.GetClientCharacter().GetPlayfieldID();
	if ( !show ) {
		g_playfieldMemoryBlacklist[ Character.GetClientCharacter().GetPlayfieldID() ] = true;
	}
	else {
		delete g_playfieldMemoryBlacklist[ Character.GetClientCharacter().GetPlayfieldID() ];
	}
	
}

// handle user changing AEGIS swap visibility in control panel
function ShowAegisSwapUIChanged():Void {
	ShowHUD();
}

// handler for situation where AEGIS system becomes unlocked during play session
function SlotTagAdded(tag:Number):Void {
	if (tag == AEGIS_SLOT_ACHIEVEMENT) {
		Lore.SignalTagAdded.Disconnect(SlotTagAdded, this);
		ShowHUD();
	}
}


// HUD load / destroy
function ShowHUD(show:Boolean):Void {

	// if no variable passed, check automatically
	if ( show == undefined ) {
		show = true;
	}

	// attach HUD
	if( show && g_HUD == undefined && g_data.options.hudEnabled && g_showAegisSwapUI.GetValue() && !Lore.IsLocked(AEGIS_SLOT_ACHIEVEMENT)) {
		g_HUD = HUD( this.attachMovie("com.ElTorqiro.AegisHUD.HUD.HUD", "m_HUD", this.getNextHighestDepth(), { settings: g_data.settings } ) );
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
	
	for ( var s:String in g_data.settings ) {
		g_data.settings[s] = g_HUD[s];
	}
}


// enables/disables (hides/shows) the HUD
function hudEnabled(enabled:Boolean):Void {	
	SetPlayfieldMemory( enabled );
	ShowHUD();
	DistributedValue.SetDValue( AddonInfo.Name + "_HUD_Enabled", enabled );
}


// hide or show default buttons
function hideDefaultSwapButtons(hide:Boolean):Void {

	// hack to wait for the passivebar to be loaded, as it actually gets unloaded during teleports etc, not just deactivated
	if ( _root.passivebar.LoadAegisButtons == undefined ) {
		// if the thrash count is exceeded, reset count and do nothing
		if (g_findPassiveBarThrashCount++ == 10)  g_findPassiveBarThrashCount = 0;
		// otherwise try again
		else _global.setTimeout( Delegate.create(this, hideDefaultSwapButtons), 300, hide );
		
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
