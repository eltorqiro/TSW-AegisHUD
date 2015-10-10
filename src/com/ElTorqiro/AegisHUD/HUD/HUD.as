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

import com.Utils.GlobalSignal;

import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.Server.AegisServer;
import com.ElTorqiro.AegisHUD.Const;
import com.ElTorqiro.AegisHUD.AddonUtils.CommonUtils;
import com.ElTorqiro.AegisHUD.HUD.Bar;
import com.ElTorqiro.AegisHUD.HUD.Slot;
import com.ElTorqiro.AegisHUD.AddonUtils.MovieClipHelper;
import com.ElTorqiro.AegisHUD.AddonUtils.GuiEditMode.GemController;


/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.HUD extends UIComponent {
	
	public static var __className:String = "com.ElTorqiro.AegisHUD.HUD.HUD";
	
	public function HUD() {
		
		App.debug( "HUD: HUD class constructor" );

	}
	
	/**
	 * dispose of resources and perform any object removal tasks
	 */
	public function dispose() : Void {
		
		App.debug( "HUD: HUD class dispose" );
		
		// release passivebar hook
		injectPassiveBarProxy( false );
		
		// save bar positions
		saveBarPositions();
		
	}
	
	/**
	 * configure sub components, listeners etc
	 */
	private function configUI() : Void {

		// set up listeners for aegis server slot changes
		AegisServer.SignalItemChanged.Connect( itemChanged, this );
		AegisServer.SignalSelectionChanged.Connect( selectionChanged, this );
		AegisServer.SignalXPChanged.Connect( xpChanged, this );
		
		// add bars
		AegisServer.SignalAegisSystemUnlocked.Connect( createBars, this );
		AegisServer.SignalShieldSystemUnlocked.Connect( createBars, this );
		createBars();
		
		// set up listener for ultimate ability progress bar visibility
		animusBarVisibilityMonitor = DistributedValue.Create( "ShowAnimaEnergyBar" );
		animusBarVisibilityMonitor.SignalChanged.Connect( layout, this );
		
		// listen for pref changes
		App.prefs.SignalValueChanged.Connect( prefChangeHandler, this );
		
		// listen for ability bar movement
		abilityBarGeometryMonitors = {
			x: "AbilityBarX", y: "AbilityBarY", scale: "AbilityBarScale"
		};
		
		for ( var s:String in abilityBarGeometryMonitors ) {
			abilityBarGeometryMonitors[s] = DistributedValue.Create( abilityBarGeometryMonitors[s] );
			abilityBarGeometryMonitors[s].SignalChanged.Connect( layout, this );
		}
		
		// gui edit mode listener
		GlobalSignal.SignalSetGUIEditMode.Connect( manageGuiEditMode, this );

	}
	
	/**
	 * draw the hud bars in their correct positions
	 */
	private function draw() : Void {
		
		if ( layoutIsInvalid ) {
			if ( App.prefs.getVal( "hud.position.default" ) ) {
				moveToDefaultPosition();			
			}
			
		}
		
	}

	public function validateNow() : Void {
		super.validateNow();
		
		layoutIsInvalid = false;
	}

	/**
	 * creates whatever bars are needed according to which parts of the Aegis system are unlocked
	 */
	private function createBars() : Void {
	
		// primary and secondary disruptor bars
		if ( AegisServer.aegisSystemUnlocked && !bars.primary ) {
			
			App.debug( "HUD: creating disruptor bars" );
			
			bars = { };
			
			bars.primary = MovieClipHelper.attachMovieWithClass( "bar", Bar, "primary", this, getNextHighestDepth(), { group: AegisServer.groups["primary"] } );
			bars.secondary = MovieClipHelper.attachMovieWithClass( "bar", Bar, "secondary", this, getNextHighestDepth(), { group: AegisServer.groups["secondary"] } );
			
			for ( var s:String in bars ) {
				for ( var i:String in bars[s].slots ) {
					bars[s].slots[i].watermark = i == "item" ? "watermark-weapon" : "watermark-disruptor";
					bars[s].SignalSizeChanged.Connect( layout, this );
				}
			}

		}
		
		// shield bar
		if ( AegisServer.shieldSystemUnlocked && !bars.shield ) {

			App.debug( "HUD: creating shield bar" );
			
			bars.shield = MovieClipHelper.attachMovieWithClass( "bar", Bar, "shield", this, getNextHighestDepth(), { group: AegisServer.groups["shield"] } );
			
			bars.shield.slots.item.watermark = "watermark-shield";
			bars.shield.slots.aegis1.watermark = "watermark-shield-psychic";
			bars.shield.slots.aegis2.watermark = "watermark-shield-cybernetic";
			bars.shield.slots.aegis3.watermark = "watermark-shield-demonic";
			
			bars.shield.SignalSizeChanged.Connect( layout, this );
			
		}
		
		// establish default positions
		var positions:Object = getScreenDefaultPositions();
		
		// override default positions with restored positions if possible
		for ( var s:String in positions ) {
			
			var pos:Point = App.prefs.getVal( "hud.bars." + s + ".position" );
			App.debug(" restoring " + s + " = " + pos );
			if ( pos == undefined ) {
				pos = positions[s];
			}
			
			bars[s].move( pos );
		}
		
		// set a value for bar position restoration
		saveBarPositions();
	
	}
	
	/**
	 * trigger hud to layout the bars during next draw
	 */
	private function layout() : Void {
		// check for module being active to avoid the crazy positioning resets that happen during the deactivation/activation phases when teleporting etc
		if ( App.active ) {
			layoutIsInvalid = true;
			invalidate();
		}
	}
	
	/**
	 * position bars in default layout, and in default position
	 */
	private function moveToDefaultPosition() : Void {

		App.debug( "HUD: moveToDefaultPosition" );
		
		var positions:Object;
		
		if ( passiveBarAvailable ) {

			var pb:MovieClip = _root.passivebar.m_Bar.m_Background;
			
			// get the centre top of the passivebar background block
			var centre:Point = new Point( pb._x + pb._width / 2, pb._y );
			
			pb._parent.localToGlobal( centre );
			this.globalToLocal( centre );
			
			centre.x = Math.floor( centre.x ) - 3;
			centre.y = Math.floor( centre.y );

			centre.y -= bars[ "primary" ].height + 3;
			
			// adjust top for animus charge bar
			var animusBarPresent:Boolean = animusBarVisibilityMonitor.GetValue();
			if ( animusBarPresent == undefined || animusBarPresent  ) {
				centre.y -= 10;
			}
			
			// if the centre is off screen, revert to screen default
			if ( centre.x < 0 || centre.x > Stage.visibleRect.width || centre.y < 0 || centre.y > Stage.visibleRect - 5 ) {
				positions = getScreenDefaultPositions();
			}
			
			else {
				positions = layoutAtPoint( centre );
			}
		}
		
		// no passivebar, assume screen default positions
		else {
			positions = getScreenDefaultPositions();
		}
		
		// move bars to position
		for ( var s:String in positions ) {
			bars[s].move( positions[s], 0.2 );
		}

	}

	/**
	 * calculates default screen position for each bar
	 * 
	 * @return	an object containing Point instances, one for each named bar
	 */
	private function getScreenDefaultPositions() : Object {
		
		return layoutAtPoint( new Point( Stage.visibleRect.width / 2, Stage.visibleRect.height - 130 ) ); 
	}
	
	/**
	 * generates a default layout for the bars, based around a central point
	 * 
	 * @param	centre
	 * 
	 * @return	an object containing Point instances, named for each bar
	 */
	private function layoutAtPoint( centre:Point ) : Object {
		
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
		
		left = Math.max( left, 0 );
		left = Math.min( left, Stage.visibleRect.width - totalWidth );
		
		centre.y = Math.max( centre.y, 0 );
		centre.y = Math.min( centre.y, Stage.visibleRect.height - 5 );
		
		// create result positions
		var positions:Object = { };
		
		for ( var s:String in bars ) {
			positions[s] = new Point( left + offsets[s], centre.y );
		}
		
		return positions;
	}

	/**
	 * manages the GUI Edit Mode state
	 * 
	 * @param	edit
	 */
	public function manageGuiEditMode( edit:Boolean ) : Void {
	
		if ( edit ) {
			if ( !gemController ) {
				
				var targets:Array = [];
				for ( var s:String in bars ) {
					targets.push( bars[s] );
				}
				
				gemController = GemController.create( "m_GuiEditModeController", _parent, _parent.getNextHighestDepth(), targets );
				gemController.addEventListener( "scrollWheel", this, "gemScrollWheelHandler" );
				gemController.addEventListener( "endDrag", this, "gemEndDragHandler" );
			}
		}
		
		else {
			gemController.removeMovieClip();
			gemController = null;
		}
		
	}

	private function gemScrollWheelHandler( event:Object ) : Void {
		
		App.prefs.setVal( "hud.scale", App.prefs.getVal( "hud.scale" ) + event.delta * 5 );
	}
	
	private function gemEndDragHandler( event:Object ) : Void {
		
		App.prefs.setVal( "hud.position.default", false );
		
		saveBarPositions();
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
	 * run each time module is activated to try to find default passivebar, and integrate with it
	 */
	private function hookPassiveBar( findThingId:String, thing, found:Boolean ) : Void {
		
		// is a thing finder callback
		if ( findThingId ) {
			App.debug( "HUD: hookPassiveBar: found = " + found );
			
			passiveBarAvailable = found;
			
			// things that need to happen once we know if passivebar is available or not
			injectPassiveBarProxy( true );
			layout();
		}
		
		// not a callback, start finding the thing
		else {
			passiveBarAvailable = false;
			
			var callback:Function = Delegate.create( this, hookPassiveBar );
			CommonUtils.findThing( "passiveBarExists", "_root.passivebar.m_Bar.onTweenComplete", 20, 4000, callback, callback );
		}
		
	}

	/**
	 * hooks into passivebar open/close for moving the hud if it is integrated with passivebar
	 * 
	 * @param	enable
	 */
	private function injectPassiveBarProxy( enable:Boolean ) : Void {

		var pb = _root.passivebar.m_Bar;
		
		// set up proxy for open/close
		if ( enable && (pb.onTweenComplete_AegisHUD_Saved == undefined) ) {
			
			pb.onTweenComplete_AegisHUD_Saved = pb.onTweenComplete;
			pb.onTweenComplete = undefined;
			pb.onTweenComplete = Delegate.create( this, passiveBarOnTweenCompleteProxy );
		}
		
		// remove proxy and restore original function
		else if ( pb.onTweenComplete_AegisHUD_Saved != undefined ) {
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
		
		// move bar to position
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
	 * handles updates based on pref changes
	 * 
	 * @param	pref
	 * @param	newValue
	 * @param	oldValue
	 */
	private function prefChangeHandler( pref:String, newValue, oldValue ) : Void {
		
		switch ( pref ) {
			
			case "hud.position.default":
				if ( newValue ) layout();
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
	 * triggered by the app when the module is activated, so things like passivebar integration can work
	 */
	public function activate() : Void {
		hookPassiveBar();
	}
	
	public function deactivate() : Void {
		// stop finder looking for passivebar
		CommonUtils.cancelFindThing( "passiveBarExists" );
	}
	
	/*
	 * internal variables
	 */
	
	private var bars:Object;
	private var tooltip:TooltipInterface;
	
	public var gemController:GemController;

	private var passiveBarAvailable:Boolean;
	
	private var animusBarVisibilityMonitor:DistributedValue;
	
	private var abilityBarGeometryMonitors:Object;

	private var layoutIsInvalid:Boolean;
	
	/*
	 * properties
	 */

}