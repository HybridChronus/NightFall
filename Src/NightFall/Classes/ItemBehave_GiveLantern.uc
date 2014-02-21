class ItemBehave_GiveLantern extends ItemBehavior;

function Used(NFPlayerController User, NFItem Instigator)
{
	if(User != none && User.bePawn != none)
	{
		User.bePawn.NFInventoryManager.RemoveInventory(Instigator);
		User.bePawn.hasLantern=true;
	}
}

DefaultProperties
{
}
