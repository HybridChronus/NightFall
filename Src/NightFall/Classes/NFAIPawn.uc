class NFAIPawn extends UDKPawn
	ClassGroup(NF)
	placeable;

/** Weight for Calculating Footstep Sounds **/
var(NF) float Weight;

DefaultProperties
{
	Begin Object Name=CollisionCylinder
        CollisionHeight=+44.000000
    End Object
 //
    Begin Object Class=SkeletalMeshComponent Name=PawnSkeletalMesh
        HiddenGame=FALSE
        HiddenEditor=FALSE
    End Object
	Mesh=PawnSkeletalMesh
	Components.Add(PawnSkeletalMesh)

	ControllerClass=class'NightFall.NFAIController'
}