class SeqAct_AddItem extends SequenceAction;

var() const archetype NFItem ItemToAdd;
var() const int Amount;

event Activated()
{
	local SeqVar_Object obj;
	local NFPawn bePawn;
	local NFPlayerController bePC;

	foreach LinkedVariables(class'SeqVar_Object', obj)
	{
		bePawn = NFPawn(obj.GetObjectValue());
		if(ItemToAdd != none && bePawn != none && bePawn.NFInventoryManager != none)
		{
			if(bePawn.NFInventoryManager.CheckInventorySize(ItemToAdd))
				bePawn.NFInventoryManager.AddInventory(ItemToAdd,Amount);
		}
		else
		{
			bePC = NFPlayerController(obj.GetObjectValue());
			if(ItemToAdd != none && bePC != none && bePC.bePawn != none && bePC.bePawn.NFInventoryManager != none)
			{
				if(bePC.bePawn.NFInventoryManager.CheckInventorySize(ItemToAdd))
					bePC.bePawn.NFInventoryManager.AddInventory(ItemToAdd,Amount);
			}
		}

	}
}

defaultproperties
{
	Amount=1;
	ObjName="Add Item"
	ObjCategory="NF"
	bCallHandler=false
	InputLinks(0)=(LinkDesc="In")
	OutputLinks(0)=(LinkDesc="Out")
}