import com.Utils.Archive;
import mx.utils.Delegate;

import com.Utils.GlobalSignal;

import com.Utils.Signal;
import GUIFramework.ClipNode;
import GUIFramework.SFClipLoader;
import com.GameInterface.LoreBase;
import com.GameInterface.Game.Character;
import com.GameInterface.DistributedValue;

import com.GameInterface.UtilsBase;
import com.GameInterface.LogBase;

import com.ElTorqiro.AegisHUD.Const;
import com.ElTorqiro.AegisHUD.Preferences;
import com.ElTorqiro.AegisHUD.VTIOConnector;
import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.AutoSwapper;
import com.ElTorqiro.AegisHUD.HotkeyManager;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.App {
	
	// static class only
	private function App() { }
	
	// starts the app running
	public static function start() {

		if ( running ) return;
		_running = true;
		
		debug( "App: start" );
		
		timers = { };
		
		// load preferences
		prefs = new Preferences( Const.PrefsName );
		createPrefs();
		prefs.load();

		// perform initial installation tasks
		install();
		
		// start aegis server running
		AegisServer.start();

		// attach widget
		widgetClip = SFClipLoader.LoadClip( Const.AppID + "\\Widget.swf", Const.AppID + "_Widget", false, _global.Enums.ViewLayer.e_ViewLayerTop, 2, [] );
		widgetClip.SignalLoaded.Connect( widgetLoaded );
	
		// listen for GUI edit mode signal, to retain state so the HUD can use it even if the HUD is not enabled when the signal is emitted
		GlobalSignal.SignalSetGUIEditMode.Connect( guiEditModeChangeHandler );
		
	}

	/**
	 * stop app running and clean up resources
	 */
	public static function stop() : Void {
		
		debug( "App: stop" );
		
		GlobalSignal.SignalSetGUIEditMode.Disconnect( guiEditModeChangeHandler );
		
		// unload widget
		SFClipLoader.UnloadClip( Const.AppID + "_Widget" );
		widgetClip = null;

		// stop aegis server
		AegisServer.stop();

		// remove prefs
		prefs.dispose();
		prefs = null;
		
		// remove timers
		timers = null;
		
		_running = false;
	}
	
	/**
	 * make the app active
	 * - typically called by OnModuleActivated in the module
	 */
	public static function activate() : Void {
		
		debug( "App: activate" );
		
		_active = true;
		
		// show widget clip
		manageWidgetVisibility();

		// determine hud enabled state based on playfield memory
		// hud clip will be loaded if the hud becomes enabled at this point, courtesy of the pref event listener
		prefs.setVal( "hud.enabled", !(prefs.getVal( "hud.disabledPlayfields" )[ Character.GetClientCharacter().GetPlayfieldID() ]) );
		manageHud();
		
		// manipulate default ui elements
		manageDefaultUiShieldButton();
		
		// start autoswapper
		manageAutoSwapper();
		
		// hijack hotkeys
		manageHotkeys();

		// manage config window
		manageConfigWindow();
		showConfigWindowMonitor = DistributedValue.Create( Const.ShowConfigWindowDV );
		showConfigWindowMonitor.SignalChanged.Connect( manageConfigWindow );

		// listen for pref changes and route to appropriate behaviour
		prefs.SignalValueChanged.Connect( prefChangeHandler );
		
	}
	
	/**
	 * make the app inactive
	 * - typically called by OnModuleDeactivated in the module
	 */
	public static function deactivate() : Void {
		
		debug( "App: deactivate" );
		
		_active = false;

		// destroy config window
		showConfigWindowMonitor.SetValue ( false );
		showConfigWindowMonitor.SignalChanged.Disconnect( manageConfigWindow );
		showConfigWindowMonitor = null;
		
		// stop listening for pref value changes
		prefs.SignalValueChanged.Disconnect( prefChangeHandler );
		
		// update playfield hud enabled memory
		var playfield:Number = Character.GetClientCharacter().GetPlayfieldID();
		var blacklist:Object = prefs.getVal( "hud.disabledPlayfields" );
		if ( !hudEnabled ) {
			blacklist[ playfield ] = true;
		}
		
		else {
			delete blacklist[ playfield ];
		}

		// hide widget clip
		manageWidgetVisibility();
		
		// destroy hud clip
		manageHud();
		
		// restore default ui elements
		manageDefaultUiShieldButton();
		
		// stop autoswapper
		manageAutoSwapper();
		
		// release hotkeys
		manageHotkeys();
		
		// save settings
		prefs.save();
	}

	/**
	 * populate pref object with app entries
	 */
	private static function createPrefs() : Void  {
		
		prefs.add( "prefs.version", Const.PrefsVersion );
		
		prefs.add( "app.installed", false );
		
		prefs.add( "configWindow.position", undefined );
		prefs.add( "widget.position", undefined );
		prefs.add( "widget.scale", 100 );
		
		prefs.add( "hud.enabled", true );

		prefs.add( "hud.disabledPlayfields", {} );
		
		prefs.add( "autoSwap.enabled", true );
		
		prefs.add( "autoSwap.type.primary", Const.e_AutoSwapOffensiveShield );
		prefs.add( "autoSwap.type.secondary", Const.e_AutoSwapOffensiveShield );
		prefs.add( "autoSwap.type.shield", Const.e_AutoSwapOffensiveDisruptor );

		prefs.add( "autoSwap.match.friendly.self", true );
		prefs.add( "autoSwap.match.enemy.players", false );
		
		prefs.add( "defaultUI.disruptorSelectors.hide", true );
		prefs.add( "defaultUI.shieldSelector.hide", true );

		prefs.add( "hud.hide.whenAutoswapEnabled", false );
		prefs.add( "hud.hide.whenNotInCombat", false );
		
		prefs.add( "hud.scale", 100 );
		
		prefs.add( "hud.icons.type", Const.e_IconTypeAegisHUD );
		
		prefs.add( "hud.abilityBarIntegration.enable", true );

		prefs.add( "hud.layout.type", Const.e_LayoutDefault );
		
		prefs.add( "hud.bars.primary.position", undefined );
		prefs.add( "hud.bars.primary.itemSlotPlacement", Const.e_BarItemPlaceFirst );
		
		prefs.add( "hud.bars.secondary.position", undefined );
		prefs.add( "hud.bars.secondary.itemSlotPlacement", Const.e_BarItemPlaceFirst );

		prefs.add( "hud.bars.shield.position", undefined );
		prefs.add( "hud.bars.shield.itemSlotPlacement", Const.e_BarItemPlaceFirst );

		prefs.add( "hud.bar.background.type", Const.e_BarTypeThin );
		prefs.add( "hud.bar.background.tint", false );
		prefs.add( "hud.bar.background.neon", true );
		prefs.add( "hud.bar.background.transparency", 100 );

		prefs.add( "hud.slots.item.tint", false );
		prefs.add( "hud.slots.item.neon", true );

		prefs.add( "hud.slots.aegis.xp.enabled", true );
		prefs.add( "hud.slots.aegis.xp.hideWhenFull", false );
		
		prefs.add( "hud.tooltips.enabled", true );
		prefs.add( "hud.tooltips.suppressInCombat", true );
		
		prefs.add( "hud.slots.aegis.tint", false );
		prefs.add( "hud.slots.selectedAegis.neon", true );
		prefs.add( "hud.slots.selectedAegis.background.transparency", 0 );
		prefs.add( "hud.slots.selectedAegis.background.tint", false );
		prefs.add( "hud.slots.selectedAegis.background.neon", false );

		prefs.add( "hud.click.multiSelectType.leftButton", Const.e_SelectMulti );
		prefs.add( "hud.click.multiSelectType.rightButton", Const.e_SelectSingle );
		prefs.add( "hud.click.multiSelectType.shiftLeftButton", Const.e_SelectSingle );
		
		prefs.add( "hotkeys.enabled", true );
		prefs.add( "hotkeys.lockoutWhenHudDisabled", true );
		prefs.add( "hotkeys.multiSelectType.primary", Const.e_SelectMulti );
		prefs.add( "hotkeys.multiSelectType.secondary", Const.e_SelectMulti );

		prefs.add( "hud.tints.aegis.psychic", 			0xe083ff );
		prefs.add( "hud.tints.aegis.cybernetic",		0x00d0ff );
		prefs.add( "hud.tints.aegis.demonic",			0xff3300 );
		prefs.add( "hud.tints.aegis.empty",				0x999999 );
		prefs.add( "hud.tints.selectedAegis.background",0xc0c0c0 );
		prefs.add( "hud.tints.bar.background",			0x484848 );
		prefs.add( "hud.tints.xp.notFull",				0xf0f0f0 );	/* 0x00E5A3 */
		prefs.add( "hud.tints.xp.full",					0x66ff66 );	/* // 0x4EE500 // 0x19FDFF */
		
	}

	/**
	 * handle pref value changes and route to appropriate behaviour
	 * 
	 * @param	name
	 * @param	newValue
	 * @param	oldValue
	 */
	private static function prefChangeHandler( name:String, newValue, oldValue ) : Void {
		
		switch ( name ) {
			
			case "hud.enabled":
				manageAutoSwapper();
				manageHud();
			break;
			
			case "autoSwap.enabled":
				manageAutoSwapper();
				manageHud();
			break;
			
		case "hud.hide.whenAutoswapEnabled":
				manageHud();
			break;
			
			case "defaultUI.shieldSelector.hide":
				manageDefaultUiShieldButton();
			break;
		
		}
		
	}
	
	/**
	 * triggers updates that need to occur after the widget clip has been loaded
	 * 
	 * @param	clipNode
	 * @param	success
	 */
	private static function widgetLoaded( clipNode:ClipNode, success:Boolean ) : Void {
		debug("App: widget loaded: " + success);
		
		manageWidgetVisibility();

		vtio = new VTIOConnector( Const.AppID, Const.AppAuthor, Const.AppVersion, Const.ShowConfigWindowDV, widgetClip.m_Movie.m_Icon, registeredWithVTIO );
	}

	/**
	 * triggers updates that need to occur after the app has been registered with VTIO
	 * e.g. updating the state of the widget icon copy that VTIO creates
	 */
	private static function registeredWithVTIO() : Void {

		debug( "App: registered with VTIO" );
		
		vtio = null;
	}
	
	/**
	 * controls the visibility of the widget clip
	 */
	private static function manageWidgetVisibility() : Void {
		widgetClip.m_Movie._visible = active;
	}	

	/**
	 * shows or hides the config window
	 * 
	 * @param	show
	 */
	public static function manageConfigWindow() : Void {
		debug( "App: manageConfigWindow" );
		
		if ( active && showConfigWindowMonitor.GetValue() ) {
			
			if ( !configWindowClip ) {
				debug("App: loading config window");
				configWindowClip = SFClipLoader.LoadClip( Const.ConfigWindowClipPath, Const.AppID + "_ConfigWindow", false, _global.Enums.ViewLayer.e_ViewLayerTop, 0, [] );
			}
		}
		
		else if ( configWindowClip ) {
			SFClipLoader.UnloadClip( Const.AppID + "_ConfigWindow" );
			configWindowClip = null;
			
			debug("App: config window clip unloaded");

		}
	}

	/**
	 * control the presence of the autoswap feature
	 */
	private static function manageAutoSwapper() : Void {
		
		if ( active && prefs.getVal( "autoSwap.enabled" ) && prefs.getVal( "hud.enabled" ) ) {
			
			if ( !swapper ) {
				debug( "App: creating AutoSwapper" );
				swapper = new AutoSwapper();
			}
		}
		
		else if ( swapper ) {
			debug( "App: destroying AutoSwapper" );
			swapper = null;
		}
		
	}

	/**
	 * control the hijacking of hotkeys feature
	 */
	private static function manageHotkeys() : Void {
		
		HotkeyManager.Hijack( active && prefs.getVal( "hotkeys.enabled" ) );
		
	}

	/**
	 * control the presence of the HUD
	 */
	private static function manageHud() : Void {
		
		if ( active && prefs.getVal( "hud.enabled" ) && AegisServer.aegisSystemUnlocked 
			&& ( prefs.getVal( "hud.hide.whenAutoswapEnabled" ) ? !prefs.getVal( "autoSwap.enabled" ) : true )
		) {
			
			if ( !hudClip ) {
				debug("App: loading hud");
				hudClip = SFClipLoader.LoadClip( Const.HudClipPath, Const.AppID + "_HUD", false, _global.Enums.ViewLayer.e_ViewLayerMiddle, 0, [] );
			}
		}
		
		else if ( hudClip ) {
			SFClipLoader.UnloadClip( Const.AppID + "_HUD" );
			hudClip = null;
			
			debug("App: hud clip unloaded");
		}
		
	}

	/**
	 * manage the default shield selector ui visibility
	 */
	private static function manageDefaultUiShieldButton() : Void {

		var el:MovieClip = _root.playerinfo.m_PlayerShield;

		var hide:Boolean = prefs.getVal( "defaultUI.shieldSelector.hide" );
		
		if ( hide && active && (el == undefined) ) {
			
			// set up initial run of timer
			if ( timers.mdusb == undefined ) {
				timers.mdusb = { id: setTimeout( manageDefaultUiShieldButton, 20 ), start: new Date() };
				debug( "mdusb timer: starting up, " + timers.mdusb.start );
			}
			
			// else if timer is running, just restart it
			else if ( (new Date()) - timers.mdusb.start < 2000 ) {
				debug( "mdusb timer: restarting timer (tick)" );
				timers.mdusb.id = setTimeout( manageDefaultUiShieldButton, 20 );
			}

			// if timer has expired and still haven't found the element, revert to default behaviour
			else {
				debug( "mdusb timer: giving up, " + ((new Date()) - timers.mdusb.start) );
				delete timers.mdusb;
			}
			
			return;
		}
		
		delete timers.mdusb;
		el._visible = !( hide && active ) || !active;
	}
	
	/**
	 * performs initial installation tasks
	 */
	private static function install() : Void {
		
		// only "install" once ever
		if ( !prefs.setVal( "app.installed" ) ) {;
		
			// hide default disruptor swap ui
			DistributedValue.SetDValue( "ShowAegisSwapUI", false );

			prefs.setVal( "app.installed", true );
		}
		
		
		// handle upgrades from one version to the next
		var prefsVersion:Number = prefs.getVal( "prefs.version" );
		
		// set prefs version to current version
		prefs.reset( "prefs.version" );
	}

	/**
	 * handles gui edit mode signal, to keep a constant track of edit mode state
	 * 
	 * @param	value
	 */
	private static function guiEditModeChangeHandler( edit:Boolean ) : Void {
		_guiEditMode = edit;
	}
	
	/**
	 * prints a message to the chat window if debug is enabled
	 * 
	 * @param	msg
	 */
	public static function debug( msg:String ) : Void {
		if ( !debugEnabled ) return;
		
		var message:String = Const.AppID + ": " + msg;
		
		UtilsBase.PrintChatText( message );
		LogBase.Print( 3, Const.AppID, message );
	}
	
	/*
	 * internal variables
	 */
	 
	private static var hudClip:ClipNode;
	private static var widgetClip:ClipNode;
	private static var configWindowClip:ClipNode;
	
	private static var showConfigWindowMonitor:DistributedValue;
	
	private static var vtio:VTIOConnector;
	
	private static var swapper:AutoSwapper;
	
	private static var timers:Object;
	
	/*
	 * properties
	 */
	
	public static function get debugEnabled() : Boolean {
		return Boolean(DistributedValue.GetDValue( Const.DebugModeDV ));
	};
	
	public static var prefs:Preferences;

	private static var _active:Boolean;
	public static function get active() : Boolean { return _active; }

	private static var _running:Boolean;
	public static function get running() : Boolean { return Boolean(_running); }
	
	public static function get hudEnabled() : Boolean {
		return Boolean(prefs.getVal( "hud.enabled" ));
	}
	
	public static function get autoSwapEnabled() : Boolean {
		return Boolean(prefs.getVal( "autoSwap.enabled" ));
	}
	
	private static var _guiEditMode:Boolean;
	public static function get guiEditMode() : Boolean { return _guiEditMode; }
}