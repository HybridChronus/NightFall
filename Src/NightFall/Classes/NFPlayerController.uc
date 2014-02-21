/**
 * Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
 */
class NFPlayerController extends UDKPlayerController
	config(Game);

struct LastInteractableObject
{
	var InteractableInterface Interactable;
	var TraceHitInfo HitInfo;
	var Vector HitLocation, StartLocation, HitNormal, TraceDirection;
};
/** Caches our Last Deproject from the Center of our Screen**/
var Vector outWorldOrigin, outWorldDirection;
var LastInteractableObject lastTracedObject;
var FocusableInterface lastFocusObject;

/**How far we have already interpolated into a focus target **/
var float LookAtLerp;
// are we focusing something?
var bool IsFocusing;

//is our inventory open? Or menu etc
enum enumPlayerUIState
{
	PS_GamePlay,
	PS_Inventory,
	PS_Notes,
	PS_Menu
};
//is our inventory open? Or menu etc
var enumPlayerUIState PlayerUIState;

//is our lantern outside
var bool bLanternOut;
//is our Lantern forbidden
var bool bLanternForbidden;
//are we pressing the r button?
var bool bCurrentlyRotating;
//HowMuch Time Our leftHandhasLeft to hold control
var float LeftHandTimer;
var Vector LeftHandTarget;
var NFPickup AttachedItem;

//Final PhysGrabber Weapon
var PhysGrabber PhysGrabber;

var Lantern Lantern;
var NFPawn bePawn; // ReferenceToOurPawn

function SetFocusObject(FocusableInterface newFocus)
{
	if(lastFocusObject != newFocus)
	{
		if(lastFocusObject != none)
			lastFocusObject.LostFocus(NFPawn(Pawn));
		lastFocusObject=newFocus;
	}
}

exec function Focusing(bool isPressed)
{
	if(PlayerUIState != PS_GamePlay) return;
	isPressed = (NFPawn(Pawn) != none && isPressed && lastFocusObject != none && lastFocusObject.CanSeeMe() && NFPawn(Pawn).LookAtControl != none);
	if(isPressed != IsFocusing)
	{
		IsFocusing = isPressed;
		if(IsFocusing)
		{
			if(IsTimerActive('FocusTimer'));
				ClearTimer('FocusTimer');
			SetTimer(0.02,true,'FocusTimer');
		}
		else
		{
			if(IsTimerActive('FocusTimer'))
			{
				ClearTimer('FocusTimer');
				if(lastFocusObject != none)
					lastFocusObject.LostFocus(NFPawn(Pawn));
			}
			SetTimer(0.02,true,'FocusTimer');
		}
	}
}

function FocusTimer()
{
	if(IsFocusing)
		IsFocusing = ForceFocus();
	else
	{
		LookAtLerp=Lerp(LookAtLerp,0,0.1);
		NFPawn(Pawn).LookAtControl.ControlStrength = LookAtLerp;
		if(LookAtLerp < 0.05 && IsTimerActive('FocusTimer'))
			ClearTimer('FocusTimer');
	}
}

function bool ForceFocus()
{
	if(PlayerUIState == PS_GamePlay && NFPawn(Pawn) != none && lastFocusObject != none && lastFocusObject.CanSeeMe() && NFPawn(Pawn).LookAtControl != none)
	{
		LookAtLerp=Lerp(LookAtLerp,1,0.1);
		Pawn.SetViewRotation(RLerp(Pawn.Rotation,rotator(lastFocusObject.GetFocusPosition()-Pawn.Location),LookAtLerp*0.2));
		NFPawn(Pawn).LookAtControl.SetTargetLocation(lastFocusObject.GetFocusPosition());
		NFPawn(Pawn).LookAtControl.ControlStrength = LookAtLerp;
		lastFocusObject.GotFocus(NFPawn(Pawn), LookAtLerp);
		return true;
	}
	else
	{
		if(lastFocusObject != none)
			lastFocusObject.LostFocus(NFPawn(Pawn));
		return false;
	}
}

exec function Use()
{
	local NFPickup tempPickup;
	local ObserveableMesh tempObserver;
	if(PlayerUIState != PS_GamePlay) return;
	if(lastTracedObject.Interactable != none && lastTracedObject.Interactable.CanItemInteract(self) && lastTracedObject.Interactable.GetType() == ObserveAble)
	{
	tempPickup = NFPickup(lastTracedObject.Interactable);
			if(tempPickup != none)
			{
				tempPickup.PickUp(NFPawn(Pawn));
			}
			else
			{	
				tempObserver = ObserveableMesh(lastTracedObject.Interactable);
				if(tempObserver != none)
				{
					tempObserver.Observed(NFPawn(Pawn));
				}
			}
	}
}

exec function StartFire(optional byte FireModeNum)
{
	local InterActableType ObjectType;
	local NFPickup tempPickup;
	local AmbientPawn tempPawn;
//	local StaticMeshComponent HitComponent;
	if(PlayerUIState != PS_GamePlay)
	{
		if(myHUD != none && NFHud(myHUD) != none)
			NFHud(myHUD).MouseClick(FireModeNum,true);
		return;
	}
	if(lastTracedObject.Interactable != none && lastTracedObject.Interactable.CanItemInteract(self))
	{
		ObjectType = lastTracedObject.Interactable.GetType();
		/*if(ObjectType == OpenAble)
		{
			if(lastTracedObject.HitInfo.HitComponent != none)
			{
				HitComponent = StaticMeshComponent(lastTracedObject.HitInfo.HitComponent);
				if(HitComponent != none)
				{
					HitComponent.AddImpulse(lastTracedObject.HitNormal*10,lastTracedObject.HitLocation,,true);
				}
			}
			//lastTracedObject.Interactable.
		}
		else*/ if(ObjectType == Carryable || ObjectType == OpenAble)
		{
			if(PhysGrabber != none && !bCinematicMode)
				PhysGrabber.StartFire(FireModeNum,lastTracedObject);
		}
		else if(ObjectType == Pickup || ObjectType == ObserveAble)
		{
			tempPickup = NFPickup(lastTracedObject.Interactable);
			if(tempPickup != none)
			{
				if(FireModeNum == 0)
					tempPickup.PickUp(NFPawn(Pawn));
				else if(FireModeNum == 2 && PhysGrabber != none && !bCinematicMode)
					PhysGrabber.StartFire(FireModeNum,lastTracedObject);
			}
			else
			{	
				tempPawn = AmbientPawn(lastTracedObject.Interactable);
				if(tempPawn != none)
				{
					if(FireModeNum == 0)
						tempPawn.Poke(NFPawn(Pawn));
					else if(FireModeNum == 2)
						tempPawn.AddVelocity(outWorldDirection*50,lastTracedObject.HitLocation,class'NFDamageType',lastTracedObject.HitInfo);
				}
			}
		}
	}
}

exec function StopFire(optional byte FireModeNum)
{
	if(PlayerUIState != PS_GamePlay)
	{
		if(myHUD != none && NFHud(myHUD) != none)
			NFHud(myHUD).MouseClick(FireModeNum,false);
		return;
	}
	if(PhysGrabber != none)
		PhysGrabber.StopFire(FireModeNum);
}

exec function PrevWeapon()
{
	if(PlayerUIState != PS_GamePlay) return;
		if(PhysGrabber != none)
			PhysGrabber.ZoomOut();
}

exec function NextWeapon()
{
	if(PlayerUIState != PS_GamePlay) return;
		if(PhysGrabber != none)
			PhysGrabber.ZoomIn();
}

exec function RotatingObject(bool isRotating)
{
	if(PlayerUIState != PS_GamePlay) return;
		bCurrentlyRotating=isRotating;
}

exec function TakeOutLantern()
{
	local NFMapInfo beMapInfo;
	if(bLanternForbidden)
	{
		if(NFHud(myHUD) != none)
			
         NFHud(myHUD).AddMessage(MESS_Note,"I shouldn't take out my Lantern Right Now");
		return;
	}
	beMapInfo = NFMapInfo(WorldInfo.GetMapInfo());
	if(beMapInfo != none)
	{
		if(!beMapInfo.LanternAllowed) return;
	}
	if(PlayerUIState != PS_GamePlay) return;
	if(bePawn == none || !bePawn.hasLantern) return;
	bLanternOut = !bLanternOut;
	if(bePawn.LanternBlender != none)
	{
		bePawn.LanternBlender.ChangeLanternState(bLanternOut);
		if(bLanternOut)
			bePawn.AddCharacterBrightness(0.5);
		else
			bePawn.AddCharacterBrightness(-0.5);
	}
	if(Lantern != none)
		Lantern.SetTotallyHidden(!bLanternOut);
}

exec function OpenInventory()
{
	if(PlayerUIState == PS_Inventory)
		PlayerUIState = PS_GamePlay;
	else if(PlayerUIState == PS_GamePlay)
	{
		if(NFHUD(myHUD) != none)
		{
			NFHUD(myHUD).InventoryIconBlink.Alpha=0;
			NFHUD(myHUD).InventoryIconBlink.Cooldown=0;
		}
		PlayerUIState = PS_Inventory;
	}
	//SetPause(bShowInventory);
	ResetPlayerMovementInput();
	ClientIgnoreMoveInput(PlayerUIState != PS_GamePlay);
	ClientIgnoreLookInput(PlayerUIState != PS_GamePlay);
}

exec function OpenNotes()
{
	if(PlayerUIState == PS_Notes)
	{
		if(NFHUD(myHUD) != none)
		{
			NFHUD(myHUD).PageOfNotebook = NBP_Main;
			NFHUD(myHUD).ReadingNote = false;
			NFHUD(myHUD).NoteID = 0;
			if(NFHUD(myHUD).DialogPlayer != none && NFHUD(myHUD).DialogPlayer.IsPlaying())
				NFHUD(myHUD).DialogPlayer.Stop();
		}
		PlayerUIState = PS_GamePlay;
	}
	else if(PlayerUIState == PS_GamePlay)
	{
		if(NFHUD(myHUD) != none)
		{
			NFHUD(myHUD).NoteBookIconBlink.Alpha=0;
			NFHUD(myHUD).NoteBookIconBlink.Cooldown=0;
		}
		PlayerUIState = PS_Notes;
	}
	//SetPause(bShowInventory);
	ResetPlayerMovementInput();
	ClientIgnoreMoveInput(PlayerUIState != PS_GamePlay);
	ClientIgnoreLookInput(PlayerUIState != PS_GamePlay);
}

exec function OpenMenu()
{
	switch(PlayerUIState)
	{
		case PS_Menu: PlayerUIState = PS_GamePlay; break;
		case PS_Notes: OpenNotes(); break;
		case PS_Inventory: OpenInventory(); break;
		case PS_GamePlay : PlayerUIState = PS_Menu; break;
	}
	//SetPause(bShowInventory);
	ResetPlayerMovementInput();
	ClientIgnoreMoveInput(PlayerUIState != PS_GamePlay);
	ClientIgnoreLookInput(PlayerUIState != PS_GamePlay);
}

exec function AlphaKeyPress(byte number)
{
	if(NFHUD(myHUD) != none)
		NFHUD(myHUD).LastAlphaKeyPress=number;
}

function PlayerTick(float DeltaTime)
{
	super.PlayerTick(DeltaTime);
	UpdateLeftHand(DeltaTime);
}

function CheckJumpOrDuck()
{
	if(PlayerUIState == PS_GamePlay && Pawn != None)
	{
		if ( bPressedJump )
			Pawn.DoJump( bUpdating );
		if ( Pawn.Physics != PHYS_Falling && Pawn.bCanCrouch )
			Pawn.ShouldCrouch(bDuck != 0);
	}
}

function DetachItem()
{
	if(AttachedItem!=none)
	{
		AttachedItem.StaticMeshComponent.SetHidden(true);
		AttachedItem.SetBase(none);
		AttachedItem.LifeSpan=0;
		AttachedItem.bTearOff=true;
		AttachedItem.TornOff();
		AttachedItem.Destroy();
		AttachedItem=none;
	}
}

function UpdateLeftHand(float DeltaTime)
{
	if(bePawn != none && bePawn.SkeletalArmMover != none)
	{
		if(PhysGrabber != none && PhysGrabber.PhysicsGrabber.GrabbedComponent != none)
		{
			bePawn.SkeletalArmMover.SetSkelControlStrength(1,0.2);
			LeftHandTarget = PhysGrabber.PhysicsGrabber.Location;
		}
		else if(AttachedItem != none)
		{
			bePawn.SkeletalArmMover.SetSkelControlStrength(1,0.2);
			LeftHandTarget = outWorldOrigin+(outWorldDirection*200);
		}
		else
		{
			if(LeftHandTimer <= 0)
				bePawn.SkeletalArmMover.SetSkelControlStrength(0,0.2);
			else
				LeftHandTimer-=DeltaTime;
		}
		bePawn.SkeletalArmMover.EffectorLocation = LeftHandTarget;
	}
}

function UpdateRotation( float DeltaTime )
{
	local Rotator	DeltaRot, newRotation, ViewRotation;
	local Vector    DeltaVector;
	if(PhysGrabber != none && ((PhysGrabber.PhysicsGrabber.GrabbedComponent != none && bCurrentlyRotating) || PhysGrabber.Door.Interactable != none))
	{
		DeltaRot.Roll = 0;
		DeltaRot.Yaw	= -PlayerInput.aTurn;
		DeltaRot.Pitch	= -PlayerInput.aLookUp;

		DeltaVector.X =  -PlayerInput.aTurn;
		DeltaVector.Y = -PlayerInput.aLookUp;
		DeltaVector.Z = 0;
		PhysGrabber.RotateObject(DeltaRot, DeltaVector ,DeltaTime);
		//PhysicalDoor((PhysGrabber.PhysicsGrabber.GrabbedComponent.Owner)).AngularVelocity= PhysicalDoor((PhysGrabber.PhysicsGrabber.GrabbedComponent.Owner)).AngularVelocity<<DeltaRot;
		//PhysGrabber.PhysicsGrabber.GrabbedComponent.SetRBAngularVelocity(vect(1555,0,5555),true);
	}
	else
	{
		ViewRotation = Rotation;
		if (Pawn!=none)
		{
			Pawn.SetDesiredRotation(ViewRotation);
		}

		// Calculate Delta to be applied on ViewRotation
		DeltaRot.Yaw	= PlayerInput.aTurn;
		DeltaRot.Pitch	= PlayerInput.aLookUp;

		ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
		SetRotation(ViewRotation);

		ViewShake( deltaTime );

		NewRotation = ViewRotation;
		NewRotation.Roll = Rotation.Roll;

		if ( Pawn != None )
			Pawn.FaceRotation(NewRotation, deltatime);
	}
}

state PlayerWalking
{
	function PlayerMove( float DeltaTime )
	{
		local vector			X,Y,Z, NewAccel;
		local eDoubleClickDir	DoubleClickMove;
		local rotator			OldRotation;
		local bool				bSaveJump;

		if( Pawn == None )
		{
			GotoState('Dead');
		}
		else
		{
			GetAxes(Pawn.Rotation,X,Y,Z);

			// Update acceleration.
			NewAccel = PlayerInput.aForward*X + PlayerInput.aStrafe*Y;
			NewAccel.Z	= 0.1;	
			if(bePawn != none && bePawn.lastTouchedPhysicalMaterial != none)
			{
				Pawn.AccelRate = bePawn.default.AccelRate*bePawn.lastTouchedPhysicalMaterial.Friction;
				NewAccel = Pawn.AccelRate * Normal(NewAccel);
				NewAccel.X = FInterpTo(Pawn.Acceleration.X,NewAccel.X,DeltaTime,bePawn.lastTouchedPhysicalMaterial.Friction*200);
				NewAccel.Y = FInterpTo(Pawn.Acceleration.Y,NewAccel.Y,DeltaTime,bePawn.lastTouchedPhysicalMaterial.Friction*200);
			}
			else
			{
				Pawn.AccelRate = Pawn.default.AccelRate;
				NewAccel = Pawn.AccelRate * Normal(NewAccel);
			}
			

			if (IsLocalPlayerController())
			{
				AdjustPlayerWalkingMoveAccel(NewAccel);
			}

			DoubleClickMove = PlayerInput.CheckForDoubleClickMove( DeltaTime/WorldInfo.TimeDilation );

			// Update rotation.
			OldRotation = Rotation;
			UpdateRotation( DeltaTime );
			bDoubleJump = false;

			if( bPressedJump && Pawn.CannotJumpNow() )
			{
				bSaveJump = true;
				bPressedJump = false;
			}
			else
			{
				bSaveJump = false;
			}

			if( Role < ROLE_Authority ) // then save this move and replicate it
			{
				ReplicateMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
			else
			{
				ProcessMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
			bPressedJump = bSaveJump;
		}
	}
}

/** Spawn ClientSide Camera Effects **/
unreliable client function ClientSpawnCameraEffectPerArchetype(UDKEmitCameraEffect newCameraEffect,bool ReplaceOld, optional float duration = 0)
{
	local vector CamLoc;
	local rotator CamRot;

	if(ReplaceOld) ClearCameraEffect();

	if (newCameraEffect != None)
	{
		CameraEffect = Spawn(newCameraEffect.Class, self,,Location,Rotation,newCameraEffect);
		if(duration > 0) CameraEffect.LifeSpan = duration;
		if (CameraEffect != None)
		{
			GetPlayerViewPoint(CamLoc, CamRot);
			CameraEffect.RegisterCamera(self);
			CameraEffect.UpdateLocation(CamLoc, CamRot, FOVAngle);
		}
	}
}

exec function FOV(float F)
{
	if( PlayerCamera != None )
	{
		PlayerCamera.SetFOV( F );
		return;
	}

	if( (F >= 80.0) || (WorldInfo.NetMode==NM_Standalone) || PlayerReplicationInfo.bOnlySpectator )
	{
		DefaultFOV = FClamp(F, 80, 100);
		DesiredFOV = DefaultFOV;
	}
}


exec function SaveGame(string FileName)
{
	local SaveLoadSystem GameSave;

	// Instance the save game state
	GameSave = new class'SaveLoadSystem';

	if (GameSave == None)
		return;

	ScrubFileName(FileName);    // Scrub the file name
	GameSave.Save();   // Ask the save game state to save the game

	// Serialize the save game state object onto disk
	if (class'Engine'.static.BasicSaveObject(GameSave, FileName, true, class'SaveLoadSystem'.const.REVISION))
	{
		// If successful then send a message
		ClientMessage("Saved game state to " $ FileName $ ".", 'System');
	}
}

exec function LoadGame(string FileName)
{
	local SaveLoadSystem GameSave;

	// Instance the save game state
	GameSave = new class'SaveLoadSystem';

	if (GameSave == None)
		return;

	// Scrub the file name
	ScrubFileName(FileName);

	// Attempt to deserialize the save game state object from disk
	if (class'Engine'.static.BasicLoadObject(GameSave, FileName, true, class'SaveLoadSystem'.const.REVISION))
	{
		// Start the map with the command line parameters required to then load the save game state
		ConsoleCommand("start " $ GameSave.PersistentMapFileName $ "?Game=NFGame.NFGameInfo?SaveGame=" $ FileName);
	}
}

function ScrubFileName(out string FileName)
{
	// Add the extension if it does not exist
	if (InStr(FileName, ".sav",, true) == INDEX_NONE)
	{
		FileName $= ".sav";
	}

	FileName = Repl(FileName, " ", "_");                            // If the file name has spaces, replace then with under scores
	FileName = class'SaveLoadSystem'.const.SAVE_LOCATION $ FileName; // Prepend the filename with the save folder location
}

defaultproperties
{
	CameraClass=class'NightFall.NFCamera'
	InputClass=class'NightFall.NFPlayerInput'
}