import mx.utils.Delegate;

import com.GameInterface.Game.Character;
import com.GameInterface.Tooltip.TooltipInterface;
import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Tooltip.TooltipManager;
import com.GameInterface.Tooltip.TooltipDataProvider;

import mx.transitions.easing.None;

import gfx.core.UIComponent;
import flash.geom.Point;

import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.Server.AegisServerSlot;
import com.ElTorqiro.AegisHUD.HUD.BarSlot;
import com.ElTorqiro.AegisHUD.Enums;
import com.ElTorqiro.AegisHUD.Preferences;

import com.GameInterface.UtilsBase;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.HUD extends UIComponent {
	
	public function HUD() {
		
		App.debug( "hud constructor" );

		// start hidden
		visible = false;
		
		player = Character.GetClientCharacter();
		player.SignalToggleCombat.Connect( autoHide, this );

		uiElementFinder = { };
		
		// autohide handlers
		Preferences.addEventListener( "autoSwap.enabled", this, "autoHide" );
		Preferences.addEventListener( "ui.hide.whenAutoswapEnabled", this, "autoHide" );
		Preferences.addEventListener( "ui.hide.whenNotInCombat", this, "autoHide" );
		autoHide();
		
		// create bars
		bars = {
			primary: attachMovie( "com.ElTorqiro.AegisHUD.HUD.Bar", "primary", getNextHighestDepth(), { groupID: "primary" } ),
			secondary: attachMovie( "com.ElTorqiro.AegisHUD.HUD.Bar", "secondary", getNextHighestDepth(), { groupID: "secondary" } )
		};
		
		for ( var s:String in bars ) {
			bars[s].m_Item.watermark = "weapon-watermark";
			bars[s].m_Aegis1.watermark = "disruptor-watermark";
			bars[s].m_Aegis2.watermark = "disruptor-watermark";
			bars[s].m_Aegis3.watermark = "disruptor-watermark";
		}
		
		if ( AegisServer.shieldSystemUnlocked ) {
			bars.shield = attachMovie( "com.ElTorqiro.AegisHUD.HUD.Bar", "shield", getNextHighestDepth(), { groupID: "shield" } );

			bars.shield.m_Item.staticIcon = "shield-logo";
			bars.shield.m_Aegis1.watermark = "shield-watermark-psychic";
			bars.shield.m_Aegis2.watermark = "shield-watermark-cybernetic";
			bars.shield.m_Aegis3.watermark = "shield-watermark-demonic";
		}
		
		// wire up aegis server event listeners
		AegisServer.SignalSelectionChanged.Connect( selectionChanged, this );
		AegisServer.SignalXPChanged.Connect( slotXPChanged, this );
		AegisServer.SignalItemChanged.Connect( slotItemChanged, this );

		// pref handlers
		Preferences.addEventListener( "ui.hud.scale", this, "hudScalePrefHandler" );
		hudScalePrefHandler();
		
		// position bars on screen
		restorePositions();
		
		App.debug( "hud constructor end" );
	}
	
	/**
	 * configure UI (listeners, handlers etc)
	 */
	private function configUI() : Void {

		//UtilsBase.PrintChatText("hud configui");
		
		var slotNames:Array = [ "item" ];
		for ( var i:Number = 1; i <= Enums.e_AegisSlotsPerGroup; i++ ) {
			slotNames.push( "aegis" + i );
		}
		
		// wire up aegis slot mouse handlers
		for ( var s:String in bars ) {
			var bar = bars[s];
			for ( var i:String in bar.slots ) {
				var slot = bar.slots[i];
				slot.addEventListener( "click", this, "slotClickHandler" );
				slot.addEventListener( "mouseOver", this, "slotMouseOverHandler" );
				slot.addEventListener( "mouseOut", this, "slotMouseOutHandler" );
			}
		}
		
		// set initial selections
		for ( var s:String in bars ) {
			selectionChanged( s, AegisServer.getSelectedSlotID(s) );
		}
		
	}
	
	/**
	 * lays out bar internals and position
	 */
	public function layout() : Void {

		// if integrating with ability bar, position directly above passivebar placement
		if ( Preferences.getValue( "ui.integrateWithAbilityBar" ) ) {
			
		}
		
	}

	/**
	 * restores bar positions from saved values
	 */
	private function restorePositions() : Void {
		// position bars
		for ( var s:String in bars ) {
			var position:Point = Preferences.getValue( "ui.bars." + s + ".position" );
			
			// restore position if possible
			if ( position ) {
				bars[s]._x = position.x;
				bars[s]._y = position.y;
			}
			
			else {
				// set default position for this bar
				applyDefaultPosition( s );
			}
		}
	}
	
	/**
	 * moves bars to default position
	 * 
	 * @param	forceAnimate
	 */
	public function applyDefaultPosition( barName:String )  : Void {

		var totalWidth:Number = bars.primary._width + 6 + bars.secondary._width + ( bars.shield ? 18 + bars.shield._width : 0 );
		var centre:Number = Stage.visibleRect.width / 2;
		var left:Number = centre - totalWidth / 2;
		var top:Number = Stage.visibleRect.height - 105; // - 75 - bars.primary._height + 1);
		
		switch ( barName ) {
			case "primary":
				bars.primary._x = left;
				bars.primary._y = top;
			break;
			
			case "secondary":
				bars.secondary._x = left + bars.primary._width + 6;
				bars.secondary._y = top;
			break;
			
			case "shield":
				bars.shield._x = left + bars.primary._width + 6 + bars.secondary._width + 18;
				bars.shield._y = top;
			break;
		}
		
	}

	/**
	 * integrates HUD with ability bar
	 * 
	 * @param	integrate
	 */
	private function integrateWithAbilityBar( integrate:Boolean ):Void {

		var pb = _root.passivebar.m_Bar;
		
		// if removing integration, assume it can be found immmediately
		if ( !integrate ) {
			if( pb.onTweenComplete_AegisHUD_Saved != undefined ) {
				pb.onTweenComplete = pb.onTweenComplete_AegisHUD_Saved;
				pb.onTweenComplete_AegisHUD_Saved = undefined;
			}
		}

		// if integrating, find bar class instance and hijack function
		else {
			// make sure not to "re-attach" if already attached
			if( pb.onTweenComplete_AegisHUD_Saved == undefined ) {
				pb.onTweenComplete_AegisHUD_Saved = pb.onTweenComplete;
				// break the link
				pb.onTweenComplete = undefined;
				pb.onTweenComplete = Delegate.create(this, passiveBarOnTweenCompleteProxy);
				
				moveToPassiveBar( false );
			}
		}
		
	}
	
	/**
	 * proxy function for hooking into the passivebar onTweenComplete listener that fires after each open/close
	 * this is used for moving the hud when the passivebar opens/closes, if the integrate option is set
	 */
	private function passiveBarOnTweenCompleteProxy():Void {
		// let the original function run
		_root.passivebar.m_Bar.onTweenComplete_AegisHUD_Saved();
		moveToPassiveBar();
	}
	
	/**
	 * lays out bars in default layout, starting at the desired coordinates
	 * 
	 * @param	top
	 * @param	left
	 */
	private function defaultLayout( top:Number, left:Number ) : Void {
		
	}
	
	/**
	 * moves hud to passivebar position, to simulate integration
	 * 
	 * @param	forceAnimate
	 */
	private function moveToPassiveBar( forceAnimate:Boolean ) : Void {
		
		var tweenTime:Number = (forceAnimate == undefined || forceAnimate == true) ? 0.3 : 0;
		
		var pb = _root.passivebar.m_Bar;
		/*
		var targetY:Number = _root.passivebar.m_UltimateProgress._visible ? _root.passivebar.m_UltimateProgress._y + 2 : _root.passivebar.m_Bar._y;
		
		var pbx:Number = pb.m_BaseWidth / 2 + pb.m_Button._x; // - 4;
		var pby:Number = targetY; // pb.m_Bar._y; // - 5;
		
		var globalPassiveBarPos:Point = new Point( pbx, pby );
		pb.localToGlobal( globalPassiveBarPos );
		this.globalToLocal( globalPassiveBarPos );

		var primaryDefaultPosition = new Point( globalPassiveBarPos.x - m_Primary._width - 3 - 9 - m_Shield._width / 2, globalPassiveBarPos.y - m_Primary._height - 3 );
		var secondaryDefaultPosition = new Point( primaryDefaultPosition.x + m_Primary._width + 6, primaryDefaultPosition.y );
		
		var shieldDefaultPosition = new Point( secondaryDefaultPosition.x + m_Secondary._width + 18, primaryDefaultPosition.y );
		
		// apply default layout of bars relative to each other
		defaultLayout();
		
		// move bars to passivebar position
		
		
		if( userTriggered && animateMovementsToDefaultPosition ) {
		
			m_Primary.tweenTo(1, {
					_x: primaryDefaultPosition.x,
					_y: primaryDefaultPosition.y
				},
				Bounce.easeOut
			);
			
			m_Secondary.tweenTo(1, {
					_x: secondaryDefaultPosition.x,
					_y: secondaryDefaultPosition.y
				},
				Bounce.easeOut
			);
			
			m_Shield.tweenTo(1, {
					_x: shieldDefaultPosition.x,
					_y: shieldDefaultPosition.y
				},
				Bounce.easeOut
			);
		*/
	}
	
	/**
	 * handles an aegis button being clicked
	 */
	private function slotClickHandler( e:Object ) : Void {
		closeTooltip();
		
		AegisServer.selectSlot( e.target.groupID, e.target.slotID );
		
		// if a dual-related click, dual select
		var dual:Boolean = 
			( e.button == 0 && e.shift && Preferences.getValue("ui.select.shiftLeftButton") == Enums.e_SelectionDual ) ||
			( e.button == 0 && !e.shift && Preferences.getValue("ui.select.leftButton") == Enums.e_SelectionDual ) ||
			( e.button == 1 && Preferences.getValue("ui.select.rightButton") == Enums.e_SelectionDual )
		;
		
		if ( dual ) {
			var slot:AegisServerSlot = AegisServer.getSlot( e.target.groupID, e.target.slotID );
			
			if ( slot.pairGroupID ) {
				AegisServer.selectSlot( slot.pairGroupID, e.target.slotID );
			}
		}
	}
	
	/**
	 * handles mouse hovering over a slot
	 * 
	 * @param	e
	 */
	private function slotMouseOverHandler( e:Object ) : Void {
		openTooltip( e.target );
	}
	
	/**
	 * handles mouse leaving a slot
	 * 
	 * @param	e
	 */
	private function slotMouseOutHandler( e:Object ) : Void {
		closeTooltip();
	}
	
	/**
	 * handles selected aegis slot changing
	 * 
	 * @param	groupID
	 * @param	slotID
	 */
	private function selectionChanged( groupID:String, slotID:String ) : Void {
		
		var bar:Object = bars[groupID].updateSelection();
		
		/*
		bar.redraw();
		
		for ( var s:String in bar.slots ) {
			bar.slots[s].selected = s == slotID;
		}
		*/
	}

	/**
	 * handles xp changing on an aegis slot
	 * 
	 * @param	groupID
	 * @param	slotID
	 */
	private function slotXPChanged( groupID:String, slotID:String ) : Void {
		bars[groupID].slots[slotID].refreshXP();
	}
	
	/**
	 * handles item in a slot changing
	 * 
	 * @param	groupID
	 * @param	slotID
	 */
	private function slotItemChanged( groupID:String, slotID:String ) : Void {
		bars[groupID].slots[slotID].refreshItem();
		
		if ( bars[groupID].aegisSlots[slotID].selected ) bars[groupID].redraw();
	}

	/**
	 * opens the item tooltip for a bar slot
	 * 
	 * @param	barSlot
	 */
    private function openTooltip( barSlot:BarSlot ) : Void {
		// close any existing tooltip
		closeTooltip();

		var slot:AegisServerSlot = AegisServer.getSlot( barSlot.groupID, barSlot.slotID );
		if ( !slot.item ) return;
		
		// don't show anything if setting disabled OR if the hud elements are currently being dragged
		//if ( !showTooltips || _dragging || (suppressTooltipsInCombat && _character.IsInCombat()) || slot.item == undefined ) return;

		var tooltipData:TooltipData = TooltipDataProvider.GetInventoryItemTooltip( slot.inventoryID, slot.position );
		
		// add raw xp value
		//tooltipData.AddAttributeSplitter();
		if ( slot.item.m_AegisItemType ) {
			tooltipData.AddDescription( 'AEGIS Item ID: <font color="#ffff00">' + slot.item.m_AegisItemType + '</font>, XP: <font color="#ffff00">' + slot.xp + '</font>' );
		}
		
		tooltip = TooltipManager.GetInstance().ShowTooltip( barSlot, TooltipInterface.e_OrientationVertical, -1, tooltipData );
    }
    
	/**
	 * closes any currently open tooltip
	 */
    private function closeTooltip():Void {
		tooltip.Close();
		tooltip = null;
    }

	/**
	 * runs functions against all bars and/or all slots
	 * 
	 * @param	barFn
	 * @param	slotFn
	 */
	private function all( barFn:Object, slotFn:Object ) : Void {
		
	}
	
	/**
	 * handle autohide of the hud based on preferences and conditions
	 */
	private function autoHide() : Void {
		
		var hide:Boolean = 
			( Preferences.getValue("autoSwap.enabled") && Preferences.getValue("ui.hide.whenAutoswapEnabled") ) ||
			( Preferences.getValue("ui.hide.whenNotInCombat") && !player.IsThreatened() )
		;
		
		this["tweenTo"]( 0.1, { _alpha: hide ? 0 : 100 }, None.easeNone );

		if ( !hide ) visible = true;
		else closeTooltip();
	}
	
	/**
	 * called when tween animation ends
	 */
	private function onTweenComplete() : Void {
		visible = _alpha > 0;
	}
	
	private function hudScalePrefHandler( e:Object ) : Void {
		
		var scale:Number = Preferences.getValue( "ui.hud.scale" );
		
		for ( var s:String in bars ) {
			bars[s]._xscale = bars[s]._yscale = scale;
		}
		
		if ( Preferences.getValue( "ui.integrateWithAbilityBar" ) ) {
			layout();
		}
	}
	
	/**
	 * movieclip unload event handler
	 */
	public function onUnload() : Void {
		super.onUnload();
		
		// save bar positions
		Preferences.setValue( "ui.bars.primary.position", new Point( bars.primary._x, bars.primary._y ) );
		Preferences.setValue( "ui.bars.secondary.position", new Point( bars.secondary._x, bars.secondary._y ) );
		
		if ( bars.shield ) {
			Preferences.setValue( "ui.bars.shield.position", new Point( bars.shield._x, bars.shield._y ) );
		}		
		
		dispose();
	}
	
	/**
	 * cleans up any resources and references held by this object
	 */
	public function dispose() : Void {

		closeTooltip();

		Preferences.removeEventListener( "autoSwap.enabled", this, "autoHide" );		
		Preferences.removeEventListener( "ui.hide.whenAutoswapEnabled", this, "autoHide" );
		Preferences.removeEventListener( "ui.hide.whenNotInCombat", this, "autoHide" );

		Preferences.removeEventListener( "ui.hud.scale", this, "hudScalePrefHandler" );
		
		player.SignalToggleCombat.Disconnect( autoHide, this );
		player = null;
		
		// unwire aegis server event listeners
		AegisServer.SignalSelectionChanged.Connect( selectionChanged, this );
		AegisServer.SignalXPChanged.Connect( slotXPChanged, this );
		AegisServer.SignalItemChanged.Connect( slotItemChanged, this );
		
	}
	
	/*
	 * internal variables
	 */
	
	private var bars:Object;
	private var tooltip:TooltipInterface;
	
	private var player:Character;
	
	private var uiElementFinder:Object;

	/*
	 * properties
	 */
	
}