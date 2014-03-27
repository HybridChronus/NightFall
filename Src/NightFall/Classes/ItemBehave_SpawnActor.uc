class ItemBehave_SpawnActor extends ItemBehavior;

var(NF) const archetype Actor actorToSpawn;
var(NF) const float DistanceToSpawnItemInFront;

function Used(NFPlayerController User, NFItem Instigator)
{
	if(User != none && User.bePawn != none && User.bePawn.NFInventoryManager != none)
	{
		User.bePawn.NFInventoryManager.RemoveInventory(Instigator);
		User.Spawn(actorToSpawn.Class,User,,User.outWorldOrigin+(User.outWorldDirection*DistanceToSpawnItemInFront),,actorToSpawn,true);
	}
}


DefaultProperties
{
	DistanceToSpawnItemInFront=150
}