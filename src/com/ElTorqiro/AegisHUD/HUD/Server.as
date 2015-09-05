import com.ElTorqiro.AegisHUD.HUD.TargetAegisWatcher;
import mx.utils.Delegate;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.Utils.ID32;
import com.Utils.Signal;
import com.GameInterface.Tooltip.TooltipDataProvider;
import com.Utils.LDBFormat;

import com.GameInterface.UtilsBase;

import com.ElTorqiro.AegisHUD.AddonInfo;
import com.ElTorqiro.AegisHUD.App;
import com.ElTorqiro.AegisHUD.HUD.Enums;

import com.ElTorqiro.AegisHUD.AddonUtils.AddonUtils;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.Server {
	
	public function Server() {

		player = Character.GetClientCharacter();
		
		
		AddonUtils.FindGlobalEnum("view");
		/*
		for ( var i:Number = 0; i < 50000; i++ ) {
			var val:Number = player.GetTokens( i );
			
			var str:String = val.toString();
			
			//if ( str.substr(0, 2) == "32" ) {
			if ( val > 0 ) {
				UtilsBase.PrintChatText("tok " + i + " = " + val);
			}
			//}
		}
		*/
		
		equipped = new Inventory( new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, player.GetID().GetInstance()) );
		backpack = new Inventory( new ID32(_global.Enums.InvType.e_Type_GC_BackpackContainer, player.GetID().GetInstance()) );

		// properties of known aegis items
		aegisItems = { };
		aegisItems[103] = { id: 103, itemType: Enums.e_ItemTypeAegisWeapon, aegisType: Enums.e_AegisTypePink };
		aegisItems[104] = { id: 104, itemType: Enums.e_ItemTypeAegisWeapon, aegisType: Enums.e_AegisTypePink };
		aegisItems[105] = { id: 105, itemType: Enums.e_ItemTypeAegisWeapon, aegisType: Enums.e_AegisTypeBlue };
		aegisItems[106] = { id: 106, itemType: Enums.e_ItemTypeAegisWeapon, aegisType: Enums.e_AegisTypeBlue };
		aegisItems[107] = { id: 107, itemType: Enums.e_ItemTypeAegisWeapon, aegisType: Enums.e_AegisTypeRed };
		aegisItems[108] = { id: 108, itemType: Enums.e_ItemTypeAegisWeapon, aegisType: Enums.e_AegisTypeRed };

		aegisItems[111] = { id: 111, itemType: Enums.e_ItemTypeAegisShield, aegisType: Enums.e_AegisTypePink };
		aegisItems[113] = { id: 113, itemType: Enums.e_ItemTypeAegisShield, aegisType: Enums.e_AegisTypeBlue };
		aegisItems[114] = { id: 114, itemType: Enums.e_ItemTypeAegisShield, aegisType: Enums.e_AegisTypeRed };

		// aegis item groups
		groups = {
			primary: {
				slots: {
					weapon: { position: Enums.e_PrimaryWeaponPosition },
					aegis1: { position: Enums.e_PrimaryAegis1Position, next: "aegis2", prev: "aegis3", pair: { group: "secondary", slot: "aegis1" } },
					aegis2: { position: Enums.e_PrimaryAegis2Position, next: "aegis3", prev: "aegis1", pair: { group: "secondary", slot: "aegis2" } },
					aegis3: { position: Enums.e_PrimaryAegis3Position, next: "aegis1", prev: "aegis2", pair: { group: "secondary", slot: "aegis3" } }
				}
			},
			
			secondary: {
				slots: {
					weapon: { position: Enums.e_SecondaryWeaponPosition },
					aegis1: { position: Enums.e_SecondaryAegis1Position, next: "aegis2", prev: "aegis3", pair: { group: "primary", slot: "aegis1" } },
					aegis2: { position: Enums.e_SecondaryAegis2Position, next: "aegis3", prev: "aegis1", pair: { group: "primary", slot: "aegis2" } },
					aegis3: { position: Enums.e_SecondaryAegis3Position, next: "aegis1", prev: "aegis2", pair: { group: "primary", slot: "aegis3" } }
				}
			},
			
			shield: {
				slots: {
					aegis1: { aegisID: Enums.e_PsychicShieldID },
					aegis2: { aegisID: Enums.e_CyberneticShieldID },
					aegis3: { aegisID: Enums.e_DemonicShieldID }
				}
			}
		};

		// initialise position and type to slot maps
		weaponPositions = { };
		slotFromAegisID = { };
		
		for ( var s:String in groups ) {
			var group:Object = groups[s];
			
			group.name = s;
			
			for ( var i:String in group.slots ) {
				var slot:Object = group.slots[i];
				
				slot.group = s;
				slot.name = i;
				
				if ( slot.position ) {
					weaponPositions[ slot.position ] = slot;
					slot.inventoryID = equipped.GetInventoryID();
				}
				
				else if ( slot.aegisID ) {
					slotFromAegisID[ slot.aegisID ] = slot;
				}
				
			}
		}
		
		// initial load of items into slots
		refreshShields();
		refreshWeapons();
		refreshActivePointers();
		
		// setup listeners for inventory actions
		var inventorySignals:Array = [
			"SignalItemAdded",
			"SignalItemLoaded",
			"SignalItemMoved",
			"SignalItemRemoved",
			"SignalItemChanged"
		];
		
		var inventories:Array = [ equipped, backpack ];
		for ( var s:String in inventories ) {
			for ( var i:String in inventorySignals ) {
				inventories[s][ inventorySignals[i] ].Connect( inventoryUpdateHandler, this );
			}
		}
		
		// setup listener for active disruptor changes
		player.SignalStatChanged.Connect( statChangedHandler, this );
		
		// setup listener for aegis xp changes
		player.SignalTokenAmountChanged.Connect( updateAegisItemXP, this );

		// setup listeners for target aegis types changing
		targetAegisWatcher = new TargetAegisWatcher( player );
		targetAegisWatcher.SignalShieldTypeChanged.Connect( autoSwapDisruptors, this );
		targetAegisWatcher.SignalDisruptorTypeChanged.Connect( autoSwapShield, this );
		
		// initial autoswap
		autoSwapNow();

		// listen for disruptor swap RPC, typically for hotkey handling
		disruptorSwapRPC = DistributedValue.Create( AddonInfo.ID + "_Swap" );
		disruptorSwapRPC.SignalChanged.Connect( disruptorSwapRPCHandler, this );
		
		// create signals last so initial setup doesn't emit them
		SignalSelectedAegisChanged = new Signal();
		SignalItemChanged = new Signal();
		SignalItemXPChanged = new Signal();
		
	}
	
	/**
	 * handles calls from the disruptor swap RPC, triggered via hotkeys
	 */
	private function disruptorSwapRPCHandler() : Void {
		
	}

	/**
	 * finds and loads shields into shield slots
	 */
	private function refreshShields() : Void {

		var foundCount:Number = 0;
		
		// initialise shield position tracker
		shieldPositions = { };

		foundCount += Number(inventoryUpdateHandler( equipped.GetInventoryID(), Enums.e_AegisShieldPosition ));
		
		// find shields in backpack
		// stop once the most possible number of shields has been found
		for ( var i:Number = backpack.GetMaxItems() - 1; foundCount < 3 && i >= 0; i-- ) {
			foundCount += Number(inventoryUpdateHandler( backpack.GetInventoryID(), i ));
		}
		
	}

	/**
	 * loads weapons into weapon slots
	 */
	private function refreshWeapons() : Void {

		for ( var s:String in weaponPositions ) {
			inventoryUpdateHandler( equipped.GetInventoryID(), s );
		}

	}

	/**
	 * handles inventory update signals to keep track of items in slots
	 * 
	 * @param	inventoryID
	 * @param	position
	 * @return
	 */
	private function inventoryUpdateHandler(inventoryID:ID32, position:Number) : Boolean {
		
		var inventory:Inventory = inventoryID.GetType() == equipped.GetInventoryID().GetType() ? equipped : backpack;
		var item:InventoryItem = inventory.GetItemAt( position );

		var key:String = createPositionKey( inventoryID, position );
		
		var slot:Object;
		
		var handled:Boolean = false;
		
		// if this is a weapon position, update the item in its corresponding slot
		if ( inventory == equipped && (slot = weaponPositions[position]) ) {

			// if the slot is now empty, unlink it from aegis id map
			if ( item == undefined ) {
				delete slotFromAegisID[ slot.item.m_AegisItemType ];
			}
			
			// otherwise if it is an aegis item, link it to the aegis id map
			else if ( item.m_AegisItemType ) {
				slotFromAegisID[ item.m_AegisItemType ] = slot;

				// update aegis item xp since item is fresh in slot
				updateAegisItemXP( item.m_AegisItemType );
			}
			
			slot.item = item;
			SignalItemChanged.Emit( slot.group, slot.name );
			
			handled = true;
		}
		
		// else if it used to be a shield position and the item is now empty (e.g. removed) or not a shield
		// clear the links to it
		else if ( (slot = shieldPositions[key]) && (item == undefined || item.m_ItemType != Enums.e_ItemTypeAegisShield) ) {
			
			delete shieldPositions[key];

			// was it really lost (e.g. deleted or moved to crafting window), or is it just moving between backpack and equipped?
			confirmLostItem( slot.item.m_AegisItemType );
			
			// update active pointer if necessary
			refreshActivePointers();
			
			handled = true;
		}
		
		// else if it is a known shield, create a link to its slot
		else if ( item.m_ItemType == Enums.e_ItemTypeAegisShield && (slot = slotFromAegisID[ item.m_AegisItemType ]) ) {

			// clear up any lost item confirmation runner
			confirmLostItem( item.m_AegisItemType, true );
			
			// add/update position link
			shieldPositions[key] = slot;
			
			// trigger slot update
			slot.inventoryID = inventoryID;
			slot.position = position;
			
			if ( slot.item == undefined ) {
				slot.item = item;
				
				// update aegis item xp since item is fresh in slot
				updateAegisItemXP( item.m_AegisItemType );
				
				SignalItemChanged.Emit( slot.group, slot.name );
			}
			
			// update active pointer if necessary
			refreshActivePointers();
			
			handled = true;
		}
		
		return handled;
	}
	
	private function createPositionKey( inventory, position:Number ) : String {
		
		var prefix:String = "";
		
		// if an inventory id is passed, use it
		if ( inventory instanceof ID32 ) prefix = inventory.GetType();
		else if ( inventory instanceof Inventory ) prefix = inventory.GetInventoryID().GetType();
		
		return prefix + "_" + position;
	}

	/**
	 * triggered by shield item updates in inventory
	 * to make sure tracking of a shield item has actually been lost before signaling a change
	 * 
	 * this avoids unnecessary rapid flip between lost and found when moving a shield from equipped to backpack or back
	 * 
	 * @param	aegisID
	 * @param	clear
	 */
	private function confirmLostItem( aegisID:Number, clear:Boolean ) : Void {
		
		// clearing the timer if an item for this aegisID was found
		if ( clear ) {
			clearTimeout( lostItemTimers[ aegisID ] );
			lostItemTimers[ aegisID ] = undefined;
		}
		
		// if not a callback, start the timer
		else if ( lostItemTimers[ aegisID ] == undefined ) {
			lostItemTimers[ aegisID ] = setTimeout( Delegate.create( this, confirmLostItem ), 50, aegisID );
		}

		// item is still lost, trigger an update
		else {
			clearTimeout( lostItemTimers[ aegisID ] );
			lostItemTimers[ aegisID ] = undefined;
			
			var slot:Object = slotFromAegisID[ aegisID ];
			slot.inventoryID = undefined;
			slot.position = undefined;
			slot.item = undefined;
			SignalItemChanged.Emit( slot.group, slot.name );
		}
		
	}
	
	/**
	 * handles calls for the active disruptor pointer changing
	 * 
	 * @param	stat
	 * @param	value
	 */
	private function statChangedHandler( stat:Number, value:Number ) : Void {
		if ( stat == Enums.e_PrimaryActiveAegisStat || stat == Enums.e_SecondaryActiveAegisStat ) {
			refreshActivePointers();
		}
	}
	
	/**
	 * updates the current active slot pointers against their game counterparts
	 */
	private function refreshActivePointers() : Void {
		
		groups.primary.activeSlot = weaponPositions[ player.GetStat( Enums.e_PrimaryActiveAegisStat ) ];
		groups.secondary.activeSlot = weaponPositions[ player.GetStat( Enums.e_SecondaryActiveAegisStat ) ];
		
		groups.shield.activeSlot = shieldPositions[ createPositionKey( equipped, Enums.e_AegisShieldPosition ) ];
		
		// if the post-swap catchup timer isn't running, immediately sync the selected with the active
		if ( swapCatchupTimerID == undefined ) {
			syncSelectedWithActive();
		}
		
	}
	
	/**
	 * syncs the current selected slot pointers with their active counterparts
	 */
	private function syncSelectedWithActive() : Void {
		
		for ( var s:String in groups ) {
			if ( groups[s].selectedSlot != groups[s].activeSlot ) {
				groups[s].selectedSlot = groups[s].activeSlot;
				SignalSelectedAegisChanged.Emit( s, groups[s].selectedSlot.name );
			}
		}
		
	}
	
	/**
	 * updates the xp values for a given aegis item id
	 * 
	 * @param	tokenID
	 * @param	value
	 */
	private function updateAegisItemXP( aegisID:Number, value:Number ) : Void {

		var aegisItem:Object = aegisItems[ aegisID ];

		// only proceed if update is for a known aegis item
		if ( aegisItem == undefined ) return;
		
		
		// TODO: apply a throttle for fetching xp on a per item basis, to avoid tooltip-scraping spam
		

		var xp:Number = 0;
		
		// fetch tooltip for item, if possible
		var slot:Object = slotFromAegisID[ aegisID ];
		var xpString:String = TooltipDataProvider.GetInventoryItemTooltip( slot.inventoryID, slot.position ).m_Descriptions[2];

		// can't let indexOf run against undefined, it halts the game
		if ( xpString != undefined ) {

			// get the first occurence of %
			var endPos:Number = xpString.indexOf('%');
			
			if ( LDBFormat.GetCurrentLanguageCode() == 'de' ) endPos--;	// german client has a space between number and %

			// woork backwards until we hit the end of the html tag that wraps the percent text
			for ( var startPos:Number = endPos; startPos >= 0; startPos-- ) {
				
				var char:String = xpString.charAt(startPos);
				
				// not a number sequence
				if ( char == ' ' || char == '>' ) {
					break;
				}
			}

			xp = Number(xpString.substring(++startPos, endPos));
			//xp = Math.floor( Number(xpString.substring(++startPos, endPos)) );
		}

		aegisItem.xp = value;
		aegisItem.xpPercent = xp;
		
		// signal an update
		SignalItemXPChanged.Emit( slot.group, slot.name );
		
	}
	
	/**
	 * trigger an autoswap event for disruptors and shield now
	 */
	public function autoSwapNow() : Void {
		autoSwapDisruptors( targetAegisWatcher.shieldType );
		autoSwapShield( targetAegisWatcher.disruptorType );
	}
	
	private function autoSwapDisruptors( aegisType:Number ) : Void {
		UtilsBase.PrintChatText("switch disruptors to " + aegisType);
	}
	
	private function autoSwapShield( aegisType:Number ) : Void {
		UtilsBase.PrintChatText("switch shield to: " + aegisType);
	}
	
	/**
	 * 
	 * @param	group
	 * @param	slot
	 * @return
	 */
	public function getSlot( group:String, name:String ) : Object {
		
		var groupObject:Object = groups[ group ];
		var slotObject:Object = groupObject.slots[ name ];
		
		var aegisItem:Object = aegisItems[ slotObject.item.m_AegisItemType ];
		
		return {
			group: slotObject.group,
			name: slotObject.name,
			item: slotObject.item,
			
			xp: aegisItem.xp,
			xpPercent: aegisItem.xpPercent
		};
	}
	
	
	/*
	 * internal variables
	 */

	private var player:Character;
	private var equipped:Inventory;
	private var backpack:Inventory;
	
	private var disruptorSwapRPC:DistributedValue;
	
	private var targetAegisWatcher:TargetAegisWatcher;
	
	private var aegisItems:Object;
	private var groups:Object;
	private var weaponPositions:Object;
	private var shieldPositions:Object;
	private var slotFromAegisID:Object;
	
	private var swapCatchupTimerID:Number = undefined;
	private var lostItemTimers:Object = { };
	
	private var app:App;
	
	
	/*
	 * properties
	 */
	
	public var SignalSelectedAegisChanged:Signal;
	public var SignalItemChanged:Signal;
	public var SignalItemXPChanged:Signal;
	 
}