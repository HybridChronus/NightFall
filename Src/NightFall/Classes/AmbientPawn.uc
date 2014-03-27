class AmbientPawn extends NFAIPawn implements (InteractableInterface);

var(NF) const string DescriptionText;

function bool CanItemInteract(NFPlayerController User)
{
	return true;
}

function string GetDescriptionText()
{
	return DescriptionText;
}

function InterActableType GetType()
{
	return ObserveAble;
}

function Poke(NFPawn newInstigator)
{
	TriggerEventClass(class'SeqEvent_Observed', Instigator);
}

DefaultProperties
{
	DescriptionText = "Bunny";
	SupportedEvents.Add(class'SeqEvent_Observed')


	ControllerClass=class'NightFall.NFAmbientAIController'
}
