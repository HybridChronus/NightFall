/**If performance should lower try this with KActorFromStatic and make all our Kactors static **/
class NFKActor extends KActor implements (InteractableInterface)
	ClassGroup(NF)
	placeable;

var(NF) const string DescriptionText;
var(NF) const InterActableType ObjectType;
var(NF) const archetype NFItem ItemNeededToInteract;
/** Velocity at which we get Killed **/
var(NF) const float DestroyVelocity;

var float lastSoundTime, lastHitTime;

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
	/*local PhysicalMaterial PhysMat1, PhysMat2;
	local RigidBodyContactInfo Contact;
	local float newVelocity;
	super.RigidBodyCollision(HitComponent, OtherComponent, Collision, ContactIndex);
	if(OtherComponent != none && Collision.ContactInfos.Length > 0)
	{
		Contact = Collision.ContactInfos[0];
		PhysMat1 = Contact.PhysMaterial[0];
		PhysMat2 = Contact.PhysMaterial[1];
		newVelocity=VSize(Collision.TotalNormalForceVector)*HitComponent.BodyInstance.GetBodyMass();
		`log("Velocity:"@newVelocity@",Pos:"@Contact.ContactPosition);
		if(PhysMat1 != none)
		{
			if(newVelocity > DestroyVelocity)
			{
				DestroyedVelocity(PhysMat1,newVelocity, Contact.ContactPosition);
				return;
			}
			PlayHitSoundByVelocity(PhysMat1,newVelocity, Contact.ContactPosition);
		}
		if(PhysMat2 != none)
		{
			if(newVelocity > DestroyVelocity)
			{
				DestroyedVelocity(PhysMat2,newVelocity, Contact.ContactPosition);
				return;
			}
			PlayHitSoundByVelocity(PhysMat2,newVelocity, Contact.ContactPosition);
		}
	}
	if(OtherComponent != none && OtherComponent.Owner != none)
		AddDamage(OtherComponent.Owner,newVelocity);*/
}

event Bump(Actor Other, PrimitiveComponent OtherComp, Vector HitNormal)
{
	if(CollisionComponent != none)
		AddDamage(Other,VSize(CollisionComponent.BodyInstance.GetUnrealWorldVelocity())*CollisionComponent.BodyInstance.GetBodyMass());
}

function AddDamage(Actor target, float newvelocity)
{
	if(target != none && newvelocity > 250)
		target.TakeDamage(newvelocity*0.00001,none,vect(0,0,0),vect(0,0,0),class'DamageType_Impact');
}

simulated function DestroyedVelocity(PhysicalMaterial PhysMat, float newVelocity, Vector position)
{
	local NF_PhysicalMaterialProperty PhysicalProperty;
	PhysicalProperty = NF_PhysicalMaterialProperty(PhysMat.GetPhysicalMaterialProperty(class'NF_PhysicalMaterialProperty'));
	if (PhysicalProperty != None)
	{
		if(PhysicalProperty.DestroyedSound != none)
			PlaySound(PhysicalProperty.DestroyedSound, false, true,,position, true);
		if(PhysicalProperty.DestroyedParticles != none)
			WorldInfo.MyEmitterPool.SpawnEmitter(PhysicalProperty.DestroyedParticles,Location);
	}
	Destroy();
}


DefaultProperties
{
	DescriptionText = "SimpleStone";
	ObjectType = Carryable;
	bCanStepUpOn=true
	DestroyVelocity=15000

	bCollideActors=true
    bCollideWorld=true
    bBlockActors=true

	bPawnCanBaseOn=true
	//bNoEncroachCheck=False
	Begin Object Name=StaticMeshComponent0
		ScriptRigidBodyCollisionThreshold=0.001
		bNotifyRigidBodyCollision=true
		BlockNonZeroExtent=True
		BlockRigidBody=true
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE,Pawn=true,DeadPawn=true,Untitled3=True,Clothing=True,ClothingCollision=True)
	End Object
}