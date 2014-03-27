*MAKE A COMPLETE BACKUP OF THE UDK DIRECTORY YOU ARE USING(unless you don't care about the files in there).
There are some UT files i'm using for either testing purposes or it just worked out really well. I'm mostly deriving from GameInfo however.
So this will not work on a blank UDK install.

I tried to keep everything as light as possible to save space and to get everyone right into the fray.

Let's get started shall we?

-INSTALLATION-

These don't have to be put in any order, as long as the files are in the correct place.
Make sure you have all the assets for the game in your Content directory.

First off, to get it out of the way, you do not need to use the "UserCode" folder. It's only if you want to be ahead of the game.
It'l be used for saving and loading later on.

Put the UserCode files inside your UserCode folder in Binaries>Win32>UserCode. Done.

Next, place the files in the "Src" folder, into your Src folder. The folder is called "NightFall" and holds all our games logic and classes. Done.

Then you can put the "Assets" folder into your content folder. Nothing more to do there. Done.

Lastely, and perhaps the most important and most dangerous part, the "Config" folder. Completely replace your Config folder with the one provided.
If you have your own games created in your configs, add them in afterwards. Alot of content has been put into the Configs.

Assuming your editor compiles correctly, you should be good to go.

-FEATURES LIST + HOW TO USE-

These features are for testing purposes and are in no way the final product.It's to see what we want in the end, and we can tweak from there.

-CONTROLS-

Running - LEFT OR RIGHT SHIFT
Crouching - C
Lookback - Q AND E KEYS
Pickups(for inventory) - F
Pickups(Physics) - Left click and hold to pick up physical items in the world.
Inventory - I
Esc Menu - ESC *This is working, we just need a menu to go back to*
Notes/Hints/Diary - *Implemented but still being tweaked*

-MISC FEATURES-
Sanity
Health pick ups
Keys for locked doors
Full body awareness
Physical + Open with F doors
In game hints
Notes/Diary
Pop up text
Dialog

All these features are completely versatile and don't require any code so anyone can use them. Everything can be accessed through archetypes.

I'm sure to have missed something, so i'll update the list if I remember anything i've missed.

Let me know if you have any questions, if anything was unclear, or if you need help in general.