import mx.utils.Delegate;

import com.GameInterface.Game.Character;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.Utils.ID32;
import com.Utils.Signal;
import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Tooltip.TooltipDataProvider;
import com.Utils.LDBFormat;
import com.GameInterface.LoreBase;

import com.ElTorqiro.AegisHUD.Const;
import com.ElTorqiro.AegisHUD.Server.AegisServerGroup;
import com.ElTorqiro.AegisHUD.Server.AegisServerSlot;

import com.GameInterface.UtilsBase;


/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.Server.AegisServer {
	
	// static class only
	private function AegisServer() { }
	
	/**
	 * start the server running
	 */
	public static function start() {
	
		if ( running ) return;
		_running = true;
		
		character = Character.GetClientCharacter();
		
		equipped = new Inventory( new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, character.GetID().GetInstance()) );
		backpack = new Inventory( new ID32(_global.Enums.InvType.e_Type_GC_BackpackContainer, character.GetID().GetInstance()) );

		// properties of known aegis items
		aegisItems = { };
		aegisItems[103] = { id: 103, itemType: Const.e_ItemTypeAegisWeapon, aegisType: Const.e_AegisTypePink, aegisTypeName: "psychic" };
		aegisItems[104] = { id: 104, itemType: Const.e_ItemTypeAegisWeapon, aegisType: Const.e_AegisTypePink, aegisTypeName: "psychic" };
		aegisItems[105] = { id: 105, itemType: Const.e_ItemTypeAegisWeapon, aegisType: Const.e_AegisTypeBlue, aegisTypeName: "cybernetic" };
		aegisItems[106] = { id: 106, itemType: Const.e_ItemTypeAegisWeapon, aegisType: Const.e_AegisTypeBlue, aegisTypeName: "cybernetic" };
		aegisItems[107] = { id: 107, itemType: Const.e_ItemTypeAegisWeapon, aegisType: Const.e_AegisTypeRed, aegisTypeName: "demonic" };
		aegisItems[108] = { id: 108, itemType: Const.e_ItemTypeAegisWeapon, aegisType: Const.e_AegisTypeRed, aegisTypeName: "demonic" };

		aegisItems[111] = { id: 111, itemType: Const.e_ItemTypeAegisShield, aegisType: Const.e_AegisTypePink, aegisTypeName: "psychic" };
		aegisItems[113] = { id: 113, itemType: Const.e_ItemTypeAegisShield, aegisType: Const.e_AegisTypeBlue, aegisTypeName: "cybernetic" };
		aegisItems[114] = { id: 114, itemType: Const.e_ItemTypeAegisShield, aegisType: Const.e_AegisTypeRed, aegisTypeName: "demonic" };
		
		// define slot tracking references
		var defn:Object = {
			
			primary: {
				type: "disruptor",
				trackBy: "equippedPosition",
				trackRefs: {
					item:	Const.e_PrimaryWeaponPosition,
					aegis1:	Const.e_PrimaryAegis1Position,
					aegis2:	Const.e_PrimaryAegis2Position,
					aegis3:	Const.e_PrimaryAegis3Position
				}
			},
			
			secondary: {
				type: "disruptor",
				trackBy: "equippedPosition",
				trackRefs: {
					item:	Const.e_SecondaryWeaponPosition,
					aegis1:	Const.e_SecondaryAegis1Position,
					aegis2:	Const.e_SecondaryAegis2Position,
					aegis3:	Const.e_SecondaryAegis3Position
				}	
			},
			
			shield: {
				type: "shield",
				trackBy: "aegisID",
				trackRefs: {
					aegis1:	Const.e_PsychicShieldID,
					aegis2:	Const.e_CyberneticShieldID,
					aegis3:	Const.e_DemonicShieldID
				}	
			}
			
		};

		// define next/prev links for aegis swapping
		nextPrevMap = {
			aegis1: { next: "aegis2", prev: "aegis3" },
			aegis2: { next: "aegis3", prev: "aegis1" },
			aegis3: { next: "aegis1", prev: "aegis2" }
		};
		
		// build actual group and slot hierarchy from definition
		groups = { };
		equippedPositionBinds = { };
		aegisIdBinds = { };
		multiSelectGroups = { };
		
		for ( var s:String in defn ) {
			
			var group:AegisServerGroup = new AegisServerGroup( s, defn[s].type );
			groups[s] = group;
			
			// build the multiselect group list 
			if ( group.type == "disruptor" ) {
				multiSelectGroups[s] = group;
			}

			var map:Object = defn[s].trackBy == "equippedPosition" ? equippedPositionBinds : aegisIdBinds;
			for ( var t:String in defn[s].trackRefs ) {
				map[ defn[s].trackRefs[t] ] = group.slots[t];
			}
		}
		
		// map shield types to aegis item IDs, needed for mapping the active pointer for shields
		shieldTypeToAegisId = { };
		for ( var s:String in aegisItems ) {
			if ( aegisItems[s].itemType == Const.e_ItemTypeAegisShield ) {
				shieldTypeToAegisId[ aegisItems[s].aegisType ] = s;
			}
		}
		
		// load items tracked by aegis id
		var maxAegisItems:Number = 0;
		for ( var s:String in aegisIdBinds ) {
			maxAegisItems++;
		}
		
		knownLocationBinds = { };

		// find equipped shield, if any
		var foundCount:Number = Number(inventoryEventHandler( equipped.GetInventoryID(), Const.e_AegisShieldPosition ));
		
		// find items in backpack
		for ( var i:Number = backpack.GetMaxItems() - 1; foundCount < maxAegisItems && i >= 0; i-- ) {
			foundCount += Number(inventoryEventHandler( backpack.GetInventoryID(), i ));
		}

		// load items tracked by equipped position
		for ( var s:String in equippedPositionBinds ) {
			inventoryEventHandler( equipped.GetInventoryID(), Number(s) );
		}
		
		refreshActivePointers();
		
		timers = {
			lostItem: { }
		};
		
		// equipped inventory only needs to track add/remove events
		equipped.SignalItemAdded.Connect( inventoryEventHandler );
		equipped.SignalItemRemoved.Connect( inventoryEventHandler );
		equipped.SignalItemLoaded.Connect( inventoryEventHandler );
		
		// backpack needs to track add/remove/changed events
		backpack.SignalItemAdded.Connect( inventoryEventHandler );
		backpack.SignalItemRemoved.Connect( inventoryEventHandler );
		backpack.SignalItemChanged.Connect( inventoryEventHandler );
		backpack.SignalItemLoaded.Connect( inventoryEventHandler );
		
		// setup listener for active pointer changes
		character.SignalStatChanged.Connect( statChangedHandler );
		
		// setup listener for aegis xp changes
		character.SignalTokenAmountChanged.Connect( updateAegisItemXP );

		// create signals last so initial setup doesn't emit them
		SignalSelectionChanged = new Signal();
		SignalItemChanged = new Signal();
		SignalXPChanged = new Signal();

		SignalAegisSystemUnlocked = new Signal();
		SignalShieldSystemUnlocked = new Signal();
		
		// aegis system unlock listener
		LoreBase.SignalTagAdded.Connect( loreTagAddedHandler );
	}

	/**
	 * shuts down the server, shutting down all activity
	 */
	public static function stop() : Void {
		
		character = null;		
		
		equipped = null;
		backpack = null;

		aegisItems = null;
		nextPrevMap = null;
		multiSelectGroups = null;

		for ( var s:String in groups ) {
			groups[s].dispose();
		}
		
		groups = null;
		equippedPositionBinds = null;
		aegisIdBinds = null;
		shieldTypeToAegisId = null;
		knownLocationBinds = null;
		
		SignalSelectionChanged = null;
		SignalItemChanged = null;
		SignalXPChanged = null;
		
		SignalAegisSystemUnlocked = null;
		SignalShieldSystemUnlocked = null;
		
		LoreBase.SignalTagAdded.Disconnect( loreTagAddedHandler );
		
		for ( var s:String in timers.lostItem ) {
			clearTimeout( timers.lostItem[s] );
		}
		
		clearTimeout( timers.swapCatchup );
		
		timers = null;
		
		_running = false;
	}
	
	/**
	 * handles inventory events needed for tracking item locations
	 * 
	 * @param	inventoryID
	 * @param	itemPos
	 * 
	 * @return	whether the inventory event was of interest and was processed as an aegis server event
	 */
	private static function inventoryEventHandler( inventoryID:ID32, itemPos:Number ) : Boolean {

		var inventory:Inventory = inventoryID.toString() == equipped.GetInventoryID().toString() ? equipped : backpack;
		var item:InventoryItem = inventory.GetItemAt( itemPos );
		
		var location:String = createPositionKey( inventory, itemPos );
		var slot:AegisServerSlot;

		var handled:Boolean = false;

		// is this a location we track by equipped position?
		if ( inventory == equipped && (slot = equippedPositionBinds[itemPos]) ) {

			// if the position is empty, remove item references from its slot
			if ( item == undefined ) {
				setSlotItem( slot );
			}
			
			// otherwise add item references to its slot
			else {
				setSlotItem( slot, inventoryID, itemPos, item );
			}

			handled = true;
		}
		
		// else if the position is empty and it used to be on our known location list
		else if ( item == undefined && (slot = knownLocationBinds[location]) ) {
			
			// remove links to it
			delete knownLocationBinds[location];

			// was it really lost (e.g. deleted or moved to crafting window)
			// or is it just moving between backpack and equipped?
			confirmLostItem( slot.item.m_AegisItemType );
			
			handled = true;
		}
		
		// else if the item is one we track by aegis id
		else if ( slot = aegisIdBinds[item.m_AegisItemType] ) {

			// clear any lost item confirmation runner
			confirmLostItem( item.m_AegisItemType, true );
			
			// add links to it
			knownLocationBinds[location] = slot;
			setSlotItem( slot, inventoryID, itemPos, item );

			handled = true;
		}
		
		return handled;
	}
	
	/**
	 * triggered by aegis item updates in inventory
	 * to make sure tracking of an item item has actually been lost before signaling a change
	 * 
	 * this avoids unnecessary rapid flip between lost and found when e.g. moving a shield from equipped to backpack
	 * 
	 * @param	aegisID
	 * @param	clear
	 */
	private static function confirmLostItem( aegisID:Number, clear:Boolean ) : Void {

		// clearing the timer if an item for this aegisID was found
		if ( clear ) {
			clearTimeout( timers.lostItem[ aegisID ] );
			delete timers.lostItem[ aegisID ];
		}
		
		// if not a callback, start the timer
		else if ( timers.lostItem[ aegisID ] == undefined ) {
			timers.lostItem[ aegisID ] = setTimeout( confirmLostItem, 50, aegisID );
		}

		// item is still lost, trigger an update
		else {
			delete timers.lostItem[ aegisID ];
			setSlotItem( aegisIdBinds[ aegisID ] );
		}
		
	}

	/**
	 * creates a string key for an inventory & position combination
	 * 
	 * @param	inventory
	 * @param	position
	 * 
	 * @return	the string key
	 */
	private static function createPositionKey( inventory, position:Number ) : String {
		
		var prefix:String = "";
		
		// if an inventory id is passed, use it
		if ( inventory instanceof ID32 ) prefix = inventory.GetType();
		else if ( inventory instanceof Inventory ) prefix = inventory.GetInventoryID().GetType();
		
		return prefix + "_" + position;
	}
	
	/**
	 * changes the selected slot of a given group
	 * 
	 * @param	groupID
	 * @param	slotID	slot name to select (TODO: the reserved names "next" and "prev" are used for switching forward/back from the current selected slot)
	 * @param	multi	the type of multiselect logic to use, default=single
	 */
	public static function selectSlot( groupID:String, slotID:String, multiSelect:Number ) : Void {
		
		var multi:Number = multiSelect != undefined ? multiSelect : Const.e_SelectSingle;
		
		var group:AegisServerGroup = groups[groupID];
		var fromSlot:AegisServerSlot = group.selectedSlot;
		var toSlot:AegisServerSlot;

		if ( slotID == "next" || slotID == "prev" ) {
			toSlot = group.slots[ nextPrevMap[fromSlot.id][slotID] ];
		}
		
		else {
			toSlot = group.slots[ slotID ];
		}
		
		if ( toSlot != fromSlot ) {

			var success:Boolean;
			
			// swapping to shields involves "using" the item
			if ( groupID == "shield" ) {

				// swapping shields can only be done out of combat			
				if ( character.IsInCombat() || character.IsGhosting() || character.IsDead() ) return;

				var inventory:Inventory = toSlot.inventoryID.GetType() == equipped.GetInventoryID().GetType() ? equipped : backpack;
				
				// don't unequip the slotted shield if it is clicked, or if there is no item in the slot
				if ( inventory == equipped || toSlot.item == undefined ) return;

				// otherwise use the item to initiate a swap
				inventory.UseItem( toSlot.position );

				success = true;
			}

			// disruptors rotate through available slots
			else {
			
				// switch forward?
				if ( nextPrevMap[ fromSlot.id ].next == toSlot.id ) {
					// first param is first/second aegis, second param is forward/back
					Character.SwapAegisController( groupID == "primary", true);
				}
				
				// or switch back? (doing the extra check instead of an arbitrary 'else' prevents double-jumps caused by switch latency)
				else if ( nextPrevMap[ fromSlot.id ].prev == toSlot.id ) {
					Character.SwapAegisController( groupID == "primary", false);
				}

				success = true;
			}
			
			if ( success ) {
				// restart post-swap callback
				postSwapCatchup(true);
				
				// important to update the internal pointer for the aegis location
				// even before we find out if the swap was successful
				// otherwise rapid clicks can cause the selection to jump 2 spots (for disruptors) or do a swapback (for shields)

				group.selectedSlot = toSlot;
				SignalSelectionChanged.Emit( groupID, toSlot.id, fromSlot.id );
			}
		}
			
		// handle multiselect
		if ( multi == Const.e_SelectMulti && multiSelectGroups[groupID] != undefined ) {
			for ( var s:String in multiSelectGroups ) {
				if ( s != groupID ) {
					selectSlot( s, toSlot.id );
				}
			}
		}
		
	}

	/**
	 * selects the first slot in a group that matches a given aegis type
	 * - useful for things like autoswap features
	 * 
	 * @param	groupID
	 * @param	aegisType
	 */
	public static function selectAegisType( groupID:String, aegisType:Number ) : Void {
		
		var slots:Object = groups[groupID].slots;
		
		for ( var s:String in slots ) {
			if ( aegisItems[ slots[s].item.m_AegisItemType ].aegisType == aegisType ) {
				selectSlot( groupID, s );
				break;
			}
		}
		
	}

	/**
	 * post-swap callback that will delay the sync of the active with the selected slots in all groups
	 * this is needed in case of users going bonkers with very rapid clicks, which can
	 * get out of sync with the server if the server drops one of the request packets
	 * (yes it happens often under command spam)
	 * 
	 * @param	restart
	 */
	private static function postSwapCatchup(restart:Boolean):Void {
		
		// clear any existing timer
		clearTimeout( timers.swapCatchup );
		delete timers.swapCatchup;
		
		// if restarting timer, set up timer again
		if ( restart ) {
			timers.swapCatchup = setTimeout( postSwapCatchup, 1000 );
		}
		
		// otherwise action the catchup
		else {
			syncSelectedWithActive();
		}
	}

	/**
	 * apply inventory item information to a slot
	 * 
	 * @param	slot
	 * @param	inventoryID
	 * @param	position
	 * @param	item
	 */
	private static function setSlotItem( slot:AegisServerSlot, inventoryID:ID32, position:Number, item:InventoryItem ) : Void {

		var oldItem:InventoryItem = slot.item;

		// update inventory references
		slot.inventoryID = inventoryID;
		slot.position = position;
		slot.item = item;
		
		aegisItems[ oldItem.m_AegisItemType ].slot = undefined;
		aegisItems[ item.m_AegisItemType ].slot = slot;
		
		// only trigger signals if the item has actually changed, not just the location info
		if ( oldItem.m_Icon.toString() != item.m_Icon.toString() ) {
			
			slot.aegisTypeName = aegisItems[ item.m_AegisItemType ].aegisTypeName;
			
			SignalItemChanged.Emit( slot.group.id, slot.id );

			// update aegis data
			if ( oldItem.m_AegisItemType ) {
				
				slot.xpRaw = undefined;
				slot.xpPercent = undefined;
				
				SignalXPChanged.Emit( slot.group.id, slot.id );
			}
			
			else {
				updateAegisItemXP( item.m_AegisItemType );
			}
		}
	}
	
	/**
	 * handles the active controller pointers changing
	 * 
	 * @param	stat
	 * @param	value
	 */
	private static function statChangedHandler( stat:Number, value:Number ) : Void {
		
		switch ( stat ) {
			
			case Const.e_PrimaryActiveAegisStat:
			case Const.e_SecondaryActiveAegisStat:
			case Const.e_ShieldActiveAegisStat:
				refreshActivePointers();
			break;
		}
	}
	
	/**
	 * updates the current active slot pointers against their game counterparts
	 */
	private static function refreshActivePointers() : Void {

		//UtilsBase.PrintChatText( "active: pr " + character.GetStat(Const.e_PrimaryActiveAegisStat, 2) + ", se " + + character.GetStat(Const.e_SecondaryActiveAegisStat, 2) + ", sh " + character.GetStat(Const.e_ShieldActiveAegisStat, 2) );
		
		groups.primary.activeSlot = equippedPositionBinds[ character.GetStat(Const.e_PrimaryActiveAegisStat, 2) ];
		groups.secondary.activeSlot = equippedPositionBinds[ character.GetStat(Const.e_SecondaryActiveAegisStat, 2) ];
		groups.shield.activeSlot = aegisIdBinds[ shieldTypeToAegisId[character.GetStat(Const.e_ShieldActiveAegisStat, 2)] ];
		
		// if the post-swap catchup timer isn't running, immediately sync the selected with the active
		if ( timers.swapCatchup == undefined ) {
			syncSelectedWithActive();
		}
		
	}
	
	/**
	 * syncs the current selected slot pointers with their active counterparts
	 */
	private static function syncSelectedWithActive() : Void {
		
		for ( var s:String in groups ) {
			if ( groups[s].selectedSlot != groups[s].activeSlot ) {
				
				var fromSlotID:String = groups[s].selectedSlot.id;
				groups[s].selectedSlot = groups[s].activeSlot;
				SignalSelectionChanged.Emit( s, groups[s].selectedSlot.id, fromSlotID );
			}
		}
		
	}
	
	/**
	 * updates the xp values for a given aegis item id
	 * 
	 * @param	tokenID
	 * @param	value
	 */
	private static function updateAegisItemXP( aegisID:Number ) : Void {

		var slot:AegisServerSlot = aegisItems[ aegisID ].slot;
		
		// only proceed if update is for a known aegis item, and the data is available
		if ( slot == undefined ) return;
		
		// TODO: apply a throttle for fetching xp on a per item basis, to avoid tooltip-scraping spam

		var rawXP:Number = character.GetTokens( aegisID );
		var percentXP:Number = 0;
		
		// only proceed if token data is available (this avoids the game issue where items are populated but tokens haven't been populated yet, such as when zoning)
		if ( rawXP == 0 && slot.item.m_Rank > 0 ) return;
		
		var xpString:String = TooltipDataProvider.GetInventoryItemTooltip( slot.inventoryID, slot.position ).m_Descriptions[2];
		
		// can't let indexOf run against undefined, it halts the game
		if ( xpString.length > 0 ) {

			// get the first occurence of %
			var endPos:Number = xpString.indexOf('%');
			
			if ( LDBFormat.GetCurrentLanguageCode() == 'de' ) endPos--;	// german client has a space between number and %

			// work backwards until we hit the end of the html tag that wraps the percent text
			for ( var startPos:Number = endPos; startPos >= 0; startPos-- ) {
				
				var char:String = xpString.charAt(startPos);
				
				// not a number sequence
				if ( char == ' ' || char == '>' ) {
					break;
				}
			}

			percentXP = Number(xpString.substring(++startPos, endPos));
			//xp = Math.floor( Number(xpString.substring(++startPos, endPos)) );
		}
		
		slot.xpRaw = rawXP;
		slot.xpPercent = percentXP;
		
		// signal an update
		SignalXPChanged.Emit( slot.group.id, slot.id );
	}
	
	/**
	 * returns a specified slot
	 * 
	 * @param	groupID
	 * @param	slotID
	 * @return
	 */
	public static function getSlot( groupID:String, slotID:String ) : AegisServerSlot {
		return groups[groupID].slots[slotID];
	}

	/**
	 * returns a specified group
	 * 
	 * @param	groupID
	 * @return
	 */
	public static function getGroup( groupID:String ) : AegisServerGroup {
		return groups[groupID];
	}
	
	/**
	 * listens for aegis system or shield system to become unlocked
	 * 
	 * @param	tag
	 */
	private static function loreTagAddedHandler( tag:Number ) : Void {
		
		switch ( tag ) {
			
			case Const.e_AegisUnlockAchievement: SignalAegisSystemUnlocked.Emit( tag ); break;
			case Const.e_AegisShieldUnlockAchievement: SignalShieldSystemUnlocked.Emit( tag ); break;
			
		}

	}

	
	/*
	 * internal variables
	 */

	private static var character:Character;
	private static var equipped:Inventory;
	private static var backpack:Inventory;
	
	private static var aegisItems:Object;
	
	private static var equippedPositionBinds:Object;
	private static var aegisIdBinds:Object;
	private static var knownLocationBinds:Object;
	
	private static var shieldTypeToAegisId:Object;
	
	private static var nextPrevMap:Object;
	private static var multiSelectGroups:Object;
	
	private static var timers:Object;
	
	
	/*
	 * properties
	 */

	private static var _running:Boolean;
	public static function get running() : Boolean { return Boolean(_running); }

	public static var groups:Object;
	
	public static var SignalSelectionChanged:Signal;
	public static var SignalItemChanged:Signal;
	public static var SignalXPChanged:Signal;
	
	public static var SignalAegisSystemUnlocked:Signal;
	public static var SignalShieldSystemUnlocked:Signal;

	public static function get aegisSystemUnlocked() : Boolean { return !LoreBase.IsLocked(Const.e_AegisUnlockAchievement); }
	public static function get shieldSystemUnlocked() : Boolean { return !LoreBase.IsLocked(Const.e_AegisShieldUnlockAchievement); }
}