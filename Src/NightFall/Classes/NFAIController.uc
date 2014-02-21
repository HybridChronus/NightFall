class NFAIController extends AIController;

var Pawn Target;

event Possess(Pawn inPawn, bool bVehicleTransition)
{
    super.Possess(inPawn, bVehicleTransition);
    Pawn.SetMovementPhysics();
}
//
DefaultProperties
{
}