class SeqAct_RemoveItem extends SequenceAction;

var() const archetype NFItem ItemToRemove;
var() const int Amount;

event Activated()
{
	local SeqVar_Object obj;
	local NFPawn bePawn;
	local NFPlayerController bePC;

	foreach LinkedVariables(class'SeqVar_Object', obj)
	{
		bePawn = NFPawn(obj.GetObjectValue());
		if(ItemToRemove != none && bePawn != none && bePawn.NFInventoryManager != none)
		{
			bePawn.NFInventoryManager.RemoveInventory(ItemToRemove,Amount);
		}
		else
		{//
			bePC = NFPlayerController(obj.GetObjectValue());
			if(ItemToRemove != none && bePC != none && bePC.bePawn != none && bePC.bePawn.NFInventoryManager != none)
			{
				bePC.bePawn.NFInventoryManager.RemoveInventory(ItemToRemove,Amount);
			}
		}

	}
}

defaultproperties
{
	Amount=1;
	ObjName="Remove Item"
	ObjCategory="NF"
	bCallHandler=false
	InputLinks(0)=(LinkDesc="In")
	OutputLinks(0)=(LinkDesc="Out")
}