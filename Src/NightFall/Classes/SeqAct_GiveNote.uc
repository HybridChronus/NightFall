// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class SeqAct_GiveNote extends SequenceAction;

var() const archetype Notes NoteToAdd;

event Activated()
{
	local SeqVar_Object obj;
	local NFPawn bePawn;
	local NFPlayerController bePC;

	foreach LinkedVariables(class'SeqVar_Object', obj)
	{
		bePawn = NFPawn(obj.GetObjectValue());
		if(NoteToAdd != none && bePawn != none && bePawn.NFInventoryManager != none)
		{
			bePawn.NFInventoryManager.AddNote(NoteToAdd);
		}
		else
		{
			bePC = NFPlayerController(obj.GetObjectValue());
			if(NoteToAdd != none && bePC != none && bePC.bePawn != none  && bePC.bePawn.NFInventoryManager != none)
			{
				bePC.bePawn.NFInventoryManager.AddNote(NoteToAdd);
			}
		}

	}
}

defaultproperties
{
	ObjName="Add Note"
	ObjCategory="NF"
	bCallHandler=false
	InputLinks(0)=(LinkDesc="In")
	OutputLinks(0)=(LinkDesc="Out")
}