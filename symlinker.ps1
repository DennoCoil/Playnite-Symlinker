<# The Symlinker

Note:  Whenever a Logic Run shows LOG, it means use the $__logger to post logs to PLaynite. #>

$CurrentGame = Null

<#The JSON database: where PLaynite and the owner can refer where their games are located

Some methods to work with

			JSON_ORIGINAL_EXTENSION_NAME  (String:  The 2\3 letter extension used to launch with the emulator)  
			JSON_DESTINATION_PATH  (String)
			JSON_ORIGINAL_PATH  (String)
			JSON_IS_COMPRESSED  (BOOL: Checks if said game entry is compressed.)
			JSON_IS_SYMLINKED  (BOOL: Checks if a Symlink is made)
#>

<#Example of the "symlinker.json" file

{"SYMLINK DESTINATION PATH": "D:\Steam Backups",
"SYMLINK ARCHIVE PATH": "E:\Backups",
	{
	"GAME_ID": "777-777-777-777-777"  (Playnite Internal ID)
	"FOLDER_NAME": "Half-Life2"  (Makes it easy to look up folder\archive name)
	"ORIGINAL_PATH": "C:\Steam\Steamapps\Half-Life2"
	"ARCHIVE_NAME": "Half-Life2.7z"
	"ORIGINAL_EXTENSION_NAME": "hl2.exe"
	"IS_COMPRESSED": False  (If True, the game should be in a archive like 7z.)
	"IS_SYMLINKED": False  (Says if there's a symlink where the original folder used to be.)
	},
	{"GAME_ID": "6969-6969-6969-6969-6969"
	"FOLDER_NAME": "DukeNukem3D"
	"ORIGINAL_PATH": "C:\GOG\DukeNukem3D"
	"ARCHIVE_NAME": "DukeNukem3D.7z"
	"ORIGINAL_EXTENSION_NAME": "duke3d.exe"
	"IS_COMPRESSED": True
	"IS_SYMLINKED": True
	}
}
#>

<#CHECK_SELECTED_FOLDER (DONE)
			Check the JSON if the Destination folder\drive was set.
			If it wasn't set
				Show Message Box:  "The Destination folder\drive has not been selected."\n
									"Please set it in the first Menu option."
#>

<#LOGGED:  Write to the log that MENU item was selected.  Use this at the beginning of each Menu option.

SET_LOGGED {
			Set $MenuX variable
			Check the LOGS
			If it shows incomplete JOBS
					LOG:  Incomplete JOBS found
			Show "There's an incomplete JOB for this plugin.  Do you want to continue?  YES\NO"
				If YES, jump to the option and continue it starting where the QUEUE left off.  Overwrite everything.
				If NO, clear the QUEUE and reset all flags
			Write to Log:  $MenuX was selected.}
#>

<#Menu 1:		"Select the destination folder\drive for the symlink to point towards your uncompressed software." (DONE)

			LOGGED
			Dialogue.SelectFolder()
			LOG:  "$_.SelectedFolder was selected."
			Write $_ variable to JSON
			LOG:  "Destination folder\drive `"$_`" successfully written to the Symlinker Plugin database."
			Message Box:  Your Destination folder\drive has been selected.
DONE #>

<#Menu 2:		"Select the destination folder\drive for your compressed archive." (DONE)

			LOGGED
			Dialogue.SelectFolder()
			LOG:  "$_.SelectedFolder was selected as the place to store compressed archives."
			Write variable to JSON
			LOG:  "Destination folder\drive `"$_`" successfully written to the Symlinker Plugin database."
			Message Box:  Your Destination folder\drive has been selected.
#>

<#Menu 3:  	"Archive and delete the Installation folder(s) of the selected games."  (DONE)

			LOGGED
			FOR-EACH LOOP of $_.SelectedGames
				SET Variable of $CurrentGame
				GET $_.InstallationDirectory
				$GAMEDIRECTORY = $_
				IF $GAMEDIRECTORY != True (
					LOG:  $CurrentGame at $GAMEDIRECTORY has an invalid install folder.
					Message Box: "$CurrentGame has an invalid Install Folder.  Please install the game first."
					(Skip current Loop and move onto next game.)  )
				JSON:  Write the Original Installation Path to $SelectedGames
				LOG:  Compressing CURRENT_GAME Files
				Activate the 7z script.
					By Default:  Use 7Z -Ultra_Compression with -Delete_After_Finished on $InstallationDirectory
					##Make sure this only zips the folder and a level down into the contents itself.
				If $InstallationFolder hasn't been deleted
					(
							Throw ERROR:
							Message Box:  "The Installation Folder wasn't deleted. Is a file there still open?"
							LOG:  The Installation Folder to $CurrentGame wasn't deleted.
					)
					Else:
							LOG:  $CURRENT_GAME finished compressing
				JSON: $CURRENT_GAME is now compressed at $Archive_Location as $CompressedFileName
				LOG:  JSON write of $CURRENT_GAME successful
				Mark game as uninstalled on Playnite
				LOG:  "Game marked as Uninstalled"
			LOG:  "All games successfully compressed."
			
			Folder where game was is now archived, the folder deleted, and marked "Uninstalled."
#>

<#Menu 4:	"Extract selected game(s) from archives to the Played."
			"Extract selected game(s) from archives to the Destination folder and be Playable."

Got a problem.  I can't just plug anything into the Script areas.  Other people might be angry at what I overwrite.

How to "Be playable"?

Set uninstalled as Installed?



			LOGGED
			CHECK_SELECTED_FOLDER
			FOR-EACH LOOP of $_.SelectedGames
				Get the Playnite Numerical ID ($MatchingID) of said game
				Look inside JSON for the $MatchingID number
				If not found, throw an error message and log:
					"The requested archive wasn't found in the database."
					BREAK
				GET location of $SavedArchive of the game that has the $MatchingID
				7z Script:  Extract $SavedArchive to $DestinationFolder -OverWriteAll
				Overwrite Play state for game with $MatchingID within Playnite
					to point towards the 
				SET JSON for $MatchingID as Playable
			
			
			
				$InstallationFolder = $Some.Playnite.API
				If ($InstallationFolder = Null)
					Throw ERROR Message
					BREAK
				GET $JSON.ArchiveLocation
				Test variable IF it's not NULL
				IF Null, throw LOG and ShowMessage(): "There was no path in Playnite for $THIS_GAME."
				IF NOT NULL and returns TRUE--
				LOG:  Folder found.  Now Tagging MOVING of CURRENT_GAME to Destination Path
				JSON:  Write Destination Path
				Activate 7zip script:
					Default is decompress archive to Destination Folder using 7zip.
					Very simple script.  Will move to next instruction automatically when done.
				Pass
#>

<#Menu 5:		"Delete extracted game(s) at Destination folder to make more space."
			LOGGED
			CHECK_SELECTED_FOLDER
#>

<#Menu 6:		"Extract selected game(s) to their original path and Delete archive."
			LOGGED
#>

<#Menu 7:		"Mark selected game(s) as already compressed into an unrunable archive."

			LOGGED
#>

<#Version Info

Revision 01:  Initial Writeup

Revision 02:  Change how compressing ROM logic worked:
				All raw, uncompressed ROMs are now required to be extracted and
				within their own folders now when starting out.

				This allows the existence of ROMs with weird naming schemes without
				having to keep a database of individual files or write in a bunch of
				custom naming schemes to keep track of.

				Most ROMs are individual files dedicated to their console.  Most
				others are ISOs.  Some are Bin\CUE pairs.  Others have individual CD
				audio tracks.  Some like MAME are just WTF???  DOS\Windows games are a
				nightmare to archive.  What works for 1 will not work for another.

				So instead of putting in a lot of logic where exactly named files get
				compressed together or have the user compress everything that might
				screw the algorythm and scripting up, I'm going to have to recommend
				to everyone to put the ROMs into individual folders for each rom\game
				and let Playnite deal with executing the game's.

				Altogether, this means writing a lot less logic, maintenance, or
				having the end user screw around with individual screwy entries.

Revision 03:  Added option to put archive's in a specific direcotry.
#>
