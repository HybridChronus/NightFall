class ItemBehave_HealthPotion extends ItemBehavior;

var(NF) float PercentofHealthTOFillUp;

function Used(NFPlayerController User, NFItem Instigator)
{
	if(User != none && User.bePawn != none && User.bePawn.NFInventoryManager != none)
	{
		User.bePawn.NFInventoryManager.RemoveInventory(Instigator);
		User.bePawn.Health = FClamp(User.bePawn.Health + (User.bePawn.HealthMax*PercentofHealthTOFillUp),0,User.bePawn.HealthMax);
	}
}

DefaultProperties
{
	PercentofHealthTOFillUp=0.4
}
