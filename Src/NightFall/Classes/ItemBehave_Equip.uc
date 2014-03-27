class ItemBehave_Equip extends ItemBehavior;

var() const float DrawScale;
/**Pickup for that were beeing a reference **/
var(NF) const archetype NFPickup Pickup;

function Used(NFPlayerController User, NFItem Instigator)
{
	local NFPickup tempPickup;
	local Vector SpawnLoc;
	local Rotator SpawnRot;
	if(User != none && User.bePawn != none && User.Pawn.Mesh.GetSocketWorldLocationAndRotation(User.bePawn.WeaponAttachment,SpawnLoc,SpawnRot,0))
	{
		if(User.AttachedItem!=none)
			User.DetachItem();
		tempPickup = User.Spawn(Pickup.Class,User,,SpawnLoc,SpawnRot,Pickup,true);
		if(tempPickup != none)
		{
			tempPickup.SetBase(User.Pawn, spawnloc, User.Pawn.Mesh, User.bePawn.WeaponAttachment);
			tempPickup.SetHardAttach(true);
			User.Pawn.Mesh.AttachComponentToSocket(tempPickup.StaticMeshComponent,User.bePawn.WeaponAttachment);
			tempPickup.StaticMeshComponent.SetShadowParent(User.Pawn.Mesh);
			tempPickup.SetPhysics(PHYS_Interpolating);
			tempPickup.SetCollisionType(COLLIDE_NoCollision);
			tempPickup.SetCollision(false,false,true);
			tempPickup.SetDrawScale(DrawScale);
			tempPickup.StaticMeshComponent.SetScale(DrawScale);
		}

		User.AttachedItem=tempPickup;
	}
}

DefaultProperties
{
	DrawScale=1;
}