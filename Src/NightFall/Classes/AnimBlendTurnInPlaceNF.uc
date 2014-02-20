class AnimBlendTurnInPlaceNF extends UDKAnimBlendBase
	dependson(NFPawn)
	hidecategories(AnimNodeBlendList, AnimNodeBlendBase, AnimNode, Morph);

var NFPawn Owner;
var int oldLegsTurning;
var int OldActiveChildIndex;

simulated event OnInit()
{
	Super.OnInit();

	OldActiveChildIndex = ActiveChildIndex;

	// Call me paranoid, but I must insist on checking for both of these on init
	if ((SkelComponent == None) || (NFPawn(SkelComponent.Owner) == None))
		return;
	
	Owner = NFPawn(SkelComponent.Owner);
	oldLegsTurning = 255;
}

simulated event TickAnim(float DeltaSeconds)
{
	if (Owner == None)
	{
		// EDITOR ONLY
		if (OldActiveChildIndex != ActiveChildIndex)
			SetSlaveActiveChild();
		return;
	}
	
	if (oldLegsTurning != Owner.LegsTurning)
	{
		if (Owner.LegsTurning == 0)
			SetActiveChild(0, BlendTime);
		else
			SetActiveChild((Owner.LegsTurning < 0 ? 1 : 2), BlendTime);
		oldLegsTurning = Owner.LegsTurning;
	}
}

// EDITOR ONLY
function SetSlaveActiveChild()
{
	local AnimBlendTurnInPlaceNF ByTurnInPlace;

	`log(self$"::SetSlaveActiveChild() => OldActiveChildIndex = "$OldActiveChildIndex$", ActiveChildIndex= "$ActiveChildIndex);
	OldActiveChildIndex = ActiveChildIndex;

	foreach SkelComponent.AllAnimNodes(class'AnimBlendTurnInPlaceNF', ByTurnInPlace)
	{
		if (ByTurnInPlace != self)
		{
			ByTurnInPlace.SetActiveChild(ActiveChildIndex, ByTurnInPlace.BlendTime);
			ByTurnInPlace.OldActiveChildIndex = ActiveChildIndex;
		}
	}
}

defaultproperties
{
	CategoryDesc="NF"
	Children(0)=(Name="Idle",Weight=1.0)
	Children(1)=(Name="Turn Left")
	Children(2)=(Name="Turn Right")
	bFixNumChildren=true
	bTickAnimInScript=true
	bPlayActiveChild=true
	bCallScriptEventOnInit=true
	NodeName="Turn In Place"
}