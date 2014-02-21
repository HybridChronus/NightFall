class Notes extends Object
	ClassGroup(NF)
    AutoExpandCategories(NF);

struct ImageEntry
{
	var() int XPos, YPos;
	var() Texture2D Image;
};

enum NoteType
{
	Memo,
	DiaryEntry,
	Note
};

var(NF) int EntryNumber;
var(NF) NoteType TypeOfNote;
var(NF) string Headline;
var(NF) string Text;
var(NF) Font FontToUse;
var(NF) array<ImageEntry> Images;
var(NF) SoundCue SoundToPlay;

DefaultProperties
{
	Headline="Uff Undefined"
	FontToUse=Font'Main.Fonts.Mathilde'
	EntryNumber = 0
}