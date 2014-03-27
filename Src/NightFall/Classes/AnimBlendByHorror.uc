class AnimBlendByHorror extends UDKAnimBlendBase
	dependson(NFPawn)
	hidecategories(AnimNodeBlendList, AnimNodeBlendBase, AnimNode, Morph);

var NFPawn Owner;
var int OldActiveChildIndex;

/** WE need to stay over that value to blend to the next horror Stage **/
var(NF) const float HorrorStep, InsaneStep;

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
	
	if(Owner.Illnes > InsaneStep)
		DesiredChild = 2;
	else if(Owner.Illnes > HorrorStep)
		DesiredChild = 1;
	else
		DesiredChild = 0;
	
	if (ActiveChildIndex != DesiredChild)
		SetActiveChild(DesiredChild, BlendTime);
}

// EDITOR ONLY
function SetSlaveActiveChild()
{
	local AnimBlendByHorror Node;

	`log(self$"::SetSlaveActiveChild() => OldActiveChildIndex = "$OldActiveChildIndex$", ActiveChildIndex= "$ActiveChildIndex);
	OldActiveChildIndex = ActiveChildIndex;

	foreach SkelComponent.AllAnimNodes(class'AnimBlendByHorror', Node)
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
	HorrorStep=40
	InsaneStep=70

	CategoryDesc="NF"
	Children(0)=(Name="FeelWell",Weight=1.0)
	Children(1)=(Name="Horror")
	Children(2)=(Name="Insane")
	bFixNumChildren=true
	bTickAnimInScript=true
	bPlayActiveChild=true
	bCallScriptEventOnInit=true
	NodeName="BlendByHorror"
}