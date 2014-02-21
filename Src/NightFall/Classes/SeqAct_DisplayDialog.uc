class SeqAct_DisplayDialog extends SequenceAction;

var() const archetype Dialog DialogToPlay;

event Activated()
{
	local SeqVar_Object obj;
	local NFPawn bePawn;
	local NFPlayerController bePC;

	foreach LinkedVariables(class'SeqVar_Object', obj)
	{
		bePawn = NFPawn(obj.GetObjectValue());
		if(DialogToPlay != none && bePawn != none && bePawn.NFController != none && NFHud(bePawn.NFController.myHUD) != none)
		{
			NFHud(bePawn.NFController.myHUD).PlayDialog(DialogToPlay);
		}
		else
		{
			bePC = NFPlayerController(obj.GetObjectValue());
			if(DialogToPlay != none && bePC != none && NFHud(bePC.myHUD) != none)
			{
				NFHud(bePC.myHUD).PlayDialog(DialogToPlay);
			}
		}

	}
}

defaultproperties
{
	ObjName="Display Dialog"
	ObjCategory="NF"


	bCallHandler=false
	InputLinks(0)=(LinkDesc="In")
	OutputLinks(0)=(LinkDesc="Out")
}