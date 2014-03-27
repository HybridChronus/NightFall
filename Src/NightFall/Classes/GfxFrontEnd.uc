class GfxFrontEnd extends GFxMoviePlayer abstract;

var GFxObject RootMC, CursorMC;
var GfxFrontEnd NextMenu;
var Vector2D MouseCoords;

function SetMouseCoords(GFxObject LastCursorMC)
{
	MouseCoords.X = LastCursorMC.GetFloat("x");
	MouseCoords.Y = LastCursorMC.GetFloat("y");
}

function SetCursorPosition()
{
	CursorMC.SetFloat("x", MouseCoords.X);
	CursorMC.SetFloat("y", MouseCoords.Y);
}

function bool Start(optional bool StartPaused = false)
{
	local bool retVal;
	retVal = super.Start(StartPaused);
	Advance(0);

	RootMC = GetVariableObject("root");
	CursorMC = RootMC.GetObject("MenuCursor");
	SetCursorPosition();
	return retVal;
}

function LoadNextMenu(EventData data, class NextMenuClass)
{
	if (data.mouseIndex == 0)
	{
		//GfxFrontEnd
		NextMenu = GfxFrontEnd(new NextMenuClass);
		NextMenu.SetMouseCoords(CursorMC);
		NextMenu.LocalPlayerOwnerIndex = LocalPlayerOwnerIndex;
		NextMenu.Start();
		Close(false);
	}
}
//
DefaultProperties
{
	TimingMode=TM_Real
	bPauseGameWhileActive=false
	bCaptureInput=true
}