import com.ElTorqiro.AegisHUD.HUD.Bar;
import com.ElTorqiro.AegisHUD.HUD.Slot;
import com.GameInterface.DistributedValue;
import mx.utils.Delegate;

import com.GameInterface.Game.Character;
import com.GameInterface.Tooltip.TooltipInterface;
import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Tooltip.TooltipManager;
import com.GameInterface.Tooltip.TooltipDataProvider;

import mx.transitions.easing.Bounce;

import gfx.core.UIComponent;
import flash.geom.Point;

import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.Server.AegisServer;
//import com.ElTorqiro.AegisHUD.Server.AegisServerSlot;
//import com.ElTorqiro.AegisHUD.HUD.BarSlot;
import com.ElTorqiro.AegisHUD.Const;


/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.HUD extends UIComponent {
	
	public function HUD() {
		
		App.debug( "HUD: HUD class constructor" );

		// start hidden
		visible = false;
		
		timers = { };
		
		// add bars
		bars = {
			primary: attachMovie( "bar", "primary", getNextHighestDepth(), { group: AegisServer.groups["primary"], _x: 100, _y: 200 } ),
			secondary: attachMovie( "bar", "secondary", getNextHighestDepth(), { group: AegisServer.groups["secondary"], _x: 350, _y: 200 } )
		};
		
		for ( var s:String in bars ) {
			for ( var i:String in bars[s].slots ) {
				bars[s].slots[i].watermark = i == "item" ? "watermark-weapon" : "watermark-disruptor";
			}
		}
		
		if ( AegisServer.shieldSystemUnlocked ) {
			bars.shield = attachMovie( "bar", "shield", getNextHighestDepth(), { group: AegisServer.groups["shield"], _x: 600, _y: 200 } );
			
			bars.shield.slots.item.watermark = "watermark-shield";
			bars.shield.slots.aegis1.watermark = "watermark-shield-psychic";
			bars.shield.slots.aegis2.watermark = "watermark-shield-cybernetic";
			bars.shield.slots.aegis3.watermark = "watermark-shield-demonic";
		}
		
		// set up listeners for aegis server slot changes
		AegisServer.SignalItemChanged.Connect( itemChanged, this );
		AegisServer.SignalSelectionChanged.Connect( selectionChanged, this );
		AegisServer.SignalXPChanged.Connect( xpChanged, this );

		// set up listener for ultimate ability progress bar visibility
		animusBarVisibilityMonitor = DistributedValue.Create( "ShowAnimaEnergyBar" );
		animusBarVisibilityMonitor.SignalChanged.Connect( layout, this );
		
		// hook passive bar open/close event
		hookPassiveBarOpenClose( true );
		
		// perform initial layout
		layout();
		
		visible = true;
	}
	
	/**
	 * configure UI (listeners, handlers etc)
	 */
	private function configUI() : Void {
		App.debug( "HUD: HUD class configUI" );
		
		// set up listeners for tooltips on slots
		for ( var s:String in bars ) {
			
			for ( var i:String in bars[s].slots ) {
				
				var slot:Slot = bars[s].slots[i];
					slot.addEventListener( "mouseOver", this, "showSlotTooltip" );
					slot.addEventListener( "mouseOut", this, "closeTooltip" );
			}
		}
		
	}
	
	/**
	 * dispose of resources and perform any object removal tasks
	 */
	public function dispose() : Void {
		
		App.debug( "HUD: HUD class dispose" );
		
		closeTooltip();
		
		// release passivebar open/close event
		hookPassiveBarOpenClose( false );
		
		/**
		 * save settings
		 */
		
		// bar positions
		if ( !App.prefs.getVal( "hud.abilityBarIntegration.enable" ) ) {
			saveBarPositions();
		}
		
	}
	 
	/**
	 * position the bars in either the restored positions or the default
	 */
	private function layout() : Void {
		
		var doLayout:Number = App.prefs.getVal( "hud.layout.type" );
		
		if ( App.prefs.getVal( "hud.abilityBarIntegration.enable" ) ) {
			layoutWithAbilityBar();
		}
		
		else if ( doLayout == Const.e_LayoutDefault ) {
			layoutDefault();
		}

		else if ( doLayout == Const.e_LayoutCustom && !initialLayoutDone ) {
			layoutCustom();
		}

		initialLayoutDone = true;
		
	}
	
	/**
	 * layout the bars integrated with the ability bar
	 */
	private function layoutWithAbilityBar() : Void {

		var pb:MovieClip = _root.passivebar.m_Bar.m_Background;
		
		if ( pb == undefined ) {
			
			// set up initial run of timer
			if ( timers.lwab == undefined ) {
				timers.lwab = { id: setTimeout( Delegate.create( this, layoutWithAbilityBar ), 20 ), start: new Date() };
				App.debug( "lwab timer: starting up, " + timers.lwab.start );
			}
			
			// if timer has expired and still haven't found the element, revert to default behaviour
			else if ( (new Date()) - timers.lwab.start > 2000 ) {
				App.debug( "lwab timer: giving up, " + ((new Date()) - timers.lwab.start) );
				delete timers.lwab;
				layoutDefault();
			}

			// else if timer is running, just restart it
			else {
				App.debug( "lwab timer: restarting timer (tick)" );
				timers.lwab.id = setTimeout( Delegate.create( this, layoutWithAbilityBar ), 20 );
			}
			
			return;
		}

		delete timers.lwab;
		
		// get the centre top of the passivebar background block
		var centre:Point = new Point( pb._x + pb._width / 2, pb._y );
		
		pb._parent.localToGlobal( centre );
		this.globalToLocal( centre );
		
		centre.x = Math.floor( centre.x ) - 5;
		centre.y = Math.floor( centre.y );

		centre.y -= bars[ "primary" ]._height;
		
		// adjust top for animus charge bar
		//if ( animusBarVisibilityMonitor.GetValue() ) {
		if ( _root.passivebar.m_UltimateProgress._visible ) {
			centre.y -= 10;
		}
		
		// test random positioning to check for duplicate clip being left behind during OnModuleDeactivated / Activated spam such as when portaling in Agartha
		/*
		var min:Number = 400;
		var max:Number = 800;
		centre.x = Math.floor(Math.random() * (max - min + 1)) + min;
		centre.y = Math.floor(Math.random() * (max - min + 1)) + min;
		*/
		
		layoutAtPoint( centre, true );
	}

	/**
	 * layout the bars at the default position, without integrating with ability bar
	 */
	private function layoutDefault() : Void {
		
		App.prefs.setVal( "hud.layout.type", Const.e_LayoutDefault );
		
		// find a spot in the centre, near the bottom of the screen
		var centre:Point = new Point( Stage.visibleRect.width / 2, Stage.visibleRect.bottom - 107 );
		
		if ( _root.passivebar.m_UltimateProgress._visible ) {
			centre.y -= 10;
		}

		layoutAtPoint( centre );
		saveBarPositions();
	}

	/**
	 * layout the bars at their restored positions, or suitable temporary defaults on a per-bar basis if they have never been set
	 */
	private function layoutCustom() : Void {
		
		var left:Number = Stage.visibleRect.width / 2 - 200;
		var top:Number = Stage.visibleRect.bottom - 200;
		
		var defaultX:Object = {
			primary: left,
			secondary: left + 140,
			shield: left + 280
		};
		
		for ( var s:String in bars ) {
			
			var pos:Point = App.prefs.getVal( "hud.bars." + s + ".position" );
			if ( pos == undefined ) {
				pos = new Point( defaultX[s], top );
			}
			
			bars[ s ]._x = pos.x;
			bars[ s ]._y = pos.y;
		}
		
		saveBarPositions();
	}
	
	/**
	 * 	layout bars in default configuration around a central point
	 * @param	centre
	 */
	private function layoutAtPoint( centre:Point, animate:Boolean ) : Void {
		
		var tweenTime:Number = initialLayoutDone && animate ? 0.8 : 0;

		var barsX:Object = { };
		
		barsX[ "primary" ] = centre.x - bars[ "primary" ]._width - 3;
		barsX[ "secondary" ] = centre.x + 6;
		
		// adjust for shield bar positioning
		if ( bars[ "shield" ] ) {
			var leftOffset:Number = ( bars[ "shield" ]._width + 18 ) / 2;
			
			barsX[ "primary" ] -= leftOffset;
			barsX[ "secondary" ] -= leftOffset;
			
			barsX[ "shield" ] = barsX[ "secondary" ] + bars[ "secondary" ]._width + 18;
		}

		for ( var s:String in bars ) {
			
			bars[s].tweenTo( tweenTime, {
					_x: barsX[s],
					_y: centre.y
				},
				Bounce.easeOut
			);

		}
		
	}

	/**
	 * saves the positions of all active bars to the prefs
	 */
	private function saveBarPositions() : Void {
			
		for ( var s:String in bars ) {
			App.prefs.setVal( "hud.bars." + s + ".position", new Point( bars[s]._x, bars[s]._y ) );
		}

	}

	/**
	 * opens aegis item tooltip
	 * 
	 * @param	slot
	 */
    private function showSlotTooltip( event:Object ) : Void {

		return;
		
		closeTooltip();
		
		var slot:Slot = event.target;
		
		// don't show anything if no item in slot or tooltip setting is disabled
		if ( !slot.slot.item || !App.prefs.getVal( "hud.tooltips.enabled" ) || ( App.prefs.getVal( "hud.tooltips.suppressInCombat" ) && Character.GetClientCharacter().IsInCombat() ) ) return;

		var tooltipData:TooltipData = TooltipDataProvider.GetInventoryItemTooltip( slot.slot.inventoryID, slot.slot.position );
		
		// add raw xp value
		if ( slot.slot.item.m_AegisItemType ) {
			tooltipData.AddDescription( 'Research Data: <font color="#ffff00">' + slot.slot.xpRaw + '</font>' );
		}
		
		tooltip = TooltipManager.GetInstance().ShowTooltip( slot, TooltipInterface.e_OrientationVertical, -1, tooltipData );
		
    }

	/**
	 * close and destroy any open tooltip
	 */
    private function closeTooltip():Void {

		return;
		
		tooltip.Close();
		tooltip = null;
    }

	/**
	 * hooks into passivebar open/close for moving the hud if it is integrated with passivebar
	 * 
	 * @param	hook
	 */
	private function hookPassiveBarOpenClose( hook:Boolean ) : Void {
		
		var el:Function = _root.passivebar.m_Bar.onTweenComplete;
		
		if ( el == undefined ) {
			
			// set up initial run of timer
			if ( timers.hpboc == undefined ) {
				timers.hpboc = { id: setTimeout( Delegate.create( this, hookPassiveBarOpenClose ), 20 ), start: new Date() };
				App.debug( "hpboc timer: starting up, " + timers.hpboc.start );
			}
			
			// if timer has expired and still haven't found the element, revert to default behaviour
			else if ( (new Date()) - timers.hpboc.start > 2000 ) {
				App.debug( "hpboc timer: giving up, " + ((new Date()) - timers.hpboc.start) );
				delete timers.hpboc;
			}

			// else if timer is running, just restart it
			else {
				App.debug( "hpboc timer: restarting timer (tick)" );
				timers.hpboc.id = setTimeout( Delegate.create( this, hookPassiveBarOpenClose ), 20 );
			}
			
			return;
		}

		delete timers.hbpoc;
		
		var pb = _root.passivebar.m_Bar;
		
		// set up proxies and force HUD into position
		if ( hook && (pb.onTweenComplete_AegisHUD_Saved == undefined) ) {
			
			pb.onTweenComplete_AegisHUD_Saved = pb.onTweenComplete;
			pb.onTweenComplete = undefined;
			pb.onTweenComplete = Delegate.create( this, passiveBarOnTweenCompleteProxy );
		}
		
		// remove proxy and restore original function
		else if( pb.onTweenComplete_AegisHUD_Saved != undefined ) {
			pb.onTweenComplete = pb.onTweenComplete_AegisHUD_Saved;
			pb.onTweenComplete_AegisHUD_Saved = undefined;
		}
	}
	
	/**
	 * proxy function for hooking into the passivebar onTweenComplete function that fires after each open/close
	 */
	private function passiveBarOnTweenCompleteProxy():Void {
		// let the original function run
		_root.passivebar.m_Bar.onTweenComplete_AegisHUD_Saved();
		
		// move bar to position (layout will handle test for prefs etc)
		layout();
	}

	
	
	/**
	 * handles item changes in aegis server slots
	 * 
	 * @param	groupID
	 * @param	slotID
	 */
	private function itemChanged( groupID:String, slotID:String ) : Void {

		var bar:Bar = bars[ groupID ];
		var slot:Slot = bar.slots[ slotID ];

		slot.loadIcon();
		
		if ( slot.slot == slot.group.selectedSlot ) {
			bar.slots[ "item" ].invalidate();
			bar.invalidate();
		}
	}

	/**
	 * handles selection changes in aegis groups
	 * 
	 * @param	groupID
	 * @param	slotID
	 */
	private function selectionChanged( groupID:String, slotID:String, fromSlotID:String ) : Void {
		
		var bar:Bar = bars[ groupID ];
		
		bar.slots[ fromSlotID ].invalidate();
		bar.slots[ slotID ].invalidate();
		bar.slots[ "item" ].invalidate();
		bar.invalidate();
	}
	
	/**
	 * handles xp changing in an aegis slot
	 * 
	 * @param	groupid
	 * @param	slotid
	 */
	private function xpChanged( groupID:String, slotID:String ) : Void {
		bars[ groupID ].slots[ slotID ].loadXP();
	}

	/*
	 * internal variables
	 */
	
	private var bars:Object;
	private var tooltip:TooltipInterface;
	
	private var timers:Object;

	private var animusBarVisibilityMonitor:DistributedValue;
	
	private var initialLayoutDone:Boolean;
	
	/*
	 * properties
	 */
	
}