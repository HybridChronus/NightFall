class ItemBehave_AddItems extends ItemBehavior;

struct ItemPack
{
	var(NF) const int Amount;
	var(NF) const archetype NFItem Item;

	structdefaultproperties
	{
		Amount=1
	}
};

var(NF) const archetype array<ItemPack> ItemsToAdd;

var(NF) const bool RemoveAfterUse;

function Used(NFPlayerController User, NFItem Instigator)
{
	local ItemPack tempItem;
	if(User != none && User.bePawn != none && User.bePawn.NFInventoryManager != none)
	{
		if(RemoveAfterUse)
			User.bePawn.NFInventoryManager.RemoveInventory(Instigator);
		foreach ItemsToAdd(tempItem)
		{
			if(User.bePawn.NFInventoryManager.CheckInventorySize(tempItem.Item))
				User.bePawn.NFInventoryManager.AddInventory(tempItem.Item,tempItem.Amount);
		}
	}
}

DefaultProperties
{
	RemoveAfterUse=false
}