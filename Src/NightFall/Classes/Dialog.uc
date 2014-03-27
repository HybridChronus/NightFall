class Dialog extends Object
	ClassGroup(NF)
    AutoExpandCategories(NF);

struct DialogStruct
{
	var(NF) float DisplayLength;
	var(NF) SoundCue SoundToPlay;
	var(NF) string Message;
	var(NF) float Delay;

	var(NF) bool TriggerKismet;
	var(NF) float TriggerKismetTime;
	var(NF) name KismetCommand;

	var(NF) array<string> Answers;

	structdefaultproperties
	{
		Delay=0;
		Message="Hello Dude";
		DisplayLength=4
		TriggerKismet=false
	}
};
//
var(NF) array<DialogStruct> FullDialog;
var(NF) archetype Notes NoteToAddToPlayer;
var(NF) bool LogTextIfNoNoteSpecified;

var float TimeRunnedComplete;
var float TimeRunnedThisDialogStep;
var bool  SoundWasPlayed;
var byte  AnswerSelected;

DefaultProperties
{
	AnswerSelected=0
}