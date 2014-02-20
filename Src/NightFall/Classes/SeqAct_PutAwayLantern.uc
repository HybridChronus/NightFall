class SeqAct_PutAwayLantern extends SequenceAction;

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
				if(!bePawn.NFController.bLanternOut)
					bePawn.NFController.TakeOutLantern();
			else
			{
				bePC = NFPlayerController(obj.GetObjectValue());
				if(bePC != none && !bePC.bLanternOut)
					bePC.TakeOutLantern();
			}
		}
	}
	else if(InputLinks[1].bHasImpulse)
	{
		foreach LinkedVariables(class'SeqVar_Object', obj)
		{
			bePawn = NFPawn(obj.GetObjectValue());
			if(bePawn != none && bePawn.NFController != none)
				if(bePawn.NFController.bLanternOut)
					bePawn.NFController.TakeOutLantern();
			else
			{
				bePC = NFPlayerController(obj.GetObjectValue());
				if(bePC != none && bePC.bLanternOut)
					bePC.TakeOutLantern();
			}
		}
	}
}

defaultproperties
{
	ObjName="Put Away/Out Lantern"
	ObjCategory="NF"
	bCallHandler=false
	InputLinks(0)=(LinkDesc="Put Out")
    InputLinks(1)=(LinkDesc="Put Away")
	OutputLinks(0)=(LinkDesc="Out")
}