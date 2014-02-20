class SeqCond_HasItem  extends SequenceCondition;

var() const archetype NFItem  ItemToCheckFor;
var() const int AmountNeeded;
var Actor Player;


/**
Checks the player and activates the corresponding output.
*/
event Activated()
{
	local bool HasItem;

	if (NFPawn(Player) != None  && NFPawn(Player).NFInventoryManager != none) {
		HasItem = NFPawn(Player).NFInventoryManager.HasItem(ItemToCheckFor) >= AmountNeeded;
	}
	else if (NFPlayerController(Player) != None && NFPlayerController(Player).bePawn != None && NFPlayerController(Player).bePawn.NFInventoryManager != None) {
		HasItem = NFPlayerController(Player).bePawn.NFInventoryManager.HasItem(ItemToCheckFor) >= AmountNeeded;
	}
	else {
		ScriptLog(Self $ " - No player specified!");
	}
	
	OutputLinks[HasItem ? 0 : 1].bHasImpulse = true;
}

defaultproperties
{
	ObjName         = "NF"
	ObjCategory     = "Has Item?"
	AmountNeeded    = 1

	OutputLinks(0) = (LinkDesc="Yes")
	OutputLinks(1) = (LinkDesc="No")
	VariableLinks.Add((ExpectedType=Class'Engine.SeqVar_Object',LinkDesc="Player",PropertyName=Player,MaxVars=1))
}