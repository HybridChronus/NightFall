class NFAmbientTameableAIController extends NFAmbientAIController;

auto state Follow
{
Begin:
    Target = GetALocalPlayerController().Pawn;
    //Target is an Actor variable defined in my custom AI Controller.
    //Of course, you would normally verify that the Pawn is not None before proceeding.
 
    MoveToward(Target, Target, 128);
 
    goto 'Begin';
}

DefaultProperties
{
}
