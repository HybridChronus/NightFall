interface FocusableInterface;

function Vector GetFocusPosition();
function GotFocus(NFPawn Focuser, float Percent);
function LostFocus(NFPawn Focuser);

function bool CanSeeMe();