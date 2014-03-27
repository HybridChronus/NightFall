// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class SeqAct_RemoveGiveLantern extends SequenceAction;

event Activated()
{
	local SeqVar_Object obj;
	local NFPawn bePawn;
	local NFPlayerController bePC;

	if(InputLinks[0].bHasImpulse)
	{
		foreach LinkedVariables(class'SeqVar_Object', obj)
		{
			bePawn = NFPawn(obj.GetObjectValue());
			if(bePawn != none && bePawn.NFController != none)
				if(bePawn.NFController.bLanternForbidden)
					bePawn.NFController.bLanternForbidden = false;
			else
			{
				bePC = NFPlayerController(obj.GetObjectValue());
				if(bePC != none && bePC.bLanternForbidden)
					bePC.bLanternForbidden = false;
			}
		}
	}
	else if(InputLinks[1].bHasImpulse)
	{
		foreach LinkedVariables(class'SeqVar_Object', obj)
		{
			bePawn = NFPawn(obj.GetObjectValue());
			if(bePawn != none && bePawn.NFController != none)
				if(!bePawn.NFController.bLanternForbidden)
					bePawn.NFController.bLanternForbidden = true;
			else
			{
				bePC = NFPlayerController(obj.GetObjectValue());
				if(bePC != none && !bePC.bLanternForbidden)
					bePC.bLanternForbidden = true;
			}
		}
	}
}

defaultproperties
{
	ObjName="Remove/Give Lantern"
	ObjCategory="NF"
	bCallHandler=false
	InputLinks(0)=(LinkDesc="Give")
    InputLinks(1)=(LinkDesc="Remove")
	OutputLinks(0)=(LinkDesc="Out")
}