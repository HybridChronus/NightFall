class SeqAct_ModifyHorrorMultiplier extends SequenceAction;

var() float HorrorAmount;
var float Result;

/**
* When activated this node triggers the DH_PlayerController’s modifyExp()
**/
event Activated()
{
	local SeqVar_Object obj;
	local NFPawn bePawn;
	local NFPlayerController bePC;

	foreach LinkedVariables(class'SeqVar_Object', obj)
	{
		bePawn = NFPawn(obj.GetObjectValue());
		if(bePawn != none)
		{
			bePawn.HorrorMultiplier+=HorrorAmount;
			Result=bePawn.HorrorMultiplier;
		}
		else
		{
			bePC = NFPlayerController(obj.GetObjectValue());
			if(bePC != none)
			{
				bePawn = NFPawn(bePC.Pawn);
				bePawn.HorrorMultiplier+=HorrorAmount;
				Result=bePawn.HorrorMultiplier;
			}
		}
	}
}

defaultproperties
{
	ObjName="Modify Horrormultiplier"
	ObjCategory="NF"
	bCallHandler=false
	InputLinks(0)=(LinkDesc="In")
	
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(1)=(ExpectedType=class'SeqVar_Float',bWriteable = false, LinkDesc="HorrorAmount",PropertyName=HorrorAmount)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Float',bWriteable = true, LinkDesc="Result",PropertyName=Result)
}