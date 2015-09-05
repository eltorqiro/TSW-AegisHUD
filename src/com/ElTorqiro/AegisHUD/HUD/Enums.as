

class com.ElTorqiro.AegisHUD.HUD.Enums {
	
	// static class only, cannot be instantiated
	private function Enums() { }
	
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
	
	// selected aegis disruptor position shortcuts
	public static var e_PrimaryActiveAegisStat:Number = _global.Enums.Stat.e_FirstActiveAegis;
	public static var e_SecondaryActiveAegisStat:Number = _global.Enums.Stat.e_SecondActiveAegis;

	// aegis unlock achivement id
	public static var e_AegisUnlockAchievement:Number = 6817;				// The Lore number that unlocks the AEGIS system
	public static var e_UltimateAbilityUnlockAchievement:Number = 7783;		// the Lore number that unlocks the Ultimate Ability
	public static var e_AegisShieldUnlockAchievement:Number = 6818;			// The Lore number that unlocks the AEGIS Shield system
	
	// aegis type id
	public static var e_PsychicShieldID:Number = 111;
	public static var e_CyberneticShieldID:Number = 113;
	public static var e_DemonicShieldID:Number = 114;
	
}