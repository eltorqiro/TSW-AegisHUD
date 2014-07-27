import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import gfx.core.UIComponent;
import com.ElTorqiro.AddonUtils.AddonUtils;
import com.GameInterface.InventoryItem;
import com.Utils.ID32;
import mx.utils.Delegate;
import flash.filters.GlowFilter;
import gfx.motion.Tween;
import mx.transitions.easing.Bounce;
import com.ElTorqiro.AegisHUD.AddonInfo;
import com.GameInterface.UtilsBase;
import flash.geom.Point;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.CombatIndicator extends UIComponent {

	// internal movieclips;
	private var m_Primary:MovieClip;
	private var m_Secondary:MovieClip;
	
	// player character
	private var _character:Character;
	
	// utilty objects
	private var _isThreatened:Boolean;
	
	// game scaling mechanism settings
    private var _guiResolutionScale:DistributedValue; 
    private var _guiHUDScale:DistributedValue;	

	
	/**
	 * constructor
	 */
	public function CombatIndicator() {
		super();

		_character = Character.GetClientCharacter();

		_character.SignalToggleCombat.Connect( ToggleCombatIndicator, this );
		_isThreatened = _character.IsInCombat();
		
		// wire up scale related listeners
		_guiResolutionScale = DistributedValue.Create("GUIResolutionScale");
		_guiResolutionScale.SignalChanged.Connect( ToggleCombatIndicator, this );
		_guiHUDScale = DistributedValue.Create("GUIScaleHUD")
		_guiHUDScale.SignalChanged.Connect( ToggleCombatIndicator, this );
	}
	
	
	function ToggleCombatIndicator(isThreatened):Void {
		
		_isThreatened = isThreatened;
		
		UtilsBase.PrintChatText('<font color="#999999">togglecombatindicator: ' + isThreatened + ', ' + _character.IsInCombat() + ', ' + _character.IsThreatened() + '</font>');
	
		invalidate();
	}
	
	public function onUnload():Void	{
		super.onUnload();

		_guiResolutionScale.SignalChanged.Disconnect( ToggleCombatIndicator, this );
		_guiHUDScale.SignalChanged.Disconnect( ToggleCombatIndicator, this );

		_character.SignalToggleCombat.Disconnect( ToggleCombatIndicator, this );
		
		_character = undefined;
	}
	
	public function configUI():Void {
		super.configUI();

		// colourise bars
		var tint:Number = 0xffcc00;
		var combatGlow:GlowFilter = new GlowFilter(
			tint, 	/* glow_color */
			0.8, 		/* glow_alpha */
			8, 			/* glow_blurX */
			8, 			/* glow_blurY */
			2,			/* glow_strength */
			3, 			/* glow_quality */
			false, 		/* glow_inner */
			false 		/* glow_knockout */
		);
		
		AddonUtils.Colorize( this, tint );
		this.filters = [ combatGlow ];
	}

	private function draw():Void {
		// hide if not in combat
		if ( !_isThreatened ) {
			UtilsBase.PrintChatText('<font color="#ff0000">combat off</font>');
			
			this._visible = false;
			return;
		}
		

		// find the hud
		var hud:MovieClip = _parent.m_HUD;

		UtilsBase.PrintChatText('<font color="#00ff00">combat on</font>');
		
		// if hud present
		if( hud != undefined ) {
			UtilsBase.PrintChatText('<font color="#0099ff">' + hud._name + '</font>');
			var hudBars:Object = { primary: hud.m_Primary, secondary: hud.m_Secondary };
			for ( var s:String in hudBars ) {
				var barMC = hudBars[s];
				
				var inCombat:MovieClip = this[ barMC._name ];
				
				inCombat._width = barMC._width - ( hud.barPadding * 2);
				inCombat._x = barMC._x + 5;
				inCombat._height = 5;
				inCombat._y = barMC._y - inCombat._height - 4;

//				AddonUtils.Colorize( inCombat, tint );
//				inCombat.filters = [ combatGlow ];
				
				inCombat._visible = true;
			}
			
		}
		
		// no hud, try passivebar
		else {

			var pb = _root.passivebar;
			
			var pbx:Number = pb.m_BaseWidth / 2 + pb.m_Button._x; // - 4;
			var pby:Number = pb.m_Bar._y; // - 5;
			
			var globalPassiveBarPos:Point = new Point( pbx, pby );
			pb.localToGlobal( globalPassiveBarPos );
			this.globalToLocal( globalPassiveBarPos );

			m_Primary._width = m_Secondary._width = 100;
			m_Primary._height = m_Secondary._height = 5;
			
			
			var primaryDefaultPosition = new Point( globalPassiveBarPos.x - m_Primary._width - 2, globalPassiveBarPos.y - m_Primary._height - 3 );
			var secondaryDefaultPosition = new Point( globalPassiveBarPos.x + 2, globalPassiveBarPos.y - m_Secondary._height - 3 );
			
			m_Primary._x = primaryDefaultPosition.x;
			m_Primary._y = primaryDefaultPosition.y;
			m_Secondary._x = secondaryDefaultPosition.x;
			m_Secondary._y = secondaryDefaultPosition.y;
						
/*			
			var inCombat:MovieClip = m_Primary;
			m_Secondary._visible = false;
			
			inCombat._x = barPosition.x + 5;
			inCombat._height = 5;
			inCombat._y = barPosition.y - inCombat._height - 4;
			inCombat._width = pb._width - 5;
*/		
			

		}
		
		this._visible = true;
		
	}
}