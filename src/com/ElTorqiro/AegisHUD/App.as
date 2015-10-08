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
import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.AutoSwapper;
import com.ElTorqiro.AegisHUD.HotkeyManager;
import com.ElTorqiro.AegisHUD.AddonUtils.CommonUtils;
import com.ElTorqiro.AegisHUD.AddonUtils.Preferences;
import com.ElTorqiro.AegisHUD.AddonUtils.VTIOConnector;

import com.ElTorqiro.AegisHUD.AddonUtils.MovieClipHelper;
import com.ElTorqiro.AegisHUD.HUD.HUD;


/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.App {
	
	// static class only
	private function App() { }
	
	// starts the app running
	public static function start( host:MovieClip ) {

		if ( running ) return;
		_running = true;
		
		debug( "App: start" );
		
		hostMovie = host;
		hostMovie._visible = false;
		
		// load preferences
		prefs = new Preferences( Const.PrefsName );
		createPrefs();
		prefs.load();

		// perform initial installation tasks
		install();
		
		// start aegis server running
		AegisServer.start();

		// attach app icon
		_isRegisteredWithVtio = false;
		iconClip = SFClipLoader.LoadClip( Const.IconClipPath, Const.AppID + "_Icon", false, Const.IconClipDepthLayer, Const.IconClipSubDepth, [] );
		iconClip.SignalLoaded.Connect( iconLoaded );
	
		// attach hud
		hudMovie = HUD( MovieClipHelper.createMovieWithClass( HUD, "m_HUD", hostMovie, hostMovie.getNextHighestDepth() ) );
		LoreBase.SignalTagAdded.Connect( loreTagAddedHandler );
		
		// prepare for config window signal
		showConfigWindowMonitor = DistributedValue.Create( Const.ShowConfigWindowDV );
		
		// listen for GUI edit mode signal
		GlobalSignal.SignalSetGUIEditMode.Connect( guiEditModeChangeHandler );
		
		// set up listener for combat state changes
		Character.GetClientCharacter().SignalToggleCombat.Connect( manageVisibility );

		// listen for pref changes and route to appropriate behaviour
		prefs.SignalValueChanged.Connect( prefChangeHandler );
		
	}

	/**
	 * stop app running and clean up resources
	 */
	public static function stop() : Void {
		
		debug( "App: stop" );

		// stop listening for pref value changes
		prefs.SignalValueChanged.Disconnect( prefChangeHandler );
		
		// stop listening for gui edit mode signal
		GlobalSignal.SignalSetGUIEditMode.Disconnect( guiEditModeChangeHandler );
		
		// set up listener for combat state changes
		Character.GetClientCharacter().SignalToggleCombat.Disconnect( manageVisibility );
		
		// release resources for config window signal
		showConfigWindowMonitor = null;
		
		// unload icon
		SFClipLoader.UnloadClip( Const.AppID + "_Icon" );
		iconClip = null;
		
		// unload hud
		LoreBase.SignalTagAdded.Disconnect( loreTagAddedHandler );
		hudMovie.dispose();
		hudMovie.removeMovieClip();
		hudMovie = null;

		// stop aegis server
		AegisServer.stop();
		
		// remove prefs
		prefs.dispose();
		prefs = null;
		
		_running = false;

	}
	
	/**
	 * make the app active
	 * - typically called by OnModuleActivated in the module
	 */
	public static function activate() : Void {
		
		debug( "App: activate" );
		
		_active = true;
		
		// component clip visibility
		iconClip.m_Movie._visible = true;
		manageVisibility();

		// determine hud enabled state based on playfield memory
		prefs.setVal( "hud.enabled", !(prefs.getVal( "hud.disabledPlayfields" )[ Character.GetClientCharacter().GetPlayfieldID() ]) );
		
		// manipulate default ui elements
		manageDefaultUiShieldButton();
		
		// start autoswapper
		manageAutoSwapper();
		
		// hijack hotkeys
		manageHotkeys();

		// manage config window
		showConfigWindowMonitor.SignalChanged.Connect( manageConfigWindow );
		manageConfigWindow();

		// inform the HUD that the GUI has been activated
		hudMovie.activate();
	}

	/**
	 * make the app inactive
	 * - typically called by OnModuleDeactivated in the module
	 */
	public static function deactivate() : Void {
		
		debug( "App: deactivate" );
		
		_active = false;

		// inform the HUD that the GUI has been activated
		hudMovie.deactivate();
		
		// destroy config window
		showConfigWindowMonitor.SetValue ( false );
		showConfigWindowMonitor.SignalChanged.Disconnect( manageConfigWindow );

		// release hotkeys
		manageHotkeys();

		// stop autoswapper
		manageAutoSwapper();

		// restore default ui elements
		manageDefaultUiShieldButton();

		// update playfield hud enabled memory
		var playfield:Number = Character.GetClientCharacter().GetPlayfieldID();
		var blacklist:Object = prefs.getVal( "hud.disabledPlayfields" );
		prefs.getVal( "hud.enabled" ) ? delete blacklist[ playfield ] : blacklist[ playfield ] = true;
		
		// component clip visibility
		iconClip.m_Movie._visible = false;
		manageVisibility();
		
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
		
		/**
		 * use of name "widget" changed to "icon" in 4.0.0 beta, retained here solely for upgrading purposes
		 */
		prefs.add( "widget.position", undefined );
		prefs.add( "widget.scale", 100 );
		
		prefs.add( "icon.position", undefined );
		prefs.add( "icon.scale", 100,
			function( newValue, oldValue ) {
				var value:Number = Math.min( newValue, Const.MaxIconScale );
				value = Math.max( value, Const.MinIconScale );
				
				return value;
			}
		);
		
		prefs.add( "hud.enabled", true );

		prefs.add( "hud.disabledPlayfields", {} );
		
		prefs.add( "autoSwap.enabled", true );
		
		prefs.add( "autoSwap.type.primary", Const.e_AutoSwapOffensiveShieldXorDisruptor );
		prefs.add( "autoSwap.type.secondary", Const.e_AutoSwapOffensiveShieldXorDisruptor );
		prefs.add( "autoSwap.type.shield", Const.e_AutoSwapOffensiveDisruptor );

		prefs.add( "autoSwap.match.friendly.self", true );
		prefs.add( "autoSwap.match.enemy.players", false );
		
		prefs.add( "defaultUI.disruptorSelectors.hide", true );
		prefs.add( "defaultUI.shieldSelector.hide", true );

		prefs.add( "hud.hide.whenAutoswapEnabled", false );
		prefs.add( "hud.hide.whenNotInCombat", false );
		
		prefs.add( "hud.position.default", true );
		prefs.add( "hud.scale", 100,
			function( newValue, oldValue ) {
				var value:Number = Math.min( newValue, Const.MaxBarScale );
				value = Math.max( value, Const.MinBarScale );
				
				return value;
			}
		);
		
		prefs.add( "hud.icons.type", Const.e_IconTypeAegisHUD );
		
		// retired with the 4.0.0 beta update, kept here for upgrade purposes only
		prefs.add( "hud.abilityBarIntegration.enable", true );

		prefs.add( "hud.bars.primary.position", undefined );
		prefs.add( "hud.bars.primary.itemSlotPlacement", Const.e_BarItemPlaceFirst );
		
		prefs.add( "hud.bars.secondary.position", undefined );
		prefs.add( "hud.bars.secondary.itemSlotPlacement", Const.e_BarItemPlaceFirst );

		prefs.add( "hud.bars.shield.position", undefined );
		prefs.add( "hud.bars.shield.itemSlotPlacement", Const.e_BarItemPlaceFirst );

		prefs.add( "hud.bar.background.type", Const.e_BarTypeThin );
		prefs.add( "hud.bar.background.tint", true );
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
			case "autoSwap.enabled":
				manageAutoSwapper();
				manageVisibility();
			break;
			
			case "hud.hide.whenAutoswapEnabled":
			case "hud.hide.whenNotInCombat":
				manageVisibility();
			break;
			
			case "defaultUI.shieldSelector.hide":
				manageDefaultUiShieldButton();
			break;
		
		}
		
	}
	
	/**
	 * triggers updates that need to occur after the icon clip has been loaded
	 * 
	 * @param	clipNode
	 * @param	success
	 */
	private static function iconLoaded( clipNode:ClipNode, success:Boolean ) : Void {
		debug("App: icon loaded: " + success);
		
		vtio = new VTIOConnector( Const.AppID, Const.AppAuthor, Const.AppVersion, Const.ShowConfigWindowDV, iconClip.m_Movie.m_Icon, registeredWithVTIO );
	}

	/**
	 * triggers updates that need to occur after the app has been registered with VTIO
	 * e.g. updating the state of the icon copy that VTIO creates
	 */
	private static function registeredWithVTIO() : Void {

		debug( "App: registered with VTIO" );
		
		// move clip to the depth required by VTIO icons
		SFClipLoader.SetClipLayer( SFClipLoader.GetClipIndex( iconClip.m_Movie ), VTIOConnector.e_VtioDepthLayer, VTIOConnector.e_VtioSubDepth );
		
		_isRegisteredWithVtio = true;
		vtio = null;
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
	 * control the visibility of the HUD
	 */
	private static function manageVisibility() : Void {
		hostMovie._visible = active && ( guiEditMode || 
			( Boolean(isAegisSystemUnlocked) && prefs.getVal( "hud.enabled" )
				&& ( prefs.getVal( "hud.hide.whenNotInCombat" ) ? Character.GetClientCharacter().IsThreatened() : true )
				&& ( prefs.getVal( "hud.hide.whenAutoswapEnabled" ) ? !prefs.getVal( "autoSwap.enabled" ) : true )
			)
		);
	}
	
	/**
	 * manage the default shield selector ui visibility
	 */
	private static function manageDefaultUiShieldButton( findThingId:String, thing, found:Boolean ) : Void {

		var shieldButton:MovieClip = _root.playerinfo.m_PlayerShield;
		
		var hide:Boolean = active && prefs.getVal( "defaultUI.shieldSelector.hide" );
		
		// unhide attempts immediately, no need to wait as it should only be invisible if we made it so earlier
		if ( !hide ) {
			CommonUtils.cancelFindThing( "shieldButton" );
			shieldButton._visible = true;
		}
		
		// trying to hide and finder isn't performing a callback, start finder
		else if ( !findThingId ) {
			CommonUtils.findThing( "shieldButton", "_root.playerinfo.m_PlayerShield", 20, 2000, manageDefaultUiShieldButton, manageDefaultUiShieldButton );
		}
		
		// trying to hide, and finder has found it
		else if ( found ) {
			shieldButton._visible = false;
		}
		
	}

	/**
	 * handler for ultimate ability becoming unlocked
	 * 
	 * @param	tag
	 */
	private static function loreTagAddedHandler( tag:Number ) {
		if ( tag == Const.e_AegisUnlockAchievement ) {
			manageVisibility();
		}
	}
	
	/**
	 * performs initial installation tasks
	 */
	private static function install() : Void {
		
		// only "install" once ever
		if ( !prefs.getVal( "app.installed" ) ) {;
		
			// hide default disruptor swap ui
			DistributedValue.SetDValue( "ShowAegisSwapUI", false );

			prefs.setVal( "app.installed", true );
		}
		
		
		// handle upgrades from one version to the next
		var prefsVersion:Number = prefs.getVal( "prefs.version" );
		
		if ( prefsVersion < 40006 ) {
			prefs.setVal( "icon.scale", prefs.getVal( "widget.scale" ) );
			prefs.setVal( "icon.position", prefs.getVal( "widget.position" ) );
			
			prefs.remove( "widget.scale" );
			prefs.remove( "widget.position" );
			
			prefs.setVal( "hud.position.default", prefs.getVal( "hud.abilityBarIntegration.enable" ) );
			prefs.remove( "hud.abilityBarIntegration.enable" );
		}
		
		if ( prefsVersion < 40008 ) {
			prefs.setVal( "hud.disabledPlayfields", new Object() );
		}
		
		// set prefs version to current version
		prefs.reset( "prefs.version" );
	}

	/**
	 * handles gui edit mode signal, to keep a constant track of edit mode state and set the right clip depth level for edit mode
	 * 
	 * @param	value
	 */
	private static function guiEditModeChangeHandler( edit:Boolean ) : Void {
		
		if ( guiEditMode == edit ) return;
		
		var hudClipIndex:Number = SFClipLoader.GetClipIndex( hostMovie );
		var subDepth:Number = edit ? Const.HudClipSubDepthGuiEditMode : Const.HudClipSubDepth;
		
		SFClipLoader.SetClipLayer( hudClipIndex, Const.HudClipDepthLayer, subDepth );

		_guiEditMode = edit;
	
		manageVisibility();
		
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
	 
	private static var hostMovie:MovieClip;
	private static var hudMovie:HUD;
	private static var iconClip:ClipNode;
	private static var configWindowClip:ClipNode;
	
	private static var showConfigWindowMonitor:DistributedValue;
	
	private static var vtio:VTIOConnector;
	
	private static var swapper:AutoSwapper;
	
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
	
	private static var _isRegisteredWithVtio:Boolean;
	public static function get isRegisteredWithVtio() : Boolean { return _isRegisteredWithVtio; }
	
	public static function get isAegisSystemUnlocked() : Boolean {
		return !LoreBase.IsLocked( Const.e_AegisUnlockAchievement );
	}
}