class NFPickup extends NFKActor
	ClassGroup(NF)
	placeable;

/** Item that we should give owner on Pickup **/
var(NF) const archetype NFItem InvItem;

function bool PickUp(NFPawn Picker)
{
	TriggerEventClass(class'SeqEvent_Observed', Picker);
	if(ObjectType == PickUp)
	{ 
		if(InvItem != none) 
		{
			if(Picker != none && Picker.NFInventoryManager != none && Picker.NFInventoryManager.CheckInventorySize(InvItem))
			{
				Picker.NFInventoryManager.AddInventory(InvItem);
				LifeSpan=0;
				bTearOff=true;
				TornOff();
				Destroy();
				return true;
			}
		}
		else
		{
			LifeSpan=0;
			bTearOff=true;
			TornOff();
			Destroy();
		}
	}
	else if(ObjectType == ObserveAble)
	{
		return true;
	}
	return false;
}

function string GetDescriptionText()
{
	if(ObjectType == PickUp && InvItem != none)
		return InvItem.ItemName;
	return DescriptionText;
}


DefaultProperties
{
	DescriptionText = "Knife";
	ObjectType = Pickup;
	SupportedEvents.Add(class'SeqEvent_Observed')

	//bPawnCanBaseOn=false
	//bSafeBaseIfAsleep=false
	bNoDelete=false
	bStatic=false
}