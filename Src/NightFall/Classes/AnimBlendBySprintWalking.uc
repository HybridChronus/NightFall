                                                   class AnimBlendBySprintWalking extends UDKAnimBlendBase
	dependson(NFPawn)
	hidecategories(AnimNodeBlendList, AnimNodeBlendBase, AnimNode, Morph);

var NFPawn Owner;
var int OldActiveChildIndex;

simulated event OnInit()
{
	Super.OnInit();  

	OldActiveChildIndex = ActiveChildIndex;
	
	if ((SkelComponent == None) || (NFPawn(SkelComponent.Owner) == None))
		return;
	
	Owner = NFPawn(SkelComponent.Owner);
}

simulated event TickAnim(float DeltaSeconds)
{
	local int DesiredChild;
	
	if (Owner == None)
	{
		if (OldActiveChildIndex != ActiveChildIndex)
			SetSlaveActiveChild();
		return;
	}

	if (Owner.bIsSprinting)
		DesiredChild = 1;
	else
		DesiredChild = 0;
	
	if (ActiveChildIndex != DesiredChild)
		SetActiveChild(DesiredChild, BlendTime);
}

// EDITOR ONLY
function SetSlaveActiveChild()
{
	local AnimBlendBySprintWalking Node;

	`log(self$"::SetSlaveActiveChild() => OldActiveChildIndex = "$OldActiveChildIndex$", ActiveChildIndex= "$ActiveChildIndex);
	OldActiveChildIndex = ActiveChildIndex;

	foreach SkelComponent.AllAnimNodes(class'AnimBlendBySprintWalking', Node)
	{
		if (Node != self)
		{
			Node.SetActiveChild(ActiveChildIndex, Node.BlendTime);
			Node.OldActiveChildIndex = ActiveChildIndex;
		}
	}
}

defaultproperties
{
	CategoryDesc="NF"
	Children(0)=(Name="Walk",Weight=1.0)
	Children(1)=(Name="Run")
	bFixNumChildren=true
	bTickAnimInScript=true
	bPlayActiveChild=true
	bCallScriptEventOnInit=true
	NodeName="Walk / Run"
}