class ItemBehavior extends Object
	hidecategories(Object)
	editinlinenew;

function Used(NFPlayerController User, NFItem Instigator)
{
	if(User != none && User.bePawn != none && User.bePawn.NFInventoryManager != none)
	{
		User.bePawn.NFInventoryManager.RemoveInventory(Instigator);
		`log(Instigator.GetToolTip()@", was used");
	}
}

DefaultProperties
{
}