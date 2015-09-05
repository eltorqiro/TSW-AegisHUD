import flash.geom.Point;

import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Tooltip.TooltipManager;
import com.GameInterface.Tooltip.TooltipInterface;

import com.GameInterface.DistributedValue;

import com.ElTorqiro.AegisHUD.Const;
import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.Preferences;

import com.GameInterface.UtilsBase;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.IconWidget extends MovieClip {
	
	public function IconWidget() {
		
		App.debug( "IconWidget: " + _name + ": constructor" );

		isVtioIcon = _name == "Icon";
		
		App.prefs.addEventListener( "hud.enabled", this, "refreshState" );
		App.prefs.addEventListener( "autoSwap.enabled", this, "refreshState" );
		AegisServer.SignalAegisSystemUnlocked.Connect( refreshState, this );
		refreshState();
		
		// if this is not the duplicate created by VTIO, handle regular setup of icon
		if ( !isVtioIcon ) {
			attachMovie( "com.ElTorqiro.AegisHUD.IconWidget.Overlay", "m_Overlay", m_Overlay.getDepth() );
			m_Overlay._visible = false;
			
			this.scale = App.prefs.getVal( "widget.scale" );

			var position:Point = App.prefs.getVal( "widget.position" );
			if ( position == undefined ) {
				position = new Point( Math.floor((Stage.visibleRect.width - this._width) / 2), Math.floor((Stage.visibleRect.height + this._height) / 4) );
			}

			// update position pref
			App.prefs.setVal( "widget.position", position );
			
			this.position = position;

		}
		
	}
	
	/**
	 * refreshes the current internal state, and changes the icon accordingly
	 */
	public function refreshState() : Void {
		
		App.debug("IconWidget: " + _name + ": refreshState");
		
		var hudEnabled:Boolean = App.prefs.getVal("hud.enabled");
		var autoSwapEnabled:Boolean = App.prefs.getVal("autoSwap.enabled");
		
		if ( hudEnabled && !AegisServer.aegisSystemUnlocked ) {
			state = "locked";
		}
		
		else if ( hudEnabled && autoSwapEnabled ) {
			state = "autoswap";
		}
		
		else if ( hudEnabled ) {
			state = "enabled";
		}
		
		else {
			state = "disabled";
		}
		
		gotoAndStop( state );
	}
	
	public function onMousePress( button:Number ) : Void {
		
		var hudEnabled:Boolean = App.prefs.getVal("hud.enabled");
		var autoSwapEnabled:Boolean = App.prefs.getVal("autoSwap.enabled");
		
		// left button toggles config window
		if ( button == 1 ) {
			
			DistributedValue.SetDValue( Const.ShowConfigWindowDV, !DistributedValue.GetDValue( Const.ShowConfigWindowDV ) );
			closeTooltip();
		}
		
		// shift right-click toggles autoswap
		else if ( button == 2 && Key.isDown(Key.SHIFT) ) {
			
			// if app is enabled and autoswap is enabled, disable just the autoswap
			if ( hudEnabled && autoSwapEnabled ) {
				App.prefs.setVal( "autoSwap.enabled", false );
			}
			
			// if app is enabled, without autoswap
			else if ( hudEnabled ) {
				App.prefs.setVal( "autoSwap.enabled", true );
			}
			
			// if app is disabled, enable it and force autoswap on
			else {
				
				App.prefs.setVal( "autoSwap.enabled", true );
				App.prefs.setVal( "hud.enabled", true );
			}
			
			openTooltip();
		}
		
		// right click toggles enabled/disabled
		else if ( button == 2 ) {
			App.prefs.setVal( "hud.enabled", !App.prefs.getVal( "hud.enabled" ) );
			
			openTooltip();
		}
		
	}
	
	public function onRollOver() : Void {
		openTooltip();
	}
	
	public function onRollOut() : Void {
		closeTooltip();
	}
	
	private function closeTooltip() : Void {
		tooltip.Close();
		tooltip = null;
	}
	
	/**
	 * opens a tooltip on the icon, showing the current status of AegisHUD and some instructions
	 */
	private function openTooltip() : Void {
		
		closeTooltip();
		
		var td:TooltipData = new TooltipData();
		td.AddAttribute( "", "<font face=\'_StandardFont\' size=\'14\' color=\'#00ccff\'><b>" + Const.AppName + " v" + Const.AppVersion + "</b></font>" );
		td.AddAttributeSplitter();
		td.AddAttribute( "", "" );
		
		var stateStr:String = "";
		
		if ( state == "locked" ) {
			stateStr += "<font face=\'_StandardFont\' size=\'11\' color=\'#c8c8c8\'><b>AEGIS System Locked</b></font>";
		}
		
		else {
			stateStr += "<font face=\'_StandardFont\' size=\'11\' color=\'#c8c8c8\'><b>HUD: </b></font>";

			stateStr += App.hudEnabled
				? "<font face=\'_StandardFont\' size=\'11\' color=\'#00ff00\'><b>Enabled</b></font>"
				: "<font face=\'_StandardFont\' size=\'11\' color=\'#ff3333\'><b>Disabled</b></font>"
			;
			
			stateStr += "<font face=\'_StandardFont\' size=\'11\' color=\'#c8c8c8\'><b>&nbsp;&nbsp;&nbsp;&nbsp;AutoSwap: </b></font>";			
			
			stateStr += App.autoSwapEnabled
				? "<font face=\'_StandardFont\' size=\'11\' color=\'#ffff00\'><b>Enabled</b></font>"
				: "<font face=\'_StandardFont\' size=\'11\' color=\'#ff3333\'><b>Disabled</b></font>"
			;
		}
		
		td.AddAttribute( "", stateStr );
		td.AddAttributeSplitter();
		td.AddAttribute( "", "" );
		
		td.AddAttribute("", "<font face=\'_StandardFont\' size=\'11\' color=\'#BFBFBF\'><b>Left Click</b> Open/Close configuration window.\n<b>Right Click</b> Enable/Disable HUD.\n<b>Shift + Right Click</b> Enable/Disable AutoSwap.</font>");
		
		td.m_Padding = 8;
		td.m_MaxWidth = 256;
		
		
		// create tooltip instance
		tooltip = TooltipManager.GetInstance().ShowTooltip( undefined, TooltipInterface.e_OrientationVertical, 0, td );
		
	}
	
	/*
	 * internal variables
	 */

	public var m_Overlay:MovieClip;
	
	private var tooltip:TooltipInterface;
	private var state:String;

	private var isVtioIcon:Boolean;
	
	/*
	 * properties
	 */

	// the position of the moveable icon
	public function get position() : Point { return new Point( this._x, this._y ); }
	public function set position( value:Point ) : Void {
		this._x = value.x;
		this._y = value.y;
	}

	// the scale of the moveable icon
	public function get scale() : Number { return this._xscale; }
	public function set scale( value:Number ) : Void {
		if ( value != undefined ) {
			this._xscale = this._yscale = value;
		}
	}
	
}