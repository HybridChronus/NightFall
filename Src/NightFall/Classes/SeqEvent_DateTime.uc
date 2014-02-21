class SeqEvent_DateTime extends SequenceEvent;

/** 0 = All Hours **/
var() int OnSpecificHour;

var DateTime Date;

DefaultProperties
{
	OnSpecificHour=0
	ObjName="Date Time"
	ObjCategory="NF"
	MaxTriggerCount=0
	VariableLinks(1)=(ExpectedType=class'SeqVar_DateTime',LinkDesc="DateTime",bWriteable=TRUE,PropertyName=Date)
	OutputLinks(0)=(LinkDesc="FullHour")
}
