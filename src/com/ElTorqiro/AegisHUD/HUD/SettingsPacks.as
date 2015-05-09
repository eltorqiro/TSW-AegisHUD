/**
 * settings packs, including the default settings
 * 
 * this has been moved out of the HUD class to avoid the 32k class/function branch limit
 */

class com.ElTorqiro.AegisHUD.HUD.SettingsPacks {

	/**
	 * default settings package
	 * ( must use function to ensure a fresh copy of the object is returned, rather than a reference to an existing object )
	 * 
	 * readonly
	 */
	public static function get defaultSettings():Object {
		
		return new Object( {
		
			settingsVersion: 3000,
			
			hudEnabled: true,
			
			hideWhenAutoSwapEnabled: false,
			hideWhenNotInCombat: false,
			
			slotSize: 24,
			barPadding: 3,
			slotSpacing: 3,
			hudScale: 100,
			maxHUDScale: 150,
			minHUDScale: 50,
			
			hideDefaultDisruptorSwapUI: true,
			hideDefaultShieldSwapUI: true,
			
			autoSwapEnabled: true,
			autoSwapPrimaryEnabled: true,
			autoSwapSecondaryEnabled: true,
			autoSwapShieldEnabled: true,
			
			primaryPosition: undefined,
			secondaryPosition: undefined,
			shieldPosition: undefined,
			
			aegisTypeIcons: true,
			
			neonGlowEntireBar: false,
			lockBars: false,
			attachToPassiveBar: true,
			animateMovementsToDefaultPosition: true,
			
			showBarBackground: true,
			barBackgroundThin: true,
			tintBarBackgroundByActiveAegis: true,
			neonGlowBarBackground: true,

			showWeapons: true,
			showShield: true,
			primaryItemFirst: true,
			secondaryItemFirst: true,
			shieldItemFirst: true,
			
			tintWeaponIconByActiveAegis: false,
			neonGlowWeapon: true,
			
			showXP: true,
			hideXPWhenFull: false,

			showTooltips: true,
			suppressTooltipsInCombat: true,

			tintAegisIconByType: false,
			showActiveAegisBackground: false,
			tintActiveAegisBackground: false,
			neonGlowActiveAegisBackground: false,
			neonGlowAegis: true,
			
			neonEnabled: true,

			dualSelectWithModifier: true,
			dualSelectWithButton: true,
			dualSelectByDefault: true,
			dualSelectFromHotkey: true,
			
			tintAegisPsychic:		0xe083ff,
			tintAegisCybernetic:	0x00d0ff,
			tintAegisDemonic:		0xff3300,
			tintAegisEmpty:			0x999999,
			tintAegisStandard:		0xe8e8e8,

			tintXPProgress:			0xf0f0f0,		/* 0x00E5A3 */
			tintXPFull:				0x66ff66,		/* // 0x4EE500 // 0x19FDFF */
			
			tintBarStandard:		0x000000
		});
	}
	
}
