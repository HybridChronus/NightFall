class SeqEvent_DialogAnswer extends SequenceEvent;

var() name Parameter;
var() byte CorrectAnswerID;

defaultproperties
{
	Parameter=Looly
	CorrectAnswerID=1
	ObjName="Dialog Answer Event"
	ObjCategory="NF"
	MaxTriggerCount=0
	OutputLinks(0)=(LinkDesc="Right Answer")
	OutputLinks(1)=(LinkDesc="Wrong Answer")

	bAutoActivateOutputLinks=false
}
