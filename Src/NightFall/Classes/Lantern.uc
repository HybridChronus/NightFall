class Lantern extends KAssetSpawnable
	ClassGroup(NF)
    AutoExpandCategories(NF)
	placeable;

var(NF) const PointLightComponent LanternLight;
var(NF) const name LightAttachmentPoint;
var(NF) const AudioComponent LanternSounds;
var(NF) const ParticleSystemComponent Particles;
var(NF) const int Test;

simulated function PostBeginPlay()
{
	if(SkeletalMeshComponent != none && SkeletalMeshComponent.GetSocketByName(LightAttachmentPoint) != none)
	{
		if(LanternLight != none) SkeletalMeshComponent.AttachComponentToSocket(LanternLight,LightAttachmentPoint);
		if(Particles != none) SkeletalMeshComponent.AttachComponentToSocket(Particles,LightAttachmentPoint);
	}
//
	 //SkeletalMeshComponent.SetHasPhysicsAssetInstance(true,true);

	 SkeletalMeshComponent.InitRBPhys();
	 //SkeletalMeshComponent.PhysicsWeight = 1.0;
	 SkeletalMeshComponent.PhysicsAssetInstance.SetAllBodiesFixed(true);
	 SkeletalMeshComponent.bEnableFullAnimWeightBodies = true;
	 SkeletalMeshComponent.PhysicsAssetInstance.SetFullAnimWeightBonesFixed(false, SkeletalMeshComponent);
	// SkeletalMeshComponent.SetBlockRigidBody(true);

	 SkeletalMeshComponent.WakeRigidBody();

	 if(LanternSounds != none) LanternSounds.VolumeMultiplier = 0;
}

function SetTotallyHidden(bool bNewHidden, float BlendTime = 0.5)
{
	if(bNewHidden)
		SetTimer(BlendTime,false,'HideTimer');
	else
	{
		if(IsTimerActive('HideTimer')) ClearTimer('HideTimer');
		SetHidden(bNewHidden);
		if(SkeletalMeshComponent != none) SkeletalMeshComponent.SetHidden(bNewHidden);
		if(LanternLight != none) LanternLight.SetEnabled(!bNewHidden);
		if(LanternSounds != none) LanternSounds.FadeIn(0.5,0);
		if(Particles != none) Particles.SetActive(!bNewHidden);
	}
}

function HideTimer()
{
	SetHidden(true);
	if(SkeletalMeshComponent != none) SkeletalMeshComponent.SetHidden(true);
	if(LanternLight != none) LanternLight.SetEnabled(false);
	if(LanternSounds != none) LanternSounds.FadeOut(0.5,0);
	if(Particles != none) Particles.SetActive(false);
}

DefaultProperties
{
	bMovable = True
	bHardAttach=true
	bBlockActors=false

	Begin Object Name=KAssetSkelMeshComponent
		CollideActors = False
		BlockActors = False
		BlockRigidBody = True
		BlockZeroExtent = False
		BlockNonZeroExtent = False
		bCastDynamicShadow = True
		LightingChannels=(Dynamic=True,Static=True)
		bHasPhysicsAssetInstance = True
		bEnableFullAnimWeightBodies = True
		RBChannel = RBCC_Pawn
		RBCollideWithChannels = (Default = True, GameplayPhysics = True)
		//bEnableFullAnimWeightBodies=true
		bUpdateKinematicBonesFromAnimation=true
	End Object

	begin object Class=AudioComponent Name=LanternAudioCOmponent
		bAutoPlay=true
		bAlwaysPlay=true
		bShouldRemainActiveIfDropped=true
	end object
	LanternSounds=LanternAudioCOmponent
	Components.Add(LanternAudioCOmponent)

	Begin Object Class=PointLightComponent Name=LightComp
		Brightness=2
	End Object
	LanternLight=LightComp
	Components.Add(LightComp)

	Begin Object Class=ParticleSystemComponent Name=ParticleComp
	End Object
	Particles = ParticleComp
	Components.Add(ParticleComp)
}