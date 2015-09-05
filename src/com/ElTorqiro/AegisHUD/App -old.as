import com.ElTorqiro.AegisHUD.AutoSwapper;
import com.Utils.Signal;
import GUIFramework.ClipNode;
import GUIFramework.SFClipLoader;
import com.GameInterface.LoreBase;

import com.GameInterface.Game.Character;

import com.GameInterface.UtilsBase;

import com.ElTorqiro.AegisHUD.Enums;
import com.ElTorqiro.AegisHUD.Preferences;
import com.ElTorqiro.AegisHUD.VTIOConnector;
import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.HotkeyManager;

import com.GameInterface.DistributedValue;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.App {
	
	public function App() {
		
		// load preferences
		prefs = new Preferences();
		createPrefEntries();
		prefs.load();

		// attach widget
		widgetClip = SFClipLoader.LoadClip( ID + "\\Widget.swf", ID + "_Widget", false, _global.Enums.ViewLayer.e_ViewLayerTop, 2, [ this ] );
		widgetClip.SignalLoaded.Connect( widgetLoaded, this );
		
		// create aegis server
		aegisServer = new AegisServer();
	}

	/**
	 * make the app active
	 * - typically called by OnModuleActivated in the module
	 */
	public function activate() : Void {
		_active = true;

		// show widget clip
		updateWidgetVisibility();
		
		// attach hud clip
		
		// manipulate default ui elements
		
		// start autoswapper
		
		// hijack hotkeys
		

		
		
		
		// show widget icon
		controlWidgetVisibility();
		
		// load the hud
		controlHUD();
		
		// start the autoswapper
		controlAutoSwap();
		
		defaultDisruptorButtonsPrefHandler();
		defaultShieldButtonPrefHandler();
		hotkeyPrefHandler();
	}
	
	/**
	 * make the app inactive
	 * - typically called by OnModuleDeactivated in the module
	 */
	public function deactivate() : Void {
		_active = false;

		// save settings
		prefs.save();
		
		// hide widget clip
		updateWidgetVisibility();
		
		// destroy hud clip
		
		// restore default ui elements
		
		// stop autoswapper
		
		// release hotkeys
		

		
		
		
		Preferences.save();

		HotkeyManager.Hijack( false );
		hideDefaultDisruptorButtons( false );
		hideDefaultShieldButton( false );
		
		// unload the hud
		unloadHUD();
		
		// stop autoswapper
		stopAutoSwap();
		
		// close the config window
		showConfigWindow.SetValue( false );
		
		// hide widget
		controlWidgetVisibility();
	}

	/**
	 * stop app running and clean up resources
	 */
	public function dispose() : Void {
		
		prefs.dispose();
		prefs = null;
		
		// destroy widget clip
		
		// destroy config window

		// destroy aegis server
		aegisServer.dispose();
		aegisServer = null;
		
	}
	
	/**
	 * triggers updates that need to occur after the widget clip has been loaded
	 * 
	 * @param	clipNode
	 * @param	success
	 */
	private function widgetLoaded( clipNode:ClipNode, success:Boolean ) : Void {
		debug("App: widget loaded: " + success);
		
		updateWidgetVisibility();

		var vtio:VTIOConnector = new VTIOConnector( ID, Author, Version, ID + "_ShowConfigWindow", widgetClip.m_Movie.m_Icon, registeredWithVTIO, this );
	}

	/**
	 * triggers updates that need to occur after the app has been registered with VTIO
	 * e.g. updating the state of the widget icon copy that VTIO creates
	 * 
	 * @param	id
	 * @param	registrationInfo
	 */
	private function registeredWithVTIO( id:String, registrationInfo:Object ) : Void {
			
			debug( "App: registered with VTIO" );
	}
	
	/**
	 * controls the visibility of the widget clip
	 */
	private function updateWidgetVisibility() : Void {
		widgetClip.m_Movie._visible = active;
	}	
	
	/**
	 * populate pref object with app entries
	 */
	private function createPrefEntries() : Void  {
		prefs.add( "prefs.version", 40000 );
		
		prefs.add( "configwindow.position", undefined );
		prefs.add( "widget.position", undefined );
		prefs.add( "widget.scale", 100 );
		
		prefs.add( "app.enabled", true );

		prefs.add( "app.disabled.playfields", undefined );
		
		prefs.add( "autoSwap.enabled", true );
		prefs.add( "autoSwap.behaviour", Enums.e_AutoSwapBehaviourOffensive );
		
		prefs.add( "autoSwap.primary.enabled", true );
		prefs.add( "autoSwap.secondary.enabled", true );
		prefs.add( "autoSwap.shield.enabled", true );

		prefs.add( "defaultUI.disruptorSelect.hide", true );
		prefs.add( "defaultUI.shieldSelect.hide", true );

		prefs.add( "ui.hide.whenAutoswapEnabled", false );
		prefs.add( "ui.hide.whenNotInCombat", false );
		
		prefs.add( "ui.hud.scale", 100 );
		
		prefs.add( "ui.icons.type", Enums.e_IconTypeInbuilt );
		
		prefs.add( "ui.integrateWithAbilityBar", true );
		prefs.add( "ui.animateWithAbilityBar", true );

		prefs.add( "ui.bars.primary.position", undefined );
		prefs.add( "ui.bars.primary.item.showType", Enums.e_BarItemShowFirst );
		
		prefs.add( "ui.bars.secondary.position", undefined );
		prefs.add( "ui.bars.secondary.item.showType", Enums.e_BarItemShowFirst );

		prefs.add( "ui.bars.shield.position", undefined );
		prefs.add( "ui.bars.shield.item.showType", Enums.e_BarItemShowFirst );

		prefs.add( "ui.bar.background.type", Enums.e_BarTypeThin );
		prefs.add( "ui.bar.tint", false );
		prefs.add( "ui.bar.neon", true );

		prefs.add( "ui.item.tint", false );
		prefs.add( "ui.item.neon", true );

		prefs.add( "ui.xp.enabled", true );
		prefs.add( "ui.xp.hideWhenFull", false );
		
		prefs.add( "ui.tooltips.enabled", true );
		prefs.add( "ui.tooltips.suppressInCombat", true );
		
		prefs.add( "ui.aegis.tint", false );
		prefs.add( "ui.aegis.selected.neon", true );
		prefs.add( "ui.aegis.selected.background.enabled", false );
		prefs.add( "ui.aegis.selected.background.tint", false );
		prefs.add( "ui.aegis.selected.background.neon", false );

		prefs.add( "ui.select.leftButton", Enums.e_SelectionDual );
		prefs.add( "ui.select.rightButton", Enums.e_SelectionSingle );
		prefs.add( "ui.select.shiftLeftButton", Enums.e_SelectionSingle );
		
		prefs.add( "hotkeys.enabled", true );
		prefs.add( "hotkeys.lockedOutWhenHudDisabled", true );
		prefs.add( "hotkeys.primary.select", Enums.e_SelectionDual );
		prefs.add( "hotkeys.secondary.select", Enums.e_SelectionDual );

		prefs.add( "tints.aegis.psychic", 			0xe083ff );
		prefs.add( "tints.aegis.cybernetic",		0x00d0ff );
		prefs.add( "tints.aegis.demonic",			0xff3300 );
		prefs.add( "tints.aegis.empty",				0x999999 );
		prefs.add( "tints.aegis.standardBackground",0xe8e8e8 );
		
		prefs.add( "tints.xp.progress",				0xf0f0f0 );	/* 0x00E5A3 */
		prefs.add( "tints.xp.full",					0x66ff66 );	/* // 0x4EE500 // 0x19FDFF */
	}
	
	
	
	/**
	 * initialises the app
	 */
	public static function init() : Void {
		if ( initialised ) return;
		initialised = true;
		
		Preferences.init();

		Preferences.addStore( "account", "ElTorqiro_AegisHUD_Account_Preferences", true );
		
		Preferences.add( "prefs.version", 40000, "account" );
		
		Preferences.add( "configwindow.position", undefined, "account" );
		Preferences.add( "widget.position", undefined, "account" );
		Preferences.add( "widget.scale", 100, "account" );
		
		Preferences.add( "app.enabled", true, "account" );

		Preferences.add( "app.disabled.playfields", undefined, "account" );
		
		Preferences.add( "autoSwap.enabled", true, "account" );
		Preferences.add( "autoSwap.behaviour", Enums.e_AutoSwapBehaviourOffensive, "account" );
		
		Preferences.add( "autoSwap.primary.enabled", true, "account" );
		Preferences.add( "autoSwap.secondary.enabled", true, "account" );
		Preferences.add( "autoSwap.shield.enabled", true, "account" );

		Preferences.add( "defaultUI.disruptorSelect.hide", true, "account" );
		Preferences.add( "defaultUI.shieldSelect.hide", true, "account" );

		Preferences.add( "ui.hide.whenAutoswapEnabled", false, "account" );
		Preferences.add( "ui.hide.whenNotInCombat", false, "account" );
		
		Preferences.add( "ui.hud.scale", 100, "account" );
		
		Preferences.add( "ui.icons.type", Enums.e_IconTypeInbuilt, "account" );
		
		Preferences.add( "ui.integrateWithAbilityBar", true, "account" );
		Preferences.add( "ui.animateWithAbilityBar", true, "account" );

		Preferences.add( "ui.bars.primary.position", undefined, "account" );
		Preferences.add( "ui.bars.primary.item.showType", Enums.e_BarItemShowFirst, "account" );
		
		Preferences.add( "ui.bars.secondary.position", undefined, "account" );
		Preferences.add( "ui.bars.secondary.item.showType", Enums.e_BarItemShowFirst, "account" );

		Preferences.add( "ui.bars.shield.position", undefined, "account" );
		Preferences.add( "ui.bars.shield.item.showType", Enums.e_BarItemShowFirst, "account" );

		Preferences.add( "ui.bar.background.type", Enums.e_BarTypeThin, "account" );
		Preferences.add( "ui.bar.tint", false, "account" );
		Preferences.add( "ui.bar.neon", true, "account" );

		Preferences.add( "ui.item.tint", false, "account" );
		Preferences.add( "ui.item.neon", true, "account" );

		Preferences.add( "ui.xp.enabled", true, "account" );
		Preferences.add( "ui.xp.hideWhenFull", false, "account" );
		
		Preferences.add( "ui.tooltips.enabled", true, "account" );
		Preferences.add( "ui.tooltips.suppressInCombat", true, "account" );
		
		Preferences.add( "ui.aegis.tint", false, "account" );
		Preferences.add( "ui.aegis.selected.neon", true, "account" );
		Preferences.add( "ui.aegis.selected.background.enabled", false, "account" );
		Preferences.add( "ui.aegis.selected.background.tint", false, "account" );
		Preferences.add( "ui.aegis.selected.background.neon", false, "account" );

		Preferences.add( "ui.select.leftButton", Enums.e_SelectionDual, "account" );
		Preferences.add( "ui.select.rightButton", Enums.e_SelectionSingle, "account" );
		Preferences.add( "ui.select.shiftLeftButton", Enums.e_SelectionSingle, "account" );
		
		Preferences.add( "hotkeys.enabled", true, "account" );
		Preferences.add( "hotkeys.lockedOutWhenHudDisabled", true, "account" );
		Preferences.add( "hotkeys.primary.select", Enums.e_SelectionDual, "account" );
		Preferences.add( "hotkeys.secondary.select", Enums.e_SelectionDual, "account" );

		Preferences.add( "tints.aegis.psychic", 			0xe083ff, "account" );
		Preferences.add( "tints.aegis.cybernetic",			0x00d0ff, "account" );
		Preferences.add( "tints.aegis.demonic",				0xff3300, "account" );
		Preferences.add( "tints.aegis.empty",				0x999999, "account" );
		Preferences.add( "tints.aegis.standardBackground",	0xe8e8e8, "account" );
		
		Preferences.add( "tints.xp.progress",				0xf0f0f0, "account" );	/* 0x00E5A3 */
		Preferences.add( "tints.xp.full",					0x66ff66, "account" );	/* // 0x4EE500 // 0x19FDFF */
	}
	
	/**
	 * starts the app running
	 */
	public static function start() : Void {
		if ( running ) return;
		running = true;
		
		init();

		Preferences.load();

		//start the aegis server
		AegisServer.start();		
		
		// listen for pref changes
		Preferences.addEventListener( "app.enabled", App, "updatePlayfieldBlacklist" );
		Preferences.addEventListener( "app.enabled", App, "controlHUD" );
		Preferences.addEventListener( "app.enabled", App, "controlAutoSwap" );
		
		Preferences.addEventListener( "autoSwap.enabled", App, "controlAutoSwap" );
		
		Preferences.addEventListener( "defaultUI.disruptorSelect.hide", App, "defaultDisruptorButtonsPrefHandler" );
		Preferences.addEventListener( "defaultUI.shieldSelect.hide", App, "defaultShieldButtonPrefHandler" );
		Preferences.addEventListener( "hotkeys.enabled", App, "hotkeyPrefHandler" );
		
		// create widget
		widgetClip = SFClipLoader.LoadClip( ID + "\\Widget.swf", ID + "_Widget", false, _global.Enums.ViewLayer.e_ViewLayerTop, 2, [] );
		widgetClip.SignalLoaded.Connect( widgetLoaded );
		
		// listen for config window directives
		showConfigWindow = DistributedValue.Create( ID + "_ShowConfigWindow" );
		showConfigWindow.SignalChanged.Connect( controlConfigWindow );

		// ui element finder tracking
		uiElementFinder = { };
	}
	
	/**
	 * registers the app with VTIO
	 */
	private static function registerWithVTIO() : Void {

		VTIOConnector.register( ID, Author, Version, ID + "_ShowConfigWindow", widgetClip.m_Movie.m_Icon, registeredWithVTIO );
	}

	/**
	 * loads the HUD clip, the main UI for the app
	 */
	private static function loadHUD() : Void {

		if ( hudClip ) return;
		
		hudClip = SFClipLoader.LoadClip( ID + "\\HUD.swf", ID + "_HUD", false, _global.Enums.ViewLayer.e_ViewLayerMiddle, 0, [] );
		hudClip.SignalLoaded.Connect( hudLoaded );

	}

	/**
	 * triggers updates that need to occur after the HUD clip has loaded
	 * 
	 * @param	clipNode
	 * @param	success
	 */
	private static function hudLoaded( clipNode:ClipNode, success:Boolean ) : Void {
		debug( "App: hud loaded: " + success );

	}
	
	/**
	 * unloads the HUD clip
	 */
	private static function unloadHUD() : Void {
		
		if ( !hudClip ) return;
		
		hudClip.m_Movie.UnloadClip();
		hudClip = null;
		
		debug("App: hud clip unloaded");
		
	}
	
	/**
	 * conditionally loads/unloads the main HUD
	 */
	private static function controlHUD() : Void {
		
		// load the hud if...
		if ( enabled && AegisServer.aegisSystemUnlocked ) {
			loadHUD();
		}
		
		// otherwise unload it
		else {
			unloadHUD();
		}
	}
	
	/**
	 * conditionally loads/unloads the config window
	 */
	private static function controlConfigWindow() : Void {
		
		if ( showConfigWindow.GetValue() && !configWindowClip ) {
			configWindowClip = SFClipLoader.LoadClip( ID + "\\ConfigWindow.swf", ID + "_ConfigWindow", false, _global.Enums.ViewLayer.e_ViewLayerOptions, 0, [] );
		}
		
		else {
			configWindowClip.m_Movie.UnloadClip();
			configWindowClip = null;
		}
	}
	
	/**
	 * conditionally starts/stops the autoswapper
	 */
	private static function controlAutoSwap() : Void {

		if ( active && enabled && autoSwapEnabled ) {
			startAutoSwap();
		}
		
		else {
			stopAutoSwap();
		}		
		
	}
	
	/**
	 * starts the autoswapper
	 */
	private static function startAutoSwap() : Void {
		if ( !autoSwapper ) {
			autoSwapper = new AutoSwapper();
		}
	}
	
	/**
	 * stops the autoswapper
	 */
	private static function stopAutoSwap() : Void {
		autoSwapper.dispose();
		autoSwapper = null;
	}
	
	/**
	 * terminate the app, removing all loaded clips
	 * - typically called by OnUnload in the module
	 */
	public static function shutdown() : Void {
		
		Preferences.removeAllEventListeners();
		
		deactivate();
		
		AegisServer.shutdown();
		
		// unload widget clip
		widgetClip.m_Movie.UnloadClip();
		widgetClip = null;
		
		// unload config window
		showConfigWindow.SetValue( false );
		showConfigWindow.SignalChanged.Disconnect( controlConfigWindow );
		showConfigWindow = null;
		
		running = false;
		
		debug( "App: stopped" );
		
	}

	/**
	 * handles updating the playfield blacklist when enabled is toggled
	 * 
	 * @param	e
	 */
	private static function updatePlayfieldBlacklist( e:Object ) : Void {
		var value:Boolean = Preferences.getValue( "app.enabled" );
		
		var blacklist:Object = Preferences.getValue( "app.disabled.playfields" );
		
		var playfield:Number = Character.GetClientCharacter().GetPlayfieldID();
		
		if ( value ) {
			delete blacklist[playfield];
		}
		
		else {
			if ( blacklist == undefined ) {
				blacklist = new Object();
			}
			
			blacklist[playfield] = true;
		}

		Preferences.setValue( "app.disabled.playfields", blacklist );
	}

	/**
	 * pref change handler for default ui disruptor swap button visibility
	 * 
	 * @param	e
	 */
	private static function defaultDisruptorButtonsPrefHandler( e:Object ) : Void {
		hideDefaultDisruptorButtons( Preferences.getValue("defaultUI.disruptorSelect.hide") );
	}
	
	/**
	 * hides or shows the default disruptor swap buttons
	 * 
	 * @param	hide
	 */
	private static function hideDefaultDisruptorButtons( hide:Boolean ) : Void {
		
		var pb:MovieClip = _root.passivebar;
		
		// if restoring items, assume UI is present already
		if ( !hide && pb.LoadPrimaryAegisButton_AegisHUD_Saved != undefined ) {
			pb.LoadPrimaryAegisButton = pb.LoadPrimaryAegisButton_AegisHUD_Saved;
			pb.LoadPrimaryAegisButton_AegisHUD_Saved = undefined;

			pb.LoadSecondaryAegisButton = pb.LoadSecondaryAegisButton_AegisHUD_Saved;
			pb.LoadSecondaryAegisButton_AegisHUD_Saved = undefined;

			// do a load to restore buttons naturally if they need to be visible
			pb.LoadAegisButtons();
		}	
		
		else {
		
			// wait for the passivebar to be loaded, as it actually gets unloaded during teleports etc, not just deactivated
			if ( pb.LoadAegisButtons == undefined ) {
				
				// if the thrash count is exceeded, reset count and do nothing
				if ( new Date() - uiElementFinder["defaultSwapButtons"].startTime > 3000 )  uiElementFinder["defaultSwapButtons"] = undefined;

				// otherwise try again only if we aren't trying to restore the buttons
				else {
					if ( uiElementFinder["defaultSwapButtons"] == undefined ) {
						uiElementFinder["defaultSwapButtons"].startTime = new Date();
					}
					
					_global.setTimeout( hideDefaultDisruptorButtons, 100, hide );
				}

				return;
			}
			
			uiElementFinder["defaultSwapButtons"] = undefined;

			// hide buttons
			if ( pb.LoadPrimaryAegisButton_AegisHUD_Saved == undefined ) {
				pb.LoadPrimaryAegisButton_AegisHUD_Saved = pb.LoadPrimaryAegisButton;
				// break the link
				pb.LoadPrimaryAegisButton = undefined;
				pb.LoadPrimaryAegisButton = function() { };

				pb.LoadSecondaryAegisButton_AegisHUD_Saved = pb.LoadSecondaryAegisButton;
				// break the link
				pb.LoadSecondaryAegisButton = undefined;
				pb.LoadSecondaryAegisButton = function() { };
				
				// remove any existing movieclips
				pb.m_PrimaryAegisSwap.removeMovieClip();
				pb.m_SecondaryAegisSwap.removeMovieClip();
			}
		}
	}

	/**
	 * pref change handler for default ui shield swap button visibility
	 * 
	 * @param	e
	 */
	private static function defaultShieldButtonPrefHandler( e:Object ) : Void {
		hideDefaultShieldButton( Preferences.getValue("defaultUI.shieldSelect.hide") );
	}
	
	/**
	 * hides or shows the default shield swap button
	 * 
	 * @param	hide
	 */
	private static function hideDefaultShieldButton( hide:Boolean ) : Void {
		
		var pi:MovieClip = _root.playerinfo.m_PlayerShield;

		// if restoring items, assume UI is present already
		if ( !hide ) {
			pi._visible = true;
		}
		
		else {
		
			// wait for the playerinfo panel to be loaded, as it actually gets unloaded during teleports etc, not just deactivated
			if ( pi == undefined ) {
				
				// if the thrash count is exceeded, reset count and do nothing
				if ( new Date() - uiElementFinder["defaultShieldButton"].startTime > 3000 )  uiElementFinder["defaultShieldButton"] = undefined;
				// otherwise try again only if we aren't trying to restore the buttons
				else {
					_global.setTimeout( hideDefaultShieldButton, 100, hide );
				}
				
				return;
			}
			
			uiElementFinder["defaultShieldButton"] = undefined

			// hide button
			pi._visible = false;
		
		}
	}	

	/**
	 * pref change handler for hotkey override
	 * 
	 * @param	e
	 */
	public static function hotkeyPrefHandler( e:Object ) : Void {
		HotkeyManager.Hijack( Preferences.getValue("hotkeys.enabled") );
	}
	
	/**
	 * prints a message to the chat window if debug is enabled
	 * 
	 * @param	message
	 */
	public static function debug( message:String ) : Void {
		if ( !debugEnabled ) return;
		
		UtilsBase.PrintChatText( ID + ": " + message );
	}

	
	/*
	 * internal variables
	 */

	private var aegisServer:AegisServer;
	 
	private var hudClip:ClipNode;
	private var widgetClip:ClipNode;
	private var configWindowClip:ClipNode;
	
	private var showConfigWindow:DistributedValue;
	
	private var autoSwapper:AutoSwapper;
	
	private var uiElementFinder:Object;
	
	/*
	 * properties
	 */
	
	public var ID:String = "ElTorqiro_AegisHUD";
	public var Name:String = "AegisHUD";
	public var Version:String = "4.0.0 pre-alpha";
	public var Author:String = "ElTorqiro";
	
	public var debugEnabled:Boolean;
	
	public var prefs:Preferences;
	
	public function get enabled() : Boolean {
		return Boolean(Preferences.getValue( "app.enabled" ));
	}
	
	public function set enabled( value:Boolean ) {
		Preferences.setValue( "app.enabled", Boolean(value) );
	}
	
	public function get autoSwapEnabled() : Boolean {
		return Boolean(Preferences.getValue( "autoSwap.enabled" ));
	}
	
	public function set autoSwapEnabled( value:Boolean ) {
		Preferences.setValue( "autoSwap.enabled", Boolean(value) );
	}
	
	private var _active:Boolean;
	public static function get active() : Boolean { return _active; }
	
}