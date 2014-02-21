class ObserveableMesh extends StaticMeshActor implements (InteractableInterface)
	ClassGroup(NF)
	placeable;

var(NF) const string DescriptionText;
var(NF) const InterActableType ObjectType;
var(NF) const archetype NFItem ItemNeededToInteract;

function bool CanItemInteract(NFPlayerController User)
{
	if(User != none)
	{
		if(ItemNeededToInteract != none )
		{
			if(User.bePawn != none && User.bePawn.NFInventoryManager != none && User.bePawn.NFInventoryManager.HasItem(ItemNeededToInteract) > 0 && User.AttachedItem != none && User.AttachedItem.InvItem != none && User.AttachedItem.InvItem.ItemName == ItemNeededToInteract.ItemName)
			{
				User.bePawn.NFInventoryManager.RemoveInventory(User.AttachedItem.InvItem,1);
				return true;
			}
			if(NFHud(User.myHUD) != none)
			{
				if(User.AttachedItem != none && User.AttachedItem.InvItem != none)
					NFHud(User.myHUD).AddMessage(MESS_Hint,"That wont work with a"@User.AttachedItem.InvItem.ItemName);
				else
					NFHud(User.myHUD).AddMessage(MESS_Hint,"I need an item to get this done");
			}
		}
		User.DetachItem();
	}

	if(ItemNeededToInteract != none )
		return false;
	else
		return true;
}

function string GetDescriptionText()
{
	return DescriptionText;
}

function InterActableType GetType()
{
	return ObjectType;
}

function Observed(NFPawn Observer)
{
	TriggerEventClass(class'SeqEvent_Observed',Observer);
}

DefaultProperties
{
	DescriptionText = "Book full of Text";
	ObjectType = ObserveAble;
	SupportedEvents.Add(class'SeqEvent_Observed')
}