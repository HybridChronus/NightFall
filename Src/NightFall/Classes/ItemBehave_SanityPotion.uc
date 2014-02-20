class ItemBehave_SanityPotion extends ItemBehavior;

var(NF) float PercentofSanityToHeal;

function Used(NFPlayerController User, NFItem Instigator)
{
	if(User != none && User.bePawn != none && User.bePawn.NFInventoryManager != none)
	{
		User.bePawn.NFInventoryManager.RemoveInventory(Instigator);
		User.bePawn.Illnes = FClamp(User.bePawn.Illnes - (100*PercentofSanityToHeal),0,100);
	}
}

DefaultProperties
{
	PercentofSanityToHeal=0.4
}