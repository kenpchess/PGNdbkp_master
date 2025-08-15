; PureBasic PGN SAN-UCI-notation Reader, SQLite chess DB, and Display (by kenpchess).
; Many thanks to all of the coding experts at the PureBasic forum. This program
; contains code snippets from "Azjio", "Fred", "mk-soft",	"ti994A", "idle",
; "infratec", and others! Thank you all for your code examples!
;
CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  EnableExplicit
CompilerEndIf

Global version.s = "_20250813"
#game_max = 200000 : #halfmove_max = 2000 : #PGNSizeSkipProgressStartBtn = 10000000
#canvas_gadgetX = 75 : #canvas_gadgetY = 470
#cg_width = 575 : #cg_height = 545
#alg_filesY = 20 : #alg_rankX = 20
#alg_baseX = 25 : #alg_baseY = 20
#progressBarEvent = #PB_Event_FirstCustomValue

#ButtonsLeftEdgeDefaultX = 675
#playgadgetwidth = 685 : #playgadgetDefaultHeight = 425
#movesgadgetX = 730 : #movesgadgetwidth = 275 : #movesgadgetDefaultHeight = 425

#fileinfogadgetDefaultX = 150 : #fileinfogadgetDefaultY = 440 : #fileinfogadgetwidth = 450
#FENBtnDefaultY = 475 : #FENBtnDefaultX = #ButtonsLeftEdgeDefaultX - 5
#Single_MoveDefaultY = 510 : #Single_MoveDefaultX = #ButtonsLeftEdgeDefaultX
#InfoFieldDefaultY = 545 : #InfoFieldDefaultHeight = 115
#InfoFieldDefaultX = #ButtonsLeftEdgeDefaultX
#prevbtnDefaultX = #ButtonsLeftEdgeDefaultX : #prevbtnDefaultY = 675
#nextbtnDefaultX = #ButtonsLeftEdgeDefaultX : #nextbtnDefaultY = 710
#dbbtn1DefaultX = #ButtonsLeftEdgeDefaultX  : #dbbtn1DefaultY = 745
#dbbtn2DefaultX = #ButtonsLeftEdgeDefaultX  : #dbbtn2DefaultY = 778
#sfbtnDefaultX = #ButtonsLeftEdgeDefaultX : #sfbtnDefaultY = 810
#sfbtn10secDefaultX = #ButtonsLeftEdgeDefaultX + 80 : #sfbtn10secDefaultY = 810
#PSearchbtnDefaultX = #ButtonsLeftEdgeDefaultX : #PSearchbtnDefaultY = 842
#FENEditbtnDefaultX = #ButtonsLeftEdgeDefaultX : #FENEditbtnDefaultY = 874

#btnbr40DefaultY = 435 : #btnbn40DefaultY = 475 : #btnbb40DefaultY = 515
#btnbq40DefaultY = 555 : #btnbk40DefaultY = 595 : #btnbp40DefaultY = 635

#btnwr40DefaultY = 675 : #btnwn40DefaultY = 715 : #btnwb40DefaultY = 755
#btnwq40DefaultY = 795 : #btnwk40DefaultY = 835 : #btnwp40DefaultY = 875

#btnes32DeFaultY = 915 : #btndone40DefaultX = 810 : #btndone40DefaultY = #FENEditbtnDefaultY

#progressBytes = 2000
#mainwinDefaultWidth = 1040 : #mainwinDefaultHeight = 1020
#SQLBatchOfGames = 500

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  #StockfishPath = "/usr/local/bin/stockfish"                                    ; Adjust this to the actual path of your Stockfish executable
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  #StockfishPath = "C:\PureBasic\stockfish.exe"                                    ; Adjust this to the actual path of your Stockfish executable
CompilerEndIf

Global SquareSize = 60

Global Debug_Board_Squares = #False
Global Dim BlackPlayers.s(#game_max)
Global Dim Display_Flag.i(#game_max)
Global Dim Each_Game_Result.s(#game_max)
Global Dim EventSites.s(#game_max)
Global Dim GameDates.s(#game_max)
Global Dim WhiteElos.s(#game_max)
Global Dim BlackElos.s(#game_max)
Global Dim FEN_setup_str.s(#game_max)
Global Dim FEN_setup_flag.b(#game_max)
Global Dim FilePGNs.s(#game_max)
Global Dim Gadget_List_Display.s(#game_max)
Global Dim Game_FEN_Positions.s(#halfmove_max)
Global Dim GameScore_UCI_HalfMoves.s(#halfmove_max)
Global Dim GameScore_Plain_HalfMoves.s(#halfmove_max)
Global Dim WhitePlayers.s(#game_max)
Global PGNFileName.s, All_Games_Read_Flag.b
Global AssignedChessDate.s = FormatDate("%yyyy%mm%dd", Date())                   ; todays chess date (for pgns with missing date)
Global EmptySq_Button_Flag.b, Piece_Button_Flag.b
Global PlayEngineEditCount.i, PlayEngineFENstr.s, QuickEngine_Flag.b = #False

Global Dim MbxBrd.b(119)                                   ; the semi-famous mailbox chessboard used by me in 1975 (and others in similar timeframe)
Global Dim ValidQueenMbxSqs.s(119)                         ; this array contains all valid queen move squares from every square on the mailbox board

;Square numbers for mailbox board mbxbrd(119)

;000 001 002 003 004 005 006 007 008 009     ;000 001 002 003 004 005 006 007 008 009
;010 011 012 013 014 015 016 017 018 019     ;010 011 012 013 014 015 016 017 018 019
;020 021 022 023 024 025 026 027 028 029     ;020  a8  b8  c8  d8  e8  f8  g8  h8 029
;030 031 032 033 034 035 036 037 038 039     ;030  a7  b7  c7  d7  e7  f7  g7  h7 039
;040 041 042 043 044 045 046 047 048 049     ;040  a6  b6  c6  d6  e6  f6  g6  h6 049
;050 051 052 053 054 055 056 057 058 059     ;050  a5  b5  c5  d5  e5  f5  g5  h5 059
;060 061 062 063 064 065 066 067 068 069     ;060  a4  b4  c4  d4  e4  f4  g4  h4 069
;070 071 072 073 074 075 076 077 078 079     ;070  a3  b3  c3  d3  e3  f3  g3  h3 079
;080 081 082 083 084 085 086 087 088 089     ;080  a2  b2  c2  d2  e2  f2  g2  h2 089
;090 091 092 093 094 095 096 097 098 099     ;090  a1  b1  c1  d1  e1  f1  g1  h1 099
;100 101 102 103 104 105 106 107 108 109     ;100 101 102 103 104 105 106 107 108 109
;110 111 112 113 114 115 116 117 118 119     ;110 111 112 113 114 115 116 117 118 119

; Only squares 021 - 098 are actually used.
; The rest are off-the-board border squares.

Global Dim PieceImages(25) ; 12 piece types (6 white, 6 black) + 40 pixel versions + emptysq
Global Dim PieceLetters.s(12)

Global UCI_move_str.s, Saved_MoveNumber_Construct.s, GameLink.s
Global GameCount.i, MoveColumn.b
Global GameIndex, HalfMoveCount, TotalHalfMoves, SQL_flag, SF_Time_Per_Move
Global FENpositionstr.s
Global SF_fenposition.s
Global GameTag.s, Game_Result.s
Global Game_Prefix.s = "G#"
Global Ellipsis_move.s = "1. ..."
Global Dot_Sequence.s = "..."
Global DollarSign.s = "$"
Global Win1.s = "1-0" , Lose1.s = "0-1" , Draw1.s = "1/2-1/2", Other1.s = " *"
Global GameResult_SearchMask.s = "1-0xx0-1xx1/2-1/2xx *"
Global WhiteKingSideCastle.s = "e1-g1" , WhiteQueenSideCastle.s = "e1-c1"
Global BlackKingSideCastle.s = "e8-g8" , BlackQueenSideCastle.s = "e8-c8"
Global FEN_Start_Position.s = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
Global AlgSquares.s = "000102030405060708091011121314151617181920a8b8c8d8e8f8g8h82930a7b7c7d7e7f7g7h73940a6b6c6d6e6f6g6h64950a5b5c5d5e5f5g5h55960a4b4c4d4e4f4g4h46970a3b3c3d3e3f3g3h37980a2b2c2d2e2f2g2h28990a1b1c1d1e1f1g1h1"
Global WhiteTag.s = "[White", BlackTag.s = "[Black", EventTag.s = "[Event", SiteTag.s = "[Site"
Global DateTag.s = "[Date", WhiteEloTag.s = "[WhiteElo", BlackEloTag.s = "[BlackElo", FENTag.s = "[FEN"
Global PGN_InputFile, DB_InputFile.s, Search_player.s
Global MultiPV.b, cpscore_pos, pva, pvb
Global G1_pos, G2_pos
Global GameScore_MoveList.s
Global Dim pvstring.s(2) 
Global Dim cpscore_str.s(2)
Global mailbox_editor_squareXY.b
Global GamesInserted.i
Global ResultPGN.s
Global startdate.q

Global text.s, output.s, bestmove.s, uci_info.s, anotherFen.s
Global Stockfish_Input_Path.s

Global Images_Path.s = "/users/kenpchess/desktop/kppb_pgn_etc/images/"           ; Adjust this to the actual path of your chesspiece images

Global Dim GameResult_Tags.s(4)
GameResult_Tags(1) = Win1 : GameResult_Tags(2) = Lose1 : GameResult_Tags(3) = Draw1 : GameResult_Tags(4) = Other1

PieceLetters(1) = "BR" : PieceLetters(2) = "BN" : PieceLetters(3) = "BB" : PieceLetters(4) = "BQ" : PieceLetters(5) = "BK" : PieceLetters(6) = "BP"
PieceLetters(7) = "WR" : PieceLetters(8) = "WN" : PieceLetters(9) = "WB" : PieceLetters(10) = "WQ" : PieceLetters(11) = "WK" : PieceLetters(12) = "WP"

Global Wpawn = 12, Wking = 11, Wqueen = 10, Wbishop = 9, Wknight = 8, Wrook = 7
Global Bpawn = 6, Bking = 5, Bqueen = 4, Bbishop = 3, Bknight = 2, Brook = 1

Global Dim Colorflip(13)

Colorflip(1) = 0 : Colorflip(2) = 0 : Colorflip(3) = 0 : Colorflip(4) = 0 : Colorflip(5) = 0 : Colorflip(6) = 0 
Colorflip(7) = 6 : Colorflip(8) = 6 : Colorflip(9) = 6 : Colorflip(10) = 6 : Colorflip(11) = 6 : Colorflip(12) = 6

Global Dim ColorSign(13)

ColorSign(1) = -1 : ColorSign(2) = -1 : ColorSign(3) = -1 : ColorSign(4) = -1 : ColorSign(5) = -1 : ColorSign(6) = -1
ColorSign(7) = 1 : ColorSign(8) = 1 : ColorSign(9) = 1 : ColorSign(10) = 1 : ColorSign(11) = 1 : ColorSign(12) = 1


Global White_on_Move = 1, Black_on_Move = 0, FEN_SideToMove = 1

; Define chessboard colors
Global WhiteColor = RGB(240, 217, 181)
Global BlackColor = RGB(181, 136, 99)

Global _emptysq = 0

Global FilePattern.s, RequesterTitle.s, Pattern.b

;keycodes and  variables for NSCocoa definitions follows

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  Global sharedApplication = CocoaMessage(0, 0, "NSApplication sharedApplication")
  Global clickCount, location.NSPoint, deltaX.CGFloat, deltaY.CGFloat
CompilerEndIf

Define currentEvent, type, modifierFlags, keyCode

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

; ******* new globals etc for SAN routines *******

Global uci.s, result.s, pgnfile.s, ucifile.s

#LightSq = 1 : #DarkSq = 2 : #OffTheBoard = -99

Global LightOrDarkToSq.b, BishopSqLoc.b, CountOfQueens.b

Global Dim knight_dirs(9)
knight_dirs(1) = -8 : knight_dirs(2) = 8 : knight_dirs(3) = -12 : knight_dirs(4) = 12
knight_dirs(5) = -19 : knight_dirs(6) = 19 : knight_dirs(7) = -21 : knight_dirs(8) = 21

Global Dim king_dirs(9)
king_dirs(1) = -9 : king_dirs(2) = 9 : king_dirs(3) = -11 : king_dirs(4) = 11
king_dirs(5) = -1 : king_dirs(6) = 1 : king_dirs(7) = -10 : king_dirs(8) = 10

Global Dim queen_dirs(9)
queen_dirs(1) = -9 : queen_dirs(2) = 9 : queen_dirs(3) = -11 : queen_dirs(4) = 11
queen_dirs(5) = -1 : queen_dirs(6) = 1 : queen_dirs(7) = -10 : queen_dirs(8) = 10

Global Dim Bishop_dirs(5)
Bishop_dirs(1) = -9 : Bishop_dirs(2) = 9 : Bishop_dirs(3) = -11 : Bishop_dirs(4) = 11

Global Dim Rook_dirs(5)
Rook_dirs(1) = -1 : Rook_dirs(2) = 1 : Rook_dirs(3) = -10 : Rook_dirs(4) = 10

Global  disambiguator_symbol.s, disambiguator_sq_list.s

Global ValidSANsymbols.s = "NBRQKabcdefghO+=#"

Global file_disambiguator.s = "xxa21x31x41x51x61x71x81x91xxxb22x32x42x52x62x72x82x92xxxc23x33x43x53x63x73x83x93xxxd24x34x44x54x64x74x84x94xxxe25x35x45x55x65x75x85x95xxxf26x36x46x56x66x76x86x96xxxg27x37x47x57x67x77x87x97xxxh28x38x48x58x68x78x88x98"

Global rank_disambiguator1.s = "1xx91x92x93x94x95x96x97x98x2xx81x82x83x84x85x86x87x88x3xx71x72x73x74x75x76x77x78x4xx61x62x63x64x65x66x67x68x5xx51x52x53x54x55x56x57x58x6xx41x42x43x44x45x46x47x48x7xx31x32x33x34x35x36x37x38x8xx21x22x23x24x25x26x27x28"
Global rank_disambiguator2.s = "1xxzzxzzxzzxzzxzzxzzxzzxzzx2xxzzxzzxzzxzzxzzxzzxzzxzzx3xxzzxzzxzzxzzxzzxzzxzzxzzx4xxzzxzzxzzxzzxzzxzzxzzxzzx5xxzzxzzxzzxzzxzzxzzxzzxzzx6xxzzxzzxzzxzzxzzxzzxzzxzzx7xxzzxzzxzzxzzxzzxzzxzzxzzx8xxzzxzzxzzxzzxzzxzzxzzxzz"


Global WPawn2MoveSqs.s = "x81x82x83x84x85x86x87x88"
Global BPawn2MoveSqs.s = "x31x32x33x34x35x36x37x38"

Global WPawnQueenSqs.s = "x21x22x23x24x25x26x27x28"
Global BPawnQueenSqs.s = "x91x92x93x94x95x96x97x98"

Global WhiteSquaresEP.s = "x41x42x43x44x45x46x47x48"
Global BlackSquaresEP.s = "x71x72x73x74x75x76x77x78"

Global piece.s, Counter.l

Global Dim possibleFromSquaresMailbox.b(6) ; Store potential move mailbox indices, this dimension is rather arbitrary
Global possibleCount.b
Global fromsq1.b, fromsq2.b
Global fromSq_str.s, toSq_str.s
Global fromSquareMailbox.b
Global toSquareMailbox.b
Global pgngamecount.i
Global WhiteKingCurrentSq.b, BlackKingCurrentSq.b
Global WhiteQueenCurrentSq.b, BlackQueenCurrentSq.b
Global AppWindow
Global Mailbox_editor_piece.i, GameInfo.s
Global wFlags.i, filelen.l, max.i, event.i, appQuit.b, currentRead.l, inc.l


CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
DataSection
  piece1:
  IncludeBinary "/Users/kenpchess/Public/images/br.png"
	piece2:
	IncludeBinary "/users/kenpchess/Public/images/bn.png"
	piece3:
	IncludeBinary "/users/kenpchess/Public/images/bb.png"
	piece4:
	IncludeBinary "/users/kenpchess/Public/images/bq.png"
	piece5:
	IncludeBinary "/users/kenpchess/Public/images/bk.png"
	piece6:
	IncludeBinary "/users/kenpchess/Public/images/bp.png"
	piece7:
	IncludeBinary "/users/kenpchess/Public/images/wr.png"
	piece8:
	IncludeBinary "/users/kenpchess/Public/images/wn.png"
	piece9:
	IncludeBinary "/users/kenpchess/Public/images/wb.png"
	piece10:
	IncludeBinary "/users/kenpchess/Public/images/wq.png"
	piece11:
	IncludeBinary "/users/kenpchess/Public/images/wk.png"
	piece12:
	IncludeBinary "/users/kenpchess/Public/images/wp.png"
	piece13:
	IncludeBinary "/users/kenpchess/Public/images/pieces40/br40.png"
	piece14:
	IncludeBinary "/users/kenpchess/Public/images/pieces40/bn40.png"
	piece15:
	IncludeBinary "/users/kenpchess/Public/images/pieces40/bb40.png"
	piece16:
	IncludeBinary "/users/kenpchess/Public/images/pieces40/bq40.png"
	piece17:
	IncludeBinary "/users/kenpchess/Public/images/pieces40/bk40.png"
	piece18:
	IncludeBinary "/users/kenpchess/Public/images/pieces40/bp40.png"
	piece19:
	IncludeBinary "/users/kenpchess/Public/images/pieces40/wr40.png"
	piece20:
	IncludeBinary "/users/kenpchess/Public/images/pieces40/wn40.png"
	piece21:
	IncludeBinary "/users/kenpchess/Public/images/pieces40/wb40.png"
	piece22:
	IncludeBinary "/users/kenpchess/Public/images/pieces40/wq40.png"
	piece23:
	IncludeBinary "/users/kenpchess/Public/images/pieces40/wk40.png"
	piece24:
	IncludeBinary "/users/kenpchess/Public/images/pieces40/wp40.png"
	piece25:
  IncludeBinary "/users/kenpchess/Public/images/pieces40/es32.png"
  
EndDataSection
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
DataSection
  piece1:
  IncludeBinary "C:/PureBasic/images/br.png"
  piece2:
  IncludeBinary "C:/PureBasic/images/bn.png"
  piece3:
  IncludeBinary "C:/PureBasic/images/bb.png"
  piece4:
  IncludeBinary "C:/PureBasic/images/bq.png"
  piece5:
  IncludeBinary "C:/PureBasic/images/bk.png"
  piece6:
  IncludeBinary "C:/PureBasic/images/bp.png"
  piece7:
  IncludeBinary "C:/PureBasic/images/wr.png"
  piece8:
  IncludeBinary "C:/PureBasic/images/wn.png"
  piece9:
  IncludeBinary "C:/PureBasic/images/wb.png"
  piece10:
  IncludeBinary "C:/PureBasic/images/wq.png"
  piece11:
  IncludeBinary "C:/PureBasic/images/wk.png"
  piece12:
  IncludeBinary "C:/PureBasic/images/wp.png"
  piece13:
	IncludeBinary "C:/PureBasic/images/pieces40/br40.png"
	piece14:
	IncludeBinary "C:/PureBasic/images/pieces40/bn40.png"
	piece15:
	IncludeBinary "C:/PureBasic/images/pieces40/bb40.png"
	piece16:
	IncludeBinary "C:/PureBasic/images/pieces40/bq40.png"
	piece17:
	IncludeBinary "C:/PureBasic/images/pieces40/bk40.png"
	piece18:
	IncludeBinary "C:/PureBasic/images/pieces40/bp40.png"
	piece19:
	IncludeBinary "C:/PureBasic/images/pieces40/wr40.png"
	piece20:
	IncludeBinary "C:/PureBasic/images/pieces40/wn40.png"
	piece21:
	IncludeBinary "C:/PureBasic/images/pieces40/wb40.png"
	piece22:
	IncludeBinary "C:/PureBasic/images/pieces40/wq40.png"
	piece23:
	IncludeBinary "C:/PureBasic/images/pieces40/wk40.png"
	piece24:
	IncludeBinary "C:/PureBasic/images/pieces40/wp40.png"
	piece25:
  IncludeBinary "C:/PureBasic/images/pieces40/es32.png"

EndDataSection
CompilerEndIf


Declare Add_Game_To_SQLite_DB()
Declare Add_All_Games_To_SQLite_DB_Thread(*Value)
Declare BoardDisplay()
Declare BoardEditorDisplay()
Declare BoardEmpty()
Declare BoardInitialize()
Declare BoardSqIsEmptyMailbox(square.b)
Declare BuildValidQueenMovesTable()
Declare ConstructFENfromPosition()
Declare ConstructPositionfromFEN(FENpositionstr.s)
Declare Convert_UCI_Notation()
Declare DoEventMacOS()
Declare DisplayGames()
Declare ExportPGNGame()
Declare FreeBoardEditorGadgets()

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  Declare.s FileRequester(RequesterType, Title.s, DefaultFile.s = "", AllowedFileTypes.s = "", Message.s = "", Flags = 0)
CompilerEndIf

Declare GameFENEditorPlus()

Declare GetMouseX(gadget)
Declare GetMouseY(gadget)
Declare ReportCursor(msg1.s)

Declare GetBestMoveUCIPV(ProgramID, fen.s, searchTime_ms, MultiPV.b)
Declare LoadPGN_Thread(null)
Declare LoadSQLiteChessDatabase(FileName.s)
Declare LocateTheKings()
Declare LocateTheQueen(isWhite.b)
Declare LocateLightOrDarkSquareBishop(isWhite.b,XtoSq.b)
Declare LegalMovesKnightAndKing(isWhite.b,piece.s)
Declare LegalMovesBishopAndRook(isWhite.b,piece.s)
Declare LegalMovesQueen(isWhite.b,piece.s)
Declare LegalMovesPawn(san.s,isWhite.b,piece.s)
Declare MailboxMouseXY(xcoordm.i,ycoordm.i)
Declare MakeUCIMoveViaBrdUpd(fromSquareMailbox.b,toSquareMailbox.b,uci.s, isWhite.b)
Declare NextMove()
Declare.s ParseAndCleanPGN(PGNDirtyGameScore.s)
Declare Parse_Save_GameScore_Bare_Halfmoves(GameScore.s)
Declare PlayEngine()
Declare Player_Search()
Declare PreviousMove()
Declare PrintAsciiBoard()
Declare PieceIsWhite(Xpiece.b)
Declare PieceIsBlack(Xpiece.b)
Declare PopulateMovesGadget()
Declare ReadUCIResponse(ProgramID, timeout_ms = 100)
Declare RemovePGNCommentsAndVariations2(line.s)
Declare RemoveNumberDotSequenceSpecialNotations(XGameScore_Movelist.s)
Declare SavePossibleMoveMailBoxSquare(XMailBoxSquare.b)
Declare SANtoUCI_SingleMove(san.s, isWhite.b)
Declare SelectPieceButton()
Declare SizeHandler()
Declare SizeHandlerFENEditorButtons()

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  Declare SetTextColorABGR(EditorGadget, Color, StartPosition, Length = -1, BackColor = #NO)
CompilerEndIf

Declare SetMoveColumn()
Declare SpacifyNoSpaceGamescoreLine(line.s)
Declare SquareIsAttacked(Xsquare.b,isWhite.b)
Declare SendUCICommand(ProgramID, command.s)
Declare SetupGameLinkForSearchSort(Index.i)
Declare Stockfish_FEN_Analysis_Thread(*Value)
Declare WaitForUCIResponse(ProgramID, expectedResponse.s, timeout_ms = 5000)
Declare XTrim(text.s)

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  DeclareC.w GetAsyncKeyState(vKey.l) ; Use .w for WORD return value as per API, though .l also works. This is for Windows OS keyscan codes
CompilerEndIf

Enumeration #PB_Event_FirstCustomValue
  #EventBeginProcessing
  #AnotherBatchOfGamesProcessed
  #AllGamesProcessed
EndEnumeration

Enumeration filescreen
  #miniwin
  #clocktimer
  #startbutton
  #fileprogresstextgadget
  #fileprogressbar
EndEnumeration

Enumeration
  #mainwin
  #CanvasGadgetChessBoard
  #Players_ListIcon_Gadget
  #Move_ListIcon_Gadget
  #DbFile_Gadget
  #Single_Move_Gadget
  #Btn_Fen
  #Btn_BoardSize
  #Btn_ExportGame
  #Info_Field
  #Dummy1
  #Btn_Prev
  #Btn_Next
  #Btn_Db1
  #Btn_Db2
  #Btn_SFAnaly
  #Btn_SF10sec
  #Btn_PlayvsSF
  #Btn_UpdSF
  #Btn_PSearch
  #Btn_FENEditor
  #Btn_br40
  #Btn_bn40
  #Btn_bb40
  #Btn_bq40
  #Btn_bk40
  #Btn_bp40
  #Btn_wr40
  #Btn_wn40
  #Btn_wb40
  #Btn_wq40
  #Btn_wk40
  #Btn_wp40
  #Btn_es32
  #Btn_done40
  
EndEnumeration

UsePNGImageDecoder()
UsePNGImageEncoder()


Procedure Add_Game_To_SQLite_DB()

Protected UCI_Gamescore.s, query.s
Protected i.i, GameLink_pos.i

; create an empty file - ensure file path

If FileSize(DB_InputFile) > 0
  ; do nothing file already exists
  PrintN("...file already exists...")
Else
  ;If CreateFile(0, "/Users/testuser/Desktop/kppb_pgn_etc/" + DB_InputFile)
  If CreateFile(0, DB_InputFile) 
    ; close the file
    CloseFile(0)
  EndIf
EndIf

#sqlite = 0

; initialise SQLite library
UseSQLiteDatabase()

If OpenDatabase(#sqlite, DB_InputFile, "", "")
  
  ; tables must be created before the database can be used.
  ; this query instructs the database to create a table named 
  ; PGNGAMES and format it with the following data fields:
  ; 1. gameid - numerical data type
  ; 2. event - text data type
  ; 3. gamedate - text data type length 7
  ; 5. player1 - text data type length of 50
  ; 5. elo1 - text data type length of 4
  ; 6. player2 - text data type length of 50
  ; 7. elo2 - text data type length of 4
  ; 8. startingFEN - text data
  ; 9. gameresult - text data type
  ; 10. ucimoves - text data


  query.s =  "CREATE TABLE IF NOT EXISTS pgngames (gameid INTEGER PRIMARY KEY, event TEXT, gamedate TEXT, player1 TEXT, ELO1 TEXT, player2 TEXT, ELO2 TEXT, startingFEN TEXT, gameresult TEXT, ucimoves TEXT)"
 
  
  ; update the database with the prepared query

  If DatabaseUpdate(#sqlite, query.s)
    
    Debug "database table created successfully."
    
  Else
    
    Debug "error creating database table! " + DatabaseError()
    
  EndIf
  
  ;query.s = "INSERT INTO pgngames (event, gamedate, player1, elo1, player2, elo2, startingFEN, gameresult, ucimoves) " + "VALUES ('kptourney1', '20250331', 'Chess, Kenp', '2000', 'Fischer, Bobby', '2800', '', '1/2-1/2','e2-e4 e7-e5 g1-f3 b8-c6 f1-c4 g8-f6')"
  
  ; FYI Retrieval 1

  ; retrieve ALL (*) data and records from the pgngames table
  ;query.s = "SELECT * FROM pgngames"
  
  ; GAME insertion with binding

  UCI_Gamescore = ""
  For i = 1 To TotalHalfMoves : UCI_Gamescore = UCI_Gamescore + GameScore_UCI_HalfMoves(i) + Space(1) : Next

  PrintN("UCI_Gamescore = " + UCI_Gamescore)
   
  query.s = "INSERT INTO pgngames (event, gamedate, player1, elo1, player2, elo2, startingFEN, gameresult, ucimoves) " + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"   ; binding order = 0, 1, 2, 3, 4, 5, 6
  
  ; the question marks above will be substituted with these values
  ; column 0 = event (text)
  SetDatabaseString(#sqlite, 0, EventSites(GameIndex+1))
  ; column 1 = gamedate (text)
  SetDatabaseString(#sqlite, 1, GameDates(GameIndex+1))
  
  ; column 2 = player1 (text)
  GameLink_pos = FindString(WhitePlayers(GameIndex+1), Game_Prefix, 1)
  SetDatabaseString(#sqlite, 2, Trim(Left(WhitePlayers(GameIndex+1), GameLink_pos-1), Space(1)))
  
  ;column 3 = elo1 (text)
  SetDatabaseString(#sqlite, 3, WhiteElos(GameIndex+1))

  ; column 4 = player2 (text)
  GameLink_pos = FindString(BlackPlayers(GameIndex+1), Game_Prefix, 1)
  SetDatabaseString(#sqlite, 4, Trim(Left(BlackPlayers(GameIndex+1), GameLink_pos-1), Space(1)))
  
  ;column 5 = elo2 (text)
  SetDatabaseString(#sqlite, 5, BlackElos(GameIndex+1))

  ; column 6 = starting_fen (text)
  SetDatabaseString(#sqlite, 6, FEN_setup_str(GameIndex+1))
  
  ; column 7 = gameresult (text)
  SetDatabaseString(#sqlite, 7, GameScore_UCI_HalfMoves(TotalHalfMoves))
  
  ; column 8 = ucimoves (text)
  SetDatabaseString(#sqlite, 8, UCI_Gamescore)
  
  ; update the database with the bound prepared query and confirm the write
  If UCI_Gamescore <> "" And DatabaseUpdate(#sqlite, query) And AffectedDatabaseRows(#sqlite) = 1
    
    PrintN(WhitePlayers(GameIndex+1) + Space(5) + BlackPlayers(GameIndex+1) + " current game successfully inserted.")

    ; binding sequence by inserting the values in an arbitrary order
    ;query = "INSERT INTO pgngames (ucimoves, player2, player1, event) " + "VALUES (?, ?, ?, ?)"   ; binding order = 0, 1, 2, 3
    
    
  Else
    Debug "error inserting data (current game)! " + DatabaseError()
  EndIf
  
  ; close the database file
  CloseDatabase(#sqlite)

Else
  Debug "error opening database! " + DatabaseError()
EndIf

EndProcedure


Procedure Add_All_Games_To_SQLite_DB_Thread(*Value)

  Protected UCI_Gamescore.s, query.s
  Protected i.i, j.i, GameLink_pos.i
  Protected Gamescore.s
  
  If FileSize(DB_InputFile) > 0
    ; do nothing file already exists
    PrintN("...file already exists...")
  Else 
    If CreateFile(0, DB_InputFile)
      ; close the file
      CloseFile(0)
    EndIf
  EndIf

  #sqlite = 0
  UseSQLiteDatabase()

  ;If OpenDatabase(#sqlite, "/Users/testuser/Desktop/kppb_pgn_etc/" + DB_InputFile, "", "")
  If OpenDatabase(#sqlite, DB_InputFile, "", "")

    query.s =  "CREATE TABLE IF NOT EXISTS pgngames (gameid INTEGER PRIMARY KEY, event TEXT, gamedate TEXT, player1 TEXT, ELO1 TEXT, player2 TEXT, ELO2 TEXT, startingFEN TEXT, gameresult TEXT, ucimoves TEXT)"
    If DatabaseUpdate(#sqlite, query.s)
      Debug "database table created successfully."
    Else
      Debug "error creating database table! " + DatabaseError()
    EndIf
    
    For i = 1 To GameCount-1
      GamesInserted = i
      GameScore = FilePGNs(i)
      Gamescore = ParseAndCleanPGN(Gamescore)
      Parse_Save_GameScore_Bare_Halfmoves(GameScore.s)
      RemovePGNCommentsAndVariations2(Gamescore)
      Gamescore = result
      ; single game insertion with binding
      UCI_Gamescore = ""
      For j = 1 To TotalHalfMoves : UCI_Gamescore = UCI_Gamescore + GameScore_UCI_HalfMoves(j) + Space(1) : Next

      PrintN("UCI_Gamescore = " + UCI_Gamescore)
      query.s = "INSERT INTO pgngames (event, gamedate, player1, elo1, player2, elo2, startingFEN, gameresult, ucimoves) " + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"   ; binding order = 0, 1, 2, 3, 4, 5, 6
    
      ; column 0 = event (text)
      SetDatabaseString(#sqlite, 0, EventSites(i))
      
      ; column 1 = gamedate (text)
      SetDatabaseString(#sqlite, 1, GameDates(i))
      
      ; column 2 = player1 (text)
      GameLink_pos = FindString(WhitePlayers(i), Game_Prefix, 1)
      SetDatabaseString(#sqlite, 2, Trim(Left(WhitePlayers(i), GameLink_pos-1), Space(1)))
      
      ; column 3 = elo1 (text)
      SetDatabaseString(#sqlite, 3, WhiteElos(i))

      ; column 4 = player2 (text)
      GameLink_pos = FindString(BlackPlayers(i), Game_Prefix, 1)
      SetDatabaseString(#sqlite, 4, Trim(Left(BlackPlayers(i), GameLink_pos-1), Space(1)))
      
      ; column 5 = elo2 (text)
      SetDatabaseString(#sqlite, 5, BlackElos(i))

      ; column 6 = starting_fen (text)
      SetDatabaseString(#sqlite, 6, FEN_setup_str(i))
      
      ; column 7 = gameresult (text)
      SetDatabaseString(#sqlite, 7, GameScore_UCI_HalfMoves(TotalHalfMoves)) ; win-loss-draw result stored in last half-move
                                                                             ; column 7 = ucimoves (text)
      ; column 8 = ucimoves (text)
      SetDatabaseString(#sqlite, 8, UCI_Gamescore)
  
      ; update the database with the bound prepared query and confirm the write
      If UCI_Gamescore <> "" And DatabaseUpdate(#sqlite, query) And AffectedDatabaseRows(#sqlite) = 1
        PrintN(WhitePlayers(i) + Space(5) + BlackPlayers(i) + " current game #" + Str(i) + " successfully inserted.")
        If i % #SQLBatchOfGames = 0
          PostEvent(#AnotherBatchOfGamesProcessed)
        EndIf
      Else
        Debug "error inserting data (current game)! " + DatabaseError()
      EndIf

    Next ; i
    PostEvent(#AnotherBatchOfGamesProcessed)

    ; close the database file
    CloseDatabase(#sqlite)
  Else
    Debug "error opening database! " + DatabaseError()
  EndIf

EndProcedure



Procedure BoardEmpty()
  
  Protected i.b, row.b, col.b

; Chessboard empty layout (0=empty)
  
  For i = 0 To 19 : MbxBrd(i) = #OffTheBoard : Next

For row = 20 To 90 Step 10
  For col = 1 To 8
    MbxBrd(row+col) = _emptysq
  Next
Next

; rest of squares are off-the-board
MbxBrd(20) = #OffTheBoard : MbxBrd(29) = #OffTheBoard : MbxBrd(30) = #OffTheBoard : MbxBrd(39) = #OffTheBoard : MbxBrd(40) = #OffTheBoard : MbxBrd(49) = #OffTheBoard : MbxBrd(50) = #OffTheBoard : MbxBrd(59) = #OffTheBoard
MbxBrd(60) = #OffTheBoard : MbxBrd(69) = #OffTheBoard : MbxBrd(70) = #OffTheBoard : MbxBrd(79) = #OffTheBoard : MbxBrd(80) = #OffTheBoard : MbxBrd(89) = #OffTheBoard : MbxBrd(90) = #OffTheBoard : MbxBrd(99) = #OffTheBoard

For i = 100 To 119 : MbxBrd(i) = #OffTheBoard : Next

EndProcedure



Procedure BoardInitialize()
  
  Protected i.b, row.b, col.b

; Chessboard piece layout (0=empty)
  
  For i = 0 To 19 : MbxBrd(i) = #OffTheBoard : Next

MbxBrd(21) = Brook  : MbxBrd(22) = Bknight  : MbxBrd(23) = Bbishop  : MbxBrd(24) = Bqueen  : MbxBrd(25) = Bking  : MbxBrd(26) = Bbishop  : MbxBrd(27) = Bknight  : MbxBrd(28) = Brook
MbxBrd(31) = Bpawn : MbxBrd(32) = Bpawn : MbxBrd(33) = Bpawn : MbxBrd(34) = Bpawn : MbxBrd(35) = Bpawn : MbxBrd(36) = Bpawn : MbxBrd(37) = Bpawn : MbxBrd(38) = Bpawn

For row = 40 To 70 Step 10
  For col = 1 To 8
    MbxBrd(row+col) = _emptysq
  Next
Next

MbxBrd(81) = Wpawn: MbxBrd(82) = Wpawn: MbxBrd(83) = Wpawn : MbxBrd(84) = Wpawn: MbxBrd(85) = Wpawn: MbxBrd(86) = Wpawn : MbxBrd(87) = Wpawn: MbxBrd(88) = Wpawn
MbxBrd(91) = Wrook  : MbxBrd(92) = Wknight  : MbxBrd(93) = Wbishop  : MbxBrd(94) = Wqueen  : MbxBrd(95) = Wking  : MbxBrd(96) = Wbishop  : MbxBrd(97) = Wknight  : MbxBrd(98) = Wrook

; rest of squares are off-the-board
MbxBrd(20) = #OffTheBoard : MbxBrd(29) = #OffTheBoard : MbxBrd(30) = #OffTheBoard : MbxBrd(39) = #OffTheBoard : MbxBrd(40) = #OffTheBoard : MbxBrd(49) = #OffTheBoard : MbxBrd(50) = #OffTheBoard : MbxBrd(59) = #OffTheBoard
MbxBrd(60) = #OffTheBoard : MbxBrd(69) = #OffTheBoard : MbxBrd(70) = #OffTheBoard : MbxBrd(79) = #OffTheBoard : MbxBrd(80) = #OffTheBoard : MbxBrd(89) = #OffTheBoard : MbxBrd(90) = #OffTheBoard : MbxBrd(99) = #OffTheBoard

For i = 100 To 119 : MbxBrd(i) = #OffTheBoard : Next

EndProcedure



Procedure BoardDisplay()
  
  Protected x.b, row.b, col.b
  
  ; Note: The canvas drawing board is created in the DisplayGames routine just after the other gadgets
  
  ;PrintN("...in BoardDisplay procedure...")
  ;PrintN("...in BoardDisplay MbxBrd(65) = " + Str(MbxBrd(65)))
  
  ;PieceImages(1) = LoadImage(1, Images_Path + "br.png")
  ;              ...
  ;PieceImages(6) = LoadImage(6, Images_Path + "bp.png")
  ;
  ;PieceImages(7) = LoadImage(7, Images_Path + "wr.png")
  ;              ...
  ;PieceImages(12) = LoadImage(12, Images_Path + "wp.png")
  
  If SquareSize = 60
    CatchImage(1, ?piece1) : CatchImage(2, ?piece2) : CatchImage(3, ?piece3) : CatchImage(4, ?piece4)
    CatchImage(5, ?piece5) : CatchImage(6, ?piece6) : CatchImage(7, ?piece7) : CatchImage(8, ?piece8)
    CatchImage(9, ?piece9) : CatchImage(10, ?piece10) : CatchImage(11, ?piece11) : CatchImage(12, ?piece12)
  Else
    CatchImage(1, ?piece13) : CatchImage(2, ?piece14) : CatchImage(3, ?piece15) : CatchImage(4, ?piece16)
    CatchImage(5, ?piece17) : CatchImage(6, ?piece18) : CatchImage(7, ?piece19) : CatchImage(8, ?piece20)
    CatchImage(9, ?piece21) : CatchImage(10, ?piece22) : CatchImage(11, ?piece23) : CatchImage(12, ?piece24)
  EndIf

  
  StartDrawing(CanvasOutput(#CanvasGadgetChessBoard))        ; see the DisplayGames routine just after the other gadgets are created
  
; Draw chessboard
For row = 1 To 8
  For col = 1 To 8
    If (row + col) % 2 = 0
      Box(col * SquareSize, row * SquareSize, SquareSize, SquareSize, WhiteColor)
    Else
      Box(col * SquareSize, row * SquareSize, SquareSize, SquareSize, BlackColor)
    EndIf
  Next
Next


; Draw pieces (new)
For row = 20 To 90 Step 10
  For col = 1 To 8
    If MbxBrd(row+col) <> _emptysq
      DrawAlphaImage(ImageID(MbxBrd(row+col)), col * SquareSize, (row/10-1) * SquareSize)
    Else
      If Debug_Board_Squares
        DrawText(col * SquareSize +25, (row/10-1) * SquareSize + 25,Str(row+col),#Gray,#White)
      EndIf
    EndIf
  Next
Next


DrawText(#alg_baseX+Squaresize,#alg_filesY,"a") : DrawText(#alg_baseX+2*Squaresize,#alg_filesY,"b") : DrawText(#alg_baseX+3*Squaresize,#alg_filesY,"c") : DrawText(#alg_baseX+4*Squaresize,#alg_filesY,"d")
DrawText(#alg_baseX+5*Squaresize,#alg_filesY,"e") : DrawText(#alg_baseX+6*Squaresize,#alg_filesY,"f") : DrawText(#alg_baseX+7*Squaresize,#alg_filesY,"g") : DrawText(#alg_baseX+8*Squaresize,#alg_filesY,"h")

DrawText(#alg_rankX,#alg_baseY+Squaresize,"8") : DrawText(#alg_rankX,#alg_baseY+2*Squaresize,"7") : DrawText(#alg_rankX,#alg_baseY+3*Squaresize,"6") : DrawText(#alg_rankX,#alg_baseY+4*Squaresize,"5")
DrawText(#alg_rankX,#alg_baseY+5*Squaresize,"4") : DrawText(#alg_rankX,#alg_baseY+6*Squaresize,"3") : DrawText(#alg_rankX,#alg_baseY+7*Squaresize,"2") : DrawText(#alg_rankX,#alg_baseY+8*Squaresize,"1")


StopDrawing()

;Free images.
For x = 1 To 12
  FreeImage(x)
Next


EndProcedure


Procedure BoardEditorDisplay()
  
  CatchImage(13, ?piece13) : CatchImage(14, ?piece14) : CatchImage(15, ?piece15)
  CatchImage(16, ?piece16) : CatchImage(17, ?piece17) : CatchImage(18, ?piece18)
  CatchImage(19, ?piece19) : CatchImage(20, ?piece20) : CatchImage(21, ?piece21)
  CatchImage(22, ?piece22) : CatchImage(23, ?piece23) : CatchImage(24, ?piece24)
  CatchImage(25, ?piece25)
  
  ButtonImageGadget(#Btn_br40,30,#btnbr40DefaultY, 40, 40,ImageID(13))
  ButtonImageGadget(#Btn_bn40,30,#btnbn40DefaultY, 40, 40,ImageID(14))
  ButtonImageGadget(#Btn_bb40,30,#btnbb40DefaultY, 40, 40,ImageID(15))
  ButtonImageGadget(#Btn_bq40,30,#btnbq40DefaultY, 40, 40,ImageID(16))
  ButtonImageGadget(#Btn_bk40,30,#btnbk40DefaultY, 40, 40,ImageID(17))
  ButtonImageGadget(#Btn_bp40,30,#btnbp40DefaultY, 40, 40,ImageID(18))
  
  ButtonImageGadget(#Btn_wr40,30,#btnwr40DefaultY, 40, 40,ImageID(19))
  ButtonImageGadget(#Btn_wn40,30,#btnwn40DefaultY, 40, 40,ImageID(20))
  ButtonImageGadget(#Btn_wb40,30,#btnwb40DefaultY, 40, 40,ImageID(21))
  ButtonImageGadget(#Btn_wq40,30,#btnwq40DefaultY, 40, 40,ImageID(22))
  ButtonImageGadget(#Btn_wk40,30,#btnwk40DefaultY, 40, 40,ImageID(23))
  ButtonImageGadget(#Btn_wp40,30,#btnwp40DefaultY, 40, 40,ImageID(24))
  ButtonImageGadget(#Btn_es32,30,#btnes32DeFaultY, 40, 40,ImageID(25))
  
  ButtonGadget(#Btn_done40, #btndone40DefaultX, #btndone40DefaultY, 110, 25, "EXIT Ed/Move", #PB_Button_Default)
  
  BindEvent(#PB_Event_SizeWindow, @SizeHandlerFENEditorButtons())
  
EndProcedure

Procedure FreeBoardEditorGadgets()
  
  FreeGadget(#Btn_br40) : FreeGadget(#Btn_bn40) : FreeGadget(#Btn_bb40)
  FreeGadget(#Btn_bq40) : FreeGadget(#Btn_bk40) : FreeGadget(#Btn_bp40)
  
  FreeGadget(#Btn_wr40) : FreeGadget(#Btn_wn40) : FreeGadget(#Btn_wb40)
  FreeGadget(#Btn_wq40) : FreeGadget(#Btn_wk40) : FreeGadget(#Btn_wp40)
  
  FreeGadget(#Btn_es32) : FreeGadget(#Btn_done40)
  
EndProcedure



Procedure BoardSqIsEmptyMailbox(square.b)
  ; This procedure should return #True if the given square on the board is empty, #False otherwise.
  ; You will need to implement your board representation and check it here.
  
  If MbxBrd(square) = _emptysq
    ;PrintN("Proc: BrdSqIsEmpty...TRUE...Mailbox square = " + Str(square) + "  algebraic square = " + Mid(AlgSquares,square*2+1,2) + " MbxBrd(sq) = " + Str(MbxBrd(square)))
    ProcedureReturn #True
   Else
     ;PrintN("Proc: BrdSqIsEmpty...FALSE...Mailbox square = " + Str(square) + "  algebraic square = " + Mid(AlgSquares,square*2+1,2) + " MbxBrd(sq) = " + Str(MbxBrd(square)))
    ProcedureReturn #False
  EndIf
  ProcedureReturn
EndProcedure



Procedure BuildValidQueenMovesTable()

  Protected i.b, j.b, k.b, ValidQueenSq.b

  For i = 21 To 98
    ValidQueenMbxSqs(i) = ""
    If MbxBrd(i) <> #OffTheBoard
      For j = 1 To 8
        For k = 1 To 7
          ValidQueenSq = i + Queen_dirs(j) * k
          If MbxBrd(ValidQueenSq) <> #OffTheBoard
            ;PrintN("ValidQueenSq = " + Str(ValidQueenSq))
            ValidQueenMbxSqs(i) = ValidQueenMbxSqs(i) + "x" + Str(ValidQueenSq)
          Else
            Break
          EndIf
        Next ;k
      Next ;j
    EndIf

    ;PrintN("ValidQueenMbxSqs(" + Str(i) + ") = " + ValidQueenMbxSqs(i))

  Next ;i

EndProcedure



Procedure ConstructFENfromPosition()
    
  Protected blanksquarecount.b, BoardSq.b, chessrank.b, chessfile.b, WhitecastleFlag.b, BlackcastleFlag.b
  Protected BlackPieces.s = "rnbqkp", WhitePieces.s = "RNBQKP", BlackAndWhitePieces.s

  BlackAndWhitePieces = BlackPieces + WhitePieces
  FENpositionstr = ""
  blanksquarecount = 0
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("CFP - HalfMoveCount = " + Str(HalfMoveCount))
  CompilerEndIf
  
  For chessrank = 20 To 90 Step 10
    For chessfile = 1 To 8
      If MbxBrd(chessrank + chessfile) <> 0 
        If blanksquarecount > 0 
          FENpositionstr = FENpositionstr + Str(blanksquarecount)
          blanksquarecount = 0
        EndIf
        FENpositionstr = FENpositionstr + Mid(BlackAndWhitePieces, MbxBrd(chessrank + chessfile), 1)
      Else
        blanksquarecount = blanksquarecount + 1
      EndIf
    Next
    If blanksquarecount > 0 
      FENpositionstr = FENpositionstr + Str(blanksquarecount)
      If chessfile >= 8 And chessrank < 90
        FENpositionstr = FENpositionstr + "/"
      EndIf
      blanksquarecount = 0
    Else
      If chessfile >= 8 And chessrank < 90 
        FENpositionstr = FENpositionstr + "/"
      EndIf
    EndIf
  Next

   If HalfMoveCount % 2
    FENpositionstr = FENpositionstr + " b "
  Else
    FENpositionstr = FENpositionstr + " w "
  EndIf

  WhitecastleFlag = 0
  If MbxBrd(95) = Wking
    If MbxBrd(98) = Wrook
      FENpositionstr = FENpositionstr + "K"
      WhitecastleFlag = 1
    EndIf
    If MbxBrd(91) = Wrook
      FENpositionstr = FENpositionstr + "Q"
      WhitecastleFlag = 1
    EndIf
  EndIf

  BlackcastleFlag = 0
  If MbxBrd(25) = Bking 
    If MbxBrd(28) = Brook 
      FENpositionstr = FENpositionstr + "k"
      BlackcastleFlag = 1
    EndIf
    If MbxBrd(21) = Brook 
      FENpositionstr = FENpositionstr + "q"
      BlackcastleFlag = 1
    EndIf
  EndIf

  If Not WhitecastleFlag And Not BlackcastleFlag 
    FENpositionstr = FENpositionstr + "-"
  EndIf

  ;not checking enpassant conditions

  FENpositionstr = FENpositionstr + " - "
  
  ;not checking half-moves since last capture or pawn move for fifty move rule, use a random number like zero

  FENpositionstr = FENpositionstr + "0 "
  ; now add the actual game move number
  FENpositionstr = FENpositionstr + Str(HalfMoveCount/2+1)
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("") : PrintN("FENpositionstr = " + FENpositionstr) : PrintN("")
  CompilerEndIf
  
EndProcedure


Procedure ConstructPositionfromFEN(FENpositionstr.s)
  
  Protected blanksquarecount.b, BoardSq.b, chessrank.b, chessfile.b, slashposition.b, WhitecastleFlag.b, BlackcastleFlag.b
  Protected BlackPieceNo.b, WhitePieceNo.b, EmptySquaresCount.b,SideToMove.b, GameMoveNumber.i, z4.b
  Protected tempFENstr.s, MoveNoStr.s, debugMsg1.s
  Protected FEN_ColorToMove.b, i.i
  Dim FENrankstr.s(8)

  tempFENstr = FENpositionstr
  PrintN("")
  PrintN("FEN = " + tempFENstr)
  PrintN("")
  
  PrintN("CPF - HalfMoveCount = " + Str(HalfMoveCount))
  
  FEN_ColorToMove = FindString(tempFENstr," w",1)
  
  If FEN_ColorToMove > 0
    FEN_SideToMove = White_on_Move
  Else
    FEN_SideToMove = Black_on_Move
  EndIf
  
  MoveNoStr = Mid(tempFENstr,Len(tempFENstr)-1,2)
  GameMoveNumber = Val(Trim(MoveNoStr,Space(1)))
  PrintN("debug: CPfF - length of FEN string = " + Str(Len(tempFENstr)) + " GameMoveNumber = " + Str(GameMoveNumber))

  For chessrank = 2 To 9
    If chessrank <> 9
      slashposition = FindString(tempFENstr,"/")
      FENrankstr(chessrank-1) = Left(tempFENstr,slashposition - 1)
      tempFENstr = Mid(tempFENstr,slashposition+1,Len(tempFENstr)-slashposition)
    Else
      FENrankstr(chessrank-1) = tempFENstr
    EndIf
    ; PrintN("Rank " + FENrankstr(chessrank-1) + "  Remaining FEN part = " + tempFENstr)
  Next ;chessrank
  
  For i = 21 To 98
    If MbxBrd(i) <> #OffTheBoard
      MbxBrd(i) = _emptysq
    EndIf
  Next
  
  For chessrank = 2 To 9
    chessfile = 1
    While chessfile <= 8
      EmptySquaresCount = FindString("12345678",Mid(FENrankstr(chessrank-1),1,1))
      BlackPieceNo = FindString("rnbqkp",Left(FENrankstr(chessrank-1),1))
      WhitePieceNo = FindString("xxxxxxRNBQKP",Left(FENrankstr(chessrank-1),1))
      If EmptySquaresCount > 0                                        ;  number of empty squares
        For z4 = 1 To EmptySquaresCount
         MbxBrd(chessrank*10 + chessfile) = _emptySq
         chessfile = chessfile + 1
        Next ;z4
        EmptySquaresCount = 0
      Else
        If BlackPieceNo > 0                                           ; it is a Black Piece
          MbxBrd(chessrank*10 + chessfile) = BlackPieceNo
          BlackPieceNo = 0
        Else                                               
          If WhitePieceNo > 0  
            MbxBrd(chessrank*10 + chessfile) = WhitePieceNo          ; it is a White Piece Or a bad FEN
            WhitePieceNo = 0
          EndIf
        EndIf
        chessfile = chessfile + 1
      EndIf
      FENrankstr(chessrank-1) = Mid(FENrankstr(chessrank-1),2,Len(FENrankstr(chessrank-1))-1)
      ; PrintN("debug: rank " + Str(chessrank-1) + " " + FENrankstr(chessrank-1))
    Wend
    
    
    debugMsg1 = "rank " + Str(chessrank-1) + " squares = "
    For z4 = 1 To 8 
      debugMsg1 = debugMsg1 + " " + Str(MbxBrd(chessrank*10 + z4))
    Next ;z4
    ; PrintN("debug: FEN Row squares = " + debugMsg1)
  Next ;chessrank

EndProcedure



Procedure Convert_UCI_Notation()
  
  ; This procedure takes a UCI notation halfmove (such as e2-e4 or g1-f3) and simply converts the departure and arrival alebraic squares
  ; to their corresponding mailbox square numbers (i.e. 21 to 98) for updating the chessboard state. Of course it does have to handle 
  ; special moves like castling and pawn promotion.
  
  ; This procedure calls: ConstructFENfromPosition()
  
  Protected fromsq.i, tosq.i, movingPiece.b
  Protected promopiece.s
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("")
    PrintN("at Convert_UCI_Notation start: UCI_move_str = " + UCI_move_str)
  CompilerEndIf

  UCI_move_str = Trim(GameScore_UCI_HalfMoves(HalfMoveCount),Space(1))


  Select UCI_move_str

    Case Win1, Lose1, Draw1, Trim(Other1, Space(1))
      UCI_move_str = "done"
    Default
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN("")
        PrintN("at Convert_UCI_Notation middle: UCI_move_str = xxx" + UCI_move_str + "xxx")
      CompilerEndIf
  
      fromSq_str = Left(UCI_move_str, 2)
      toSq_str = Mid(UCI_move_str, 4, 2)

      fromsq = FindString(AlgSquares,fromSq_str, 1)/2
      tosq = FindString(AlgSquares,toSq_str, 1)/2
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN(" CUCIN proc : fromsq = " + Str(fromsq) + "  tosq = " + Str(tosq))
      CompilerEndIf

      If fromsq = 0 Or tosq = 0
        PrintN(" CnvUCINotation proc ERROR: fromsq = " + Str(fromsq) + "  tosq = " + Str(tosq))
        SetGadgetText(#Info_Field, "...ERROR...fromsq or tosq is invalid...recheck gamescore above...setting both squares to: a1")
        MessageRequester("Move format ERROR!", "...ERROR...fromsq or tosq is invalid...recheck gamescore above...setting both squares to: a1")
        fromSq_str = "a1" : toSq_str = "a1" : fromsq = 91 : tosq = 91
      EndIf
    
      Select Trim(UCI_move_str,Space(1))
        Case WhiteKingSideCastle
          If MbxBrd(95) = Wking And MbxBrd(98) = Wrook ; king on e1 and rook on h1
            MbxBrd(98) = _emptySq
            MbxBrd(96) = Wrook
          EndIf
        Case WhiteQueenSideCastle
          If MbxBrd(95) = Wking And MbxBrd(91) = Wrook ; king on e1 and rook on a1
            MbxBrd(91) = _emptySq
            MbxBrd(94) = Wrook
          EndIf
        Case BlackKingSideCastle
          If MbxBrd(25) = Bking And MbxBrd(28) = Brook; king on e8 and rook on h8
            MbxBrd(28) = _emptySq
            MbxBrd(26) = Brook
          EndIf
        Case BlackQueenSideCastle
          If MbxBrd(25) = Bking And MbxBrd(21) = Brook; king on e8 and rook on a8
            MbxBrd(21) = _emptySq
            MbxBrd(24) = Brook
          EndIf
        Default
          ; do nothing just continue
      EndSelect
      
      movingPiece = MbxBrd(fromSq)
      
      If (movingpiece = Wpawn And FindString(WhiteSquaresEP,Str(tosq),1) > 0) Or (movingpiece = Bpawn And FindString(BlackSquaresEP,Str(tosq),1) > 0)
        If  MbxBrd(tosq) =  _emptysq
          If Abs(fromsq - tosq) = 11                                                ; this is an en passant move
            MbxBrd(fromSq-ColorSign(movingpiece)) = _emptysq ; remove the enemy pawn
            SetGadgetText(#Info_Field, "...this is an en passant move...")
          EndIf
          If Abs(fromsq - tosq) = 9                                                 ; this is also an en passant move
            PrintN(" ep move...")
            MbxBrd(fromSq+ColorSign(movingpiece)) = _emptysq ; remove the enemy pawn
            SetGadgetText(#Info_Field, "...this is an en passant move...")
          EndIf
        EndIf
      EndIf

      MbxBrd(fromSq) = _emptySq
      MbxBrd(toSq) = movingPiece

      If (movingPiece = Bpawn And FindString(BPawnQueenSqs, Str(toSq), 1) > 0) Or (movingPiece = Wpawn And FindString(WPawnQueenSqs, Str(toSq), 1) > 0)
        promopiece = Mid(UCI_move_str,6,1)
        Select promopiece
          Case "Q"                                                                   ; pawn is Queening, other promotions below
            MbxBrd(toSq) = Bqueen + Colorflip(movingPiece)          
            SetGadgetText(#Info_Field, "...the pawn has Queened!...")
          Case "N"                                                                   
            MbxBrd(toSq) = Bknight + Colorflip(movingPiece)
            SetGadgetText(#Info_Field, "...the pawn has promoted to a knight!...")
          Case "B"                                                                
            MbxBrd(toSq) = Bbishop + Colorflip(movingPiece)
            SetGadgetText(#Info_Field, "...the pawn has promoted to a bishop!...")
          Case "R"                                                                
            MbxBrd(toSq) = Brook + Colorflip(movingPiece)
            SetGadgetText(#Info_Field, "...the pawn has promoted to a rook!...")
          Default
            MbxBrd(toSq) = Bqueen + Colorflip(movingPiece)
            SetGadgetText(#Info_Field, "...unknown promotion piece, the pawn has promoted to a queen!...")
        EndSelect
      EndIf
  
      ConstructFENfromPosition()
      Game_FEN_Positions(HalfMoveCount) = FENpositionstr
  
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN("")
        PrintN("Game_FEN_Positions(" + Str(HalfMoveCount) + ") = " + FENpositionstr)
        PrintN("")
  
        PrintN("...from square = " + fromSq_str + "  ...to square = " + toSq_str)
        PrintN("...moving Piece = " + Str(movingPiece))
      CompilerEndIf

  EndSelect

EndProcedure


CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  Procedure DoEventMacOS()
    Select EventMenu()
      Case #PB_Menu_Quit
        PostEvent(#PB_Event_CloseWindow, #mainwin, 0)
      Case #PB_Menu_About
        MessageRequester("About", "PGNdb"+version, #PB_MessageRequester_Info)
      Case #PB_Menu_Preferences
        ;PostEvent(#PB_Event_Menu, 0, #MyMenuItem_Preferences)
        ;
    EndSelect
  EndProcedure
CompilerEndIf



Procedure DisplayGames()
  
  ; This procedure is the EVENT loop for the main window to display the list of games, a games' movescore, and of course the chessboard. This routine
  ; processes all main window clicks, button presses, and keyboard events. After processing an event, it calls the appropriate proceure to actually handle
  ; the event (i.e, NextMove, etc). It should be noted that from a PGN flow processing standpoint that individual PGN games are mostly cleaned and processed
  ; AFTER they are selected (clicked on) in the players-games gadget. It is a bit too time-consuming to process them all as they are being loaded from the
  ; PGNGameFile, depending on the size of the file.
  
  ; This Procedure calls: Add_Game_To_SQLite_DB(), Add_All_Games_To_SQLite_DB_Thread(), BoardDisplay(), ConstructPositionfromFEN(),
  ; GameFENEditorPlus(), NextMove(), PreviousMove(), ParseAndCleanPGN(), Parse_Save_GameScore_Bare_Halfmoves(), Player_Search(), PopulateMovesGadget(),
  ; RemovePGNCommentsAndVariations2(), SetTextColorABGR(), SizeHandler(), SizeHandlerFENEditorButtons()

  Protected WindowID.b, PlayerListGadget.b, MovesGadget.b
  Protected SingleMoveResult.b, FENBtnResult.b, InfoResult.b, Dummy1Result.b, FileInfoResult.b
  Protected PrevBtnResult.b, NextBtnResult.b, DbBtn1Result.b, DbBtn2Result.b, SFBtnResult.b
  Protected SFBtn10secResult.b, PSBtnResult.b, EdBtnResult.b, UpdSFBtnResult.b
  Protected BrdSizeBtnResult.b, PlayvsSFBtnResult, ExportGameBtnResult.b
  Protected GameLink_pos.i, G1_pos.i, G2_pos.i, i.i
  Protected ColorToMove.b, WhiteOnMove.b, x.b, y.i, yy.i, z.i
  Protected currentEvent.i, type.i, modifierFlags.i, keycode.i, wflags.i
  
  wflags = #PB_Window_SizeGadget | #PB_Window_SystemMenu | #PB_Window_ScreenCentered
  WindowID = OpenWindow(#mainwin, 100, 100, #mainwinDefaultWidth, #mainwinDefaultHeight, "PGNdbkp" + version + " - PGN Game And SQLite chessdb Viewer ", wflags)
  PlayerListGadget = ListIconGadget(#Players_ListIcon_Gadget, 20, 10, #playgadgetwidth, #playgadgetDefaultHeight, "White Player", 175, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(#Players_ListIcon_Gadget, 1, "Black Player", 175)
  AddGadgetColumn(#Players_ListIcon_Gadget, 2, "GameDate", 80)
  AddGadgetColumn(#Players_ListIcon_Gadget, 3, "Event/Site", 95)
  AddGadgetColumn(#Players_ListIcon_Gadget, 4, "Result", 65)
  AddGadgetColumn(#Players_ListIcon_Gadget, 5, "Game #", 80)
  
  MovesGadget = ListIconGadget(#Move_ListIcon_Gadget, #movesgadgetX , 10, #movesgadgetwidth, #movesgadgetDefaultHeight, "White Player Moves", #movesgadgetwidth/2, #PB_ListIcon_GridLines)
  AddGadgetColumn(#Move_ListIcon_Gadget, 1, "Black Player Moves", #movesgadgetwidth/2)
  ;CocoaMessage(0, 0, "makeFirstResponder:", GadgetID(0))
  AppWindow = WindowID
  CreateMenu(0, WindowID(#mainwin))
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      MenuItem(#PB_Menu_About, "")
      MenuItem(#PB_Menu_Preferences, "")
      MenuItem(#PB_Menu_Quit, "")
      BindMenuEvent(0, #PB_Menu_About, @DoEventMacOS())
      BindMenuEvent(0, #PB_Menu_Preferences, @DoEventMacOS())
      BindMenuEvent(0, #PB_Menu_Quit, @DoEventMacOS())
    CompilerEndIf
    
  FileInfoResult = StringGadget(#DbFile_Gadget, #fileinfogadgetDefaultX, #fileinfogadgetDefaultY, #fileinfogadgetwidth, 25, "db: " + DB_InputFile)
  FENBtnResult = ButtonGadget(#Btn_Fen, #FENBtnDefaultX, #FENBtnDefaultY, 90, 25, "Show FEN")
  BrdSizeBtnResult = ButtonGadget(#Btn_BoardSize, #ButtonsLeftEdgeDefaultX+85, #FENBtnDefaultY, 100, 25, "BoardSize")
  ExportGameBtnResult = ButtonGadget(#Btn_ExportGame, #ButtonsLeftEdgeDefaultX+185, #FENBtnDefaultY, 100, 25, "ExportGame")
  SingleMoveResult = StringGadget(#Single_Move_Gadget, #ButtonsLeftEdgeDefaultX, #Single_MoveDefaultY, 100, 25, " no moves yet")
  InfoResult = EditorGadget(#Info_Field, #ButtonsLeftEdgeDefaultX, #InfoFieldDefaultY, 200, #InfoFieldDefaultHeight, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
  
  PrevBtnResult = ButtonGadget(#Btn_Prev, #ButtonsLeftEdgeDefaultX, #prevbtnDefaultY, 100, 25, " < move")
  NextBtnResult = ButtonGadget(#Btn_Next, #ButtonsLeftEdgeDefaultX, #nextbtnDefaultY, 100, 25, " > move")
  DbBtn1Result = ButtonGadget(#Btn_Db1, #ButtonsLeftEdgeDefaultX, #dbbtn1DefaultY, 100, 25, "Game to Db")
  DbBtn2Result = ButtonGadget(#Btn_Db2, #ButtonsLeftEdgeDefaultX, #dbbtn2DefaultY, 125, 25, "All Games to Db")
  SFBtnResult = ButtonGadget(#Btn_SFAnaly, #sfbtnDefaultX, #sfbtnDefaultY, 80, 25, "SF Analy")
  SFBtn10secResult = ButtonGadget(#Btn_SF10sec, #sfbtn10secDefaultX, #sfbtn10secDefaultY, 80, 25, "SF 10sec")
  PlayvsSFBtnResult = ButtonGadget(#Btn_PlayvsSF, #sfbtn10secDefaultX+80, #sfbtn10secDefaultY, 110, 25, "PlayVsEngine")
  UpdSFBtnResult = ButtonGadget(#Btn_UpdSF, #sfbtn10secDefaultX+40, #dbbtn2DefaultY, 120, 25, "Update Engine")
  PSBtnResult = ButtonGadget(#Btn_PSearch, #PSearchbtnDefaultX, #PSearchbtnDefaultY, 140, 25, "Player Search/Sort")
  EdBtnResult = ButtonGadget(#Btn_FENEditor, #FENEditbtnDefaultX, #FENEditbtnDefaultY, 100, 25, "FEN Editor")
  
  ; create a canvasgadget for the chessboard
  CanvasGadget(#CanvasGadgetChessBoard, #Canvas_GadgetX, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#canvas_gadgetY), #cg_width, #cg_height, #PB_Canvas_Keyboard)

  
  BindEvent(#PB_Event_SizeWindow, @SizeHandler())

  BoardDisplay()
  
  For i = 1 To GameCount-1
    If Display_Flag(i) = 1
      G1_pos = FindString(WhitePlayers(i), Game_Prefix, 1)
      G2_pos = FindString(BlackPlayers(i), Game_Prefix, 1)
      GameLink = Game_Prefix + Mid(BlackPlayers(i), G2_pos+2, 6)
      AddGadgetItem(#Players_ListIcon_Gadget, -1, Trim(Left(WhitePlayers(i), G1_pos-1), " ") + "[" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + "[" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i) + Chr(10) + GameLink) 
    EndIf
  Next
  ;SetGadgetText(#Info_Field, "db = " + DB_InputFile + #CRLF$ + #CRLF$ + "...Select a game above left...")
  SetGadgetText(#Info_Field, "...Select a game above left...")
  
  Repeat
    
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    ; ********* start of macintosh macos keyscan code *********
    currentEvent = CocoaMessage(0, sharedApplication, "currentEvent")
    If currentEvent
      type = CocoaMessage(0, currentEvent, "type")
      modifierFlags = CocoaMessage(0, currentEvent, "modifierFlags")
      If type = #NSKeyDown
        keyCode = CocoaMessage(0, currentEvent, "keyCode")
        Select keycode
          Case 123                                              ; same code as PreviousButton
            PrintN("Left-Arrow Key down with code : " + Str(keyCode))
            If HalfMoveCount > 0
              PreviousMove()
              SetGadgetText(#Info_Field, "")
            EndIf
          Case 124                                              ; same code as NextButton
            PrintN("Right-Arrow Key down with code : " + Str(keyCode))
            If GameInfo <> ""
              NextMove()
              BoardDisplay()
              SetGadgetText(#Info_Field, "")
            EndIf
        EndSelect
      EndIf
    EndIf
    ; ********* end of macintosh macos keyscan code *********
    CompilerEndIf
    
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      
      ; ********* start of Windows OS keyscan code ************
    
    If GetAsyncKeyState_(#VK_RIGHT) & $8000 ; Check if the right-arrow is down
      ;PrintN("Right-Arrow is down!")
      If GameInfo <> ""
        Delay(150)                          ; yeah i know, kinda kludgy, right-arrow key is very touchy otherwise on Windows
        NextMove()
        BoardDisplay()
        SetGadgetText(#Info_Field, "")
      EndIf
    EndIf
    If GetAsyncKeyState_(#VK_LEFT) & $8000 ; Check if the left-arrow is down
      ;PrintN("Left-Arrow key is down!")
      If HalfMoveCount > 0
        Delay(150)
        PreviousMove()
        SetGadgetText(#Info_Field, "")
      EndIf
    EndIf
    
    ; ********* end of Windows OS keyscan code *********
    CompilerEndIf

    
    Select WaitWindowEvent()
      Case #AnotherBatchOfGamesProcessed
        If GamesInserted <> GameCount - 1
          SetGadgetText(#Info_Field, "***..." + Str(GamesInserted) + " games inserted into sqlite chess database.")
          ;SetGadgetItemColor(#Info_Field, #PB_All, #PB_Gadget_FrontColor, #Red, #PB_All)
          CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
            SetTextColorABGR(#Info_Field, $ff0000ff, 1, 100); make halfmove characters red
          CompilerEndIf
        Else
          CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
            ;SetTextColorABGR(#Info_Field, $00ff0000, 1, 100); make halfmove characters normal
          CompilerEndIf
          SetGadgetText(#Info_Field, "...ALL GAMES..." + Str(GamesInserted) + "...inserted into sqlite chess database: " + DB_InputFile)
        EndIf
      Case #PB_Event_CloseWindow
        Break
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      Case #PB_Menu_Quit
        PostEvent(#PB_Event_CloseWindow, #mainwin, #Null)
    CompilerEndIf
      Case #PB_Event_Gadget
        Select EventType()
          Case #PB_EventType_LeftClick
            Select EventGadget()
              Case #Btn_Fen
                PrintN("FEN = " + Game_FEN_Positions(HalfMoveCount-1))
                If HalfMoveCount > 1
                  SetGadgetText(#Info_Field, Game_FEN_Positions(HalfMoveCount-1))
                Else
                  If FEN_setup_flag(GameIndex+1) = 0
                    SetGadgetText(#Info_Field, FEN_Start_Position)
                  Else
                    SetGadgetText(#Info_Field, FEN_setup_str(GameIndex+1))
                  EndIf
                EndIf
              Case #Btn_BoardSize
                FreeGadget(#CanvasGadgetChessBoard)
                If SquareSize = 60
                  SquareSize = 40
                  CanvasGadget(#CanvasGadgetChessBoard, #Canvas_GadgetX, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#canvas_gadgetY), #cg_width-50, #cg_height-100, #PB_Canvas_Keyboard)
                Else
                  SquareSize = 60
                  CanvasGadget(#CanvasGadgetChessBoard, #Canvas_GadgetX, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#canvas_gadgetY), #cg_width, #cg_height, #PB_Canvas_Keyboard)
                EndIf
                BoardDisplay()
              Case #Btn_ExportGame
                ExportPGNGame()
              Case #Btn_Prev
                If HalfMoveCount > 0
                  PreviousMove()
                  SetGadgetText(#Info_Field, "")
                EndIf
              Case #Btn_Next
                If GameInfo <> ""
                  NextMove()
                  SetGadgetText(#Info_Field, "")
                EndIf
              Case #Btn_Db1
                DB_InputFile = InputRequester("DB Input File", "Please enter the PB Sqlite chess db filename: ", "/users/kenpchess/desktop/kppb_pgn_etc/chesspgn_db.sqlite")
                Add_Game_To_SQLite_DB()
              Case #Btn_Db2
                DB_InputFile = InputRequester("DB Input File", "Please enter the full path of the PB Sqlite chess database filename: ", "/users/kenpchess/desktop/kppb_pgn_etc/chesspgn_db.sqlite")
                CreateThread(@Add_All_Games_To_SQLite_DB_Thread(),1)
              Case #Btn_SFAnaly
                pvstring(1) = "" : pvstring(2) = "" : cpscore_str(1) = "" : cpscore_str(2) = ""
                SF_Time_Per_Move = 1000
                QuickEngine_Flag = #True
                ;PrintN("HalfMoveCount = " + Str(HalfMoveCount-1) + " FEN = " + Game_FEN_Positions(HalfMoveCount))
                If HalfMoveCount > 1
                  SetGadgetText(#Info_Field, "...Stockfish...analyzing...")
                  SF_fenposition = Game_FEN_Positions(HalfMoveCount-1)
                  CreateThread(@Stockfish_FEN_Analysis_Thread(),1)  ; calling Stockfish seems to work best in threaded mode
                Else
                  SetGadgetText(#Info_Field, "...Stockfish...analyzing...")
                  If FEN_setup_flag(GameIndex+1) = 0
                    SF_fenposition = FEN_Start_Position
                    CreateThread(@Stockfish_FEN_Analysis_Thread(),1)  ; calling Stockfish seems to work best in threaded mode
                  Else
                    SF_fenposition = FEN_setup_str(GameIndex+1)
                    CreateThread(@Stockfish_FEN_Analysis_Thread(),1)  ; calling Stockfish seems to work best in threaded mode
                  EndIf
                EndIf
                SetGadgetText(#Info_Field, "...Stockfish...is...analyzing...for...about...2...secs")
                Delay(500)
                QuickEngine_Flag = #False
              Case #Btn_SF10sec
                pvstring(1) = "" : pvstring(2) = "" : cpscore_str(1) = "" : cpscore_str(2) = ""
                SF_Time_Per_Move = 10000
                If HalfMoveCount > 1
                  SetGadgetText(#Info_Field, "...Stockfish...analyzing...")
                  SF_fenposition = Game_FEN_Positions(HalfMoveCount-1)
                  CreateThread(@Stockfish_FEN_Analysis_Thread(),1)  ; calling Stockfish seems to work best in threaded mode
                Else
                  SetGadgetText(#Info_Field, "...Stockfish...analyzing...")
                  If FEN_setup_flag(GameIndex+1) = 0
                    SF_fenposition = FEN_Start_Position
                    CreateThread(@Stockfish_FEN_Analysis_Thread(),1)  ; calling Stockfish seems to work best in threaded mode
                  Else
                    SF_fenposition = FEN_setup_str(GameIndex+1)
                    CreateThread(@Stockfish_FEN_Analysis_Thread(),1)  ; calling Stockfish seems to work best in threaded mode
                  EndIf
                EndIf
                SetGadgetText(#Info_Field, "...Stockfish...is...analyzing...for...10-20...secs")
              Case #Btn_PlayvsSF
                ; nothing yet
                PlayEngine()
              Case #Btn_UpdSF
                Stockfish_Input_Path = InputRequester("Stockfish Path", "Please enter the full file path of your Stockfish executable: ", "/usr/local/bin/stockfish17")
              Case #Btn_PSearch
                Player_Search()
              Case #Btn_FENEditor
                GameFENEditorPlus()
              Case #Players_ListIcon_Gadget
                GameIndex = GetGadgetState(#Players_ListIcon_Gadget)
                GameInfo = GetGadgetItemText(#Players_ListIcon_Gadget, GameIndex,5)
                GameLink_pos = FindString(GameInfo, Game_Prefix, 1)
                GameLink = Mid(GameInfo, GameLink_pos+2, 6)
                CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
                  PrintN("GameInfo Line = " + GameInfo)
                  PrintN("GameLink # = " + GameLink)
                CompilerEndIf
                ColorToMove = WhiteOnMove
                If GameIndex >= 0 And GameIndex <= GameCount
                  FilePGNs(Val(GameLink)) = ParseAndCleanPGN(FilePGNs(Val(GameLink)))
                  RemovePGNCommentsAndVariations2(FilePGNs(Val(GameLink)))
                  FilePGNs(Val(GameLink)) = result
                  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
                    PrintN("FilePGNs(" + Gamelink + ") = " + FilePGNs(Val(GameLink)))
                  CompilerEndIf
                  Parse_Save_GameScore_Bare_Halfmoves(FilePGNs(Val(GameLink)))
                  ;SetGadgetText(#Move_ListIcon_Gadget, FilePGNs(Val(GameLink)))
                  ;SetGadgetText(#Move_ListIcon_Gadget, GameScore_MoveList)
                  PopulateMovesGadget()
                  SetGadgetState(#Move_ListIcon_Gadget, 0)
                  SetGadgetText(#Info_Field, "")
                  If FEN_setup_flag(Val(GameLink)) = 0 
                   SetGadgetText(#Single_Move_Gadget, " no moves yet")
                    BoardInitialize()
                  Else
                    SetGadgetText(#Single_Move_Gadget, " FEN position")
                    ConstructPositionfromFEN(FEN_setup_str(Val(GameLink)))
                  EndIf
                  BoardDisplay()
                  HalfMoveCount = 1
                  For x = 1 To #halfmove_max 
                    Game_FEN_Positions(x) = ""
                  Next
                EndIf
            EndSelect           
        EndSelect
    EndSelect
  ForEver
EndProcedure


Procedure ExportPGNGame()
  

Protected DefaultFileName.s, Pattern.s, PGNFilename.s, FileID.i, G1_pos.i, G2_pos.i
Protected fullversionname.s = "PGNdbkp" + version
Protected nowdate1.s, nowdate2.s, MoveString.s
Protected j.i, year.i, month.i, day.i, hour.i, minute.i, seconds.i


nowdate1 = FormatDate("%yyyy%mm%dd%hh%ii%ss", Date())
nowdate2 = FormatDate("%yyyy%mm%dd", Date())

DefaultFileName = "/Users/kenpchess/Desktop/PGNdbkp_game_" + nowdate1 + ".pgn"
Pattern.s = ""
MoveString = ""

PGNFilename = SaveFileRequester("Save the currently selected single PGN game (or engine game)?", DefaultFileName, Pattern, 0)
FileID = OpenFile(#PB_Any, PGNFileName)

If FileID
  If GameIndex >= 1
    G1_pos = FindString(WhitePlayers(GameIndex+1), Game_Prefix, 1)
    G2_pos = FindString(BlackPlayers(GameIndex+1), Game_Prefix, 1)
    GameLink = Mid(BlackPlayers(GameIndex+1), G2_pos+2, 6)
    If Trim(EventSites(Val(GameLink)),Space(1)) = ""
      WriteStringN(FileID, "[Site " + #DQUOTE$ + "n/a" + #DQUOTE$ + "]")
    Else
      WriteStringN(FileID, "[Site " + #DQUOTE$ + EventSites(Val(GameLink)) + #DQUOTE$ + "]")
    EndIf
    WriteStringN(FileID, "[Date " + #DQUOTE$ + GameDates(Val(GameLink)) + #DQUOTE$ + "]")
    WriteStringN(FileID, "[White " + #DQUOTE$ + Trim(Left(WhitePlayers(Val(GameLink)), G1_pos-1), " ")  + #DQUOTE$ + "]")
    WriteStringN(FileID, "[Black " + #DQUOTE$ + Trim(Left(BlackPlayers(Val(GameLink)), G2_pos-1), " ") + #DQUOTE$ + "]")
    WriteStringN(FileID, "[Result " + #DQUOTE$ + Each_Game_Result(Val(GameLink)) + #DQUOTE$ + "]")
    If FEN_setup_flag(Val(GameLink)) = 1
      WriteStringN(FileID, "[Setup " + #DQUOTE$ + "1" + #DQUOTE$ + "]")
      WriteStringN(FileID, "[FEN " + #DQUOTE$ + FEN_setup_str(Val(GameLink)) + #DQUOTE$ + "]")
    EndIf
  Else
    WriteStringN(FileID, "[Site " + #DQUOTE$ + fullversionname + " exportgame" + #DQUOTE$ + "]")
    WriteStringN(FileID, "[Date " + #DQUOTE$ +  nowdate2 + #DQUOTE$ + "]")
    WriteStringN(FileID, "[White " + #DQUOTE$ + "HumanPlayer" + #DQUOTE$ + "]")
    WriteStringN(FileID, "[Black " + #DQUOTE$ + "Eng:" + Stockfish_Input_Path + #DQUOTE$ + "]")
    WriteStringN(FileID, "[Result " + #DQUOTE$ + "*" + #DQUOTE$ + "]")
  EndIf
  WriteStringN(FileID, "")
  
  For j = 1 To TotalHalfMoves
    If j % 2 > 0 And J <> TotalHalfMoves
      MoveString = MoveString + Str(j/2 + 1) + ". " + ReplaceString(GameScore_Plain_HalfMoves(j),Space(1),"") + Space(1)
    Else
      MoveString = MoveString + ReplaceString(GameScore_Plain_HalfMoves(j),Space(1),"") + Space(1)
    EndIf
  Next
  MoveString = Trim(Movestring,Space(1))
  If GameIndex < 1
    MoveString = MoveString + Space(1) + "*"
  EndIf
  WriteString(FileID, MoveString)
  CloseFile(FileID)
  SetGadgetText(#Info_Field, "Text file: " + PGNFilename + " created successfully.")
Else
  SetGadgetText(#Info_Field, "Error: Could Not create Or open file :" + PGNFileName)
EndIf
  
EndProcedure



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


Procedure GameFENEditorPlus()
  
  Protected i.i, Demographic_Info.s, Position_Info.s, Save_Text.s, WhitePlayer.s, BlackPlayer.s, Info_Result.s, Info_Description.s, GameLink.s
  Protected Space1_pos.b, Space2_pos.b, Move_Sequence.s, Start_Info.s
  Protected piece_sqr_list.s, piece_square.s, piece.s, asquare.s, piece_list.s, all_mbxsquares.s
  Protected mbx_square.b, mbx_piece.b, STF_flag.b
  Protected xc.i, yc.i, Event.i, currentEvent.i, type.i
  
  
    SetGadgetText(#Info_Field, "...Now in point-and-click GUI editor mode...click on piece, then click on square...click [Exit Ed/Move] to exit")
    BoardEditorDisplay()
    BindEvent(#PB_Event_SizeWindow, @SizeHandlerFENEditorButtons())
    
    Counter = 0
    Repeat
      Event = WaitWindowEvent(1)
      If Event = #PB_Event_Gadget
        SelectPieceButton()
      Else
        ; do nothing for now
      EndIf
      
      
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    
        currentEvent = CocoaMessage(0, sharedApplication, "currentEvent")
        If currentEvent
          type = CocoaMessage(0, currentEvent, "type")
          Select type
            Case #NSLeftMouseUp
              clickCount = CocoaMessage(0, currentEvent, "clickCount")
              PrintN("Left mouse " + Str(clickCount) + "x clicked"); kp
              CocoaMessage(@location, currentEvent, "locationInWindow")
              mailbox_editor_squareXY = 0       
              xc = location\x : yc = WindowHeight(#mainwin)-location\y
              ;xc = location\x : yc = #mainwinDefaultHeight-location\y
              MailboxMouseXY(xc.i,yc.i)
              ;PrintN("Mouse moved to (" + StrF(location\x, 1) + "," + StrF(WindowHeight(AppWindow)-location\y, 1) + ")"); use WindowHeight() to flip y coordinate
              PrintN("You clicked in mailbox square = " + Str(mailbox_editor_squareXY))
              If mailbox_editor_squareXY >= 21 And mailbox_editor_squareXY <= 98
                MbxBrd(mailbox_editor_squareXY) = Mailbox_editor_piece
                BoardDisplay() ;: FreeBoardEditorGadgets() : BoardEditorDisplay()
              EndIf
            Case #NSMouseMoved
              CocoaMessage(@location, currentEvent, "locationInWindow")
              ;PrintN("Mouse moved to (" + StrF(location\x, 1) + "," + StrF(WindowHeight(AppWindow)-location\y, 1) + ")"); use WindowHeight() to flip y coordinate
              If location\x >= 135 And location\x <= 195 And #mainwinDefaultHeight-location\y >= 500 And #mainwinDefaultHeight-location\y <= 560
                ;PrintN("You are in mailbox square 21")
              EndIf
          EndSelect
        EndIf
        
      CompilerEndIf
      
      
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    
    Select Event
      Case #WM_LBUTTONDOWN
      ReportCursor("#WM_LBUTTONDOWN - You clicked: ")
      mailbox_editor_squareXY = 0
      mx=GetMouseX(#CanvasGadgetChessBoard) : my=GetMouseY(#CanvasGadgetChessBoard)
      xc = #canvas_gadgetX + mx : yc = #canvas_gadgetY + my
      MailboxMouseXY(xc.i,yc.i)
      PrintN("#WM_LBUTTONDOWN - You clicked in mailbox square = " + Str(mailbox_editor_squareXY))
      If mailbox_editor_squareXY >= 21 And mailbox_editor_squareXY <= 98
        PrintN("Setting mailbox square " + Str(mailbox_editor_squareXY) + " to contain: " + Str(Mailbox_editor_piece))
        MbxBrd(mailbox_editor_squareXY) = Mailbox_editor_piece
        BoardDisplay() ;: FreeBoardEditorGadgets() : BoardEditorDisplay()
      EndIf
 
      Case #WM_MOUSEMOVE
        mx=GetMouseX(#CanvasGadgetChessBoard) : my=GetMouseY(#CanvasGadgetChessBoard)
        ;ReportCursor("#WM_MouseMove - Mouse moved to: ")
      Default
        ; nothing for now
      EndSelect
      
  CompilerEndIf
      
  Until Counter >= 99
  

  SetGadgetText(#Info_Field, "")
  ConstructFENfromPosition()
  SetGadgetText(#Info_Field, FENpositionstr)
  
  STF_flag = #False
  Demographic_Info = InputRequester("White and Black and Description", "Enter any whiteplayer blackplayer description plus date : ", "Fischer Spassky game position-001 19721001")
  Position_Info = InputRequester("FEN string or Squares info", "Enter FEN string (default is FEN GUI construct), or squares info (Ke4 Pf4 ke6 pg6 STF...etc [stockfish analysis]): ", FENpositionstr)
  If FindString(Position_Info,"/",1) > 0
    Save_Text = InputRequester("Save FEN Position in GameList", "Save this FEN position in the gamelist?", "Yes")
  Else
    Save_Text = "No"
  EndIf
    
  If FindString(Save_Text,"Yes",1) > 0
    Move_Sequence = InputRequester("Bestmove sequence for this FEN", "Enter any bestmove sequence for this FEN: ", "1. Qxf6+ Kxf6")
    FEN_setup_str(GameCount) = Position_info
    FEN_setup_flag(GameCount) = 1
    Display_Flag(GameCount) = 1
    Space1_pos = FindString(Demographic_Info,Space(1),1)
    Space2_pos = FindString(Demographic_Info,Space(1),Space1_pos+1)
    WhitePlayer = Left(Demographic_Info,Space1_pos-1)
    BlackPlayer = Mid(Demographic_Info, Space1_pos+1,Space2_pos-Space1_pos-1)
    Info_Description = Right(Demographic_Info, Space2_pos+1)
    Info_Result = " *"
    GameLink = Game_Prefix + Str(GameCount)
    
    WhitePlayers(GameCount) = WhitePlayer + Space(3) + Game_Prefix + Str(GameCount)
    BlackPlayers(GameCount) = BlackPlayer + Space(3) + Game_Prefix + Str(GameCount)
    EventSites(GameCount) = Info_Description
    Each_Game_Result(GameCount) = Info_Result
    FilePGNs(GameCount) = Move_Sequence + Info_Result
    PrintN("New game position addition = " + WhitePlayer + Space(2) + BlackPlayer + Space(2) + Info_Result + Space(2) + GameLink)
    AddGadgetItem(#Players_ListIcon_Gadget, -1, WhitePlayer + Chr(10) + BlackPlayer + Chr(10) + "20990101" + Chr(10) + Info_Description + Chr(10) + Info_Result + Chr(10) + GameLink)
    SetGadgetItemState(#Players_ListIcon_Gadget, GameCount-1, #PB_ListIcon_Selected)
    GameCount = GameCount + 1
  Else
    If FindString(Position_Info,"/",1) > 0
      ;just convert and show FEN on the board
      ConstructPositionfromFEN(Position_Info)
      SetGadgetState(#Players_ListIcon_Gadget, -1)
      SetGadgetText(#Move_ListIcon_Gadget, "")
      BoardDisplay()
    Else                                                   ; EASTER EGG non-FEN square mode (Qe4 Pf4 Pg4 kf6 pg6 etc, Ef2 is empty sqr, STF calls Stockfish)
      Start_Info = InputRequester("Start Position Info", "[Start]ing position, [Empty] board, [Exist]ing position - plus your square edits: ", "Empty")
      Select Start_Info
        Case "Start"
          BoardInitialize()
        Case "Empty"
          BoardEmpty()
        Case "Exist"
          ; do nothing
        Default
          BoardEmpty()
      EndSelect
      all_mbxsquares = ""
      piece_list = "ErnbqkpRNBQKP"
      piece_sqr_list = position_info
      For i = 1 To Len(piece_sqr_list)-2 Step 4
        piece_square = Mid(piece_sqr_list,i,3)
        If piece_square <> "STF"
          piece = Left(piece_square,1)
          asquare = Mid(piece_square,2,2)
          mbx_square = FindString(AlgSquares,asquare, 1)/2
          all_mbxsquares = all_mbxsquares + Str(mbx_square) + Space(1)
          mbx_piece = FindString(piece_list,piece,1)-1
          MbxBrd(mbx_square) = mbx_piece
        Else
          STF_flag = #True
          Continue
        EndIf
      Next
      ConstructFENfromPosition()
      If STF_flag
        SF_fenposition = FENpositionstr
        SetGadgetText(#Info_Field, "...Stockfish...is...analyzing...for...about...2...secs")
        CreateThread(@Stockfish_FEN_Analysis_Thread(),1)  ; calling Stockfish seems to work best in threaded mode
      EndIf
      PrintN("All mailbox squares list = " + all_mbxsquares)
      BoardDisplay()
    EndIf
  EndIf
  
  FreeBoardEditorGadgets()
  UnbindEvent(#PB_Event_SizeWindow, @SizeHandlerFENEditorButtons()) ; Unbind it immediatel

EndProcedure


CompilerIf #PB_Compiler_OS = #PB_OS_Windows

Procedure GetMouseX(gadget)    ;;  by griz
  GetCursorPos_(mouse.POINT) 
  MapWindowPoints_(0,GadgetID(gadget),mouse,1) 
  ProcedureReturn mouse\x 
EndProcedure 

Procedure GetMouseY(gadget) 
  GetCursorPos_(mouse.POINT) 
  MapWindowPoints_(0,GadgetID(gadget),mouse,1) 
  ProcedureReturn mouse\y 
EndProcedure 

Procedure ReportCursor(msg1.s)
  mx=GetMouseX(#CanvasGadgetChessBoard) : my=GetMouseY(#CanvasGadgetChessBoard)
  PrintN(Msg1 + " x = " + Str(#canvas_gadgetX+mx) + " y = " + Str(#canvas_gadgetY+my))
EndProcedure   

CompilerEndIf



Procedure GetBestMoveUCIPV(ProgramID, fen.s, searchTime_ms, MultiPV.b)
  Protected pv1a.w, pv1b.w, pv2a.w, pv2b.w, response2.s
  If MultiPV = 2
    SendUCICommand(ProgramID, "setoption name MultiPV value 2")
    Delay(10)
  EndIf
  SendUCICommand(ProgramID, "position fen " + fen)
  SendUCICommand(ProgramID, "go movetime " + Str(searchTime_ms))
  
  Protected startTime = ElapsedMilliseconds(), response.s, pos, endPos, pv, cpscore, nodes
  bestmove = ""
  output = ""
  While ElapsedMilliseconds() - startTime < searchTime_ms + 1000 ; Add extra time for the response
    
    ReadUCIResponse(ProgramID, 50)
    response2 = output
    ;PrintN("SF analy = " + response2)
    If MultiPV = 2
      pva = FindString(response2, "multipv 2", 1)
    Else
      pva = FindString(response2, "multipv 1", 1)
    EndIf
    pvb = FindString(response2, "pv ", pva+9) ; skip over multipv string

    pos = FindString(response2, "bestmove", 1)
    cpscore_pos = FindString(response2, "score cp", 1)
    nodes = FindString(response2, "nodes", 1)
    If pvb > 0
      pvstring(MultiPV) = Mid(response2, pvb+3,90)
      PrintN("")
      PrintN("pvstring" + "(" + Str(multipv) + ") = " + pvstring(MultiPV))
      PrintN("")
    EndIf
    
    If cpscore_pos
      cpscore_str(MultiPV) = Trim(Mid(response2, cpscore_pos+9, nodes-cpscore_pos-9), Space(1))
      PrintN("")
      PrintN("score(" + Str(MultiPV) + ") = " + cpscore_str(MultiPV))
      PrintN("")
    EndIf

    If pos
      ; Find the start of the bestmove value (after "bestmove ")
      pos = pos + Len("bestmove ")
      ; Find the end of the bestmove value (usually the next space or end of line)
      endPos = FindString(response, " ", pos)
      If endPos
        bestmove = Mid(response, pos, endPos - pos)
      Else
        bestmove = Mid(response, pos) ; Bestmove is the last word on the line
      EndIf
      XTrim(bestmove)
    EndIf
    Delay(10)
  Wend
  ;ProcedureReturn "" ; Return empty string if best move not found within timeout
EndProcedure



Procedure LoadPGN_Thread(null)
  Protected FileHandle, GameLine.s, WhitePlayer.s, BlackPlayer.s, GamePGN.s, ChessEvent.s, WhiteElo.s, BlackElo.s
  Protected ChessSite.s, ChessDate.s, InGame.b, MovesStarted.b, Quote1.i, Quote2.i, x.i, j.i, filelen.i
  Protected readBytes.l
  
  All_Games_Read_Flag = 0
  ;PrintN("filename = " + PGNFileName)
  FileHandle = ReadFile(0, PGNFileName)
  If FileHandle
    GamePGN = "" : GameLine = "" : WhitePlayer = "" : BlackPlayer = "" : ChessEvent = ""
    ChessSite = "" : ChessDate = "" : WhiteElo = "n/a" : BlackElo = "n/a" : GameCount = 1 : MovesStarted = 0
    For x = 1 To #halfmove_max : FEN_setup_flag(x) = 0 : FEN_setup_str(x) = ""
      Each_Game_Result(x) = "" : WhiteElos(x) = "n/a" : BlackElos(x) = "n/a"
      Display_Flag(x) = 0
    Next
    fileLen = Lof(0) 
    While Not Eof(0)
      GameLine = ReadString(0) : GameLine = Trim(GameLine,Space(1)) : GameLine = Trim(GameLine,Chr(13)) : GameLine = Trim(GameLine,Chr(10))
      
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        ;PrintN("GameLine = " + GameLine)
      CompilerEndIf
      
      If GameLine <> ""             ; End of a GamePGN or blank line
        GameTag = Left(GameLine, FindString(GameLine,Space(1))-1)
        Select GameTag
          Case WhiteTag
            WhitePlayer = Mid(GameLine, 9, Len(GameLine) - 10)           ;PrintN("White = " + WhitePlayer)
          Case BlackTag
            BlackPlayer = Mid(GameLine, 9, Len(GameLine) - 10)           ;PrintN("Black = " + BlackPlayer)
          Case EventTag
            ChessEvent = Mid(GameLine, 9, Len(GameLine) - 10)
          Case SiteTag
            ChessSite = Mid(GameLine, 8, Len(GameLine) - 9)
          Case DateTag
            ChessDate = Mid(GameLine, 8, Len(GameLine) - 9)
            ChessDate = ReplaceString(ChessDate, Space(1), "")           ; remove spaces
            ChessDate = ReplaceString(ChessDate, ".", "")                ; remove periods
          Case WhiteEloTag
            WhiteElo = Trim(Mid(GameLine, 12, Len(GameLine) - 13),Space(1))
            If WhiteElo = ""
              WhiteElo = "n/a"
            EndIf
          Case BlackEloTag
            BlackElo = Trim(Mid(GameLine, 12, Len(GameLine) - 13),Space(1))
            If BlackElo = ""
              BlackElo = "n/a"
            EndIf
          Case FENTag
            ;PrintN("...FEN " + GameLine)
            FEN_setup_flag(GameCount) = 1
            Quote1 = FindString(Gameline,Chr(34),1)
            Quote2 = FindString(Gameline,Chr(34),Quote1+1)
            ;PrintN("Quote1 = " + Str(Quote1) + "  Quote2 = " + Str(Quote2))
            FEN_setup_str(GameCount) = Mid(GameLine,Quote1+1,Quote2-Quote1-1)
            PrintN("")
            PrintN("FEN_setup_str = " + FEN_setup_str(GameCount))
        EndSelect
        
        If FindString(GameLine, "1.", 1) = 1  And MovesStarted = 0; Start of moves
          MovesStarted = 1
          GamePGN = GameLine + " " ; Initialize moves string with White to move
        Else
          If FindString(GameLine, Ellipsis_move, 1) = 1 And MovesStarted = 0; FEN setup and Black to move
            MovesStarted = 1
            GamePGN = GameLine + " " ; Initialize moves string with Black to move
          Else
            If Left(GameTag,1) = "[" And Right(GameTag,1) = "]"
              ; tag or junk gametag, we have the info from above, just toss it away
            Else
              GamePGN = GamePGN + GameLine + " " ; Append moves as normal gameline
            EndIf
          EndIf
        EndIf

        Game_Result = ""
        For j = 1 To 4
          If FindString(GameLine,GameResult_Tags(j),1) > 0
            Game_Result = Trim(GameResult_Tags(j), Space(1))
          EndIf
        Next
        
        If Game_Result <> "" And FindString(GameLine,"[Result") = 0  ;		do not want this line to be a pgn tagline, but just actual game result only
          If WhitePlayer <> "" And BlackPlayer <> ""
            WhitePlayers(GameCount) = WhitePlayer + Space(3) + Game_Prefix + Str(GameCount)
            BlackPlayers(GameCount) = BlackPlayer + Space(3) + Game_Prefix + Str(GameCount)
            WhiteElos(GameCount) = WhiteElo
            BlackElos(GameCount) = BlackElo
            EventSites(GameCount) = ChessEvent + Space(2) + ChessSite
            If ChessDate = ""
              GameDates(GameCount) = AssignedChessDate
            Else
              GameDates(GameCount) = ChessDate
            EndIf
            Each_Game_Result(GameCount) = Game_Result
            GamePGN = ReplaceString(GamePGN, Space(2), Space(1)) ; convert any double-spaces to a single space
            ;RemovePGNCommentsAndVariations2(GamePGN.s)
            ;FilePGNs(GameCount) = result
            ;FilePGNs(GameCount) = ParseAndCleanPGN(GamePGN)      ; parseandcleanpgn() is latest best attemt at cleaning grungy PGNs
            FilePGNs(GameCount) = GamePGN
            CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
              PrintN("FilePGNs(GameCount) = " + FilePGNs(GameCount))
            CompilerEndIf
            Display_Flag(GameCount) = 1
            CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
              PrintN("GameDate = " + GameDates(GameCount)) : PrintN("WhiteElo = " + WhiteElos(GameCount))
              PrintN("BlackElo = " + BlackElos(GameCount)) : PrintN("GameCount = " + Str(GameCount))
              PrintN("FilePGN = " + FilePGNs(GameCount))
            CompilerEndIf
            GameCount = GameCount + 1
            If GameCount > #game_max
              Break
            EndIf
            WhitePlayer = "" : BlackPlayer = "" : GamePGN = "" : GameLine = ""  : Game_Result = "" : ChessDate = ""
            ;FEN_setup_flag = 0 : FEN_setup_str = ""
            MovesStarted = 0
            ReadByte(0) : readBytes = Loc(0)      ; get current read location
            If Mod(readBytes, #progressBytes) = 0 
              PostEvent(#progressBarEvent, -1, -1, -1, readBytes)   ; post the custom event with the current read location
              ;Delay(1)        
            EndIf
          EndIf
        EndIf
      EndIf
    Wend
    CloseFile(0)
    PostEvent(#progressBarEvent, -1, -1, -1, readBytes)
    All_Games_Read_Flag = 1
  EndIf
EndProcedure



Procedure LoadSQLiteChessDatabase(FileName.s)

  Protected i.i, j.i, k.i, numberOfColumns.i, ucimove_length.b, numbered_ucimoves.s, movenumber.i, space_pos1.i, space_pos2.i
  Protected HalfMove_Pair.s, AnyFEN_str.s, GameLink_pos.i, WhitePlayer.s, Blackplayer.s, query.s, ucimoves_str.s, TheGameDate.s
  Protected Result_pos.i, Search_Result.i, Game_Result.s
  
#sqlite = 0

; initialise SQLite library
UseSQLiteDatabase()

;If OpenDatabase(#sqlite, "/Users/testuser/Desktop/kppb_pgn_etc/" + DB_InputFile, "", "")
If OpenDatabase(#sqlite, DB_InputFile, "", "")

  ; retrieve ALL (*) data and records from the pgngames table
  query.s = "SELECT * FROM pgngames"
  
  ; results matching query retrieved
  If DatabaseQuery(#sqlite, query)
    
    GameCount = 0
    ; iterate through all the retrieved results
    While NextDatabaseRow(#sqlite)                    
      
      k = 1
      movenumber = 1
      ucimove_length = 0
      AnyFEN_str = ""
      GameCount = GameCount + 1
      ; retrieve & display the ID number which is in the first column (column 0)
      PrintN(#CRLF$ + "Record #" + Str(GetDatabaseLong(#sqlite, 0)) + ":")
      
      ; determine the number of columns in the retrieved row
      ;numberOfColumns = DatabaseColumns(#sqlite)
      
      ; iterate through the columns from column 1
      ; determine the column type
      ;columnType = DatabaseColumnType(#sqlite, i)

      ;If columnType = #PB_Database_String
       
       PrintN("GameCount = " + Str(GameCount))
       EventSites(GameCount) = GetDatabaseString(#sqlite, 1)
       GameDates(GameCount) = GetDatabaseString(#sqlite, 2)
       WhitePlayers(GameCount) =  GetDatabaseString(#sqlite, 3) + Space(3) + Game_Prefix + Str(GameCount)
       PrintN("Whiteplayer = " + WhitePlayers(GameCount))
       WhiteElos(GameCount) = GetDatabaseString(#sqlite, 4)
       PrintN("WhiteElo = " + WhiteElos(GameCount))
       BlackPlayers(GameCount) =  GetDatabaseString(#sqlite, 5) + Space(3) + Game_Prefix + Str(GameCount)
       PrintN("Blackplayer = " + BlackPlayers(GameCount))
       BlackElos(GameCount) = GetDatabaseString(#sqlite, 6)
       PrintN("BlackElo = " + BlackElos(GameCount))
       AnyFEN_str = Trim(GetDatabaseString(#sqlite, 7), Space(1))
       Each_Game_Result(GameCount) = GetDatabaseString(#sqlite, 8)
       PrintN("GameResult = " + Each_Game_Result(GameCount))
       Display_Flag(GameCount) = 1
       
       If AnyFEN_str <> ""
         FEN_setup_str(GameCount) = AnyFEN_str
         FEN_setup_flag(GameCount) = 1
       EndIf
         
       ucimoves_str = Trim(GetDatabaseString(#sqlite, 9))
       ucimoves_str = ReplaceString(ucimoves_str, Space(2), Space(1))
       numbered_ucimoves = ""
       ucimove_length = Len(ucimoves_str)
       HalfMove_Pair = ""
       PrintN("PGN moves = " + ucimoves_str)
       
       Search_Result = 0
       Result_pos = 0
       For j = 1 To 4
         Search_Result = FindString(GameScore_MoveList,Trim(GameResult_Tags(j),Space(1)),1)
         If  Search_Result > 0
           Game_Result = Trim(GameResult_Tags(j), Space(1))
           PrintN("Game_Result = " + Game_Result)
           Result_pos = Search_Result
         EndIf
       Next
       
       
       While FindString(HalfMove_Pair,Game_Result) <= 0 And Len(ucimoves_str) > 0
         space_pos1 = FindString(ucimoves_str,Space(1), 1)
         space_pos2 = FindString(ucimoves_str,Space(1), space_pos1+1)
         If space_pos2 > 0
           HalfMove_Pair = Mid(ucimoves_str, 1, space_pos2-1)
           ucimoves_str = Trim(Mid(ucimoves_str, space_pos2+1, 3000), Space(1))
           numbered_ucimoves = numbered_ucimoves + Str(movenumber) + "." + Space(1) + HalfMove_Pair + Space(1)
         Else
           If space_pos1 > 0
             HalfMove_Pair = Left(ucimoves_str, space_pos1)
             ucimoves_str = Trim(Mid(ucimoves_str, space_pos1+1, 3000), Space(1))
             numbered_ucimoves = numbered_ucimoves + Str(movenumber) + "." + Space(1) + HalfMove_Pair
           Else
             numbered_ucimoves = numbered_ucimoves + Left(ucimoves_str, 7)
             ucimoves_str = ""
           EndIf
         EndIf
         movenumber = movenumber + 1
         ;numbered_ucimoves = numbered_ucimoves + Str(movenumber) + "." + Space(1) + HalfMove_Pair + Space(1)
         ;ucimove_length = Len(ucimoves_str)
       Wend
       
       PrintN("Numbered ucimoves = " + numbered_ucimoves)
       FilePGNs(GameCount) = numbered_ucimoves
       
     Wend
    
    ; release the database query resources
    FinishDatabaseQuery(#sqlite)
  EndIf
Else
  Debug "error opening database! " + DatabaseError()
EndIf

EndProcedure



Procedure LocateTheKings()

  Protected i.b

  For i = 21 To 98
    If MbxBrd(i) <> #OffTheBoard
      If MbxBrd(i) = Wking
        WhiteKingCurrentSq = i
      EndIf
      If MbxBrd(i) = Bking
        BlackKingCurrentSq = i
      EndIf
    EndIf
  Next

EndProcedure


Procedure LocateTheQueen(isWhite.b)

  Protected i.b

  CountOfQueens = 0
  For i = 21 To 98
    If MbxBrd(i) <> #OffTheBoard
      If isWhite
        If MbxBrd(i) = Wqueen
          If FindString(ValidQueenMbxSqs(i),Str(toSquareMailbox),1) > 0                        ; SAN destination sq is a pseudo-legal valid move sq from this found queen sq
            ;PrintN("ValidQueenMbxSqs(" + Str(i) + ") = " + ValidQueenMbxSqs(i))
            WhiteQueenCurrentSq = i
            CountOfQueens = CountOfQueens + 1
            Break
          EndIf
        EndIf
      Else
        If MbxBrd(i) = Bqueen
          If FindString(ValidQueenMbxSqs(i),Str(toSquareMailbox),1) > 0                        ; SAN destination sq is a pseudo-legal valid move sq from this found queen sq
            BlackQueenCurrentSq = i
            CountOfQueens = CountOfQueens + 1
            Break
          EndIf
        EndIf
      EndIf
    EndIf
  Next

EndProcedure



Procedure LocateLightOrDarkSquareBishop(isWhite.b,XtoSq.b)

  Protected i.b, LightOrDarkSearchSq.b, Xpiece.b, fromsq1.b, sumsqdigits.b

  If isWhite
    Xpiece = Wbishop
  Else
    Xpiece = Bbishop
  EndIf
  
  sumsqdigits = Val(Left(Str(XtoSq),1)) + Val(Mid(Str(XtoSq),2,1))
  If sumsqdigits % 2 = 0
    LightOrDarkToSq = #DarkSq                                       ; sum of sq digits is even, so dark square!
  Else
    LightOrDarkToSq = #LightSq                                             ; sum of sq digits is odd, so light square!
  EndIf

    For i = 21 To 98
      If MbxBrd(i) <> #OffTheBoard
        If MbxBrd(i) = Xpiece
          sumsqdigits = Val(Left(Str(i),1)) + Val(Mid(Str(i),2,1))
          If sumsqdigits % 2 = 0
            ;PrintN("...sum of sq digits = " + Str(sumsqdigits) + "...is a dark square") 
            LightOrDarkSearchSq = #DarkSq
          Else
            ;PrintN("...sum of sq digits = " + Str(sumsqdigits) + "...is a light square") 
            LightOrDarkSearchSq = #LightSq
          EndIf
          If LightOrDarkSearchSq = LightOrDarkToSq
            fromsq1 = i
            ;PrintN("...in LLDSB bishop...fromsq1 = " + Str(fromsq1) + "...xpiece = " +Str(xpiece))
            SavePossibleMoveMailBoxSquare(fromSq1.b)
            Break
          EndIf
        EndIf
      EndIf
    Next

EndProcedure



Procedure LegalMovesPawn(san.s,isWhite.b,piece.s)

  Protected captureMove.b, i.b

    
    captureMove = FindString(san,"x",1)
    ;PrintN("...in LMPawn...SAN = " + san + "...len(san) = " + Str(Len(san)) + "...capturemove = " + Str(captureMove))

    If (Len(san)=4 And captureMove > 0) 
      toSq_str = Mid(san,3,2)
      disambiguator_symbol = Mid(san,1,1)
      If FindString("abcdefgh",disambiguator_symbol,1) > 0
        disambiguator_sq_list = Mid(file_disambiguator,FindString(file_disambiguator,disambiguator_symbol,1)+1,24)
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN("...disambiguatur_sq_list = " + disambiguator_sq_list)
        CompilerEndIf
      EndIf
    Else
      toSq_str = Mid(san,1,2)
    EndIf
    toSquareMailbox = FindString(AlgSquares,toSq_str,1)/2
    If isWhite
      If captureMove <= 0
        For i = 20 To 10 Step -10
          fromSquareMailbox = toSquareMailbox + i
          If BoardSqIsEmptyMailbox(toSquareMailbox)                                      ; is pawn blocked?
            If i = 10 Or (i = 20 And FindString(WPawn2MoveSqs,Str(fromSquareMailbox),1) > 0 And BoardSqIsEmptyMailbox(toSquareMailbox+10))      ; Check two-step move
              SavePossibleMoveMailBoxSquare(fromSquareMailbox.b)
            EndIf
          EndIf
        Next
      EndIf
                                                                  
      If captureMove > 0                                                                 ; Check for diagonal pawn captures
        For i = 9 To 11 Step 2
          fromSquareMailbox = toSquareMailbox + i
          If MbxBrd(fromSquareMailbox) = Wpawn And (MbxBrd(toSquareMailbox) > 0 Or FindString(WhiteSquaresEP,Str(toSquareMailBox),1) > 0)
            If FindString(disambiguator_sq_list,Str(fromSquareMailbox),1) > 0
              CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
                PrintN("...White diagonal pawn capture dir = " + Str(i))
              CompilerEndIf
              SavePossibleMoveMailBoxSquare(fromSquareMailbox.b)
            EndIf
          EndIf
        Next
      EndIf
    Else ; Black pawn
      
      If captureMove <= 0
        For i = 20 To 10 Step -10
          fromSquareMailbox = toSquareMailbox - i
          If BoardSqIsEmptyMailbox(toSquareMailbox)                                       ; is pawn blocked?
            If i = 10 Or (i = 20 And FindString(BPawn2MoveSqs,Str(fromSquareMailbox),1) > 0 And BoardSqIsEmptyMailbox(toSquareMailbox-10))       ; Check two-step move
              SavePossibleMoveMailBoxSquare(fromSquareMailbox.b)
            EndIf
          EndIf
        Next
      EndIf

      If captureMove > 0                                                                 ; Check for diagonal pawn captures
        For i = 9 To 11 Step 2
          fromSquareMailbox = toSquareMailbox - i
          If MbxBrd(fromSquareMailbox) = Bpawn And (MbxBrd(toSquareMailbox) > 0 Or FindString(BlackSquaresEP,Str(toSquareMailBox),1) > 0)
            If FindString(disambiguator_sq_list,Str(fromSquareMailbox),1) > 0
              CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
                PrintN("...Black diagonal pawn capture dir = " + Str(-i))
              CompilerEndIf
              SavePossibleMoveMailBoxSquare(fromSquareMailbox.b)
            EndIf
          EndIf
        Next
      EndIf
    EndIf

EndProcedure



Procedure LegalMovesKnightAndKing(isWhite.b,piece.s)

  Protected Xpiece.b, i.b, fromsq1.b, kingsq.b, possible_saved_piece.b
  
  ;PrintN("...in knight and king routine...Piece = " + piece)
  For i = 1 To 8    
    Select piece
      Case "N"
        If isWhite
          XPiece = Wknight
        Else
          XPiece = Bknight
        EndIf
        ;PrintN("...xpiece = " + Str(xpiece) + "...")
        fromsq1 = toSquareMailbox + knight_dirs(i)
        ;PrintN(" fromsq1 = " + Str(fromsq1) + "  MbxBrd(fromsq1) = " + Str(MbxBrd(fromsq1)))
        ;PrintN(" knight_dir(i) = " + Str(knight_dirs(i)))
      Case "K"
        If isWhite
          XPiece = Wking
        Else
          XPiece = Bking
        EndIf
        fromsq1 = toSquareMailbox + king_dirs(i)
        ;PrintN(" king_dir(i) = " + Str(king_dirs(i)))
    EndSelect

    If MbxBrd(fromsq1) = Xpiece
      If disambiguator_sq_list <> "" 
        If FindString(disambiguator_sq_list,Str(fromsq1),1) > 0
          ;PrintN("...in If MbxBrd...fromsq1 = " + Str(fromsq1) + "...xpiece = " + Str(xpiece) + "...disam_sq_list = " + disambiguator_sq_list)
          SavePossibleMoveMailBoxSquare(fromSq1.b)
          Break
        Else
          Continue
        EndIf
      Else
        If Xpiece = Wknight Or Xpiece = Bknight
          LocateTheKings()
          If isWhite
            kingsq = WhiteKingCurrentSq
          Else
            kingsq = BlackKingCurrentSq
          EndIf
          possible_saved_piece = MbxBrd(toSquareMailbox)
          MbxBrd(fromsq1) = 0                                                 ; temporarily remove knight from board and make the move
          MbxBrd(toSquareMailbox) = Xpiece
          If SquareIsAttacked(kingsq,isWhite)                                         ; that knight must be pinned if kingsq is attacked
            ;PrintN("...knight is pinned on...square..." + Str(fromsq1))
            MbxBrd(fromsq1) = Xpiece                                          ; put back the knight
            MbxBrd(toSquareMailbox) = possible_saved_piece
            Break                                                             ; since knight is pinned break out of routine, do not save fromsq1
          Else
            ;PrintN("...knight is NOT pinned on...square..." + Str(fromsq1))
            MbxBrd(fromsq1) = Xpiece                                          ; king square is not attacked, OK fall thru and save fromsq1
            MbxBrd(toSquareMailbox) = possible_saved_piece
          EndIf
          ;MbxBrd(fromsq1) = Xpiece
        EndIf
        ;PrintN("...in If MbxBrd...fromsq1 = " + Str(fromsq1) + "...xpiece = " +Str(xpiece))
        SavePossibleMoveMailBoxSquare(fromSq1.b)
        Break
      EndIf
    EndIf

  Next

EndProcedure


Procedure LegalMovesBishopAndRook(isWhite.b,piece.s)

  Protected Xpiece.b, i.b, fromsq1.b

  For i = 1 To 4
    Select piece
      Case "B"
        If isWhite
          XPiece = Wbishop
        Else
          XPiece = Bbishop
        EndIf
        fromsq1 = toSquareMailbox + Bishop_dirs(i)
        ;PrintN(" fromsq1 = " + Str(fromsq1))
        ;PrintN(" bishop_dirs(i) = " + Str(Bishop_dirs(i)))
      Case "R"
        If isWhite
          XPiece = Wrook
        Else
          XPiece = Brook
        EndIf
        fromsq1 = toSquareMailbox + Rook_dirs(i)
        ;PrintN(" rook_dirs(i) = " + Str(Rook_dirs(i)))
    EndSelect

    If MbxBrd(fromsq1) = Xpiece
      If disambiguator_sq_list <> "" 
        If FindString(disambiguator_sq_list,Str(fromsq1),1) > 0
          CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
            PrintN("...in If MbxBrd...fromsq1 = " + Str(fromsq1) + "...xpiece = " + Str(xpiece) + "...disam_sq_list = " + disambiguator_sq_list)
          CompilerEndIf
          SavePossibleMoveMailBoxSquare(fromSq1.b)
          Break
        Else
          Continue
        EndIf
      Else
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN("...in If MbxBrd...fromsq1 = " + Str(fromsq1) + "...xpiece = " +Str(xpiece))
        CompilerEndIf
        SavePossibleMoveMailBoxSquare(fromSq1.b)
        Break
      EndIf
    Else
      While BoardSqIsEmptyMailbox(fromsq1)
        If Piece = "B"
          fromsq1 = fromsq1 + Bishop_dirs(i)
        EndIf
        If Piece = "R"
         fromsq1 = fromsq1 + Rook_dirs(i)
        EndIf
      Wend
      If MbxBrd(fromsq1) = Xpiece
        If disambiguator_sq_list <> "" 
          If FindString(disambiguator_sq_list,Str(fromsq1),1) > 0
            CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
              PrintN("...in If MbxBrd...fromsq1 = " + Str(fromsq1) + "...xpiece = " + Str(xpiece) + "...disam_sq_list = " + disambiguator_sq_list)
            CompilerEndIf
            SavePossibleMoveMailBoxSquare(fromSq1.b)
            Break
          Else
            Continue
          EndIf
        Else
          CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
            PrintN("...in If MbxBrd...fromsq1 = " + Str(fromsq1) + "...xpiece = " +Str(xpiece))
          CompilerEndIf
          SavePossibleMoveMailBoxSquare(fromSq1.b)
          Break
        EndIf
      EndIf
    EndIf
  Next

EndProcedure



Procedure LegalMovesQueen(isWhite.b,piece.s)

  Protected Xpiece.b, i.b, fromsq1.b

  For i = 1 To 8
    If isWhite
      XPiece = Wqueen
    Else
      XPiece = Bqueen
    EndIf
    fromsq1 = toSquareMailbox + queen_dirs(i)
    ;PrintN(" queen_dir(i) = " + Str(queen_dirs(i)))

    If MbxBrd(fromsq1) = Xpiece                                                 ; ran into the queen, save square
      SavePossibleMoveMailBoxSquare(fromSq1.b)
      Break
    Else
      While BoardSqIsEmptyMailbox(fromsq1)                                      ; loop thru empty squares
        fromsq1 = fromsq1 + queen_dirs(i)
      Wend
      If MbxBrd(fromsq1) = Xpiece                                               ; ran into our queen after empty squares, save square
        SavePossibleMoveMailBoxSquare(fromSq1.b)
        Break
      Else
        Continue                                                                   ; ran into another piece (ours or ememys), not our queen so go next direction
      EndIf      
    EndIf
  Next

EndProcedure


Procedure MailboxMouseXY(xcoordm.i,ycoordm.i)

  Protected i.i, mailbox_row.b, mailbox_file.b

  mailbox_row = 0 : mailbox_file = 0
  For i = 0 To 7
    If SquareSize = 60
      If ycoordm >= 500 + (60*i) And ycoordm <= 500 + (i+1)*60
        mailbox_row = (i+2)*10
      EndIf
      If xcoordm >= 135 + (60*i) And xcoordm <= 135 + (i+1)*60
        mailbox_file = i + 1
      EndIf
    Else
      If ycoordm >= 500 + (40*i) And ycoordm <= 500 + (i+1)*40
        mailbox_row = (i+2)*10
      EndIf
      If xcoordm >= 115 + (40*i) And xcoordm <= 115 + (i+1)*40
        mailbox_file = i + 1
      EndIf
      ;PrintN("ycoord = " + Str(ycoordm) + "  xcoord = " + Str(xcoordm))
    EndIf
    
    If mailbox_row > 0 And mailbox_file > 0
      mailbox_editor_squareXY = mailbox_row + mailbox_file
      PrintN("MBXxy: You Clicked mailbox square = " + Str(mailbox_editor_squareXY))
    Break
    EndIf
  Next ; i

EndProcedure


Procedure MakeUCIMoveViaBrdUpd(fromSquareMailbox.b,toSquareMailbox.b,uci.s, isWhite.b)

  Protected moving_piece.b

  If (uci = "e1-g1" And MbxBrd(95) = Wking) Or (uci = "e1-c1" And MbxBrd(95) = Wking)
    If uci = "e1-g1"
      fromSquareMailBox = 95 : toSquareMailbox = 97
      MbxBrd(96) = Wrook : MbxBrd(98) = _emptySq        ; rook part of castling move
    EndIf
    If uci = "e1-c1"
      fromSquareMailBox = 95 : toSquareMailbox = 93
      MbxBrd(94) = Wrook : MbxBrd(91) = _emptySq        ; rook part of castling move
    EndIf
  EndIf

  If (uci = "e8-g8" And MbxBrd(25) = Bking) Or (uci = "e8-c8" And MbxBrd(25) = Bking)
    If uci = "e8-g8"
      fromSquareMailBox = 25 : toSquareMailbox = 27
      MbxBrd(26) = Brook : MbxBrd(28) = _emptySq        ; rook part of castling move
    EndIf
    If uci = "e8-c8"
      fromSquareMailBox = 25 : toSquareMailbox = 23
      MbxBrd(24) = Brook : MbxBrd(21) = _emptySq        ; rook part of castling move
    EndIf
  EndIf

  ; update board position with regular uci move or king position if castling move
  moving_piece = MbxBrd(fromSquareMailbox)
  MbxBrd(fromSquareMailbox) = _emptysq
  MbxBrd(toSquareMailbox) = moving_piece
  
  If FindString("QRBN",Mid(Uci,6,1)) > 0 And (FindString(BPawnQueenSqs,Str(toSquareMailbox),1) > 0 Or FindString(WPawnQueenSqs,Str(toSquareMailbox),1) > 0)
    Select Mid(Uci,6,1)
      Case "Q"
        MbxBrd(toSquareMailbox) = Bqueen + Colorflip(moving_Piece)
      Case "N"
        MbxBrd(toSquareMailbox) = Bknight+ Colorflip(moving_Piece)
      Case "B"
        MbxBrd(toSquareMailbox) = Bbishop+ Colorflip(moving_Piece)
      Case "R"
        MbxBrd(toSquareMailbox) = Brook+ Colorflip(moving_Piece)
    EndSelect
  EndIf
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("Proc MakeUCIMove:...moving piece = " + Str(moving_piece) + "  ...fromsquare = " + Str(fromSquareMailbox) + "...tosquare = " + Str(toSquareMailbox))
    PrintN("SANtoUCI_SingleMove: UCI move = " + uci)
    ;PrintAsciiBoard()
  CompilerEndIf

EndProcedure



Procedure NextMove()
  
  Protected LinesToScroll.i
  
    UCI_move_str = ""
    UCI_move_str = Trim(GameScore_UCI_HalfMoves(HalfMoveCount),Space(1))
    SetMoveColumn()
    If Fen_setup_Flag(Val(GameLink)) = 0 
      Convert_UCI_Notation()
      SetGadgetItemColor(#Move_ListIcon_Gadget, (HalfMoveCount-1)/2, #PB_Gadget_FrontColor, #Red,  MoveColumn)
    Else
      PrintN("NM: FEN_SideToMove = " + Str(FEN_SideToMove))
      PrintN("NM: HalfMoveCount = " + Str(HalfMoveCount))
      PrintN("NM: GameScore_UCI_HalfMoves(HalfMoveCount) = " + GameScore_UCI_HalfMoves(HalfMoveCount))
      Select FEN_SideToMove
        Case White_On_Move
          Convert_UCI_Notation()
          SetMoveColumn()
          SetGadgetItemColor(#Move_ListIcon_Gadget, (HalfMoveCount-1)/2, #PB_Gadget_FrontColor, #Red,  MoveColumn)
        Case Black_on_Move
          If FindString(Left(UCI_move_str,3),Dot_Sequence) <= 0
            Convert_UCI_Notation()
            SetMoveColumn()
            ;SetGadgetItemColor(#Move_ListIcon_Gadget, (HalfMoveCount-1)/2, #PB_Gadget_FrontColor, $ff0000ff,  MoveColumn)
            SetGadgetItemColor(#Move_ListIcon_Gadget, (HalfMoveCount-1)/2, #PB_Gadget_FrontColor, #Red,  MoveColumn)
          EndIf
      EndSelect
    EndIf
    
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      SetGadgetState(#Move_ListIcon_Gadget, HalfMoveCount/2)
    CompilerEndIf
    
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      LinesToScroll = GadgetHeight(#Move_ListIcon_Gadget)/28
      If HalfMoveCount/2 >= LinesToScroll
        If HalfMoveCount/2 <= (TotalHalfMoves/2 - LinesToScroll-1)
          If HalfMoveCount % 2
            ;CocoaMessage(WindowID(#mainwin), GadgetID(#Move_ListIcon_Gadget), "scrollRowToVisible:", HalfMoveCount/2 + 14)
          Else
            If HalfMoveCount % LinesToScroll = 0
              CocoaMessage(WindowID(#mainwin), GadgetID(#Move_ListIcon_Gadget), "scrollRowToVisible:", HalfMoveCount/2 + LinesToScroll-1)
              ;SetGadgetState(#Move_ListIcon_Gadget, HalfMoveCount/2)
            EndIf
          EndIf
        Else
          CocoaMessage(WindowID(#mainwin), GadgetID(#Move_ListIcon_Gadget), "scrollRowToVisible:", HalfMoveCount/2)
        EndIf
      EndIf
    CompilerEndIf
    
    If UCI_move_str <> "done"
      
      BoardDisplay()
      If HalfMoveCount % 2
        SetGadgetText(#Single_Move_Gadget, Str(HalfMoveCount/2 + 1) +". " + UCI_move_str)
      Else
        SetGadgetText(#Single_Move_Gadget, Str(HalfMoveCount/2) + " ... " + UCI_move_str)
      EndIf
      
      HalfMoveCount = HalfMoveCount + 1
      
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN("")
        PrintN("Proc NM - HalfMoveCount = " + Str(HalfMoveCount))
        PrintN("")
      CompilerEndIf
    Else
      BoardInitialize()
      BoardDisplay()
    EndIf
    
  EndProcedure

  
  Procedure.s ParseAndCleanPGN(PGNDirtyGameScore.s)
    
    Protected ResultPGN.s = "" , FileID.i, Line.s, CleanedLine.s, Char.s
    Protected CurrentChar.i, startpos.i, searchpos.i
    Protected i.i, j.i
    Protected InTagPair.b = #False
    Protected InComment.b = #False
    Protected InVariation.b = #False
    Protected InString.b = #False 
    Protected InLineComment.b = #False ; For comments starting with ';'
    Protected CommentDepth.i = 0, VariationDepth.i = 0
    Protected LastCharWasSpace.b = #True ; To collapse multiple spaces
    
    ; do a bit of preprocessing
    For j = 150 To 1 Step -1
      PGNDirtyGameScore = ReplaceString(PGNDirtyGameScore,"$"+Str(j)," ")   ; remove mal-formed NAGs (with no space after the $)
    Next
    
    InString = #False ;                     For tag pair values like [Event "Blah Tournament (2025)"]
    startpos = 1
    While startpos < Len(PGNDirtyGameScore)
      searchpos = startpos + Len(PGNDirtyGameScore)
            ;PrintN("searchpos = " + Str(searchpos))
            Line =  Mid(PGNDirtyGameScore,startpos,searchpos-startpos); mostly grabbing entire PGN game
            startpos = searchpos + 1
            CleanedLine = ""
            InLineComment = #False ; Reset for each new line

            For i = 1 To Len(Line)
                Char = Mid(Line, i, 1)
                CurrentChar = Asc(Char)

                If InLineComment
                    ; Skip until end of line
                    Continue
                EndIf

                Select CurrentChar
                    Case Asc("[")
                        If Not InComment And Not InVariation And Not InString
                            InTagPair = #True
                        Else
                            ; If inside a comment, variation, or string, treat as literal character
                            CleanedLine = CleanedLine + char
                            LastCharWasSpace = #False
                        EndIf

                    Case Asc("]")
                        If InTagPair
                            InTagPair = #False
                            InString = #False ; Ensure string mode is reset after a tag pair
                            If Not LastCharWasSpace
                                CleanedLine + " " ; Add a space after a tag pair
                                LastCharWasSpace = #True
                            EndIf
                        ElseIf Not InComment And Not InVariation
                            ; If not in tag pair but ']' is found, treat as literal (might be malformed PGN)
                            CleanedLine = CleanedLine + char
                            LastCharWasSpace = #False
                        EndIf

                    Case Asc("{")
                        If Not InTagPair And Not InString
                            InComment = #True
                            CommentDepth = CommentDepth + 1
                        Else
                            ; If inside a tag pair or string, treat as literal
                            CleanedLine = CleanedLine + char
                            LastCharWasSpace = #False
                        EndIf

                    Case Asc("}")
                        If InComment
                            CommentDepth = CommentDepth - 1
                            If CommentDepth = 0
                                InComment = #False
                                If Not LastCharWasSpace
                                    CleanedLine + " " ; Add a space after a comment
                                    LastCharWasSpace = #True
                                EndIf
                            EndIf
                        ElseIf Not InTagPair And Not InVariation And Not InString
                            ; Malformed: '}' without preceding '{' in current context
                            CleanedLine = CleanedLine + char
                            LastCharWasSpace = #False
                        EndIf

                    Case Asc("(")
                        If Not InTagPair And Not InComment And Not InString
                            InVariation = #True
                            VariationDepth = VariationDepth + 1
                        Else
                            ; If inside a tag pair, comment, or string, treat as literal
                            CleanedLine = CleanedLine + char
                            LastCharWasSpace = #False
                        EndIf

                    Case Asc(")")
                        If InVariation
                            VariationDepth = VariationDepth - 1
                            If VariationDepth = 0
                                InVariation = #False
                                If Not LastCharWasSpace
                                    CleanedLine + " " ; Add a space after a variation
                                    LastCharWasSpace = #True
                                EndIf
                            EndIf
                        ElseIf Not InTagPair And Not InComment And Not InString
                            ; Malformed: ')' without preceding '(' in current context
                            CleanedLine = CleanedLine + char
                            LastCharWasSpace = #False
                        EndIf

                    Case Asc(";")
                        If Not InTagPair And Not InComment And Not InVariation And Not InString
                            InLineComment = #True ; Start of a line comment, skip rest of line
                        Else
                            CleanedLine = CleanedLine + char
                            LastCharWasSpace = #False
                        EndIf

                    Case Asc(#DQUOTE$)
                      If InTagPair
                        If InString = #True     ; Toggle string mode within tag pair
                          InString = #False
                        Else
                          InString = #True
                        EndIf
                        Else
                            CleanedLine = CleanedLine + char
                            LastCharWasSpace = #False
                        EndIf

                    Case Asc("$") ; Numeric Annotation Glyph (NAG)
                        If Not InTagPair And Not InComment And Not InVariation And Not InString And Not InLineComment
                            ; Skip digits after '$'
                            Dim FoundNAG.s(0)
                            Protected k.i
                            k = i + 1
                            ;While k <= Len(Line) And IsDigit(Mid(Line, k, 1))
                            While k <= Len(Line) And FindString("0123456789",Mid(Line, k, 1)) > 0
                                k = k + 1
                            Wend
                            i = k - 1 ; Adjust loop counter
                            ; No need to add space here as NAGs are typically followed by space or move.
                        Else
                            CleanedLine = CleanedLine + char
                            LastCharWasSpace = #False
                        EndIf

                    Default
                        If Not InTagPair And Not InComment And Not InVariation And Not InString And Not InLineComment
                            If CurrentChar = Asc(" ") Or CurrentChar = 9 ; Space or Tab
                                If Not LastCharWasSpace
                                    CleanedLine = CleanedLine + " "
                                    LastCharWasSpace = #True
                                EndIf
                            Else
                                CleanedLine = CleanedLine + char
                                LastCharWasSpace = #False
                            EndIf
                        EndIf
                EndSelect
            Next i

            ResultPGN = ResultPGN + CleanedLine + " " ; Add a space after each processed line
            PrintN("ResultPGN = " + ResultPGN)
        Wend


    ; Final cleanup:
    ; 1. Remove leading/trailing spaces.
    ; 2. Collapse multiple spaces that might have accumulated.
    ; 3 junk cleanup (strays)
    ;For j = 1 To 7
       ;ResultPGN = ReplaceString(ResultPGN,Mid("[](){};",j,1),"")
    ;Next
    
    ResultPGN = Trim(ResultPGN)
    For j = 1 To 3
      ResultPGN = ReplaceString(ResultPGN, "  ", " ", #PB_String_NoCase) ; Collapse double spaces (repeat a few times for safety)
    Next


    ProcedureReturn ResultPGN
EndProcedure
  

Procedure Parse_Save_GameScore_Bare_Halfmoves(GameScore.s)
  
  ; This procedure takes an entire gamescore movelist string (SAN or UCI) and stores it bare halfmove-by-halfmove into
  ; string array GameScore_Plain_HalfMoves(HalfMoveCount) and then populates the moves gadget.. The halfmove array is then converted later
  ; into UCI (if necessary) for board display or converted into mailbox array squares for game-state manipulation.
  
  ; This procedures calls: BoardInitialize(), ConstructPositionfromFEN(), MakeUCIMoveViaBrdUpd(), 
  ; RemoveNumberDotSequenceSpecialNotations(), SANtoUCI_SingleMove(), SpacifyNoSpaceGamescoreLine()
  
  
  Protected i.i, Saved_Space_Offset.i, HalfMoveCount.i, Next_HalfMove_Offset.i
  Protected HalfMove.s, isWhite.b
  Protected Search_Result.i, Result_pos.i, j.i, R1.i, R2.i, R3.i, R4.i
  Protected Gamescore_Already_UCI_Flag.b

  ;PrintN("")

  Game_Result = "" : HalfMoveCount = 1 : i = 1 : TotalHalfMoves = 1 : Saved_Space_Offset = 1

  GameScore_MoveList = Space(1) + Trim(GameScore,Space(1))
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("Parse_Save_GameScore: Gamescore_MoveList = " + GameScore_MoveList)
  CompilerEndIf
  
  If FindString(Left(GameScore_MoveList,20),"-") <= 0 
    RemoveNumberDotSequenceSpecialNotations(GameScore_Movelist)         ; only call these two routines for SAN gamescores
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      PrintN("") : PrintN("GameScore_Movelist reduced in Parse_Save = " + GameScore_MoveList) : PrintN("")
    CompilerEndIf
    SpacifyNoSpaceGamescoreLine(GameScore_MoveList)
  EndIf
  
  Search_Result = 0
  Result_pos = 0
  For j = 1 To 4
    Search_Result = FindString(GameScore_MoveList,Trim(GameResult_Tags(j),Space(1)),1)
    If  Search_Result > 0
      Game_Result = Trim(GameResult_Tags(j), Space(1))
      Result_pos = Search_Result
    EndIf
  Next
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("")
    PrintN("Game_Result = " + Game_Result)
  CompilerEndIf

  ;PrintN("R1 = " + Str(R1) + "  R2 = " + Str(R2) + "  R3 = " + Str(R3) + "  R4 = " + Str(R4))
  ;PrintN("")

  If FEN_setup_flag(Val(GameLink)) = 0 
    SetGadgetText(#Single_Move_Gadget, " no moves yet")
    BoardInitialize()
  Else
    SetGadgetText(#Single_Move_Gadget, " FEN position")
    ConstructPositionfromFEN(FEN_setup_str(Val(GameLink)))
  EndIf

While Saved_Space_Offset <> Result_pos - 1
  
  ;PrintN("... in While loop...")
  If HalfMoveCount % 2
    Saved_Space_Offset = FindString(GameScore_MoveList," ",Saved_Space_Offset)
    Saved_Space_Offset = FindString(GameScore_MoveList,". ",Saved_Space_Offset+1) ;skip over move number
    Next_HalfMove_Offset = FindString(GameScore_MoveList,Space(1),Saved_Space_Offset + 2)  
    HalfMove = Mid(GameScore_MoveList,Saved_Space_Offset+1, Next_Halfmove_Offset - Saved_Space_Offset -1)
    Saved_Space_Offset = Next_HalfMove_Offset
  Else
    Saved_Space_Offset = FindString(GameScore_MoveList,Space(1),Saved_Space_Offset)
    Next_HalfMove_Offset = FindString(GameScore_MoveList,Space(1),Saved_Space_Offset + 1)  
    HalfMove = Mid(GameScore_MoveList,Saved_Space_Offset+1, Next_Halfmove_Offset - Saved_Space_Offset -1)
    Saved_Space_Offset = Next_HalfMove_Offset
  EndIf
  GameScore_Plain_HalfMoves(HalfMoveCount) = HalfMove

  HalfMove = Trim(HalfMove,Space(1))
  Gamescore_Already_UCI_Flag = 0
  fromSquareMailbox = -1 : toSquareMailbox = -1
  If HalfMoveCount % 2 = 0
    If FindString(GameResult_SearchMask,HalfMove,1) <= 0
      If HalfMove <> "O-O" And Left(HalfMove,5) <> "O-O-O"
        Gamescore_Already_UCI_Flag = FindString(HalfMove,"-",1)
      Else
        Gamescore_Already_UCI_Flag = 0
        EndIf
      If Gamescore_Already_UCI_Flag <= 0
        If FindString(Left(HalfMove,3),Dot_Sequence) <= 0
          SANtoUCI_SingleMove(HalfMove, #False)
          MakeUCIMoveViaBrdUpd(fromSquareMailbox.b,toSquareMailbox.b,uci.s, isWhite.b)
        EndIf
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN("...Uci move is: " + Uci) : PrintN("")
        CompilerEndIf
      EndIf
    Else
      Uci = HalfMove
    EndIf
  Else
    If FindString(GameResult_SearchMask,HalfMove,1) <= 0
      If HalfMove <> "O-O" And Left(HalfMove,5) <> "O-O-O"
        Gamescore_Already_UCI_Flag = FindString(HalfMove,"-",1)
      Else
        Gamescore_Already_UCI_Flag = 0
        EndIf
        If Gamescore_Already_UCI_Flag <= 0
          If FindString(Left(HalfMove,3),Dot_Sequence) <= 0
            SANtoUCI_SingleMove(HalfMove, #True)
            MakeUCIMoveViaBrdUpd(fromSquareMailbox.b,toSquareMailbox.b,uci.s, isWhite.b)
          EndIf
          CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
            PrintN("...Uci move is: " + Uci) : PrintN("")
          CompilerEndIf
      EndIf
    Else
      Uci = HalfMove
    EndIf
  EndIf
  
  If FindString(Left(HalfMove,3),Dot_Sequence) > 0
    GameScore_UCI_HalfMoves(1) = HalfMove
  Else
    If Gamescore_Already_UCI_Flag <= 0
     GameScore_UCI_HalfMoves(HalfMoveCount) = Uci
    Else
     GameScore_UCI_HalfMoves(HalfMoveCount) = HalfMove
    EndIf
  EndIf
  ;PrintN("")
  ;PrintN("HalfMoveCount = " + Str(HalfMoveCount) + "  HalfMove = " + GameScore_UCI_HalfMoves(HalfMoveCount))
  TotalHalfMoves = HalfMoveCount
  HalfMoveCount = HalfMoveCount + 1
  
Wend

  TotalHalfMoves = HalfMoveCount
  GameScore_UCI_HalfMoves(HalfMoveCount) = Game_Result
  GameScore_Plain_HalfMoves(HalfMoveCount) = Game_Result
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("") : PrintN("GameScore_UCI_HalfMoves(HalfMoveCount) = " + GameScore_UCI_HalfMoves(HalfMoveCount)) : PrintN("") : PrintN("TotalHalfMoves = " + Str(TotalHalfMoves))

    PrintN("GameScore_Plain_HalfMoves(HalfMoveCount) = ")
    PrintN("") : For i = 1 To TotalHalfMoves : Print(GameScore_Plain_HalfMoves(i) + Space(1)) : Next : PrintN("")

    PrintN("GameScore_UCI_HalfMoves(HalfMoveCount) = ")
    PrintN("") : For i = 1 To TotalHalfMoves : Print(GameScore_UCI_HalfMoves(i) + Space(1)) : Next : PrintN("")
  CompilerEndIf

EndProcedure



Procedure PieceIsBlack(Xpiece.b)

  Protected i.b

  For i = 1 To 6
    If Xpiece = i
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False

EndProcedure


Procedure PieceIsWhite(Xpiece.b)

  Protected i.b

  For i = 7 To 12
    If Xpiece = i
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False

EndProcedure


Procedure PlayEngine()
  
  Protected i.i, Demographic_Info.s, Position_Info.s, Save_Text.s, WhitePlayer.s, BlackPlayer.s, Info_Result.s, Info_Description.s, GameLink.s
  Protected Space1_pos.b, Space2_pos.b, Move_Sequence.s, Start_Info.s
  Protected piece_sqr_list.s, piece_square.s, piece.s, asquare.s, piece_list.s, all_mbxsquares.s
  Protected mbx_square.b, mbx_piece.b, STF_flag.b, departure_sq.b, arrival_sq.b
  Protected xc.i, yc.i, Event.i, currentEvent.i, type.i
  
  
    SetGadgetText(#Info_Field, "...Now in point-and-click GUI play vs engine mode...You are White...click on piece at LEFT, then click on destination square to place, you can cheat, move multiple pieces! After engine moves, click [PlayVsEngine] for each subsequent move...click [Exit] to exit")
    
    QuickEngine_Flag = #True
    PlayEngineEditCount = 0 : PlayEngineFENstr = ""
    BoardEditorDisplay()
    BindEvent(#PB_Event_SizeWindow, @SizeHandlerFENEditorButtons())
    
    Counter = 0
    arrival_sq = 0 : departure_sq = 0
    Repeat
      Event = WaitWindowEvent(1)
      If Event = #PB_Event_Gadget
        SelectPieceButton()
      Else
        ; do nothing for now
      EndIf
      
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    
        currentEvent = CocoaMessage(0, sharedApplication, "currentEvent")
        If currentEvent
          type = CocoaMessage(0, currentEvent, "type")
          Select type
            Case #NSLeftMouseUp
              clickCount = CocoaMessage(0, currentEvent, "clickCount")
              PrintN("Left mouse " + Str(clickCount) + "x clicked"); kp
              CocoaMessage(@location, currentEvent, "locationInWindow")
              mailbox_editor_squareXY = 0       
              xc = location\x : yc = WindowHeight(#mainwin)-location\y
              ;xc = location\x : yc = #mainwinDefaultHeight-location\y
              MailboxMouseXY(xc.i,yc.i)
              ;PrintN("Mouse moved to (" + StrF(location\x, 1) + "," + StrF(WindowHeight(AppWindow)-location\y, 1) + ")"); use WindowHeight() to flip y coordinate
              PrintN("You clicked in mailbox square = " + Str(mailbox_editor_squareXY))
              If mailbox_editor_squareXY >= 21 And mailbox_editor_squareXY <= 98
                PrintN("EmptySq_Button_Flag = " + Str(EmptySq_Button_Flag))
                If EmptySq_Button_Flag = 1
                  departure_sq = mailbox_editor_squareXY
                  PlayEngineEditCount = PlayEngineEditCount + 1
                  EmptySq_Button_Flag = 0
                Else
                  arrival_sq = mailbox_editor_squareXY
                  PlayEngineEditCount = PlayEngineEditCount + 1
                EndIf
                MbxBrd(mailbox_editor_squareXY) = Mailbox_editor_piece
                BoardDisplay() ;: FreeBoardEditorGadgets() : BoardEditorDisplay()
              EndIf
            Case #NSMouseMoved
              CocoaMessage(@location, currentEvent, "locationInWindow")
              ;PrintN("Mouse moved to (" + StrF(location\x, 1) + "," + StrF(WindowHeight(AppWindow)-location\y, 1) + ")"); use WindowHeight() to flip y coordinate
              If location\x >= 135 And location\x <= 195 And #mainwinDefaultHeight-location\y >= 500 And #mainwinDefaultHeight-location\y <= 560
                ;PrintN("You are in mailbox square 21")
              EndIf
          EndSelect
        EndIf
        
      CompilerEndIf
      
    Until Counter >= 99
  
  FreeBoardEditorGadgets()
  
  pvstring(1) = ""
  HalfMoveCount = HalfMoveCount + 1
  TotalHalfMoves = TotalHalfMoves + 1
  GameScore_Plain_HalfMoves(HalfMoveCount) = Mid(AlgSquares,departure_sq*2+1,2) + "-" + Mid(AlgSquares,arrival_sq*2+1,2)
  GameScore_UCI_HalfMoves(HalfMoveCount) = GameScore_Plain_HalfMoves(HalfMoveCount)
  ConstructFENfromPosition()
  Game_FEN_Positions(HalfMoveCount) = FENpositionstr
  If PlayEngineEditCount > 4
    If Mailbox_editor_piece <> Wking And Mailbox_editor_piece <> Wrook
    PlayEngineFENstr = FENpositionstr
    GameScore_Plain_HalfMoves(HalfMoveCount) = "[FEN]"
    PrintN("PlayEng: PlayEngineEditCount = " + Str(PlayEngineEditCount) + "  PlayEngineFENstr = " + PlayEngineFENstr)
    EndIf
  EndIf
  PopulateMovesGadget()
  
  SetGadgetText(#Info_Field, "")
  ConstructFENfromPosition()
  SetGadgetText(#Info_Field, FENpositionstr)
  
  pvstring(1) = "" : pvstring(2) = "" : cpscore_str(1) = "" : cpscore_str(2) = ""
  SF_Time_Per_Move = 1000
  ;PrintN("HalfMoveCount = " + Str(HalfMoveCount-1) + " FEN = " + Game_FEN_Positions(HalfMoveCount))
  
  SetGadgetText(#Info_Field, "...Stockfish...analyzing...")
  SF_fenposition = FENPositionstr
  CreateThread(@Stockfish_FEN_Analysis_Thread(),1)  ; calling Stockfish seems to work best in threaded mode
  While pvstring(1) = ""
    Delay(500)
    ;PrintN("500 ms delay")
  Wend
  HalfMoveCount = HalfMoveCount + 1
  TotalHalfMoves = TotalHalfMoves + 1
  GameScore_UCI_HalfMoves(HalfMoveCount) = Left(pvstring(1),2) + "-" + Mid(pvstring(1),3,2)
  GameScore_Plain_HalfMoves(HalfMoveCount) = GameScore_UCI_HalfMoves(HalfMoveCount)
  ;PrintN("xx"+ GameScore_UCI_HalfMoves(HalfMoveCount) + "xx")
  Convert_UCI_Notation()
  BoardDisPlay()
  ConstructFENfromPosition()
  Game_FEN_Positions(HalfMoveCount) = FENpositionstr
  PopulateMovesGadget()
  GameInfo = "Casual player versus engine game"

  UnbindEvent(#PB_Event_SizeWindow, @SizeHandlerFENEditorButtons()) ; Unbind it immediatel
  QuickEngine_Flag = #False
  
  
EndProcedure


Procedure Player_Search()

  Protected i, player_result1.i, player_result2.i
  ReDim Gadget_List_Display.s(GameCount-1)
  
  player_result1 = 0 : player_result2 = 0
  Search_player = InputRequester("Search for player name", "Please enter full or partial player name to search, asterisk (*) for all, *sort to sort: ", "Carlsen")
  ClearGadgetItems(#Players_ListIcon_Gadget)
  If Search_player = "*"
    For i = 1 To GameCount-1
      SetupGameLinkForSearchSort(i)
      AddGadgetItem(#Players_ListIcon_Gadget, -1, Trim(Left(WhitePlayers(i), G1_pos-1), " ") + "[" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + "[" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i) + Chr(10) + GameLink)
    Next
  ElseIf  Search_player = "*sort"
    For i = 1 To GameCount-1
      SetupGameLinkForSearchSort(i)
      Gadget_List_Display(i) = Trim(Left(WhitePlayers(i), G1_pos-1), " ") + "[" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + "[" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i) + Chr(10) + GameLink
      PrintN("List row = " + Gadget_List_Display(i))
    Next
    SortArray(Gadget_List_Display(),#PB_Sort_Ascending)
    PrintN("")
    For i = 1 To GameCount-1
        PrintN("List row = " + Gadget_List_Display(i))
        AddGadgetItem(#Players_ListIcon_Gadget, -1, Gadget_List_Display(i))
    Next
  Else
    For i = 1 To GameCount-1
      player_result1 = FindString(WhitePlayers(i), Search_player, 1)
      player_result2 = FindString(BlackPlayers(i), Search_player, 1)
      If player_result1 > 0 Or player_result2 > 0
        Display_flag(i) = 1
        PrintN("...found a player match...")
      Else
        Display_flag(i) = 0
      EndIf

      If Display_Flag(i) = 1
        SetupGameLinkForSearchSort(i)
        AddGadgetItem(#Players_ListIcon_Gadget, -1, Trim(Left(WhitePlayers(i), G1_pos-1), " ") + "[" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + "[" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i) + Chr(10) + GameLink)
      EndIf
    Next
  EndIf
  BoardInitialize()
  BoardDisplay()
  SetGadgetText(#Single_Move_Gadget, " ")
  SetGadgetText(#Info_Field, "db = " + DB_InputFile + #CRLF$ + #CRLF$ +  "...Select a game above left...")

EndProcedure



Procedure PopulateMovesGadget()
  
  Protected i.i, Move_Line_Text.s
  
  ;SetGadgetText(#Move_ListIcon_Gadget, "")
  ClearGadgetItems(#Move_ListIcon_Gadget)
  
  For i = 1 To TotalHalfMoves Step 2
    ;Move_Line_Text = Space(1) + Str(i/2+1) + "." + Space(1) + GameScore_UCI_HalfMoves(i)  
    Move_Line_Text = Space(1) + Str(i/2+1) + "." + Space(1) + GameScore_Plain_HalfMoves(i) 
    If FindString(GameResult_SearchMask,GameScore_UCI_HalfMoves(i)) <= 0
      ;Move_Line_Text = Move_Line_Text + Chr(10) + Space(1) + GameScore_UCI_HalfMoves(i+1)
      Move_Line_Text = Move_Line_Text + Chr(10) + Space(1) + GameScore_Plain_HalfMoves(i+1)
    EndIf
    AddGadgetItem(#Move_ListIcon_Gadget, -1, Move_Line_Text)
  Next
  
  
EndProcedure


Procedure PreviousMove()
  
    ; This reversing in the movelist is very tricky!
    
    HalfMoveCount = HalfMoveCount - 1
    If HalfMoveCount = 2 And FindString(Dot_Sequence,Left(GameScore_UCI_HalfMoves(HalfMoveCount-1),3)) > 0
      HalfMoveCount = 1                                                                 ; grundgy patch for ... display purposes
      SetGadgetItemColor(#Move_ListIcon_Gadget, (HalfMoveCount-1)/2, #PB_Gadget_FrontColor, #PB_Default, 1)
    EndIf
    
    PrintN("PM - HalfMoveCount = " + Str(HalfMoveCount))
    
    Select HalfmoveCount
      Case -1, 0, 1
        ;SetGadgetText(#Move_ListIcon_Gadget, GameScore_MoveList)
        HalfMoveCount = 1
        If FEN_setup_Flag(Val(GameLink)) = 0       ; normal game from start
          ConstructPositionfromFEN(FEN_Start_Position)
          SetGadgetText(#Single_Move_Gadget, " no moves yet")
          BoardInitialize()
        Else
          ConstructPositionfromFEN(FEN_setup_str(Val(GameLink)))
          SetGadgetText(#Single_Move_Gadget, " FEN position")
        EndIf
        SetGadgetItemColor(#Move_ListIcon_Gadget, (HalfMoveCount-1)/2, #PB_Gadget_FrontColor, #PB_Default, 0)
        BoardDisplay()
      Case 2 To 2000
        UCI_move_str = GameScore_UCI_HalfMoves(HalfMoveCount-1)
        ;SetGadgetText(#Move_ListIcon_Gadget, GameScore_MoveList)
        SetMoveColumn()
        SetGadgetItemColor(#Move_ListIcon_Gadget, (HalfMoveCount-1)/2, #PB_Gadget_FrontColor, #PB_Default, MoveColumn)
        ConstructPositionfromFEN(Game_FEN_Positions(HalfMoveCount-1))
        If HalfMoveCount % 2
          SetGadgetText(#Single_Move_Gadget, Str(HalfMoveCount/2) + " ... " + UCI_move_str)
        Else
          SetGadgetText(#Single_Move_Gadget, Str(HalfMoveCount/2) +". " + UCI_move_str)
        EndIf
        
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        If HalfMoveCount/2 >= 15
          If HalfMoveCount % 2
            ;CocoaMessage(WindowID(#mainwin), GadgetID(#Move_ListIcon_Gadget), "scrollRowToVisible:", HalfMoveCount/2 + 14)
          Else
            CocoaMessage(WindowID(#mainwin), GadgetID(#Move_ListIcon_Gadget), "scrollRowToVisible:", HalfMoveCount/2 - 15)
            ;SetGadgetState(#Move_ListIcon_Gadget, HalfMoveCount/2)
          EndIf
        EndIf
        CompilerEndIf
        
        BoardDisplay()
        PrintN("")  ; PrintN("Proc NM - HalfMoveCount = " + Str(HalfMoveCount)) : PrintN("")
      Default
        HalfMoveCount = 1
    EndSelect
    
EndProcedure
  

Procedure PrintAsciiBoard()

  Protected BoardLetters.s = "--BRBNBBBQBKBPWRWNWBWQWKWP"
  Protected rank.b, file.b

  For rank = 20 To 90 Step 10
    PrintN("")
    For file = 1 To 8
      Print(Mid(BoardLetters,MbxBrd(rank+file)*2+1,2) + Space(1))
    Next
  Next
  PrintN("") : PrintN("")

EndProcedure


Procedure ReadUCIResponse(ProgramID, timeout_ms = 100)
  Protected startTime = ElapsedMilliseconds()
  While AvailableProgramOutput(ProgramID)
    ;output = output + ReadProgramString(ProgramID)
    output = ReadProgramString(ProgramID)
  Wend
  Delay(timeout_ms) ; Give Stockfish a little time to respond more fully
  While AvailableProgramOutput(ProgramID)
    ;output = output + ReadProgramString(ProgramID)
    output = ReadProgramString(ProgramID)
  Wend
  ;ProcedureReturn output
EndProcedure




Procedure RemovePGNCommentsAndVariations2(line.s)

  Protected dollarsign_pos.b, spaceafterdollar_pos.b
  Protected opensymbol_pos.i, closesymbol_pos.i, i.b, j.i, opensymbol.s, closesymbol.s
  
  ;For j = 150 To 1 Step -1
    ;line = ReplaceString(line,"$"+Str(j)," ")   ; remove mal-formed NAGs (with no space after the $)
  ;Next

  opensymbol = "[{(" : closesymbol = "]})"
  For i = 1 To 3
    opensymbol_pos =  FindString(line,Mid(opensymbol,i,1),1)
    While opensymbol_pos > 0
      closesymbol_pos = FindString(line,Mid(closesymbol,i,1),1)
      If closesymbol_pos > 0
        line = Left(line,opensymbol_pos-1) + Mid(line,closesymbol_pos+1)
      Else
        Break 1
      EndIf
      opensymbol_pos =  FindString(line,Mid(opensymbol,i,1))
    Wend
  Next
  
  result = ""
  dollarsign_pos = FindString(line,DollarSign,1)
  If dollarsign_pos > 0
    spaceafterdollar_pos = FindString(line,Space(1),dollarsign_pos+1)
    If spaceafterdollar_pos > 0
      line = Left(line,dollarsign_pos-1) + Mid(line,spaceafterdollar_pos)
    Else
      line = Left(line,dollarsign_pos-1) + Mid(line,dollarsign_pos+1)
    EndIf
  EndIf
  
  ; junk cleanup (strays)
    For i = 1 To 7
       line = ReplaceString(Line,Mid("[](){};",i,1),"")
    Next
  
  
  result = Line
  While FindString(result,Space(2)) > 0
   result = ReplaceString(result,Space(2),Space(1))
 Wend
 
EndProcedure



Procedure RemoveNumberDotSequenceSpecialNotations(XGameScore_Movelist.s)
  
  ; this routine is for special "odd" pgns that look like 1. e4 {or Nf3 first} 1...e5 2. Nf3 {or e4 second} 2...Nc6 etc
  ; I have a bunch of those "odd" pgns and just wanted to be able to read them
  ; this routine is "post-processing" (as is SpacifyNoSpaceGamescoreLine() ) so they won't unnecessarily slow down reading the whole PGN file
  
  Protected i.i, tempnumber_str1.s, tempnumber_str2.s, BlackStartingTest.s
  
  If FindString(XGameScore_Movelist,Dot_Sequence) > 0
    For i = 100 To 2 Step -1
      tempnumber_str1 = Str(i) + Dot_Sequence
      If FindString(XGameScore_MoveList,tempnumber_str1) > 0
      XGameScore_Movelist = ReplaceString(XGameScore_Movelist,tempnumber_str1,"")
      ;GameScore_Movelist = ReplaceString(GameScore_Movelist,tempnumber_str2,"")
      EndIf
    Next
  EndIf

  tempnumber_str2 = "1" + Dot_Sequence
  BlackStartingTest = Trim(XGameScore_Movelist,Space(1))
  BlackStartingTest = Left(XGameScore_Movelist,4)
  BlackStartingTest = ReplaceString(BlackStartingTest,Space(1),"")
  
  If FindString(XGameScore_MoveList,tempnumber_str2) > 0 And Left(BlackStartingTest,3) <> "1.."
    XGameScore_MoveList = ReplaceString(XGameScore_MoveList,tempnumber_str2,"")
  EndIf
  
  While FindString(XGameScore_MoveList,Space(2)) > 0
   XGameScore_MoveList = ReplaceString(XGameScore_MoveList,Space(2),Space(1))
  Wend
  
  PrintN("") : PrintN("XGameScore_Movelist reduced = " + XGameScore_MoveList) : PrintN("")
  GameScore_MoveList = XGameScore_Movelist                                                  ; work-around for global string bug I do not understand??
  PrintN("") : PrintN("GameScore_Movelist reduced = " + GameScore_MoveList) : PrintN("")
    
EndProcedure


Procedure SelectPieceButton()
  
  ;EmptySq_Button_Flag = 0
  Select EventGadget()
    Case #Btn_br40
      Mailbox_editor_piece = Brook : PrintN("You Clicked: " + "Black rook")
    Case #Btn_bn40
      Mailbox_editor_piece = Bknight : PrintN("You Clicked: " + "Black knight")
    Case #Btn_bb40
      Mailbox_editor_piece = Bbishop : PrintN("You Clicked: " + "Black bishop")
    Case #Btn_bq40
      Mailbox_editor_piece = Bqueen : PrintN("You Clicked: " + "Black queen")
    Case #Btn_bk40
      Mailbox_editor_piece = Bking : PrintN("You Clicked: " + "Black king")
    Case #Btn_bp40
      Mailbox_editor_piece = Bpawn : PrintN("You Clicked: " + "Black pawn")
    Case #Btn_wr40
      Mailbox_editor_piece = Wrook : PrintN("You Clicked: " + "White rook")
    Case #Btn_wn40
      Mailbox_editor_piece = Wknight : PrintN("You Clicked: " + "White knight")
    Case #Btn_wb40
      Mailbox_editor_piece = Wbishop : PrintN("You Clicked: " + "White bishop")
    Case #Btn_wq40
      Mailbox_editor_piece = Wqueen : PrintN("You Clicked: " + "White queen")
    Case #Btn_wk40
      Mailbox_editor_piece = Wking : PrintN("You Clicked: " + "White king")
    Case #Btn_wp40
      Mailbox_editor_piece = Wpawn : PrintN("You Clicked: " + "White pawn")
    Case #Btn_es32
      Mailbox_editor_piece = _emptysq : PrintN("You Clicked: " + "Empty square")
      EmptySq_Button_Flag = 1
      PrintN("Select Proc: EmptySq_Button_Flag = " + Str(EmptySq_Button_Flag))
    Case #Btn_done40
      Counter = 99
    Default
            ; do nothing now
  EndSelect
  
EndProcedure


Procedure SizeHandler()
  
        ;Slide some gadgets according to new window size, shrink players and moves gadgets
  
        ResizeGadget(#Players_ListIcon_Gadget, #PB_Ignore, #PB_Ignore, #playgadgetwidth, WindowHeight(#mainwin) - 605) 
        ResizeGadget(#Move_ListIcon_Gadget, #PB_Ignore, #PB_Ignore, #movesgadgetwidth, WindowHeight(#mainwin) - 595)
        If SquareSize = 60
          ResizeGadget(#CanvasGadgetChessBoard, #PB_Ignore, (WindowHeight(#mainwin)-(#mainwinDefaultHeight-#canvas_gadgetY)),#PB_Ignore, #PB_Ignore)
        Else
          ResizeGadget(#CanvasGadgetChessBoard, #PB_Ignore, (WindowHeight(#mainwin)-(#mainwinDefaultHeight-(#canvas_gadgetY+100))),#PB_Ignore, #PB_Ignore)
        EndIf
        
        ResizeGadget(#DbFile_Gadget, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#fileinfogadgetDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_Fen, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#FENBtnDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_BoardSize, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#FENBtnDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_ExportGame, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#FENBtnDefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Single_Move_Gadget, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#Single_MoveDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Info_Field, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#InfoFieldDefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Btn_Prev, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#prevbtnDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_Next, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#nextbtnDefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Btn_Db1, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#dbbtn1DefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_Db2, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#dbbtn2DefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Btn_SFAnaly, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#sfbtnDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_SF10sec, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#sfbtn10secDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_UpdSF, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#dbbtn2DefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Btn_PlayvsSF, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#sfbtn10secDefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Btn_PSearch, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#PSearchbtnDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_FENEditor, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#FENEditbtnDefaultY), #PB_Ignore, #PB_Ignore)
        
      EndProcedure
      
      
      Procedure SizeHandlerFENEditorButtons()
        
        ResizeGadget(#Btn_done40, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#btndone40DefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Btn_br40, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#btnbr40DefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_bn40, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#btnbn40DefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_bb40, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#btnbb40DefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_bq40, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#btnbq40DefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_bk40, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#btnbk40DefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_bp40, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#btnbp40DefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Btn_wr40, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#btnwr40DefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_wn40, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#btnwn40DefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_wb40, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#btnwb40DefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_wq40, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#btnwq40DefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_wk40, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#btnwk40DefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_wp40, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#btnwp40DefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Btn_es32, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#btnes32DefaultY), #PB_Ignore, #PB_Ignore)
        
      EndProcedure


CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
Procedure SetTextColorABGR(EditorGadget, Color, StartPosition, Length = -1, BackColor = #NO)
  ; NOTE this procedure is MacOS specific
  Protected.CGFloat r,g,b,a
  Protected range.NSRange, textStorage.i
  If StartPosition > 0
    textStorage = CocoaMessage(0, GadgetID(EditorGadget), "textStorage")
    range\location = StartPosition - 1
    range\length = CocoaMessage(0, textStorage, "length") - range\location
    If range\length > 0
      If Length >= 0 And Length < range\length
        range\length = Length
      EndIf
      r = Red(Color) / 255
      g = Green(Color) / 255
      b = Blue(Color) / 255
      a = Alpha(Color) / 255
      Color = CocoaMessage(0, 0, "NSColor colorWithDeviceRed:@", @r, "green:@", @g, "blue:@", @b, "alpha:@", @a)
      If BackColor
        CocoaMessage(0, textStorage, "addAttribute:$", @"NSBackgroundColor", "value:", Color, "range:@", @range)
      Else
        CocoaMessage(0, textStorage, "addAttribute:$", @"NSColor", "value:", Color, "range:@", @range)
      EndIf
    EndIf
  EndIf
EndProcedure
CompilerEndIf


Procedure SANtoUCI_SingleMove(san.s, isWhite.b)
  
  ; This procedure translates a single SAN move to UCI format using the mailbox board state.
  ; It generally needs a legal move generation routine that works with the mailbox board.
  ; I am using a combination of pseudo-legal, piece-finders, and pinned-piece routines.
  
  ; This procedure calls: LegalMovesBishopAndRook(), LegalMovesKnightAndKing(), LegalMovesPawn(), LocateTheQueen(), LocateLightOrDarkSquareBishop()

  Protected fromFile.b, fromRank.b, toFile.b, toRank.b
  Protected promoequalsign_pos.b, promotion.s = ""

  Protected fromSquareIndex
  Protected i, file, rank
  Protected algSquare.s
  
  uci = ""
  possibleCount = 1

  ;Handle special moves (castling, promotion)

  If Left(san,3) = "O-O" And Left(san,5) <> "O-O-O" ; Kingside castling
    If isWhite
      uci = "e1-g1" : fromSquareMailBox = 95 : toSquareMailbox = 97
      ProcedureReturn
    Else
      uci = "e8-g8" : fromSquareMailBox = 25 : toSquareMailbox = 27
      ProcedureReturn
    EndIf
  ElseIf Mid(san,1,5) = "O-O-O" 
    If isWhite
      uci = "e1-c1" : fromSquareMailBox = 95 : toSquareMailbox = 93
      ProcedureReturn
    Else
      uci = "e8-c8" : fromSquareMailBox = 25 : toSquareMailbox = 23
      ProcedureReturn
    EndIf
  EndIf

  If FindString(Left(san,3),Dot_Sequence) > 0
    uci = Dot_Sequence
    ProcedureReturn
  EndIf

  promoequalsign_pos = FindString(san,"=",1)
  If promoequalsign_pos > 0
    promotion = Mid(san,promoequalsign_pos+1,1)
    san = Left(san,promoequalsign_pos-1)
  Else
    promotion = ""
  EndIf

  ; Extract potential piece type and target square, try to calculate from square
  
  If FindString("NBRQK",Left(san,1),1) <= 0    ; No piecetype, must be a bare pawn move, with capture or maybe with check or queening
    piece = "P"
    san = ReplaceString(san, "+", "")                                                             ; trim check symbol
    san = ReplaceString(san, "#", "")                                                             ; trim mate symbol
    LegalMovesPawn(san.s,isWhite.b,piece.s)
  Else                                                                                            ; piecetype is given, NOT a pawn move
    piece = Mid(san,1,1)
    san = ReplaceString(san, "+", "")                                                             ; trim check symbol
    san = ReplaceString(san, "#", "")
    disambiguator_symbol = ""
    disambiguator_sq_list = ""
    If (Len(san) >= 4 And FindString(AlgSquares,Mid(san,Len(san)-1,2),1) > 0)
      toSq_str = Mid(san,Len(san)-1,2)
      disambiguator_symbol = Mid(san,2,1)
      If disambiguator_symbol = "x"
        disambiguator_symbol = ""
      EndIf
      If FindString("abcdefgh",disambiguator_symbol,1) > 0
        disambiguator_sq_list = Mid(file_disambiguator,FindString(file_disambiguator,disambiguator_symbol,1)+1,24)
      EndIf
      If FindString("12345678",disambiguator_symbol,1) > 0
        disambiguator_sq_list = Mid(rank_disambiguator1,FindString(rank_disambiguator2,disambiguator_symbol,1)+3,24)
      EndIf
    Else
      toSq_str = Mid(san,2,2)
    EndIf
    
    toSquareMailbox = FindString(AlgSquares,toSq_str,1)/2
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      PrintN("SAN toSq_str = " + toSq_str + "  Piece = " + piece + " ...disambiguator symbol = " + disambiguator_symbol + "...disamb sqlist = " + disambiguator_sq_list)
      PrintN("to squareMailbox = " + Str(toSquareMailbox))
    CompilerEndIf
    
    If toSquareMailbox <= 0
      Debug "Invalid target square"
    EndIf

    Select Piece                                                                                          ; all non-pawn pieces
      Case "N"
        ;PrintN("calling knight and king routine")
        LegalMovesKnightAndKing(isWhite.b,piece.s)
      Case "B"
        ;PrintN("calling LLSDB bishop routine")
        ;LegalMovesBishopAndRook(isWhite.b,piece.s)
        LocateLightOrDarkSquareBishop(isWhite.b,toSquareMailbox.b)                                        ; new simpler, quicker bishop test
      Case "R"
        ;PrintN("calling rook and bishop routine")
        LegalMovesBishopAndRook(isWhite.b,piece.s)
      Case "Q"                                                                                            ; simpler queen check, only works with one queen
        ;PrintN("calling queen routine")
        LocateTheQueen(isWhite.b)
        ;If CountOfQueens > 1
        ;LegalMovesQueen(isWhite.b,piece.s)
        ;Else
        possibleCount = 1
        If isWhite
          possibleFromSquaresMailbox(1) = WhiteQueenCurrentSq
        Else
          possibleFromSquaresMailbox(1) = BlackQueenCurrentSq
        EndIf
        ;EndIf
      Case "K"
        ;PrintN("calling king and knight routine")
        LegalMovesKnightAndKing(isWhite.b,piece.s)
    EndSelect
  EndIf

  ; If there are multiple possible origin squares, the SAN should have disambiguated.

  If possibleCount = 1
    fromSquareMailbox = possibleFromSquaresMailbox(1)
  ElseIf possibleCount > 1
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      PrintN("...possiblecount > 1, ...possiblecount = " + Str(possiblecount))
    CompilerEndIf
    ; The SAN move should have included file or rank of origin.
    ; We've already filtered by those. If still multiple, it's ambiguous (shouldn't happen with valid SAN).
    ; We'll just take the first valid one found.
    fromSquareMailbox = possibleFromSquaresMailbox(1)
  EndIf

  ; 5. Construct the UCI move


    fromSq_str = Mid(AlgSquares,fromSquareMailbox*2+1,2)
    uci = fromSq_str + "-" + toSq_str
    If promotion <> ""
      uci = uci + promotion
    EndIf


EndProcedure



Procedure SetupGameLinkForSearchSort(Index.i)

  DisPlay_flag(Index) = 1
  G1_pos = FindString(WhitePlayers(Index), Game_Prefix, 1)
  G2_pos = FindString(BlackPlayers(Index), Game_Prefix, 1)
  GameLink = Game_Prefix + Mid(BlackPlayers(Index), G2_pos+2, 6)

EndProcedure



Procedure SavePossibleMoveMailboxSquare(XMailBoxSquare.b)

  possibleFromSquaresMailbox(possibleCount) = XMailBoxSquare
  possibleCount = possibleCount + 1

EndProcedure


Procedure SetMoveColumn()
  
  If HalfMoveCount % 2
    MoveColumn = 0
  Else
    MoveColumn = 1
  EndIf
  
EndProcedure



Procedure SpacifyNoSpaceGamescoreLine(line.s)
  
  Protected i.b, periodandSANsymbol.s, periodpandspaceplusSANsymbol.s

  If FindString(line, "1...", 1) > 0
    line = ReplaceString(line, "1...", "1. ...")
  EndIf

  For i = 1 To 14
    periodandSANsymbol = "." + Mid(ValidSANsymbols,i,1)
    If FindString(line,periodandSANsymbol,1) > 0
      periodpandspaceplusSANsymbol = "." + Space(1) + Mid(ValidSANsymbols,i,1)
      line = ReplaceString(line, periodandSANsymbol, periodpandspaceplusSANsymbol)
      ;PrintN("Spacified gameline = " + line)
    EndIf
  Next ; i
  
  GameScore_MoveList = Line
  
  PrintN("") : PrintN("GameScore_Movelist spacified = " + GameScore_MoveList) : PrintN("")
  
EndProcedure



Procedure SquareIsAttacked(Xsquare.b,isWhite.b)

  Protected SqCnt.b, A_Dir.b, ThePiece.b, TargetSq.b, The_Dir.b, TheSq.b

  TargetSq = Xsquare

  For The_Dir = 1 To 8                                                                       ; all slider direction attacks 
    For SqCnt = 1 To 7
      A_Dir = queen_dirs(The_Dir) * SqCnt
      TheSq = TargetSq + A_Dir
      If MbxBrd(TheSq) = #OffTheBoard
        Break
      Else
        ThePiece = MbxBrd(TheSq)
        If ThePiece <> _emptySq
          If isWhite             ; opposite piece colors
            If PieceIsWhite(ThePiece)                                                          ; own color White piece
              Break 
            EndIf
            If PieceIsBlack(ThePiece)
              Select The_Dir
                Case 1,2,3,4                                                                   ; diagonal directions
                  Select ThePiece
                    Case Bpawn,Bknight,Bking
                      ; pawn or knight or king do nothing, not diagonal or slider
                      Break
                    Case Bbishop,Bqueen
                      ProcedureReturn #True
                  EndSelect
                Case 5,6,7,8                                                                   ; rank and file directions
                  Select ThePiece
                    Case Bpawn,Bknight,Bking
                      ; pawn or knight or king do nothing, not rank and file or slider, cannot pin(attack)
                      Break
                    Case Brook,Bqueen
                      ProcedureReturn #True
                  EndSelect
              EndSelect
            EndIf
          Else
            If PieceIsBlack(ThePiece)                                                          ; own color Black piece
              Break 
            EndIf
            If PieceIsWhite(ThePiece)
              Select The_Dir
                Case 1,2,3,4                                                                   ; diagonal directions
                  Select ThePiece
                    Case Wpawn,Wknight,Wking
                      ; pawn or knight or king do nothing, not diagonal or slider
                      Break
                    Case Wbishop,Wqueen
                      ProcedureReturn #True
                  EndSelect
                Case 5,6,7,8                                                                   ; rank and file directions
                  Select ThePiece
                    Case Wpawn,Wknight,Wking
                      ; pawn or knight or king do nothing, not rank and file or slider, cannot pin(attack)
                      Break
                    Case Wrook,Wqueen
                      ProcedureReturn #True
                  EndSelect
              EndSelect
            EndIf
          EndIf  ; is white or black
        Else
          ; empty square, just keep going
        EndIf
      EndIf  ; off-board test
    Next ;SqCnt
  Next ;The_Dir

  ProcedureReturn #False

EndProcedure



Procedure Stockfish_FEN_Analysis_Thread(*Value)

Define ProgramID
OpenConsole()

ProgramID = RunProgram(Stockfish_Input_Path, "", GetCurrentDirectory(), #PB_Program_Open | #PB_Program_Read | #PB_Program_Write)

If ProgramID And QuickEngine_Flag = #False
 
  PrintN("Stockfish started successfully.")

  ; --- UCI Handshake ---
  SendUCICommand(ProgramID, "uci")
  
  ReadUCIResponse(ProgramID, 1000)
  uci_info = output
  PrintN("<< UCI Received:\n" + uci_info)
  If FindString(uci_info, "uciok", 1)
    PrintN("Stockfish UCI handshake successful.")
  Else
    PrintN("Error: Stockfish UCI handshake failed.")
    End
  EndIf

  SendUCICommand(ProgramID, "isready")
  If WaitForUCIResponse(ProgramID, "readyok")
    PrintN("Stockfish is ready.")
  Else
    PrintN("Error: Stockfish did not become ready.")
    End
  EndIf

  ; --- Set a FEN position and get the best move --- fen passed thru call vector above
  ;fenPosition = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1" ; Starting position
  PrintN("Sending FEN: " + SF_fenPosition)
  GetBestMoveUCIPV(ProgramID, SF_fenPosition, SF_Time_Per_Move, 2)
  If bestMove
    PrintN("Stockfish best move: " + bestMove)
  Else
    ;Debug "Error: Could not get best move from Stockfish."
  EndIf
  
  SendUCICommand(ProgramID, "quit")
  CloseProgram(ProgramID)
  
Else
  Debug "Error: Could not start Stockfish. Please ensure the path is correct."
EndIf
  


  ProgramID = RunProgram(Stockfish_Input_Path, "", GetCurrentDirectory(), #PB_Program_Open | #PB_Program_Read | #PB_Program_Write)

  If ProgramID
    PrintN("Stockfish started successfully.")
  
    ; --- UCI Handshake ---
    SendUCICommand(ProgramID, "uci")
  
    ReadUCIResponse(ProgramID, 1000)
    uci_info = output
    PrintN("<< UCI Received:\n" + uci_info)
    If FindString(uci_info, "uciok", 1)
      PrintN("Stockfish UCI handshake successful.")
    Else
      PrintN("Error: Stockfish UCI handshake failed.")
      End
    EndIf

  SendUCICommand(ProgramID, "isready")
  If WaitForUCIResponse(ProgramID, "readyok")
    PrintN("Stockfish is ready.")
  Else
    PrintN("Error: Stockfish did not become ready.")
    End
  EndIf

  ; --- Set a FEN position and get the best move --- fen passed thru call vector above
  ;fenPosition = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1" ; Starting position
  PrintN("Sending FEN: " + SF_fenPosition)
  GetBestMoveUCIPV(ProgramID, SF_fenPosition, SF_Time_Per_Move, 1)
  SendUCICommand(ProgramID, "quit")
  CloseProgram(ProgramID)
  If QuickEngine_Flag = #False And pvstring(2) <> ""
    SetGadgetText(#Info_Field, "...done...pv1 = " + pvstring(1) + Space(2) + " score: " + cpscore_str(1) + #CRLF$ + "pv2 = " + pvstring(2) + Space(2) + " score: " + cpscore_str(2))
  Else
    SetGadgetText(#Info_Field, "...done...pv1 = " + pvstring(1) + Space(2) + " score: " + cpscore_str(1) + #CRLF$)
  EndIf
Else
  Debug "Error: Could not start Stockfish. Please ensure the path is correct."
EndIf
  

EndProcedure



Procedure WaitForUCIResponse(ProgramID, expectedResponse.s, timeout_ms = 5000)
  Protected startTime = ElapsedMilliseconds(), response$
  While ElapsedMilliseconds() - startTime < timeout_ms
    ReadUCIResponse(ProgramID)
    response$ = output
    If FindString(response$, expectedResponse, 1)
      ProcedureReturn #True
    EndIf
    Delay(10)
  Wend
  ProcedureReturn #False
EndProcedure


Procedure XTrim(text.s)
  While Left(text, 1) = " " Or Left(text, 1) = Chr(9) Or Left(text, 1) = Chr(10) Or Left(text, 1) = Chr(13)
    text = Mid(text, 2)
  Wend
  While Right(text, 1) = " " Or Right(text, 1) = Chr(9) Or Right(text, 1) = Chr(10) Or Right(text, 1) = Chr(13)
    text = Left(text, Len(text) - 1)
  Wend
  ;ProcedureReturn text
EndProcedure

Procedure SendUCICommand(ProgramID, command.s)
  WriteProgramStringN(ProgramID, command)
  Debug ">> UCI Sent: " + command
EndProcedure


; ***************************************************** main program  ***********************************

OpenConsole("PBConsole")

BoardInitialize()
BuildValidQueenMovesTable()
Stockfish_Input_Path = #StockfishPath

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  DB_InputFile = FileRequester(#RequesterTypeOpen,
                    "Please choose a PGN or SQLite file to open",
                    "/users/kenpchess/",
                    "pgn|db3|sqlite",
                    "Choose a PGN (.pgn, [SAN] or [UCI]) or SQLite (.db3, .sqlite) file only",
                    #PB_Requester_MultiSelection)
CompilerEndIf


CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  
  #StandardFile = "C:\PureBasic\pgns\sf_4cpu_gms_san2.pgn"
  RequesterTitle = "Please choose the PGN or SQLite file to load"
  
  ; With next string we will set the search patterns ("|" as separator) for file displaying:
  ;  1st: "Text (*.txt)" as name, ".txt" and ".bat" as allowed extension
  ;  2nd: "PureBasic (*.pb)" as name, ".pb" as allowed extension
  ;  3rd: "All files (*.*) as name, "*.*" as allowed extension, valid for all files
  ;Pattern$ = "Text (*.txt;*.bat)|*.txt;*.bat|PureBasic (*.pb)|*.pb|All files (*.*)|*.*"
  FilePattern = "PGN(*.pgn)|*.pgn|SQLite(*.db3;*.sqlite)|*.db3;*.sqlite"
  Pattern = 0    ; use the first of the three possible patterns as standard
  DB_InputFile = OpenFileRequester(RequesterTitle, #StandardFile, FilePattern, Pattern, #PB_Requester_MultiSelection)
  If DB_InputFile
    ;MessageRequester("Information", "You have selected the following file:" + Chr(10) + DB_InputFile, 0)
  Else
    MessageRequester("Information", "The requester was canceled.", 0) 
  EndIf
  
CompilerEndIf


;DB_InputFile = InputRequester("PGN or SQLite Input File - about 10 - 30secs to load", "Please enter a SAN-compliant PGN filename or UCI-compliant PGN filename or SQLite chess database file: ", "/users/kenpchess/desktop/kppb_pgn_etc/pgns/sf_4cpu_gms_san2.pgn")

 If FindString(DB_InputFile, ".pgn") > 0 And ReadFile(0, DB_InputFile)
  wFlags = #PB_Window_SystemMenu | #PB_Window_ScreenCentered
  OpenWindow(#miniwin, 0, 0, 900, 300,"Ready to read PGN file..." + DB_InputFile, wFlags)
  TextGadget(#clocktimer, 10, 10, 860, 50, "00:00:00", #PB_Text_Right)
  TextGadget(#fileprogresstextgadget, 10, 200, 800,  40, "", #PB_Text_Center)
  ButtonGadget(#startbutton, 200, 60, 500, 30, "Click to begin the PGN file reading process...")
  AddWindowTimer(#miniwin, 0, 1000)
  startdate = Date()
 
    fileLen = Lof(0)
    If fileLen > 65536
      max = 65536
    Else
      max = fileLen
    EndIf
    ProgressBarGadget(#fileprogressbar, 45, 120, 780, 50, 0, max) 
    HideGadget(#fileprogressbar, #True)
    CloseFile(0)

  SQL_flag = 0
  ;LoadPGN("/users/testuser/desktop/kppb_pgn_etc/pgns/"+DB_InputFile) ; Replace with your PGN file name
  PGNFileName = DB_InputFile
  If FileSize(PGNFileName) < #PGNSizeSkipProgressStartBtn
    PostEvent(#PB_Event_Gadget, #miniwin, #startbutton, #PB_EventType_LeftClick)
  EndIf
  
  Repeat
    event = WaitWindowEvent()
    Select Event
      Case #PB_Event_CloseWindow
        appQuit = 1
      Case #PB_Event_Gadget
        If EventGadget() = #startbutton
          HideGadget(#fileprogressbar, #False)
          DisableGadget(#startbutton, #True)
          ; start reading the file in a thread
          CreateThread(@LoadPGN_Thread(), 0)
        EndIf
      Case #PB_Event_Timer
        If EventTimer() = 0
          ; a running clock shows that window events are not blocked
          SetGadgetText(#clocktimer, FormatDate("%hh:%ii:%ss", Date()-startdate))     
        EndIf
      Case #progressBarEvent        ; process the custom event
        ; get the current file read location
        currentRead = EventData()       
        ; calculate the current location of the progress bar
        If fileLen > 65536
          inc = currentRead / (fileLen / 65536)
        Else
          inc = currentRead
        EndIf
        SetGadgetState (#fileprogressbar, inc)               ; increment the progress bar & label with the read location value
        SetGadgetText(#fileprogresstextgadget, "PGNFile Read Progress (" + Str(currentRead) + "/" + Str(fileLen) + ")")
        If currentRead = fileLen
          DisableGadget(#startbutton, #False)
        EndIf
        
    EndSelect
  Until All_Games_Read_Flag = 1
  
  Delay(500)
  CloseWindow(#miniwin)
Else
  SQL_flag = 1
    ;MessageRequester("File PGN read...", "File error!")
  ;LoadSQLiteChessDatabase("/users/testuser/desktop/kppb_pgn_etc/"+DB_InputFile)
  LoadSQLiteChessDatabase(DB_InputFile)
EndIf

DisplayGames()
; IDE Options = PureBasic 6.21 - C Backend (MacOS X - x64)
; CursorPosition = 2461
; FirstLine = 2434
; Folding = --------------------
; EnableThread
; EnableXP
; DPIAware
; Executable = PGNdbkp_20250813.app
