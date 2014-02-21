class DateTime extends Object
	hidecategories(Object)
	editinlinenew;

enum MonthEnum
{
	January,
	February,
	March,
	April,
	May,
	Juni,
	Juli,
	August,
	September,
	October,
	November,
	December
};

var() int Year, Month, Days, Hours, Mins;
var() float Seconds, FinalSeconds;

function Initialize(int _Year, int _Month, int _Days, int _Hours, int _Mins, float _Seconds)
{
	self.Year = _Year;
	self.Month = _Month;
	self.Days = _Days;
	self.Hours = _Hours;
	self.Mins = _Mins;
	self.Seconds = _Seconds;
}

function CallEvents()
{
	local int Idx;
	local array<SequenceObject> Events;
	local SeqEvent_DateTime SpawnedEvent;

	if (class'Worldinfo'.static.GetWorldInfo().GetGameSequence() != None)
		{
			class'Worldinfo'.static.GetWorldInfo().GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_DateTime',TRUE,Events);
			for (Idx = 0; Idx < Events.Length; Idx++)
			{
				SpawnedEvent = SeqEvent_DateTime(Events[Idx]);
				if (SpawnedEvent != None)
				{
					if(SpawnedEvent.OnSpecificHour != 0 && Hours != SpawnedEvent.OnSpecificHour) continue;
					else if(SpawnedEvent.CheckActivate(class'Worldinfo'.static.GetWorldInfo(),class'Worldinfo'.static.GetWorldInfo()))
					{
						SpawnedEvent.Date = self;
						SpawnedEvent.PopulateLinkedVariableValues();
					}
				}
			}
		}
}

function AddSeconds(float _Seconds)
{
	while(_Seconds > 0)
	{
		self.FinalSeconds += _Seconds;
		self.Seconds += _Seconds;
		if(self.Seconds>59)
		{
			self.Seconds=0;
			AddMins(1);
		}
		_Seconds-=1.f;
	}
}

function AddMins(int _Mins)
{
	while(_Mins > 0)
	{
		self.Mins++;
		if(self.Mins>59)
		{
			self.Mins=0;
			AddHours(1);
		}
		_Mins--;
	}
}

function AddHours(int _Hours)
{
	while(_Hours > 0)
	{
		self.Hours++;
		if(self.Hours>23)
		{
			self.Hours=0;
			AddDays(1);
		}
		_Hours--;
	}
	CallEvents();
}

function AddDays(int _Days)
{
	while(_Days > 0)
	{
		self.Days++;
		if(self.Days>29)
		{
			self.Days=1;
			AddMonths(1);
		}
		_Days--;
	}
}

function AddMonths(int _Months)
{
	while(_Months > 0)
	{
		self.Month++;
		if(self.Month>12)
		{
			self.Month=0;
			AddYears(1);
		}
		_Months--;
	}
}

function AddYears(int _Years)
{
	self.Year += _Years;
}

function string ToString()
{
    local string NewTimeString;
	local int intSeconds;
	intSeconds = Seconds;

	NewTimeString = "" $ String(Days)$",";
	NewTimeString = NewTimeString $ String(Month) $ ",";
	NewTimeString = NewTimeString $ String(Year) $ " | ";
	NewTimeString = NewTimeString $ ( Hours > 9 ? String(Hours) : "0"$String(Hours)) $ ":";
    NewTimeString = NewTimeString $ ( Mins > 9 ? String(Mins) : "0"$String(Mins)) $ ":";
    NewTimeString = NewTimeString $ ( intSeconds > 9 ? String(intSeconds) : "0"$String(intSeconds));

    return NewTimeString;
}

function string ToDateString(bool MonthAsString = false)
{
    local string NewTimeString;

	NewTimeString = "" $ String(Days)$".";
	if(MonthAsString)
		NewTimeString = NewTimeString $ String(GetEnum(Enum'MonthEnum', Month-1));
	else
		NewTimeString = NewTimeString $ String(Month);
	if(Year < 0)
		NewTimeString = NewTimeString @ String(int(Abs(Year))) @ "v. Chr.";
	else
		NewTimeString = NewTimeString @ String(Year);

    return NewTimeString;
}

function string ToTimeString(bool ShowSeconds = false)
{
    local string NewTimeString;
	local int intSeconds;

	NewTimeString = "" $ ( Hours > 9 ? String(Hours) : "0"$String(Hours)) $ ":";
    NewTimeString = NewTimeString $ ( Mins > 9 ? String(Mins) : "0"$String(Mins));
	if(ShowSeconds)
	{
		intSeconds = Seconds;
		NewTimeString = NewTimeString $ ":" $ ( intSeconds > 9 ? String(intSeconds) : "0"$String(intSeconds));
	}

    return NewTimeString;
}

DefaultProperties
{
	Year=1738
	Month=6
	Days=13
	Hours=14
	Mins=23
	Seconds=16
}
