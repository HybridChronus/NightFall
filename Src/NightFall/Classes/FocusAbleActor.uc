class FocusAbleActor extends Trigger_PawnsOnly implements(FocusableInterface)
   ClassGroup(NF)
   AutoExpandCategories(NF)
   placeable;

var(NF) const Actor FocusedActor;
var(NF) const bool NeedsToBeVisible;

function Vector GetFocusPosition()
{
	if(FocusedActor != none)
		return FocusedActor.Location;
	return Location;
}

function GotFocus(NFPawn Focuser, float Percent)
{
	if(Percent > 0.85)
		TriggerEventClass(class'SeqEvent_Focused',Focuser,1);
	TriggerEventClass(class'SeqEvent_Focused',Focuser,0);
}

function LostFocus(NFPawn Focuser)
{
	TriggerEventClass(class'SeqEvent_Focused',Focuser,2);
}

function bool CanSeeMe()
{
	if(FocusedActor != none && NeedsToBeVisible)
		return (FocusedActor.PlayerCanSeeMe(true) || (WorldInfo.TimeSeconds-FocusedActor.LastRenderTime)<0.09);
	return true;
}

event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	local NFPawn BP;
	BP = NFPawn(Other);
	if(BP != none && BP.NFController != none)
	{
		BP.NFController.SetFocusObject(self);
	}
}

event UnTouch(Actor Other)
{
	local NFPawn BP;
	BP = NFPawn(Other);
	if(BP != none && BP.NFController != none && BP.NFController.lastFocusObject == self)
	{
		BP.NFController.SetFocusObject(none);
	}
}

event Destroyed()
{
	super.Destroyed();
	ClearAllTimers(self);
}

DefaultProperties
{
	NeedsToBeVisible=true
	SupportedEvents.Add(class'SeqEvent_Focused')
}