class NFKAsset extends KAsset implements (InteractableInterface)
	ClassGroup(NF)
	placeable;

var(NF) const string DescriptionText;
var(NF) const InterActableType ObjectType;
var(NF) const archetype NFItem ItemNeededToInteract;

function bool CanItemInteract(NFPlayerController User)
{
	if(User != none)
	{
		if(ItemNeededToInteract != none )
		{
			if(User.bePawn != none && User.bePawn.NFInventoryManager != none && User.bePawn.NFInventoryManager.HasItem(ItemNeededToInteract) > 0 && User.AttachedItem != none && User.AttachedItem.InvItem != none && User.AttachedItem.InvItem.ItemName == ItemNeededToInteract.ItemName)
			{
				User.bePawn.NFInventoryManager.RemoveInventory(User.AttachedItem.InvItem,1);
				return true;
			}
			if(NFHud(User.myHUD) != none)
			{
				if(User.AttachedItem != none && User.AttachedItem.InvItem != none)
					NFHud(User.myHUD).AddMessage(MESS_Hint,"That wont work with a"@User.AttachedItem.InvItem.ItemName);
				else
					NFHud(User.myHUD).AddMessage(MESS_Hint,"I need an item to get this done");
			}
		}
		User.DetachItem();
	}

	if(ItemNeededToInteract != none )
		return false;
	else
		return true;
}

function string GetDescriptionText()
{
	return DescriptionText;
}

function InterActableType GetType()
{
	return ObjectType;
}

simulated event RigidBodyCollision (PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent, const out CollisionImpactData Collision, int ContactIndex)
{
	super.RigidBodyCollision(HitComponent,OtherComponent,Collision,ContactIndex);
	if(OtherComponent.Owner != none)
		AddDamage(OtherComponent.Owner,VSize(Collision.TotalNormalForceVector),HitComponent.BodyInstance.GetBodyMass());
}

event Bump(Actor Other, PrimitiveComponent OtherComp, Vector HitNormal)
{
	if(CollisionComponent != none)
		AddDamage(Other,VSize(CollisionComponent.BodyInstance.GetUnrealWorldVelocity()),CollisionComponent.BodyInstance.GetBodyMass());
}

function AddDamage(Actor target, float newvelocity, float mass)
{
	if(target != none && newvelocity > 250)
		target.TakeDamage(newvelocity*0.00001*mass,none,vect(0,0,0),vect(0,0,0),class'DamageType_Impact');
}


DefaultProperties
{
	DescriptionText = "SimpleStone";
	ObjectType = Carryable;

	Begin Object Name=KAssetSkelMeshComponent
		ScriptRigidBodyCollisionThreshold=0.001
		bNotifyRigidBodyCollision=true
		BlockNonZeroExtent=True
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE,Pawn=true,DeadPawn=true,Untitled3=True,Clothing=True,ClothingCollision=True)
	End Object
}