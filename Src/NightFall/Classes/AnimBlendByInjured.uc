class AnimBlendByInjured extends UDKAnimBlendBase
	dependson(NFPawn)
	hidecategories(AnimNodeBlendList, AnimNodeBlendBase, AnimNode, Morph);

var Pawn Owner;
var int OldActiveChildIndex;
var(NF) const float InjuredValue;

simulated event OnInit()
{
	Super.OnInit();

	OldActiveChildIndex = ActiveChildIndex;
	
	if ((SkelComponent == None) || (Pawn(SkelComponent.Owner) == None))
		return;
	
	Owner = Pawn(SkelComponent.Owner);
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

	if (float(Owner.Health)/float(Owner.HealthMax) < InjuredValue)
		DesiredChild = 1;
	else
		DesiredChild = 0;
	
	if (ActiveChildIndex != DesiredChild)
		SetActiveChild(DesiredChild, BlendTime);
}

// EDITOR ONLY
function SetSlaveActiveChild()
{
	local AnimBlendByInjured Node;

	`log(self$"::SetSlaveActiveChild() => OldActiveChildIndex = "$OldActiveChildIndex$", ActiveChildIndex= "$ActiveChildIndex);
	OldActiveChildIndex = ActiveChildIndex;

	foreach SkelComponent.AllAnimNodes(class'AnimBlendByInjured', Node)
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
	InjuredValue=0.3
	CategoryDesc="NF"
	Children(0)=(Name="Healthy",Weight=1.0)
	Children(1)=(Name="Injured")
	bFixNumChildren=true
	bTickAnimInScript=true
	bPlayActiveChild=true
	bCallScriptEventOnInit=true
	NodeName="BlendByInjured"
}