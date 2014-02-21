/*Note that only basic properties (ints, floats, strings, names, etc) and arrays/structs of basic properties will be saved.
 * You can save an object pointer, but when loading, the object must already be in memory (it uses StaticFindObject on the
 * pathname of the object, since object properties are stored as strings). */

/***Should get updated for console games ***/
class SaveLoadSystem extends Object;

const REVISION = 0;                                         // SaveGameState revision number
const SAVE_LOCATION = "..\\..\\..\\Saves\\SaveGameState\\"; // Folder for saved game files

var string PersistentMapFileName;                           // File name of the map that this save game state is associated with
var array<name> StreamingMapFileNames;	                    // File names of the streaming maps that this save game state is associated with
var array<string> SerializedWorldData;                      // Serialized world data

var string SaveGameTitle;
var string SaveTimeIngame;
var string RealSaveTime;

function bool Save()
{
	local WorldInfo SWorldInfo;
    local JsonObject SJsonObject;
    local SaveGameStateInterface SaveGameInterface;
    local LevelStreaming Level;
    local Actor CurrentActor;
    local string ActorData;
    SWorldInfo = class'WorldInfo'.static.GetWorldInfo();  // Get the world info, abort if the world info could not be found

    if (SWorldInfo == none)
        return false;

	SaveGameTitle=SWorldInfo.Title;
	if(NFGameInfo(SWorldInfo.Game) != none)
		SaveTimeIngame=NFGameInfo(SWorldInfo.Game).ActualDate.ToString();

	RealSaveTime = TimeStamp();
    PersistentMapFileName = String(SWorldInfo.GetPackageName()); // Save the persistent map file name
	
	// Save the currently streamed in map file names
    foreach SWorldInfo.StreamingLevels(Level)
    {
	// Levels that are visible and have a load request pending should be included in the streaming levels list
        if (Level != none && (Level.bIsVisible || Level.bHasLoadRequestPending))			
            StreamingMapFileNames.AddItem(Level.PackageName);
    }

	 // Iterate through all of the actors that implement SaveGameStateInterface and ask them to serialize themselves
    foreach SWorldInfo.DynamicActors(class'Actor', CurrentActor, class'SaveGameStateInterface')
    {
		SaveGameInterface = SaveGameStateInterface(CurrentActor);// Type cast to the SaveGameStateInterface

		if (SaveGameInterface != none)
		{
			// Serialize properties that are common to every serializable actor to avoid repetition in the actor classes
			SJsonObject = class'JsonObject'.static.DecodeJson(SaveGameInterface.Serialize());
			SJsonObject.SetStringValue("Name", PathName(CurrentActor));
			SJsonObject.SetStringValue("ObjectArchetype", PathName(CurrentActor.ObjectArchetype));

			ActorData = class'JsonObject'.static.EncodeJson(SJsonObject);

			// If the serialzed actor data is valid, then add it to the serialized world data array
			if (ActorData != "")
				SerializedWorldData.AddItem(ActorData);
		}
    }

	SaveKismetState();
	SaveMatineeState();
	return true;
	//return class'Engine'.static.BasicSaveObject(self, Path, true, class'SaveLoadSystem'.const.REVISION);
}

function bool Load()
{
    local WorldInfo SWorldInfo;
    local JSonObject SJSonObject;
    local SaveGameStateInterface SaveGameInterface;
    local Actor CurrentActor, ActorArchetype;
    local string ObjectData, ObjectName;

	//if(!class'Engine'.static.BasicLoadObject(self, Path, true, class'SaveLoadSystem'.const.REVISION))
	//	return false;

    // No serialized world data to load
    if (SerializedWorldData.Length <= 0)
        return false;

    // Grab the world info, abort if no valid world info
    SWorldInfo = class'WorldInfo'.static.GetWorldInfo();

    if (SWorldInfo == none)
        return false;

    // Iterate through each serialized data object
    foreach SerializedWorldData(ObjectData)
    {
        if (ObjectData != "")
        {
            // Decode the JSonObject from the encoded string
            SJSonObject = class'JSonObject'.static.DecodeJson(ObjectData);
            if (SJSonObject != none)
            {
                ObjectName = SJSonObject.GetStringValue("Name");            // Get the object name
				if (InStr(ObjectName, "SeqAct_Interp",, true) != INDEX_NONE)
				{
					LoadMatineeState(ObjectName, SJSonObject);
				}
				else if (InStr(ObjectName, "SeqEvent",, true) != INDEX_NONE || InStr(ObjectName, "SeqVar",, true) != INDEX_NONE)
				{
					LoadKismetState(ObjectName, SJSonObject);
				}
				else
				{
					CurrentActor = Actor(FindObject(ObjectName, class'Actor')); // Try to find the persistent level actor
					// If the actor was not in the persistent level, then it must have been dynamic so attempt to spawn it
					if (CurrentActor == none)
					{
						ActorArchetype = Actor(DynamicLoadObject(SJSonObject.GetStringValue("ObjectArchetype"), class'Actor'));
						if (ActorArchetype != none)
							CurrentActor = SWorldInfo.Spawn(ActorArchetype.Class,,,,, ActorArchetype, true);
					}
					if (CurrentActor != none)
					{
						SaveGameInterface = SaveGameStateInterface(CurrentActor); // Type cast to the SaveGameStateInterface
						if (SaveGameInterface != none)
							SaveGameInterface.Deserialize(SJSonObject); // Deserialize the actor
					}
				}
            }
        }
    }

	return true;
}

/**
 * Saves the Kismet game state
 */
protected function SaveKismetState()
{
  local WorldInfo WorldInfo;
  local array<Sequence> RootSequences;
  local array<SequenceObject> SequenceObjects;
  local SequenceEvent SequenceEvent;
  local SeqVar_Bool SeqVar_Bool;
  local SeqVar_Float SeqVar_Float;
  local SeqVar_Int SeqVar_Int;
  local SeqVar_Object SeqVar_Object;
  local SeqVar_String SeqVar_String;
  local SeqVar_Vector SeqVar_Vector;
  local int i, j;
  local JSonObject JSonObject;

  // Get the world info, abort if it does not exist
  WorldInfo = class'WorldInfo'.static.GetWorldInfo();
  if (WorldInfo == None)
  {
    return;
  }

  // Get all of the root sequences within the world, abort if there are no root sequences
  RootSequences = WorldInfo.GetAllRootSequences();
  if (RootSequences.Length <= 0)
  {
    return;
  }
  
  // Serialize all SequenceEvents and SequenceVariables
  for (i = 0; i < RootSequences.Length; ++i)
  {
    if (RootSequences[i] != None)
    {
      // Serialize Kismet Events
      RootSequences[i].FindSeqObjectsByClass(class'SequenceEvent', true, SequenceObjects);
      if (SequenceObjects.Length > 0)
      {
        for (j = 0; j < SequenceObjects.Length; ++j)
        {
          SequenceEvent = SequenceEvent(SequenceObjects[j]);
          if (SequenceEvent != None)
          {
            JSonObject = new () class'JSonObject';
            if (JSonObject != None)
            {
              // Save the path name of the SequenceEvent so it can found later
              JSonObject.SetStringValue("Name", PathName(SequenceEvent));
              // Calculate the activation time of what it should be when the saved game state is loaded. This is done as the retrigger delay minus the difference between the current world time
              // and the last activation time. If the result is negative, then it means this was never triggered before, so always make sure it is larger or equal to zero.
              JsonObject.SetFloatValue("ActivationTime", FMax(SequenceEvent.ReTriggerDelay - (WorldInfo.TimeSeconds - SequenceEvent.ActivationTime), 0.f));
              // Save the current trigger count
              JSonObject.SetIntValue("TriggerCount", SequenceEvent.TriggerCount);
              // Encode this and append it to the save game data array
              SerializedWorldData.AddItem(class'JSonObject'.static.EncodeJson(JSonObject));
            }
          }
        }
      }

      // Serialize Kismet Variables
      RootSequences[i].FindSeqObjectsByClass(class'SequenceVariable', true, SequenceObjects);
      if (SequenceObjects.Length > 0)
      {
        for (j = 0; j < SequenceObjects.Length; ++j)
        {
          // Attempt to serialize as a boolean variable
          SeqVar_Bool = SeqVar_Bool(SequenceObjects[j]);
          if (SeqVar_Bool != None)
          {
            JSonObject = new () class'JSonObject';
            if (JSonObject != None)
            {
              // Save the path name of the SeqVar_Bool so it can found later
              JSonObject.SetStringValue("Name", PathName(SeqVar_Bool));
              // Save the boolean value
              JSonObject.SetIntValue("Value", SeqVar_Bool.bValue);
              // Encode this and append it to the save game data array
              SerializedWorldData.AddItem(class'JSonObject'.static.EncodeJson(JSonObject));
            }

            // Continue to the next one within the array as we're done with this array index
            continue;
          }

          // Attempt to serialize as a float variable
          SeqVar_Float = SeqVar_Float(SequenceObjects[j]);
          if (SeqVar_Float != None)
          {
            JSonObject = new () class'JSonObject';
            if (JSonObject != None)
            {
              // Save the path name of the SeqVar_Float so it can found later
              JSonObject.SetStringValue("Name", PathName(SeqVar_Float));
              // Save the float value
              JSonObject.SetFloatValue("Value", SeqVar_Float.FloatValue);
              // Encode this and append it to the save game data array
              SerializedWorldData.AddItem(class'JSonObject'.static.EncodeJson(JSonObject));
            }

            // Continue to the next one within the array as we're done with this array index
            continue;
          }

          // Attempt to serialize as an int variable
          SeqVar_Int = SeqVar_Int(SequenceObjects[j]);
          if (SeqVar_Int != None)
          {
            JSonObject = new () class'JSonObject';
            if (JSonObject != None)
            {
              // Save the path name of the SeqVar_Int so it can found later
              JSonObject.SetStringValue("Name", PathName(SeqVar_Int));
              // Save the int value
              JSonObject.SetIntValue("Value", SeqVar_Int.IntValue);
              // Encode this and append it to the save game data array
              SerializedWorldData.AddItem(class'JSonObject'.static.EncodeJson(JSonObject));
            }

            // Continue to the next one within the array as we're done with this array index
            continue;
          }

          // Attempt to serialize as an object variable
          SeqVar_Object = SeqVar_Object(SequenceObjects[j]);
          if (SeqVar_Object != None)
          {
            JSonObject = new () class'JSonObject';
            if (JSonObject != None)
            {
              // Save the path name of the SeqVar_Object so it can found later
              JSonObject.SetStringValue("Name", PathName(SeqVar_Object));
              // Save the object value
              JSonObject.SetStringValue("Value", PathName(SeqVar_Object.GetObjectValue()));
              // Encode this and append it to the save game data array
              SerializedWorldData.AddItem(class'JSonObject'.static.EncodeJson(JSonObject));
            }

            // Continue to the next one within the array as we're done with this array index
            continue;
          }
  
          // Attempt to serialize as a string variable
          SeqVar_String = SeqVar_String(SequenceObjects[j]);
          if (SeqVar_String != None)
          {
            JSonObject = new () class'JSonObject';
            if (JSonObject != None)
            {
              // Save the path name of the SeqVar_String so it can found later
              JSonObject.SetStringValue("Name", PathName(SeqVar_String));
              // Save the string value
              JSonObject.SetStringValue("Value", SeqVar_String.StrValue);
              // Encode this and append it to the save game data array
              SerializedWorldData.AddItem(class'JSonObject'.static.EncodeJson(JSonObject));
            }

            // Continue to the next one within the array as we're done with this array index
            continue;
          }

          // Attempt to serialize as a vector variable
          SeqVar_Vector = SeqVar_Vector(SequenceObjects[j]);
          if (SeqVar_Vector != None)
          {
            JSonObject = new () class'JSonObject';
            if (JSonObject != None)
            {
              // Save the path name of the SeqVar_Vector so it can found later
              JSonObject.SetStringValue("Name", PathName(SeqVar_Vector));
              // Save the vector value
              JSonObject.SetFloatValue("Value_X", SeqVar_Vector.VectValue.X);
              JSonObject.SetFloatValue("Value_Y", SeqVar_Vector.VectValue.Y);
              JSonObject.SetFloatValue("Value_Z", SeqVar_Vector.VectValue.Z);
              // Encode this and append it to the save game data array
              SerializedWorldData.AddItem(class'JSonObject'.static.EncodeJson(JSonObject));
            }

            // Continue to the next one within the array as we're done with this array index
            continue;
          }
        }
      }
    }
  }
}

/**
 * Saves the Matinee game state
 */
protected function SaveMatineeState()
{
  local WorldInfo WorldInfo;
  local array<Sequence> RootSequences;
  local array<SequenceObject> SequenceObjects;
  local SeqAct_Interp SeqAct_Interp;
  local int i, j;
  local JSonObject JSonObject;

  // Get the world info, abort if it does not exist
  WorldInfo = class'WorldInfo'.static.GetWorldInfo();
  if (WorldInfo == None)
  {
    return;
  }

  // Get all of the root sequences within the world, abort if there are no root sequences
  RootSequences = WorldInfo.GetAllRootSequences();
  if (RootSequences.Length <= 0)
  {
    return;
  }
  
  // Serialize all SequenceEvents and SequenceVariables
  for (i = 0; i < RootSequences.Length; ++i)
  {
    if (RootSequences[i] != None)
    {
      // Serialize Matinee Kismet Sequence Actions
      RootSequences[i].FindSeqObjectsByClass(class'SeqAct_Interp', true, SequenceObjects);
      if (SequenceObjects.Length > 0)
      {
        for (j = 0; j < SequenceObjects.Length; ++j)
        {
          SeqAct_Interp = SeqAct_Interp(SequenceObjects[j]);
          if (SeqAct_Interp != None)
          {
            // Attempt to serialize the data
            JSonObject = new () class'JSonObject';
            if (JSonObject != None)
            {
              // Save the path name of the SeqAct_Interp so it can found later
              JSonObject.SetStringValue("Name", PathName(SeqAct_Interp));
              // Save the current position of the SeqAct_Interp
              JSonObject.SetFloatValue("Position", SeqAct_Interp.Position);
              // Save if the SeqAct_Interp is playing or not
              JSonObject.SetIntValue("IsPlaying", (SeqAct_Interp.bIsPlaying) ? 1 : 0);
              // Save if the SeqAct_Interp is paused or not
              JSonObject.SetIntValue("Paused", (SeqAct_Interp.bPaused) ? 1 : 0);
              // Encode this and append it to the save game data array
              SerializedWorldData.AddItem(class'JSonObject'.static.EncodeJson(JSonObject));
            }
          }
        }
      }
    }
  }
}

function LoadKismetState(string ObjectName, JSonObject Data)
{
  local SequenceEvent SequenceEvent;
  local SeqVar_Bool SeqVar_Bool;
  local SeqVar_Float SeqVar_Float;
  local SeqVar_Int SeqVar_Int;
  local SeqVar_Object SeqVar_Object;
  local SeqVar_String SeqVar_String;
  local SeqVar_Vector SeqVar_Vector;
  local Object SequenceObject;
  local WorldInfo WorldInfo;

  // Attempt to find the sequence object
  SequenceObject = FindObject(ObjectName, class'Object');

  // Could not find sequence object, so abort
  if (SequenceObject == None)
  {
    return;
  }

  // Deserialize Kismet Event
  SequenceEvent = SequenceEvent(SequenceObject);
  if (SequenceEvent != None)
  {
    WorldInfo = class'WorldInfo'.static.GetWorldInfo();
    if (WorldInfo != None)
    {
      SequenceEvent.ActivationTime = WorldInfo.TimeSeconds + Data.GetFloatValue("ActivationTime");
    }

    SequenceEvent.TriggerCount = Data.GetIntValue("TriggerCount");
    return;
  }

  // Deserialize Kismet Variable Bool
  SeqVar_Bool = SeqVar_Bool(SequenceObject);
  if (SeqVar_Bool != None)
  {
    SeqVar_Bool.bValue = Data.GetIntValue("Value");
    return;
  }

  // Deserialize Kismet Variable Float
  SeqVar_Float = SeqVar_Float(SequenceObject);
  if (SeqVar_Float != None)
  {
    SeqVar_Float.FloatValue = Data.GetFloatValue("Value");
    return;
  }

  // Deserialize Kismet Variable Int
  SeqVar_Int = SeqVar_Int(SequenceObject);
  if (SeqVar_Int != None)
  {
    SeqVar_Int.IntValue = Data.GetIntValue("Value");
    return;
  }

  // Deserialize Kismet Variable Object
  SeqVar_Object = SeqVar_Object(SequenceObject);
  if (SeqVar_Object != None)
  {
    SeqVar_Object.SetObjectValue(FindObject(Data.GetStringValue("Value"), class'Object'));
    return;
  }

  // Deserialize Kismet Variable String
  SeqVar_String = SeqVar_String(SequenceObject);
  if (SeqVar_String != None)
  {
    SeqVar_String.StrValue = Data.GetStringValue("Value");
    return;
  }

  // Deserialize Kismet Variable Vector
  SeqVar_Vector = SeqVar_Vector(SequenceObject);
  if (SeqVar_Vector != None)
  {
    SeqVar_Vector.VectValue.X = Data.GetFloatValue("Value_X");
    SeqVar_Vector.VectValue.Y = Data.GetFloatValue("Value_Y");
    SeqVar_Vector.VectValue.Z = Data.GetFloatValue("Value_Z");
    return;
  }
}


function LoadMatineeState(string ObjectName, JSonObject Data)
{
  local SeqAct_Interp SeqAct_Interp;
  local float OldForceStartPosition;
  local bool OldbForceStartPos;

  // Find the matinee kismet object
  SeqAct_Interp = SeqAct_Interp(FindObject(ObjectName, class'Object'));
  if (SeqAct_Interp == None)
  {
    return;
  }
  
  if (Data.GetIntValue("IsPlaying") == 1)
  {
    OldForceStartPosition = SeqAct_Interp.ForceStartPosition;
    OldbForceStartPos = SeqAct_Interp.bForceStartPos;

    // Play the matinee at the forced position
    SeqAct_Interp.ForceStartPosition = Data.GetFloatValue("Position");
    SeqAct_Interp.bForceStartPos = true;
    SeqAct_Interp.ForceActivateInput(0);

    // Reset the start position and start pos
    SeqAct_Interp.ForceStartPosition = OldForceStartPosition;
    SeqAct_Interp.bForceStartPos = OldbForceStartPos;
  }
  else
  {
    // Set the position of the matinee
    SeqAct_Interp.SetPosition(Data.GetFloatValue("Position"), true);
  }

  // Set the paused 
  SeqAct_Interp.bPaused = (Data.GetIntValue("Paused") == 1) ? true : false;
}