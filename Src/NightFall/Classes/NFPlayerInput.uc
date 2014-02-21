class NFPlayerInput extends UDKPlayerInput within NFPlayerController;

var bool  bHoldDuck;

exec function Jump()
{
	if (!IsMoveInputIgnored())
	{
		 if (bDuck>0)
		 {
		 	bDuck = 0;
		 	bHoldDuck = false;
		 }
		Super.Jump();
	}
}

simulated exec function Duck()
{
	if(Pawn!= none)
	{
		if (bHoldDuck)
		{
			bHoldDuck=false;
			bDuck=0;
			return;
		}
		bDuck=1;
		bHoldDuck = true;
	}
}

simulated exec function UnDuck()
{
	if (!bHoldDuck)
	{
		bDuck=0;
	}
}

DefaultProperties
{
}
