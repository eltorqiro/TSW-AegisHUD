import com.ElTorqiro.AegisHUD.HUD.Bar;
import com.ElTorqiro.AegisHUD.HUD.Slot;
import com.GameInterface.DistributedValue;
import mx.utils.Delegate;

import com.GameInterface.Game.Character;
import com.GameInterface.Tooltip.TooltipInterface;
import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Tooltip.TooltipManager;
import com.GameInterface.Tooltip.TooltipDataProvider;

import flash.geom.ColorTransform;

import gfx.core.UIComponent;
import flash.geom.Point;

import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.Server.AegisServer;
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
			primary: attachMovie( "bar", "primary", getNextHighestDepth(), { group: AegisServer.groups["primary"] } ),
			secondary: attachMovie( "bar", "secondary", getNextHighestDepth(), { group: AegisServer.groups["secondary"] } )
		};
		
		for ( var s:String in bars ) {
			for ( var i:String in bars[s].slots ) {
				bars[s].slots[i].watermark = i == "item" ? "watermark-weapon" : "watermark-disruptor";
			}
		}
		
		if ( AegisServer.shieldSystemUnlocked ) {
			bars.shield = attachMovie( "bar", "shield", getNextHighestDepth(), { group: AegisServer.groups["shield"] } );
			
			bars.shield.slots.item.watermark = "watermark-shield";
			bars.shield.slots.aegis1.watermark = "watermark-shield-psychic";
			bars.shield.slots.aegis2.watermark = "watermark-shield-cybernetic";
			bars.shield.slots.aegis3.watermark = "watermark-shield-demonic";
		}
		
	}
	
	/**
	 * dispose of resources and perform any object removal tasks
	 */
	public function dispose() : Void {
		
		App.debug( "HUD: HUD class dispose" );
		
		// release passivebar open/close event
		hookPassiveBarOpenClose( false );
		
		// clear any timers
		for ( var s:String in timers ) {
			clearTimeout( timers[s].id );
		}

		// save bar positions
		saveBarPositions();
		
	}
	
	/**
	 * configure sub components, listeners etc
	 */
	private function configUI() : Void {
		
		// listeners for bar layouts
		for ( var s:String in bars ) {
			bars[s].addEventListener( "layout", this, "layout" );
			bars[s].SignalSizeChanged.Connect( layout, this );
		}

		// perform initial layout
		initLayout();
		
		// set up listeners for aegis server slot changes
		AegisServer.SignalItemChanged.Connect( itemChanged, this );
		AegisServer.SignalSelectionChanged.Connect( selectionChanged, this );
		AegisServer.SignalXPChanged.Connect( xpChanged, this );

		// set up listener for ultimate ability progress bar visibility
		animusBarVisibilityMonitor = DistributedValue.Create( "ShowAnimaEnergyBar" );
		animusBarVisibilityMonitor.SignalChanged.Connect( layout, this );
		
		// hook passive bar open/close event
		hookPassiveBarOpenClose( true );
		
		// set up listener for combat state changes
		Character.GetClientCharacter().SignalToggleCombat.Connect( manageVisibility, this );
		
		// listen for pref changes
		App.prefs.SignalValueChanged.Connect( prefChangeHandler, this );
		
		// set initial visible state
		manageVisibility();
		
		// listen for ability bar movement
		abilityBarXMonitor = DistributedValue.Create( "AbilityBarX" );
		abilityBarXMonitor.SignalChanged.Connect( layout, this );

		abilityBarYMonitor = DistributedValue.Create( "AbilityBarY" );
		abilityBarYMonitor.SignalChanged.Connect( layout, this );

		abilityBarScaleMonitor = DistributedValue.Create( "AbilityBarScale" );
		abilityBarScaleMonitor.SignalChanged.Connect( layout, this );

	}
	
	/**
	 * draw the hud bars in their correct positions
	 */
	private function draw() : Void {
		
		if ( layoutIsInvalid ) {

			if ( App.prefs.getVal( "hud.abilityBarIntegration.enable" ) ) {
				layoutWithAbilityBar();			
			}
			
		}
		
	}

	public function validateNow() : Void {
		super.validateNow();
		
		layoutIsInvalid = false;
	}

	/**
	 * trigger hud to layout the bars during next draw
	 */
	private function layout() : Void {
		layoutIsInvalid = true;
		invalidate();
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
				
				if ( !initialLayoutDone ) {
					initialLayoutDone = true;
					manageVisibility();
				}

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
		
		centre.x = Math.floor( centre.x ) - 3;
		centre.y = Math.floor( centre.y );

		centre.y -= bars[ "primary" ].height + 3;
		
		// adjust top for animus charge bar
		//if ( animusBarVisibilityMonitor.GetValue() ) {
		if ( _root.passivebar.m_UltimateProgress._visible ) {
			centre.y -= 10;
		}
		
		layoutAtPoint( centre, true );
		
		if ( !initialLayoutDone ) {
			initialLayoutDone = true;
			manageVisibility();
		}
	}

	/**
	 * layout the bars at their restored positions, or suitable temporary defaults on a per-bar basis if they have never been set
	 */
	private function initLayout() : Void {

		// set to starting defaults
		layoutAtPoint( new Point( Stage.visibleRect.width / 2, Stage.visibleRect.bottom - 200 ) );

		// only need to restore positions if ability bar integration isn't on as the bars will trigger a relayout of the hud when they layout internally
		if ( !App.prefs.getVal( "hud.abilityBarIntegration.enable" ) ) {
		
			// restore positions from saved values
			for ( var s:String in bars ) {
				
				var pos:Point = App.prefs.getVal( "hud.bars." + s + ".position" );
				if ( pos ) {
					bars[s].move( pos );
				}
				
			}
		
			initialLayoutDone = true;
			manageVisibility();
			
		}
		
		
		/*
		if ( App.prefs.getVal( "hud.abilityBarIntegration.enable" ) ) {
			layout();
			return;
		}
		
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
			
			bars[s].move( pos );
			
		}
		*/

	}
	
	/**
	 * 	layout bars in default configuration around a central point
	 * @param	centre
	 */
	private function layoutAtPoint( centre:Point, animate:Boolean ) : Void {
		
		var tweenTime:Number = initialLayoutDone && animate ? 0.2 : 0;

		var padding:Number = 10;
		
		var offsets:Object = { };
		
		var totalWidth:Number = 0;
		offsets[ "primary" ] = totalWidth;
		
		totalWidth += bars[ "primary" ].width + padding;
		offsets[ "secondary" ] = totalWidth;

		totalWidth += bars[ "secondary" ].width;
		
		if ( bars[ "shield" ] ) {
			totalWidth += padding * 2;
			offsets[ "shield" ] = totalWidth;
			
			totalWidth += bars[ "shield" ].width;
		}

		var left:Number = centre.x - totalWidth / 2;
		
		for ( var s:String in bars ) {
			bars[s].move( new Point( left + offsets[s], centre.y ), tweenTime );
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

	/**
	 * handles visibility of HUD per preferences when prefs or state
	 */
	private function manageVisibility() : Void {
		visible = initialLayoutDone && ( App.prefs.getVal( "hud.hide.whenNotInCombat" ) ? Character.GetClientCharacter().IsThreatened() : true );
	}
	
	/**
	 * handles updates based on pref changes
	 * 
	 * @param	pref
	 * @param	newValue
	 * @param	oldValue
	 */
	private function prefChangeHandler( pref:String, newValue, oldValue ) : Void {
		
		switch ( pref ) {
			
			case "hud.hide.whenNotInCombat":
				manageVisibility();
			break;

			case "hud.abilityBarIntegration.enable":
				if( newValue ) {
					layout();
				}

			break;
			
			case "hud.bars.primary.itemSlotPlacement":
			case "hud.bars.secondary.itemSlotPlacement":
			case "hud.bars.shield.itemSlotPlacement":
			case "hud.bar.background.type":
			/*
				for ( var s:String in bars ) {
					bars[s].layout();
				}
				
				layout();
			*/	
			break;
			
			case "hud.scale":
			/*
				for ( var s:String in bars ) {
					bars[s].scale = newValue;
				}

				layout();
			*/
			break;
			
		}
		
	}
	
	/**
	 * Colorize movieclip using color multiply method rather than flat color
	 * 
	 * Courtesy of user "bummzack" at http://gamedev.stackexchange.com/a/51087
	 * 
	 * @param	object The object to colorizee
	 * @param	color Color to apply
	 */	
	public static function colorize( object:MovieClip, color:Number) : Void {
		// get individual color components 0-1 range
		var r:Number = ((color >> 16) & 0xff) / 255;
		var g:Number = ((color >> 8) & 0xff) / 255;
		var b:Number = ((color) & 0xff) / 255;

		// get the color transform and update its color multipliers
		var ct:ColorTransform = object.transform.colorTransform;
		ct.redMultiplier = r;
		ct.greenMultiplier = g;
		ct.blueMultiplier = b;

		// assign transform back to sprite/movieclip
		object.transform.colorTransform = ct;
	}	
	
	/*
	 * internal variables
	 */
	
	private var bars:Object;
	private var tooltip:TooltipInterface;
	
	private var timers:Object;

	private var animusBarVisibilityMonitor:DistributedValue;
	
	private var initialLayoutDone:Boolean;
	
	private var abilityBarXMonitor:DistributedValue;
	private var abilityBarYMonitor:DistributedValue;
	private var abilityBarScaleMonitor:DistributedValue;

	private var layoutIsInvalid:Boolean;
	
	/*
	 * properties
	 */
	
}