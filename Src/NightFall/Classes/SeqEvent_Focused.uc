class SeqEvent_Focused extends SequenceEvent;

DefaultProperties
{
	ObjName="Focus" 
	ObjCategory="NF"

	MaxTriggerCount=0
	OutputLinks(0)=(LinkDesc="GotFocus")
	OutputLinks(1)=(LinkDesc="FullFocus")
	OutputLinks(2)=(LinkDesc="LostFocus")

	bPlayerOnly=false
}
