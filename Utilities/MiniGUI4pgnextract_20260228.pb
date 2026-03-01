EnableExplicit

Global version.s = "MiniGUI4PgnExtract_26050228"
Global commandX.s, PGN_Extract_Path.s, InputFile.s, OutputFile.s, ProgramID.i, wFlags.i
Global event.i, All_Games_Read_Flag.b, FileHandle1.i, FileHandle2.i, GameCount.i
Global GamesPerFile.s, FENpattern.s, PlayerSearch1.s, PiecePattern.s, DupesFile.s

Enumeration filescreen
  #miniwin
  #commandarea
  #cleanbutton
  #longalg1button
  #openingbutton
  #gamesperfilebutton
  #moveFENSonlybutton
  #moveevalsbutton
  #matchFENbutton
  #searchforplayerbutton
  #matchPiecePatternbutton
  #removedupesbutton
  #quitbutton
  #fileprogresstextgadget
EndEnumeration


#RequesterTypeOpen = 0
#RequesterTypeSave = 1

#NSLeftMouseUp        = 2
#NSRightMouseUp       = 4
#NSMouseMoved         = 5
#NSKeyDown            = 10
#NSKeyUp              = 11

#NSAlphaShiftKeyMask = 1 << 16
#NSShiftKeyMask      = 1 << 17
#NSControlKeyMask    = 1 << 18
#NSAlternateKeyMask  = 1 << 19
#NSCommandKeyMask    = 1 << 20


Declare DoEventMacOS()
CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  Declare.s FileRequester(RequesterType, Title.s, DefaultFile.s = "", AllowedFileTypes.s = "", Message.s = "", Flags = 0)
CompilerEndIf
Declare PgnExtract_Clean()
Declare PgnExtract_HyphenatedLongAlgebraic()
Declare PgnExtract_PGNdbkp_CreateEngineMatchOpeningBook()
Declare PgnExtract_OutputGamesPerFile()
Declare PgnExtract_OutputMoveFENsonly()
Declare PgnExtract_MoveEvals()
Declare PgnExtract_MatchGamesWithFEN()
Declare PgnExtract_SearchForPlayerGames()
Declare PgnExtract_MatchGamesWithPiecePattern()
Declare PgnExtract_ShowAndRemoveDuplicates()


CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  Procedure DoEventMacOS()
    Select EventMenu()
      Case #PB_Menu_Quit
        PostEvent(#PB_Event_CloseWindow, #miniwin, 0)
      Case #PB_Menu_About
        ;MessageRequester("About", "PGNdb"+version, #PB_MessageRequester_Info)
        ;LoadHelpData()
        ;CloseWindow(#mainwin)
      Case #PB_Menu_Preferences
        ;PostEvent(#PB_Event_Menu, 0, #MyMenuItem_Preferences)
        ;
    EndSelect
  EndProcedure
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  Procedure.s FileRequester(RequesterType, Title.s, DefaultFile.s = "", AllowedFileTypes.s = "", Message.s = "", Flags = 0)
  Protected Result.s, Path.s, NSPanel, NSEnumerator, NSURL, NSString
  
  If RequesterType = #RequesterTypeSave
    NSPanel = CocoaMessage(0, 0, "NSSavePanel savePanel")
  Else
    NSPanel = CocoaMessage(0, 0, "NSOpenPanel openPanel")
    If Flags & #PB_Requester_MultiSelection
      CocoaMessage(0, NSPanel, "setAllowsMultipleSelection:", #YES)
    EndIf    
  EndIf
  
  Path = GetPathPart(DefaultFile)
  DefaultFile = GetFilePart(DefaultFile)
  
  CocoaMessage(0, NSPanel, "setTitle:$", @Title)
  CocoaMessage(0, NSPanel, "setMessage:$", @Message)
  CocoaMessage(0, NSPanel, "setAllowedFileTypes:", CocoaMessage(0, CocoaMessage(0, 0, "NSString stringWithString:$", @AllowedFileTypes), "componentsSeparatedByString:$", @"|"))
  CocoaMessage(0, NSPanel, "setDirectoryURL:", CocoaMessage(0, 0, "NSURL fileURLWithPath:$", @Path))
  CocoaMessage(0, NSPanel, "setNameFieldStringValue:$", @DefaultFile)
  
  If CocoaMessage(0, NSPanel, "runModal")
    If RequesterType = #RequesterTypeSave
      Result = PeekS(CocoaMessage(0, CocoaMessage(0, CocoaMessage(0, NSPanel, "URL"), "path"), "fileSystemRepresentation"), -1, #PB_Ascii)
    Else
      NSEnumerator = CocoaMessage(0, CocoaMessage(0, NSPanel, "URLs"), "objectEnumerator")
      NSURL = CocoaMessage(0, NSEnumerator, "nextObject")
      If NSURL
        Result = PeekS(CocoaMessage(0, CocoaMessage(0, NSURL, "path"), "fileSystemRepresentation"), -1, #PB_Ascii)
        NSURL = CocoaMessage(0, NSEnumerator, "nextObject")
        While NSURL
          Result + "|" + PeekS(CocoaMessage(0, CocoaMessage(0, NSURL, "path"), "fileSystemRepresentation"), -1, #PB_Ascii)
          NSURL = CocoaMessage(0, NSEnumerator, "nextObject")
        Wend
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn Result
EndProcedure
CompilerEndIf


Procedure PgnExtract_Clean()
  
  ; Ask user for output filename
  OutputFile = SaveFileRequester("Save modified PGN As", "", "Clean PGN Files (*.pgn)|*.pgn",0)
  If OutputFile = ""
    MessageRequester("Info", "No output filename specified. Exiting.")
    End
  EndIf
  commandX = " -C -N -V " + InputFile + " --output " + OutputFile
  PrintN("pgn-extract path = " + PGN_Extract_Path)
  PrintN("command = " + commandX)
  ProgramID = RunProgram(PGN_Extract_Path, commandX, GetCurrentDirectory(), #PB_Program_Open | #PB_Program_Read | #PB_Program_Write)
  PrintN("ProgramID = " + Str(ProgramID))
  If ProgramID
    PrintN("pgn-extract cleaning is running...")
    SetGadgetText(#commandarea,"pgn-extract " + commandX)
    While WindowEvent() : Wend
    MessageRequester("PGNExtract cleaning option was called","Click 'OK' to quit...")
  EndIf
  CloseFile(0)
  
EndProcedure


Procedure PgnExtract_HyphenatedLongAlgebraic()
  
  OutputFile = SaveFileRequester("Save long algebraic As", "", "Algebraic PGN Files (*.pgn)|*.pgn",0)
  If OutputFile = ""
    MessageRequester("Info", "No output filename specified. Exiting.")
    End
  EndIf
  commandX = " -Whalg -o " + OutputFile + Space(1) + InputFile
  ;PGN_Extract_Path = "/usr/local/bin/pgn-extract"
  PrintN("pgn-extract path = " + PGN_Extract_Path)
  PrintN("command = " + commandX)
  ProgramID = RunProgram(PGN_Extract_Path, commandX, GetCurrentDirectory(), #PB_Program_Open | #PB_Program_Read | #PB_Program_Write)
  PrintN("ProgramID = " + Str(ProgramID))
  If ProgramID
    PrintN("pgn-extract conversion is running...")
    SetGadgetText(#commandarea,"pgn-extract " + commandX)
    While WindowEvent() : Wend
    MessageRequester("PGNExtract hyphenated long algebraic option was called","Click 'OK' to quit...")
  EndIf
  CloseFile(0)
  
EndProcedure


Procedure PgnExtract_PGNdbkp_CreateEngineMatchOpeningBook()
  
  OutputFile = SaveFileRequester("Save enginematch book file As", "/users/kenpresley/desktop/16ply_openings_20000_spaces.pb", "PB book Files (*.pb)|*.pb",0)
  If OutputFile = ""
    MessageRequester("Info", "No output filename specified. Exiting.")
    End
  EndIf
  commandX = " -Wuci --plylimit 16 --nomovenumbers --notags -o " + OutputFile + Space(1) + InputFile
  PrintN("pgn-extract path = " + PGN_Extract_Path)
  PrintN("command = " + commandX)
  ProgramID = RunProgram(PGN_Extract_Path, commandX, GetCurrentDirectory(), #PB_Program_Open | #PB_Program_Read | #PB_Program_Write)
  PrintN("ProgramID = " + Str(ProgramID))
  If ProgramID
    PrintN("pgn-extract running...")
    SetGadgetText(#commandarea,"pgn-extract " + commandX)
    While WindowEvent() : Wend
    MessageRequester("PGNExtract create book option called","Click 'OK' to quit...")
  EndIf
  CloseFile(0)
  
EndProcedure


Procedure PgnExtract_OutputGamesPerFile()
  
  MessageRequester("File output Info", "Note that output pgns will be numbered 1, 2, 3 etc....")
  GamesPerFile = InputRequester("Games per output pgn","Enter the number of games per output pgn:", "1000")
  commandX = Space(1) + InputFile + " -#" + GamesPerFile
  PrintN("pgn-extract path = " + PGN_Extract_Path)
  PrintN("command = " + commandX)
  ProgramID = RunProgram(PGN_Extract_Path, commandX, GetCurrentDirectory(), #PB_Program_Open | #PB_Program_Read | #PB_Program_Write)
  PrintN("ProgramID = " + Str(ProgramID))
  If ProgramID
    PrintN("pgn-extract running...")
    SetGadgetText(#commandarea,"pgn-extract " + commandX)
    While WindowEvent() : Wend
    MessageRequester("PGNExtract games/file option called","Click 'OK' to quit...")
  EndIf
  CloseFile(0)
  
EndProcedure


Procedure PgnExtract_OutputMoveFENsonly()
  
  OutputFile = SaveFileRequester("Save game FENS As", "", "Move FEN Files (*.txt)|*.txt",0)
  If OutputFile = ""
    MessageRequester("Info", "No output filename specified. Exiting.")
    End
  EndIf
  commandX = " -Wfen --notags -o " + OutputFile + Space(1) + InputFile
  ;PGN_Extract_Path = "/usr/local/bin/pgn-extract"
  PrintN("pgn-extract path = " + PGN_Extract_Path)
  PrintN("command = " + commandX)
  ProgramID = RunProgram(PGN_Extract_Path, commandX, GetCurrentDirectory(), #PB_Program_Open | #PB_Program_Read | #PB_Program_Write)
  PrintN("ProgramID = " + Str(ProgramID))
  If ProgramID
    PrintN("pgn-extract conversion is running...")
    SetGadgetText(#commandarea,"pgn-extract " + commandX)
    While WindowEvent() : Wend
    MessageRequester("PGNExtract Output FENS (-Wfen --notags) option was called","Click 'OK' to quit...")
  EndIf
  CloseFile(0)
  
EndProcedure


Procedure PgnExtract_MoveEvals()
  
  OutputFile = SaveFileRequester("Save move evals PGN As", "", "Eval PGN Files (*.pgn)|*.pgn",0)
  If OutputFile = ""
    MessageRequester("Info", "No output filename specified. Exiting.")
    End
  EndIf
  commandX = " --evaluation -o " + OutputFile + Space(1) + InputFile
  ;PGN_Extract_Path = "/usr/local/bin/pgn-extract"
  PrintN("pgn-extract path = " + PGN_Extract_Path)
  PrintN("command = " + commandX)
  ProgramID = RunProgram(PGN_Extract_Path, commandX, GetCurrentDirectory(), #PB_Program_Open | #PB_Program_Read | #PB_Program_Write)
  PrintN("ProgramID = " + Str(ProgramID))
  If ProgramID
    PrintN("pgn-extract conversion is running...")
    SetGadgetText(#commandarea,"pgn-extract " + commandX)
    While WindowEvent() : Wend
    MessageRequester("PGNExtract Output Move evals (--evaluation) option was called","Click 'OK' to quit...")
  EndIf
  CloseFile(0)
  
EndProcedure


Procedure PgnExtract_MatchGamesWithFEN()
  
  OutputFile = SaveFileRequester("Match games with FEN", "", "Game Match FEN Files (*.pgn)|*.pgn",0)
  If OutputFile = ""
    MessageRequester("Info", "No output filename specified. Exiting.")
    End
  EndIf
  FENpattern = InputRequester("Match Games with FEN pattern","Enter the complete FEN position string you wish to match, i.e. position after 1. e4:", "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1")
  commandX = " --fenpattern " + #DQUOTE$ + FENpattern + #DQUOTE$ + " -o " + OutputFile + Space(1) + InputFile
  PrintN("pgn-extract path = " + PGN_Extract_Path)
  PrintN("command = " + commandX)
  ProgramID = RunProgram(PGN_Extract_Path, commandX, GetCurrentDirectory(), #PB_Program_Open | #PB_Program_Read | #PB_Program_Write)
  PrintN("ProgramID = " + Str(ProgramID))
  If ProgramID
    PrintN("pgn-extract running...")
    SetGadgetText(#commandarea,"pgn-extract " + commandX)
    While WindowEvent() : Wend
    MessageRequester("PGNExtract games with FEN pattern option called","Click 'OK' to quit...")
  EndIf
  CloseFile(0)
  
EndProcedure


Procedure PgnExtract_SearchForPlayerGames()
  
  OutputFile = SaveFileRequester("Player Search Output", "", "Matching Games File (*.pgn)|*.pgn",0)
  If OutputFile = ""
    MessageRequester("Info", "No output filename specified. Exiting.")
    End
  EndIf
  PlayerSearch1 = InputRequester("Search Games for Player","Enter the players name (last name first) you wish to search for, i.e. Stockfish:", "Stockfish")
  commandX = " -Tp" + PlayerSearch1 + " -o " + OutputFile + Space(1) + InputFile
  PrintN("pgn-extract path = " + PGN_Extract_Path)
  PrintN("command = " + commandX)
  ProgramID = RunProgram(PGN_Extract_Path, commandX, GetCurrentDirectory(), #PB_Program_Open | #PB_Program_Read | #PB_Program_Write)
  PrintN("ProgramID = " + Str(ProgramID))
  If ProgramID
    PrintN("pgn-extract running...")
    SetGadgetText(#commandarea,"pgn-extract " + commandX)
    While WindowEvent() : Wend
    MessageRequester("PGNExtract games with Player search option called","Click 'OK' to quit...")
  EndIf
  ;CloseFile(0)
  
  
EndProcedure


Procedure PgnExtract_MatchGamesWithPiecePattern()
  
  OutputFile = SaveFileRequester("Match games with Piece Pattern", "", "Game Match Piece Pattern OutPut File (*.pgn)|*.pgn",0)
  If OutputFile = ""
    MessageRequester("Info", "No output filename specified. Exiting.")
    End
  EndIf
  PiecePattern = InputRequester("Match Games with Piece Pattern","Enter the Pgn-Extract Piece Pattern string you wish to match, such as one side has 2 bishops, the other side has 2 knights, i.e. [q*r*b2n0p* q=r=b0n2p=]:", "q*r*b2n0p* q=r=b0n2p=")
  ;commandX = pgn-extract --materialz "q*r*b2n0p* q=r=b0n2p=" /Users/kenpchess/Desktop/tcec_s28_divp_clean.pgn -opatterngames.pgn
  commandX = " --materialz " + #DQUOTE$ + PiecePattern + #DQUOTE$ + Space(1) + InputFile + " -o" + OutputFile 
  PrintN("pgn-extract path = " + PGN_Extract_Path)
  PrintN("command = " + commandX)
  ProgramID = RunProgram(PGN_Extract_Path, commandX, GetCurrentDirectory(), #PB_Program_Open | #PB_Program_Read | #PB_Program_Write)
  PrintN("ProgramID = " + Str(ProgramID))
  If ProgramID
    PrintN("pgn-extract running...")
    SetGadgetText(#commandarea,"pgn-extract " + commandX)
    While WindowEvent() : Wend
    MessageRequester("PGNExtract games with Piece pattern match option called","Click 'OK' to quit...")
  EndIf
  ;CloseFile(0)
  
  
  
EndProcedure


Procedure PgnExtract_ShowAndRemoveDuplicates()
  
  OutputFile = SaveFileRequester("Removed Duplicates PGN", "", "Removed Duplicates PGN Output File (*.pgn)|*.pgn",0)
  If OutputFile = ""
    MessageRequester("Info", "No output filename specified. Exiting.")
    End
  EndIf
  DupesFile = OutputFile : DupesFile = ReplaceString(DupesFile,".pgn","_dupes.txt")
  ; pgn-extract --duplicates dupes.pgn --output unique.pgn file.pgn
  commandX = " --duplicates " + DupesFile + " --output " + OutputFile + Space(1) + InputFile
  PrintN("pgn-extract path = " + PGN_Extract_Path)
  PrintN("command = " + commandX)
  ProgramID = RunProgram(PGN_Extract_Path, commandX, GetCurrentDirectory(), #PB_Program_Open | #PB_Program_Read | #PB_Program_Write)
  PrintN("ProgramID = " + Str(ProgramID))
  If ProgramID
    PrintN("pgn-extract conversion is running...")
    SetGadgetText(#commandarea,"pgn-extract " + commandX)
    While WindowEvent() : Wend
    MessageRequester("PGNExtract Remove duplicates (--duplicates) option [note duplicates are in file " + DupesFile + "]" ,"Click 'OK' To quit...")
  EndIf
  ;CloseFile(0)
  
  
EndProcedure



OpenConsole()

Repeat
  PGN_Extract_Path = InputRequester("PGN-Extract binary location","Enter the complete path of your PGN-Extract binary. Note that PGN-Extract is available from [https://www.cs.kent.ac.uk/people/staff/djb/pgn-extract/]:", "/usr/local/bin/pgn-extract")
Until FileSize(PGN_Extract_Path) > 0
  

; select input PGN file

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  InputFile = FileRequester(#RequesterTypeOpen,
                    "Please choose an input PGN to open",
                    "/users/kenpchess/",
                    "pgn",
                    "Choose an input PGN (.pgn, [SAN] or [UCI]) file only",
                    #PB_Requester_MultiSelection)
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
InputFile = OpenFileRequester("Select [source input] PGN File", "", "PGN Files (*.pgn;*.txt)|*.pgn;*.txt|All Files|*.*",0)
If InputFile = ""
  MessageRequester("Info", "No file selected. Exiting.")
  End
EndIf
  CompilerEndIf



wFlags = #PB_Window_SystemMenu | #PB_Window_ScreenCentered
OpenWindow(#miniwin, 0, 0, 1000, 800,version + " - Ready to read PGN file..." + InputFile, wFlags)
TextGadget(#commandarea, 50, 550, 800, 50, "pgn-extract command area: ...", #PB_Text_Center)
ButtonGadget(#quitbutton, 440, 725, 100, 30, "Quit")
TextGadget(#fileprogresstextgadget, 10, 200, 800,  40, "", #PB_Text_Center)
ButtonGadget(#cleanbutton, 200, 60, 300, 30, "Clean PGN file...")
ButtonGadget(#longalg1button, 525, 60, 300, 30, "Output Long algebraic...")
ButtonGadget(#openingbutton, 200, 120, 300, 30, "Create PGNdbkp enginematch book...")
ButtonGadget(#gamesperfilebutton, 525, 120, 300, 30, "Output X games per pgn file...")
ButtonGadget(#moveFENsonlybutton, 200, 180, 300, 30, "Output move FENs only...")
ButtonGadget(#moveevalsbutton, 525, 180, 300, 30, "Output move evaluations...")
ButtonGadget(#matchFENbutton, 200, 240, 300, 30, "Match Games with FEN pattern...")
ButtonGadget(#searchforplayerbutton, 525, 240, 300, 30, "Search for player's games...")
ButtonGadget(#matchPiecePatternbutton, 200, 300, 300, 30, "Match Games with piece pattern...")
ButtonGadget(#removedupesbutton, 525, 300, 300, 30, "Show and remove duplicates...")


CreateMenu(0, WindowID(#miniwin))
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      MenuItem(#PB_Menu_About, "MiniGUI_PgnExtract")
      ;MenuItem(#PB_Menu_Preferences, "")
      MenuItem(#PB_Menu_Quit, "")
      ;BindMenuEvent(0, #PB_Menu_About, @DoEventMacOS())
      ;BindMenuEvent(0, #PB_Menu_Preferences, @DoEventMacOS())
      ;BindMenuEvent(0, #PB_Menu_Quit, @DoEventMacOS())
      
    CompilerEndIf
  
;BindMenuEvent(0, #PB_Menu_About, @DoEventMacOS())
;BindMenuEvent(0, #PB_Menu_Quit, @DoEventMacOS())


Repeat
    event = WaitWindowEvent()
    Select Event
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      Case #PB_Menu_Quit
        PostEvent(#PB_Event_CloseWindow, #miniwin, 0)
        All_Games_Read_Flag = 1
        Break
      CompilerEndIf
      Case #PB_Event_CloseWindow
        Select EventWindow()
          Case #miniwin
            All_Games_Read_Flag = 1
            Break
        EndSelect
      Case #PB_Event_Gadget
        Select EventGadget()
          Case #quitbutton
            PostEvent(#PB_Event_CloseWindow, #miniwin, 0)
            All_Games_Read_Flag = 1
            Break
          Case #cleanbutton
            PgnExtract_Clean()
          Case #longalg1button
            PgnExtract_HyphenatedLongAlgebraic()
          Case #openingbutton
            PgnExtract_PGNdbkp_CreateEngineMatchOpeningBook()
          Case #gamesperfilebutton
            PgnExtract_OutputGamesPerFile()
          Case #moveFENsonlybutton
            PgnExtract_OutputMoveFENSonly()
          Case #moveevalsbutton
            PgnExtract_MoveEvals()
          Case #matchFENbutton
            PgnExtract_MatchGamesWithFEN()
          Case #searchforplayerbutton
            PgnExtract_SearchForPlayerGames()
          Case #matchPiecePatternbutton
            PgnExtract_MatchGamesWithPiecePattern()
          Case #removedupesbutton
            PgnExtract_ShowAndRemoveDuplicates()
        EndSelect
      Case #PB_Event_Timer
        If EventTimer() = 0
          ; a running clock shows that window events are not blocked
          ;SetGadgetText(#clocktimer, FormatDate("%hh:%ii:%ss", Date()-startdate))     
        EndIf
      ;Case #progressBarEvent        ; process the custom event
        ; not yet implemented
    EndSelect
  Until All_Games_Read_Flag = 1
; IDE Options = PureBasic 6.30 - C Backend (MacOS X - x64)
; CursorPosition = 312
; FirstLine = 305
; Folding = ----
; EnableXP
; DPIAware
; Executable = MiniGUI4PgnExtract_20260228.app
