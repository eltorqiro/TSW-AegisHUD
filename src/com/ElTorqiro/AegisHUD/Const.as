
/**
 * shared constants used throughout the app
 * 
 */
class com.ElTorqiro.AegisHUD.Const {
	
	// static class only, cannot be instantiated
	private function Const() { }

	// app information
	public static var AppID:String = "ElTorqiro_AegisHUD";
	public static var AppName:String = "AegisHUD";
	public static var AppAuthor:String = "ElTorqiro";
	public static var AppVersion:String = "4.0.0 alpha 4";
	
	public static var PrefsVersion:Number = 40004;
	
	public static var HudClipPath:String = "ElTorqiro_AegisHUD\\HUD.swf";
	public static var WidgetClipPath:String = "ElTorqiro_AegisHUD\\Widget.swf";
	public static var ConfigWindowClipPath:String = "ElTorqiro_AegisHUD\\ConfigWindow.swf";
	
	public static var PrefsName:String = "ElTorqiro_AegisHUD_Preferences";
	
	public static var ShowConfigWindowDV:String = "ElTorqiro_AegisHUD_ShowConfigWindow";
	public static var DebugModeDV:String = "ElTorqiro_AegisHUD_Debug";
	
	// item type enum shortcuts
	public static var e_ItemTypeWeapon:Number = _global.Enums.ItemType.e_ItemType_Weapon;
	public static var e_ItemTypeAegisShield:Number = _global.Enums.ItemType.e_ItemType_AegisShield;		
	public static var e_ItemTypeAegisWeapon:Number = _global.Enums.ItemType.e_ItemType_AegisWeapon;

	// aegis type enum shortcuts
	public static var e_AegisTypePink:Number = _global.Enums.AegisTypes.e_AegisPink;
	public static var e_AegisTypeBlue:Number = _global.Enums.AegisTypes.e_AegisBlue;
	public static var e_AegisTypeRed:Number = _global.Enums.AegisTypes.e_AegisRed;

	// equipment position enum shortcuts
	public static var e_PrimaryWeaponPosition:Number = _global.Enums.ItemEquipLocation.e_Wear_First_WeaponSlot;
	public static var e_PrimaryAegis1Position:Number = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_1;
	public static var e_PrimaryAegis2Position:Number = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_1_2;
	public static var e_PrimaryAegis3Position:Number = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_1_3;

	public static var e_SecondaryWeaponPosition:Number = _global.Enums.ItemEquipLocation.e_Wear_Second_WeaponSlot;
	public static var e_SecondaryAegis1Position:Number = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_2;
	public static var e_SecondaryAegis2Position:Number = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_2_2;
	public static var e_SecondaryAegis3Position:Number = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_2_3;

	public static var e_AegisShieldPosition:Number = _global.Enums.ItemEquipLocation.e_Aegis_Head;
	
	// maximum aegis slots per group
	public static var e_AegisSlotsPerGroup:Number = 3;
	
	// selected aegis disruptor position shortcuts
	public static var e_PrimaryActiveAegisStat:Number = _global.Enums.Stat.e_FirstActiveAegis;
	public static var e_SecondaryActiveAegisStat:Number = _global.Enums.Stat.e_SecondActiveAegis;
	
	public static var e_ShieldActiveAegisStat:Number = _global.Enums.Stat.e_PlayerAegisShieldType;

	// aegis unlock achivement id
	public static var e_AegisUnlockAchievement:Number = 6817;				// The Lore number that unlocks the AEGIS system
	public static var e_UltimateAbilityUnlockAchievement:Number = 7783;		// the Lore number that unlocks the Ultimate Ability
	public static var e_AegisShieldUnlockAchievement:Number = 6818;			// The Lore number that unlocks the AEGIS Shield system
	
	// aegis type id
	public static var e_PsychicWeapon1ID:Number = 103;
	public static var e_PsychicWeapon2ID:Number = 104;
	public static var e_CyberneticWeapon1ID:Number = 105;
	public static var e_CyberneticWeapon2ID:Number = 106;
	public static var e_DemonicWeapon1ID:Number = 107;
	public static var e_DemonicWeapon2ID:Number = 108;
	
	public static var e_PsychicShieldID:Number = 111;
	public static var e_CyberneticShieldID:Number = 113;
	public static var e_DemonicShieldID:Number = 114;
	
	// icon types
	public static var e_IconTypeRDB:Number = 1;
	public static var e_IconTypeAegisHUD:Number = 2;
	
	// ui group bar types
	public static var e_BarTypeNone:Number = 1;
	public static var e_BarTypeThin:Number = 2;
	public static var e_BarTypeFull:Number = 3;
	
	// ui bar item show types
	public static var e_BarItemPlaceNone:Number = 0;
	public static var e_BarItemPlaceFirst:Number = 1;
	public static var e_BarItemPlaceLast:Number = 2;
	
	// aegis selection types
	public static var e_SelectSingle:Number = 1;
	public static var e_SelectMulti:Number = 2;
	
	// autoswap match types
	public static var e_AutoSwapNone:Number = 0;
	public static var e_AutoSwapOffensiveShield:Number = 1;
	public static var e_AutoSwapDefensiveShield:Number = 2;
	public static var e_AutoSwapOffensiveDisruptor:Number = 3;

	// autoswap allowable match character types
	public static var e_AutoSwapTargetTypePlayer:Number = 1;
	public static var e_AutoSwapTargetTypeNPC:Number = 2;
	public static var e_AutoSwapTargetTypeSelf:Number = 3;
	
	// hud layout types, internally used to track which function did the last layout
	public static var e_LayoutDefault:Number = 1;
	public static var e_LayoutCustom:Number = 2;
	
	// hud "no tint" tint
	public static var e_TintNone:Number = 0xffffff;
}