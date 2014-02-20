/**
 * Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
 * 
    EndGame: Quite self-explanatory. It’s up to you to call this function whenever you feel like the game can possibly end. Its default implementation calls CheckEndGame, which is in charge of making sure the game is actually ready to end. If that’s the case, it then notifies all the controllers, so they can run additional routines if necessary. The function takes the “winner’s” PlayerReplicationInfo, and a string for the reason of the game’s ending.
    CheckModifiedEndGame:Called by CheckEndGame, passing it its own parameters. Must return false if… the game should end.
    RestartGame: Once the game has ended, RestartGame’s role is either to restart the current map and game, or switch to the next map.
    GetNextMap: Default implementation does nothing. Must return a string containing the name of the map file the game should load next.

 */
class NFGameInfo extends GameInfo;

var DateTime ActualDate;
var() const archetype Pawn DefaultPawnArchetype;

var private string PendingSaveGameFileName; // Pending save game state file name
var Pawn PendingPlayerPawn;                 // Pending player pawn for the player controller to spawn when loading a game state
var SaveLoadSystem StreamingSaveGameState;  // Save game state used for when streaming levels is waiting to be finished. This is cleared when streaming levels are completed.

event InitGame(string Options, out string ErrorMessage)
{
	super.InitGame(Options, ErrorMessage);

	// Set the pending save game file name if required
	if (HasOption(Options, "SaveGame"))
		PendingSaveGameFileName = ParseOption(Options, "SaveGame");
	else
		PendingSaveGameFileName = "";
}
/*

function StartMatch()
{
	local SaveLoadSystem SaveGame;
	local NFPlayerController SPlayerController;
    local int Idx;
    local array<SequenceObject> Events;
    local SeqEvent_GameLoaded SavedGameStateLoaded;
	local name CurrentStreamingMap;

	// Check if we need to load the game or not
	if (PendingSaveGameFileName != "")
	{
		// Instance the save game state
		SaveGame = new class'SaveLoadSystem';

		if (SaveGame == none)
			return;

		// Attempt to deserialize the save game state object from disk
		if (class'Engine'.static.BasicLoadObject(SaveGame, PendingSaveGameFileName, true, class'SaveLoadSystem'.const.REVISION))
		{
			// Synchrously load in any streaming levels
			if (SaveGame.StreamingMapFileNames.Length > 0)
			{
				// Ask every player controller to load up the streaming map
				foreach self.WorldInfo.AllControllers(class'NFPlayerController', SPlayerController)
				{
					// Stream map files now
					foreach SaveGame.StreamingMapFileNames(CurrentStreamingMap)											
						SPlayerController.ClientUpdateLevelStreamingStatus(CurrentStreamingMap, true, true, true);

					// Block everything until pending loading is done
					SPlayerController.ClientFlushLevelStreaming();
				}

				StreamingSaveGameState = SaveGame;                              // Store the save game state in StreamingSaveGameState
				SetTimer(0.05f, true, NameOf(WaitingForStreamingLevelsTimer));  // Start the looping timer which waits for all streaming levels to finish loading

				return;
			}
			// Load the game state
			SaveGame.Load();
		}

		// Send a message to all player controllers that we've loaded the save game state
		foreach self.WorldInfo.AllControllers(class'NFPlayerController', SPlayerController)
		{
			SPlayerController.ClientMessage("Loaded save game state from " $ PendingSaveGameFileName $ ".", 'System');

			  // Activate saved game state loaded events
			  if (WorldInfo.GetGameSequence() != None)
			  {
				WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_GameLoaded', true, Events);
				for (Idx = 0; Idx < Events.Length; Idx++)
				{
				  SavedGameStateLoaded = SeqEvent_GameLoaded(Events[Idx]);        
				  if (SavedGameStateLoaded != None)
				  {
					  SavedGameStateLoaded.CheckActivate(SPlayerController, SPlayerController);
				  }
				}
			 }
		}
	}
	super.StartMatch();
}
*/
function WaitingForStreamingLevelsTimer()
{
	local LevelStreaming Level;
	local NFPlayerController SPlayerController;

	foreach self.WorldInfo.StreamingLevels(Level)
	{
		// If any levels still have the load request pending, then return
		if (Level.bHasLoadRequestPending)
			return;
	}

	ClearTimer(NameOf(WaitingForStreamingLevelsTimer)); // Clear the looping timer
	StreamingSaveGameState.Load();                      // Load the save game state
	StreamingSaveGameState = none;                      // Clear it for garbage collection

	// Send a message to all player controllers that we've loaded the save game state
	foreach self.WorldInfo.AllControllers(class'NFPlayerController', SPlayerController)
		SPlayerController.ClientMessage("Loaded save game state from " $ PendingSaveGameFileName $ ".", 'System');

	super.StartMatch();
}

function Pawn SpawnDefaultPawnFor(Controller NewPlayer, NavigationPoint StartSpot)
{
	local Rotator StartRotation;
	local Pawn SpawnedPawn;

	if(PendingPlayerPawn != none)
	{
		SpawnedPawn = PendingPlayerPawn;
		PendingPlayerPawn = none;
	}
	else if(NewPlayer != None && StartSpot != None)
	{
		StartRotation.Yaw = StartSpot.Rotation.Yaw;
		if(DefaultPawnArchetype != none)
			SpawnedPawn = Spawn(DefaultPawnArchetype.Class,,, StartSpot.Location, StartRotation, DefaultPawnArchetype);
		else
			SpawnedPawn= super.SpawnDefaultPawnFor(NewPlayer,StartSpot);
	}
	else 
		return none;

	return SpawnedPawn;
}

function RestartPlayer(Controller NewPlayer)
{
  local LocalPlayer LP; 
  local PlayerController PC; 

  // Ensure that we have a controller
  if (NewPlayer == None)
  {
    return;
  }

  // If we have a pending player pawn, then just possess that one
  if (PendingPlayerPawn != None)
  {
    // Assign the pending player pawn as the new player's pawn
    NewPlayer.Pawn = PendingPlayerPawn;

    // Initialize and start it up
    if (PlayerController(NewPlayer) != None)
    {
      PlayerController(NewPlayer).TimeMargin = -0.1;
    }

    NewPlayer.Pawn.LastStartTime = WorldInfo.TimeSeconds;
    NewPlayer.Possess(NewPlayer.Pawn, false);    
    NewPlayer.ClientSetRotation(NewPlayer.Pawn.Rotation, true);

    if (!WorldInfo.bNoDefaultInventoryForPlayer)
    {
      AddDefaultInventory(NewPlayer.Pawn);
    }

    SetPlayerDefaults(NewPlayer.Pawn);

    // Clear the pending pawn
    PendingPlayerPawn = None;
  }
  else // Otherwise spawn a new pawn for the player to possess
  {
    Super.RestartPlayer(NewPlayer);
  }

  // To fix custom post processing chain when not running in editor or PIE.
  PC = PlayerController(NewPlayer);
  if (PC != none)
  {
    LP = LocalPlayer(PC.Player); 

    if (LP != None) 
    { 
      LP.RemoveAllPostProcessingChains(); 
      LP.InsertPostProcessingChain(LP.Outer.GetWorldPostProcessChain(), INDEX_NONE, true);

      if (PC.myHUD != None)
      {
        PC.myHUD.NotifyBindPostProcessEffects();
      }
    } 
  }
}

event PostBeginPlay()
{
	local NFMapInfo beMapInfo;
	local MusicTrackStruct theMusicTrack;
	super.PostBeginPlay();

	ActualDate=new class'DateTime';
	beMapInfo = NFMapInfo(WorldInfo.GetMapInfo());
	if(beMapInfo != none)
	{
		beMapInfo.Initialize();
		if(beMapInfo.StartDate != none)
			ActualDate = beMapInfo.StartDate;
		else
			ActualDate.Initialize(1840,6,14,13,2,45);
		if(beMapInfo.AmbientSoundtrack != none)
		{
			theMusicTrack.bAutoPlay=true;
			theMusicTrack.FadeInTime=1;
			theMusicTrack.FadeInVolumeLevel=0.6;
			theMusicTrack.FadeOutTime=1;
			theMusicTrack.FadeOutVolumeLevel=0;
			theMusicTrack.TheSoundCue=beMapInfo.AmbientSoundtrack;
			WorldInfo.UpdateMusicTrack(theMusicTrack);
		}
	}
	else
	{
		ActualDate.Initialize(1840,6,14,13,2,45);
	}
}

function Tick(float DeltaTime)
{
	ActualDate.AddSeconds(DeltaTime*GameSpeed);
	super.Tick(DeltaTime);
}

defaultproperties
{
	HUDType=class'NightFall.NFHUD'
	PlayerControllerClass=class'NightFall.NFPlayerController'
	DefaultPawnClass=class'NightFall.NFPawn'
	bDelayedStart=false
	bWaitingToStartMatch=true
	DefaultPawnArchetype=NFPawn'Main.Character.Default'
}

