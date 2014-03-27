class SeqAct_DisplayMessage extends SequenceAction;

var() const string Text;
var() const Texture2D Icon;
var() const MessageType TypeOfMessage;
var() const float DisplayLength;

event Activated()
{
	local SeqVar_Object obj;
	local NFPawn bePawn;
	local NFPlayerController bePC;

	foreach LinkedVariables(class'SeqVar_Object', obj)
	{
		bePawn = NFPawn(obj.GetObjectValue());
		if(bePawn != none && bePawn.NFController != none && NFHud(bePawn.NFController.myHUD) != none)
		{
			NFHud(bePawn.NFController.myHUD).AddMessage(TypeOfMessage,Text,Icon,DisplayLength);
		}
		else
		{
			bePC = NFPlayerController(obj.GetObjectValue());
			if(bePC != none && NFHud(bePC.myHUD) != none)
			{
				NFHud(bePC.myHUD).AddMessage(TypeOfMessage,Text,Icon,DisplayLength);
			}
		}

	}
}

defaultproperties
{
	ObjName="Display Message"
	ObjCategory="NF"

	DisplayLength=5
	bCallHandler=false
	InputLinks(0)=(LinkDesc="In")
	OutputLinks(0)=(LinkDesc="Out")
}