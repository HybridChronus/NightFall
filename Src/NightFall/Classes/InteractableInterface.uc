/*
 *Switch to a Dragable one by Calculating his mass :D 
 */

interface InteractableInterface;

enum InterActableType
{
	Carryable,
	OpenAble,
	Pickup,
	ObserveAble,
};

function string GetDescriptionText();

function InterActableType GetType();

function bool CanItemInteract(NFPlayerController User);