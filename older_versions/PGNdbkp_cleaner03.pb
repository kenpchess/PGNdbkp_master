; PGNdbkp_cleaner01 - PureBasic PGN Cleaner
; Prompts the user to select a PGN file, processes it, and saves a cleaned version.
EnableExplicit

Global linecount.i, cleanedLine.s, line.s, ii.i
Global FileHandle1.i, FileHandle2.i, GameCount.i
Global InputFile.s, OutputFile.s, line.s, Result.i
Global FirstChar.s, LastChar.s, PrevLastChar.s
Global LBracket.s = "[", RBracket.s = "]"
Global LBrace.s = "{" , RBrace.s = "}"
Global LParen.s = "(" , RParen.s = ")"
Global DollarSign.s = "$", WhiteWin.s = "1-0" , BlackWin.s = "0-1", Drawn.s = "1/2-1/2", OtherScore.s = "*"
Global AllMoves.s, TempMoves.s, GameDone_flag.b = #False, wflags.i
Global event.i, appQuit.i, All_Games_Read_Flag.i
Global Dim Scores_Array.s(5)
Global version.s = "PGNdbkp_Cleaner_v03"
Scores_Array(1) = WhiteWin : Scores_Array(2) = BlackWin : Scores_Array(3) = Drawn : Scores_Array(4) = OtherScore

#games_reported_inc = 250
#progressBarEvent = #PB_Event_FirstCustomValue
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



Declare CleanPGNLine()
Declare DoEventMacOS()
CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  Declare.s FileRequester(RequesterType, Title.s, DefaultFile.s = "", AllowedFileTypes.s = "", Message.s = "", Flags = 0)
CompilerEndIf
Declare RemoveBrackets()
Declare RemoveParentheticalLines()
Declare RemoveBraces()
Declare RemoveEllipsisMoves()
Declare RemoveNAGS()

Enumeration filescreen
  #miniwin
  #gamescleaned
  #startbutton
  #quitbutton
  #fileprogresstextgadget
  #fileprogressbar
EndEnumeration


Procedure CleanPGNLine()
  
  Protected startpos.i, endpos.i, Space_Pos.i
  
  PrintN("startclean: AllMoves = " + AllMoves)
  ;If FindString(AllMoves, ";") >= 0
   ; AllMoves = Left(AllMoves, FindString(AllMoves, ";",1) - 1)
   ;EndIf
  
  RemoveBrackets()
  RemoveBraces()
  RemoveParentheticalLines()
  RemoveEllipsisMoves()
  RemoveNAGS()
  
  ; Remove other non-move tokens (e.g., $1, !, ?, etc.)
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("cleanpgn1: AllMoves = " + AllMoves)
  CompilerEndIf
  
  AllMoves = ReplaceString(AllMoves, Chr(10), "")
  AllMoves = ReplaceString(AllMoves, Chr(13), "")
  AllMoves = ReplaceString(AllMoves, "!", "")
  AllMoves = ReplaceString(AllMoves, "%", "")
  ;AllMoves = ReplaceString(AllMoves, "?", "")
  ; Remove multiple spaces
  AllMoves = Trim(AllMoves,Space(1))
  Repeat
    AllMoves = ReplaceString(AllMoves, Space(2) , Space(1))
  Until FindString(AllMoves,Space(2)) <= 0 ; Or AllMovescount >= 10000
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("cleanpgn2: AllMoves = " + AllMoves)
  CompilerEndIf

  EndProcedure
  
  
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
  
  
  Procedure RemoveBrackets()
    
    Protected lbracket_pos.i, rbracket_pos.i, bracketpair_count.i, jj.i
    
    bracketpair_count = 0
    lbracket_pos = 0 : rbracket_pos = 0
    While FindString(AllMoves,LBracket,lbracket_pos + 1) > 0 And FindString(AllMoves,RBracket,rbracket_pos +1)  > 0
      lbracket_pos = FindString(AllMoves,LBracket,lbracket_pos+1)
      rbracket_pos = FindString(AllMoves,RBracket,rbracket_pos+1) 
      If lbracket_pos > 0 And rbracket_pos > 0
        bracketpair_count = bracketpair_count + 1
        Print("Found a pair of brackets..." + "Count = " + Str(bracketpair_count))
        ;MessageRequester("Bracket pair found...","Count = " + Str(bracketpair_count) + " ,Click OK To Continue...")
        TempMoves = Left(AllMoves, lbracket_pos-1) + Mid(AllMoves,Rbracket_pos+1) 
        AllMoves = TempMoves
      Else
        Break
      EndIf
    Wend
    
  EndProcedure
  
  
  Procedure RemoveParentheticalLines()
    
    Protected lparen_pos.i, rparen_pos.i, parenpair_count.i, jj.i, leftover_paren.i, next_space_pos.i
    
    parenpair_count = 0 : lparen_pos = 0 : rparen_pos = 0
    
    While FindString(AllMoves,LParen,lparen_pos+1) > 0 And FindString(AllMoves,RParen,rparen_pos+1) > 0
      lparen_pos = FindString(AllMoves,LParen,lparen_pos+1)
      rparen_pos = FindString(AllMoves,RParen,rparen_pos+1) 
      If lparen_pos > 0 And rparen_pos > 0 And rparen_pos > lparen_pos
        parenpair_count = parenpair_count + 1
        Print("Found a pair of parens..." + "Count = " + Str(parenpair_count))
        ;MessageRequester("Parentheses pair found...","Count = " + Str(parenpair_count) + " ,Click OK To Continue...")
        TempMoves = Left(AllMoves, lparen_pos-1) + Mid(AllMoves,Rparen_pos+1) 
        AllMoves = TempMoves
      Else
        Break
      EndIf
    Wend
    
    ; nasty hack for many left-over parens that were nested)
    AllMoves = ReplaceString(AllMoves,LParen+Space(1),LParen) : leftover_paren = 0
    While FindString(AllMoves,LParen,leftover_paren+1) > 0
      leftover_paren = FindString(AllMoves,LParen)
      next_space_pos = FindString(AllMoves,Space(1),leftover_paren+1)
      If next_space_pos > 0
        AllMoves = Left(AllMoves,leftover_paren-1) + Mid(AllMoves,next_space_pos+1,4000)
      EndIf
    Wend
    
    
  EndProcedure
  
  
  Procedure RemoveBraces()
    
    Protected lbrace_pos.i, rbrace_pos.i, bracepair_count.i, jj.i
    
    bracepair_count = 0
    lbrace_pos = 0 : rbrace_pos = 0
    While FindString(AllMoves,LBrace,lbrace_pos+1) > 0 And FindString(AllMoves,RBrace,rbrace_pos+1)  > 0
      lbrace_pos = FindString(AllMoves,LBrace,lbrace_pos+1)
      rbrace_pos = FindString(AllMoves,RBrace,rbrace_pos+1) 
      If lbrace_pos > 0 And rbrace_pos > 0
        bracepair_count = bracepair_count + 1
        Print("Found a pair of braces..." + "Count = " + Str(bracepair_count))
        ;MessageRequester("Parentheses pair found...","Count = " + Str(parenpair_count) + " ,Click OK To Continue...")
        TempMoves = Left(AllMoves, lbrace_pos-1) + Mid(AllMoves,Rbrace_pos+1) 
        AllMoves = TempMoves
      Else
        Break
      EndIf
    Wend
    
  EndProcedure
  
  
  Procedure RemoveEllipsisMoves()
    
    Protected ii.i
    
    For ii = 150 To 1 Step -1
      AllMoves = ReplaceString(AllMoves,Str(ii) + "...", "")
    Next
    
  EndProcedure
  
  
  Procedure RemoveNAGS()
    
    Protected DollarSign_Pos.i, Space_Pos.i
    
    Dollarsign_Pos = FindString(AllMoves,DollarSign,1)
    While DollarSign_pos > 0
      ;PrintN("Found a NAG $")
      Space_Pos = FindString(AllMoves,Space(1),DollarSign_Pos+1)
      If Space_Pos > 0
        AllMoves = Left(AllMoves,DollarSign_Pos-1) + Mid(AllMoves,Space_Pos+1)
      Else
        AllMoves = Left(AllMoves,DollarSign_Pos-1)
      EndIf
      Dollarsign_Pos = FindString(AllMoves,DollarSign,1) : Space_Pos = FindString(AllMoves,Space(1),DollarSign_Pos+1)
    Wend
    
  EndProcedure
  
  
  
; Main program

OpenConsole()
linecount = 0
; Ask user to select input PGN file

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  InputFile = FileRequester(#RequesterTypeOpen,
                    "Please choose a PGN to open",
                    "/users/kenpchess/",
                    "pgn",
                    "Choose a PGN (.pgn, [SAN] or [UCI]) file only",
                    #PB_Requester_MultiSelection)
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
InputFile.s = OpenFileRequester("Select PGN File", "", "PGN Files (*.pgn;*.txt)|*.pgn;*.txt|All Files|*.*",0)
If InputFile = ""
  MessageRequester("Info", "No file selected. Exiting.")
  End
EndIf
  CompilerEndIf

; Ask user for output filename
OutputFile.s = SaveFileRequester("Save Clean PGN As", "", "Clean PGN Files (*.pgn)|*.pgn",0)
If OutputFile = ""
  MessageRequester("Info", "No output filename specified. Exiting.")
  End
EndIf

wFlags = #PB_Window_SystemMenu | #PB_Window_ScreenCentered
OpenWindow(#miniwin, 0, 0, 900, 300,version + " - Ready to read PGN file..." + InputFile, wFlags)
TextGadget(#gamescleaned, 350, 150, 200, 50, "Games cleaned: ...", #PB_Text_Center)
ButtonGadget(#quitbutton, 400, 225, 100, 30, "Quit")
TextGadget(#fileprogresstextgadget, 10, 200, 800,  40, "", #PB_Text_Center)
ButtonGadget(#startbutton, 200, 60, 500, 30, "CLICK to begin the PGN file cleaning process...")
;AddWindowTimer(#miniwin, 0, 1000)

CreateMenu(0, WindowID(#miniwin))
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      MenuItem(#PB_Menu_About, "PGNdbkp_Cleaner")
      ;MenuItem(#PB_Menu_Preferences, "")
      MenuItem(#PB_Menu_Quit, "")
      BindMenuEvent(0, #PB_Menu_About, @DoEventMacOS())
      ;BindMenuEvent(0, #PB_Menu_Preferences, @DoEventMacOS())
      BindMenuEvent(0, #PB_Menu_Quit, @DoEventMacOS())
      
    CompilerEndIf
  
;BindMenuEvent(0, #PB_Menu_About, @DoEventMacOS())
;BindMenuEvent(0, #PB_Menu_Quit, @DoEventMacOS())

FileHandle1 = ReadFile(0, InputFile)

FileHandle2 = OpenFile(#PB_Any,OutputFile)


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
        If EventGadget() = #quitbutton
          PostEvent(#PB_Event_CloseWindow, #miniwin, 0)
          All_Games_Read_Flag = 1
          Break
        EndIf
        If EventGadget() = #startbutton
          If FileHandle1
            GameCount = 0
            While Not Eof(0)
              GameDone_Flag = #False
              line = ReadString(0)
              FirstChar = Left(line,1)
              LastChar = Right(line,1)
              CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
                PrintN("main: Line = " + Line)
              CompilerEndIf
              linecount = linecount + 1
              If Left(line,2) = "1." And PrevLastChar = RBracket
                WriteStringN(FileHandle2, #CRLF$)
                PrevLastChar = ""
              EndIf
    
              If  FirstChar = LBracket And LastChar = RBracket
                WriteStringN(FileHandle2, Line)
                PrevLastChar = LastChar
                AllMoves = ""
              Else
                For ii = 1 To 4
                  If FindString(line,Scores_Array(ii),1) > 0
                    AllMoves = AllMoves + line
                    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
                      PrintN("") : PrintN("********** AllMoves = " + AllMoves) : PrintN("")
                    CompilerEndIf
                    CleanPGNLine()
                    WriteStringN(FileHandle2, AllMoves+#CRLF$)
                    GameDone_Flag = #True : AllMoves = ""
                    GameCount = GameCount + 1
                    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
                      PrintN("") : PrintN("GameCount = " + Str(GameCount) + #CRLF$)
                    CompilerEndIf
                    If GameCount % #games_reported_inc = 0
                      SetGadgetText(#gamescleaned,"Games Cleaned: ..." + Str(GameCount)) 
                      ;Result = MessageRequester("...Games are being cleaned..","About " + Str(gameCount) + " games cleaned so far. Click OK to continue.")
                      While WindowEvent() : Wend
                    EndIf
                    Break
                  EndIf
                Next
                If GameDone_Flag = #False
                  AllMoves = AllMoves + line
                 EndIf
               EndIf
             Wend
             SetGadgetText(#gamescleaned,"Games Cleaned: ..." + Str(GameCount))
             While WindowEvent() : Wend
            CloseFile(0)
          Else
            MessageRequester("Error", "Failed to read input file.")
          EndIf
          
          ; Write cleaned content to output file
          If FileHandle2
            CloseFile(FileHandle2)
            MessageRequester("Done", "Clean PGN saved successfully.")
          Else
            MessageRequester("Error", "Failed to create output file.")
          EndIf
        EndIf
        ;CreateThread(@LoadPGN_Thread(), 0)

      Case #PB_Event_Timer
        If EventTimer() = 0
          ; a running clock shows that window events are not blocked
          ;SetGadgetText(#clocktimer, FormatDate("%hh:%ii:%ss", Date()-startdate))     
        EndIf
      Case #progressBarEvent        ; process the custom event
        ; get the current file read location
        ;currentRead = EventData()       
        ; calculate the current location of the progress bar
        ;If fileLen > 65536
         ; inc = currentRead / (fileLen / 65536)
        ;Else
         ; inc = currentRead
        ;EndIf
        ;SetGadgetState (#fileprogressbar, inc)               ; increment the progress bar & label with the read location value
        ;SetGadgetText(#fileprogresstextgadget, "PGNFile Read Progress (" + Str(currentRead) + "/" + Str(fileLen) + ")")
        ;If currentRead = fileLen
         ; DisableGadget(#startbutton, #False)
        ;EndIf
        
    EndSelect
  Until All_Games_Read_Flag = 1
  
  Delay(200)
  CloseWindow(#miniwin)
; IDE Options = PureBasic 6.30 - C Backend (MacOS X - x64)
; CursorPosition = 386
; FirstLine = 368
; Folding = ----
; EnableXP
; DPIAware
; Executable = PGNdbkp_cleaner03.app
