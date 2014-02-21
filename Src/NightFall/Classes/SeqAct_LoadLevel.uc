class SeqAct_LoadLevel extends SequenceAction;

var() string LevelNameToLoad;

var() Vector SpawnPosition;
var() Rotator SpawnRotation;

event Activated()
{
	local SaveLoadSystem GameSave;
	local string FileName, PlayerData;
	local WorldInfo SWorldInfo;
	local NFPlayerController bePc;
	local JsonObject SJsonObject;
	// Instance the save game state
	SWorldInfo = class'WorldInfo'.static.GetWorldInfo();
	GameSave = new class'SaveLoadSystem';

	if (GameSave == None)
		return;

	FileName = "AutoSave"$TimeStamp();
	// Scrub the file name
	ScrubFileName(FileName);
	if(String(SWorldInfo.GetPackageName()) != LevelNameToLoad)
	{
		GameSave.PersistentMapFileName = LevelNameToLoad;
		foreach SWorldInfo.LocalPlayerControllers(class'NFPlayerController',bePc)
		{
			if(bePc.bePawn != none)
			{
				PlayerData = bePc.bePawn.Serialize();

				if (PlayerData != "")
				{
					SJsonObject = class'JsonObject'.static.DecodeJson(PlayerData);

					SJsonObject.SetFloatValue("Location_X", SpawnPosition.X);
					SJsonObject.SetFloatValue("Location_Y", SpawnPosition.Y);
					SJsonObject.SetFloatValue("Location_Z", SpawnPosition.Z);

					SJsonObject.SetIntValue("Rotation_Pitch", SpawnRotation.Pitch);
					SJsonObject.SetIntValue("Rotation_Yaw", SpawnRotation.Yaw);
					SJsonObject.SetIntValue("Rotation_Roll", SpawnRotation.Roll);

					SJsonObject.SetStringValue("Name", PathName(bePc.bePawn));
					SJsonObject.SetStringValue("ObjectArchetype", PathName(bePc.bePawn.ObjectArchetype));

					PlayerData = class'JsonObject'.static.EncodeJson(SJsonObject);

					GameSave.SerializedWorldData.AddItem(PlayerData);
				}
			}
		}
	}
	else
		GameSave.Save();

	if (class'Engine'.static.BasicSaveObject(GameSave, FileName, true, class'SaveLoadSystem'.const.REVISION))
	{
		foreach SWorldInfo.LocalPlayerControllers(class'NFPlayerController',bePc)
			bePc.ClientMessage("AutoSaved game state to " $ FileName $ ".", 'System');
	}
	// Attempt to deserialize the save game state object from disk
	if (class'Engine'.static.BasicLoadObject(GameSave, FileName, true, class'SaveLoadSystem'.const.REVISION))
	{
		foreach SWorldInfo.LocalPlayerControllers(class'NFPlayerController',bePc)
			bePc.ConsoleCommand("start " $ GameSave.PersistentMapFileName $ "?Game=NFGame.NFGameInfo?SaveGame=" $ FileName);
	}
}

function ScrubFileName(out string FileName)
{
	// Add the extension if it does not exist
	if (InStr(FileName, ".sav",, true) == INDEX_NONE)
	{
		FileName $= ".sav";
	}

	FileName = Repl(FileName, ":", "_"); 
	FileName = Repl(FileName, "/", "_"); 
	FileName = Repl(FileName, "-", "");  
	FileName = Repl(FileName, " ", "_");                           // If the file name has spaces, replace then with under scores
	FileName = class'SaveLoadSystem'.const.SAVE_LOCATION $ FileName; // Prepend the filename with the save folder location
}

defaultproperties
{
	ObjName="Load Level"
	ObjCategory="NF"
	bCallHandler=false
	
	OutputLinks(0)=(LinkDesc="Out")
}