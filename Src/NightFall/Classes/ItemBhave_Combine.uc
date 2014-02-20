class ItemBhave_Combine extends ItemBehave_AddItems;

/** Items we need to combine the new item or items we get **/
var(NF) const archetype array<NFItem> ItemsNeededForCombination;

function Used(NFPlayerController User, NFItem Instigator)
{
	local ItemPack tempItemPack;
	local NFItem tempItem;
	if(User != none && User.bePawn != none && User.bePawn.NFInventoryManager != none && GotAllItemsWeNeed(User))
	{
		if(RemoveAfterUse)
		{
			foreach ItemsNeededForCombination(tempItem)
				User.bePawn.NFInventoryManager.RemoveInventory(tempItem);
		}
		foreach ItemsToAdd(tempItemPack)
		{
			if(User.bePawn.NFInventoryManager.CheckInventorySize(tempItemPack.Item))
				User.bePawn.NFInventoryManager.AddInventory(tempItemPack.Item,tempItemPack.Amount);
		}
	}
}

function bool GotAllItemsWeNeed(NFPlayerController User)
{
	local NFItem tempItem;
	foreach ItemsNeededForCombination(tempItem)
		if(User.bePawn.NFInventoryManager.HasItem(tempItem) <= 0) return false;
	return true;
}


DefaultProperties
{
}