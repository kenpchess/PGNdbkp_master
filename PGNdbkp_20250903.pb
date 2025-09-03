; PureBasic PGN SAN-UCI-notation Reader, SQLite chess DB, and Display (by kenpchess).
; Many thanks to all of the coding experts at the PureBasic forum. This program
; contains code snippets from "Azjio", "Fred", "mk-soft",	"ti994A", "idle",
; "infratec", and others! Thank you all for your code examples!
;
CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  EnableExplicit
CompilerEndIf

Global version.s = "_20250903"
#game_max = 200000 : #halfmove_max = 2000 : #PGNSizeSkipProgressStartBtn = 10000000
#canvas_gadgetX = 75 : #canvas_gadgetY = 470
#cg_width = 575 : #cg_height = 545
#alg_filesY = 20 : #alg_rankX = 20
#alg_baseX = 25 : #alg_baseY = 20
#doc_offset = 30 : #demo_y_offset = 10
#progressBarEvent = #PB_Event_FirstCustomValue
#Image_Board192 = 0
#Image_Whitebkgnd32 = 37

#ButtonsLeftEdgeDefaultX = 675
#playgadgetwidth = 685 : #playgadgetDefaultHeight = 420
#movesgadgetX = 730 : #movesgadgetwidth = 275 : #movesgadgetDefaultHeight = 425

#fileinfogadgetDefaultX = 150 : #fileinfogadgetDefaultY = 440 : #fileinfogadgetwidth = 450
#FENBtnDefaultY = 475 : #FENBtnDefaultX = #ButtonsLeftEdgeDefaultX - 5
#Single_MoveDefaultY = 510 : #Single_MoveDefaultX = #ButtonsLeftEdgeDefaultX
#InfoFieldDefaultY = 547 : #InfoFieldDefaultHeight = 115
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
#sample_games = 800

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
Global Dim Gadget_List_Display2.s(#game_max)
Global Dim Game_FEN_Positions.s(#halfmove_max)
Global Dim GameScore_UCI_HalfMoves.s(#halfmove_max)
Global Dim GameScore_Plain_HalfMoves.s(#halfmove_max)
Global Dim WhitePlayers.s(#game_max)
Global PGNFileName.s, All_Games_Read_Flag.b
Global AssignedChessDate.s = FormatDate("%yyyy%mm%dd", Date())                   ; todays chess date (for pgns with missing date)
Global EmptySq_Button_Flag.b, Piece_Button_Flag.b
Global PlayEngineEditCount.i, PlayEngineFENstr.s, MoveString.s
Global QuickEngine_Flag.b = #False, SampleGames_Flag.b = #False, Engine_Running_Flag.b = #False
Global PDFWidth.f = 600
Global PDFHeight.f = 700
Global EmptySq_Button_Click_Count.i

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
Global MultiPV.b, cpscore_normal_pos.i, cpscore_mate_pos.i, pva.i, pvb.i
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
	IncludeBinary "/users/kenpchess/Public/images/pieces24/br24.png"
	piece26:
	IncludeBinary "/users/kenpchess/Public/images/pieces24/bn24.png"
	piece27:
	IncludeBinary "/users/kenpchess/Public/images/pieces24/bb24.png"
	piece28:
	IncludeBinary "/users/kenpchess/Public/images/pieces24/bq24.png"
	piece29:
	IncludeBinary "/users/kenpchess/Public/images/pieces24/bk24.png"
	piece30:
	IncludeBinary "/users/kenpchess/Public/images/pieces24/bp24.png"
	piece31:
	IncludeBinary "/users/kenpchess/Public/images/pieces24/wr24.png"
	piece32:
	IncludeBinary "/users/kenpchess/Public/images/pieces24/wn24.png"
	piece33:
	IncludeBinary "/users/kenpchess/Public/images/pieces24/wb24.png"
	piece34:
	IncludeBinary "/users/kenpchess/Public/images/pieces24/wq24.png"
	piece35:
	IncludeBinary "/users/kenpchess/Public/images/pieces24/wk24.png"
	piece36:
	IncludeBinary "/users/kenpchess/Public/images/pieces24/wp24.png"
	piece45:
	IncludeBinary "/users/kenpchess/Public/images/pieces24/es32.png"
	board192: 
	IncludeBinary "/users/kenpchess/Public/images/pieces24/chessboard192_blank2.png"
	whitebkgnd32:
	IncludeBinary "/users/kenpchess/Public/images/pieces24/white_bkgnd32.png"
  
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
	IncludeBinary "C:/PureBasic/images/pieces24/br24.png"
	piece26:
	IncludeBinary "C:/PureBasic/images/pieces24/bn24.png"
	piece27:
	IncludeBinary "C:/PureBasic/images/pieces24/bb24.png"
	piece28:
	IncludeBinary "C:/PureBasic/images/pieces24/bq24.png"
	piece29:
	IncludeBinary "C:/PureBasic/images/pieces24/bk24.png"
	piece30:
	IncludeBinary "C:/PureBasic/images/pieces24/bp24.png"
	piece31:
	IncludeBinary "C:/PureBasic/images/pieces24/wr24.png"
	piece32:
	IncludeBinary "C:/PureBasic/images/pieces24/wn24.png"
	piece33:
	IncludeBinary "C:/PureBasic/images/pieces24/wb24.png"
	piece34:
	IncludeBinary "C:/PureBasic/images/pieces24/wq24.png"
	piece35:
	IncludeBinary "C:/PureBasic/images/pieces24/wk24.png"
	piece36:
	IncludeBinary "C:/PureBasic/images/pieces24/wp24.png"
	piece45:
  IncludeBinary "C:/PureBasic/images/pieces24/es32.png"
  board192: 
  IncludeBinary "C:/PureBasic/images/pieces24/chessboard192_blank2.png"
  whitebkgnd32:
  IncludeBinary "C:/PureBasic/images/pieces24/white_bkgnd32.png"
  
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
Declare CreateChessboardPDF()
Declare DoEventMacOS()
Declare DisplayGames()
Declare DrawVectorTextDemoData(k.i)
Declare ExportPGNGame()
Declare ExportGameToPDF()
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
Declare LoadSampleGames()
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
Declare OutputSampleGameCode()
Declare.s ParseAndCleanPGN(PGNDirtyGameScore.s)
Declare Parse_Save_GameScore_Bare_Halfmoves(GameScore.s)
Declare PlayEngine()
Declare Player_Search()
Declare PreviousMove()
Declare PrintAsciiBoard(OutputID.i,FileID.i)
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
  #Btn_SampleData
  #Single_Move_Gadget
  #Btn_Fen
  #Btn_BoardSize
  #Btn_ExportGame
  #Info_Field
  #Btn_ExportPDF
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
  CatchImage(45, ?piece45)
  
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
  ButtonImageGadget(#Btn_es32,30,#btnes32DeFaultY, 40, 40,ImageID(45))
  
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



Procedure CreateChessboardPDF()
  
  Protected x.i, y.i, row.i, col.i, piece.i
  Protected PDFSquareSize.i = 24, PieceSize.i = 24
  
  CatchImage(25, ?piece25) : CatchImage(26, ?piece26) : CatchImage(27, ?piece27) : CatchImage(28, ?piece28)
  CatchImage(29, ?piece29) : CatchImage(30, ?piece30) : CatchImage(31, ?piece31) : CatchImage(32, ?piece32)
  CatchImage(33, ?piece33) : CatchImage(34, ?piece34) : CatchImage(35, ?piece35) : CatchImage(36, ?piece36)
  CatchImage(0, ?Board192)
  CatchImage(37, ?whitebkgnd32)
  CatchImage(45, ?piece45)
  
  
  ; Start a VectorDrawing session for the PDF file
  ;If StartVectorDrawing(PdfVectorOutput("/users/kenpresley/desktop/chessboard24e.pdf", PDFWidth, PDFHeight))
    
    ; --- Draw the chessboard background ---
    ; Get the ImageID of the loaded chessboard image.
    VectorSourceImage(ImageID(#Image_Board192))
    ; Draw the image to fill the entire PDF page.
    MovePathCursor(#doc_offset, #doc_offset)
    DrawVectorImage(ImageID(#Image_Board192), 255, PDFSquareSize*8, PDFSquareSize*8)
    
    ; --- Draw each chess piece on its square ---
    For row = 20 To 90 Step 10
      y = row/10 - 2
      For col = 1 To 8
        x = col - 1
        piece = MbxBrd(row + col)
        ;PrintN("Piece = " + Str(piece))
        If piece <> 0 ; Check if there's a piece on this square
          
          ; Calculate the position for the piece on the page.
          ; We need to flip the Y coordinate because array indices start from 0 at the top,

          Define xPos.f = x * PieceSize 
          Define yPos.f = y * PieceSize
          
          ; Set the source to the image of the current piece
          VectorSourceImage(ImageID(piece+24))
          
          ; Draw the piece image, scaling it to fit the square size.
          MovePathCursor(xPos + #doc_offset, yPos + #doc_offset)
          DrawVectorImage(ImageID(piece+24),255, PieceSize, PieceSize)
        EndIf
      Next col
    Next row
    
   
    
    ;MovePathCursor(0, 0)
    ;DrawVectorImage(ImageID(45),255, 32, 32)  ; temp bugfix for weird corner graphic artifact
    
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      ;PrintN("Success! The PDF file 'chessboard.pdf' has been created.")
    CompilerEndIf
  
EndProcedure



Procedure DrawVectorTextDemoData(k.i)
  
  Protected sample_gamescore_moves.s
  Protected PDFSquareSize.i = 24
  Protected sample_move.s = "46. b4 gxh4"
  Protected pvstring_sample.s = "pv = g3h4 b1g6 e3g2 g6f7 g2f4 d6c6 f4d3 f7e6 f2g3 c6d6 d3f4 e6f7 g3h2 d6c7 f4d3 f7e6 h2g2 c7c6   eval = 137"
  
  sample_gamescore_moves = "1. d4 d5 2. c4 e6 3. Nf3 c5 4. cxd5 exd5 5. g3 Nf6 6. Bg2 Be7 7. O-O O-O 8. Nc3 Nc6 9. Bg5 cxd4 10. Nxd4 h6 11. Be3 Re8 12. Qb3 Na5 13. Qc2 Bg4 14. Nf5 Rc8 15. Bd4 Bc5 16. Bxc5 Rxc5 17. Ne3 Be6 18. Rad1 Qc8 19. Qa4 Rd8 20. Rd3 a6 21. Rfd1 Nc4 22. Nxc4 Rxc4 23. Qa5 Rc5 24. Qb6 Rd7 25. Rd4 Qc7 26. Qxc7 Rdxc7 27. h3 h5 28. a3 g6 29. e3 Kg7 30. Kh2 Rc4 31. Bf3 b5 32. Kg2 R7c5 33. Rxc4 Rxc4 34. Rd4 Kf8 35. Be2 Rxd4 36. exd4 Ke7 37. Na2 Bc8 38. Nb4 Kd6 39. f3 Ng8 40. h4 Nh6 41. Kf2 Nf5 42. Nc2 f6 43. Bd3 g5 44. Bxf5 Bxf5 45. Ne3 Bb1 46. b4 gxh4 47. Ng2 $1 hxg3+ 48. Kxg3 Ke6 49. Nf4+ Kf5 50. Nxh5 Ke6 51. Nf4+ Kd6 52. Kg4 Bc2 53. Kh5 Bd1 54. Kg6 Ke7 55. Nxd5+ Ke6 56. Nc7+ Kd7 57. Nxa6 Bxf3 58. Kxf6 Kd6 59. Kf5 Kd5 60. Kf4 Bh1 61. Ke3 Kc4 62. Nc5 Bc6 63. Nd3 Bg2 64. Ne5+ Kc3 65. Ng6 Kc4 66. Ne7 Bb7 67. Nf5 Bg2 68. Nd6+ Kb3 69. Nxb5 Ka4 70. Nd6 1-0"
  
  MovePathCursor(PDFSquareSize*8 + #doc_offset*2, #demo_y_offset + PDFSquareSize)
  DrawVectorText("[Site " + #DQUOTE$ + EventSites(k) + #DQUOTE$ + "]")
  
  MovePathCursor(PDFSquareSize*8 + #doc_offset*2, #demo_y_offset + PDFSquareSize*1.6)
  DrawVectorText("[Date " + #DQUOTE$ + GameDates(k) + #DQUOTE$ + "]")
  
  MovePathCursor(PDFSquareSize*8 + #doc_offset*2, #demo_y_offset + PDFSquareSize*2.2)
  DrawVectorText("[White " + #DQUOTE$ + Trim(WhitePlayers(k),Space(1))  + #DQUOTE$ + "]")
  
  MovePathCursor(PDFSquareSize*8 + #doc_offset*2, #demo_y_offset + PDFSquareSize*2.8)
  DrawVectorText("[WhiteElo " + #DQUOTE$ + WhiteElos(k) + #DQUOTE$ + "]")
  
  MovePathCursor(PDFSquareSize*8 + #doc_offset*2, #demo_y_offset + PDFSquareSize*3.4)
  DrawVectorText("[Black " + #DQUOTE$ + Trim(BlackPlayers(k),Space(1)) + #DQUOTE$ + "]")
  
  MovePathCursor(PDFSquareSize*8 + #doc_offset*2, #demo_y_offset + PDFSquareSize*4)
  DrawVectorText("[BlackElo " + #DQUOTE$ + BlackElos(k) + #DQUOTE$ + "]")
  
  MovePathCursor(PDFSquareSize*8 + #doc_offset*2, #demo_y_offset + PDFSquareSize*4.6)
  DrawVectorText("[Result " + #DQUOTE$ + Each_Game_Result(k) + #DQUOTE$ + "]")
  
  MovePathCursor(PDFSquareSize*8 + #doc_offset*2, #demo_y_offset + PDFSquareSize*6)
  

  DrawVectorParagraph(MoveString, 300, 600)
  
  ;MovePathCursor(#doc_offset*3, #demo_y_offset + PDFSquareSize*9)
  ;DrawVectorText(sample_move)
  
  
  
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
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("")
    PrintN("FEN = " + tempFENstr)
    PrintN("")
    PrintN("CPF - HalfMoveCount = " + Str(HalfMoveCount))
  CompilerEndIf
  
  FEN_ColorToMove = FindString(tempFENstr," w",1)
  
  If FEN_ColorToMove > 0
    FEN_SideToMove = White_on_Move
  Else
    FEN_SideToMove = Black_on_Move
  EndIf
  
  MoveNoStr = Mid(tempFENstr,Len(tempFENstr)-1,2)
  GameMoveNumber = Val(Trim(MoveNoStr,Space(1)))
  ;PrintN("debug: CPfF - length of FEN string = " + Str(Len(tempFENstr)) + " GameMoveNumber = " + Str(GameMoveNumber))

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
  Protected SingleMoveResult.b, FENBtnResult.b, InfoResult.b, ExportPDFBtnResult.b, FileInfoResult.b
  Protected PrevBtnResult.b, NextBtnResult.b, DbBtn1Result.b, DbBtn2Result.b, SFBtnResult.b
  Protected SFBtn10secResult.b, PSBtnResult.b, EdBtnResult.b, UpdSFBtnResult.b
  Protected BrdSizeBtnResult.b, PlayvsSFBtnResult, ExportGameBtnResult.b, SampleDataBtnResult.b
  Protected GameLink_pos.i, G1_pos.i, G2_pos.i, i.i
  Protected ColorToMove.b, WhiteOnMove.b, x.b, y.i, yy.i, z.i
  Protected currentEvent.i, type.i, modifierFlags.i, keycode.i, wflags.i
  
  wflags = #PB_Window_SizeGadget | #PB_Window_SystemMenu | #PB_Window_ScreenCentered
  WindowID = OpenWindow(#mainwin, 100, 100, #mainwinDefaultWidth, #mainwinDefaultHeight, "PGNdbkp" + version + " - PGN Game And SQLite chessdb Viewer ", wflags)
  PlayerListGadget = ListIconGadget(#Players_ListIcon_Gadget, 20, 10, #playgadgetwidth, #playgadgetDefaultHeight, "Game #", 80, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  
  AddGadgetColumn(#Players_ListIcon_Gadget, 1, "White Player", 175)
  AddGadgetColumn(#Players_ListIcon_Gadget, 2, "Black Player", 175)
  AddGadgetColumn(#Players_ListIcon_Gadget, 3, "GameDate", 80)
  AddGadgetColumn(#Players_ListIcon_Gadget, 4, "Event/Site", 95)
  AddGadgetColumn(#Players_ListIcon_Gadget, 5, "Result", 65)
  
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
    
  If SampleGames_Flag = #False
    FileInfoResult = StringGadget(#DbFile_Gadget, #fileinfogadgetDefaultX, #fileinfogadgetDefaultY, #fileinfogadgetwidth, 25, "db: " + DB_InputFile)
  Else
    FileInfoResult = StringGadget(#DbFile_Gadget, #fileinfogadgetDefaultX, #fileinfogadgetDefaultY, #fileinfogadgetwidth, 25, "A file was NOT selected: showing sample games: [1-" + Str(#sample_games) + "]")
  EndIf
  SampleDataBtnResult = ButtonGadget(#Btn_SampleData, #fileinfogadgetDefaultX+475, #fileinfogadgetDefaultY, 40, 25, "S")
  HideGadget(#Btn_SampleData, 1)
  FENBtnResult = ButtonGadget(#Btn_Fen, #FENBtnDefaultX, #FENBtnDefaultY, 90, 25, "Show FEN")
  BrdSizeBtnResult = ButtonGadget(#Btn_BoardSize, #ButtonsLeftEdgeDefaultX+95, #FENBtnDefaultY, 100, 25, "BoardSize")
  ExportGameBtnResult = ButtonGadget(#Btn_ExportGame, #ButtonsLeftEdgeDefaultX+205, #FENBtnDefaultY, 120, 25, "ExportGame[s]")
  ExportPDFBtnResult = ButtonGadget(#Btn_ExportPDF, #ButtonsLeftEdgeDefaultX+205, #Single_MoveDefaultY, 120, 25, "ExportToPDF")
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
      AddGadgetItem(#Players_ListIcon_Gadget, -1, GameLink + Chr(10) + Trim(Left(WhitePlayers(i), G1_pos-1), " ") + " [" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + " [" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i)) 
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
              Case #Btn_SampleData
                MessageRequester("Magic S button","This is the sample Data creator magic S button. ...Information To follow!")
                OutputSampleGameCode()
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
              Case #Btn_ExportPDF
                ExportGameToPDF()
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
                GameInfo = GetGadgetItemText(#Players_ListIcon_Gadget, GameIndex,0)
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
  
  ; This procedure exports one or more games as a PGN file with optional engine analysis and diagrams. An
  ; InputRequester expects a reply in the form:
  ;
  ; [5-8] /engine/diagram:10        or       [5] /engine/diagram:10
  ;
  ; where [x-y] or simply [x] is a game number or range of game numbers
  ; /engine     is an optional parameter requesting a shallow engine analysis be printed in the exported PGN file
  ; /diagram:z  is an optional parameter requesting diagrams (in ascii) be printed in the exported PGN file every "z" halfmoves
  ;
  ; This procedure calls: RemovePGNCommentsAndVariations2(), Parse_Save_GameScore_Bare_Halfmoves(),
  ; ConstructPositionfromFEN(), and CreateThread(@Stockfish_FEN_Analysis_Thread(),1)
  ;
  
Protected DefaultFileName.s, Pattern.s, PGNFilename.s, FileID.i, G1_pos.i, G2_pos.i, GameLink0.s, diagram_pos.i
Protected fullversionname.s = "PGNdbkp" + version
Protected nowdate1.s, nowdate2.s, MoveString.s, Games_Export_Count_str.s
Protected j.i, k.i, z.i, year.i, month.i, day.i, hour.i, minute.i, seconds.i, Games_Export_Count.i, dash_pos.i
Protected HalfMove_Diagram_Counter.i, color_pos.i, Engine_analy_flag.i, right_bracket_pos.i, first_slash_pos.i

nowdate1 = FormatDate("%yyyy%mm%dd%hh%ii%ss", Date())
nowdate2 = FormatDate("%yyyy%mm%dd", Date())

DefaultFileName = "/Users/kenpchess/Desktop/PGNdbkp_games_" + nowdate1 + ".pgn"
Pattern.s = ""
MoveString = ""

If GameIndex >= 0
  G1_pos = FindString(WhitePlayers(GameIndex+1), Game_Prefix, 1)
  G2_pos = FindString(BlackPlayers(GameIndex+1), Game_Prefix, 1)
  GameLink0 = Mid(BlackPlayers(GameIndex+1), G2_pos+2, 6)
EndIf

Repeat
  Games_Export_Count_str = InputRequester("PGN game(s) export", "Export this game [" + GameLink0 + "] or Range of games [" + GameLink0 + "-" + Str(GameCount-1) + "] (/with engine analy)(with/wo diagrams)?", "["+GameLink0+"] /engine/diagram:10")
  first_slash_pos = FindString(Games_Export_Count_str,"/",1)
  dash_pos = FindString(Games_Export_Count_str,"-",1)
  right_bracket_pos = FindString(Games_Export_Count_str,"]",1)
  Engine_analy_flag = FindString(Games_Export_Count_str,"/engine",1)
  diagram_pos = FindString(Games_Export_Count_str,"/diagram:",1)
  If diagram_pos > 0
    HalfMove_Diagram_Counter = Val(Mid(Games_Export_Count_str,diagram_pos+9,3))
    PrintN("HalfMove_Diagram_Counter = " + Str(HalfMove_Diagram_Counter))
    Games_Export_Count_str = Left(Games_Export_Count_str,first_slash_pos-2)
  Else
    HalfMove_Diagram_Counter = 200
  EndIf
  If  dash_pos <= 0
    Games_Export_Count = Val(GameLink0)
  Else
    Games_Export_Count = Val(Mid(Games_Export_Count_str,dash_pos+1,right_bracket_pos-dash_pos-1))
  EndIf
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("GameLink0 = " + GameLink0 + " Games_Export_Count = " + Str(Games_Export_Count))
  CompilerEndIf
Until Val(Gamelink0) <= GameCount-1 And Games_Export_Count <= GameCount-1

PGNFilename = SaveFileRequester("Save the currently selected single PGN game (or engine game)?", DefaultFileName, Pattern, 0)
FileID = OpenFile(#PB_Any, PGNFileName)

For k = Val(GameLink0) To Games_Export_Count

If FileID
  If GameIndex >= 1
    FilePGNs(k) = ParseAndCleanPGN(FilePGNs(k))
    ;PrintN("FilePGN(" + Str(k) + ") = " + FilePGNs(k))
    RemovePGNCommentsAndVariations2(FilePGNs(k))
    FilePGNs(k) = result
    For j = 1 To #halfmove_max : GameScore_Plain_HalfMoves(j) = "" : Game_FEN_Positions(j) = "" : Next
    Parse_Save_GameScore_Bare_Halfmoves(FilePGNs(k))
    G1_pos = FindString(WhitePlayers(k), Game_Prefix, 1)
    G2_pos = FindString(BlackPlayers(k), Game_Prefix, 1)
    MoveString = ""
    If Trim(EventSites(k),Space(1)) = ""
      WriteStringN(FileID, "[Site " + #DQUOTE$ + "n/a" + #DQUOTE$ + "]")
    Else
      WriteStringN(FileID, "[Site " + #DQUOTE$ + EventSites(k) + #DQUOTE$ + "]")
    EndIf
    WriteStringN(FileID, "[Date " + #DQUOTE$ + GameDates(k) + #DQUOTE$ + "]")
    WriteStringN(FileID, "[White " + #DQUOTE$ + Trim(Left(WhitePlayers(k), G1_pos-1), " ")  + #DQUOTE$ + "]")
    If WhiteElos(k) <> "" And WhiteElos(k) <> "n/a"
      WriteStringN(FileID, "[WhiteElo " + #DQUOTE$ + WhiteElos(k) + #DQUOTE$ + "]")
    EndIf
    WriteStringN(FileID, "[Black " + #DQUOTE$ + Trim(Left(BlackPlayers(k), G2_pos-1), " ") + #DQUOTE$ + "]")
    If BlackElos(k) <> "" And BlackElos(k) <> "n/a"
      WriteStringN(FileID, "[BlackElo " + #DQUOTE$ + BlackElos(k) + #DQUOTE$ + "]")
    EndIf
    WriteStringN(FileID, "[Result " + #DQUOTE$ + Each_Game_Result(k) + #DQUOTE$ + "]")
    If FEN_setup_flag(k) = 1
      WriteStringN(FileID, "[Setup " + #DQUOTE$ + "1" + #DQUOTE$ + "]")
      WriteStringN(FileID, "[FEN " + #DQUOTE$ + FEN_setup_str(k) + #DQUOTE$ + "]")
    EndIf
  Else
    WriteStringN(FileID, "[Site " + #DQUOTE$ + fullversionname + " exportgame" + #DQUOTE$ + "]")
    WriteStringN(FileID, "[Date " + #DQUOTE$ +  nowdate2 + #DQUOTE$ + "]")
    WriteStringN(FileID, "[White " + #DQUOTE$ + "HumanPlayer" + #DQUOTE$ + "]")
    WriteStringN(FileID, "[Black " + #DQUOTE$ + "Eng:" + Stockfish_Input_Path + #DQUOTE$ + "]")
    WriteStringN(FileID, "[Result " + #DQUOTE$ + "*" + #DQUOTE$ + "]")
  EndIf
  
  WriteStringN(FileID, "")
  ;For z = 1 To TotalHalfMoves : PrintN("FEN halfmove " + Str(z) + " = " + Game_FEN_Positions(z)) : Next
  
  For j = 1 To TotalHalfMoves
    If j % 2 > 0 And J <> TotalHalfMoves
      MoveString = MoveString + Str(j/2 + 1) + ". " + ReplaceString(GameScore_Plain_HalfMoves(j),Space(1),"") + Space(1)
    Else
      MoveString = MoveString + ReplaceString(GameScore_Plain_HalfMoves(j),Space(1),"") + Space(1)
    EndIf
  Next
  MoveString = Trim(Movestring,Space(1))
  If GameIndex <= 0
    MoveString = MoveString + Space(1) + "*"
  EndIf
  WriteString(FileID, MoveString)
  
  For z = 1 To TotalHalfMoves
    If ((z-1) % 2 > 0 And z % HalfMove_Diagram_Counter = 0) Or (z >= TotalHalfMoves-6 And (z-1) % 2 > 0 And HalfMove_Diagram_Counter <> 200)
      If FindString(GameResult_SearchMask, Trim(GameScore_Plain_HalfMoves(z),Space(1))) <= 0
        ConstructPositionfromFEN(Game_FEN_Positions(z))
      Else
        ConstructPositionfromFEN(Game_FEN_Positions(z-1))
      EndIf
      WriteString(FileID, "") : WriteString(FileID, #CRLF$) : WriteString(FileID, #CRLF$)
      PrintAsciiBoard(1, FILEID)
      PrintAsciiBoard(2, FILEID)
      WriteString(FileID, Str(z/2) + ". " + Trim(GameScore_Plain_HalfMoves(z-1),Space(1)) + Space(1) + GameScore_Plain_HalfMoves(z))
      WriteString(FileID, #CRLF$)
      pvstring(1) = "" : pvstring(2) = "" : cpscore_str(1) = "" : cpscore_str(2) = ""
      If Game_FEN_Positions(z) <> "" And Engine_analy_flag > 0
        SF_Time_Per_Move = 350
        QuickEngine_Flag = #True
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN("...calling Stockfish...halfmove = " + Str(z) + " FEN=" + Game_FEN_Positions(z))
        CompilerEndIf
        If FindString(GameResult_SearchMask, Trim(GameScore_Plain_HalfMoves(z),Space(1))) > 0
          SF_fenposition = Game_FEN_Positions(z-1)
        Else
          SF_fenposition = Game_FEN_Positions(z)
          color_pos = FindString(SF_fenposition, "b ")
          If color_pos > 0                                                   ; fix this temporary FEN to color White-to-move
            SF_fenposition = Left(SF_fenposition,color_pos-1) + "w " + Mid(SF_fenposition,color_pos+2,15)                       
            ;PrintN("Fixed SF_fenposition = " + SF_fenposition)
          EndIf
        EndIf
        Engine_Running_Flag = #True
        CreateThread(@Stockfish_FEN_Analysis_Thread(),1)
          Delay(1250)                                                        ; empirical value via testing to help engine thread syncing
        WriteString(FileID, "pv = " + pvstring(1) + Space(2) + "eval = " + cpscore_str(1))
        WriteString(FileID, #CRLF$)
      EndIf
    EndIf
  Next
  WriteString(FileID, #CRLF$) : WriteString(FileID, #CRLF$)
  EndIf
Next

CloseFile(FileID)
SetGadgetText(#Info_Field, "Text file: " + PGNFilename + " created successfully.")

  
EndProcedure

Procedure ExportGameToPDF()
  
  ; This procedure exports one or more games as a PDF file with optional engine analysis and diagrams.
  ; The printed chessboard is in the same graphic style as the onscreen board, just at 192 pixels in size.
  ;
  ; An InputRequester expects a reply in the form:
  ;
  ; [5-8] /engine/diagram:10        or       [5] /engine/diagram:10
  ;
  ; where [x-y] or simply [x] is a game number or range of game numbers
  ; /engine     is an optional parameter requesting a shallow engine analysis be printed in the exported PGN file
  ; /diagram:z  is an optional parameter requesting diagrams (in ascii) be printed in the exported PGN file every "z" halfmoves
  ;
  ; This procedure calls: RemovePGNCommentsAndVariations2(), Parse_Save_GameScore_Bare_Halfmoves(), CreateChessboardPDF(), 
  ; ConstructPositionfromFEN(), and CreateThread(@Stockfish_FEN_Analysis_Thread(),1)
  ;
  
Protected DefaultFileName.s, Pattern.s, PDFFilename.s, FileID.i, G1_pos.i, G2_pos.i, GameLink0.s, diagram_pos.i
Protected fullversionname.s = "PGNdbkp" + version
Protected nowdate1.s, nowdate2.s, Games_Export_Count_str.s
Protected j.i, k.i, z.i, year.i, month.i, day.i, hour.i, minute.i, seconds.i, Games_Export_Count.i, dash_pos.i
Protected HalfMove_Diagram_Counter.i, color_pos.i, Engine_analy_flag.i, right_bracket_pos.i, first_slash_pos.i
Protected PDFSquareSize.i = 24


nowdate1 = FormatDate("%yyyy%mm%dd%hh%ii%ss", Date())
nowdate2 = FormatDate("%yyyy%mm%dd", Date())

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  DefaultFileName = GetCurrentDirectory() + "PGNdbkp_games_" + nowdate1 + ".pdf"
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  DefaultFileName = GetTemporaryDirectory() + "PGNdbkp_games_" + nowdate1 + ".pdf"
CompilerEndIf

Pattern.s = ""
MoveString = ""

If GameIndex >= 0
  G1_pos = FindString(WhitePlayers(GameIndex+1), Game_Prefix, 1)
  G2_pos = FindString(BlackPlayers(GameIndex+1), Game_Prefix, 1)
  GameLink0 = Mid(BlackPlayers(GameIndex+1), G2_pos+2, 6)
EndIf

Repeat
  Games_Export_Count_str = InputRequester("PDF game(s) export", "Export this game [" + GameLink0 + "] or Range of games [" + GameLink0 + "-" + Str(GameCount-1) + "] (/with engine analy)(with/wo diagrams)?", "["+GameLink0+"] /engine/diagram:10")
  first_slash_pos = FindString(Games_Export_Count_str,"/",1)
  dash_pos = FindString(Games_Export_Count_str,"-",1)
  right_bracket_pos = FindString(Games_Export_Count_str,"]",1)
  Engine_analy_flag = FindString(Games_Export_Count_str,"/engine",1)
  diagram_pos = FindString(Games_Export_Count_str,"/diagram:",1)
  If diagram_pos > 0
    HalfMove_Diagram_Counter = Val(Mid(Games_Export_Count_str,diagram_pos+9,3))
    PrintN("HalfMove_Diagram_Counter = " + Str(HalfMove_Diagram_Counter))
    Games_Export_Count_str = Left(Games_Export_Count_str,first_slash_pos-2)
  Else
    HalfMove_Diagram_Counter = 200
  EndIf
  If  dash_pos <= 0
    Games_Export_Count = Val(GameLink0)
  Else
    Games_Export_Count = Val(Mid(Games_Export_Count_str,dash_pos+1,right_bracket_pos-dash_pos-1))
  EndIf
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("GameLink0 = " + GameLink0 + " Games_Export_Count = " + Str(Games_Export_Count))
  CompilerEndIf
Until Val(Gamelink0) <= GameCount-1 And Games_Export_Count <= GameCount-1

PDFFilename = SaveFileRequester("Save the currently selected single PGN game (or engine game)?", DefaultFileName, Pattern, 0)

PrintN("PDFFileName = " + PDFFileName)

StartVectorDrawing(PdfVectorOutput(PDFFileName, PDFWidth, PDFHeight))
For k = Val(GameLink0) To Games_Export_Count
  
  If GameIndex >= 1
    FilePGNs(k) = ParseAndCleanPGN(FilePGNs(k))
    ;PrintN("FilePGN(" + Str(k) + ") = " + FilePGNs(k))
    RemovePGNCommentsAndVariations2(FilePGNs(k))
    FilePGNs(k) = result
    For j = 1 To #halfmove_max : GameScore_Plain_HalfMoves(j) = "" : Game_FEN_Positions(j) = "" : Next
    Parse_Save_GameScore_Bare_Halfmoves(FilePGNs(k))
    G1_pos = FindString(WhitePlayers(k), Game_Prefix, 1)
    G2_pos = FindString(BlackPlayers(k), Game_Prefix, 1)
    MoveString = ""
    
  For j = 1 To TotalHalfMoves
    If j % 2 > 0 And J <> TotalHalfMoves
      MoveString = MoveString + Str(j/2 + 1) + ". " + ReplaceString(GameScore_Plain_HalfMoves(j),Space(1),"") + Space(1)
    Else
      MoveString = MoveString + ReplaceString(GameScore_Plain_HalfMoves(j),Space(1),"") + Space(1)
    EndIf
  Next
  MoveString = Trim(Movestring,Space(1))
  If GameIndex <= 0
    MoveString = MoveString + Space(1) + "*"
  EndIf
  
  
  For z = 1 To TotalHalfMoves
    If ((z-1) % 2 > 0 And z % HalfMove_Diagram_Counter = 0) Or (z >= TotalHalfMoves-6 And (z-1) % 2 > 0 And HalfMove_Diagram_Counter <> 200)
      If FindString(GameResult_SearchMask, Trim(GameScore_Plain_HalfMoves(z),Space(1))) <= 0
        ConstructPositionfromFEN(Game_FEN_Positions(z))
      Else
        ConstructPositionfromFEN(Game_FEN_Positions(z-1))
      EndIf
      
      CreateChessboardPDF()
      DrawVectorTextDemoData(k)
      MovePathCursor(#doc_offset*3, #demo_y_offset + PDFSquareSize*9)
      DrawVectorText( Str(z/2) + ". " + Trim(GameScore_Plain_HalfMoves(z-1),Space(1)) + Space(1) + GameScore_Plain_HalfMoves(z))
      
      pvstring(1) = "" : pvstring(2) = "" : cpscore_str(1) = "" : cpscore_str(2) = ""
      If Game_FEN_Positions(z) <> "" And Engine_analy_flag > 0
        SF_Time_Per_Move = 350
        QuickEngine_Flag = #True
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN("...calling Stockfish...halfmove = " + Str(z) + " FEN=" + Game_FEN_Positions(z))
        CompilerEndIf
        If FindString(GameResult_SearchMask, Trim(GameScore_Plain_HalfMoves(z),Space(1))) > 0
          SF_fenposition = Game_FEN_Positions(z-1)
        Else
          SF_fenposition = Game_FEN_Positions(z)
          color_pos = FindString(SF_fenposition, "b ")
          If color_pos > 0                                                   ; fix this temporary FEN to color White-to-move
            SF_fenposition = Left(SF_fenposition,color_pos-1) + "w " + Mid(SF_fenposition,color_pos+2,15)                       
            ;PrintN("Fixed SF_fenposition = " + SF_fenposition)
          EndIf
        EndIf
        Engine_Running_Flag = #True
        CreateThread(@Stockfish_FEN_Analysis_Thread(),1)
        Delay(1250)                                                   ; empirical value via testing to help engine thread syncing
        
        MovePathCursor(#doc_offset*2, #demo_y_offset + PDFSquareSize*10)
        DrawVectorText("[...engine analysis...]")
  
        MovePathCursor(#doc_offset, #demo_y_offset + PDFSquareSize*11)
        DrawVectorParagraph("pv = " + pvstring(1) + Space(2) + "eval = " + cpscore_str(1), 200, 200)
        NewVectorPage()
        
      EndIf
    EndIf
  Next
EndIf
If k < Games_Export_Count
  NewVectorPage()
EndIf
Next

StopVectorDrawing()

;CloseFile(FileID)

SetGadgetText(#Info_Field, "Text file: " + PDFFilename + " created successfully.")
Delay(500)
  
  
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
              ;PrintN("Mouse moved to (" + StrF(location\x, 1) + "," + StrF(WindowHeight(#mainwin)-location\y, 1) + ")"); use WindowHeight() to flip y coordinate
              PrintN("You clicked in mailbox square = " + Str(mailbox_editor_squareXY))
              If mailbox_editor_squareXY >= 21 And mailbox_editor_squareXY <= 98
                MbxBrd(mailbox_editor_squareXY) = Mailbox_editor_piece
                BoardDisplay() ;: FreeBoardEditorGadgets() : BoardEditorDisplay()
              EndIf
            Case #NSMouseMoved
              CocoaMessage(@location, currentEvent, "locationInWindow")
              CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
                ;PrintN("Mouse moved to (" + StrF(location\x, 1) + "," + StrF(WindowHeight(#mainwin)-location\y, 1) + ")"); use WindowHeight() to flip y coordinate
              CompilerEndIf
              If location\x >= 135 And location\x <= 195 And #mainwinDefaultHeight-location\y >= #canvas_gadgetY And #mainwinDefaultHeight-location\y <= #canvas_gadgetY + SquareSize
                PrintN("You are in mailbox square 21")
              EndIf
            Case #NSControlKeyMask+#NSMouseMoved
              PrintN("Control key pressed")
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
    PrintN("New game position addition = " + GameLink + Space(2) + WhitePlayer + Space(2) + BlackPlayer + Space(2) + Info_Result)
    AddGadgetItem(#Players_ListIcon_Gadget, -1, GameLink + Chr(10) + WhitePlayer + Chr(10) + BlackPlayer + Chr(10) + "20990101" + Chr(10) + Info_Description + Chr(10) + Info_Result)
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
    
    cpscore_normal_pos = 0
    cpscore_mate_pos = 0
    cpscore_normal_pos = FindString(response2, "score cp", 1)
    cpscore_mate_pos = FindString(response2, "score mate", 1)   ; allow score string to show mate scores
    
    nodes = FindString(response2, "nodes", 1)
    If pvb > 0
      pvstring(MultiPV) = Mid(response2, pvb+3,90)
      If cpscore_mate_pos > 0
        pvstring(MultiPV) = Trim(pvstring(MultiPV),Space(1)) + "#"
      EndIf
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN("")
        PrintN("pvstring" + "(" + Str(multipv) + ") = " + pvstring(MultiPV))
        PrintN("")
      CompilerEndIf
    EndIf
    
    If cpscore_normal_pos > 0
      cpscore_str(MultiPV) = Trim(Mid(response2, cpscore_normal_pos+9, nodes-cpscore_normal_pos-9), Space(1))
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN("")
        PrintN("score(" + Str(MultiPV) + ") = " + cpscore_str(MultiPV))
        PrintN("")
      CompilerEndIf
    EndIf
    
    If cpscore_mate_pos > 0
      cpscore_str(MultiPV) = "mate " + Trim(Mid(response2, cpscore_mate_pos+11, nodes-cpscore_mate_pos-11), Space(1))
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN("")
        PrintN("score(" + Str(MultiPV) + ") = " + cpscore_str(MultiPV))
        PrintN("")
      CompilerEndIf
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


Procedure LoadSampleGames()

  Protected i.i
  ;#sample_games = 20
  
  ; sample game 1
  EventSites(1) = "WCC31-Moscow" : GameDates(1) = "19840910" :  WhitePlayers(1) = "Karpov, Anatoly   G#1" : WhiteElos(1) = "2705" : BlackPlayers(1) = "Kasparov, Garry   G#1" : BlackElos(1) = "2715" : Each_Game_Result(1) = "1-0"
  
  FilePGNs(1) = "1. d4 d5 2. c4 e6 3. Nf3 c5 4. cxd5 exd5 5. g3 Nf6 6. Bg2 Be7 7. O-O O-O 8. Nc3 Nc6 9. Bg5 cxd4 10. Nxd4 h6 11. Be3 Re8 12. Qb3 Na5 13. Qc2 Bg4 14. Nf5 Rc8 15. Bd4 Bc5 16. Bxc5 Rxc5 17. Ne3 Be6 18. Rad1 Qc8 19. Qa4 Rd8 20. Rd3 a6 21. Rfd1 Nc4 22. Nxc4 Rxc4 23. Qa5 Rc5 24. Qb6 Rd7 25. Rd4 Qc7 26. Qxc7 Rdxc7 27. h3 h5 28. a3 g6 29. e3 Kg7 30. Kh2 Rc4 31. Bf3 b5 32. Kg2 R7c5 33. Rxc4 Rxc4 34. Rd4 Kf8 35. Be2 Rxd4 36. exd4 Ke7 37. Na2 Bc8 38. Nb4 Kd6 39. f3 Ng8 40. h4 Nh6 41. Kf2 Nf5 42. Nc2 f6 43. Bd3 g5 44. Bxf5 Bxf5 45. Ne3 Bb1 46. b4 gxh4 47. Ng2 $1 hxg3+ 48. Kxg3 Ke6 49. Nf4+ Kf5 50. Nxh5 Ke6 51. Nf4+ Kd6 52. Kg4 Bc2 53. Kh5 Bd1 54. Kg6 Ke7 55. Nxd5+ Ke6 56. Nc7+ Kd7 57. Nxa6 Bxf3 58. Kxf6 Kd6 59. Kf5 Kd5 60. Kf4 Bh1 61. Ke3 Kc4 62. Nc5 Bc6 63. Nd3 Bg2 64. Ne5+ Kc3 65. Ng6 Kc4 66. Ne7 Bb7 67. Nf5 Bg2 68. Nd6+ Kb3 69. Nxb5 Ka4 70. Nd6 1-0"
  
  ; sample game 2
  EventSites(2) = "WCC20-Moscow" : GameDates(2) = "19540415" :  WhitePlayers(2) = "Botvinnik, Mikhail   G#2" : WhiteElos(2) = "n/a" : BlackPlayers(2) = "Smyslov, Vassily   G#2" : BlackElos(2) = "n/a" : Each_Game_Result(2) = "0-1"

  FilePGNs(2) = "1. d4 Nf6 2. c4 g6 3. g3 Bg7 4. Bg2 O-O 5. Nc3 d6 6. Nf3 Nbd7 7. O-O e5 8. e4 c6 9. Be3 Ng4 $1 10. Bg5 Qb6 11. h3 exd4 $1 12. Na4 Qa6 13. hxg4 b5 14. Nxd4 bxa4 15. Nxc6 Qxc6 16. e5 Qxc4 17. Bxa8 Nxe5 18. Rc1 Qb4 19. a3 Qxb2 20. Qxa4 Bb7 $1 21. Rb1 Nf3+ 22. Kh1 Bxa8 23. Rxb2 Nxg5+ 24. Kh2 Nf3+ 25. Kh3 Bxb2 26. Qxa7 Be4 27. a4 Kg7 28. Rd1 Be5 29. Qe7 Rc8 30. a5 Rc2 31. Kg2 Nd4+ 32. Kf1 Bf3 33. Rb1 Nc6 0-1"
  
  ; sample game 3
  EventSites(3) = "Dortmund-Blitz" : GameDates(3) = "20040727" :  WhitePlayers(3) = "Kramnik, Vladimir   G#3" : WhiteElos(3) = "n/a" : BlackPlayers(3) = "Bologan, Victor   G#3" : BlackElos(3) = "n/a" : Each_Game_Result(3) = "1-0"
  
  FilePGNs(3) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 a6 5. c4 Nf6 6. Nc3 d6 7. Be2 Nbd7 8. Be3 b6 9. O-O Bb7 10. f3 Be7 11. a4 O-O 12. a5 bxa5 13. Nb3 Rb8 14. Nxa5 Ba8 15. Qd2 Qc7 16. Rfc1 Nc5 17. b4 Ncd7 18. b5 Nc5 19. bxa6 Nxa6 20. Nb5 Qd7 21. Nb3 Bb7 22. Rd1 Rfd8 23. Ba7 Ra8 24. Bb6 Rdb8 25. Nxd6 Bxe4 26. Nxe4 Qxd2 27. Nexd2 Rxb6 28. c5 1-0"
  
  ; sample game 4
  EventSites(4) = "Sofia-Masters" : GameDates(4) = "20050512" :  WhitePlayers(4) = "Kramnik, Vladimir   G#4" : WhiteElos(4) = "2752" : BlackPlayers(4) = "Polgar, Judit   G#4" : BlackElos(4) = "2732" : Each_Game_Result(4) = "1-0"
  
  FilePGNs(4) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 O-O 5. a3 Bxc3+ 6. Qxc3 b6 7. Nf3 Bb7 8. e3 d6 9. Be2 Nbd7 10. O-O Ne4 11. Qc2 f5 12. b4 Rf6 13. d5 Rg6 14. Nd4 Qg5 15. g3 exd5 16. cxd5 Bxd5 17. Bc4 Bxc4 18. Qxc4+ Kh8 19. Qc6 Rd8 20. Qxc7 Ne5 21. Ra2 Rf8 22. f4 Qg4 23. Qe7 Rg8 24. Rg2 Nd3 25. Qxa7 h5 26. Qa6 Nxc1 27. Rxc1 h4 28. Qe2 Qxe2 29. Rxe2 hxg3 30. Nxf5 gxh2+ 31. Kh1 Rg1+ 32. Rxg1 hxg1=Q+ 33. Kxg1 Ra8 34. Ra2 Nc3 35. Rh2+ Kg8 36. Rg2 Kf7 37. Nxd6+ Ke6 38. Nc4 b5 39. Na5 Kf6 40. Rd2 g5 41. Rd3 Ne4 42. fxg5+ Kxg5 43. Kg2 Rf8 44. Rd5+ Kg4 45. Rd4 Kf5 46. Nc6 Rg8+ 47. Kf1 Ra8 48. Ne7+ Ke5 49. Nc6+ Kf5 50. Ne7+ Ke5 51. Ng6+ Kf5 52. Nh4+ Ke5 53. Nf3+ Kf5 54. Nh4+ Ke5 55. Nf3+ Kf5 56. Rd5+ Kf6 57. Rd3 Rh8 58. Ke2 Ke7 59. Nd4 Rh2+ 60. Kf3 Nd6 61. Rc3 Rh3+ 62. Kg4 1-0"
  
  ; sample game 5
  EventSites(5) = "Sofia-Masters" : GameDates(5) = "20050518" :  WhitePlayers(5) = "Topalov, Veselin   G#5" : WhiteElos(5) = "2778" : BlackPlayers(5) = "Anand, Vishay   G#5" : BlackElos(5) = "2785" : Each_Game_Result(5) = "1-0"
  
  FilePGNs(5) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Ba6 5. b3 Bb4+ 6. Bd2 Be7 7. Nc3 c6 8.e4 d5 9. Qc2 dxe4 10. Nxe4 Bb7 11. Neg5 c5 12. d5 exd5 13. cxd5 h6 14. Nxf7 Kxf7 15. O-O-O Bd6 16. Nh4 Bc8 17. Re1 Na6 18. Re6 Nb4 19. Bxb4 cxb4 20. Bc4 b5 21. Bxb5 Be7 22. Ng6 Nxd5 23. Rxe7+ Nxe7 24. Bc4+ Kf6 25. Nxh8 Qd4 26. Rd1 Qa1+ 27. Kd2 Qd4+ 28. Ke1 Qe5+ 29. Qe2 Qxe2+ 30. Kxe2 Nf5 31. Nf7 a5 32. g4 Nh4 33. h3 Ra7 34. Rd6+ Ke7 35. Rb6 Rc7 36. Ne5 Ng2 37. Ng6+ Kd8 38. Kf1 Bb7 39. Rxb7 Rxb7 40. Kxg2 Rd7 41. Nf8 Rd2 42. Ne6+ Ke7 43. Nxg7 Rxa2 44. Nf5+ Kf6 45. Nxh6 Rc2 46. Bf7 Rc3 47. f4 a4 48. bxa4 b3 49. g5+ Kg7 50. f5 b2 51. f6+ Kh7 52. Nf5 1-0"
  
  ; sample game 6
  EventSites(6) = "Wijk aan Zee" : GameDates(6) = "19990120" :  WhitePlayers(6) = "Kasparov, Garry   G#6" : WhiteElos(6) = "2812" : BlackPlayers(6) = "Topalov, Veselin   G#6" : BlackElos(6) = "2700" : Each_Game_Result(6) = "1-0"
  
  FilePGNs(6) = "1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. Be3 Bg7 5. Qd2 c6 6. f3 b5 7. Nge2 Nbd7 8. Bh6 Bxh6 9. Qxh6 Bb7 10. a3 e5 11. O-O-O Qe7 12. Kb1 a6 13. Nc1 O-O-O 14. Nb3 exd4 15. Rxd4 c5 16. Rd1 Nb6 17. g3 Kb8 18. Na5 Ba8 19. Bh3 d5 20. Qf4+ Ka7 21. Rhe1 d4 22. Nd5 Nbxd5 23. exd5 Qd6 24. Rxd4 cxd4 25. Re7+ Kb6 26. Qxd4+ Kxa5 27. b4+ Ka4 28. Qc3 Qxd5 29. Ra7 Bb7 30. Rxb7 Qc4 31. Qxf6 Kxa3 32. Qxa6+ Kxb4 33. c3+ Kxc3 34. Qa1+ Kd2 35. Qb2+ Kd1 36. Bf1 Rd2 37. Rd7 Rxd7 38. Bxc4 bxc4 39. Qxh8 Rd3 40. Qa8 c3 41. Qa4+ Ke1 42. f4 f5 43. Kc1 Rd2 44. Qa7 1-0"
  
  ; sample game 7
  EventSites(7) = "KasparovChessGP" : GameDates(7) = "20000210" :  WhitePlayers(7) = "Gulko, Boris   G#7" : WhiteElos(7) = "2644" : BlackPlayers(7) = "Adams, Michael   G#7" : BlackElos(7) = "2715" : Each_Game_Result(7) = "0-1"
  
  FilePGNs(7) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 O-O 5. Bd3 d5 6. a3 Bxc3+ 7. bxc3 dxc4 8. Bxc4 c5 9. Nf3 Qa5 10. Bd2 Qc7 11. Bd3 b6 12. e4 Ba6 13. Bxa6 Nxa6 14. Qe2 Qb7 15. e5 Ne4 16. O-O Rfd8 17. Rfd1 cxd4 18. cxd4 Nxd2 19. Rxd2 h6 20. Rc1 Nc7 21. Rdc2 Nd5 22. g3 Rac8 23. Qd3 Rxc2 24. Rxc2 b5 25. Rc5 a6 26. Qe4 b4 27. axb4 Qxb4 28. Qe1 Qb3 29. Kg2 Rb8 30. Qc1 Kh7 31. h4 Ra8 32. Ra5 Qb7 33. h5 Kg8 34. Qc2 Rc8 35. Rc5 Rb8 36. Qc4 Qa8 37. Ra5 Ne3+ 38. fxe3 Rb2+ 0-1"

  ; sample game 8
  EventSites(8) = "WCC-BGN London" : GameDates(8) = "20010210" :  WhitePlayers(8) = "Kramnik, Vladimir   G#8" : WhiteElos(8) = "2770" : BlackPlayers(8) = "Kasparov, Garry   G#8" : BlackElos(8) = "2849" : Each_Game_Result(8) = "1-0"
  
  FilePGNs(8) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. e4 Nxc3 6. bxc3 Bg7 7. Nf3 c5 8. Be3 Qa5 9. Qd2 Bg4 10. Rb1 a6 11. Rxb7 Bxf3 12. gxf3 Nc6 13. Bc4 O-O 14. O-O cxd4 15. cxd4 Bxd4 16. Bd5 Bc3 17. Qc1 Nd4 18. Bxd4 Bxd4 19. Rxe7 Ra7 20. Rxa7 Bxa7 21. f4 Qd8 22. Qc3 Bb8 23. Qf3 Qh4 24. e5 g5 25. Re1 Qxf4 26. Qxf4 gxf4 27. e6 fxe6 28. Rxe6 Kg7 29. Rxa6 Rf5 30. Be4 Re5 31. f3 Re7 32. a4 Ra7 33. Rb6 Be5 34. Rb4 Rd7 35. Kg2 Rd2+ 36. Kh3 h5 37. Rb5 Kf6 38. a5 Ra2 39. Rb6+ Ke7 40. Bd5 1-0"
  
  ; sample game 9
  EventSites(9) = "Linares-19" : GameDates(9) = "20020309" :  WhitePlayers(9) = "Kasparov, Garry   G#9" : WhiteElos(9) = "2838" : BlackPlayers(9) = "Ponomariov, Ruslan   G#9" : BlackElos(9) = "2727" : Each_Game_Result(9) = "1-0"
  
  FilePGNs(9) = "1. e4 e6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Nd7 5. Nf3 Ngf6 6. Nxf6+ Nxf6 7. c3 c5 8. Ne5 Nd7 9. Bb5 Bd6 10. Qg4 Kf8 11. O-O $5 Nxe5 12. dxe5 Bxe5 13. Bg5 Bf6 14. Rad1 Qc7 15. Qh4 Bxg5 16. Qxg5 f6 17. Qh5 g6 18. Qh6+ Kf7 19. Rd3 a6 20. Rh3 Qe7 21. Bd3 f5 22. g4 Qf6 23. Rd1 b5 24. Be2 e5 25. Rhd3 Ra7 26. Rd6 Qg7 27. Qe3 Rc7 28. a4 e4 29. axb5 axb5 30. Bxb5 Qe5 31. Qg5 Qe7 32. Qh6 Be6 33. Qf4 Bc8 34. Qh6 Be6 35. gxf5 gxf5 36. Be2 Qf6 37. Bh5+ Ke7 38. Rxe6+ 1-0"
  
  ; sample game 10
  EventSites(10) = "JBorowski-4th" : GameDates(10) = "20020525" :  WhitePlayers(10) = "Kasimdzhanov, Rustam   G#10" : WhiteElos(10) = "2675" : BlackPlayers(10) = "Kortschnoj, Viktor   G#10" : BlackElos(10) = "2635" : Each_Game_Result(10) = "1-0"
  
  FilePGNs(10) = "1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. Bg5 dxe4 5. Nxe4 Nbd7 6. Nxf6+ Nxf6 7. Nf3 c5 8. Bc4 Qa5+ 9. c3 Be7 10. O-O O-O 11. Re1 h6 12. Bh4 Rd8 13. Qe2 cxd4 14. Nxd4 Bd7 15. Rad1 Kh8 16. Rd3 Ng8 17. Bg3 Rac8 18. Rf3 Bf6 19. Bd3 Qd5 20. Be4 Qxa2 21. Bb1 Qd5 22. Qd3 g6 23. Rxf6 Nxf6 24. Be5 Kg7 25. Qg3 Qc5 26. Re3 Bc6 27. Bxg6 fxg6 28. Bxf6+ Kh7 29. Bxd8 Rxd8 30. Rxe6 Qg5 31. Qxg5 hxg5 32. Re7+ Kh6 33. h3 Bd5 34. Nc2 1-0"
  
  ; sample game 11
  EventSites(11) = "EU-Cup 18th" : GameDates(11) = "20020928" :  WhitePlayers(11) = "Motylev, Alexander   G#11" : WhiteElos(11) = "2634" : BlackPlayers(11) = "Polgar, Judit   G#11" : BlackElos(11) = "2681" : Each_Game_Result(11) = "0-1"
  
  FilePGNs(11) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Qb6 5. Nb3 Nf6 6. Nc3 e6 7. Qe2 Bb4 8. Bd2 O-O 9. a3 Be7 10. O-O-O d5 11. exd5 Nxd5 12. Nxd5 exd5 13. Bc3 Be6 14. Qf3 Rac8 15. Qg3 g6 16. h4 Rfd8 17. h5 d4 18. hxg6 hxg6 19. Nxd4 Nxd4 20. Rxd4 Rxc3 21. bxc3 Rxd4 22. cxd4 Qxd4 23. c3 Qc5 24. Kd2 Bg5+ 25. Kc2 Kg7 26. Bd3 Bf6 27. Rb1 Qxc3+ 28. Kd1 Bg5 29. Ke2 Bg4+ 30. Kf1 Bf4 0-1"
  
  ; sample game 12
  EventSites(12) = "FIDE WCup Hyderabad" : GameDates(12) = "20021020" :  WhitePlayers(12) = "Anand, Vishy   G#12" : WhiteElos(12) = "2755" : BlackPlayers(12) = "Kasimdzhanov, Rustam   G#12" : BlackElos(12) = "2653" : Each_Game_Result(12) = "1-0"
  
  FilePGNs(12) = "1. e4 e5 2. Nf3 Nf6 3. Nxe5 d6 4. Nf3 Nxe4 5. d4 d5 6. Bd3 Bd6 7. O-O O-O 8. c4 c6 9. Qc2 Na6 10. a3 Re8 11. Nc3 Bf5 12. Re1 h6 13. c5 Bc7 14. Bd2 Ba5 15. Bf4 Bxc3 16. bxc3 Nc7 17. h3 Ne6 18. Bh2 N6g5 19. Ne5 f6 20. Ng4 Qa5 21. Ne3 Be6 22. Rac1 Nxh3+ 23. gxh3 Bxh3 24. Nc4 Qxc3 25. Qxc3 Nxc3 26. Nd6 Rxe1+ 27. Rxe1 b5 28. Re3 Bg4 29. Bf5 1-0"
  
  ; sample game 13
  EventSites(13) = "Dortmund SuperGM" : GameDates(13) = "20030806" :  WhitePlayers(13) = "Bologan, Viktor   G#13" : WhiteElos(13) = "2650" : BlackPlayers(13) = "Naiditsch, Arkadij   G#13" : BlackElos(13) = "2574" : Each_Game_Result(13) = "1-0"
  
  FilePGNs(13) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. c3 d5 9. exd5 Nxd5 10. Nxe5 Nxe5 11. Rxe5 c6 12. d4 Bd6 13. Re1 Qh4 14. g3 Qh3 15. Qf3 Be6 16. Qg2 Qh5 17. Bd1 Qg6 18. Nd2 Rae8 19. Ne4 Bf5 20. f3 c5 21. Bd2 cxd4 22. cxd4 Bb8 23. Bb3 Rd8 24. Nc5 h5 25. Rac1 h4 26. gxh4 Qh5 27. Ne4 Bxe4 28. Rxe4 Nf6 29. Re7 Rxd4 30. Bg5 Nd5 31. Qf2 Rd3 32. Qe2 Rxb3 33. Re8 Ba7+ 34. Kh1 Rxf3 35. Rxf8+ Kh7 36. Qe4+ 1-0"
  
  ; sample game 14
  EventSites(14) = "EU-chT-Men" : GameDates(14) = "20031012" :  WhitePlayers(14) = "Svidler, Peter   G#14" : WhiteElos(14) = "2737" : BlackPlayers(14) = "Shirov, Alexei   G#14" : BlackElos(14) = "2723" : Each_Game_Result(14) = "1-0"
  
  FilePGNs(14) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Be3 Qb6 5. Qc1 Nh6 6. Nf3 e6 7. Nbd2 c5 8. Nb3 Nd7 9. dxc5 Nxc5 10. Nfd4 Ng4 11. Bb5+ Kd8 12. O-O Nxe3 13. Qxe3 Bg6 14. Rfd1 Kc7 15. c4 dxc4 16. Bxc4 Rc8 17. Nd2 Kb8 18. Bb5 a6 19. Be2 Na4 20. Nc4 Rxc4 21. Bxc4 Nxb2 22. Nxe6 Qxe3 23. Rd8+ Ka7 24. fxe3 fxe6 25. Bxe6 1-0"
  
  ; sample game 15
  EventSites(15) = "EU-chT-Men" : GameDates(15) = "20031019" :  WhitePlayers(15) = "Jobava, Baadur   G#15" : WhiteElos(15) = "2675" : BlackPlayers(15) = "Grischuk, Alexander   G#15" : BlackElos(15) = "2732" : Each_Game_Result(15) = "0-1"
  
  FilePGNs(15) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. b4 Bxb4 5. c3 Bd6 6. d4 Nf6 7. O-O O-O 8. Re1 h6 9. Nh4 exd4 10. Nf5 Bc5 11. cxd4 d5 12. exd5 Bxf5 13. dxc5 Na5 14. Bb3 Nxb3 15. Qxb3 Qxd5 $17 16. Nc3 Rfe8 17. Be3 Qc6 18. Qb5 Qxb5 19. Nxb5 Nd5 20. Bd2 Red8 21. Rac1 Bg6 22. a3 c6 23. Nd6 b6 24. Nc4 f6 25. f3 Bd3 26. Nb2 Bg6 27. Nc4 Rac8 28. Red1 Rd7 29. Be3 Rcd8 30. cxb6 axb6 31. Bf2 b5 $19 32. Na5 Nf4 33. Rxd7 Rxd7 34. Ra1 Rd6 35. Be3 Nd3 36. a4 Re6 37. Bd2 Re2 38. Ra2 Bf7 39. Rc2 b4 40. Kf1 Rf2+ 41. Kg1 b3 42. Rb2 Nxb2 0-1"
  
  ; sample game 16
  EventSites(16) = "RUS-chT" : GameDates(16) = "20040421" :  WhitePlayers(16) = "Morozevich, Alexander   G#16" : WhiteElos(16) = "2732" : BlackPlayers(16) = "Bologan, Viktor   G#16" : BlackElos(16) = "2665" : Each_Game_Result(16) = "1-0"
  
  FilePGNs(16) = "1. e4 c6 2. d4 d5 3. f3 e6 4. Nc3 Bb4 5. Bf4 Ne7 6. Qd3 b6 7. N1e2 Ba6 8. Qe3 O-O 9. O-O-O c5 10. a3 Bxc3 11. Qxc3 Bxe2 12. Bxe2 c4 13. h4 b5 14. Qe1 Nbc6 15. h5 Qd7 16. g4 f6 17. Bf1 Rad8 18. Bh3 dxe4 19. fxe4 Nxd4 20. g5 f5 21. Kb1 Qc6 22. h6 fxe4 23. Qc3 e3 24. Rxd4 Qxh1+ 25. Ka2 Qxh3 26. Rxd8 gxh6 27. gxh6 Qg4 28. Qh8+ 1-0"
  
  ; sample game 17
  EventSites(17) = "Rilton Cup 34" : GameDates(17) = "20050103" :  WhitePlayers(17) = "Ulibin, Mikhail   G#17" : WhiteElos(17) = "2556" : BlackPlayers(17) = "Cramling, Pia   G#17" : BlackElos(17) = "2477" : Each_Game_Result(17) = "0-1"
  
  FilePGNs(17) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 Qc7 6. f4 a6 7. Nb3 b5 8. Bd3 d6 9. Be3 Nf6 10. Qf3 Bb7 11. O-O h5 12. Kh1 Be7 13. a4 b4 14. Nd1 d5 15. Nf2 dxe4 16. Nxe4 Nxe4 17. Qxe4 Na5 18. Qd4 Nxb3 19. cxb3 Rd8 $3 20. Qxg7 Bf6 21. Qxf6 Rg8 22. Rg1 Rxd3 23. Bf2 Rd2 24.Bg3 Bd5 25. Qh4 Qb7 26. h3 Bxg2+ 27. Kh2 Bf1+ 0-1"
  
  ; sample game 18
  EventSites(18) = "FIDE WorldCup" : GameDates(18) = "20051130" :  WhitePlayers(18) = "Cheparinov, Ivan   G#18" : WhiteElos(18) = "2618" : BlackPlayers(18) = "Ivanchuk, Vassily   G#18" : BlackElos(18) = "2750" : Each_Game_Result(18) = "1-0"
  
  FilePGNs(18) = "1. d4 Nf6 2. c4 c5 3. d5 b5 4. cxb5 a6 5. b6 d6 6. Nc3 Nbd7 7. a4 a5 8. e4 g6 9. Nf3 Bg7 10. Be2 O-O 11. O-O Qxb6 12. Nd2 Ba6 13. Nb5 Rfb8 14. Qc2 Qd8 15. Nc4 Nb6 16. Nca3 Ne8 17. Rb1 Nc7 18. b3 Bxb5 19. Nxb5 Na6 20. Bg5 Nb4 21. Qd2 Qd7 22. f4 Rb7 23. f5 Qe8 24. Rf3 Nd7 25. Rbf1 Be5 26. Rh3 f6 27. Be3 g5 28. g4 Rc8 29. Bc4 Bd4 30. Nxd4 cxd4 31. Bxg5 Ne5 32. Bh6 d3 33. g5 Qf7 34. Rg3 Kh8 35. g6 hxg6 36. fxg6 Nxg6 37. Rf5 Ne5 38. Bf8 Qh7 39. Bg7+ Qxg7 40. Rh5+ Kg8 41. Rxg7+ Kxg7 42. Qh6+ Kf7 43. Qh7+ Ke8 44. Qf5 1-0"
  
  ; sample game 19
  
  EventSites(19) = "FIDE WorldCup" : GameDates(19) = "20051206" :  WhitePlayers(19) = "Grischuk, Alexander   G#19" : WhiteElos(19) = "2720" : BlackPlayers(19) = "Kamsky, Gata   G#19" : BlackElos(19) = "2690" : Each_Game_Result(19) = "1-0"
  
  FilePGNs(19) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. h3 Bb7 9. d3 d6 10. a3 h6 11. Nc3 Re8 12. Nd5 Nxd5 13. Bxd5 Qc8 14. c3 Nd8 15. d4 Bf6 16. Nh2 exd4 17. Ng4 Bg5 18. cxd4 Bxd5 19. exd5 Rxe1+ 20. Qxe1 Kf8 21. Bxg5 hxg5 22. Qe3 f6 23. Re1 Qd7 24. h4 Nf7 25. Qe6 Rd8 26. h5 f5 27. Nf6 gxf6 28. Qxf6 Re8 29. Re6 Qd8 30. Qxf5 g4 31. Rf6 Re7 32. h6 Qd7 33. Qg6 1-0"
  
  ; sample game 20
  EventSites(20) = "Corus-WijkaanZee" : GameDates(20) = "20060124" :  WhitePlayers(20) = "Karjakin, Sergey   G#20" : WhiteElos(20) = "2690" : BlackPlayers(20) = "Topalov, Veselin   G#20" : BlackElos(20) = "2801" : Each_Game_Result(20) = "0-1"
  
  FilePGNs(20) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5 6. Ndb5 d6 7. Bg5 a6 8. Na3 b5 9. Nd5 Be7 10. Bxf6 Bxf6 11. c3 Bg5 12. Nc2 O-O 13. a4 bxa4 14. Rxa4 a5 15. Bc4 Rb8 16. Ra2 Kh8 17. Nce3 Bxe3 18. Nxe3 Ne7 19. b3 f5 20. exf5 Nxf5 21. Nd5 Bb7 22. O-O Rc8 23. Qd3 Nh4 24. Rd1 h6 25. Qg3 Nf5 26. Qg4 Rc5 27. Rad2 Bc8 28. Qe4 Bb7 29. h3 Nh4 30. Bd3 Rf5 31. Bb1 Rxc3 32. Qg4 h5 33. Qe2 Qg5 $19 34. f4 Rxf4 35. Kh1 Nxg2 36. Qxg2 Rg3 37. Nxf4 Bxg2+ 38. Nxg2 Rxh3+ 39. Kg1 Rg3 40. Rf2 Kg8 41. Rxd6 h4 42. Rc6 Qg4 43. Bf5 Rxg2+ 44. Rxg2 Qxf5 45. Rcg6 Qf7 46. R6g4 Qf6 47. Kh2 Kf7 48. Kh3 e4 49. Rg5 e3 50. Kxh4 g6 0-1"
  
  ; sample game 21
EventSites(21) = "World Championship 08th  Germany" : GameDates(21) = "19080824" : WhitePlayers(21) = "Tarrasch, Siegbert   G#21" : WhiteElos(21) = "n/a" : BlackPlayers(21) = "Lasker, Emanuel   G#21" : BlackElos(21) = "n/a" : Each_Game_Result(21) = "0-1"

FilePGNs(21) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O d6 5. d4 Bd7 6. Nc3 Be7 7. Re1 exd4 8. Nxd4 Nxd4 9. Qxd4 Bxb5 10. Nxb5 O-O 11. Bg5 h6 12. Bh4 Re8 13. Rad1 Nd7 14. Bxe7 Rxe7 15. Qc3 Re5  16. Nd4 Rc5 17. Qb3 Nb6 18. f4 Qf6 19. Qf3 Re8 20. c3 a5 21. b3 a4 22. b4  Rc4 23. g3 Rd8 24. Re3 c5 25. Nb5  cxb4 26. Rxd6 Rxd6 27. e5 Rxf4  28. gxf4 Qg6+ 29. Kh1 Qb1+ 30. Kg2 Rd2+ 31. Re2 Qxa2 32. Rxd2 Qxd2+ 33. Kg3 a3 34. e6 Qe1+ 35. Kg4 Qxe6+ 36. f5 Qc4+ 37. Nd4 a2 38. Qd1 Nd5 39. Qa4 Nxc3 40. Qe8+ Kh7 41. Kh5 a1=Q 0-1 "

; sample game 22
EventSites(22) = "St Petersburg preliminary  St . Petersburg" : GameDates(22) = "19140421" : WhitePlayers(22) = "Blackburne, Joseph Henry   G#22" : WhiteElos(22) = "n/a" : BlackPlayers(22) = "Lasker, Emanuel   G#22" : BlackElos(22) = "n/a" : Each_Game_Result(22) = "0-1"

FilePGNs(22) = "1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Bc5 5. Be3 Qf6 6. c3 Nge7 7. Nc2 b6  8. Nd2 Qg6 9. Bxc5 bxc5 10. Ne3 Rb8 11. b3 O-O 12. Bc4 d6  13. f4  Qf6  14. O-O  Qxc3  15. Rf3 Qd4 16. Kh1 Be6 17. Rc1 Bxc4 18. Rxc4 Qb2 19. Rc2 Qf6 20. Ng4 Qg6 21. Rg3 f5  22. Ne5 Qe6 23. Nxc6 Nxc6 24. e5 Nb4 25. Rc4 dxe5 26. Qa1 Qd7   27. Nf3 exf4 28. Ne5 Qe7 29. Rxf4 Rbe8 30. Nc4 Qe1+ 31. Rf1 Qxa1 32. Rxa1 Nxa2 33. h3 f4 34. Rd3 Nb4 35. Rd7 f3 36. gxf3  Rxf3 37. Rxa7 Nd3 38. Ra1 Ne1 39. Nd2 Rxh3+ 40. Kg1 Rg3+ 41. Kh2 Rd3 42. Rxe1 Rxd2+ 43. Rxd2 Rxe1 44. Rd7 Re3 45. Rxc7 Rxb3 46. Rxc5 h6 47. Rc6 Kh7 48. Kg2 h5 49. Ra6 g6 50. Ra4 Kh6 51. Rc4 Rb5 52. Kg3 Kg5 53. Rc3 h4+ 54. Kh3 Kh5 55. Rc4 Rb3+ 56. Kh2 g5 57. Ra4 Rb2+ 58. Kh1 h3 59. Rc4 g4 60. Kg1 g3 61. Rc5+ Kg6 62. Rc1 Kf5 63. Ra1 Rd2 64. Re1 Kf4 65. Ra1 Ke3 66. Ra3+ Rd3 67. Ra1 Ke2 0-1 "

; sample game 23
EventSites(23) = "St Petersburg preliminary  St . Petersburg" : GameDates(23) = "19140422" : WhitePlayers(23) = "Lasker, Emanuel   G#23" : WhiteElos(23) = "n/a" : BlackPlayers(23) = "Nimzowitsch, Aaron   G#23" : BlackElos(23) = "n/a" : Each_Game_Result(23) = "1/2-1/2"

FilePGNs(23) = "1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Nf6 5. Nxf6+ gxf6 6. Be2 Bf5 7. Bf3 Qa5+ 8. c3 h5  9. Bxh5 Nd7 10. Bg4 Bxg4 11. Qxg4 O-O-O  12. Ne2 e6 13. Bf4 Qb5 14. O-O-O Nb6 15. Ng3  Qd5 16. Kb1 Qxg2 17. Rdg1  Qxf2 18. Ne4 Qh4  19. Qf3 Nc4 20. Ka1 f5 21. Ng5 Bd6 22. Bc1 Rd7 23. Rg2 Bc7 24. Rhg1 Nd6 25. Qe2 Ne4  26. Nf3 Qh3 27. a3  a6 28. Be3 Rhd8 29. Ka2 Rh8 30. Ka1 Rhd8 31. Ka2 Re8 32. Rg8 Rxg8 33. Rxg8+ Rd8 34. Rg7 Rd7 35. Rg8+ Rd8 36. Rg7 Rf8 37. c4 Nf6  38. Bg5 Nh5  39. Rxf7  Rxf7 40. Qxe6+ Rd7 41. Ne5 Bxe5  42. Qe8+ 1/2-1/2 "

; sample game 24
EventSites(24) = "St Petersburg preliminary  St . Petersburg" : GameDates(24) = "19140424" : WhitePlayers(24) = "Marshall, Frank James   G#24" : WhiteElos(24) = "n/a" : BlackPlayers(24) = "Lasker, Emanuel   G#24" : BlackElos(24) = "n/a" : Each_Game_Result(24) = "1/2-1/2"

FilePGNs(24) = "1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. Bg5 Be7 5. e3 Nbd7 6. Nf3 c6 7. Bd3 dxc4 8. Bxc4 b5 9. Bd3 a6 10. O-O c5 11. Qe2 O-O 12. Rad1 c4  13. Bb1 Nd5  14. Bxe7 Qxe7 15. e4 N5b6  16. e5 Bb7 17. Rfe1 Rfd8 18. Nd2 Rac8 19. Nde4 Bxe4 20. Nxe4 Rc7 21. Qh5 Nf8 22. Re3 Nd5 23. Rf3 f5  24. exf6  gxf6 25. Re1   Qb4 26. Kf1 Qxb2 27. Nxf6+ Nxf6 28. Rxf6 Qxd4  29. Qf3 Rg7 30. h3 Qd6  31. Bf5 Re8 32. Bxe6+  Rxe6 33. Rxf8+ Qxf8 34. Qd5  Qd6 35. Qxe6+ Qxe6 36. Rxe6 Rc7 37. Ke1 c3 38. Kd1 Rd7+ 39. Kc1 Rd2 40. Rxa6 Rxf2 41. Rb6 Rxa2 42. Rxb5 Rxg2 43. Rc5 Rg3 44. h4 Kg7 45. Kc2 Kg6 46. Rxc3 1/2-1/2 "

; sample game 25
EventSites(25) = "St Petersburg preliminary  St . Petersburg" : GameDates(25) = "19140426" : WhitePlayers(25) = "Lasker, Emanuel   G#25" : WhiteElos(25) = "n/a" : BlackPlayers(25) = "Rubinstein, Akiba   G#25" : BlackElos(25) = "n/a" : Each_Game_Result(25) = "1-0"

FilePGNs(25) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Nxe4 6. d4 b5 7. Bb3 d5 8. dxe5 Be6 9. c3 Bc5 10. Nbd2 O-O 11. Bc2 Nxd2  12. Qxd2  f6 13. exf6 Rxf6 14. Nd4  Nxd4 15. cxd4 Bb6 16. a4 Rb8 17. axb5 axb5 18. Qc3 Qd6 19. Be3  Bf5 20. Rfc1 Bxc2 21. Rxc2 Re8 22. Rac1 Rfe6 23. h3 Re4 24. Qd2 R8e6 25. Rc6 Qd7  26. Rxe6 Qxe6 27. Qd3 Qe8 28. Qc3 Kf7  29. Qd3 Kg8 30. Qc3 Qe6 31. Ra1 Qe8 32. Kf1 h6 33. Qd3 Kf7 34. Rc1 Kg8 35. Qb3 Qf7  36. Rd1  c6 37. f3 Qf6 38. Qd3 Re7 39. Bf2 Qd6 40. Qc2 Kf7  41. Rc1 Re6 42. Qf5+ Rf6 43. Qe5  Re6  44. Qxd6 Rxd6 45. Ke2  Ke7 46. Kd3 Rg6 47. g3  Rf6 48. f4 Kd7 49. Re1 Rf8 50. Ra1 h5 51. Be3 g6 52. Rf1  Kd6 53. g4 hxg4 54. hxg4 c5  55. dxc5+ Bxc5 56. Bxc5+ Kxc5 57. f5 gxf5 58. gxf5 Rf6 59. Rf4  b4 60. b3  Rf7 61. f6 Kd6 62. Kd4 Ke6 63. Rf2  Kd6 64. Ra2  Rc7 65. Ra6+ Kd7 66. Rb6 1-0 "

; sample game 26
EventSites(26) = "St Petersburg preliminary  St . Petersburg" : GameDates(26) = "19140429" : WhitePlayers(26) = "Capablanca, Jose Raul   G#26" : WhiteElos(26) = "n/a" : BlackPlayers(26) = "Lasker, Emanuel   G#26" : BlackElos(26) = "n/a" : Each_Game_Result(26) = "1/2-1/2"

FilePGNs(26) = "1. e4 e5 2. Nf3 Nc6 3. Nc3 Nf6 4. Bb5 Bb4 5. O-O O-O 6. d3 d6 7. Bg5 Bxc3 8. bxc3 h6 9. Bh4 Bg4 10. h3 Bxf3 11. Qxf3 g5 12. Bg3 Nd7 13. d4 f6 14. Qg4 Kh8 15. h4 Rf7 16. hxg5 hxg5 17. f3 Nf8  18. Kf2 Rh7 19. Rh1 Qe7 20. Qf5 Rd8 21. Rxh7+ Nxh7 22. Rh1 Rg8 23. Bxc6  bxc6 24. Rb1 Kg7 25. Rb7 Ra8 26. Kg1 Nf8 27. d5 c5 28. Bf2 Qd8  29. g3 Rb8 30. Rb3 Rxb3 31. cxb3 Qd7 32. Qxd7+ Nxd7  33. Kf1 Kg6 34. Ke2 f5 35. g4  fxe4 36. fxe4 Nf6 37. Kf3 Kf7 38. Be3 Nh7 39. b4 cxb4 40. cxb4 a6 41. a4 Ke7 42. b5 axb5 43. axb5 Kd7 44. Bf2 Kc8 45. Be3 Kd7 46. Bf2 Kc8 47. Be3 Kd7 48. Bf2 Kc8 49. Be3 Kd7 1/2-1/2 "

; sample game 27
EventSites(27) = "St Petersburg preliminary  St . Petersburg" : GameDates(27) = "19140502" : WhitePlayers(27) = "Bernstein, Ossip   G#27" : WhiteElos(27) = "n/a" : BlackPlayers(27) = "Lasker, Emanuel   G#27" : BlackElos(27) = "n/a" : Each_Game_Result(27) = "1-0"

FilePGNs(27) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O d6 5. d4 Bd7 6. Nc3 Be7 7. Re1  exd4 8. Nxd4 O-O 9. Bxc6 bxc6 10. Bg5 h6 11. Bh4 Re8 12. e5  Nh7 13. Bg3 a5  14. Qd3 Bf8 15. exd6  cxd6 16. Rxe8 Qxe8 17. Nf3 Bg4  18. Rd1 d5 19. h3 Bxf3 20. Qxf3 Ng5 21. Qd3 a4   22. Kf1 Qc8 23. Ne2 Qb7 24. b3 Ne4 25. Bf4 Bc5 26. Be3 Bxe3 27. Qxe3 axb3 28. axb3 Ra2 29. f3 Ng5 30. Qd3 Ne6 31. Nc3 Ra8 32. Re1 Qb4 33. Ne2 Qc5 34. c3 Qd6  35. Nd4  Qh2  36. Nxe6 Ra2 37. Re2 Ra1+ 38. Kf2 fxe6 39. Qg6  Qc7 40. Qxe6+ Kh8 41. b4  Ra8 42. Qe3 Qd8 43. Qd4 Kh7 44. h4  Qd7 45. Qd3+ Kh8 46. Qe3 Rc8 47. Qe7   Qf5 48. Qe6 Qf8 49. Qd7  c5 50. b5 d4 51. cxd4 Rd8 52. Qe7 Qxe7 53. Rxe7 Rxd4 54. b6 Rb4 55. b7 Kh7  56. h5 1-0 "

; sample game 28
EventSites(28) = "St Petersburg preliminary  St . Petersburg" : GameDates(28) = "19140503" : WhitePlayers(28) = "Lasker, Emanuel   G#28" : WhiteElos(28) = "n/a" : BlackPlayers(28) = "Tarrasch, Siegbert   G#28" : BlackElos(28) = "n/a" : Each_Game_Result(28) = "1/2-1/2"

FilePGNs(28) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Nxe4 6. d4 b5 7. Bb3 d5 8. dxe5 Be6 9. c3 Be7 10. Nbd2 O-O 11. Re1  Nc5 12. Bc2 d4   13. cxd4 Nxd4 14. Nxd4 Qxd4 15. Nb3 Nxb3 16. axb3 Qxd1 17. Rxd1 c5  18. Bd2 Rfd8 19. Ba5 Rxd1+ 20. Rxd1 f6  21. Bc3 fxe5 22. Bxe5 Rd8 23. Rxd8+ Bxd8 24. f4 Kf7 25. Kf2 Bf6 26. Bd6  Bd4+ 27. Kf3 Bd5+ 28. Kg4 Ke6 29. Bf8 Kf7 30. Bd6 Bxg2 31. Bxh7 Ke6 32. Bf8 Kd5 33. Kg5 Bf6+  34. Kg6 Be4+ 35. f5 Ke5 36. Bxg7 Bxf5+ 37. Kf7 Bxg7  38. Bxf5 Kxf5  39. Kxg7 a5 40. h4 Kg4 41. Kg6  Kxh4  42. Kf5 Kg3 43. Ke4 Kf2 44. Kd5 Ke3 45. Kxc5 Kd3 46. Kxb5 Kc2 47. Kxa5 Kxb3 1/2-1/2 "

; sample game 29
EventSites(29) = "St Petersburg preliminary  St . Petersburg" : GameDates(29) = "19140505" : WhitePlayers(29) = "Janowski, Dawid Markelowicz   G#29" : WhiteElos(29) = "n/a" : BlackPlayers(29) = "Lasker, Emanuel   G#29" : BlackElos(29) = "n/a" : Each_Game_Result(29) = "0-1"

FilePGNs(29) = "1. d4 d5 2. Nf3 c5 3. c4 e6 4. e3 Nc6 5. Bd3 Nf6 6. O-O Bd6 7. b3 O-O 8. Bb2 b6 9. Nbd2 Bb7 10. Ne5 Qe7 11. a3 Rad8 12. Qc2  dxc4 13. Ndxc4 cxd4 14. exd4 Rc8 15. Qe2 Bb8 16. f4 Nd5 17. Rae1 f5  18. Qd2 Nxe5 19. Nxe5  a6   20. Bb1 Bd6 21. Nc4 b5 22. Na5 Ba8 23. b4 Nb6  24. Nb3 Bd5 25. Nc5 Nc4 26. Qc3 Rf6  27. Bc1 a5 28. Rf2 axb4 29. axb4 Ra8  30. Ba2 Qf7 31. Bxc4 Bxc4 32. Bb2 Rg6 33. Ra1  Rxa1+ 34. Bxa1 Qc7 35. Qe3 Rg4 36. g3  g5  37. d5 Bxd5 38. Qd4  gxf4 39. Qh8+ Kf7 40. Qxh7+ Ke8 41. Qh8+ Bf8  42. Be5 Qf7 43. Rxf4 Rxf4 44. Bxf4 Qg7  45. Qh5+  Kd8 46. Bg5+ Kc7 47. Bf4+ Bd6 48. Bxd6+ Kxd6  49. Qh4 Qa1+ 50. Kf2 Qb2+ 51. Ke1 Qc1+ 52. Ke2 Bc4+ 0-1 "

; sample game 30
EventSites(30) = "St Petersburg preliminary  St . Petersburg" : GameDates(30) = "19140507" : WhitePlayers(30) = "Lasker, Emanuel   G#30" : WhiteElos(30) = "n/a" : BlackPlayers(30) = "Gunsberg, Isidor   G#30" : BlackElos(30) = "n/a" : Each_Game_Result(30) = "1-0"

FilePGNs(30) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O d6 6. Re1 Bd7 7. c3 Be7 8. d4 O-O 9. Nbd2 b5 10. Bb3 exd4  11. cxd4 Bg4 12. Nf1 d5  13. e5 Ne4 14. Ne3 Be6 15. Qc2 Nb4 16. Qb1 f5  17. a3 Nc6 18. Qa2   Ng5 19. Nxg5 Bxg5 20. Bxd5 Bxd5 21. Nxd5 Kh8 22. f4 Bh4 23. Rd1 Qe8 24. Be3 Rd8 25. Nxc7 Qh5 26. b4 1-0 "

; sample game 31
EventSites(31) = "St Petersburg final  St . Petersburg" : GameDates(31) = "19140511" : WhitePlayers(31) = "Capablanca, Jose Raul   G#31" : WhiteElos(31) = "n/a" : BlackPlayers(31) = "Lasker, Emanuel   G#31" : BlackElos(31) = "n/a" : Each_Game_Result(31) = "1/2-1/2"

FilePGNs(31) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Nxe4 6. d4 b5 7. Bb3 d5 8. dxe5 Be6 9. Nbd2 Nc5 10. c3 d4 11. cxd4 Nxd4 12. Nxd4 Qxd4 13. Bxe6 Nxe6 14. Qf3 Rd8 15. a4 Qd5 16. Qxd5 Rxd5 17. axb5 axb5 18. Ra8+ Nd8  19. Ne4   Rxe5 20. Rd1 Be7 21. f3  Rf5 22. Rc8 O-O 23. Rxc7  Bb4 24. Be3 Ne6 25. Rcd7 Rc8 26. R1d5 Rxd5 27. Rxd5 Rc2  28. b3 Rb2 29. Rxb5 Rxb3 30. Bd2 Bc5+  31. Rxc5 Nxc5 32. Nxc5 Rb2 33. Be3 Re2 34. Bf2 f6 35. Kf1 Ra2 36. g4 Kf7 37. Ne4 h6 38. Kg2 Ra3 39. f4 Rb3 40. Ng3 Ra3 41. Nf1 Rd3 42. Ne3 Rc3 43. Kf3 Ra3 44. f5 Ra2 45. Nd5 Rb2 46. Nf4 Ra2 47. h4 Ra5 48. Bd4 Ra3+ 49. Be3 Ra5 50. Nh5 Ra4 51. Ng3 Kg8 52. Ne4 Kf7 53. Bd2 Ra1 54. Bc3 Rf1+ 55. Nf2 Rc1 56. Bd4 Re1 57. Ne4 Rf1+ 58. Bf2 Ra1 59. Kf4 Ra4 60. Bc5 Rc4 61. Kf3 Rc1 62. Bf2 Ra1 63. Kf4 Ra4 64. Kf3 Ra3+ 65. Be3 Ra5 66. Nc5 Ra1 67. Ne6 Ra3 68. Ke4 Ra4+ 69. Bd4 Rb4 70. Kd3 Rb3+ 71. Ke4 Rb4 72. Kd5 Rb1 73. g5 hxg5 74. hxg5 fxg5 75. Nxg5+ Kg8 76. Ne6 Rd1  77. Ke4 Kf7  78. Ng5+ Kg8  79. Ke5 Re1+ 80. Kf4 Rf1+ 81. Kg4 Rd1 82. Nf3 Rf1 83. Be5 Kf7 84. Kf4 Kg8 85. Ke4 Rd1 86. Ng5 Re1+ 87. Kd5 Rd1+ 88. Ke6 Re1 89. Nh3 Rb1 90. Nf4 Rb6+ 91. Ke7 Rb5 92. Ng6 Rb6 93. Bd6 Ra6 94. Ke6 Rb6 95. Ne7+ Kh7 96. Nc8 Ra6 97. Ne7 Rb6 98. Nd5 Ra6 99. Nc3 Kg8 100. Ne4 Rb6 1/2-1/2 "

; sample game 32
EventSites(32) = "St Petersburg final  St . Petersburg" : GameDates(32) = "19140515" : WhitePlayers(32) = "Marshall, Frank James   G#32" : WhiteElos(32) = "n/a" : BlackPlayers(32) = "Lasker, Emanuel   G#32" : BlackElos(32) = "n/a" : Each_Game_Result(32) = "0-1"

FilePGNs(32) = "1. d4 Nf6 2. c4 d6 3. Nc3 Nbd7 4. Nf3 e5 5. e3 Be7 6. Bd3 O-O 7. Qc2 Re8 8. O-O Bf8 9. Ng5  g6  10. f4 exd4 11. exd4  Bg7 12. f5  Ng4 13. Nf3 c5  14. fxg6 fxg6 15. h3  cxd4 16. Bg5 Ne3   17. Qf2 Qb6 18. Nd5 Nxd5 19. cxd5 Nc5 20. Rad1 Bd7 21. Qh4 Ba4  22. Bxg6  hxg6 23. Bd8 Qxd8 24. Ng5 Qxg5  25. Qxg5 Bxd1 26. Qxg6 Bc2  27. Qxc2 d3 28. Qd1 a5  29. Qg4 Rf8 30. Rd1 Rae8 31. Qg6 Re2 32. Rf1 d2 33. Rxf8+ Kxf8 34. Qxd6+ Kg8 35. Qd8+ Kh7 36. Qh4+ Bh6 0-1 "

; sample game 33
EventSites(33) = "St Petersburg final  St . Petersburg" : GameDates(33) = "19140518" : WhitePlayers(33) = "Lasker, Emanuel   G#33" : WhiteElos(33) = "n/a" : BlackPlayers(33) = "Capablanca, Jose Raul   G#33" : BlackElos(33) = "n/a" : Each_Game_Result(33) = "1-0"

FilePGNs(33) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Bxc6 dxc6 5. d4 exd4 6. Qxd4 Qxd4 7. Nxd4 Bd6 8. Nc3 Ne7 9. O-O O-O 10. f4 Re8 11. Nb3 f6 12. f5  b6 13. Bf4 Bb7  14. Bxd6 cxd6 15. Nd4 Rad8  16. Ne6 Rd7 17. Rad1 Nc8 18. Rf2 b5 19. Rfd2 Rde7 20. b4 Kf7 21. a3 Ba8  22. Kf2 Ra7 23. g4 h6 24. Rd3 a5  25. h4 axb4 26. axb4 Rae7 27. Kf3 Rg8 28. Kf4 g6 29. Rg3 g5+ 30. Kf3 Nb6 31. hxg5 hxg5 32. Rh3  Rd7 33. Kg3 Ke8 34. Rdh1 Bb7 35. e5  dxe5 36. Ne4 Nd5 37. N6c5 Bc8 38. Nxd7 Bxd7 39. Rh7 Rf8 40. Ra1 Kd8 41. Ra8+ Bc8 42. Nc5 1-0 "

; sample game 34
EventSites(34) = "St Petersburg final  St . Petersburg" : GameDates(34) = "19140521" : WhitePlayers(34) = "Tarrasch, Siegbert   G#34" : WhiteElos(34) = "n/a" : BlackPlayers(34) = "Lasker, Emanuel   G#34" : BlackElos(34) = "n/a" : Each_Game_Result(34) = "1/2-1/2"

FilePGNs(34) = "1. e4 e6 2. d4 d5 3. e5 c5 4. dxc5 Nc6 5. Nf3 Bxc5 6. Bd3 f5 7. c3 a6 8. Nbd2 Nge7 9. Nb3 Ba7 10. O-O O-O 11. Re1 Ng6 12. Nbd4 Bb8 13. Nxc6 bxc6 14. Kh1 a5 15. b3 c5  16. Ba3 Qb6 17. Qd2 Bb7 18. Qg5 Ba7 19. h4 Qd8 20. Qg3 Qe8 21. Nh2 Ne7 22. f4 Rc8 23. Nf3 Kh8 24. Ng5 Ng8  25. Be2 Qe7 26. Rad1 Rfd8 27. Rd2 Nh6 28. Red1 Qe8 29. Kh2 Rc7 30. Kh3 Rdc8 31. Bb2 Bc6 32. Bf3 Rb8 33. Ba3 Ng8 34. Be2 Nh6 35. Qe1 Rd8 36. Qg3 Rb8 37. Qe1 Rd8 38. Qg3 Rb8 39. Qe1 Rd8 1/2-1/2 "

; sample game 35
EventSites(35) = "St Petersburg final  St . Petersburg" : GameDates(35) = "19140522" : WhitePlayers(35) = "Lasker, Emanuel   G#35" : WhiteElos(35) = "n/a" : BlackPlayers(35) = "Marshall, Frank James   G#35" : BlackElos(35) = "n/a" : Each_Game_Result(35) = "1-0"

FilePGNs(35) = "1. e4 e5 2. Nf3 Nf6 3. Nxe5 d6 4. Nf3 Nxe4 5. Qe2 Qe7 6. d3 Nf6 7. Bg5 Be6 8. Nc3 Nbd7 9. O-O-O h6 10. Bh4 g5 11. Bg3 Nh5 12. d4 Nxg3 13. hxg3 g4 14. Nh4 d5 15. Qb5  O-O-O 16. Qa5 a6 17. Bxa6  bxa6 18. Qxa6+ Kb8 19. Nb5 Nb6 20. Rd3 Qg5+ 21. Kb1 Bd6 22. Rb3 Rhe8 23. a4  Bf5 24. Na7  Bd7 25. a5 Qd2 26. axb6 Re1+ 27. Ka2 c6 28. Nb5 cxb5 29. Qa7+ 1-0 "

; sample game 36
EventSites(36) = "Hastings Six Masters  Hastings" : GameDates(36) = "1922????" : WhitePlayers(36) = "Bogoljubow, Efim   G#36" : WhiteElos(36) = "n/a" : BlackPlayers(36) = "Alekhine, Alexander   G#36" : BlackElos(36) = "n/a" : Each_Game_Result(36) = "0-1"

FilePGNs(36) = "1. d4 f5 2. c4 Nf6 3. g3 e6 4. Bg2 Bb4+ 5. Bd2 Bxd2+ 6. Nxd2 Nc6 7. Ngf3 O-O 8. O-O d6 9. Qb3 Kh8 10. Qc3 e5 11. e3 a5 12. b3 Qe8 13. a3 Qh5 14. h4 Ng4 15. Ng5 Bd7 16. f3 Nf6 17. f4 e4 18. Rfd1 h6 19. Nh3 d5 20. Nf1 Ne7 21. a4 Nc6 22. Rd2 Nb4 23. Bh1 Qe8 24. Rg2 dxc4 25. bxc4 Bxa4 26. Nf2 Bd7 27. Nd2 b5 28. Nd1 Nd3  29. Rxa5 b4 30. Rxa8 bxc3  31. Rxe8 c2 32. Rxf8+ Kh7 33. Nf2 c1=Q+ 34. Nf1 Ne1  35. Rh2 Qxc4 36. Rb8 Bb5 37. Rxb5 Qxb5 38. g4 Nf3+ 39. Bxf3 exf3 40. gxf5 Qe2  41. d5 Kg8 42. h5 Kh7 43. e4 Nxe4 44. Nxe4 Qxe4 45. d6 cxd6 46. f6 gxf6 47. Rd2 Qe2 48. Rxe2 fxe2 49. Kf2 exf1=Q+ 50. Kxf1 Kg7 51. Kf2 Kf7 52. Ke3 Ke6 53. Ke4 d5+ 0-1 "

; sample game 37
EventSites(37) = "London BCF Congress  London" : GameDates(37) = "1922????" : WhitePlayers(37) = "Reti, Richard   G#37" : WhiteElos(37) = "n/a" : BlackPlayers(37) = "Watson, Charles Gilbert   G#37" : BlackElos(37) = "n/a" : Each_Game_Result(37) = "0-1"

FilePGNs(37) = "1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. Bg5 Be7 5. e3 O-O 6. Nf3 Nbd7 7. Bd3 Re8 8. O-O Nf8 9. Ne5 c6  10. f4 dxc4 11. Bxc4 Nd5 12. Bxe7 Qxe7 13. Qf3 f6 14. Nd3 Bd7 15. e4 Nb6 16. Bb3 Rad8 17. Rad1 Bc8 18. Nc5 Kh8 19. Qf2 Qc7 20. h3 Re7 21. Kh1 Nbd7 22. Nxd7  Rexd7 23. e5  f5 24. g4  g6 25. Rg1 Rg7 26. Qh4 Qe7 27. Qh6 b6 28. Kh2 Bb7 29. Rg3 c5 30. gxf5 gxf5 31. Rxg7 Qxg7 32. Qxg7+ Kxg7 33. Nb5 cxd4 34. Nd6 Rd7 35. Rxd4 Re7 36. Kg3 Kh6 37. Kf2 Rg7 38. Ke3 Ba8  39. Kd2  Rg2+ 40. Kc3 Rg3+ 41. Rd3 Rxd3+ 42. Kxd3 Bg2 43. Nf7+ Kg7 44. Nd8  Bxh3 45. Bxe6 Ng6 46. Ke3 Ne7 47. Kf2 Bg4 48. Kg3 Be2 49. Nb7 Kg6 50. Nd6 Bd3 51. a3 Be2 52. b4 Bd3 53. Bf7+ Kg7 54. Be8 h6 55. Kf3 Bf1 56. Kf2 Bd3 57. Ke3 Bf1 58. Kf2 Bd3 59. Ke3 Bf1 60. Bd7  Kg6 61. Be6  Bg2 62. Nb5 Bd5  63. Bd7 Bc6  64. Bxc6 Nxc6 65. Nd4  Ne7 66. b5 Nd5+ 67. Kf3 Nc3 68. Kg3 Ne4+ 69. Kh4 Nc3 70. Nc6  Nxb5 71. Ne7+ Kf7  72. Nxf5 Nxa3 73. Nd6+  Ke6 74. Kh5 Nc2 75. Kg6  Ne3  76. Ne8  Ke7  77. Ng7 Ng2  78. Kf5  a5 79. Ke4 a4 80. Nf5+ Kf8 81. Nd4 Nxf4  82. Nb5 Ng6 83. Kf5 Kg7 84. e6 Ne7+ 85. Ke5 h5 86. Ke4 Kf6 87. Nc3 a3 88. Kd4 h4 89. Kc4 Kxe6 90. Kb3 h3 91. Ne4 h2 92. Nf2 Kf5 0-1 "

; sample game 38
EventSites(38) = "Berlin  Berlin" : GameDates(38) = "1923????" : WhitePlayers(38) = "Alekhine, Alexander   G#38" : WhiteElos(38) = "n/a" : BlackPlayers(38) = "Saemisch, Fritz   G#38" : BlackElos(38) = "n/a" : Each_Game_Result(38) = "1-0"

FilePGNs(38) = "1. e4 c5 2. Nf3 Nc6 3. Be2 e6 4. O-O d6 5. d4 cxd4 6. Nxd4 Nf6 7. Bf3 Ne5 8. c4 Nxf3+ 9. Qxf3 Be7 10. Nc3 O-O 11. b3 Nd7 12. Bb2 Bf6 13. Rad1 a6 14. Qg3 Qc7 15. Kh1 Rd8 16. f4 b6 17. f5 Be5 18. fxe6  Bxg3 19. exf7+ Kh8 20. Nd5  1-0 "

; sample game 39
EventSites(39) = "Karlsbad  Karlstad" : GameDates(39) = "19230430" : WhitePlayers(39) = "Alekhine, Alexander   G#39" : WhiteElos(39) = "n/a" : BlackPlayers(39) = "Rubinstein, Akiba   G#39" : BlackElos(39) = "n/a" : Each_Game_Result(39) = "1-0"

FilePGNs(39) = "1. d4 d5 2. c4 e6 3. Nf3 Nf6 4. Nc3 Be7 5. Bg5 Nbd7 6. e3 O-O 7. Rc1 c6 8. Qc2 a6 9. a4 Re8 10. Bd3 dxc4 11. Bxc4 Nd5 12. Bf4 Nxf4 13. exf4 c5 14. dxc5 Qc7 15. O-O Qxf4 16. Ne4 Nxc5 17. Nxc5 Bxc5 18. Bd3 b6 19. Bxh7+ Kh8 20. Be4 Ra7 21. b4 Bf8 22. Qc6 Rd7 23. g3 Qb8 24. Ng5  Red8 25. Bg6  Qe5 26. Nxf7+ Rxf7 27. Bxf7 Qf5 28. Rfd1  Rxd1+ 29. Rxd1 Qxf7 30. Qxc8 Kh7 31. Qxa6 Qf3 32. Qd3+ 1-0 "

; sample game 40
EventSites(40) = "Karlsbad  Karlstad" : GameDates(40) = "19230429" : WhitePlayers(40) = "Gruenfeld, Ernst   G#40" : WhiteElos(40) = "n/a" : BlackPlayers(40) = "Alekhine, Alexander   G#40" : BlackElos(40) = "n/a" : Each_Game_Result(40) = "0-1"

FilePGNs(40) = "1. d4 Nf6 2. c4 e6 3. Nc3 d5 4. Bg5 Be7 5. Nf3 Nbd7 6. e3 O-O 7. Rc1 c6 8. Qc2 a6 9. a3 h6 10. Bh4 Re8 11. Bd3 dxc4 12. Bxc4 b5 13. Ba2 c5 14. Rd1 cxd4 15. Nxd4 Qb6 16. Bb1 Bb7 17. O-O Rac8 18. Qd2 Ne5 19. Bxf6 Bxf6 20. Qc2 g6 21. Qe2 Nc4 22. Be4 Bg7 23. Bxb7 Qxb7 24. Rc1 e5 25. Nb3 e4 26. Nd4 Red8 27. Rfd1 Ne5 28. Na2 Nd3 29. Rxc8 Qxc8 30. f3  Rxd4  31. fxe4 Nf4  32. exf4 Qc4  33. Qxc4 Rxd1+ 34. Qf1 Bd4+ 0-1 "

; sample game 41
EventSites(41) = "Paris  Paris" : GameDates(41) = "1925????" : WhitePlayers(41) = "Alekhine, Alexander   G#41" : WhiteElos(41) = "n/a" : BlackPlayers(41) = "Colle, Edgar   G#41" : BlackElos(41) = "n/a" : Each_Game_Result(41) = "1-0"

FilePGNs(41) = "1. d4 d5 2. c4 Nc6 3. Nf3 Bg4 4. Qa4 Bxf3 5. exf3 e6 6. Nc3 Bb4 7. a3 Bxc3+ 8. bxc3 Ne7 9. Rb1 Rb8 10. cxd5 Qxd5 11. Bd3 O-O 12. O-O Qd6 13. Qc2 Ng6 14. f4 Nce7 15. g3 Rfd8 16. Rd1 b6 17. a4 Nd5 18. Bd2 c5 19. f5 exf5 20. Bxf5 cxd4 21. cxd4 Nde7 22. Bb4 Qf6 23. Bxe7 Qxe7 24. Rbc1 Rd5 25. Be4 Rd7 26. d5 Qf6 27. Re1 Rbd8 28. Qc6 Qg5 29. Bxg6  hxg6  30. Qxd7  Rxd7 31. Re8+ Kh7 32. Rcc8 Rd8 33. Rexd8 1-0 "

; sample game 42
EventSites(42) = "Baden-Baden  Baden Baden" : GameDates(42) = "19250425" : WhitePlayers(42) = "Reti, Richard   G#42" : WhiteElos(42) = "n/a" : BlackPlayers(42) = "Alekhine, Alexander   G#42" : BlackElos(42) = "n/a" : Each_Game_Result(42) = "0-1"

FilePGNs(42) = "1. g3 e5 2. Nf3 e4 3. Nd4 d5 4. d3 exd3 5. Qxd3 Nf6 6. Bg2 Bb4+ 7. Bd2 Bxd2+ 8. Nxd2 O-O 9. c4 Na6 10. cxd5 Nb4 11. Qc4 Nbxd5 12. N2b3 c6 13. O-O Re8 14. Rfd1 Bg4 15. Rd2 Qc8 16. Nc5 Bh3 17. Bf3 Bg4 18. Bg2 Bh3 19. Bf3 Bg4 20. Bh1 h5 21. b4 a6 22. Rc1 h4 23. a4 hxg3 24. hxg3 Qc7 25. b5 axb5 26. axb5 Re3  27. Nf3  cxb5  28. Qxb5 Nc3 29. Qxb7 Qxb7 30. Nxb7 Nxe2+ 31. Kh2 Ne4  32. Rc4 Nxf2 33. Bg2 Be6  34. Rcc2 Ng4+ 35. Kh3 Ne5+ 36. Kh2 Rxf3  37. Rxe2 Ng4+ 38. Kh3 Ne3+ 39. Kh2 Nxc2 40. Bxf3 Nd4 41. Rf2 Nxf3+ 42. Rxf3 Bd5 0-1 "

; sample game 43
EventSites(43) = "Moscow  Moscow" : GameDates(43) = "1925????" : WhitePlayers(43) = "Capablanca, Jose Raul   G#43" : WhiteElos(43) = "n/a" : BlackPlayers(43) = "Bogoljubow, Efim   G#43" : BlackElos(43) = "n/a" : Each_Game_Result(43) = "1-0"

FilePGNs(43) = "1. d4 d5 2. c4 e6 3. Nf3 dxc4 4. e4 c5  5. Bxc4 cxd4 6. Nxd4 Nf6 7. Nc3 Bc5 8. Be3 Nbd7  9. Bxe6  fxe6 10. Nxe6 Qa5  11. O-O Bxe3 12. fxe3 Kf7 13. Qb3 Kg6 14. Rf5 Qb6 15. Nf4+ Kh6 16. g4  g5  17. Qxb6 axb6 18. Rd1  Rg8  19. Nfd5 Nxg4  20. Ne7  Rg7 21. Rd6+ Kh5 22. Rf3  Ngf6 23. Rh3+ Kg4 24. Rg3+ Kh5 25. Nf5 Rg6 26. Ne7  g4  27. Nxg6 Kxg6 28. Rxg4+ Kf7 29. Rf4 Kg7 30. e5 Ne8 31. Re6 Nc7 32. Re7+ 1-0 "

; sample game 44
EventSites(44) = "World Championship 13th  Buenos Aires" : GameDates(44) = "19271109" : WhitePlayers(44) = "Capablanca, Jose Raul   G#44" : WhiteElos(44) = "n/a" : BlackPlayers(44) = "Alekhine, Alexander   G#44" : BlackElos(44) = "n/a" : Each_Game_Result(44) = "1/2-1/2"

FilePGNs(44) = "1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. Bg5 Nbd7 5. e3 Be7 6. Nf3 O-O 7. Rc1 a6 8. cxd5 exd5 9. Bd3 c6 10. Qc2 h6 11. Bh4 Ne8 12. Bg3 Bd6 13. O-O Bxg3 14. hxg3 Nd6 15. Na4 Re8 16. Rfe1 Nf6 17. Ne5 Nfe4 18. Qb3  Be6 19. Nc5 Nxc5  20. dxc5 Nb5 21. a4 Nc7 22. Bb1  Bc8 23. Nf3 Ne6 24. e4  dxe4 25. Rxe4 Re7  26. Rce1 Bd7 27. Qc2 g6 28. Ba2  Qf8 29. Ne5 Qg7 30. Nxd7 Rxd7 31. Bxe6 fxe6 32. Rg4 Kh7 33. Rxe6 Rg8 34. Qe4 Rf7 35. f4 Qf8 36. Rgxg6 Qxc5+ 37. Kf1 Qc1+ 38. Kf2 Qd2+  1/2-1/2 "

; sample game 45
EventSites(45) = "Nice  Nice" : GameDates(45) = "1930????" : WhitePlayers(45) = "Colle, Edgar   G#45" : WhiteElos(45) = "n/a" : BlackPlayers(45) = "O'Hanlon, John   G#45" : BlackElos(45) = "n/a" : Each_Game_Result(45) = "1-0"

FilePGNs(45) = "1. d4 d5 2. Nf3 Nf6 3. e3 c5 4. c3 e6 5. Bd3 Bd6 6. Nbd2 Nbd7 7. O-O O-O 8. Re1 Re8 9. e4 dxe4 10. Nxe4 Nxe4 11. Bxe4 cxd4 12. Bxh7+ Kxh7 13. Ng5+ Kg6 14. h4 Rh8 15. Rxe6+  Nf6 16. h5+ Kh6 17. Rxd6 Qa5 18. Nxf7+ Kh7 19. Ng5+ Kg8 20. Qb3+ 1-0 "

; sample game 46
EventSites(46) = "Leningrad  Leningrad" : GameDates(46) = "1934????" : WhitePlayers(46) = "Botvinnik, Mikhail   G#46" : WhiteElos(46) = "n/a" : BlackPlayers(46) = "Alatortsev, Vladimir   G#46" : BlackElos(46) = "n/a" : Each_Game_Result(46) = "1-0"

FilePGNs(46) = "1. d4 e6 2. c4 d5 3. Nf3 Be7 4. Nc3 Nf6 5. Bg5 O-O 6. e3 a6 7. cxd5 exd5 8. Bd3 c6 9. Qc2 Nbd7 10. g4  Nxg4  11. Bxh7+ Kh8 12. Bf4 Ndf6 13. Bd3 Nh5 14. h3 Ngf6 15. Be5 Ng8 16. O-O-O Nh6 17. Rdg1 Be6 18. Qe2 Bf5  19. Bxf5 Nxf5 20. Nh4  1-0 "

; sample game 47
EventSites(47) = "World Championship 16th  NLD" : GameDates(47) = "19351119" : WhitePlayers(47) = "Alekhine, Alexander   G#47" : WhiteElos(47) = "n/a" : BlackPlayers(47) = "Euwe, Max   G#47" : BlackElos(47) = "n/a" : Each_Game_Result(47) = "0-1"

FilePGNs(47) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 dxc4 5. a4 Bf5 6. Ne5 Nbd7 7. Nxc4 Qc7 8. g3 e5 9. dxe5 Nxe5 10. Bf4 Nfd7 11. Bg2 Rd8 12. Qc1 f6 13. O-O Be6  14. Nxe5 Nxe5 15. a5  a6  16. Ne4 Bb4 17. Nc5 Bc8 18. Bxe5 fxe5 19. f4 Bd2  20. Qc4 Rd4 21. Qb3 exf4 22. gxf4 Qe7  23. Nd3 Be6 24. Qa3 Bc4  25. Kh1 Qxa3 26. Rxa3 O-O 27. Ra4 Rfd8 28. Ra3 Bxd3 29. exd3 Rb4 30. Rf2 Rxb2 31. Bf1 Rd4 32. f5 Rf4 33. Rxf4 Bxf4 34. h3 Bd6 35. Ra1 Kf7 36. d4 Kf6 37. Re1 Bb4 38. Ra1 Rd2 39. Bc4 Rxd4 40. Be6 Rd3 0-1 "

; sample game 48
EventSites(48) = "Moscow  Moscow" : GameDates(48) = "1936????" : WhitePlayers(48) = "Kan, Ilia Abramovich   G#48" : WhiteElos(48) = "n/a" : BlackPlayers(48) = "Capablanca, Jose Raul   G#48" : BlackElos(48) = "n/a" : Each_Game_Result(48) = "0-1"

FilePGNs(48) = "1. e4 e5 2. Nc3 Bc5 3. Nf3 d6 4. Na4 Bb6 5. Nxb6 axb6 6. d4 exd4 7. Qxd4 Qf6 8. Bg5 Qxd4 9. Nxd4 Bd7 10. Bc4 Ne7 11. O-O Ng6 12. a3 O-O 13. Rad1 Nc6 14. Nxc6 bxc6 15. Bd2 Ra4 16. Bd3 Ne5 17. Bc3 f6 18. f3 Re8 19. Rf2 Bc8  20. Bf1  Ba6 21. Bxa6  Rxa6 22. Bxe5  fxe5 23. Rd3 b5 24. Rfd2 c5 25. Kf2 Ra4 26. Ke3 Kf7 27. Rd1 Ke6 28. Kd2  Rb8 29. Rc3 g5 30. h3 h5 31. Rh1 Rd4+ 32. Ke2 Rg8 33. Rd3 Ra4 34. Rhd1 g4 35. hxg4 hxg4 36. Ke3  Rh8  37. Rb3 Rh2  38. Rd2 Rd4 39. Re2 c6 40. Rc3 g3  41. Rd3 Rh1 42. f4 Rf1  43. f5+ Kf6 44. c3 Rxd3+ 45. Kxd3 d5  46. b3 c4+ 47. bxc4 bxc4+ 48. Ke3 Ra1 49. Kf3 Rxa3 50. Kxg3 Rxc3+ 51. Kh4 Rc1 52. g4 Rh1+ 53. Kg3 d4 54. Ra2 d3 55. Kg2 Re1 56. Kf2 Rxe4 57. Kf3 0-1 "

; sample game 49
EventSites(49) = "World Championship 17th  NLD" : GameDates(49) = "19371005" : WhitePlayers(49) = "Euwe, Max   G#49" : WhiteElos(49) = "n/a" : BlackPlayers(49) = "Alekhine, Alexander   G#49" : BlackElos(49) = "n/a" : Each_Game_Result(49) = "1-0"

FilePGNs(49) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 dxc4 5. a4 Bf5 6. Ne5 Nbd7 7. Nxc4 Qc7 8. g3 e5 9. dxe5 Nxe5 10. Bf4 Nfd7 11. Bg2 f6 12. O-O Rd8 13. Qc1 Be6 14. Ne4  Bb4 15. a5 O-O 16. a6 bxa6  17. Nxe5 Nxe5 18. Nc5 Bxc5 19. Qxc5 g5  20. Be3 Bd5 21. Rxa6 Bxg2 22. Kxg2 Rf7 23. Rfa1 Qd6 24. Qxd6 Rxd6 25. Rxa7 Rxa7 26. Rxa7 Nc4 27. Bc5 Re6 28. Bd4 Rxe2 29. Bxf6 g4 30. Kf1 Rc2 31. Rg7+ Kf8 32. Rxg4 Nxb2 33. Bxb2 Rxb2 34. Rc4 Rb6 35. Ke2 Kf7 36. Rh4 Kg6 37. Rf4 Rb3 38. Rc4 Rb6 39. Ke3 Kf5 40. g4+ Ke6 41. f4 Kd5 42. Rd4+ Ke6 43. f5+ Ke7 44. Re4+ Kf7 45. h4 Rb1 46. Kf4 Rc1 47. Ra4 h6 48. Ra7+ Kg8 49. g5 Rc4+ 50. Ke5 1-0 "

; sample game 50
EventSites(50) = "AVRO  Holland" : GameDates(50) = "19381115" : WhitePlayers(50) = "Botvinnik, Mikhail   G#50" : WhiteElos(50) = "n/a" : BlackPlayers(50) = "Alekhine, Alexander   G#50" : BlackElos(50) = "n/a" : Each_Game_Result(50) = "1-0"

FilePGNs(50) = "1. Nf3 d5 2. d4 Nf6 3. c4 e6 4. Nc3 c5 5. cxd5 Nxd5 6. e3 Nc6 7. Bc4 cxd4 8. exd4 Be7 9. O-O O-O 10. Re1 b6  11. Nxd5  exd5 12. Bb5 Bd7  13. Qa4 Nb8 14. Bf4 Bxb5 15. Qxb5 a6 16. Qa4 Bd6 17. Bxd6 Qxd6 18. Rac1 Ra7 19. Qc2 Re7 20. Rxe7 Qxe7 21. Qc7 Qxc7 22. Rxc7 f6  23. Kf1 Rf7 24. Rc8+ Rf8 25. Rc3  g5 26. Ne1 h5 27. h4  Nd7 28. Rc7 Rf7 29. Nf3  g4 30. Ne1 f5 31. Nd3 f4 32. f3 gxf3 33. gxf3 a5 34. a4 Kf8 35. Rc6 Ke7 36. Kf2 Rf5 37. b3 Kd8 38. Ke2 Nb8 39. Rg6  Kc7 40. Ne5 Na6 41. Rg7+ Kc8 42. Nc6 Rf6 43. Ne7+ Kb8 44. Nxd5 Rd6 45. Rg5 Nb4 46. Nxb4 axb4 47. Rxh5 Rc6 48. Rb5 Kc7 49. Rxb4 Rh6 50. Rb5 Rxh4 51. Kd3 1-0 "

; sample game 51
EventSites(51) = "AVRO  Holland" : GameDates(51) = "19381122" : WhitePlayers(51) = "Botvinnik, Mikhail   G#51" : WhiteElos(51) = "n/a" : BlackPlayers(51) = "Capablanca, Jose Raul   G#51" : BlackElos(51) = "n/a" : Each_Game_Result(51) = "1-0"

FilePGNs(51) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 d5 5. a3 Bxc3+ 6. bxc3 c5 7. cxd5 exd5 8. Bd3 O-O 9. Ne2 b6 10. O-O Ba6 11. Bxa6 Nxa6 12. Bb2  Qd7 13. a4 Rfe8  14. Qd3 c4  15. Qc2 Nb8 16. Rae1 Nc6 17. Ng3 Na5 18. f3 Nb3 19. e4 Qxa4 20. e5 Nd7 21. Qf2 g6 22. f4 f5 23. exf6 Nxf6 24. f5 Rxe1 25. Rxe1 Re8 26. Re6  Rxe6 27. fxe6 Kg7 28. Qf4 Qe8 29. Qe5 Qe7 30. Ba3  Qxa3 31. Nh5+  gxh5 32. Qg5+ Kf8 33. Qxf6+ Kg8 34. e7 Qc1+ 35. Kf2 Qc2+ 36. Kg3 Qd3+ 37. Kh4 Qe4+ 38. Kxh5 Qe2+ 39. Kh4 Qe4+ 40. g4 Qe1+ 41. Kh5 1-0 "

; sample game 52
EventSites(52) = "NED-ch m  Netherlands" : GameDates(52) = "1939????" : WhitePlayers(52) = "Euwe, Max   G#52" : WhiteElos(52) = "n/a" : BlackPlayers(52) = "Landau, Salo   G#52" : BlackElos(52) = "n/a" : Each_Game_Result(52) = "1-0"

FilePGNs(52) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 dxc4 5. a4 Bf5 6. e3 e6 7. Bxc4 Bb4 8. O-O Nbd7 9. Qb3 Qb6 10. e4  Bg6 11. Bxe6  fxe6 12. a5  Bxa5 13. Qxe6+ Kd8 14. e5 Re8  15. Qh3 Bxc3 16. exf6 Bb4 17. fxg7 Bd6 18. Ne5  Bxe5 19. dxe5 Bf7  20. Rd1 Bd5 21. e6 Nf6 22. Bg5 Ke7 23. Qc3 1-0 "

; sample game 53
EventSites(53) = "World Championship 18th  The Hague/Moscow" : GameDates(53) = "19480411" : WhitePlayers(53) = "Smyslov, Vassily   G#53" : WhiteElos(53) = "n/a" : BlackPlayers(53) = "Reshevsky, Samuel Herman   G#53" : BlackElos(53) = "n/a" : Each_Game_Result(53) = "1-0"

FilePGNs(53) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 d6 5. c3 Ne7 6. d4 Bd7 7. Bb3 h6 8. Nbd2 Ng6 9. Nc4 Be7 10. O-O O-O 11. Ne3 Bf6 12. Nd5 Re8  13. dxe5  Bxe5 14. Nxe5 dxe5 15. Qf3 Be6 16. Rd1 Bxd5 17. Rxd5 Qe7 18. Qf5  Nf8 19. Be3 Ne6 20. Rad1 Red8 21. g3 Rd6 22. Rxd6 cxd6 23. Qg4  Kh8 24. Bb6  Nb8 25. Bxe6  fxe6 26. Qh4  Qd7 27. Qd8+ Qxd8 28. Bxd8 Nd7 29. Bc7 Nc5 30. Rxd6 Rc8 31. Bb6 Na4 32. Rxe6 Nxb2 33. Rxe5 Nc4 34. Re6 Nxb6 35. Rxb6 Rxc3 36. Rxb7 Rc2 37. h4 Rxa2 38. Kg2 a5 39. h5 a4 40. Ra7 Kg8 41. g4 a3 42. Kg3 Re2 43. Kf3 Ra2 44. Ke3 Kf8 45. f3 Ra1 46. Kf4 a2 47. e5 Kg8 48. Kf5 Rf1 49. Rxa2 Rxf3+ 50. Kg6 Kf8 51. Ra8+ Ke7 52. Ra7+ 1-0 "

; sample game 54
EventSites(54) = "World Championship 18th  The Hague/Moscow" : GameDates(54) = "19480413" : WhitePlayers(54) = "Botvinnik, Mikhail   G#54" : WhiteElos(54) = "n/a" : BlackPlayers(54) = "Euwe, Max   G#54" : BlackElos(54) = "n/a" : Each_Game_Result(54) = "1-0"

FilePGNs(54) = "1. d4 d5 2. Nf3 Nf6 3. c4 e6 4. Nc3 c6 5. e3 Nbd7 6. Bd3 dxc4 7. Bxc4 b5 8. Bd3 a6 9. e4 c5 10. e5 cxd4 11. Nxb5 axb5 12. exf6 Qb6 13. fxg7 Bxg7 14. O-O Nc5 15. Bf4 Bb7 16. Re1 Rd8  17. Rc1 Rd5 18. Be5 Bxe5 19. Rxe5 Rxe5 20. Nxe5 Nxd3 21. Qxd3 f6 22. Qg3  fxe5 23. Qg7 Rf8 24. Rc7 Qxc7 25. Qxc7 Bd5 26. Qxe5 d3 27. Qe3 Bc4 28. b3 Rf7 29. f3  Rd7 30. Qd2 e5 31. bxc4 bxc4 32. Kf2 Kf7 33. Ke3 Ke6 34. Qb4 Rc7 35. Kd2 Rc6 36. a4 1-0 "

; sample game 55
EventSites(55) = "World Championship 20th  Moscow" : GameDates(55) = "19540318" : WhitePlayers(55) = "Botvinnik, Mikhail   G#55" : WhiteElos(55) = "n/a" : BlackPlayers(55) = "Smyslov, Vassily   G#55" : BlackElos(55) = "n/a" : Each_Game_Result(55) = "1-0"

FilePGNs(55) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 b6 5. Ne2 Ba6 6. a3 Be7 7. Nf4 d5 8. cxd5 Bxf1 9. Kxf1 exd5 10. g4  c6 11. g5 Nfd7 12. h4 Bd6  13. e4  dxe4 14. Nxe4 Bxf4 15. Bxf4 O-O 16. h5  Re8 17. Nd6 Re6 18. d5  Rxd6 19. Bxd6 Qxg5 20. Qf3  Qxd5 21. Qxd5 cxd5 22. Rc1 Na6 23. b4  h6 24. Rh3 Kh7 25. Rd3 Nf6 26. b5 Nc5 27. Bxc5 bxc5 28. Rxc5 Rb8 29. a4 Rb7 30. Rdc3 1-0 "

; sample game 56
EventSites(56) = "World Championship 20th  Moscow" : GameDates(56) = "19540415" : WhitePlayers(56) = "Botvinnik, Mikhail   G#56" : WhiteElos(56) = "n/a" : BlackPlayers(56) = "Smyslov, Vassily   G#56" : BlackElos(56) = "n/a" : Each_Game_Result(56) = "0-1"

FilePGNs(56) = "1. d4 Nf6 2. c4 g6 3. g3 Bg7 4. Bg2 O-O 5. Nc3 d6 6. Nf3 Nbd7 7. O-O e5 8. e4 c6 9. Be3 Ng4  10. Bg5 Qb6 11. h3 exd4  12. Na4 Qa6 13. hxg4 b5 14. Nxd4 bxa4 15. Nxc6 Qxc6 16. e5 Qxc4 17. Bxa8 Nxe5 18. Rc1 Qb4  19. a3 Qxb2 20. Qxa4 Bb7  21. Rb1  Nf3+ 22. Kh1 Bxa8  23. Rxb2 Nxg5+ 24. Kh2 Nf3+ 25. Kh3 Bxb2 26. Qxa7 Be4 27. a4 Kg7 28. Rd1 Be5 29. Qe7 Rc8 30. a5 Rc2 31. Kg2 Nd4+ 32. Kf1 Bf3 33. Rb1 Nc6 0-1 "

; sample game 57
EventSites(57) = "World Championship 23th  Moscow" : GameDates(57) = "19600402" : WhitePlayers(57) = "Tal, Mihail   G#57" : WhiteElos(57) = "n/a" : BlackPlayers(57) = "Botvinnik, Mikhail   G#57" : BlackElos(57) = "n/a" : Each_Game_Result(57) = "0-1"

FilePGNs(57) = "1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Bf5 5. Ng3 Bg6 6. N1e2 Nf6 7. h4 h6 8. Nf4 Bh7 9. Bc4 e6 10. O-O Bd6 11. Nxe6  fxe6 12. Bxe6 Qc7 13. Re1 Nbd7 14. Bg8+ Kf8 15. Bxh7 Rxh7 16. Nf5 g6  17. Bxh6+ Kg8 18. Nxd6 Qxd6 19. Bg5 Re7 20. Qd3 Kg7 21. Qg3  Rxe1+ 22. Rxe1 Qxg3 23. fxg3 Rf8  24. c4 Ng4 25. d5 cxd5 26. cxd5 Ndf6 27. d6 Rf7 28. Rc1 Rd7 29. Rc7 Kf7 30. Bxf6 Nxf6 31. Kf2 Ke6 32. Rxd7 Kxd7 33. Kf3 Kxd6 34. Kf4 Ke6 35. g4 Nd5+ 36. Ke4 Nf6+ 37. Kf4 Nd5+ 38. Ke4 Nb4 39. a3 Nc6 40. h5 g5 41. h6 Kf6 42. Kd5 Kg6 43. Ke6 Na5 44. a4 Nb3 45. Kd6 a5 46. Kd5 Kxh6 47. Kc4 Nc1 48. Kb5 Nd3 49. b3 Nc1 50. Kxa5 Nxb3+ 51. Kb4 Nc1 52. Kc3 Kg6 53. Kc2 Ne2 54. Kd3 Nc1+ 55. Kc2 Ne2 56. Kd3 Nf4+ 57. Kc4 Kf6 58. g3 Ne2 0-1 "

; sample game 58
EventSites(58) = "World Championship 25th  Moscow" : GameDates(58) = "19630424" : WhitePlayers(58) = "Botvinnik, Mikhail   G#58" : WhiteElos(58) = "n/a" : BlackPlayers(58) = "Petrosian, Tigran V   G#58" : BlackElos(58) = "n/a" : Each_Game_Result(58) = "1-0"

FilePGNs(58) = "1. d4 d5 2. c4 e6 3. Nc3 Be7 4. cxd5 exd5 5. Bf4 c6 6. e3 Bf5 7. g4  Be6 8. h3 Nf6 9. Bd3 c5 10. Nf3 Nc6 11. Kf1  O-O 12. Kg2 cxd4 13. Nxd4 Nxd4 14. exd4 Nd7 15. Qc2 Nf6 16. f3 Rc8 17. Be5 Bd6 18. Rae1 Bxe5 19. Rxe5 g6 20. Qf2 Nd7 21. Re2 Nb6 22. Rhe1 Nc4 23. Bxc4 Rxc4 24. Rd2 Re8 25. Re3 a6 26. b3 Rc6 27. Na4 b6 28. Nb2 a5 29. Nd3 f6 30. h4 Bf7 31. Rxe8+ Bxe8 32. Qe3 Bf7 33. g5 Be6 34. Nf4 Bf7 35. Nd3 Be6 36. gxf6 Qxf6 37. Qg5 Qxg5+ 38. hxg5 a4 39. bxa4 Rc4 40. a5 bxa5 41. Nc5 Bf5 42. Kg3 a4 43. Kf4 a3 44. Ke5 Rb4 45. Nd3 Rb5 46. Kd6 Kf7 47. Kc6 Bxd3 48. Rxd3 Rb2 49. Rxa3 Rg2 50. Kxd5 Rxg5+ 51. Kc6 h5 52. d5 Rg2 53. d6 Rc2+ 54. Kd7 h4 55. f4 Rf2 56. Kc8 Rxf4 57. Ra7+ 1-0 "

; sample game 59
EventSites(59) = "Moscow  Moscow" : GameDates(59) = "198104??" : WhitePlayers(59) = "Kasparov, Garry   G#59" : WhiteElos(59) = "2625" : BlackPlayers(59) = "Petrosian, Tigran V   G#59" : BlackElos(59) = "2585" : Each_Game_Result(59) = "0-1"

FilePGNs(59) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. a3 Bb7 5. Nc3 d5 6. cxd5 Nxd5 7. e3 Be7 8. Bb5+ c6 9. Bd3 Nxc3 10. bxc3 c5 11. O-O O-O  12. Qc2 g6 13. e4 Nc6 14. Bh6  Re8 15. Rfd1 Qc7 16. Qe2 Red8 17. Qe3  e5 18. d5 Na5 19. c4 Nb3 20. Ra2 f6 21. h4 Bc8  22. Rb1  Nd4 23. Nxd4 cxd4 24. Qg3  Bf8 25. Bd2  Bd6 26. Rf1 Qg7 27. a4 a5 28. Rb2  Bc5 29. f4 Bd7  30. h5  Bxa4 31. h6 Qc7 32. f5  g5 33. Bxg5  fxg5  34. Qxg5+ Kf8 35. Qf6+  Ke8 36. Ra1 Qe7   37. Qe6  Rd6  38. Qg8+ Qf8 39. Qg3 Qxh6  40. Rxa4  Qc1+ 41. Kf2 Qxb2+ 42. Kf3 Kf7 0-1 "

; sample game 60
EventSites(60) = "World Championship 31th-KK1  Moscow" : GameDates(60) = "19841005" : WhitePlayers(60) = "Karpov, Anatoly   G#60" : WhiteElos(60) = "2705" : BlackPlayers(60) = "Kasparov, Garry   G#60" : BlackElos(60) = "2715" : Each_Game_Result(60) = "1-0"

FilePGNs(60) = "1. d4 d5 2. c4 e6 3. Nf3 c5 4. cxd5 exd5 5. g3 Nf6 6. Bg2 Be7 7. O-O O-O 8. Nc3 Nc6 9. Bg5 cxd4 10. Nxd4 h6 11. Be3 Re8 12. Qb3 Na5 13. Qc2 Bg4 14. Nf5 Rc8 15. Bd4 Bc5 16. Bxc5 Rxc5 17. Ne3 Be6 18. Rad1 Qc8 19. Qa4 Rd8 20. Rd3 a6 21. Rfd1 Nc4 22. Nxc4 Rxc4 23. Qa5 Rc5 24. Qb6 Rd7 25. Rd4 Qc7 26. Qxc7 Rdxc7 27. h3 h5 28. a3 g6 29. e3 Kg7 30. Kh2 Rc4 31. Bf3 b5 32. Kg2 R7c5 33. Rxc4 Rxc4 34. Rd4 Kf8 35. Be2 Rxd4 36. exd4 Ke7 37. Na2 Bc8 38. Nb4 Kd6 39. f3 Ng8 40. h4 Nh6 41. Kf2 Nf5 42. Nc2 f6 43. Bd3 g5 44. Bxf5 Bxf5 45. Ne3 Bb1 46. b4 gxh4  47. Ng2  hxg3+ 48. Kxg3 Ke6 49. Nf4+ Kf5 50. Nxh5 Ke6 51. Nf4+ Kd6 52. Kg4 Bc2 53. Kh5 Bd1 54. Kg6 Ke7 55. Nxd5+ Ke6 56. Nc7+ Kd7 57. Nxa6 Bxf3 58. Kxf6 Kd6 59. Kf5 Kd5 60. Kf4 Bh1 61. Ke3 Kc4 62. Nc5 Bc6 63. Nd3 Bg2 64. Ne5+ Kc3 65. Ng6 Kc4 66. Ne7 Bb7 67. Nf5 Bg2 68. Nd6+ Kb3 69. Nxb5 Ka4 70. Nd6 1-0 "

; sample game 61
EventSites(61) = "Thessaloniki ol (Men)  Thessaloniki" : GameDates(61) = "1988????" : WhitePlayers(61) = "Knaak, Rainer   G#61" : WhiteElos(61) = "2500" : BlackPlayers(61) = "Speelman, Jonathan S   G#61" : BlackElos(61) = "2645" : Each_Game_Result(61) = "0-1"

FilePGNs(61) = "1. d4 d6 2. c4 e5 3. Nf3 e4 4. Ng5 f5 5. Nc3 c6 6. Nh3 Na6  7. e3 Nf6 8. d5  g6  9. b3 Bg7 10. Bb2 O-O 11. Qd2 Ng4  12. Be2 Nc5 13. Rd1  Qh4  14. Na4 f4  15. Bxg7 fxe3 16. Qc3 Rxf2 17. Bh8 Rxg2+ 18. Kf1 Ne5  0-1 "

; sample game 62
EventSites(62) = "Hoogovens  Wijk aan Zee" : GameDates(62) = "198901??" : WhitePlayers(62) = "Nikolic, Predrag   G#62" : WhiteElos(62) = "2605" : BlackPlayers(62) = "Piket, Jeroen   G#62" : BlackElos(62) = "2500" : Each_Game_Result(62) = "1-0"

FilePGNs(62) = "1. Nf3 Nf6 2. d4 d5 3. Bf4 Bf5 4. c4 c6 5. e3 e6 6. Nc3 Nbd7 7. Qb3 Qb6 8. c5  Qxb3 9. axb3 a6 10. b4 Rc8 11. h3 h6  12. Nd2 Be7 13. Nb3 Bd8 14. Bd6  Ne4 15. Nxe4 Bxe4 16. f3 Bg6 17. Na5 Bxa5 18. bxa5 Kd8 19. Ra4 Ra8 20. Rb4 Kc8 21. h4  h5 22. Rh3  Bf5 23. Rg3 g6 24. Kd2 Re8 25. Rg5  f6  26. Rg3 g5 27. Bd3  g4 28. e4 dxe4 29. fxe4 Bg6 30. Bc2  f5 31. e5 Rg8 32. Rgb3 Ra7 33. Bd3 Nb8 34. Ke3  Rg7 35. Kf4 Bf7 36. Rb6 Be8 37. d5  cxd5 38. Bxb8 Kxb8 39. Rxe6 Ba4 40. Rb4 g3 41. Bxf5 1-0 "

; sample game 63
EventSites(63) = "Candidates qf3  Quebec" : GameDates(63) = "1989????" : WhitePlayers(63) = "Jussupow, Artur   G#63" : WhiteElos(63) = "2610" : BlackPlayers(63) = "Spraggett, Kevin   G#63" : BlackElos(63) = "2575" : Each_Game_Result(63) = "1-0"

FilePGNs(63) = "1. d4 d5 2. Nf3 c5 3. c4 e6 4. cxd5 exd5 5. Nc3 Nc6 6. g3 Nf6 7. Bg2 Be7 8. O-O O-O 9. Bg5 Be6  10. dxc5 Bxc5 11. Bxf6 Qxf6 12. Nxd5 Qxb2 13. Nc7 Rad8 14. Qc1  Qxc1 15. Raxc1 Be7 16. Nxe6 fxe6 17. Rc4 Bf6 18. e3 Rd6 19. h4 h6 20. Re4 Rfd8 21. Bh3 Kf7 22. Kg2 Re8 23. Rc1 Re7 24. Rc2 b6  25. Rf4  Kg6  26. g4  Ba1 27. Rc1 Bb2 28. Rc2 Ba1 29. a4  Ne5 30. Nxe5+ Bxe5 31. Rf8 Rdd7 32. f4 Rc7 33. Rd2 Bc3 34. Rd6 Kh7 35. g5 hxg5 36. hxg5 Bb4 37. Rdd8  Kg6  38. Kf3 Rf7 39. Rh8 e5 40. Bg4 exf4 41. Rd5  fxe3+ 42. Kg3 1-0 "

; sample game 64
EventSites(64) = "World Cup  Reykjavik" : GameDates(64) = "1991????" : WhitePlayers(64) = "Karpov, Anatoly   G#64" : WhiteElos(64) = "2730" : BlackPlayers(64) = "Speelman, Jonathan S   G#64" : BlackElos(64) = "2630" : Each_Game_Result(64) = "1-0"

FilePGNs(64) = "1. e4 e6 2. d4 d5 3. Nd2 dxe4 4. Nxe4 Nd7 5. Nf3 Ngf6 6. Nxf6+ Nxf6 7. Bd3 c5 8. dxc5 Bxc5 9. Qe2 O-O  10. Bg5 Qa5+ 11. c3 Be7 12. Ne5 h6 13. Bh4 Rd8 14. O-O Qc7 15. Rad1 b6 16. Rfe1  Bb7  17. Nxf7  Qc6  18. Be4  Qxe4 19. Qxe4 Rxd1  20. Nxh6+  Kf8 21. Qxe6 Rxe1+ 22. Qxe1 gxh6 23. Bxf6 Bxf6 24. Qe6 Bg7 25. Qd6+ Ke8 26. Qg6+ Kf8 27. Qd6+ Ke8 28. Qc7 Rd8 29. f3 Rd1+ 30. Kf2 Rd2+ 31. Kg1 Rd1+ 32. Kf2 Rd2+ 33. Ke3 Rd7 34. Qb8+ Kf7 35. Qxa7 Re7+ 36. Kf2 Bxf3 37. Qxb6 Bd5 38. Qa5 Re5 39. g3 Bf6 40. h4 Be6 41. Qc7+ Kg6 42. a4 Bg4 43. Qc4 h5 44. Qa6 Rf5+ 45. Ke1 Rd5 46. Qb7 Rd7 47. Qb5 Bd8 48. a5 Bc7 49. Kf2 Rf7+ 50. Ke3 Re7+ 51. Kd2 Bxg3  52. Qd3+ 1-0 "

; sample game 65
EventSites(65) = "World Championship PCA  London" : GameDates(65) = "19931002" : WhitePlayers(65) = "Short, Nigel D   G#65" : WhiteElos(65) = "2655" : BlackPlayers(65) = "Kasparov, Garry   G#65" : BlackElos(65) = "2805" : Each_Game_Result(65) = "1/2-1/2"

FilePGNs(65) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bc4 e6 7. Bb3 Nc6 8. f4 Be7 9. Be3 O-O 10. Qf3 Nxd4 11. Bxd4 b5 12. Bxf6 Bxf6 13. e5 Bh4+ 14. g3 Rb8 15. gxh4 Bb7 16. Ne4 dxe5  17. Rg1 g6 18. Rd1 Bxe4 19. Qxe4 Qxh4+ 20. Ke2 Qxh2+  21. Rg2 Qxf4 22. Qxf4 exf4 23. Kf3 Rfd8 24. Rxd8+ Rxd8 25. Kxf4 Kf8 26. Ke3 Ke7 27. c4 h5 28. a4 bxa4  29. Bxa4 h4 30. c5  Rh8 31. Rc2 h3 32. Bc6 e5 33. Kf2 h2 34. Rc1 a5  35. Bd5 Rd8 36. Bg2 Rd2+ 37. Kg3 Kd7 38. Ra1 f5 39. Kxh2  Rxb2 40. Rxa5 e4 1/2-1/2 "

; sample game 66
EventSites(66) = "World Championship PCA  New York" : GameDates(66) = "19950914" : WhitePlayers(66) = "Anand, Viswanathan   G#66" : WhiteElos(66) = "2725" : BlackPlayers(66) = "Kasparov, Garry   G#66" : BlackElos(66) = "2795" : Each_Game_Result(66) = "1/2-1/2"

FilePGNs(66) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be2 e6 7. O-O Be7 8. a4 Nc6 9. Be3 O-O 10. f4 Qc7 11. Kh1 Re8 12. Bd3 Nb4 13. a5 Bd7 14. Nf3  Bc6  15. Bb6 Qc8  16. Qe1 Nd7 17. Bd4 Nc5  18. Qg3 f6 19. e5  Rf8  20. Bxc5  dxc5 21. Bc4 Bd5  22. Nxd5 exd5  23. Bb3 c4 24. Ba4 Nc6 25. c3 fxe5 26. Nxe5 Nxe5 27. fxe5 Qe6 28. Bc2 Rxf1+ 29. Rxf1 Rf8 30. Rxf8+ Bxf8 31. Qf4 g6 32. Bd1 Qf7 33. Qd4  Qf1+ 34. Qg1 Qxg1+ 35. Kxg1 Kf7 36. Bg4 b6 1/2-1/2 "

; sample game 67
EventSites(67) = "World Championship PCA  New York" : GameDates(67) = "19950919" : WhitePlayers(67) = "Kasparov, Garry   G#67" : WhiteElos(67) = "2795" : BlackPlayers(67) = "Anand, Viswanathan   G#67" : BlackElos(67) = "2725" : Each_Game_Result(67) = "1/2-1/2"

FilePGNs(67) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Nxe4 6. d4 b5 7. Bb3 d5 8. dxe5 Be6 9. Nbd2 Nc5 10. c3 d4 11. Ng5  dxc3 12. Nxe6 fxe6 13. bxc3 Qd3 14. Nf3 O-O-O  15. Qe1 Nxb3 16. axb3 Kb7 17. Be3 Be7 18. Bg5 h6 19. Bxe7 Nxe7 20. Nd4  Rxd4  21. cxd4 Qxb3 22. Qe3  Qxe3  23. fxe3 Nd5 24. Kf2 Kb6 25. Ke2 a5 26. Rf7 a4 27. Kd2 c5  28. e4  1/2-1/2 "

; sample game 68
EventSites(68) = "World Championship PCA  New York" : GameDates(68) = "19950922" : WhitePlayers(68) = "Kasparov, Garry   G#68" : WhiteElos(68) = "2795" : BlackPlayers(68) = "Anand, Viswanathan   G#68" : BlackElos(68) = "2725" : Each_Game_Result(68) = "1/2-1/2"

FilePGNs(68) = "1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Nf6 5. Nxc6 bxc6 6. e5 Qe7 7. Qe2 Nd5 8. c4 Ba6 9. b3 g5  10. Ba3 d6 11. exd6 Qxe2+ 12. Bxe2 Bg7  13. cxd5 Bxe2 14. Kxe2 Bxa1 15. Rc1 O-O-O   16. Rxc6 Rhe8+ 17. Kd3 Rd7 18. Nc3  Bxc3  19. Kxc3  Re5 20. Kc4 Re4+ 21. Kd3 Re5 22. Kc4 Re4+ 1/2-1/2 "

; sample game 69
EventSites(69) = "World Championship PCA  New York" : GameDates(69) = "19950925" : WhitePlayers(69) = "Anand, Viswanathan   G#69" : WhiteElos(69) = "2725" : BlackPlayers(69) = "Kasparov, Garry   G#69" : BlackElos(69) = "2795" : Each_Game_Result(69) = "1-0"

FilePGNs(69) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be2 e6 7. O-O Be7 8. a4 Nc6 9. Be3 O-O 10. f4 Qc7 11. Kh1 Re8 12. Bf3 Bd7 13. Nb3 Na5 14. Nxa5 Qxa5 15. Qd3 Rad8 16. Rfd1  Bc6 17. b4 Qc7 18. b5 Bd7 19. Rab1   axb5 20. Nxb5  Bxb5 21. Qxb5 Ra8 22. c4 e5 23. Bb6  Qc8 24. fxe5 dxe5 25. a5 Bf8 26. h3 Qe6 27. Rd5  Nxd5  28. exd5  Qg6 29. c5 e4 30. Be2 Re5 31. Qd7  Rg5 32. Rg1  e3 33. d6 Rg3 34. Qxb7 Qe6 35. Kh2  1-0 "

; sample game 70
EventSites(70) = "World Championship PCA  New York" : GameDates(70) = "19951009" : WhitePlayers(70) = "Anand, Viswanathan   G#70" : WhiteElos(70) = "2725" : BlackPlayers(70) = "Kasparov, Garry   G#70" : BlackElos(70) = "2795" : Each_Game_Result(70) = "1/2-1/2"

FilePGNs(70) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 g6 6. Be3 Bg7 7. f3 O-O 8. Qd2 Nc6 9. Bc4 Bd7 10. h4 h5 11. O-O-O Rc8 12. Bb3 Ne5 13. Bg5 Rc5 14. Kb1 Re8 15. Rhe1 Qa5 16. a3  b5  17. Bxf6  exf6 18. Nde2  Rc6 19. Nd5 Qxd2 20. Rxd2 Nc4 21. Bxc4 bxc4 22. Red1  f5 23. exf5 Bxf5 24. Nd4 Bxd4 25. Rxd4 Re2 26. R4d2 Rxd2 27. Rxd2 Kf8 28. Kc1  Be6 29. Rd4 Bxd5  30. Rxd5 Ke7 31. Rb5  Ke6 32. Rb7 Rc5  33. Rxa7 g5 34. Ra8 gxh4 35. Re8+  Kd7 36. Re4 c3 37. Rxh4  cxb2+ 38. Kxb2 Rg5 39. a4 f5 40. a5 f4 41. a6 Kc7 42. Rxf4 Rxg2 43. Rf7+ Kb8 44. Kc3 h4 45. Kd3 Rf2 46. c4  Ra2  47. Ke4 Rxa6 48. Rh7 Ra5 49. f4 Kc8 50. f5 Kd8 51. Kf4 Rc5 52. Kg5 Rxc4 53. Kg6 Rg4+ 54. Kf7 d5 55. f6 Kd7 56. Kf8+ Ke6 57. f7 Rf4 58. Kg8 d4 59. f8=Q Rxf8+ 60. Kxf8 Ke5 61. Rxh4 d3 62. Rh3 Ke4 63. Rxd3 1/2-1/2 "

; sample game 71
EventSites(71) = "Hoogovens  Wijk aan Zee" : GameDates(71) = "19960121" : WhitePlayers(71) = "Ivanchuk, Vassily   G#71" : WhiteElos(71) = "2735" : BlackPlayers(71) = "Piket, Jeroen   G#71" : BlackElos(71) = "2570" : Each_Game_Result(71) = "1-0"

FilePGNs(71) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. Be3 Nbd7 8. O-O c6 9. d5 Ng4 10. Bd2 f5  11. Ng5 Ndf6 12. b4 cxd5 13. cxd5 fxe4  14. Ne6  Bxe6 15. dxe6 Nh6 16. g4  d5 17. Bg5  Rc8 18. e7  Qxe7 19. Nxd5 Qe6 20. Nxf6+ Rxf6 21. Bxf6 Qxf6 22. Qd5+ Nf7 23. Bc4 Rxc4 24. Qxc4 Qf3 25. Qe6 Bh6 26. Rad1 e3 27. Rd7 1-0 "

; sample game 72
EventSites(72) = "Philadelphia m  Philadelphia" : GameDates(72) = "19960210" : WhitePlayers(72) = "Comp Deep Blue   G#72" : WhiteElos(72) = "2735" : BlackPlayers(72) = "Kasparov, Garry   G#72" : BlackElos(72) = "2795" : Each_Game_Result(72) = "1-0"

FilePGNs(72) = "1. e4 c5 2. c3 d5 3. exd5 Qxd5 4. d4 Nf6 5. Nf3 Bg4 6. Be2 e6 7. h3 Bh5 8. O-O Nc6 9. Be3 cxd4 10. cxd4 Bb4  11. a3 Ba5 12. Nc3 Qd6 13. Nb5 Qe7 14. Ne5 Bxe2 15. Qxe2 O-O 16. Rac1 Rac8 17. Bg5 Bb6 18. Bxf6 gxf6 19. Nc4  Rfd8 20. Nxb6 axb6 21. Rfd1 f5 22. Qe3 Qf6 23. d5  Rxd5 24. Rxd5 exd5 25. b3  Kh8 26. Qxb6 Rg8 27. Qc5 d4  28. Nd6 f4 29. Nxb7 Ne5 30. Qd5 f3 31. g3 Nd3 32. Rc7 Re8 33. Nd6 Re1+ 34. Kh2 Nxf2 35. Nxf7+ Kg7 36. Ng5+ Kh6 37. Rxh7+ 1-0 "

; sample game 73
EventSites(73) = "St Petersburg  St . Petersburg" : GameDates(73) = "19970420" : WhitePlayers(73) = "Khalifman, Alexander   G#73" : WhiteElos(73) = "2650" : BlackPlayers(73) = "Kortschnoj, Viktor   G#73" : BlackElos(73) = "2635" : Each_Game_Result(73) = "1-0"

FilePGNs(73) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Bb7 5. Bg2 Be7 6. Nc3 Ne4 7. Bd2 f5 8. d5 Bf6 9. Qc2 Qe7 10. Rd1 exd5 11. cxd5 c5  12. dxc6 dxc6 13. Nxe4   fxe4 14. Nh4  Bxh4 15. gxh4 O-O  16. Qc4+ Qf7 17. Qxf7+ Rxf7 18. Bxe4  c5  19. Bxb7 Rxb7 20. Bc3 Nc6 21. Rg1 Re8 22. Rg5 Re4 23. h5 Rbe7 24. e3 Nd4 25. Kf1 h6 26. Rd5 Nb5 27. Be1 Rf7  28. Rd8+ Kh7 29. R1d7  Rf5 30. Rd5 Rf6 31. Rb8  Rd6 32. Rf5 Rf6 33. Rxf6 gxf6 34. Rd8 c4   35. a4 c3 36. axb5 cxb2 37. Rd1 Rc4 38. Bd2   Rc5 39. Rb1 Rxb5 40. Bc3 Rc5 41. Bxb2 Rb5 42. Ke2 a5 43. Kd3 a4 44. Kc2 Rc5+ 45. Bc3 b5 46. Kd3 Rxh5 47. Bxf6 1-0 "

; sample game 74
EventSites(74) = "New York man vs machine  New York" : GameDates(74) = "19970503" : WhitePlayers(74) = "Kasparov, Garry   G#74" : WhiteElos(74) = "2785" : BlackPlayers(74) = "Comp Deep Blue   G#74" : BlackElos(74) = "2635" : Each_Game_Result(74) = "1-0"

FilePGNs(74) = "1. Nf3 d5 2. g3 Bg4 3. b3 Nd7 4. Bb2 e6 5. Bg2 Ngf6 6. O-O c6 7. d3 Bd6 8. Nbd2 O-O 9. h3 Bh5 10. e3 h6 11. Qe1 Qa5 12. a3 Bc7  13. Nh4 g5  14. Nhf3 e5 15. e4 Rfe8 16. Nh2 Qb6 17. Qc1 a5 18. Re1 Bd6 19. Ndf1 dxe4 20. dxe4 Bc5 21. Ne3 Rad8 22. Nhf1 g4 23. hxg4 Nxg4 24. f3  Nxe3 25. Nxe3 Be7  26. Kh1 Bg5 27. Re2 a4 28. b4 f5 29. exf5  e4 30. f4 Bxe2 31. fxg5 Ne5 32. g6 Bf3 33. Bc3 Qb5  34. Qf1 Qxf1+ 35. Rxf1 h5 36. Kg1  Kf8 37. Bh3 b5 38. Kf2 Kg7  39. g4 Kh6 40. Rg1 hxg4 41. Bxg4 Bxg4 42. Nxg4+ Nxg4+ 43. Rxg4 Rd5 44. f6 Rd1 45. g7 1-0 "

; sample game 75
EventSites(75) = "New York man vs machine  New York" : GameDates(75) = "19970504" : WhitePlayers(75) = "Comp Deep Blue   G#75" : WhiteElos(75) = "2785" : BlackPlayers(75) = "Kasparov, Garry   G#75" : BlackElos(75) = "2785" : Each_Game_Result(75) = "1-0"

FilePGNs(75) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 h6 10. d4 Re8 11. Nbd2 Bf8 12. Nf1 Bd7 13. Ng3 Na5 14. Bc2 c5 15. b3 Nc6 16. d5 Ne7 17. Be3 Ng6 18. Qd2 Nh7  19. a4 Nh4 20. Nxh4 Qxh4 21. Qe2  Qd8 22. b4 Qc7 23. Rec1 c4  24. Ra3 Rec8 25. Rca1 Qd8 26. f4  Nf6 27. fxe5 dxe5 28. Qf1 Ne8 29. Qf2 Nd6 30. Bb6 Qe8 31. R3a2 Be7 32. Bc5 Bf8  33. Nf5 Bxf5 34. exf5 f6 35. Bxd6  Bxd6 36. axb5  axb5 37. Be4 Rxa2 38. Qxa2 Qd7 39. Qa7 Rc7 40. Qb6 Rb7 41. Ra8+ Kf7 42. Qa6 Qc7 43. Qc6 Qb6+ 44. Kf1  Rb8 45. Ra6 h5 1-0 "

; sample game 76
EventSites(76) = "FIDE-Wch k.o.  Groningen" : GameDates(76) = "19971214" : WhitePlayers(76) = "Short, Nigel D   G#76" : WhiteElos(76) = "2660" : BlackPlayers(76) = "Sokolov, Andrei   G#76" : BlackElos(76) = "2585" : Each_Game_Result(76) = "1-0"

FilePGNs(76) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 d6 6. Be2 Nf6 7. Be3 Be7 8. O-O Bd7 9. Nb3 a6 10. f4 b5 11. a3 O-O 12. g4 Bc8 13. Qe1 Bb7 14. Rd1 b4 15. g5 bxc3  16. gxf6 Bxf6 17. e5 Bh4  18. Qxc3 d5 19. Nc5 Qc7 20. f5  d4  21. Rxd4 Nxd4 22. Qxd4 Bd5 23. Qxh4 Qxe5 24. Qd4 Qxd4 25. Bxd4 e5 26. Be3 a5 27. Rd1 1-0 "

; sample game 77
EventSites(77) = "Bad Homburg  Bad Homburg" : GameDates(77) = "19980723" : WhitePlayers(77) = "Larsen, Bent   G#77" : WhiteElos(77) = "2515" : BlackPlayers(77) = "Svidler, Peter   G#77" : BlackElos(77) = "2690" : Each_Game_Result(77) = "1/2-1/2"

FilePGNs(77) = "1. e4 c5 2. Nf3 Nc6 3. Bb5 g6 4. O-O Bg7 5. Na3  Nf6 6. Re1 O-O 7. Bxc6 bxc6 8. e5 Nd5 9. d3 d6 10. Nc4 h6 11. Bd2 Bf5  12. h3 Qd7 13. Qe2 Rae8 14. a3 Nb6 15. Bf4 g5  16. Bg3 Bg6 17. h4 Nxc4 18. dxc4 g4 19. Nh2 h5 20. Qd2 Qf5 21. exd6 exd6 22. c3  Rxe1+ 23. Rxe1 Rd8 24. Nf1 d5 25. Ne3 Qd7  26. cxd5 cxd5 27. Bf4  Re8 28. c4  d4 29. Nd5 Rxe1+ 30. Qxe1 Kh7 31. Bg5 Qf5 32. b4 cxb4 33. axb4 d3 34. Bd2 Bd4 35. Bc3 Qe4 36. Qxe4 Bxe4 37. Bxd4 Bxd5 38. Kf1 Bxg2+ 39. Ke1 a6 40. Kd2 Be4 41. Ke3 Kg6 42. Bc3 Kf5 43. Bd2 Ke5 1/2-1/2 "

; sample game 78
EventSites(78) = "Bad Homburg  Bad Homburg" : GameDates(78) = "19980726" : WhitePlayers(78) = "Jussupow, Artur   G#78" : WhiteElos(78) = "2630" : BlackPlayers(78) = "Larsen, Bent   G#78" : BlackElos(78) = "2515" : Each_Game_Result(78) = "1-0"

FilePGNs(78) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 O-O 5. Bd3 c5 6. a3 Bxc3+ 7. bxc3 d6 8. Ne2 Nc6 9. O-O e5 10. d5 Ne7 11. Ng3 Re8 12. Qc2 Kh8  13. f4 exf4 14. exf4 Ng6 15. f5  Ne5 16. Bg5 Qc7 17. a4 b6 18. Rf4 Ba6 19. Be2 Ned7 20. Rh4 Re5 21. Bd3 Rae8 22. Qd2 Qb8 23. Rf1 Rg8 24. Rf3 Rge8 25. Qf4 Re1+ 26. Nf1 Qd8 27. Rfh3 Nf8 28. Rg3 N8d7 29. Qf2 Qe7  30. Rxh7+  Kxh7 31. Rh3+ Kg8 32. Qh4 Kf8 33. Qh8+ Ng8 34. Bxe7+ R8xe7 35. Qh4 Ne5 36. Qf4 Nxd3 37. Rxd3 R7e5 38. Rg3  Nf6 39. Qh4 Rxf5  40. Qh8+ Ke7 41. Re3+ Rxe3 42. Nxe3 Re5 43. Kf2 Ne4+ 44. Ke1 Nxc3 45. Qb8 Bxc4 46. Qxa7+ Kf6 47. Kf2 Rxe3 48. Kxe3 Nxd5+ 49. Kd2 Ke6 50. h4 Bb3 51. Qa8 c4 52. Qe8+ Kf6 53. g4 c3+ 54. Kd3 c2 55. Kd2 Nb4 56. Qe4 1-0 "

; sample game 79
EventSites(79) = "RUS-ch51  St . Petersburg" : GameDates(79) = "19980805" : WhitePlayers(79) = "Dreev, Alexey   G#79" : WhiteElos(79) = "2645" : BlackPlayers(79) = "Shchekachev, Andrei   G#79" : BlackElos(79) = "2560" : Each_Game_Result(79) = "1/2-1/2"

FilePGNs(79) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. f3 O-O 6. Nge2 c5 7. d5 e6 8. Ng3 exd5 9. cxd5 Nh5 10. Nxh5 gxh5 11. Bd3 f5 12. O-O Na6 13. Bf4 fxe4 14. fxe4 c4 15. Bxc4 Qb6+ 16. Kh1 Qxb2 17. Bxd6 Bg4 18. Qb3 Bxc3 19. Qxb2 Bxb2 20. Rae1 Rxf1+ 21. Bxf1 Bd4 22. h3 1/2-1/2 "

; sample game 80
EventSites(80) = "Harplinge  Harplinge" : GameDates(80) = "19980817" : WhitePlayers(80) = "Sutovsky, Emil   G#80" : WhiteElos(80) = "2575" : BlackPlayers(80) = "Hodgson, Julian M   G#80" : BlackElos(80) = "2575" : Each_Game_Result(80) = "1-0"

FilePGNs(80) = "1. e4 c5 2. Nf3 Nc6 3. Bb5 d6 4. d4  cxd4 5. Qxd4 Bd7 6. Bxc6 Bxc6 7. Nc3 Nf6 8. Bg5 e6 9. O-O-O Be7 10. Rhe1 O-O 11. Qd2 h6  12. Bf4 e5 13. Bg3 b5 14. Bh4 g5  15. Bxg5 hxg5 16. Nxe5 Be8 17. Qxg5+ Kh8 18. Nf3  Nh7 19. Qf4 Rc8 20. e5 Rxc3  21. bxc3 d5 22. Kb1  Rg8  23. e6  f6 24. Nd4 Qa5 25. Nf5 Bc5 26. Rd3 b4 27. Rh3 Bg6 28. Qh4 Qd8  29. e7 Qb6  30. e8=Q  bxc3+ 31. Kc1 Qb2+ 32. Kd1 Qb1+ 33. Ke2 Rxe8+ 34. Kf3 Re3+ 35. Rxe3 Qd1+ 36. Kg3 Kg8 37. Qf4 Bxe3 38. Qb8+ Kf7 39. Qc7+ Ke6 40. Ng7# 1-0 "

; sample game 81
EventSites(81) = "Elista ol (Men)  Elista" : GameDates(81) = "19981004" : WhitePlayers(81) = "Lautier, Joel   G#81" : WhiteElos(81) = "2625" : BlackPlayers(81) = "Topalov, Veselin   G#81" : BlackElos(81) = "2700" : Each_Game_Result(81) = "0-1"

FilePGNs(81) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 c5 5. Ne2 cxd4 6. exd4 O-O 7. a3 Be7 8. d5 exd5 9. cxd5 Bc5 10. Nd4  d6 11. Be2 a6 12. O-O Nbd7 13. Be3 Ne5 14. h3 Re8 15. b4  Bb6 16. Qb3 Bd7 17. a4 Rc8 18. Rac1 Ng6  19. Rfd1  Rxe3   20. fxe3 Qe7 21. Na2 Rxc1 22. Nxc1 Bxa4  23. Qxa4 Qxe3+ 24. Kh1 Ne4  25. Nf5 Nf2+ 26. Kh2 Qe5+ 27. Ng3 Ne4 28. Qb3 Bf2 29. Rd3 h5   30. Bxh5 Nxg3 31. Rxg3 Qxh5  32. Rxg6 Qxg6 33. Qf3 Bd4 34. Nd3 Qg5 35. Qe4 Qe3 36. Qxe3 Bxe3 37. Kg3 g6 38. Kf3 Bd4 39. Ke2 Kg7 40. Ne1 Kf6 41. Kd3 Bf2 42. Nf3 Kf5 43. Ke2 Ba7 0-1 "

; sample game 82
EventSites(82) = "Oxford GM-A  Oxford" : GameDates(82) = "19981222" : WhitePlayers(82) = "Hodgson, Julian M   G#82" : WhiteElos(82) = "2575" : BlackPlayers(82) = "Wells, Peter K   G#82" : BlackElos(82) = "2515" : Each_Game_Result(82) = "1-0"

FilePGNs(82) = "1. d4 Nf6 2. Bg5 Ne4 3. Bf4 d5 4. e3 c5 5. Bd3  cxd4 6. Bxe4 dxe4 7. exd4 Nc6 8. Ne2 Bg4 9. Nbc3 e6 10. h3 Bh5 11. Nxe4 Bxe2 12. Qxe2 Nxd4 13. Qd3 Nc6 14. O-O-O Qxd3 15. Rxd3 Nb4  16. Rb3 Nd5 17. Bg3 b6 18. Rd1 Rc8 19. Kb1 Rc6  20. Rd4  Be7 21. c4 Nf6 22. Nd6+ Bxd6 23. Bxd6 Nd7 24. Rg3  g6 25. Rgd3 f6 26. Be7  Ne5 27. Ra3  Nxc4 28. Rxa7 e5 29. Rd8+ Kf7 30. Bb4+  1-0 "

; sample game 83
EventSites(83) = "Hoogovens  Wijk aan Zee" : GameDates(83) = "19990120" : WhitePlayers(83) = "Kasparov, Garry   G#83" : WhiteElos(83) = "2812" : BlackPlayers(83) = "Topalov, Veselin   G#83" : BlackElos(83) = "2700" : Each_Game_Result(83) = "1-0"

FilePGNs(83) = "1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. Be3 Bg7  5. Qd2 c6 6. f3 b5 7. Nge2 Nbd7 8. Bh6 Bxh6 9. Qxh6 Bb7 10. a3  e5 11. O-O-O Qe7 12. Kb1 a6 13. Nc1  O-O-O 14. Nb3 exd4  15. Rxd4 c5 16. Rd1 Nb6 17. g3 Kb8 18. Na5  Ba8 19. Bh3 d5 20. Qf4+ Ka7 21. Rhe1 d4 22. Nd5 Nbxd5 23. exd5 Qd6 24. Rxd4  cxd4  25. Re7+  Kb6 26. Qxd4+ Kxa5 27. b4+ Ka4 28. Qc3  Qxd5 29. Ra7 Bb7  30. Rxb7 Qc4  31. Qxf6 Kxa3 32. Qxa6+ Kxb4 33. c3+  Kxc3 34. Qa1+ Kd2  35. Qb2+ Kd1 36. Bf1  Rd2  37. Rd7  Rxd7 38. Bxc4 bxc4  39. Qxh8 Rd3 40. Qa8 c3 41. Qa4+ Ke1 42. f4 f5 43. Kc1 Rd2 44. Qa7 1-0 "

; sample game 84
EventSites(84) = "RUS-Cup03 (Geller mem)  Moscow" : GameDates(84) = "19990214" : WhitePlayers(84) = "Filipenko, Alexander V   G#84" : WhiteElos(84) = "2360" : BlackPlayers(84) = "Tunik, Gennady   G#84" : BlackElos(84) = "2474" : Each_Game_Result(84) = "0-1"

FilePGNs(84) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. Nc3 Bb4 5. Qb3 a5 6. Bg5 Bb7 7. e3 h6 8. Bh4 d6 9. Bd3 Nbd7 10. O-O-O Bxc3 11. Qxc3 g5 12. Bg3 Ne4 13. Qc2 f5 14. Ne1 Qf6 15. f3 Nxg3 16. hxg3 O-O-O 17. Qc3 f4 18. gxf4 gxf4 19. e4 e5 20. d5 Rdg8 21. a3 Kd8  22. Bc2 Ke7 23. Rh2 Ra8  24. Nd3 h5 25. Rdh1 Qg5 26. Ba4 Nf6 27. Bb5 h4 28. Qe1 h3  29. Rxh3 Rxh3 30. gxh3 Rg8 31. h4 Qg3 32. Qxg3 Rxg3 33. Ne1 Nh5 34. Kd2 Rg8 35. Rh2 Bc8 36. Rg2 Ng3 37. Kd3 Bh3 38. Rh2 Bf1+ 39. Kd2 Rh8 40. b3 Kf6 41. Nc2 Rg8  42. b4  Bg2   43. c5 Bxf3 44. cxb6 cxb6 45. Kc3 Bxe4 46. Bc4 Rc8 47. Kb3 Nf5 0-1 "

; sample game 85
EventSites(85) = "Mitropa Cup  Baden" : GameDates(85) = "19990401" : WhitePlayers(85) = "Acs, Peter   G#85" : WhiteElos(85) = "2521" : BlackPlayers(85) = "Zelcic, Robert   G#85" : BlackElos(85) = "2554" : Each_Game_Result(85) = "0-1"

FilePGNs(85) = "1. e4 c6 2. d4 d5 3. exd5 cxd5 4. c4 e6 5. Nc3 Nf6 6. Nf3 Bb4 7. Bd3 dxc4 8. Bxc4 O-O 9. O-O b6 10. Bg5 Bb7 11. Re1 Nbd7 12. Rc1 Rc8 13. Bd3 Re8  14. Qe2 Bxc3 15. bxc3 Qc7 16. c4 h6 17. Bh4 Qf4 18. Bg3 Qg4 19. Qe3 Bxf3 20. gxf3 Qh5 21. Rb1 Qa5 22. Re2  Qa4 23. Rb3 Rxc4  24. Bxc4 Qxc4 25. Rc3 Qa6 26. Ra3 Qb7 27. Rc2 Nd5 28. Qe2 a5 29. Ra4 f5 30. Be5 Nxe5 31. Qxe5 Qf7  32. Rac4 Nb4 33. Rd2 Kh7 34. a3 Nd5 35. Rdc2 Qh5 36. Rc8  Qxf3 37. R2c7 Qd1+ 38. Kg2 Qg4+ 39. Kf1 Rxc8 40. Rxc8 Nf4 41. Rc3 Qg2+ 42. Ke1 Qg1+ 43. Kd2 Qxf2+ 44. Kd1 Qg1+ 45. Kc2 Qxh2+ 46. Kb3 Qd2 47. Rc7 Qd1+ 48. Ka2 Qe2+ 0-1 "

; sample game 86
EventSites(86) = "Frankfurt-West Masters  Frankfurt" : GameDates(86) = "19990701" : WhitePlayers(86) = "Leko, Peter   G#86" : WhiteElos(86) = "2694" : BlackPlayers(86) = "Comp Fritz 6   G#86" : BlackElos(86) = "2554" : Each_Game_Result(86) = "0-1"

FilePGNs(86) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Na5 10. Bc2 c5 11. d4 cxd4 12. cxd4 exd4  13. Nxd4 Bb7 14. Nd2 Re8 15. b3 Bf8 16. Bb2 g6 17. Re2 Bg7 18. Qe1 Rc8 19. Rd1 Nh5 20. Bb1 Nf4 21. Re3 Qf6 22. N2f3 Nc6 23. Kh2 Ne5 24. g3 Nd5  25. exd5 Nxf3+ 26. Nxf3 Rxe3 27. Bxf6 Rxe1 28. Nxe1 Bxf6 29. Be4 h5 30. Kg2 h4 31. g4 Rc3 32. Nf3 g5 33. Ng1 Rc5 34. Ne2 b4 35. Kf3 Kg7 36. Ke3 Bd8 37. f4 Bb6 38. Kf3 Kf6 39. fxg5+ Kxg5 40. Rd2 a5 41. Rc2 Rxd5  42. Nf4 Re5 43. Bxb7 Re3+ 44. Kg2 Rg3+ 45. Kh2 Kxf4 46. Bg2 Rd3 47. Re2 Be3 48. Bc6 d5 49. Be8 Kf3 0-1 "

; sample game 87
EventSites(87) = "Rubinstein mem 36th  Polanica Zdroj" : GameDates(87) = "19990826" : WhitePlayers(87) = "Rustemov, Alexander   G#87" : WhiteElos(87) = "2573" : BlackPlayers(87) = "Khenkin, Igor   G#87" : BlackElos(87) = "2633" : Each_Game_Result(87) = "1-0"

FilePGNs(87) = "1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. cxd5 exd5 5. Bg5 c6 6. e3 Bf5 7. Qf3 Bg6 8. Bxf6 Qxf6 9. Qxf6 gxf6 10. h4 h5 11. Nge2 Bd6 12. g3 Nd7 13. Nf4 Nb6  14. Rc1 a5 15. Be2 a4 16. a3 Ke7 17. f3 Bf5 18. Kf2 Be6 19. Rhe1 f5 20. Bd3 Nd7 21. e4  fxe4 22. fxe4 dxe4 23. Bxe4  Rh6 24. d5 cxd5 25. Ncxd5+ Bxd5 26. Bxd5+ Ne5 27. Re4 Kd7 28. Rc2 Ra7 29. Kg2 b5 30. Rce2 f6 31. Rc2 f5 32. Rd4 Ra6 33. Bb7 Ra7 34. Bc8+ Kd8 35. Bxf5  Nc4 36. Kf3 Re7 37. Bd3 Ne5+ 38. Kg2 Ng4 1-0 "

; sample game 88
EventSites(88) = "EU-chT (Men)  Batumi" : GameDates(88) = "19991207" : WhitePlayers(88) = "Piket, Jeroen   G#88" : WhiteElos(88) = "2635" : BlackPlayers(88) = "Short, Nigel D   G#88" : BlackElos(88) = "2675" : Each_Game_Result(88) = "0-1"

FilePGNs(88) = "1. d4 e6 2. c4 b6 3. a3 g6 4. Nc3 Bg7 5. e4 Ne7 6. f4 d5  7. cxd5 exd5 8. e5 c5 9. Nf3 Nbc6 10. Be3 O-O 11. Be2 Nf5 12. Bf2 cxd4 13. Nxd4 Ncxd4 14. Bxd4 Be6 15. O-O f6  16. exf6 Bxf6 17. Bxf6 Qxf6 18. Qd2 Rad8 19. Bg4 Ne3 20. Qxe3 Bxg4 21. Qd2 d4 22. Ne4 Qc6 23. Nf2 Bf5 24. Rac1 Qd5 25. Rfe1 Rfe8 26. h3 d3 27. g4  Be4 28. Re3 Bh1  29. Rg3 Bf3 30. Rc3  Be2  31. f5 Qd6 32. Kh2 gxf5  33. gxf5+ Kh8 34. Rc4  Qf6 35. Ne4 Qe5 36. Ng5 Rf8 37. Rh4 Rd7 38. Re4 Qc5 39. Ne6 Qc2 40. Qh6 Bf3+ 41. Kg1 Rxf5  42. Rf4 Qd1+ 0-1 "

; sample game 89
EventSites(89) = "KasparovChess GP g/60  Internet" : GameDates(89) = "20000210" : WhitePlayers(89) = "Gulko, Boris F   G#89" : WhiteElos(89) = "2644" : BlackPlayers(89) = "Adams, Michael   G#89" : BlackElos(89) = "2715" : Each_Game_Result(89) = "0-1"

FilePGNs(89) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 O-O 5. Bd3 d5 6. a3 Bxc3+ 7. bxc3 dxc4 8. Bxc4 c5 9. Nf3 Qa5  10. Bd2 Qc7 11. Bd3 b6 12. e4  Ba6 13. Bxa6 Nxa6 14. Qe2 Qb7  15. e5 Ne4 16. O-O Rfd8 17. Rfd1 cxd4 18. cxd4 Nxd2 19. Rxd2 h6  20. Rc1 Nc7 21. Rdc2 Nd5 22. g3 Rac8 23. Qd3 Rxc2 24. Rxc2 b5  25. Rc5 a6 26. Qe4 b4 27. axb4 Qxb4 28. Qe1 Qb3 29. Kg2 Rb8 30. Qc1 Kh7 31. h4 Ra8 32. Ra5 Qb7 33. h5 Kg8 34. Qc2 Rc8 35. Rc5 Rb8 36. Qc4 Qa8  37. Ra5  Ne3+ 38. fxe3 Rb2+ 0-1 "

; sample game 90
EventSites(90) = "Redbus KO  Southend" : GameDates(90) = "2000????" : WhitePlayers(90) = "Rowson, Jonathan   G#90" : WhiteElos(90) = "2499" : BlackPlayers(90) = "Miles, Anthony J   G#90" : BlackElos(90) = "2579" : Each_Game_Result(90) = "1-0"

FilePGNs(90) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. d4 Nd6 6. Bxc6 dxc6 7. dxe5 Nf5 8. Qxd8+ Kxd8 9. Nc3 Ke8 10. h3  Bb4 11. Ne4  Be6 12. c3  Bf8  13. g4  Ne7 14. Ng3  Ng6 15. Re1 Bd5 16. Nd4 Nh4 17. Bg5 Nf3+ 18. Nxf3 Bxf3 19. c4  c5  20. Nh5  h6 21. Bh4  g5 22. Bg3 Be7 23. e6  fxe6 24. Rxe6 Kd7 25. Rae1 Bd8 26. Rg6 b6 27. Re3 Bb7 28. f4  Rh7 29. f5  Be7 30. Rd3+ Ke8 31. Rg8+  Kf7 32. Rxa8 Bxa8 33. Rd7 Kg8 34. Rxc7 Be4 35. Bd6  Bd8 36. Rc8 Rd7 37. Nf6+ 1-0 "

; sample game 91
EventSites(91) = "Dubai op  Dubai" : GameDates(91) = "20000429" : WhitePlayers(91) = "Ermenkov, Evgenij   G#91" : WhiteElos(91) = "2449" : BlackPlayers(91) = "Ibragimov, Ildar   G#91" : BlackElos(91) = "2611" : Each_Game_Result(91) = "1-0"

FilePGNs(91) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Na5 10. Bc2 c5 11. d4 Qc7 12. Nbd2 Bd7 13. Nf1 Nc4 14. Ng3 Rfe8 15. d5 Nb6 16. Nh2 c4 17. f4  exf4 18. Bxf4 Na4 19. Rb1 Nc5 20. Nf3 Qb6 21. Nd4 b4 22. Kh2 a5 23. Qf3 b3 24. axb3 cxb3 25. Bd3 a4 26. Ndf5 Bf8 27. Bg5 Bxf5 28. Nxf5 Nfd7 29. Bf1 Ne5 30. Qg3 Ncd7 31. Nd4  Ra5 32. h4 g6 33. h5 Bg7 34. hxg6 hxg6 35. Re3 f6  36. Bf4 Kf7 37. Be2 Rh8+ 38. Kg1 Bh6 39. Bg4  Bxf4 40. Qxf4 Nc5 41. Rf1 Qd8 42. Be6+ Ke8 43. Rh3  Rxh3 44. Bxh3 Qe7 45. Qh4 a3 46. bxa3 Rxa3 47. Nb5 Ra5 48. Qh8+ Kf7 49. Nd4 Qe8 50. Qh7+ 1-0 "

; sample game 92
EventSites(92) = "Dubai op  Dubai" : GameDates(92) = "20000507" : WhitePlayers(92) = "Ermenkov, Evgenij   G#92" : WhiteElos(92) = "2449" : BlackPlayers(92) = "Kharlov, Andrei   G#92" : BlackElos(92) = "2616" : Each_Game_Result(92) = "1-0"

FilePGNs(92) = "1. e4 c5 2. Nc3 Nc6 3. Nge2 d6 4. d4 cxd4 5. Nxd4 Nf6 6. Be2 g6 7. Nb3 Bg7 8. O-O O-O 9. Re1 a5 10. Bb5  Ne8   11. a4  Nc7 12. Bf1 Be6 13. Be3 Bxb3  14. cxb3 Na6 15. Re2  Nc5 16. f3 Nb4 17. Rd2 Rc8 18. Bc4 Qd7 19. Qe2 Rfd8 20. Rad1 Qe8 21. f4 Nc6 22. Bf2  e5 23. Nb5 Nd4 24. Nxd4 exd4 25. Bh4 Rd7 26. Bb5 Rc6  27. Re1 Nxb3 28. Rdd1 Rdc7 29. e5 dxe5 30. fxe5 Qe6  31. Bxc6 bxc6 32. Bf6  c5  33. Bxg7 Kxg7 34. Rf1 c4 35. Qe4  d3  36. Rf6 Qe7 37. Qf4  d2 38. h4 Qc5+  39. Kh2 h6 40. Rf1 Qe7 41. e6  fxe6 42. h5 g5 43. Qe5 Kg8 44. Rxh6 1-0 "

; sample game 93
EventSites(93) = "NED-ch  Rotterdam" : GameDates(93) = "20000519" : WhitePlayers(93) = "Van der Wiel, John TH   G#93" : WhiteElos(93) = "2558" : BlackPlayers(93) = "Comp Fritz SSS   G#93" : BlackElos(93) = "2616" : Each_Game_Result(93) = "1-0"

FilePGNs(93) = "1. d4 d5 2. c3 Nf6 3. Bg5  Ne4 4. Bf4 g5 5. Bc1 h6 6. e3 Bg7 7. Bd3 Nd7  8. c4  Ndf6 9. f3 Nd6 10. c5 Nf5 11. Ne2 g4  12. f4 Qd7 13. Nbc3 Qe6 14. Qd2 Bd7 15. b4 h5 16. a4 O-O-O  17. Kd1 h4 18. b5 Kb8 19. Rb1 h3 20. g3 Be8 21. a5 Ka8 22. Ke1 Bd7 23. Kf2 a6 24. Qc2 Rb8 25. Bd2 axb5 26. Nxb5 Bxb5 27. Rxb5 Ne4+ 28. Bxe4 Qxe4 29. Qxe4 dxe4 30. Nc3 e6 31. Nxe4 Ne7 32. Ng5 Rhf8 33. Rhb1 Ka7 34. a6  bxa6 35. Rxb8 Rxb8 36. Rxb8 Kxb8 37. Nxf7 Kc8 38. Ng5 Kd7 39. Ke2 Nf5 40. Ne4 Kc6 41. Nf2 Nh6 42. Ba5  Bf6 43. Kd3 Kd7 44. e4 Bg7 45. Kc4 Kc6 46. Bd2 1-0 "

; sample game 94
EventSites(94) = "World Championship BGN  London" : GameDates(94) = "20001010" : WhitePlayers(94) = "Kramnik, Vladimir   G#94" : WhiteElos(94) = "2770" : BlackPlayers(94) = "Kasparov, Garry   G#94" : BlackElos(94) = "2849" : Each_Game_Result(94) = "1-0"

FilePGNs(94) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. e4 Nxc3 6. bxc3 Bg7 7. Nf3 c5 8. Be3 Qa5 9. Qd2 Bg4 10. Rb1 a6 11. Rxb7   Bxf3 12. gxf3 Nc6 13. Bc4  O-O 14. O-O cxd4 15. cxd4 Bxd4  16. Bd5 Bc3  17. Qc1  Nd4 18. Bxd4 Bxd4 19. Rxe7  Ra7  20. Rxa7 Bxa7 21. f4 Qd8 22. Qc3 Bb8 23. Qf3 Qh4 24. e5 g5 25. Re1  Qxf4 26. Qxf4 gxf4 27. e6 fxe6 28. Rxe6 Kg7 29. Rxa6 Rf5 30. Be4 Re5  31. f3 Re7 32. a4 Ra7   33. Rb6 Be5 34. Rb4 Rd7 35. Kg2  Rd2+ 36. Kh3 h5 37. Rb5 Kf6 38. a5 Ra2 39. Rb6+ Ke7  40. Bd5 1-0 "

; sample game 95
EventSites(95) = "World Championship BGN  London" : GameDates(95) = "20001028" : WhitePlayers(95) = "Kramnik, Vladimir   G#95" : WhiteElos(95) = "2770" : BlackPlayers(95) = "Kasparov, Garry   G#95" : BlackElos(95) = "2849" : Each_Game_Result(95) = "1/2-1/2"

FilePGNs(95) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 O-O 5. Bd3 d5 6. Nf3 c5 7. O-O dxc4 8. Bxc4 Nbd7 9. a3 cxd4 10. axb4 dxc3 11. bxc3 Qc7 12. Be2  Qxc3  13. Ba3   Nd5  14. Qb1  Qf6 15. Bd3 h6 16. b5 Rd8 17. Bb2 Qe7 18. Ra4  Nc5 19. Bh7+ Kh8 20. Rh4  f6  21. Rc4 Bd7 22. Ba3 b6 23. Be4  a6  24. bxa6 Rxa6 25. Bxc5 bxc5 26. Rfc1 Ra5  27. Qb2 Rb5 28. Qa3 Nb6  29. R4c3 Rb4 30. Nd2  f5   31. Bf3   Na4  32. Rxc5  Rb2 33. Nc4  Qxc5  1/2-1/2 "

; sample game 96
EventSites(96) = "World Championship BGN  London" : GameDates(96) = "20001031" : WhitePlayers(96) = "Kramnik, Vladimir   G#96" : WhiteElos(96) = "2770" : BlackPlayers(96) = "Kasparov, Garry   G#96" : BlackElos(96) = "2849" : Each_Game_Result(96) = "1/2-1/2"

FilePGNs(96) = "1. Nf3 Nf6 2. c4 b6 3. g3 c5 4. Bg2 Bb7 5. O-O g6 6. Nc3 Bg7 7. d4 cxd4 8. Qxd4 d6 9. Rd1 Nbd7 10. Be3 Rc8 11. Rac1 O-O 12. Qh4 a6 13. Ne1  Bxg2 14. Nxg2 Re8 15. b3 Qc7  16. Bg5 Qb7 17. Ne3 b5  18. Ned5  bxc4 19. bxc4 h5  20. Qf4 Qc6 21. Bxf6 Nxf6 22. Nxf6+ Bxf6 23. Nd5 Bb2   24. Rb1 Bg7 25. Qg5 Kf8 26. Rdc1 e6 27. Nf6 Red8 28. h4 Qa8 29. c5  Rxc5 30. Rxc5 Bxf6  31. Qxf6 dxc5 32. Kh2  Kg8 33. Rb6 Re8 34. Qf3  Qxf3 35. exf3 Rc8 36. Rxa6 c4 37. Rd6 c3 38. Rd1 Ra8 39. Rc1 Rxa2 40. Rxc3 Rxf2+ 41. Kg1 Ra2  42. Rc7 Kf8 43. Rb7 Ke8 44. Rb8+ Ke7 45. Rb7+ Kf6 46. Kf1 e5  47. Rb6+ Kf5 48. Rb7 Ke6 49. Rb6+ Kf5 50. Rb7 f6 51. Rg7 g5   52. hxg5 fxg5 53. Rg8 g4 54. Rf8+ Ke6 55. Re8+ Kf5 56. Rf8+ Kg6 57. Rg8+ Kf5 1/2-1/2 "

; sample game 97
EventSites(97) = "Corus  Wijk aan Zee" : GameDates(97) = "20010126" : WhitePlayers(97) = "Adams, Michael   G#97" : WhiteElos(97) = "2746" : BlackPlayers(97) = "Fedorov, Alexei   G#97" : BlackElos(97) = "2575" : Each_Game_Result(97) = "0-1"

FilePGNs(97) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 g6 6. Be3 Bg7 7. f3 Nc6 8. Qd2 O-O 9. O-O-O d5 10. exd5 Nxd5 11. Nxc6 bxc6 12. Nxd5 cxd5 13. Qxd5 Qc7 14. Qc5 Qb8  15. Qa3 Be6 16. Ba6 Qe5 17. g3 Rad8 18. Bf4 Qf6 19. Rhe1 Bf5 20. Rxd8 Rxd8 21. c3  Qb6  22. Be3 Bh6   23. f4 Qc6 24. Bd2 Qd5 25. Re2 e5 26. Qa4 exf4 27. gxf4  Bxf4  28. Re8+ Kg7 29. Qxf4 Rxe8 30. Bc4 Qh1+ 31. Bf1 Kg8 0-1 "

; sample game 98
EventSites(98) = "EU-ch 2nd  Ohrid" : GameDates(98) = "20010606" : WhitePlayers(98) = "Shulman, Yuri   G#98" : WhiteElos(98) = "2551" : BlackPlayers(98) = "Lautier, Joel   G#98" : BlackElos(98) = "2658" : Each_Game_Result(98) = "1-0"

FilePGNs(98) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 O-O 5. Ne2  d5 6. a3 Be7 7. cxd5 exd5 8. b4 c6 9. Ng3 Re8 10. Bd3 Nbd7 11. O-O Nb6 12. b5  c5 13. dxc5 Bxc5 14. Na4  Nxa4 15. Qxa4 d4 16. Qc2 Bb6 17. e4  Ng4 18. h3 Ne5 19. f4 Nxd3 20. Qxd3 Bd7 21. Bd2 a6 22. bxa6 Rxa6 23. Bb4  Ba7 24. Rac1 Rc6 25. e5 Qb6 26. Ne4 Bf5 27. Kh2 h6 28. Qf3 Bxe4 29. Qxe4 Qb5 30. Rcd1 Rc4 31. Rfe1 Qc6 32. Rd2 Qc8 33. Rd3 Qc6 34. Rd2 Bb6 35. Rd3 Rc2 36. Re2 Qxe4 37. Rxe4 g6 38. Re1 Ba7 39. Kg3 Rec8 40. Kf3 h5 41. g4  Rh2 42. Ke4 hxg4 43. hxg4 Re8 44. g5 Rc8 45. Kd5 Rh4 46. Rb1 b5 47. Rf1 Rc2 48. Rff3 Rc4 49. Be7 Rc7 50. Bf6 Rc5+ 51. Kd6 Rc1 52. Rh3 Rh1 53. Rxh4 Rxh4 54. Rd1 Kh7 55. Rc1 1-0 "

; sample game 99
EventSites(99) = "EU-ch 2nd  Ohrid" : GameDates(99) = "20010610" : WhitePlayers(99) = "Bologan, Viktor   G#99" : WhiteElos(99) = "2684" : BlackPlayers(99) = "Huzman, Alexander   G#99" : BlackElos(99) = "2578" : Each_Game_Result(99) = "1-0"

FilePGNs(99) = "1. e4 e5 2. Nf3 Nf6 3. Nxe5 d6 4. Nf3 Nxe4 5. d4 d5 6. Bd3 Be7 7. O-O Nc6 8. c4 Nb4 9. Be2 O-O 10. a3 Nc6 11. cxd5 Qxd5 12. Nc3 Nxc3 13. bxc3 Bf5 14. c4 Qd6 15. d5 Ne5 16. Nd4 Bd7 17. a4 c5 18. Nb3 f5 19. f4 Nf7 20. Nd2 Bf6 21. Ra2 Rfe8 22. Nf3 Re7 23. Bd3 Rae8 24. Qc2 g6 25. g3 Kg7 26. a5 Bc8 27. Bd2 b6 28. Rb1 Rb7 29. Bc3 Bd7 30. axb6 axb6 31. Ra6  Reb8 32. Qb2 Bxc3 33. Qxc3+ Qf6 34. Ne5 Be8 35. Qa1 Kg8 36. Re1 Nd6 37. Bf1 Qd8 38. Bg2 Re7 39. Rd1 Qc7 40. Bf3 Rb7 41. Rb1 b5 42. Rc6  Bxc6 43. dxc6 Ra7 44. Qb2 Nxc4 45. Bd5+ Rf7 46. Nxc4 bxc4 47. Qf6 1-0 "

; sample game 100
EventSites(100) = "EU-ch 2nd  Ohrid" : GameDates(100) = "20010613" : WhitePlayers(100) = "Wells, Peter K   G#100" : WhiteElos(100) = "2522" : BlackPlayers(100) = "Azarov, Sergei   G#100" : BlackElos(100) = "2452" : Each_Game_Result(100) = "1-0"

FilePGNs(100) = "1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Bc5 5. Be3 Qf6 6. c3 Nge7 7. Bc4 b6  8. Qd2  O-O  9. b4  Bxd4 10. cxd4 Qg6 11. Nc3 d5  12. Nxd5  Qxg2 13. O-O-O Qxe4 14. Nc3 Qf5 15. Rhg1 Nxb4  16. Rg5 Qf6  17. Ne4 Qc6 18. Qxb4 Qxe4 19. Re5 Qc6 20. d5  Nxd5 21. Rexd5 Ba6 22. R1d4  Bb7  23. Rf5  Ba6 24. Qc3  Bxc4 25. Rxc4 Qd7 26. Rg5 g6 27. Rxc7 Qh3 28. Qf6 Rad8 29. Bd4 Rxd4 30. Qxd4 Qxh2 31. Rc2 Qh3 32. Kb2 1-0 "

; sample game 101
EventSites(101) = "SCO-ch  Aberdeen" : GameDates(101) = "20010710" : WhitePlayers(101) = "Rowson, Jonathan   G#101" : WhiteElos(101) = "2514" : BlackPlayers(101) = "Motwani, Paul   G#101" : BlackElos(101) = "2511" : Each_Game_Result(101) = "1-0"

FilePGNs(101) = "1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Bxc3+ 6. bxc3 Qa5 7. Bd2 Qa4 8. Qb1  c4 9. Ne2  Nc6  10. Ng3 Nge7 11. Nh5 Rg8  12. g3 Bd7 13. Bh3 O-O-O 14. O-O Rdf8 15. Re1  Kb8 16. Qb2 Nc8 17. Re3  Nb6 18. Rf1 Qa5 19. Qc1 Be8  20. Nf4  a6 21. Ng2  Na7 22. f4 Bd7 23. f5 exf5  24. Bxf5 Bxf5 25. Rxf5 Nb5 26. Ref3 Qxa3 27. Qxa3 Nxa3 28. e6  f6 29. Bf4+ Kc8 30. Bd6 Nb5 31. Bc5  Kc7 32. Nf4 Re8 33. Re3 Nc8  34. Nxd5+ Kd8 35. e7+ Kd7 36. Rxf6  gxf6 37. Nxf6+ Kc6 38. Nxg8 Nbd6 39. Bxd6 Kxd6 40. Kf2  Nxe7  41. Nxe7 Rxe7 42. Rxe7 Kxe7 43. g4  Kf6 44. h4 h6 45. Ke3 a5 46. Kd2 b5 47. Kc1 Ke6 48. Kb2 Kd5 49. h5 Ke6 50. g5 1-0 "

; sample game 102
EventSites(102) = "WchT 5th  Yerevan" : GameDates(102) = "20011015" : WhitePlayers(102) = "Lputian, Smbat G   G#102" : WhiteElos(102) = "2618" : BlackPlayers(102) = "Sakaev, Konstantin   G#102" : BlackElos(102) = "2639" : Each_Game_Result(102) = "1-0"

FilePGNs(102) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. e3 Bb7 5. Bd3 d5 6. O-O Nbd7 7. b3 Be7 8. Bb2 O-O 9. Nc3 c5 10. Qe2 cxd4 11. exd4 Re8 12. Ne5 a6 13. Rad1 Nf8 14. Kh1 Bb4 15. f4 Bxc3 16. Bxc3 Ne4 17. Bxe4 dxe4 18. Ng4  f6 19. Ne3  Qc7 20. g4  Rad8 21. f5 Rd7 22. g5  fxg5 23. Qh5 Rf7 24. f6 gxf6  25. d5  exd5 26. Bxf6 d4 27. Ng4 e3+ 28. Kg1  Ng6 29. Nh6+ Kf8 30. Nxf7 Qc6 31. Qh6+ Kxf7 32. Bxd4+ Ke7 33. Qxg5+ Kd7 34. Bxb6+ 1-0 "

; sample game 103
EventSites(103) = "FIDE-Wch k.o.  Moscow" : GameDates(103) = "20011127" : WhitePlayers(103) = "Nielsen, Peter Heine   G#103" : WhiteElos(103) = "2620" : BlackPlayers(103) = "Goldin, Alexander   G#103" : BlackElos(103) = "2612" : Each_Game_Result(103) = "1-0"

FilePGNs(103) = "1. d4 d5 2. c4 e6 3. Nf3 Nf6 4. g3 Be7 5. Bg2 O-O 6. O-O dxc4 7. Qc2 a6 8. Qxc4 b5 9. Qc2 Bb7 10. Bd2 Be4 11. Qc1 Bb7 12. Bf4 Bd6 13. Nbd2 Nbd7 14. Nb3 Bd5 15. Rd1 Rc8 16. Nc5 Nxc5 17. dxc5 Bxf4 18. Qxf4 Qe7 19. Ne5  Qxc5 20. Rac1 Qe7 21. Nc6 Bxc6 22. Rxc6 Rfd8 23. Rdc1 h6 24. a3 e5  25. Qf5 e4 26. e3 Re8 27. Rxa6 c5 28. Rb6  Rcd8 29. Bf1 Rd5 30. Rxf6 Rxf5 31. Rxf5 b4 32. a4 g6 33. Rfxc5 Qf6 34. b3 Qb2 35. a5 Qxb3 36. a6 Qa3 37. Rb1 Rb8 38. Rc7 Qa5 39. Rbc1 Kg7 40. R1c5 Qa1 41. Kg2 Rb6 42. Rb7  Rf6 43. Rc2  Qb1 44. Rd2 b3 45. a7 Qa1 46. Bc4 Qc3 47. Bxf7 Rxf7 48. Rdd7 1-0 "

; sample game 104
EventSites(104) = "FIDE-Wch k.o.  Moscow" : GameDates(104) = "20011128" : WhitePlayers(104) = "Goldin, Alexander   G#104" : WhiteElos(104) = "2612" : BlackPlayers(104) = "Nielsen, Peter Heine   G#104" : BlackElos(104) = "2620" : Each_Game_Result(104) = "1/2-1/2"

FilePGNs(104) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 dxc4 5. e4 Bb4 6. Bg5 c5 7. e5 h6 8. exf6 hxg5 9. fxg7 Rg8 10. dxc5 Qxd1+ 11. Rxd1 Rxg7 12. Bxc4 Nc6 13. O-O Bxc5 14. Ne4 Be7 15. g4 Bd7 16. Nd6+ Bxd6 17. Rxd6 Ke7 18. Rfd1 Be8 19. R6d2 Rc8 20. Re1 Rg8 21. a3 Kf6 22. Ba2 Ne7 23. Ne5 Ng6 24. Nxg6 Rxg6 25. Bb1 Rh6 26. Be4 b6 27. Kg2 Bc6 28. Bxc6 Rxc6 29. Rd7 Rc2 30. Re3 Kg7 31. Rf3 Rf6 32. Rxf6 Kxf6 33. b4 a5 34. bxa5 bxa5 35. Ra7 1/2-1/2 "

; sample game 105
EventSites(105) = "FIDE-Wch k.o.  Moscow" : GameDates(105) = "20011129" : WhitePlayers(105) = "Nielsen, Peter Heine   G#105" : WhiteElos(105) = "2620" : BlackPlayers(105) = "Anand, Viswanathan   G#105" : BlackElos(105) = "2770" : Each_Game_Result(105) = "0-1"

FilePGNs(105) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Ba6 5. b3 Bb4+ 6. Bd2 Be7 7. Bg2 c6 8. O-O d5 9. Qc2 Nbd7 10. Rd1 Rc8 11. Bf4 c5 12. dxc5 Bxc5 13. Nc3  O-O 14. e4  Ng4 15. exd5  Nxf2 16. Rf1 e5 17. Bc1 e4 18. Nh4 e3 19. Na4 Bd4 20. Bb2 Bxb2 21. Qxb2  b5 22. Nf5 Qg5 23. Nd6 bxa4 24. Nxc8 Bxc8 25. Qd4 Nf6 26. Rae1 Re8 27. d6 Nh3+ 28. Bxh3 Bxh3 29. Rf4 Qa5  30. Rxe3 Rxe3 31. Qxe3 axb3 32. d7 Bxd7 33. axb3 Bh3 0-1 "

; sample game 106
EventSites(106) = "Linares 19th  Linares" : GameDates(106) = "20020309" : WhitePlayers(106) = "Kasparov, Garry   G#106" : WhiteElos(106) = "2838" : BlackPlayers(106) = "Ponomariov, Ruslan   G#106" : BlackElos(106) = "2727" : Each_Game_Result(106) = "1-0"

FilePGNs(106) = "1. e4 e6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Nd7 5. Nf3 Ngf6 6. Nxf6+ Nxf6 7. c3 c5 8. Ne5  Nd7  9. Bb5 Bd6  10. Qg4 Kf8  11. O-O  Nxe5 12. dxe5 Bxe5 13. Bg5 Bf6  14. Rad1 Qc7 15. Qh4  Bxg5 16. Qxg5 f6 17. Qh5 g6 18. Qh6+ Kf7  19. Rd3  a6 20. Rh3  Qe7 21. Bd3 f5  22. g4  Qf6 23. Rd1 b5  24. Be2 e5 25. Rhd3 Ra7  26. Rd6 Qg7 27. Qe3 Rc7 28. a4  e4 29. axb5 axb5 30. Bxb5  Qe5 31. Qg5 Qe7 32. Qh6 Be6 33. Qf4  Bc8 34. Qh6 Be6 35. gxf5 gxf5 36. Be2  Qf6 37. Bh5+ Ke7 38. Rxe6+ 1-0 "

; sample game 107
EventSites(107) = "CAN-ch zt  Richmond" : GameDates(107) = "20020326" : WhitePlayers(107) = "Charbonneau, Pascal   G#107" : WhiteElos(107) = "2386" : BlackPlayers(107) = "Hebert, Jean   G#107" : BlackElos(107) = "2398" : Each_Game_Result(107) = "0-1"

FilePGNs(107) = "1. e4 g6 2. d4 Bg7 3. Nc3 d6 4. Be3 Nf6 5. Nf3 O-O 6. Qd2 a6  7. Bd3 Bg4 8. Bh6  Nc6 9. Bxg7 Kxg7 10. d5  Bxf3  11. dxc6 Bxg2 12. Rg1 Bh3 13. cxb7 Rb8 14. Bxa6 c6 15. Qe3 Qa5 16. Bc4 Be6  17. Bxe6 fxe6 18. f4 Rxb7 19. O-O-O Nh5  20. Rdf1 Qb4 21. Nd1 Nf6 22. Re1 d5 23. f5  Nxe4 24. fxg6 h6  25. Ref1 Rf6 26. Rf4 Qb6 27. Qxb6 Rxb6 28. Rfg4 h5 29. R4g2 Ra6  30. a3 c5 31. c4 d4  32. Re2 Nd6 33. Re5 Rc6 34. Rgg5  Nxc4 35. Rxc5 e5  36. Rxc6 Rxc6 37. Nf2 Nxa3+ 38. Kd1 Nc4 39. b3 Ne3+ 40. Ke2 Rc2+ 41. Kf3 Ng4  42. Nxg4 hxg4+ 43. Rxg4 Rxh2  44. b4 Rb2 45. Re4 Rb3+ 46. Kg4 Kxg6 47. Rxe5 Kf6 48. Rh5  e5 49. Rh6+ Ke7 50. Kf5 Re3 51. b5 d3 52. b6 Kd7  53. Rh7+ Kc8 54. b7+ Kb8 55. Rd7 e4 56. Ke5 Re2  57. Kd5  Ka7  58. Kc5 Rb2 59. Kd4 Rxb7 60. Rd8 Re7 61. Ke3 Kb6 62. Rd5 Kc6 63. Ra5 Rd7  64. Ra1 Kc5 65. Kd2 Kd4 66. Ra4+ Ke5 67. Ra1 Rh7 0-1 "

; sample game 108
EventSites(108) = "CAN-ch zt  Richmond" : GameDates(108) = "20020331" : WhitePlayers(108) = "Hebert, Jean   G#108" : WhiteElos(108) = "2398" : BlackPlayers(108) = "Roussel Roozmon, Thomas   G#108" : BlackElos(108) = "2140" : Each_Game_Result(108) = "1/2-1/2"

FilePGNs(108) = "1. d4 Nf6 2. Nf3 e6 3. g3 b6 4. Bg2 Bb7 5. O-O c5 6. c4 cxd4 7. Qxd4 Be7 8. Nc3 d6 9. Bg5 a6 10. Bxf6 Bxf6 11. Qd3 Bxf3 12. Bxf3 Ra7 13. Rfd1 Be7 14. Bg2 O-O 15. Rac1 Nd7 16. b3 Qb8 17. e3 Rc7 18. Qb1 Nf6  19. Ne2 Rd8 20. Nd4 Qc8 21. b4  d5  22. cxd5 Nxd5 23. Rxc7 Qxc7 24. Rc1 Nc3 25. Qc2 Rc8 26. Nc6 Bf6  27. Qd3 Rd8  28. Nxd8 Ne2+ 29. Qxe2 Qxc1+ 30. Bf1 Bxd8 31. Qxa6 g6 32. Qb5 Kg7 33. Qe5+ Kg8 34. Qd4 Qc7 35. a3  Be7 36. Qb2 Qd6 37. Be2 Bf8 38. Qc2 Be7 39. Bf3 Bf6 40. Kf1 Kf8 41. Ke2 Kg7 42. Be4 h5 43. h4 Kf8 44. Qc4 Be7 45. Bc6 Qe5  46. Qd4  Qxd4 47. exd4 g5 48. hxg5 Bxg5 49. a4 h4 50. Kd3  hxg3 51. fxg3 Ke7 52. a5 bxa5 53. bxa5 Kd6 54. Be8 f6 55. a6 Kc7 56. Bd7 Kb6 57. Bc8 Bc1 58. Kc4 Bb2 59. g4 Ba1 60. Bxe6 Kxa6 61. Kc5 Kb7 62. d5 Kc7 63. d6+ Kd8 64. Kd5 Bb2 1/2-1/2 "

; sample game 109
EventSites(109) = "Julian Borowski-A 4th  Essen" : GameDates(109) = "20020525" : WhitePlayers(109) = "Kasimdzhanov, Rustam   G#109" : WhiteElos(109) = "2674" : BlackPlayers(109) = "Kortschnoj, Viktor   G#109" : BlackElos(109) = "2635" : Each_Game_Result(109) = "1-0"

FilePGNs(109) = "1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. Bg5 dxe4 5. Nxe4 Nbd7 6. Nxf6+ Nxf6 7. Nf3 c5 8. Bc4 Qa5+ 9. c3 Be7 10. O-O O-O 11. Re1 h6   12. Bh4 Rd8 13. Qe2 cxd4 14. Nxd4 Bd7 15. Rad1 Kh8 16. Rd3 Ng8 17. Bg3 Rac8 18. Rf3 Bf6 19. Bd3 Qd5  20. Be4 Qxa2 21. Bb1  Qd5 22. Qd3 g6 23. Rxf6  Nxf6 24. Be5 Kg7 25. Qg3 Qc5 26. Re3 Bc6  27. Bxg6  fxg6 28. Bxf6+ Kh7 29. Bxd8 Rxd8 30. Rxe6 Qg5 31. Qxg5 hxg5 32. Re7+ Kh6 33. h3 Bd5 34. Nc2   1-0 "

; sample game 110
EventSites(110) = "EU-Cup 18th  Chalkidiki" : GameDates(110) = "20020928" : WhitePlayers(110) = "Motylev, Alexander   G#110" : WhiteElos(110) = "2634" : BlackPlayers(110) = "Polgar, Judit   G#110" : BlackElos(110) = "2681" : Each_Game_Result(110) = "0-1"

FilePGNs(110) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Qb6 5. Nb3 Nf6 6. Nc3 e6 7. Qe2 Bb4 8. Bd2 O-O 9. a3 Be7 10. O-O-O d5 11. exd5 Nxd5 12. Nxd5 exd5 13. Bc3 Be6 14. Qf3 Rac8 15. Qg3 g6 16. h4 Rfd8 17. h5 d4  18. hxg6 hxg6 19. Nxd4 Nxd4 20. Rxd4 Rxc3  21. bxc3 Rxd4 22. cxd4 Qxd4 23. c3 Qc5 24. Kd2 Bg5+ 25. Kc2 Kg7 26. Bd3 Bf6 27. Rb1 Qxc3+ 28. Kd1 Bg5 29. Ke2 Bg4+  30. Kf1 Bf4  0-1 "

; sample game 111
EventSites(111) = "Hoogeveen Essent Crown  Hoogeveen" : GameDates(111) = "20021019" : WhitePlayers(111) = "Van Wely, Loek   G#111" : WhiteElos(111) = "2681" : BlackPlayers(111) = "Acs, Peter   G#111" : BlackElos(111) = "2591" : Each_Game_Result(111) = "0-1"

FilePGNs(111) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 O-O 5. Bd3 d5 6. cxd5 exd5 7. Ne2 Re8 8. O-O Bd6 9. a3 Ng4  10. h3  Nh2  11. Re1 Nf3+ 12. gxf3 Qg5+ 13. Kh1 Qh4  14. Nf4 Bxh3 15. Ncxd5 Re6  16. Nxe6 Bf5+  17. Kg1 Qh2+ 18. Kf1 Bg3 0-1 "

; sample game 112
EventSites(112) = "FIDE World Cup final  Hyderabad" : GameDates(112) = "20021020" : WhitePlayers(112) = "Anand, Viswanathan   G#112" : WhiteElos(112) = "2755" : BlackPlayers(112) = "Kasimdzhanov, Rustam   G#112" : BlackElos(112) = "2653" : Each_Game_Result(112) = "1-0"

FilePGNs(112) = "1. e4 e5 2. Nf3 Nf6 3. Nxe5 d6 4. Nf3 Nxe4 5. d4 d5 6. Bd3 Bd6 7. O-O O-O 8. c4 c6 9. Qc2 Na6 10. a3 Re8 11. Nc3 Bf5 12. Re1 h6  13. c5 Bc7 14. Bd2 Ba5  15. Bf4 Bxc3 16. bxc3 Nc7 17. h3  Ne6 18. Bh2 N6g5  19. Ne5   f6 20. Ng4 Qa5 21. Ne3 Be6 22. Rac1 Nxh3+ 23. gxh3 Bxh3 24. Nc4 Qxc3 25. Qxc3 Nxc3 26. Nd6 Rxe1+ 27. Rxe1 b5 28. Re3 Bg4 29. Bf5 1-0 "

; sample game 113
EventSites(113) = "Bled ol (Men)  Bled" : GameDates(113) = "20021027" : WhitePlayers(113) = "Rozentalis, Eduardas   G#113" : WhiteElos(113) = "2563" : BlackPlayers(113) = "Adams, Michael   G#113" : BlackElos(113) = "2745" : Each_Game_Result(113) = "1/2-1/2"

FilePGNs(113) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Bc5 4. O-O Nf6 5. d3 Nd4 6. Ba4 Qe7 7. c3 Nxf3+ 8. Qxf3 c6  9. Bg5 d6 10. Nd2 h6 11. Bxf6 Qxf6 12. Qxf6 gxf6 13. b4 Bb6 14. Nc4 Ke7 15. Bb3 Be6 16. Nxb6  axb6 17. f4 Bxb3 18. axb3 exf4  19. Kf2 Ke6 20. Kf3 Rhg8 21. Kxf4  Rxa1 22. Rxa1 Rxg2 23. Ra7 Rb2 24. Rxb7 Rxb3 25. d4  Rxc3 26. b5  d5 1/2-1/2 "

; sample game 114
EventSites(114) = "Bled ol (Men)  Bled" : GameDates(114) = "20021031" : WhitePlayers(114) = "Kortschnoj, Viktor   G#114" : WhiteElos(114) = "2634" : BlackPlayers(114) = "Macieja, Bartlomiej   G#114" : BlackElos(114) = "2615" : Each_Game_Result(114) = "0-1"

FilePGNs(114) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 c5 5. dxc5 O-O 6. a3 Bxc5 7. Nf3 b6 8. Bg5 Bb7 9. e4 h6 10. Bh4 Be7 11. Rd1 Nh5 12. Bg3 a6   13. Be2 Nxg3 14. hxg3 Nc6 15. e5  Qc7 16. Nd5 exd5 17. cxd5 Rfe8  18. Rh5  Bf8   19. dxc6 Qxc6 20. Qb3 b5  21. Kf1 Rad8 22. Rh4 Qe6  23. Qc2  d6  24. exd6 Rxd6 25. Rxd6 Qxd6   26. Kg1 Qc5  27. Qd2 Qb6 28. Bf1 Bd6 29. Qd4  Bc5 30. Qd2 Rd8 31. Qc2 Be7 32. Rf4 Bf6  33. a4  bxa4 34. Qxa4 Qxb2  35. Rb4 Bc6  36. Qa5 Qc3 37. Qb6 Rd1 38. Qb8+ Kh7 39. Rb1  Qc2  40. Rxd1 Qxd1 41. Qf4 Qa1 42. g4 Bb5 43. Nd2 Bxf1 44. Nxf1 g6  45. g3 a5 46. Kg2 a4 47. Ne3 Kg7 48. Qd6 Be5 49. Qd5 Qd4 50. Qa5 Bd6 51. g5 Qe4+ 52. Kh2 Qh4+ 53. Kg2 Qxg5 54. Qxa4 Bxg3  55. fxg3 Qxe3 56. Qc4 h5 57. Qc2 Qd4 58. Qe2 h4 59. g4 Qf4 60. Kh1 Kh6 0-1 "

; sample game 115
EventSites(115) = "Bermuda-A  Bermuda" : GameDates(115) = "20030202" : WhitePlayers(115) = "Shabalov, Alexander   G#115" : WhiteElos(115) = "2613" : BlackPlayers(115) = "Macieja, Bartlomiej   G#115" : BlackElos(115) = "2629" : Each_Game_Result(115) = "1/2-1/2"

FilePGNs(115) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. Nc3 Bb7 5. a3 d5 6. Bg5 Be7 7. Bxf6 Bxf6 8. cxd5 exd5 9. Qb3 O-O 10. Rd1 Re8  11. g3 c5 12. Bg2 Nc6 13. dxc5 Ba6 14. e3 bxc5 15. Nxd5 Qa5+ 16. Rd2 Rab8 17. Qc2  Nd4 18. Nxd4 Bxd4 19. b3 Qxa3 20. Bf1 Bb7 21. Bc4 Rbd8 22. O-O Bxd5 23. exd4 Bxc4 24. Qxc4 Re4  25. dxc5 Rxd2 26. Qxe4 Qxc5 27. Qa8+ Qf8 28. Qxa7 g6 29. Rc1 Rd8 30. Qc7 Rb8 31. Rc3 Qe8 32. Re3 Qb5 33. h4 h5 34. Rf3 Rb7 35. Qc8+ Kg7 36. Qc3+ Kg8 37. Re3 Kh7 38. Kh2 Qf5 39. Rf3 Qd5 40. Rd3 Qf5 41. Kg1 Rb8 42. Re3 Qb5 43. Qd4 Qb7 44. Qc4 Kg8 45. Kh2 Kg7 46. Qd4+ Kh7 47. Qf6 Kg8 48. Rd3 Rf8 49. Qf4 Re8 50. Re3 Rd8 51. Qf6 Rb8 52. Rd3 Rf8 53. Qc3 Rc8 54. Qd2 Qb6 55. b4 Rb8 56. Rd4 Kg7 57. Rf4 Rb7 58. Qd5 Kg8 59. Kg2 Kf8 60. Rc4 Kg7 61. Rc6 Qxb4 62. Qe5+ Kh7 63. Rc8 f6 64. Qe8  Kh6 65. Qh8+ Rh7 66. Qxf6 Qb7+ 67. Rc6 Rg7 68. Kg1 Kh7 69. Re6 Qd7 70. Qe5 Qd1+ 71. Kg2 Rd7 72. Qf6 Qd5+ 73. Kg1 Qf5 74. Qxf5 gxf5 75. Kg2 Kg7 76. Kf3 Rd4 77. Ke3 Ra4 78. Rd6 Re4+ 79. Kd3 Ra4 80. Re6 Rb4 81. Rc6 f4 82. Rc4 Rxc4 83. Kxc4 fxg3 84. fxg3 Kf6 85. Kd4 Kf5 86. Ke3 1/2-1/2 "

; sample game 116
EventSites(116) = "Moscow Aeroflot op-A  Moscow" : GameDates(116) = "20030218" : WhitePlayers(116) = "Shabalov, Alexander   G#116" : WhiteElos(116) = "2613" : BlackPlayers(116) = "Yandemirov, Valeri   G#116" : BlackElos(116) = "2469" : Each_Game_Result(116) = "1-0"

FilePGNs(116) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. Nf3 Bg7 5. Qb3 dxc4 6. Qxc4 O-O 7. e4 Na6 8. Be2 c5 9. d5 e6 10. O-O exd5 11. exd5 Nb4  12. Bg5 b6 13. Qh4 h6  14. Bxh6 Nbxd5 15. Rad1 Nxc3 16. bxc3 Qe7 17. Bc4 Qe4 18. Bxf7+ Rxf7 19. Rd8+ Bf8 20. Bxf8 Qxh4 21. Bd6+ Kh7 22. Nxh4 Bb7 23. Rxa8 Bxa8 24. f4  Rd7 25. Bb8 Rd2 26. h3  Rxa2 27. Rd1 Nd5  28. c4 Ne3 29. Rd7+ Kg8 30. Be5 Be4 31. g4 Nxc4  32. Bf6 Rd2 33. Rg7+ Kf8 34. f5  gxf5 35. Ng6+ Ke8 36. Re7+ Kd8 37. Rxe4+ Kd7 38. Rxc4 fxg4 39. hxg4 a5 40. g5 Ke6 41. Ne7 Rd8 42. Re4+ Kf7 43. Bc3 1-0 "

; sample game 117
EventSites(117) = "Reykjavik Hrokurinn  Reykjavik" : GameDates(117) = "20030225" : WhitePlayers(117) = "McShane, Luke J   G#117" : WhiteElos(117) = "2568" : BlackPlayers(117) = "Macieja, Bartlomiej   G#117" : BlackElos(117) = "2629" : Each_Game_Result(117) = "0-1"

FilePGNs(117) = "1. e4 c5 2. Nf3 d6 3. Bc4 Nf6 4. d3 Nc6 5. O-O Bg4 6. Nbd2 e6 7. h3 Bh5 8. c3 Be7 9. Bb3 d5 10. Qe2 Qc7 11. Re1 O-O-O   12. Ba4 Ne5  13. g4 Nxf3+ 14. Nxf3 Bg6 15. e5 Nd7 16. Bf4 h5 17. Bg3 hxg4 18. hxg4 c4  19. d4 Rh6 20. Kg2 Rdh8 21. Bc2  Qd8  22. b3 Nb6 23. Rab1  Qg8 24. Bxg6 Rxg6 25. Rh1  Rgh6  26. Rxh6 gxh6  27. Nd2 Qg6 28. Rc1  h5  29. gxh5 Rxh5  30. bxc4 Qf5 31. Rh1  Rxh1 32. Kxh1 Qc2  33. cxd5 Nxd5 34. c4 Nb6 35. c5  Nd5 36. Qe1 Qxa2   37. Ne4 a5 38. Qd1  a4 39. Qf3   Qb3   40. Qxf7 Qb1+ 41. Kh2 Qxe4 42. Qxe6+ Kc7 43. Qf7 Qxd4 44. Qe8 Bh4  45. Qf7+ Ne7 46. Kh3 Bxg3 47. Qxe7+ Qd7+ 0-1 "

; sample game 118
EventSites(118) = "BIH-chT  Jahorina" : GameDates(118) = "20030626" : WhitePlayers(118) = "Atalik, Suat   G#118" : WhiteElos(118) = "2568" : BlackPlayers(118) = "Almasi, Zoltan   G#118" : BlackElos(118) = "2676" : Each_Game_Result(118) = "1-0"

FilePGNs(118) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. a3 Bb7 5. Nc3 d5 6. cxd5 Nxd5 7. Bd2  Nd7 8. Nxd5 Bxd5 9. Qc2 c5 10. e4 Bb7 11. d5 exd5 12. exd5 Qe7+ 13. Be3 O-O-O 14. O-O-O Nf6 15. d6   Qe8  16. Bc4 Bxd6 17. Ng5 Rf8 18. Rhe1  Bc7 19. Rxd8+  Qxd8 20. Nxf7 Qd7 21. Ng5 Re8 22. Rd1 Qc6 23. Ne6   Kb8   24. Nxg7 Re7 25. Nf5 Re8 26. f3   Bc8 27. Bg1  Re5 28. Ng3 b5 29. Bd3 c4 30. Bf5 Bb7 31. Kb1  h5 32. Bd4 Rd5 33. Bh3 Qd6  34. Nf5 Qd8 35. Qf2 Ka8 36. Re1  Bc8 37. Bxf6  Qxf6  38. Ne7  1-0 "

; sample game 119
EventSites(119) = "Dortmund SuperGM  Dortmund" : GameDates(119) = "20030803" : WhitePlayers(119) = "Leko, Peter   G#119" : WhiteElos(119) = "2745" : BlackPlayers(119) = "Bologan, Viktor   G#119" : BlackElos(119) = "2650" : Each_Game_Result(119) = "0-1"

FilePGNs(119) = "1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Nd7 5. Bc4 Ngf6 6. Ng5 e6 7. Qe2 Nb6 8. Bd3 h6 9. N5f3 c5 10. Be3 Qc7 11. Ne5 a6 12. Ngf3 cxd4 13. Bxd4 Nbd5 14. O-O Bc5  15. Bb5+ Kf8  16. Bxc5+ Qxc5 17. Bc4  Ke7 18. Bxd5  Nxd5 19. c4 Nf6 20. Rfd1 Bd7 21. b4  Qc7 22. Nd4 Rhd8 23. Rd3 Kf8 24. Rad1 Be8  25. h3 Nd7  26. Ng4 Qxc4 27. Qd2  Rac8  28. Nb3 Qc7 29. Rc1 Qb8 30. Rxc8 Qxc8 31. b5  Qc4 32. bxa6 bxa6 33. Rd6  Qb5 34. Nd4 Qb1+ 35. Kh2 Rc8 36. Nb3 Nc5 37. Nxc5 Rxc5 38. Rxa6 Qb8+ 39. Kg1 Rb5 40. Ne3  Rb1+ 41. Nd1 Qe5 42. Ra3 Qg5  43. Re3 Ba4 44. Kh2 Qf4+ 45. g3 Rxd1  46. Qd8+ Rxd8 0-1 "

; sample game 120
EventSites(120) = "Dortmund SuperGM  Dortmund" : GameDates(120) = "20030806" : WhitePlayers(120) = "Bologan, Viktor   G#120" : WhiteElos(120) = "2650" : BlackPlayers(120) = "Naiditsch, Arkadij   G#120" : BlackElos(120) = "2574" : Each_Game_Result(120) = "1-0"

FilePGNs(120) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. c3 d5 9. exd5 Nxd5 10. Nxe5 Nxe5 11. Rxe5 c6 12. d4 Bd6 13. Re1 Qh4 14. g3 Qh3 15. Qf3  Be6  16. Qg2 Qh5 17. Bd1 Qg6 18. Nd2 Rae8 19. Ne4 Bf5 20. f3  c5  21. Bd2 cxd4 22. cxd4 Bb8 23. Bb3 Rd8 24. Nc5 h5 25. Rac1 h4 26. gxh4  Qh5  27. Ne4 Bxe4 28. Rxe4 Nf6 29. Re7 Rxd4 30. Bg5 Nd5 31. Qf2  Rd3 32. Qe2 Rxb3  33. Re8  Ba7+ 34. Kh1 Rxf3 35. Rxf8+ Kh7 36. Qe4+ 1-0 "

; sample game 121
EventSites(121) = "RUS-ch 56th  Krasnoiarsk" : GameDates(121) = "20030906" : WhitePlayers(121) = "Yakovich, Yuri   G#121" : WhiteElos(121) = "2573" : BlackPlayers(121) = "Yandarbiev, Ruslan   G#121" : BlackElos(121) = "2424" : Each_Game_Result(121) = "1-0"

FilePGNs(121) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Bb4 5. cxd5 exd5 6. Bg5 Nbd7 7. Qc2 c5 8. a3 Bxc3+ 9. Qxc3 c4 10. Nd2  O-O 11. e3 h6 12. Bf4 Re8 13. Be2 b5 14. a4  bxa4 15. Rxa4 Nb6 16. Ra5  Bg4 17. Bxg4 Nxg4 18. O-O Nf6 19. Rfa1 Nh5 20. Be5 f6 21. Bg3 Nxg3 22. hxg3  Qd7 23. Qa3 Reb8 24. Nb1  Rb7 25. Nc3 Rab8 26. Ra2  Ra8 27. Rb5  Rab8 28. Qa6 Kh7 29. Raa5 Qf7  30. Ra1  Qd7 31. Qa2  Qe6 32. Qb1+ g6 33. Ra6  Qe7 34. Qa2 Rd7  35. Na4   Rdb7 36. Nxb6 Qf7 37. Rxd5 axb6 38. Qxc4 Rd8 39. e4 Rxd5 40. exd5 Kg7 41. Qc6 b5 42. d6 Qd7 43. d5 g5 44. Ra8 Kg6 45. Rg8+ Kf7 46. Rc8 Kg6 47. Rc7 1-0 "

; sample game 122
EventSites(122) = "RUS-ch 56th  Krasnoiarsk" : GameDates(122) = "20030909" : WhitePlayers(122) = "Yakovich, Yuri   G#122" : WhiteElos(122) = "2573" : BlackPlayers(122) = "Motylev, Alexander   G#122" : BlackElos(122) = "2634" : Each_Game_Result(122) = "1/2-1/2"

FilePGNs(122) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 O-O 5. Bd3 d5 6. Nf3 c5 7. O-O cxd4 8. exd4 dxc4 9. Bxc4 a6 10. a4 Nc6 11. Bg5 h6 12. Be3  b6   13. Qe2 Be7 14. Rad1  Nb4 15. Ne5 Bb7 16. f4  Nfd5  17. f5 Bg5  18. Bxg5 Qxg5 19. Bxd5 Nxd5 20. Nxd5 Bxd5 21. Nd7 Rfe8  22. f6  Bb3  23. Ra1 Rad8 24. Ra3  Rxd7 25. Rxb3 g6 26. Qxa6 Rxd4  27. Qxb6 1/2-1/2 "

; sample game 123
EventSites(123) = "EU-chT (Men)  Plovdiv" : GameDates(123) = "20031012" : WhitePlayers(123) = "Svidler, Peter   G#123" : WhiteElos(123) = "2723" : BlackPlayers(123) = "Shirov, Alexei   G#123" : BlackElos(123) = "2737" : Each_Game_Result(123) = "1-0"

FilePGNs(123) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Be3 Qb6 5. Qc1 Nh6 6. Nf3 e6 7. Nbd2 c5 8. Nb3 Nd7 9. dxc5 Nxc5 10. Nfd4 Ng4  11. Bb5+ Kd8 12. O-O Nxe3 13. Qxe3 Bg6 14. Rfd1  Kc7 15. c4  dxc4  16. Bxc4  Rc8 17. Nd2 Kb8 18. Bb5 a6 19. Be2 Na4 20. Nc4 Rxc4  21. Bxc4 Nxb2  22. Nxe6   Qxe3 23. Rd8+ Ka7 24. fxe3 fxe6 25. Bxe6 1-0 "

; sample game 124
EventSites(124) = "EU-chT (Men)  Plovdiv" : GameDates(124) = "20031013" : WhitePlayers(124) = "Krasenkow, Michal   G#124" : WhiteElos(124) = "2597" : BlackPlayers(124) = "Eljanov, Pavel   G#124" : BlackElos(124) = "2597" : Each_Game_Result(124) = "1/2-1/2"

FilePGNs(124) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. e4 Nxc3 6. bxc3 Bg7 7. Be3 c5 8. Qd2 O-O 9. Rc1 Qa5 10. d5 e6 11. Nf3 exd5 12. exd5 Bg4 13. Ng5 Na6  14. h3 Bf5 15. g4 Bd7 16. Bg2 c4  17. O-O Nc5  18. Bxc5 Qxc5 19. Ne4 Qa3 20. Qf4 f5 21. Qc7  fxe4 22. Qxd7 Bxc3 23. d6 Rad8 24. Qxb7 Rxd6 25. Qxe4 Kh8 26. Qxc4 Be5 27. Rfe1 Rd4 28. Qe6 Bf6 29. Rc8 Rdd8 30. Rxd8 Bxd8 31. f4  Qg3 32. Rf1 Bb6+ 33. Kh1 Qe3 34. Qxe3 Bxe3 35. f5 gxf5 36. gxf5 Kg7 37. Bd5 Kf6 38. Be6 Rd8 39. Rb1 Bb6 40. Rb4 Rd4 1/2-1/2 "

; sample game 125
EventSites(125) = "EU-chT (Men)  Plovdiv" : GameDates(125) = "20031019" : WhitePlayers(125) = "Jobava, Baadur   G#125" : WhiteElos(125) = "2605" : BlackPlayers(125) = "Grischuk, Alexander   G#125" : BlackElos(125) = "2732" : Each_Game_Result(125) = "0-1"

FilePGNs(125) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. b4 Bxb4 5. c3 Bd6  6. d4 Nf6  7. O-O O-O 8. Re1 h6 9. Nh4  exd4 10. Nf5 Bc5 11. cxd4 d5  12. exd5 Bxf5 13. dxc5 Na5 14. Bb3 Nxb3 15. Qxb3 Qxd5  16. Nc3 Rfe8  17. Be3 Qc6 18. Qb5 Qxb5 19. Nxb5 Nd5 20. Bd2 Red8 21. Rac1 Bg6 22. a3 c6 23. Nd6 b6  24. Nc4 f6 25. f3 Bd3 26. Nb2 Bg6 27. Nc4 Rac8  28. Red1  Rd7 29. Be3 Rcd8 30. cxb6 axb6 31. Bf2 b5  32. Na5 Nf4 33. Rxd7 Rxd7 34. Ra1 Rd6 35. Be3 Nd3 36. a4 Re6 37. Bd2 Re2 38. Ra2 Bf7 39. Rc2 b4 40. Kf1 Rf2+ 41. Kg1 b3 42. Rb2 Nxb2 0-1 "

; sample game 126
EventSites(126) = "Vicente Bonil op 27th  Albox" : GameDates(126) = "20031122" : WhitePlayers(126) = "Dreev, Alexey   G#126" : WhiteElos(126) = "2705" : BlackPlayers(126) = "Arizmendi Martinez, Julen Luis   G#126" : BlackElos(126) = "2521" : Each_Game_Result(126) = "1/2-1/2"

FilePGNs(126) = "1. d4 d6 2. e4 Nf6 3. Nc3 Nbd7 4. Nf3 e5 5. Bc4 Be7 6. O-O O-O 7. Re1 c6 8. a4 a5  9. h3 exd4 10. Nxd4 Nc5 11. Bf4 Qb6 12. b3 Re8 13. Nf3  Be6 14. Nd2 Rad8 15. Bxe6 Nxe6 16. Nc4 Qa6 17. Bd2  d5 18. exd5 cxd5 19. Ne5 Ne4  20. Nxe4 dxe4 21. Nc4 Bb4  22. Qc1 Nd4 23. Kh1 Qg6 24. Bxb4 axb4 25. Rb1 Rd5 26. Rd1 Red8 27. Qf4 h6  28. Ne3 R5d7 29. Qe5 Qe6  30. Qxe6 Nxe6 31. Rxd7 Rxd7 32. a5  Rd2 33. Kg1 Nd4 34. g4  Nxc2 35. Nc4 Rd3 36. Kg2 Na3 37. Rc1 Rxb3  38. Nd6 Rc3 39. Ra1 b3 40. Rxa3 b2 41. Rxc3 b1=Q 42. Rc8+ Kh7 43. Nf5 Qb3 44. Ne3 1/2-1/2 "

; sample game 127
EventSites(127) = "Hastings 0304 79th  Hastings" : GameDates(127) = "20040105" : WhitePlayers(127) = "Rowson, Jonathan   G#127" : WhiteElos(127) = "2541" : BlackPlayers(127) = "Epishin, Vladimir   G#127" : BlackElos(127) = "2658" : Each_Game_Result(127) = "1-0"

FilePGNs(127) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 d5 5. a3 Be7  6. Nf3 Nbd7 7. Bf4 c6 8. e3 Nh5 9. Be5 O-O 10. h3  Nxe5 11. dxe5 g6 12. O-O-O  b5  13. cxb5 cxb5 14. Bxb5 Bb7 15. Nd4 Rc8 16. Qa4  Rc5  17. g4 Ng7 18. Kb1 a6 19. Be2 Qc7 20. f4 Rb8 21. Na2  Bc8  22. Rc1 Qb7 23. Nb4 a5 24. Rxc5 Bxc5 25. Qxa5 Bb6 26. Qa4 g5 27. Qd1 gxf4 28. exf4 Bd7 29. Qd2  Ba5 30. Rc1 h6 31. Rc5  Bxb4 32. axb4 Qxb4 33. Qc3  Qxc3 34. Rxc3 Rb4 35. Rd3 Bb5 36. Nxb5 Rxb5 37. Rd4 Rb8 38. b4 Ne8 39. Kb2 Kf8 40. b5 Ke7 41. Ra4 Nc7 42. h4  Rb7 43. g5 h5 44. Ra5 d4 45. Bc4 Ne8 46. Kb3 Ng7 47. Bd3 Nf5 48. Bxf5 exf5 49. Kc4 Rd7 50. Kd3 Rd5 51. Ra7+ Ke6 52. Kc4 Rd8 53. Ra6+ Ke7 54. Rd6 Rc8+ 55. Kb4 Rc1 56. Rxd4 Rh1 57. b6 1-0 "

; sample game 128
EventSites(128) = "Linares 21st  Linares" : GameDates(128) = "20040225" : WhitePlayers(128) = "Vallejo Pons, Francisco   G#128" : WhiteElos(128) = "2663" : BlackPlayers(128) = "Leko, Peter   G#128" : BlackElos(128) = "2722" : Each_Game_Result(128) = "1/2-1/2"

FilePGNs(128) = "1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Nf6 5. Nxc6 bxc6 6. e5 Qe7 7. Qe2 Nd5 8. c4 Nb6 9. b3 Qe6 10. Bb2 a5 11. Qc2   Bb4+ 12. Nd2 a4 13. Bd3 Qh6 14. Rd1 axb3 15. axb3 Ra2 16. O-O O-O 17. Qb1 Ra5 18. Nf3 d5 19. Nd4 Bd7 20. Nc2 dxc4 21. bxc4 Bd2  22. Bxh7+  Qxh7 23. Rxd2 Bf5 24. Bc3 Raa8  25. Qb3 1/2-1/2 "

; sample game 129
EventSites(129) = "Linares 21st  Linares" : GameDates(129) = "20040228" : WhitePlayers(129) = "Radjabov, Teimour   G#129" : WhiteElos(129) = "2656" : BlackPlayers(129) = "Kasparov, Garry   G#129" : BlackElos(129) = "2831" : Each_Game_Result(129) = "1/2-1/2"

FilePGNs(129) = "1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Nf6 5. Nxc6 bxc6 6. e5 Qe7 7. Qe2 Nd5 8. c4 Ba6 9. b3 g6 10. f4 f6 11. exf6 Qxe2+ 12. Bxe2 Bb4+ 13. Bd2 Bxd2+ 14. Nxd2 Nxf4 15. Rf1 Nxe2   16. Kxe2 Kf7 17. Kd3 Rae8 18. Rae1  Rxe1 19. Rxe1 Kxf6 20. Ne4+ Kg7 21. Nc3 Kf7 22. Rf1+ Ke7 23. Re1+ Kf7 24. Rf1+ Ke7 25. Re1+ Kd8  26. Rf1 Bb7 27. Ne4 Ke7 28. Re1 Kf7 29. Kd4 h6 30. b4 d6 31. c5 Rd8 32. Re3 g5 33. Ra3 a6 34. Rf3+ Kg7 35. Re3  Bc8  36. Rc3 dxc5+ 37. Kxc5 Be6 38. Kxc6  Bxa2 39. Nc5 Rb8  40. Ra3 Bc4 41. Ra4 Re8 42. Kxc7 Re2 43. g4  Rxh2 44. Nxa6 Rb2 45. Kb6 Be2 46. Nc5 Bxg4 47. b5 Be2 48. Ne6+ Kf6 49. Nd4 h5 50. Kc5 g4 51. b6 g3  52. b7 g2 53. b8=Q Rxb8 54. Nxe2 Rb2 55. Ng1 Rf2  56. Ra6+ Kf5 57. Kd4 Rf1 58. Ke3  1/2-1/2 "

; sample game 130
EventSites(130) = "Cappelle op 20th  Cappelle la Grande" : GameDates(130) = "20040304" : WhitePlayers(130) = "Murdzia, Piotr   G#130" : WhiteElos(130) = "2445" : BlackPlayers(130) = "Rozentalis, Eduardas   G#130" : BlackElos(130) = "2625" : Each_Game_Result(130) = "0-1"

FilePGNs(130) = "1. e4 e6 2. d4 d5 3. Nd2 c5 4. exd5 exd5 5. Bb5+ Bd7 6. Bxd7+ Nxd7 7. Ngf3 Bd6 8. O-O Ne7 9. dxc5 Nxc5 10. Nb3 Ne4 11. Bg5 Nxg5 12. Nxg5 h6 13. Nf3 O-O 14. c3 b5 15. Nbd4 b4  16. cxb4 Bxb4 17. a3 Bc5 18. b4 Bb6 19. a4 Qd6 20. b5 Ba5  21. Rc1  Rfc8 22. Qd3 Bb6  23. g3 Qb4  24. Nc6 Nxc6 25. bxc6 Qd6 26. Qc3 d4 27. Qc4 Qf6 28. Kg2 Rc7 29. Rfd1  Rac8 30. Qa6  Rxc6 31. Qxc8+ Rxc8 32. Rxc8+ Kh7 33. Rc2 Qg6 34. Rcd2 Qc6 35. a5 Bxa5 36. Rxd4 Bb6 37. Rf4 f6 38. g4 a5 39. h3 a4 40. Ra1 Qc2 41. Ng1 g5  42. Rfxa4 Qxf2+ 43. Kh1 Bd4 44. R4a2 Qg3 45. Rg2 Qd3  46. Re1 Bxg1 47. Kxg1 Qxh3 48. Rf1 Kg6 49. Re1 h5 50. gxh5+ Qxh5 51. Rf1 f5 52. Rgf2 Qg4+ 53. Rg2 Qd4+ 54. Kh1 Qe4 55. Kh2 Kf6 56. Rgf2 f4 57. Rf3 Kf5 58. R1f2 Kg4 59. Kg2 Qd5 60. Rf1 Kf5 61. Kg1 Kg6 62. Kh2 Qe6 63. Kg2 Qg4+ 64. Kf2 Qh4+ 65. Ke2  Kf5 66. R1f2 Qh5 67. Kf1 Qh1+ 68. Ke2 Qc1 69. Rf1 Qc2+ 70. Ke1 Qe4+ 71. Kd2 g4 0-1 "

; sample game 131
EventSites(131) = "Blackpool Weekend Congress  Blackpool" : GameDates(131) = "20040316" : WhitePlayers(131) = "Rowson, Jonathan   G#131" : WhiteElos(131) = "2548" : BlackPlayers(131) = "Wells, Peter K   G#131" : BlackElos(131) = "2497" : Each_Game_Result(131) = "1-0"

FilePGNs(131) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 d6 6. f3 e5 7. Nb3 Be7 8. Be3 O-O 9. Qd2 a5  10. Bb5 Na7 11. Be2 Nc6 12. O-O a4 13. Nc1 Qa5 14. a3  Be6 15. b4 axb3 16. Nxb3 Qc7 17. Rfb1  Rfc8  18. Nd5 Bxd5 19. exd5 Nb8  20. c4 Nfd7 21. a4 Na6 22. a5 g6 23. Ra2  Bf6 24. Rc2 Nac5 25. Nxc5 Nxc5 26. Rb5 e4 27. f4  Ra6 28. g3  Rca8 29. Ra2 Bg7 30. Kg2  h5  31. Qb4 Qd8  32. Bxc5 dxc5 33. Qxc5 b6 34. Qe3 Rxa5 35. Rbxa5 Rxa5 36. Rxa5 bxa5 37. Qxe4 Qd6  38. f5  gxf5  39. Qe8+ Bf8 40. Bxh5 Qf6 41. c5 Kg7 42. c6  Bd6 43. Qd7  Qe5 44. Qxf7+ Kh8 45. Kh3  a4 46. Bg6 Qg7 47. Qe8+  Bf8 48. c7 Qh6+ 49. Bh5 1-0 "

; sample game 132
EventSites(132) = "RUS-chT  Sochi" : GameDates(132) = "20040421" : WhitePlayers(132) = "Morozevich, Alexander   G#132" : WhiteElos(132) = "2732" : BlackPlayers(132) = "Bologan, Viktor   G#132" : BlackElos(132) = "2665" : Each_Game_Result(132) = "1-0"

FilePGNs(132) = "1. e4 c6 2. d4 d5 3. f3 e6 4. Nc3 Bb4 5. Bf4 Ne7 6. Qd3 b6 7. Ne2 Ba6 8. Qe3 O-O 9. O-O-O c5 10. a3 Bxc3 11. Qxc3 Bxe2 12. Bxe2 c4  13. h4 b5 14. Qe1 Nbc6 15. h5 Qd7 16. g4 f6 17. Bf1 Rad8 18. Bh3 dxe4 19. fxe4 Nxd4 20. g5 f5  21. Kb1  Qc6 22. h6 fxe4  23. Qc3  e3  24. Rxd4   Qxh1+ 25. Ka2 Qxh3 26. Rxd8 gxh6 27. gxh6 Qg4 28. Qh8+ 1-0 "

; sample game 133
EventSites(133) = "RUS-chT  Sochi" : GameDates(133) = "20040424" : WhitePlayers(133) = "Kobalia, Mihail   G#133" : WhiteElos(133) = "2630" : BlackPlayers(133) = "Ovetchkin, Roman   G#133" : BlackElos(133) = "2492" : Each_Game_Result(133) = "0-1"

FilePGNs(133) = "1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Bf5 5. Ng3 Bg6 6. h4 h6 7. Nf3 Nd7 8. h5 Bh7 9. Bd3 Bxd3 10. Qxd3 e6 11. Bf4 Qa5+ 12. Bd2 Bb4 13. Ne4 Bxd2+ 14. Nfxd2 Ngf6 15. Nd6+ Ke7 16. Nc4 Qc7 17. O-O-O Rhd8 18. Qa3+ c5 19. Nb3 b6 20. Kb1  Kf8 21. dxc5 bxc5  22. Qa6 Nb6 23. Qb5 Nfd5 24. a3  a6   25. Qxc5+ Qxc5 26. Nxc5 Nxc4 27. Rd3 Rdc8 28. Na4 Rab8 29. Rh4 Rb5 30. Kc1 Ra5 31. b3 Nxa3 32. c4 Nb4 33. Rdd4 e5 34. Nb6 Rc6 35. Rd8+ Ke7 36. Rb8 Rb5 37. Nc8+ Ke6 38. Ra8 Nd3+ 0-1 "

; sample game 134
EventSites(134) = "Sarajevo Bosnia 34th  Sarajevo" : GameDates(134) = "20040522" : WhitePlayers(134) = "Shirov, Alexei   G#134" : WhiteElos(134) = "2713" : BlackPlayers(134) = "Atalik, Suat   G#134" : BlackElos(134) = "2558" : Each_Game_Result(134) = "1-0"

FilePGNs(134) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Na5 10. Bc2 c5 11. d4 cxd4 12. cxd4 Bb7 13. d5  Rc8 14. Nbd2 Nh5 15. Nf1 Nc4 16. a4  b4  17. b3 Na3 18. Bd3 a5  19. Nxe5 Bf6 20. Qxh5 Bxe5 21. Ra2 Rc3 22. Qd1 Qf6  23. Re3  Rfc8 24. Bd2 R3c5 25. Rf3 Qd8 26. Ne3 R8c7 27. Ng4  Qc8 28. Bf1  Rc1 29. Bxc1 Rxc1 30. Qd2 Ba6 31. Nxe5 Rxf1+ 32. Kh2 dxe5 33. d6 Bb7   34. d7 Qd8 35. Rd3  f6 36. Rd6  Kf7 37. Qe2  Rc1 38. Qh5+ Ke7 39. Re6+  Kxd7 40. Rd2+ 1-0 "

; sample game 135
EventSites(135) = "Sarajevo Bosnia 34th  Sarajevo" : GameDates(135) = "20040525" : WhitePlayers(135) = "Bologan, Viktor   G#135" : WhiteElos(135) = "2665" : BlackPlayers(135) = "Atalik, Suat   G#135" : BlackElos(135) = "2558" : Each_Game_Result(135) = "1-0"

FilePGNs(135) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Nb8 10. d4 Nbd7 11. Nbd2 Bb7 12. Bc2 c5  13. d5 g6 14. Nf1 Nh5 15. Bh6 Re8 16. a4 Nb6  17. a5  Nc4 18. b3  Nxa5 19. Ra2 Qc7 20. Qa1 Bd8 21. N1d2 Bc8  22. Rc1 Nf4 23. Bxf4 exf4 24. b4 cxb4 25. cxb4 Nc4 26. Bd3 Qb8 27. Bxc4  bxc4 28. Nxc4 Rxe4 29. Na5  Bxa5 30. bxa5 Qb5 31. Rd2 Bb7 32. h4  Bxd5 33. h5 Ra4 34. Qf6 Bxf3  35. Rdc2  Re8  36. h6 Qe5 37. Rc8 Bc6 38. Qxe5 dxe5 39. R1xc6 Kf8  40. R8c7   Ra1+ 41. Kh2 Re6  42. Rb6   e4 43. Rb8+ Re8 44. Rbb7 Re5  45. Rxf7+ Ke8 46. g4  fxg3+ 47. Kxg3 Rg5+ 48. Kf4 Rf5+ 49. Rxf5 gxf5 50. Rxh7 Rf1 51. Rb7 Rxf2+ 52. Kg3 1-0 "

; sample game 136
EventSites(136) = "Dortmund-B playoff  Dortmund" : GameDates(136) = "20040727" : WhitePlayers(136) = "Kramnik, Vladimir   G#136" : WhiteElos(136) = "2770" : BlackPlayers(136) = "Bologan, Viktor   G#136" : BlackElos(136) = "2663" : Each_Game_Result(136) = "1-0"

FilePGNs(136) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 a6 5. c4 Nf6 6. Nc3 d6 7. Be2 Nbd7  8. Be3 b6 9. O-O Bb7 10. f3 Be7 11. a4  O-O 12. a5  bxa5 13. Nb3 Rb8 14. Nxa5 Ba8 15. Qd2 Qc7 16. Rfc1 Nc5  17. b4  Ncd7 18. b5  Nc5  19. bxa6  Nxa6  20. Nb5 Qd7 21. Nb3 Bb7 22. Rd1 Rfd8 23. Ba7  Ra8 24. Bb6  Rdb8 25. Nxd6  Bxe4  26. Nxe4 Qxd2 27. Nexd2 Rxb6 28. c5  1-0 "

; sample game 137
EventSites(137) = "Calvia ol (Men)  Mallorca" : GameDates(137) = "20041022" : WhitePlayers(137) = "Fridman, Daniel   G#137" : WhiteElos(137) = "2578" : BlackPlayers(137) = "Kortschnoj, Viktor   G#137" : BlackElos(137) = "2601" : Each_Game_Result(137) = "1/2-1/2"

FilePGNs(137) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Bb7 5. Bg2 Be7 6. O-O O-O 7. Nc3 Ne4 8. Bd2 d5 9. Ne5 Nxc3 10. Bxc3 Nd7 11. cxd5 exd5 12. Qa4 Nxe5 13. dxe5 Qc8  14. Rfd1 Qe6 15. Rd2 c5 16. e3 Bc6 17. Qd1 Rfd8 18. Qf1 b5 19. Ba5 Re8 20. Rad1 Bd8 21. Bxd8 Raxd8 22. f4 f6 23. Bh3 Qf7 24. e6 Rxe6 25. Bxe6 Qxe6 26. Rc1  d4  27. Rxc5 Qxe3+ 28. Qf2 Qe4 29. Rxc6 Qxc6 30. Rxd4 Re8 31. Rd1 h5 32. Rf1 a6 33. Qf3 Qc5+ 34. Qf2 Re3 35. Rd1 Kh7 36. b3 Kh6 37. Kf1 Qc3 38. Qd2 h4 39. gxh4 Rf3+ 40. Kg2 Qxd2+ 41. Rxd2 Rxf4 42. Rd8 Rxh4 43. Ra8 b4 44. Rxa6 Kg5 45. Rb6 Rd4 46. Kg3 f5 47. Rb5 g6 48. Rb6 Rg4+ 49. Kh3 Kh5 50. Rb8 Rg1 51. Rb5 Kg5  52. Rxb4 f4 53. Rb8 Kf5 54. a4 f3 55. Rf8+ Ke4 56. a5 Ke3 57. a6 f2 58. a7 Ra1 1/2-1/2 "

; sample game 138
EventSites(138) = "Calvia ol (Men)  Mallorca" : GameDates(138) = "20041027" : WhitePlayers(138) = "Navara, David   G#138" : WhiteElos(138) = "2620" : BlackPlayers(138) = "Kortschnoj, Viktor   G#138" : BlackElos(138) = "2601" : Each_Game_Result(138) = "1/2-1/2"

FilePGNs(138) = "1. e4 e6 2. d4 d5 3. Nd2 c5 4. Ngf3 Nf6 5. e5 Nfd7 6. c3 Nc6 7. Bd3 a5  8. O-O Be7 9. Re1 c4 10. Bc2 b5 11. Nf1 Nb6 12. N3d2 h5 13. f4 b4 14. Qf3 g6 15. g3 a4 16. a3 bxa3 17. bxa3 Na5 18. h3 Nb3 19. Ra2 Rb8 20. g4 hxg4 21. hxg4 Na8 22. Nb1 Nc7 23. Ng3 Nb5 24. Be3 Kd7  25. f5 gxf5 26. gxf5 Bh4 27. f6 Rg8  28. Bf4 Kc6 29. Kg2 Rh8 30. Rh1 Qg8  31. Rh3 Bd7 32. Be3 Kc7 33. Qf4 Bxg3 34. Rxg3 Qf8 35. Rg7 Kb6 36. Bd1 Ka6 37. Qg5 Be8 38. Bc2 Bc6 39. Bh7 Nc7 40. Qh5 Be8 41. Rb2 Nb5 42. Bh6 Nxa3 43. Rg5 Rxh7 44. Bxf8 Rxh5 45. Rxh5 Nb5 46. Bd6  Nxd6 47. exd6 Kb5 48. Rh8 Kc6 49. Ra2 Ra8 50. Na3 Kxd6 51. Kf3 Nc1 52. Rb2 Kc7 53. Rg2 Rb8 54. Rgg8 Kd7 55. Rf8 Rd8 56. Ke3  Nd3 57. Nb5 e5  58. Nd6 exd4+ 59. Kxd4 Kxd6 60. Rxe8 Rxe8 61. Rxe8 Nf4 62. Re7 a3 63. Rxf7 Ne6+ 64. Ke3 Ke5 65. Ra7 Kxf6 66. Rxa3 Ke5 67. Ra7 Ng5 68. Re7+ Ne6 69. Rh7 Kd6 70. Rh5 Kc6 71. Rh1 Kd6 72. Re1 Ke5 73. Kf3+ Kf5 74. Rd1 Ke5 75. Re1+ Kf5 76. Rh1 d4 77. cxd4 Nxd4+ 1/2-1/2 "

; sample game 139
EventSites(139) = "Bundesliga 0405  Germany" : GameDates(139) = "20050129" : WhitePlayers(139) = "Polzin, Rainer   G#139" : WhiteElos(139) = "2517" : BlackPlayers(139) = "Chuchelov, Vladimir   G#139" : BlackElos(139) = "2571" : Each_Game_Result(139) = "1-0"

FilePGNs(139) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5 6. Ndb5 d6 7. Bg5 a6 8. Na3 b5 9. Nd5 Be7 10. Bxf6 Bxf6 11. c4 Qa5+  12. Qd2 b4 13. Nc2 Rb8 14. b3 Qc5 15. Nxf6+ gxf6 16. g3   a5  17. Bg2 Be6 18. Rd1 Ke7 19. O-O a4 20. Qh6   Ra8 21. Rd3 axb3 22. axb3 Rhg8 23. Bh3 Rg6 24. Qxh7  Rag8 25. Bxe6 R6g7 26. Qh6 fxe6 27. Rfd1 Rg6 28. Qh3 R6g7 29. Rxd6 Qxd6 30. Rxd6 Kxd6 31. Qh6 Ke7 32. Qe3 Rb8 33. Qc5+ Kd7 34. Kg2 Rgg8 35. h4 Rgc8 36. Qe3 Ke7 37. g4 Rd8 38. Qc5+ Rd6 39. h5 Kd7 40. h6 Rd3 41. h7 Rxb3 42. Qb5 Rd8 43. c5 1-0 "

; sample game 140
EventSites(140) = "Rilton Cup 34th  Stockholm" : GameDates(140) = "20050103" : WhitePlayers(140) = "Ulibin, Mikhail   G#140" : WhiteElos(140) = "2556" : BlackPlayers(140) = "Cramling, Pia   G#140" : BlackElos(140) = "2477" : Each_Game_Result(140) = "0-1"

FilePGNs(140) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 Qc7 6. f4 a6 7. Nb3 b5 8. Bd3 d6 9. Be3 Nf6 10. Qf3 Bb7 11. O-O h5  12. Kh1 Be7 13. a4  b4 14. Nd1 d5  15. Nf2 dxe4 16. Nxe4 Nxe4 17. Qxe4  Na5  18. Qd4  Nxb3 19. cxb3 Rd8  20. Qxg7 Bf6  21. Qxf6 Rg8 22. Rg1 Rxd3 23. Bf2 Rd2  24. Bg3 Bd5  25. Qh4 Qb7 26. h3 Bxg2+ 27. Kh2 Bf1+ 0-1 "

; sample game 141
EventSites(141) = "Poikovsky Karpov 6th  Poikovsky" : GameDates(141) = "20050226" : WhitePlayers(141) = "Vaganian, Rafael A   G#141" : WhiteElos(141) = "2670" : BlackPlayers(141) = "Dominguez, Lenier   G#141" : BlackElos(141) = "2661" : Each_Game_Result(141) = "1/2-1/2"

FilePGNs(141) = "1. Nf3 d5 2. g3 c6 3. Bg2 Nf6 4. O-O Bf5 5. d3 e6 6. Qe1 h6 7. Nbd2 Be7 8. e4 Bh7 9. Ne5 Nbd7 10. Nxd7 Nxd7 11. f4 O-O 12. Kh1 dxe4 13. dxe4 Nc5 14. Qe3  Qd7 15. a4  Rfd8 16. Nb3 Nxb3 17. Qxb3 Bc5 18. g4 Qe7 19. f5 h5   20. fxe6 Qxe6 21. Qxe6 fxe6 22. gxh5 Rd4 23. Be3 Rc4 24. Bxc5 Rxc5 25. c3 Rf8 26. Rxf8+ Kxf8 27. Bf3 Re5 28. Re1 Ra5 29. Rd1 Ke7 30. b3 b5 31. axb5 Rxb5 32. b4 a5 33. bxa5 Rxa5 34. Kg2 Rc5 35. Ra1 Kf6 36. Ra7 Bg8 37. e5+ Rxe5 38. Bxc6 1/2-1/2 "

; sample game 142
EventSites(142) = "Poikovsky Karpov 6th  Poikovsky" : GameDates(142) = "20050227" : WhitePlayers(142) = "Bologan, Viktor   G#142" : WhiteElos(142) = "2683" : BlackPlayers(142) = "Rublevsky, Sergei   G#142" : BlackElos(142) = "2650" : Each_Game_Result(142) = "1-0"

FilePGNs(142) = "1. d4 d5 2. c4 dxc4 3. e3 e6 4. Bxc4 c5 5. Nf3 a6 6. O-O Nf6 7. Bb3 b5 8. a4 b4 9. e4  cxd4 10. Nbd2 Be7 11. e5 Nfd7 12. Nc4 Nc6 13. Nxd4 Ncxe5 14. Bf4 Nxc4 15. Nc6 Qb6 16. Nxe7 Kxe7 17. Bxc4 Bb7 18. Qd2 Rhc8 19. Rac1  Ke8  20. Rfe1 Nf6  21. b3 Rd8 22. Qa2 Rac8 23. a5 Qc6  24. Bf1 Qd7 25. Qa1 Kf8 26. Bg5 Rxc1 27. Rxc1 Rc8  28. Rxc8+ Qxc8 29. Qd4 Nd5 30. Bd2  Kg8 31. Bxb4 h6 32. Qc5  Qxc5 33. Bxc5 g5 34. f3 f6 35. Kf2 Kf7 36. b4 Nc7 37. Be2 Bc6 38. Bb6 Nb5 39. Ke3 f5  40. g3 Kg6 41. Kd3 Bd5 42. Bd4 h5 43. Be5 g4 44. Ke3 Bc6 45. Kf2 Kf7 46. h4  gxh3 47. Kg1 Bb7 48. Kh2 Na3 49. Kxh3 Nc2 50. Bc3 Ne3 51. Kh4 f4  52. gxf4 Kg6 53. Bd3+ Nf5+ 54. Kh3 Kh6 55. Bc4 Kg6 56. Bxe6 Bxf3 57. b5  axb5 58. a6 Ne7 59. Bd7 Nd5 60. Kg3 Be4 61. f5+  Kg5 62. Ba5 h4+ 63. Kf2 Nf6 64. Bc8 b4 65. Bxb4 Kg4 66. Bb7 h3 67. Bxe4 Nxe4+ 68. Kg1 Kg3 69. Be1+ 1-0 "

; sample game 143
EventSites(143) = "CUB-ch KO  Santa Clara" : GameDates(143) = "20050422" : WhitePlayers(143) = "Dominguez, Lenier   G#143" : WhiteElos(143) = "2658" : BlackPlayers(143) = "Almeida Quintana, Omar   G#143" : BlackElos(143) = "2452" : Each_Game_Result(143) = "1-0"

FilePGNs(143) = "1. e4 Nf6 2. e5 Nd5 3. d4 d6 4. c4 Nb6 5. f4 dxe5 6. fxe5 Bf5 7. Nc3 e6 8. Be3 Nc6 9. Nf3 Be7 10. d5 exd5 11. cxd5 Nb4 12. Nd4 Bd7 13. Qf3 c5 14. dxc6 bxc6 15. Be2 O-O 16. O-O N4d5 17. Bf2 Qc7 18. Bg3 Nxc3 19. bxc3 Qc8 20. Bd3 g6 21. Be4 Bg4 22. Qf2 Nd5 23. c4 Nc3 24. Nxc6  Nxe4 25. Nxe7+ Kg7 26. Qf4 Qc5+ 27. Rf2 Bf5 28. Bh4 f6 29. Nxf5+ gxf5 30. Qxf5 Qxe5 31. Qxe5 fxe5 32. Re2 Rf4 33. g3 Nc3 34. Rxe5 Rxc4 35. Rf1 Nxa2 36. Re7+  Kg8  37. Rff7 Rg4 38. Bf6 Rg6 39. Rg7+ Rxg7 40. Rxg7+ Kf8 41. Rxh7 Re8 42. Rxa7 Re2 43. Rb7 Nc1 44. Rb2 Kf7 45. Bh8 Re8 46. Rf2+ Kg6 47. Bb2 Nd3 48. Rd2 Re3 49. Bd4 Rf3 50. Bf2 Ne5 51. Kg2 Rf7 52. h3 Kh7 53. g4 1-0 "

; sample game 144
EventSites(144) = "Sofia MTel Masters  Sofia" : GameDates(144) = "20050516" : WhitePlayers(144) = "Kramnik, Vladimir   G#144" : WhiteElos(144) = "2753" : BlackPlayers(144) = "Polgar, Judit   G#144" : BlackElos(144) = "2732" : Each_Game_Result(144) = "1-0"

FilePGNs(144) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 O-O 5. a3 Bxc3+ 6. Qxc3 b6 7. Nf3 Bb7 8. e3 d6 9. Be2 Nbd7 10. O-O Ne4 11. Qc2 f5 12. b4 Rf6 13. d5 Rg6 14. Nd4  Qg5 15. g3 exd5 16. cxd5 Bxd5 17. Bc4 Bxc4 18. Qxc4+ Kh8 19. Qc6  Rd8 20. Qxc7 Ne5 21. Ra2  Rf8 22. f4 Qg4 23. Qe7 Rg8 24. Rg2 Nd3 25. Qxa7 h5 26. Qa6 Nxc1 27. Rxc1 h4 28. Qe2 Qxe2 29. Rxe2 hxg3 30. Nxf5 gxh2+ 31. Kh1 Rg1+ 32. Rxg1 hxg1=Q+ 33. Kxg1 Ra8 34. Ra2 Nc3 35. Rh2+ Kg8 36. Rg2 Kf7 37. Nxd6+ Ke6 38. Nc4 b5 39. Na5 Kf6 40. Rd2  g5 41. Rd3 Ne4 42. fxg5+ Kxg5 43. Kg2 Rf8 44. Rd5+ Kg4 45. Rd4 Kf5 46. Nc6 Rg8+ 47. Kf1 Ra8 48. Ne7+ Ke5 49. Nc6+ Kf5 50. Ne7+ Ke5 51. Ng6+ Kf5 52. Nh4+ Ke5 53. Nf3+ Kf5 54. Nh4+ Ke5 55. Nf3+ Kf5 56. Rd5+ Kf6 57. Rd3 Rh8 58. Ke2 Ke7 59. Nd4 Rh2+ 60. Kf3 Nd6 61. Rc3 Rh3+ 62. Kg4 1-0 "

; sample game 145
EventSites(145) = "Sofia MTel Masters  Sofia" : GameDates(145) = "20050518" : WhitePlayers(145) = "Topalov, Veselin   G#145" : WhiteElos(145) = "2778" : BlackPlayers(145) = "Anand, Viswanathan   G#145" : BlackElos(145) = "2785" : Each_Game_Result(145) = "1-0"

FilePGNs(145) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Ba6 5. b3 Bb4+ 6. Bd2 Be7 7. Nc3 c6 8. e4 d5 9. Qc2 dxe4 10. Nxe4 Bb7 11. Neg5 c5 12. d5 exd5 13. cxd5 h6 14. Nxf7  Kxf7 15. O-O-O Bd6  16. Nh4  Bc8  17. Re1  Na6 18. Re6  Nb4  19. Bxb4 cxb4 20. Bc4 b5  21. Bxb5 Be7  22. Ng6  Nxd5 23. Rxe7+  Nxe7 24. Bc4+ Kf6 25. Nxh8 Qd4  26. Rd1 Qa1+ 27. Kd2 Qd4+ 28. Ke1 Qe5+ 29. Qe2 Qxe2+ 30. Kxe2 Nf5 31. Nf7 a5 32. g4 Nh4 33. h3 Ra7 34. Rd6+ Ke7 35. Rb6 Rc7 36. Ne5 Ng2 37. Ng6+ Kd8 38. Kf1 Bb7 39. Rxb7 Rxb7 40. Kxg2 Rd7 41. Nf8 Rd2 42. Ne6+ Ke7 43. Nxg7 Rxa2 44. Nf5+ Kf6 45. Nxh6 Rc2 46. Bf7 Rc3 47. f4 a4 48. bxa4 b3 49. g5+ Kg7 50. f5 b2 51. f6+ Kh7 52. Nf5  1-0 "

; sample game 146
EventSites(146) = "Sofia MTel Masters  Sofia" : GameDates(146) = "20050521" : WhitePlayers(146) = "Topalov, Veselin   G#146" : WhiteElos(146) = "2778" : BlackPlayers(146) = "Ponomariov, Ruslan   G#146" : BlackElos(146) = "2695" : Each_Game_Result(146) = "1-0"

FilePGNs(146) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Ba6 5. b3 Bb4+ 6. Bd2 Be7 7. Nc3 O-O 8. Rc1 c6 9. e4 d5 10. e5  Ne4 11. Bd3 Nxc3  12. Rxc3 c5 13. dxc5 bxc5 14. h4 h6  15. Bb1  f5 16. exf6  Bxf6 17. Qc2 d4 18. Ng5  hxg5 19. hxg5 dxc3 20. Bf4 Kf7 21. Qg6+ Ke7 22. gxf6+ Rxf6 23. Qxg7+ Rf7 24. Bg5+ Kd6 25. Qxf7 Qxg5 26. Rh7 Qe5+ 27. Kf1 Kc6 28. Qe8+ Kb6 29. Qd8+ Kc6 30. Be4+  1-0 "

; sample game 147
EventSites(147) = "George Marx mem 3rd  Paks" : GameDates(147) = "20050615" : WhitePlayers(147) = "Kortschnoj, Viktor   G#147" : WhiteElos(147) = "2619" : BlackPlayers(147) = "Sutovsky, Emil   G#147" : BlackElos(147) = "2665" : Each_Game_Result(147) = "1-0"

FilePGNs(147) = "1. c4 Nf6 2. g3 c6 3. Nf3  d5 4. b3 Bg4 5. Ne5  Bf5 6. Bg2 Nbd7 7. d4 e6 8. O-O Bd6 9. Bb2 Qc7 10. Nd3  h5  11. c5 Be7 12. b4 h4 13. Nd2 Ng4 14. h3  hxg3  15. hxg4 gxf2+ 16. Rxf2 Qh2+ 17. Kf1 Bxg4 18. Nf3 Bxf3  19. Bxf3 Qh3+ 20. Bg2 Qg3 21. Rf3 Qh2 22. Nf2 Rh5 23. Bc1  Bg5 24. Rh3 Rxh3 25. Nxh3 Bxc1 26. Qxc1 e5 27. Qg5 exd4 28. Qxg7 Qe5 29. Qxe5+ Nxe5 30. Rd1 a5 31. b5 Nd7 32. Nf4 Nxc5 33. bxc6 bxc6 34. Rc1 Ne6 35. Nxe6 fxe6 36. Rxc6 Kd7 37. Rb6 Rc8 38. Bh3 Rc1+ 39. Kf2 Rc2 40. Rxe6 Kc7 41. Bf5 Rxa2 42. Bd3 Ra1 43. Kf3 Rf1+ 44. Kg4 a4 45. Ra6 a3 46. Rxa3 Kd6 47. Ra8 Ke6 48. Bf5+ Kd6 49. Ra6+ Ke7 50. Re6+ Kd7 51. Kg5 Rf2 52. Bg4 Rg2 53. Re4+ Kd6 54. Rxd4 Ke5 55. Rd3 d4 56. Kh4 Rg1 57. Kh3 Ke4 58. Bf3+ Ke5 59. Kh2 Rg7 60. Bg2 Rg8 61. Kg1 Rf8 62. Bf3 Rf6 63. Kf2 Ra6 64. Rb3 Ra1 65. Rb5+ Kf4 66. Rb8 Rd1 67. Re8 Kg5 68. Be4 1-0 "

; sample game 148
EventSites(148) = "EU-ch 6th  Warsaw" : GameDates(148) = "20050621" : WhitePlayers(148) = "Wojtaszek, Radoslaw   G#148" : WhiteElos(148) = "2569" : BlackPlayers(148) = "Sokolov, Ivan   G#148" : BlackElos(148) = "2662" : Each_Game_Result(148) = "1-0"

FilePGNs(148) = "1. Nf3 d5 2. c4 c6 3. e3 Nf6 4. Nc3 a6 5. b3 Bg4 6. Bb2 e5 7. h3 Bxf3 8. Qxf3 Be7  9. g4 e4 10. Qg2 O-O 11. f3 exf3 12. Qxf3 Ne4  13. Nxe4 dxe4 14. Qxe4 Bh4+ 15. Kd1 Bf6 16. Bd3 g6 17. Bxf6 Qxf6 18. Kc2 c5  19. Qf4 Qb6 20. Be4 Nc6 21. a3 a5 22. Bxc6  Qxc6 23. a4 Rad8 24. Rad1 Rfe8 25. Rhf1 Rd7 26. Qf3 Qb6 27. h4  Re6 28. h5 Qb4 29. Qf4 Rb6 30. Qb8+ Kg7 31. h6+ Kxh6 32. Rh1+ Kg7 33. Rxh7+ Kf6 34. Qh8+ Ke6 35. Qc3 Rbd6 36. d4 Ke7 37. Rf1 Rf6 38. Rxf6 Qxc3+ 39. Kxc3 Kxf6 40. d5 Kg5 41. e4 Kf4 42. Kd3 Re7 43. g5 b6 44. Rh8 Rb7 45. Rf8 Re7 46. Rb8 Rxe4 47. Rxb6 Re3+ 48. Kd2 Rg3 49. Rb7 Ke5 50. Rxf7 Rxb3 51. Rf6 Kd4 52. Rf4+ Ke5 53. Rf6 Kd4 54. Rxg6 Kxc4 55. d6 Rd3+ 56. Ke2 Rd4 57. Rf6 Kd5 58. g6 Kc6 59. Kf3 Rd3+ 60. Kf4 Rd1 61. Kf5 Rg1 62. Ke6 c4 63. Ke7 1-0 "

; sample game 149
EventSites(149) = "EU-ch 6th  Warsaw" : GameDates(149) = "20050629" : WhitePlayers(149) = "Beliavsky, Alexander G   G#149" : WhiteElos(149) = "2630" : BlackPlayers(149) = "Popov, Valerij   G#149" : BlackElos(149) = "2568" : Each_Game_Result(149) = "1-0"

FilePGNs(149) = "1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. cxd5 exd5 5. Bg5 c6 6. e3 Bf5 7. Qf3 Bg6 8. Bxf6 Qxf6 9. Qxf6 gxf6 10. Nf3 Nd7 11. g3 Nb6 12. Nh4 Nc4  13. Bxc4 dxc4 14. e4 O-O-O 15. O-O-O Bb4 16. f3 Rd7 17. Rd2 Rhd8 18. Rhd1 b5 19. Kc2  Ba5 20. a3 a6 21. d5  c5 22. Re2 Kb7 23. g4 Bc7 24. Ng2 h5 25. h3 Rg8 26. f4 Bh7 27. f5   hxg4 28. hxg4 Rxg4 29. Rh1 Rg7 30. Ne3 Rd8 31. Rg2 Rdg8 32. Rxg7 Rxg7 33. Rh4 Be5 34. Ne2 Kc7 35. Ng4 Kd6 36. Nxe5 Kxe5 37. Kd2 b4 38. axb4 cxb4 39. Ke3 a5  40. Nd4  Kd6 41. Rh6 Rg3+ 42. Kf4 Rd3 43. Rxf6+ Ke7 44. Ke5 c3 45. bxc3 bxc3 46. d6+ 1-0 "

; sample game 150
EventSites(150) = "EU-chT (Men) 15th  Gothenburg" : GameDates(150) = "20050801" : WhitePlayers(150) = "Berg, Emanuel   G#150" : WhiteElos(150) = "2539" : BlackPlayers(150) = "Graf, Alexander   G#150" : BlackElos(150) = "2605" : Each_Game_Result(150) = "0-1"

FilePGNs(150) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Nb8 10. d4 Nbd7 11. Nbd2 Bb7 12. Bc2 Re8 13. Nf1 Bf8 14. Ng3 g6 15. b3 d5  16. dxe5 Nxe5  17. Nxe5 Rxe5 18. f4 Re8 19. e5 Nd7 20. Qg4 Bg7 21. Ba3  c5 22. Rad1 Bc6 23. h4  Qa5 24. h5  Qxc3  25. hxg6 hxg6 26. Re2 Nf8 27. Bb2  Bd7  28. Qg5 Qxb2 29. Bxg6 Qc3 30. Bxf7+ Kxf7 31. Nh5 Ne6 32. Qf5+ Kg8 33. Nf6+ Bxf6 34. exf6 Kf7  35. Rxd5  Qc1+  36. Kh2 Rh8+ 37. Kg3 Rag8+ 38. Kf2 Rxg2+  39. Kxg2 Qh1+ 40. Kf2 Rh2+ 41. Kg3 Qg1+ 42. Kf3 Nd4+ 0-1 "

; sample game 151
EventSites(151) = "EU-chT (Men) 15th  Gothenburg" : GameDates(151) = "20050804" : WhitePlayers(151) = "Kotronias, Vasilios   G#151" : WhiteElos(151) = "2587" : BlackPlayers(151) = "Kortschnoj, Viktor   G#151" : BlackElos(151) = "2615" : Each_Game_Result(151) = "1-0"

FilePGNs(151) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 d6 6. Be3 Nf6 7. f4 Be7 8. Qf3 e5 9. Nxc6 bxc6 10. f5 d5 11. exd5 Bb4  12. Bd2 O-O 13. O-O-O cxd5 14. Nxd5 e4  15. Nxf6+ Qxf6 16. Qe3 Bxd2+ 17. Rxd2 Rb8 18. Rd4 Qb6 19. b3 Bxf5 20. Bc4 Rbd8 21. Rhd1 Bg6 22. Kb2 Bh5 23. R1d2 Rde8 24. h3  Kh8 25. g4  Bg6 26. Qf4  f5 27. Rd6 Qb8 28. R2d5 fxg4  29. Qxg4 Bf5 30. Qh4 Qc7 31. Bb5 Rc8 32. c4 e3 33. Qd4 e2 34. Qe3  Bxh3  35. Qxe2 Qf7 36. Ka3 Rb8 37. Qe3 Bf5 38. Re5 Rb7 39. Bc6 Qc7 40. Rxf5  1-0 "

; sample game 152
EventSites(152) = "EU-chT (Men) 15th  Gothenburg" : GameDates(152) = "20050807" : WhitePlayers(152) = "Illescas Cordoba, Miguel   G#152" : WhiteElos(152) = "2624" : BlackPlayers(152) = "Baburin, Alexander   G#152" : BlackElos(152) = "2523" : Each_Game_Result(152) = "1-0"

FilePGNs(152) = "1. e4 Nf6 2. e5 Nd5 3. d4 d6 4. c4 Nb6 5. f4 dxe5 6. fxe5 Nc6 7. Be3 Bf5 8. Nc3 e6 9. Nf3 Bg4 10. Be2 Bxf3 11. gxf3 Qh4+ 12. Bf2 Qf4 13. c5 Nd5 14. Nxd5 exd5 15. Qd2 Qxd2+ 16. Kxd2 g6 17. Be3 f6 18. exf6 Kf7 19. Bb5 Nd8 20. Bd7 Kxf6 21. Bf4 Ke7 22. Bh3 c6 23. Rhe1+  Kf7 24. Kd3 Bg7 25. a4 Bf6 26. b4 a6 27. Bd7 g5 28. Bg3 h5 29. b5 axb5 30. axb5 Rxa1 31. Rxa1 cxb5 32. Bxb5 Kg6 33. Re1 Kf7 34. Bd7 Nc6 35. Be6+  Kg7 36. Rb1 Nxd4 37. Rxb7+ Kh6 38. Bxd5 Rd8 39. Kc4 Nf5 40. Be4 Rd4+ 41. Kb5 Rxe4 42. fxe4 Nxg3 43. hxg3 Be5 44. Re7 1-0 "

; sample game 153
EventSites(153) = "EU-chT (Men) 15th  Gothenburg" : GameDates(153) = "20050807" : WhitePlayers(153) = "Agrest, Evgenij   G#153" : WhiteElos(153) = "2592" : BlackPlayers(153) = "Svidler, Peter   G#153" : BlackElos(153) = "2738" : Each_Game_Result(153) = "0-1"

FilePGNs(153) = "1. d4 g6 2. c4 Bg7 3. Nf3 Nf6 4. Nc3 O-O 5. Bg5 c5 6. d5 d6 7. e3 h6 8. Bh4 a6 9. Nd2 Nbd7 10. a4 Qb6 11. Ra3 Re8 12. Be2 e6 13. O-O exd5 14. cxd5 Ne5 15. Bg3 Qc7 16. h3 g5 17. f4 gxf4 18. exf4 Ng6 19. f5 Ne7 20. Bd3 Nexd5 21. Nxd5 Nxd5 22. Nc4 Qc6 23. f6 Nxf6 24. Nxd6 Be6 25. Nxe8 Rxe8 26. Bh4 Bd5 27. Bc2  Ne4 28. Raf3 Ng5  29. Rg3 Re5  30. Bxg5 hxg5 31. Qh5 Qh6 32. Qg4 c4 33. Qc8+ Bf8 34. Qd8  Kg7 35. a5 Be7 36. Qc8 Qe6 37. Qxe6 Bxe6 38. b3  Rxa5 39. bxc4 Bxc4 40. Bd3 Be6 41. Be4 b5 42. Rb1 b4 43. Bc2 Ra2 44. Bb3 Ra3 45. Kf2 a5 46. Rf3 Rxb3 47. Rfxb3 Bxb3 48. Rxb3 a4 49. Rb1 a3 0-1 "

; sample game 154
EventSites(154) = "EU-chT (Men) 15th  Gothenburg" : GameDates(154) = "20050807" : WhitePlayers(154) = "Berg, Emanuel   G#154" : WhiteElos(154) = "2539" : BlackPlayers(154) = "Bareev, Evgeny   G#154" : BlackElos(154) = "2688" : Each_Game_Result(154) = "1-0"

FilePGNs(154) = "1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. Bg5 dxe4 5. Nxe4 Be7 6. Bxf6 Bxf6 7. Nf3 O-O 8. Qd2 Be7 9. Bd3 Nd7 10. O-O-O b6 11. h4 Bb7 12. Qe2  c5 13. dxc5 Qc7 14. Neg5  Nf6 15. Ne5  h6 16. Bg6  hxg5 17. hxg5 fxg6 18. Nxg6  Ne4  19. Rh8+ Kf7 20. Ne5+  Qxe5 21. Qh5+ g6 22. Rh7+ Qg7 23. Rxg7+ Kxg7 24. Qh6+ Kf7 25. Qh7+ Ke8 26. Qxg6+ Rf7 27. c6  Bxc6 28. Qxe6 Bb7 29. g6  Rg7 30. Rh1  Nf6 31. Rh8+ Rg8 32. g7  1-0 "

; sample game 155
EventSites(155) = "EU-Cup 21st  Saint Vincent" : GameDates(155) = "20050920" : WhitePlayers(155) = "Kharlov, Andrei   G#155" : WhiteElos(155) = "2619" : BlackPlayers(155) = "Tyomkin, Dimitri   G#155" : BlackElos(155) = "2467" : Each_Game_Result(155) = "1-0"

FilePGNs(155) = "1. e4 c5 2. f4 d5 3. exd5 Nf6 4. Bb5+ Bd7 5. Bxd7+ Qxd7 6. c4 e6 7. dxe6 Qxe6+ 8. Qe2 Nc6 9. Qxe6+ fxe6 10. Na3 Nb4 11. Nh3 Nd3+ 12. Ke2 O-O-O 13. Nc2 e5 14. fxe5 Nxe5 15. b3 Bd6 16. Bb2 Rhe8 17. Ne3 Nfg4 18. g3 Nxe3 19. dxe3 Ng4 20. Kf3  Nxe3   21. Rhe1 Nf5  22. Rxe8 Rxe8 23. Rd1  Rf8 24. Ke4  g6 25. Rd5  Kd7  26. Ng5 h6 27. Nf3 Ke6 28. Be5 Be7 29. g4 Nd6+ 30. Ke3 Nf7 31. Bf4 Rd8 32. Ne5   Nxe5 33. Rxe5+ Kf6 34. Rd5  Re8 35. Kf3 g5 36. Be3  Ke6 37. Bxc5 Rf8+ 38. Ke3 Rf4 39. Bxe7 Kxe7 40. h3 Rf1 41. Rb5 b6 42. c5 bxc5 43. Rxc5 Rh1 44. Ra5 Rxh3+ 45. Ke4 Kd6 46. Rxa7 Kc5 47. Rb7 Rh2 48. a4 Rf2 49. a5 Rf4+ 50. Ke5 Rxg4 51. a6 1-0 "

; sample game 156
EventSites(156) = "EU-Cup 21st  Saint Vincent" : GameDates(156) = "20050921" : WhitePlayers(156) = "Horvath, Gyula   G#156" : WhiteElos(156) = "2428" : BlackPlayers(156) = "Tyomkin, Dimitri   G#156" : BlackElos(156) = "2467" : Each_Game_Result(156) = "1/2-1/2"

FilePGNs(156) = "1. c4 Nf6 2. Nf3 g6 3. Nc3 d5 4. cxd5 Nxd5 5. Qa4+ Bd7 6. Qh4 Nf6 7. d4 Bg4 8. Bg5 Bxf3 9. gxf3 Bg7 10. O-O-O h6 11. Bxf6  Bxf6 12. Qe4 c6 13. e3 Nd7 14. Kb1   Qa5 15. Bh3 Nb6 16. f4 Nd5 17. Rc1 Nxc3+ 18. Rxc3 Qd5 19. Qxd5 cxd5 20. Bc8  Rb8  21. Rhc1  O-O 22. Rc7 Bh4  23. Bxb7 Bxf2 24. R1c3 e6 25. Ba6 g5 26. fxg5 hxg5 27. Rxa7 Kg7 28. h3 Rh8 29. Be2 Rxh3 30. Bg4 Rxe3  31. Rxe3 Bxe3 32. Bxe6 Rxb2+ 33. Kxb2 Bxd4+ 34. Kc2 Bxa7 35. Bxd5 f5 36. Kd1 Kf6 37. Ke2 g4 38. Kf1 f4 39. Kg2 Bb6 40. Bc6 Ba5 41. Kf2 Kf5 42. a4 Kg5 43. Bb7 Kh4 44. Kg2 Kh5 45. Kf2 Kg6 46. Bc6 Kf6 47. Bb7 Bb6+ 48. Kg2 Bc7 49. Kf2 Bd8 50. Bc6 Ke6 51. Bb7 Bh4+ 52. Ke2 Kd7 53. a5 Kc7 54. Be4 Kb8 55. Bf5 f3+ 56. Ke3 Bg5+ 57. Kf2 Bh4+ 58. Ke3 f2 59. Ke2 g3 60. Kf1 Bd8 61. a6 Ka7 62. Bd3 Bc7 63. Kg2 Bb8 64. Bf1 Kb6 65. Be2 Kc5 1/2-1/2 "

; sample game 157
EventSites(157) = "EU-Cup 21st  Saint Vincent" : GameDates(157) = "20050921" : WhitePlayers(157) = "Ribli, Zoltan   G#157" : WhiteElos(157) = "2591" : BlackPlayers(157) = "Thorfinnsson, Bjorn   G#157" : BlackElos(157) = "2328" : Each_Game_Result(157) = "1-0"

FilePGNs(157) = "1. Nf3 d5 2. g3 c6 3. Bg2 Nf6 4. O-O Bf5 5. b3 Nbd7 6. Bb2 Qc7 7. d3 e5 8. Nbd2 Bd6 9. e4  dxe4 10. dxe4 Bxe4  11. Nc4 Be7 12. Nfxe5 Bxg2 13. Kxg2 Rd8 14. Qf3 O-O 15. Rfe1  Rfe8 16. Rad1 Bf8  17. Rxd7  Rxd7 18. Ng4 Re6  19. Rxe6 fxe6 20. Bxf6 h5 21. Nge5 Rd5 22. Bg5 b5 23. Ng6 Qf7 24. Qxf7+ Kxf7 25. Nce5+ Ke8 26. Be3 1-0 "

; sample game 158
EventSites(158) = "EU-Cup 21st  Saint Vincent" : GameDates(158) = "20050922" : WhitePlayers(158) = "Tyomkin, Dimitri   G#158" : WhiteElos(158) = "2467" : BlackPlayers(158) = "Macieja, Bartlomiej   G#158" : BlackElos(158) = "2593" : Each_Game_Result(158) = "0-1"

FilePGNs(158) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 Qc7 6. Be2 a6 7. O-O Nf6 8. a4 Bb4 9. Bg5 h6  10. Bxf6 gxf6 11. Nxc6  bxc6 12. Qd4 Be7  13. Rad1 Rb8 14. b3 h5 15. Kh1 h4 16. f4 Bb7 17. Qe3 c5 18. Bf3 c4 19. Ne2 Ba8 20. Qc3 Rc8 21. Qd4 h3 22. g4 Rg8 23. b4  Bc6 24. a5  c3  25. Rd3 Bb5 26. Rxc3 Qxc3  27. Nxc3 Bxf1 28. Kg1 Rc4 29. Qe3 Bxb4 30. Kxf1  Rxc3 31. Qb6 Bxa5  32. Qb8+ Bd8 33. Bd1 a5 34. Qb5 Bc7  35. Qb2 Rc4 36. Bf3 Ke7 37. Qa3+ Bd6 38. Qxa5 Bxf4 39. Be2 Rxc2 40. Qa3+ Bd6 41. Qxh3 Rb8 42. Qb3 0-1 "

; sample game 159
EventSites(159) = "FIDE-Wch  San Luis" : GameDates(159) = "20051005" : WhitePlayers(159) = "Topalov, Veselin   G#159" : WhiteElos(159) = "2788" : BlackPlayers(159) = "Kasimdzhanov, Rustam   G#159" : BlackElos(159) = "2670" : Each_Game_Result(159) = "1-0"

FilePGNs(159) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. h3 Bb7 9. d3 d6 10. a3 Na5 11. Ba2 c5 12. Nbd2 Nc6 13. Nf1 Bc8  14. c3 Be6 15. Bxe6 fxe6 16. b4 Qd7  17. Qb3 Rfb8 18. N1h2  a5 19. Bd2 h6 20. Ng4 Nxg4  21. hxg4  axb4 22. axb4 cxb4 23. cxb4 Bf6 24. Rec1 Kf7  25. g3 Qb7 26. Kg2 Rxa1 27. Rxa1 Ra8 28. Rh1  Nd4  29. Nxd4 exd4 30. Bf4 d5  31. e5  Be7 32. Qd1  Bg5 33. Bxg5 hxg5 34. Rh5 Qe7 35. Qh1 Rf8 36. Rh7 Ke8 37. Qa1  Kf7 38. Qc1 Ke8 39. Qa1 Kf7 40. Qxd4  Kg8   41. Rh1 Qf7 42. Qe3 d4  43. Qe2 Qb7+  44. Qe4 Qxe4+ 45. dxe4 Rc8 46. Rb1 Rc3  47. Rb2  Kf7 48. Kf1 Rc1+ 49. Ke2 Rc3 50. Ra2 Rb3 51. Ra7+ Kf8 52. Rb7 Rxb4 53. Kd3 Rb2 54. f4 Rb3+  55. Kxd4 Rxg3 56. f5 Rxg4 57. f6 Rg1 58. Rxg7 b4   59. Kc5 b3 60. Rb7 Ra1 61. Rxb3 Ra5+ 62. Kd4 Ra4+ 63. Ke3 Ra5 64. Rb8+ Kf7 65. Rb7+ Kf8 66. Kd4 Ra4+ 67. Kc5 Ra5+ 68. Kd4 Ra4+ 69. Ke3 Ra3+ 70. Kf2  Ra5 71. Kg3 Rxe5 72. Kg4 Rxe4+ 73. Kh5  1-0 "

; sample game 160
EventSites(160) = "WchT 6th  Beersheba" : GameDates(160) = "20051101" : WhitePlayers(160) = "Roiz, Michael   G#160" : WhiteElos(160) = "2600" : BlackPlayers(160) = "Vaganian, Rafael A   G#160" : BlackElos(160) = "2614" : Each_Game_Result(160) = "1-0"

FilePGNs(160) = "1. e4 e6 2. d4 d5 3. Nd2 dxe4 4. Nxe4 Nd7 5. Nf3 Ngf6 6. Nxf6+ Nxf6 7. c3 c5 8. Be3 Qc7 9. Ne5 a6 10. Qa4+ Bd7 11. Nxd7 Nxd7 12. Be2 O-O-O 13. O-O Nb6 14. Qb3  c4  15. Qc2 Bd6 16. Kh1  h5 17. b3  Bxh2  18. bxc4 Bf4 19. Bxf4 Qxf4 20. Rab1  Na8 21. Bf3 Rd7 22. c5 h4 23. Qb3 Kd8 24. c4 Ke7 25. d5 e5 26. Qe3 1-0 "

; sample game 161
EventSites(161) = "WchT 6th  Beersheba" : GameDates(161) = "20051102" : WhitePlayers(161) = "Rublevsky, Sergei   G#161" : WhiteElos(161) = "2652" : BlackPlayers(161) = "Erenburg, Sergey   G#161" : BlackElos(161) = "2582" : Each_Game_Result(161) = "1/2-1/2"

FilePGNs(161) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Nd2 e6 5. Nb3 c5  6. dxc5 Bxc5 7. Nxc5 Qa5+ 8. c3 Qxc5 9. Nf3 Ne7 10. Qa4+  Nbc6 11. Be3 Qa5 12. Qxa5 Nxa5 13. Nd4 a6 14. Nxf5 Nxf5 15. Bf4  Ne7 16. O-O-O Rc8 17. h4 h5  18. Rh3 Nc4 19. b3  Ng6  20. bxc4 Nxf4 21. Rf3 Ng6 22. cxd5 Nxe5 23. Rg3 Ng4  24. dxe6 fxe6 25. Be2  O-O 26. Bxg4 1/2-1/2 "

; sample game 162
EventSites(162) = "WchT 6th  Beersheba" : GameDates(162) = "200511??" : WhitePlayers(162) = "Zhang Zhong   G#162" : WhiteElos(162) = "2598" : BlackPlayers(162) = "Roiz, Michael   G#162" : BlackElos(162) = "2600" : Each_Game_Result(162) = "1-0"

FilePGNs(162) = "1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. e5 Nfd7 5. f4 c5 6. Nf3 Nc6 7. Be3 a6 8. Qd2 b5 9. a3 g5  10. fxg5 cxd4 11. Nxd4  Ncxe5  12. Be2 Bb7 13. Bh5 Qe7 14. O-O Bg7 15. Nce2 O-O 16. b3 Rac8 17. Ng3 f5  18. gxf6 Nxf6 19. Bh6  Nfd7 20. Bxg7 Kxg7 21. Be2 Kg8 22. Qh6 Rf6 23. Rxf6 Qxf6 24. Qxf6 Nxf6 25. Rf1 Ned7 26. Nxe6 Rxc2 27. Nd4 Rd2  28. Ngf5 Nc5 29. b4 Nce4 30. Rc1  Ne8 31. Bh5 Ng7  32. Bf3 Nxf5 33. Nxf5  Ra2 34. h4 Kf7 35. Rc7+  Kf6 36. Ne3 Nd6 37. Rxh7 Rxa3 38. Ng4+ Ke6 39. Rh6+ Ke7 40. Ne5  a5 41. Rh7+ Ke6 42. Nd7 axb4  43. Bg4+ Nf5 44. Nc5+ Kf6 45. Rxb7  Nxh4 46. Rxb5 Rc3 47. Nd7+ Ke7 48. Nb6 Kd6 49. Rxb4 Rc1+ 50. Kh2 Rc2 51. Bh3 Nf3+ 52. Kg3 Ne5 53. Rd4 Rc3+ 54. Kh2 Rc5 55. Nc8+ Kc6 56. Ne7+ Kd6 57. Nf5+ Kc6 58. Rd1 Ng6 59. Bg4 Ne5 60. Bf3 1-0 "

; sample game 163
EventSites(163) = "WchT 6th  Beersheba" : GameDates(163) = "20051107" : WhitePlayers(163) = "Aronian, Levon   G#163" : WhiteElos(163) = "2724" : BlackPlayers(163) = "Svidler, Peter   G#163" : BlackElos(163) = "2740" : Each_Game_Result(163) = "1/2-1/2"

FilePGNs(163) = "1. d4 Nf6 2. c4 g6 3. Nf3 Bg7 4. g3 c6 5. Nc3 d5 6. Qb3 O-O 7. Bg2 Qb6 8. O-O Rd8 9. c5 Qxb3 10. axb3 Na6 11. Bf4 Nd7 12. Rfd1 e5  13. Nxe5 Nxe5 14. Bxe5 Bxe5 15. dxe5 Bf5 16. Ra5 Bc2 17. Rd4 Bxb3 18. f4  Bc4 19. e4 Nb4  20. exd5 cxd5 21. Rd2 a6 22. Ra4  a5 23. Ra3 Kg7 24. Na4 Rac8 25. Nb6 Rxc5 26. Rc3 Nc6 27. b3 Rb5 28. Nxc4 Rc5 29. Rcd3 dxc4 30. Rxd8 Nxd8 31. bxc4 Ne6 32. Bd5 Nc7 33. Bxb7 Rxc4 34. Ra2 a4 35. Kf2 f6 1/2-1/2 "

; sample game 164
EventSites(164) = "FIDE World Cup  Khanty Mansiysk" : GameDates(164) = "20051127" : WhitePlayers(164) = "Belkhodja, Slim   G#164" : WhiteElos(164) = "2490" : BlackPlayers(164) = "Tiviakov, Sergei   G#164" : BlackElos(164) = "2700" : Each_Game_Result(164) = "0-1"

FilePGNs(164) = "1. e4 c5 2. Nf3 Nc6 3. Bb5 d6 4. O-O Bd7 5. Re1 Nf6 6. h3  g6 7. c3 Ne5 8. Bxd7+ Nfxd7 9. Nxe5 dxe5 10. Qe2  Bg7 11. a4 O-O 12. Na3 Qc7 13. d3 Rfd8 14. Be3 Nf8  15. Red1 Ne6 16. Rac1  Qd7 17. b3 h5  18. Nc4 h4 19. Qb2 b6  20. b4  Qxa4 21. b5 Nc7 22. Rb1 Rac8 23. Bg5  Rd7 24. Ne3 Rcd8 25. Nd5  Nxd5 26. exd5 c4  27. Ra1 Qb3 28. Qxb3 cxb3 29. c4 e4   30. Rab1 b2 31. d4 Rc8 32. Rxb2 Rxc4 33. Kf1 Bxd4 34. Rbd2 Bc5 0-1 "

; sample game 165
EventSites(165) = "FIDE World Cup  Khanty Mansiysk" : GameDates(165) = "20051127" : WhitePlayers(165) = "Milov, Vadim   G#165" : WhiteElos(165) = "2652" : BlackPlayers(165) = "Pantsulaia, Levan   G#165" : BlackElos(165) = "2578" : Each_Game_Result(165) = "0-1"

FilePGNs(165) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. f3 d5 5. a3 Bxc3+ 6. bxc3 c5 7. cxd5 Nxd5 8. dxc5 f5 9. Qc2 O-O 10. e4 fxe4 11. fxe4 Nf4 12. Be3 Qc7 13. Qd2 Nd7 14. Qd6 Qa5 15. Rc1 e5 16. Nf3 Rf6 17. Qe7 Qa4  18. Nd2  Rf7 19. Qd8+ Rf8 20. Qc7 Kh8 21. g3 Ne6  22. Qd6 Nf6 23. Qd3  Ng4 24. Bg1 Qxa3 25. Rb1 Rd8 26. Qc4  Ng5 27. Qb3 Qa5 28. Be2  Nh3  29. Nc4 Qc7 30. Nd6 Rf8 31. Qd5  Nxg1 32. Rxg1 Be6  33. Rxb7  Qa5 34. Qd2 Qxc5 35. Rf1 Rfd8 36. Bxg4 Rxd6 37. Qg5 Qxc3+ 38. Kf2 Rf8+ 39. Kg2 Qc2+ 40. Kg1 Qc5+ 41. Kg2 Qc2+ 42. Kg1 Rxf1+ 43. Kxf1 Bc4+ 0-1 "

; sample game 166
EventSites(166) = "FIDE World Cup  Khanty Mansiysk" : GameDates(166) = "20051128" : WhitePlayers(166) = "Gurevich, Mikhail   G#166" : WhiteElos(166) = "2652" : BlackPlayers(166) = "Markus, Robert   G#166" : BlackElos(166) = "2579" : Each_Game_Result(166) = "1/2-1/2"

FilePGNs(166) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 O-O 5. Bd3 c5 6. a3  cxd4  7. axb4 dxc3 8. bxc3 d6 9. Nf3 e5 10. e4 Be6   11. Bg5 Nbd7 12. Nd2 h6 13. Bh4  Qc7 14. Ra5 b6 15. Ra3 a5 16. O-O axb4 17. Rxa8 Rxa8 18. cxb4 Ra2  19. Nb1  Rb2  20. Qe1 Qa7 21. Qc3 Qa2 22. Rd1 Bg4 23. Re1 Be2 24. Bxe2 Rxe2 25. Rxe2 Qxe2 26. f3 Qd1+ 27. Qe1 Qd4+ 28. Bf2 Qxc4 29. Qc3 Qe2  30. Qb3  g5 31. Na3 g4  32. Nc4 d5 33. Nd6  Qd2 34. h3 gxh3 35. gxh3 Kg7  36. Nf5+ Kh7 37. Ne3  Kg6 38. exd5 e4 39. fxe4  Nxe4 40. Qc2 Qxc2  41. Nxc2 Nc3 42. Ne3 f5 43. d6 Ne4 44. Nd5 b5 45. Nc7 Nxd6 46. Bg3 Ne4 47. Be1 Nd6 48. Bg3 Ne4 49. Be1 Nd6 1/2-1/2 "

; sample game 167
EventSites(167) = "FIDE World Cup  Khanty Mansiysk" : GameDates(167) = "20051128" : WhitePlayers(167) = "Pantsulaia, Levan   G#167" : WhiteElos(167) = "2578" : BlackPlayers(167) = "Milov, Vadim   G#167" : BlackElos(167) = "2652" : Each_Game_Result(167) = "1/2-1/2"

FilePGNs(167) = "1. d4 g6 2. Nf3 Bg7 3. c4 c5 4. e4 Nc6 5. dxc5 Qa5+ 6. Bd2 Qxc5 7. Nc3 Nf6 8. Be2 O-O 9. O-O Ne5 10. Rc1 d6 11. Be3  Nxf3+ 12. Bxf3 Qa5 13. Qd2 Rd8 14. Rfd1 Be6 15. b3 Rac8 16. Nd5  Qxd2 17. Bxd2 Kf8 18. Bg5 Ng8  19. a4 Bh6  20. Bxh6+ Nxh6 21. Nc3 f6 22. Be2 Nf7 23. f4 Re8 24. Bf3 Rc5 25. Nb5 a5 26. Nd4 Bd7 27. Nc2 Rec8 28. Ne1 R5c7 29. Nd3 e5 30. fxe5 dxe5 31. Nc5 Rd8 32. Rd5 b6 33. Nxd7+ Rdxd7 34. Rb5 Rd6 35. c5  Rdc6 36. Kf2 bxc5 37. Rxa5 Nd6 38. Ra8+ Ke7 39. Rb8 Ra7 40. Ke3 c4 41. Rc3 Rcc7 42. Be2 cxb3 43. Rxc7+ Rxc7 44. Rxb3 Rc5 45. g4 g5 46. Bd3 Kd7 47. Rb8 Rc3 48. Rh8 Ra3 49. Rxh7+ Kc6 50. Rh6 Kc5 51. Rxf6 Nc4+ 52. Ke2 Ra2+ 53. Kf3 Ra3 54. Ke2 Nb2 55. Bb5 Nxa4 56. Bxa4 Rxa4 57. Rf5 Kd4 58. Rxg5 Kxe4 59. h4 Ra2+ 60. Kf1 Ra5  61. Rf5 Kd3 1/2-1/2 "

; sample game 168
EventSites(168) = "FIDE World Cup  Khanty Mansiysk" : GameDates(168) = "20051130" : WhitePlayers(168) = "Cheparinov, Ivan   G#168" : WhiteElos(168) = "2618" : BlackPlayers(168) = "Ivanchuk, Vassily   G#168" : BlackElos(168) = "2748" : Each_Game_Result(168) = "1-0"

FilePGNs(168) = "1. d4 Nf6 2. c4 c5 3. d5 b5 4. cxb5 a6 5. b6 d6 6. Nc3 Nbd7 7. a4 a5 8. e4 g6 9. Nf3 Bg7 10. Be2 O-O 11. O-O Qxb6 12. Nd2 Ba6 13. Nb5  Rfb8  14. Qc2 Qd8 15. Nc4 Nb6 16. Nca3  Ne8 17. Rb1 Nc7 18. b3  Bxb5  19. Nxb5 Na6 20. Bg5 Nb4 21. Qd2 Qd7 22. f4 Rb7 23. f5   Qe8 24. Rf3 Nd7 25. Rbf1 Be5 26. Rh3 f6 27. Be3 g5  28. g4 Rc8 29. Bc4 Bd4  30. Nxd4 cxd4 31. Bxg5  Ne5 32. Bh6 d3 33. g5 Qf7 34. Rg3 Kh8 35. g6   hxg6 36. fxg6 Nxg6 37. Rf5 Ne5 38. Bf8 Qh7 39. Bg7+ Qxg7 40. Rh5+ Kg8 41. Rxg7+ Kxg7 42. Qh6+ Kf7 43. Qh7+ Ke8 44. Qf5 1-0 "

; sample game 169
EventSites(169) = "FIDE World Cup  Khanty Mansiysk" : GameDates(169) = "20051201" : WhitePlayers(169) = "Shulman, Yuri   G#169" : WhiteElos(169) = "2565" : BlackPlayers(169) = "Khalifman, Alexander   G#169" : BlackElos(169) = "2653" : Each_Game_Result(169) = "1-0"

FilePGNs(169) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 c5 5. Ne2 cxd4 6. exd4 O-O 7. a3 Be7 8. d5 exd5 9. cxd5 Bc5 10. Na4 b6 11. b4 Bd6 12. Nec3 Be5 13. Be2 Ba6 14. Ra2 Qc7   15. Rc2 Bxc3+  16. Nxc3 Bxe2 17. Nxe2  Qe5 18. O-O Qxd5 19. Rd2 Qf5 20. Ng3 Qg6 21. Rd6  Nc6 22. Bb2 Rae8 23. Bxf6 gxf6 24. Nh5 Re6 25. Rxd7 Re5 26. Nf4 Qf5 27. Nd5  Kh8  28. Ne3  Qe4 29. Qd6 Kg7 30. Rc1 Re6 31. Qd1 Kh8  32. Rc4 Qe5 33. Rd5 Qb2 34. Rh4 Ne5  35. Rd2 Qc3 36. Qh5 1-0 "

; sample game 170
EventSites(170) = "FIDE World Cup  Khanty Mansiysk" : GameDates(170) = "20051202" : WhitePlayers(170) = "Motylev, Alexander   G#170" : WhiteElos(170) = "2632" : BlackPlayers(170) = "Ponomariov, Ruslan   G#170" : BlackElos(170) = "2704" : Each_Game_Result(170) = "0-1"

FilePGNs(170) = "1. e4 e6 2. d4 d5 3. e5 c5 4. c3 Nc6 5. Nf3 Qb6 6. a3 Nh6 7. b4 cxd4 8. cxd4 Nf5 9. Bb2 Bd7 10. g4 Nfe7 11. Nc3 Na5 12. Nd2 Rc8 13. Rc1 Ng6 14. Qe2  Be7 15. Qe3 O-O 16. h4 f6 17. h5 Nh8 18. Rc2 Nc6 19. Na4 Qd8 20. exf6 Bxf6 21. Nc5 e5  22. Nxb7  exd4  23. Qf3 Qe7+ 24. Kd1 Ne5 25. Qxd5+ Be6  26. Qd6 Bxg4+ 27. f3 Qxb7  28. fxg4 Rxc2 29. Kxc2 Nhf7 30. Qe6 Qxh1 31. Bxd4 Qc6+ 32. Qxc6 Nxc6 33. Bc5 Rd8 34. Ne4 Bd4 35. Bc4 Bxc5 36. Nxc5 Rd4 37. Be6 Kf8 38. Kc3 Rd6 0-1 "

; sample game 171
EventSites(171) = "FIDE World Cup  Khanty Mansiysk" : GameDates(171) = "20051202" : WhitePlayers(171) = "Shulman, Yuri   G#171" : WhiteElos(171) = "2565" : BlackPlayers(171) = "Khalifman, Alexander   G#171" : BlackElos(171) = "2653" : Each_Game_Result(171) = "1-0"

FilePGNs(171) = "1. d4 Nf6 2. c4 c5 3. d5 b5 4. cxb5 a6 5. bxa6 g6 6. Nc3 Bxa6 7. e4 Bxf1 8. Kxf1 d6 9. Nge2 Bg7 10. h3 O-O 11. Kg1 Nbd7 12. Kh2 Qa5 13. Qc2 Nb6  14. Rd1 Na4 15. Bd2 Nxc3 16. Nxc3 Rfb8 17. Re1 Nd7 18. b3 Qa6 19. Rab1 Ne5 20. Re3 c4 21. Kg1   cxb3 22. axb3 Rc8 23. Qd1 Rab8 24. Ne2 Qb6 25. Bc3 Nc4 26. Rd3 Ne5 27. Rg3  h5 28. Bd4 Qb4 29. Rc1 Rxc1 30. Qxc1 Nf3+ 31. Rxf3 Bxd4 32. Nxd4 Qxd4 33. Qf4  Rf8 34. Kh2 Kg7 35. g3 f6 36. Qe3 Qd1 37. Qd3 Qe1 38. Kg2 Ra8 39. Re3 Qc1 40. Qc3  Ra1 41. Qxc1 Rxc1 42. Rd3 Rb1 43. Rc3 f5  44. exf5 gxf5 45. Rd3 Kf6 46. f4 Rb2+ 47. Kf3 h4  48. gxh4 Kg6 49. Ke3 Kh5 50. Kd4 Rf2 51. b4 Rxf4+ 52. Kc3 Rf1 53. b5   f4   54. Kc2  Ra1 55. b6 Ra8 56. Rb3 Kxh4 57. Kd2   Rb8 58. Ke2 Rb7 59. Kf3 Kg5 60. Ke4  f3 61. Kxf3 Kf5 62. Ke3 Ke5 63. Rb5 e6 64. dxe6+ Kxe6 65. Kd4 Kd7 66. Kd5 Kc8 67. Kc6 d5 68. Ra5 1-0 "

; sample game 172
EventSites(172) = "FIDE World Cup  Khanty Mansiysk" : GameDates(172) = "20051204" : WhitePlayers(172) = "Rublevsky, Sergei   G#172" : WhiteElos(172) = "2652" : BlackPlayers(172) = "Jobava, Baadur   G#172" : BlackElos(172) = "2601" : Each_Game_Result(172) = "1-0"

FilePGNs(172) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Nf3 e6 5. Be2 Ne7 6. O-O Bg6 7. Nbd2 c5 8. dxc5 Nec6 9. Nb3 Nd7 10. c4  dxc4 11. Bxc4 a6 12. Be3 Ndxe5 13. Nxe5 Nxe5 14. Be2 Be7 15. Qxd8+ Bxd8 16. Rfd1 O-O 17. Nd4 Bf6 18. Rac1 Be4 19. b4 Nc6 20. Nxc6 bxc6 21. Bf4 Bb2 22. Rc4  Bd5 23. Rc2 Ba3  24. Rd4  f6 25. Bc7 e5 26. Rh4 Rf7 27. Bb6 Rb7 28. Rh3  Bxb4 29. a3 Be4 30. Rc4 Bxc5 31. Bxc5 Rb1+ 32. Bf1 Rd8 33. Rxe4 Rdd1 34. g4  Rxf1+ 35. Kg2 Rg1+ 36. Kf3 Rb5 37. Be3 Ra5 38. Rb4 h6 39. a4 Ra1 40. Rb8+ Kh7 41. Rb7 Kg6 42. Rh5  R5xa4 43. h3 Rh1  44. Bc5  e4+  45. Kg3  f5 46. Rxf5 Ra5 47. Bd4 1-0 "

; sample game 173
EventSites(173) = "FIDE World Cup  Khanty Mansiysk" : GameDates(173) = "20051204" : WhitePlayers(173) = "Kamsky, Gata   G#173" : WhiteElos(173) = "2690" : BlackPlayers(173) = "Smirin, Ilia   G#173" : BlackElos(173) = "2673" : Each_Game_Result(173) = "1-0"

FilePGNs(173) = "1. d4 Nf6 2. Nf3 g6 3. Bf4 Bg7 4. e3 d6 5. h3 O-O 6. Be2 b6 7. c4 Nbd7 8. Nc3 Bb7 9. O-O Ne4 10. Nxe4 Bxe4 11. Bh2 e5 12. Qd2 Qe7 13. Rfd1 Rfd8 14. Rac1 a5 15. Qe1 Bb7 16. Qd2 e4  17. Ne1 f5 18. Nc2 g5 19. Na3 Rf8  20. Nb5 Nf6  21. c5  dxc5 22. dxc5  Rad8 23. Bc4+ Kh8 24. Qe2 Rxd1+ 25. Rxd1 f4 26. exf4 Qxc5 27. f5  Nd5 28. Bxd5 Bxd5 29. Nxc7 Rxf5 30. b3 Bg8 31. Ne8 Bd4 32. Bg3 Rd5 33. Nc7 Rf5 34. Nb5 Be5 35. Nd6 Rf8 36. Nxe4  Qc7 37. Rd7 Qc1+ 38. Kh2 Bxg3+ 39. Nxg3 Qc3 40. f3 Qf6 41. Qe3 Qf4 42. Qxf4 gxf4 43. Ne2 a4 44. bxa4 Bc4 45. Nc3 Rg8 46. Rd2 Rc8 47. Rd4 Bf1 48. Ne4 Rc2 49. Nd2 Ba6 50. a3 Ra2 51. Nc4 Rc2 52. Nd2 Ra2 53. Kg1 Ra1+ 54. Kh2 Ra2 55. Rd6 Rxa3 56. Rxb6 Rxa4 57. Ne4 Ra2 58. Nc3 Ra5 59. Rf6 Ra3 60. Ne4 Bf1 61. Rxf4 Ra2 62. Rg4 Bd3 63. Nf6 Bg6 64. h4 Kg7 65. Nd5 Kh6 66. Rd4 Rb2 67. Kh3 Rf2 68. Nf4 Bf5+ 69. Kg3 Ra2 70. Rd5 Bc8 71. Rc5 Bb7 72. Rb5 Ba6 73. Rb6+ Kg7 74. h5 Bf1 75. h6+ Kf7 76. Rb7+ Kg8 77. Rg7+ Kh8 78. Re7 Ra8 79. Kf2 Bc4 80. Rc7 Bg8 81. g4 Ra2+ 82. Kg3 Ra3 83. g5 Ra5 84. g6 1-0 "

; sample game 174
EventSites(174) = "FIDE World Cup  Khanty Mansiysk" : GameDates(174) = "20051206" : WhitePlayers(174) = "Grischuk, Alexander   G#174" : WhiteElos(174) = "2720" : BlackPlayers(174) = "Kamsky, Gata   G#174" : BlackElos(174) = "2690" : Each_Game_Result(174) = "1-0"

FilePGNs(174) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. h3 Bb7 9. d3 d6 10. a3 h6 11. Nc3 Re8 12. Nd5 Nxd5 13. Bxd5 Qc8 14. c3 Nd8 15. d4  Bf6 16. Nh2 exd4 17. Ng4  Bg5 18. cxd4 Bxd5 19. exd5 Rxe1+ 20. Qxe1 Kf8 21. Bxg5 hxg5 22. Qe3 f6 23. Re1 Qd7 24. h4  Nf7 25. Qe6 Rd8 26. h5 f5  27. Nf6  gxf6 28. Qxf6 Re8 29. Re6 Qd8 30. Qxf5 g4 31. Rf6 Re7 32. h6 Qd7 33. Qg6 1-0 "

; sample game 175
EventSites(175) = "FIDE World Cup 9-16  Khanty Mansiysk" : GameDates(175) = "20051209" : WhitePlayers(175) = "Vallejo Pons, Francisco   G#175" : WhiteElos(175) = "2674" : BlackPlayers(175) = "Van Wely, Loek   G#175" : BlackElos(175) = "2648" : Each_Game_Result(175) = "1/2-1/2"

FilePGNs(175) = "1. c4 Nf6 2. Nc3 c5 3. g3 e6 4. Nf3 b6 5. Bg2 Bb7 6. O-O Be7 7. Re1 d5 8. cxd5 Nxd5 9. e4 Nb4 10. d4 cxd4 11. Nxd4 N8c6 12. Nxc6 Qxd1 13. Rxd1 Bxc6  14. a3 Nc2 15. Rb1  O-O 16. Bf4 Rfd8 17. Rbc1 Nd4 18. Be3 Nb3  19. Rb1 Bf6 20. f3 Rac8 21. Kf2 Kf8 22. Bf1 Bb7 23. Rxd8+ Rxd8 24. Rd1 Rxd1 25. Nxd1 Ke7 1/2-1/2 "

; sample game 176
EventSites(176) = "Corus  Wijk aan Zee" : GameDates(176) = "20060124" : WhitePlayers(176) = "Karjakin, Sergey   G#176" : WhiteElos(176) = "2660" : BlackPlayers(176) = "Topalov, Veselin   G#176" : BlackElos(176) = "2801" : Each_Game_Result(176) = "0-1"

FilePGNs(176) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5 6. Ndb5 d6 7. Bg5 a6 8. Na3 b5 9. Nd5 Be7 10. Bxf6 Bxf6 11. c3 Bg5 12. Nc2 O-O 13. a4 bxa4 14. Rxa4 a5 15. Bc4 Rb8 16. Ra2 Kh8 17. Nce3 Bxe3 18. Nxe3 Ne7 19. b3   f5 20. exf5 Nxf5 21. Nd5 Bb7 22. O-O Rc8 23. Qd3 Nh4 24. Rd1 h6 25. Qg3 Nf5 26. Qg4 Rc5 27. Rad2 Bc8 28. Qe4 Bb7 29. h3  Nh4 30. Bd3  Rf5  31. Bb1  Rxc3  32. Qg4 h5 33. Qe2 Qg5  34. f4 Rxf4 35. Kh1 Nxg2 36. Qxg2 Rg3 37. Nxf4 Bxg2+ 38. Nxg2 Rxh3+ 39. Kg1 Rg3 40. Rf2 Kg8 41. Rxd6 h4 42. Rc6 Qg4 43. Bf5 Rxg2+  44. Rxg2 Qxf5 45. Rcg6 Qf7 46. R6g4 Qf6 47. Kh2 Kf7 48. Kh3 e4 49. Rg5 e3 50. Kxh4 g6 0-1 "

; sample game 177
EventSites(177) = "Moscow Aeroflot op-A  Moscow" : GameDates(177) = "20060209" : WhitePlayers(177) = "Bologan, Viktor   G#177" : WhiteElos(177) = "2661" : BlackPlayers(177) = "Tomashevsky, Evgeny   G#177" : BlackElos(177) = "2586" : Each_Game_Result(177) = "1-0"

FilePGNs(177) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. d3 h6 5. O-O d6 6. c3 g6 7. d4 Qe7 8. Re1 Bg7 9. Nbd2 O-O 10. h3 Bd7 11. Nf1 Rae8 12. Ng3 Qd8 13. Bb3 a6  14. Bc2 Nh7 15. Be3 h5  16. Qd2 Qf6 17. Kh2 Bc8 18. Rad1 Kh8 19. Ne2 Qe7 20. Ng5 Nxg5 21. Bxg5 f6 22. Be3 f5 23. Bg5 Bf6 24. Bxf6+ Rxf6 25. f4  Qg7 26. fxe5 dxe5 27. exf5 Bxf5 28. Bxf5 Rxf5 29. Ng3 Rff8 30. d5 Nd8 31. Ne4 Rf4 32. Qe3 Ref8 33. Nc5  e4  34. Nxe4  Qe5 35. g3 R4f7 36. Kg2 Kg7 37. Qd2 c6 38. c4 cxd5 39. cxd5 h4 40. gxh4 Qh5 41. Qc3+ Kg8 42. Qg3 Rf4 43. Rd2 1-0 "

; sample game 178
EventSites(178) = "Moscow Aeroflot op-A  Moscow" : GameDates(178) = "20060215" : WhitePlayers(178) = "Efimenko, Zahar   G#178" : WhiteElos(178) = "2666" : BlackPlayers(178) = "Huzman, Alexander   G#178" : BlackElos(178) = "2573" : Each_Game_Result(178) = "1-0"

FilePGNs(178) = "1. e4 e5 2. Bc4 Nf6 3. d3 c6 4. Nf3 d5 5. Bb3 Bd6 6. exd5 Nxd5 7. O-O O-O 8. Re1 Re8 9. Nbd2 Bc7 10. Ne4 Bf5 11. Bg5  f6 12. Bd2 Nd7 13. Nh4 Be6 14. Qh5 a5 15. a3 Nf4 16. Bxe6+ Nxe6 17. Re3  Nf4 18. Qg4 Nf8 19. g3 N4e6 20. Nf5 Kh8 21. Rf3 Qd7 22. c3 Red8 23. h4 Qf7 24. h5 Rd7 25. Nh4 Rad8 26. h6 Rxd3 27. Be3 Nd7 28. hxg7+ Nxg7 29. Kg2 h5 30. Qg6 Qxg6 31. Nxg6+ Kh7 32. Nh4 Rf8 33. Rh1 Bd8 34. Nf5  Nxf5 35. Rxf5 Kg6 36. Rfxh5 Rg8 37. Rh7 Rg7 38. Rh8 Be7 39. g4 Kf7 40. Kf3 Nf8 41. Ng3 Rd7 42. Nf5 Rg6 43. b4 axb4 44. axb4 Rd8  45. R8h7+  1-0 "

; sample game 179
EventSites(179) = "Morelia/Linares 23rd  Morelia/Linares" : GameDates(179) = "20060219" : WhitePlayers(179) = "Ivanchuk, Vassily   G#179" : WhiteElos(179) = "2729" : BlackPlayers(179) = "Aronian, Levon   G#179" : BlackElos(179) = "2752" : Each_Game_Result(179) = "1-0"

FilePGNs(179) = "1. Nf3 Nf6 2. c4 b6 3. g3 Bb7 4. Bg2 c5 5. O-O g6 6. Nc3 Bg7 7. d4 cxd4 8. Qxd4 d6 9. Be3 Nbd7 10. Rac1 Rc8 11. b3 a6 12. Rfd1 O-O 13. Qd2 Ne4  14. Nxe4 Bxe4 15. Ne1 Nf6  16. Bh3  Rb8 17. Nd3 Ba8 18. f3   e6 19. Bf2 Re8  20. Nb4  a5 21. Na6 Rc8 22. Qxd6 Qxd6 23. Rxd6  Nd5 24. Rd1  Nc3 25. R1d2 b5 26. Rd7 Be5 27. cxb5 Nxb5 28. Bf1 Bc6 29. R7d3 Na3 30. f4 Bf6 31. Nc5 Be7 32. Rd1 Nb5 33. Na4  Be4 34. Rd7 Bb4 35. Bg2  Bxg2 36. Kxg2 Rc2 37. Rb7 Na3 38. Rdd7 Rf8 39. Kf3 Nb1 40. Be3 Rxa2 41. Bc5 Nd2+ 42. Kg2 Bxc5 43. Nxc5 e5  44. Ne6  exf4 45. Rxf7  1-0 "

; sample game 180
EventSites(180) = "Morelia/Linares 23rd  Morelia/Linares" : GameDates(180) = "20060219" : WhitePlayers(180) = "Leko, Peter   G#180" : WhiteElos(180) = "2740" : BlackPlayers(180) = "Radjabov, Teimour   G#180" : BlackElos(180) = "2700" : Each_Game_Result(180) = "1-0"

FilePGNs(180) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5 6. Ndb5 d6 7. Bg5 a6 8. Na3 b5 9. Nd5 Be7 10. Bxf6 Bxf6 11. c3 O-O 12. Nc2 Bg5 13. a4 bxa4 14. Rxa4 a5 15. Bc4 Rb8 16. b3 Kh8 17. Nce3 Be6 18. h4  Bf4  19. Nf5  g6 20. Nfe3 Kg7 21. g3 Bh6 22. Ng4 f5 23. Nxh6 Kxh6 24. h5  g5 25. exf5 Bxf5 26. Ne3 Bc8 27. Ra2  Ne7 28. O-O Rf6 29. Qe2 Qb6 30. Rfa1 Qc6 31. Rxa5 Bb7 32. Bd5 Nxd5 33. Rxd5  Qxc3 34. Ng4+ Kg7 35. Ra7 Re6 36. Qc4   Qe1+ 37. Kg2 Re7 38. Rxb7  Rexb7 39. Rxd6 Rf8 40. h6+ Kh8 41. Qd5 Rbb8 42. Qd3 Qb4 43. Rd7 e4 44. Qd5 Rb5 45. Nf6 1-0 "

; sample game 181
EventSites(181) = "USA-ch GpB  San Diego" : GameDates(181) = "20060302" : WhitePlayers(181) = "Kaidanov, Gregory S   G#181" : WhiteElos(181) = "2603" : BlackPlayers(181) = "Kriventsov, Stanislav G   G#181" : BlackElos(181) = "2449" : Each_Game_Result(181) = "1/2-1/2"

FilePGNs(181) = "1. Nf3 d5 2. d4 Nf6 3. c4 dxc4 4. Nc3 c5 5. d5 e6 6. e4 exd5 7. e5 d4  8. Bxc4 dxc3 9. Bxf7+ Ke7 10. exf6+ gxf6 11. Qb3 Qb6 12. O-O Qxb3 13. Bxb3 Bg4 14. Re1+ Kd8 15. Ng5 fxg5 16. Bxg5+ Kc7 17. Bf6 cxb2 18. Bxb2 Bd6 19. Bxh8 Nc6 20. Bb2 Rf8 21. f3  Bf5 22. Rad1 b5 23. Be6 Bg6 24. Bd5 Nb4 25. a3  Nd3  26. Re2 c4 27. Bg7 Rd8 28. Be4 Bxe4 29. Rxe4 Bxa3 30. Kf1 Bc5 31. Rb1 Kc6 32. Rh4 Rd7 33. Rh6+ Kd5 34. Rh5+ 1/2-1/2 "

; sample game 182
EventSites(182) = "USA-ch GpB  San Diego" : GameDates(182) = "20060306" : WhitePlayers(182) = "Milman, Lev   G#182" : WhiteElos(182) = "2478" : BlackPlayers(182) = "Kaidanov, Gregory S   G#182" : BlackElos(182) = "2603" : Each_Game_Result(182) = "1/2-1/2"

FilePGNs(182) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Bxc6 dxc6 5. O-O f6 6. d4 Bg4 7. c3 Bd6 8. Be3 Qe7 9. Nbd2 O-O-O 10. Qc2 exd4 11. cxd4 Re8 12. e5  fxe5 13. dxe5 Bxe5 14. Rfe1 Bf6 15. Bd4 Qf8  16. Rxe8+ Qxe8 17. Re1 Qf8 18. Qc4 Nh6 19. Be3 Bxf3 20. Nxf3 Qd6 21. Bxh6 gxh6 22. b3 Qd5 23. Qf4 Bc3 24. Rc1 Bg7 25. Re1 Rf8 26. Qg4+ Qd7 27. Qh5 b6 28. h3 a5 29. Ne5 Qe6 30. Nf3 Qd7 31. Ne5 Qe6 32. Re3 Kb7 33. Qe2 Qf5 34. Nf3 Rd8 35. Re7 Bf8 36. Re4 Bc5 37. g4 Qf7 38. Re6 Rd6 39. Re5 Rd5 40. Kg2 Bd6 41. Re6 h5 42. g5 Bf4 43. Qe4 Bxg5 44. Rxc6 Qf5 45. Qxf5 Rxf5 46. Re6 Bf6 47. Re8 Rd5 48. Rf8 Rd6 49. Rf7 h6 50. Kf1 Bc3 51. Ke2 Kc6 52. a4  Rf6 53. Re7 Kd6 54. Re3 Bb4 55. Rd3+ Ke6 56. Nd4+ Kf7 57. Nf3 Re6+ 58. Kf1 Rd6 59. Ke2 Kf6 60. Nd4 Bc5 61. Rf3+ Ke5 62. Nc2 Rc6  63. Ne3 Bxe3 64. Rxe3+ Kf4 65. Rf3+ Kg5 66. Rg3+ Kh4 67. Kf1 Rc5 68. Re3 Kg5 69. Ke2 Rc2+ 70. Kf3 Kf5 71. Kg3 h4+ 72. Kxh4 Kf4 73. Re7 Rc3 74. Rf7+ Ke4 75. Kg4 Rxb3 76. Rxc7 Rb4 77. Rb7 Kd5+ 78. f4 Kc6 79. Rh7 Rxa4 80. Rxh6+ Kc5 81. Rh8 b5 82. Rb8  Rd4   83. Kg5  a4 84. f5 b4 85. f6 Rd7 86. Kg6 b3 87. f7 Rxf7 88. Kxf7 Kc4 89. Rc8+ Kd3 90. Rb8 Kc3 91. Rc8+ Kb2 92. h4 a3 93. h5 a2 94. Ra8 a1=Q 95. Rxa1 Kxa1 96. h6 b2 97. h7 b1=Q 98. h8=Q+ Qb2 99. Qxb2+ Kxb2 1/2-1/2 "

; sample game 183
EventSites(183) = "Reykjavik op 22nd  Reykjavik" : GameDates(183) = "20060312" : WhitePlayers(183) = "Erenburg, Sergey   G#183" : WhiteElos(183) = "2573" : BlackPlayers(183) = "Timman, Jan H   G#183" : BlackElos(183) = "2630" : Each_Game_Result(183) = "1-0"

FilePGNs(183) = "1. e4 e6 2. d4 d5 3. Nd2 Be7 4. Ngf3 Nf6 5. e5 Nfd7 6. c3 c5 7. Be2 Nc6 8. O-O O-O 9. Re1 f6 10. exf6 Nxf6 11. Nf1 cxd4  12. cxd4 Ne4 13. Bd3  Nd6 14. Ne3  Bd7 15. Ng4 Nf5 16. Nge5  Rc8 17. Bf4 Nfxd4  18. Nxd4 Rxf4  19. Ndxc6  Rxc6 20. Qh5  g6 21. Bxg6  1-0 "

; sample game 184
EventSites(184) = "Poikovsky Karpov 7th  Poikovsky" : GameDates(184) = "20060325" : WhitePlayers(184) = "Bologan, Viktor   G#184" : WhiteElos(184) = "2661" : BlackPlayers(184) = "Dreev, Alexey   G#184" : BlackElos(184) = "2697" : Each_Game_Result(184) = "0-1"

FilePGNs(184) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Nf3 e6 5. Be2 Nd7 6. O-O Bg6 7. c3 Nh6 8. Bxh6 gxh6 9. Nbd2 Be7 10. Ne1 c5 11. Nb3  Qb6 12. dxc5 Bxc5 13. Nf3 Bf8 14. a4 a6 15. c4  Be4 16. a5 Qb4 17. Nbd2 Rd8  18. cxd5 Bxd5 19. Qc2 Bg7 20. Nc4 O-O 21. Rfd1 Rc8  22. b3  Nxe5  23. Nfxe5 Bxe5 24. Ra4 Qe7 25. Qd2 Bg7 26. Bf3  Bxf3  27. gxf3 Rfd8 28. Qe2 Qg5+ 29. Kf1 Rxd1+ 30. Qxd1 Rd8 31. Qc2 Qh5 32. Kg2 Qg6+ 33. Qxg6 hxg6 34. Rb4 Rd7 35. Nb6 Rc7 36. Na8 Bc3 0-1 "

; sample game 185
EventSites(185) = "RUS-chT 13th  Sochi" : GameDates(185) = "20060425" : WhitePlayers(185) = "Shirov, Alexei   G#185" : WhiteElos(185) = "2699" : BlackPlayers(185) = "Erenburg, Sergey   G#185" : BlackElos(185) = "2554" : Each_Game_Result(185) = "1/2-1/2"

FilePGNs(185) = "1. e4 e5 2. Nf3 Nf6 3. Nc3 Nc6 4. Bb5 Bb4 5. O-O O-O 6. d3 d6 7. Bg5 Bxc3 8. bxc3 Qe7 9. Re1 h6 10. Bh4 a6 11. Bxc6  bxc6 12. d4 Bg4 13. Qd3 Bxf3 14. Qxf3 g5 15. Bg3 Nd7 16. Rab1 Nb6 17. h4 f6 18. hxg5 hxg5 19. c4  exd4 20. c5  dxc5 21. e5 Nd5  22. exf6 Qxf6 23. Qh5  Nf4 24. Bxf4 Qxf4 25. f3 Rab8  26. Rbd1 Rf7 27. Re4 Rh7  28. Qg6+ Rg7 29. Qe6+ Qf7 30. Qxc6 g4  31. Rde1 gxf3  32. Re8+ Kh7 33. Qe4+ Rg6 34. Qh4+ Rh6 35. Qe4+ Rg6 36. Qh4+ Rh6 37. Qe4+ 1/2-1/2 "

; sample game 186
EventSites(186) = "RUS-chT 13th  Sochi" : GameDates(186) = "20060430" : WhitePlayers(186) = "Shirov, Alexei   G#186" : WhiteElos(186) = "2699" : BlackPlayers(186) = "Volokitin, Andrei   G#186" : BlackElos(186) = "2660" : Each_Game_Result(186) = "1/2-1/2"

FilePGNs(186) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 O-O 5. a3 Bxc3+ 6. Qxc3 b6 7. Bg5 Bb7 8. e3 d6 9. Ne2 Nbd7 10. Qd3 c5 11. Nc3 Qe7 12. Be2  Bxg2 13. Rg1 Bb7 14. O-O-O Rfc8 15. d5  exd5 16. cxd5 a6 17. Qf5 b5 18. Bd3 g6 19. Ne4  gxf5 20. Bxf6+  Kf8 21. Bxe7+ Kxe7 22. Ng3 Nf6  23. Nxf5+ Kd7 24. e4  Rg8 25. Nh6  Rxg1 26. Rxg1 Rf8 27. Rg7 Ke7 28. Nf5+ Kd7 29. Kd2 Bc8 30. b4  c4 31. Bc2 h5 32. h4  Kc7 33. Nh6 Ng4 34. Nxf7  Nxf2 35. Ne5+ Kb6 36. a4  a5  37. bxa5+ Kxa5 38. Nc6+ Kb6 39. a5+ Kc5 40. Rc7 Ng4  41. Kc3  Rf3+ 42. Kb2 Rf2 43. Ne5+ Kb4 44. Nc6+ Kc5 45. Ne5+ Kb4 1/2-1/2 "

; sample game 187
EventSites(187) = "Sigeman & Co 14th  Malmö" : GameDates(187) = "20060503" : WhitePlayers(187) = "Khenkin, Igor   G#187" : WhiteElos(187) = "2602" : BlackPlayers(187) = "Atalik, Suat   G#187" : BlackElos(187) = "2632" : Each_Game_Result(187) = "0-1"

FilePGNs(187) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. e4 Nxc3 6. bxc3 Bg7 7. Be3 c5 8. Qd2 cxd4 9. cxd4 Nc6 10. Bb5 O-O 11. Ne2 Qa5 12. Qxa5 Nxa5 13. Rc1 a6  14. Bd3 Bd7 15. Rc7 Bb5 16. Bxb5  axb5 17. Rxe7 Nc4 18. Bc1  Rxa2 19. e5 Rb8   20. Rc7 Bf8 21. h4 Bb4+ 22. Kd1 Nxe5   23. Rh3 Ng4 24. Be3 Re8 25. Nc3 Nxf2+ 26. Bxf2 Rxf2 27. Rf3 Rxg2 28. Rfxf7 Ra8 29. Rg7+ Kf8 0-1 "

; sample game 188
EventSites(188) = "Sigeman & Co 14th  Malmö" : GameDates(188) = "20060506" : WhitePlayers(188) = "Hector, Jonny   G#188" : WhiteElos(188) = "2514" : BlackPlayers(188) = "Atalik, Suat   G#188" : BlackElos(188) = "2632" : Each_Game_Result(188) = "0-1"

FilePGNs(188) = "1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Bc5 5. Be3 Qf6 6. c3 Nge7 7. g3 h5  8. f4  Bxd4 9. cxd4 d5 10. Nc3 Bg4 11. Be2 dxe4  12. Bxg4 hxg4 13. d5 O-O-O 14. Qxg4+ Qf5 15. Qxf5+ Nxf5 16. Bc5 b6 17. Ba3  Nxg3   18. Rg1 Nd4 19. hxg3 Nc2+ 20. Kd1 Nxa1 21. Be7 Rd7 22. Bh4 c6  23. Nxe4  cxd5 24. Ng5 Rc7 25. Kd2 Nc2 26. Nxf7 Rxf7 27. Kxc2 Re8  28. Kd3 d4  29. Rc1+ Rc7 30. Rxc7+ Kxc7 31. Kxd4 Re2 32. Kc3 Kd6  33. a4 a6 34. Kb3 Kc5 35. Ka3 b5  36. axb5 axb5  37. f5 Kc4 38. Ka2 b4 39. Kb1 b3 40. Kc1 Rc2+ 0-1 "

; sample game 189
EventSites(189) = "Sofia MTel Masters 2nd  Sofia" : GameDates(189) = "20060512" : WhitePlayers(189) = "Kamsky, Gata   G#189" : WhiteElos(189) = "2671" : BlackPlayers(189) = "Bacrot, Etienne   G#189" : BlackElos(189) = "2708" : Each_Game_Result(189) = "1-0"

FilePGNs(189) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. h3 Bb7 9. d3 d6 10. a3 Na5 11. Ba2 c5 12. Nc3 Nc6 13. Rb1  Rc8 14. Bd2 Nd4 15. b4 Nxf3+  16. Qxf3 c4  17. dxc4 bxc4 18. Qe2 Qc7 19. Bg5 Ne8  20. Bxe7 Qxe7 21. Bxc4 Nf6 22. Rbd1 a5 23. Nd5 Nxd5 24. Bxd5 axb4 25. axb4 Bxd5 26. Rxd5 Qc7 27. Rc1 Qc3 28. b5 Rfd8 29. Qd1 h6 30. Kh2  Rc5 31. Rxc5 Qxc5 32. Qe2 Rc8 33. c4 Qd4 34. Rc2 g6 35. f3 Kg7 36. Rd2 Qxc4 37. Qxc4 Rxc4 38. Rxd6 Rb4 39. b6 h5 40. h4 f5  41. Rd7+  Kf6 42. b7 fxe4 43. fxe4 g5 44. g3  Rb2+ 45. Kg1 gxh4 46. gxh4 Ke6 47. Rh7 Kd6 48. Rxh5 Rxb7 49. Kg2 Rb4 50. Kf3 Rb1 51. Rg5 Ke6 52. h5 Rf1+ 53. Ke2 Rf4 54. Ke3 Rh4 55. Rf5 Rh3+ 56. Kf2 Rh4 57. Kf3 Rh3+ 58. Kg4 Re3 59. h6 Rxe4+ 60. Kg5 Re1 61. Rf6+ Kd5  62. h7 Rg1+ 63. Kh6 Ke4 64. Rf8  Rh1+ 65. Kg6 Rxh7 66. Kxh7 Kd3 67. Rd8+ Ke3 68. Kg6 e4 69. Kf5 Kf3 70. Rh8 e3 71. Rh3+ Kf2 72. Kf4 e2 73. Rh2+ Kf1 74. Kf3 e1=N+ 75. Kg3 Nd3 76. Rd2 Ne1 77. Rf2+ Kg1 78. Rf8 Ng2 79. Kf3 Kf1  80. Kg3+  Kg1 81. Kf3 Kf1  82. Rf7  Ne1+ 83. Ke3+ Kg1 84. Ke2 Ng2 85. Rh7 Nf4+ 86. Kf3 Nd3 87. Rh4 Ne5+ 88. Ke2  Kg2 89. Re4 Nf7  90. Re7 Nd6 91. Rg7+ Kh3 92. Kf3 Kh4 93. Kf4 Kh5 94. Re7 Nc4 95. Re6 Nd2 96. Rc6 Nb3 97. Ke3 Kg4 98. Rc4+ Kg3 99. Rc3 Na5 100. Ke4+ Kf2 101. Kd5 Nb7 102. Rb3 Nd8 103. Rb8 1-0 "

; sample game 190
EventSites(190) = "Sofia MTel Masters 2nd  Sofia" : GameDates(190) = "20060513" : WhitePlayers(190) = "Anand, Viswanathan   G#190" : WhiteElos(190) = "2803" : BlackPlayers(190) = "Kamsky, Gata   G#190" : BlackElos(190) = "2671" : Each_Game_Result(190) = "0-1"

FilePGNs(190) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. h3 Bb7 9. d3 d6 10. a3 Qd7 11. Nbd2 Nd8 12. c3 Ne6 13. d4 Rad8  14. d5 Nf4 15. Nf1 Ng6 16. Ng3 c6  17. Bg5 cxd5 18. Bxf6 Bxf6 19. Bxd5 Nf4 20. Bxb7 Qxb7 21. Qc2 g6 22. Rad1 d5 23. exd5 Rxd5 24. Rxd5 Qxd5 25. Rd1 Qe6 26. Qe4 Rb8  27. Ne2 Nxe2+ 28. Qxe2 Re8  29. Qe4 h6 30. g4  Bg5  31. Nxg5 hxg5 32. Qd5 Kg7 33. Qxe6 Rxe6 34. Rd7 Kf6 35. Kf1 Rc6 36. Ke2 Ke6 37. Rd8 e4 38. f3  exf3+ 39. Kxf3 Rd6  40. Re8+ Kd5 41. b3 Rf6+ 42. Kg2 Rc6 43. Re3 f5 44. gxf5 gxf5 45. Rg3 Ke4  46. a4 bxa4 47. bxa4 Kf4 48. Rf3+ Ke5 49. Re3+ Kf6 50. Rd3 f4 51. Kf3 Ke5 52. Kg4 Rd6 53. Rxd6 Kxd6 54. h4 gxh4 55. Kxh4 Kd5 56. Kh3 Ke4 57. Kg2 Ke3  0-1 "

; sample game 191
EventSites(191) = "Sofia MTel Masters 2nd  Sofia" : GameDates(191) = "20060514" : WhitePlayers(191) = "Anand, Viswanathan   G#191" : WhiteElos(191) = "2803" : BlackPlayers(191) = "Ponomariov, Ruslan   G#191" : BlackElos(191) = "2738" : Each_Game_Result(191) = "1-0"

FilePGNs(191) = "1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Bf5 5. Ng3 Bg6 6. Nf3 Nd7 7. h4 h6 8. h5 Bh7 9. Bd3 Bxd3 10. Qxd3 e6 11. Bf4 Ngf6 12. O-O-O Be7 13. Ne4 Nxe4 14. Qxe4 Nf6 15. Qd3 Qd5 16. c4 Qe4 17. Qxe4 Nxe4 18. Be3 O-O 19. Ne5 Bd6 20. f3 Ng3 21. Rh3 Nf5 22. Bf2 Rad8 23. g4 Ne7 24. Nd3  b5 25. b3 Bc7 26. Rhh1 Bb6 27. Nc5 Rfe8 28. Kc2 bxc4 29. bxc4 Bxc5 30. dxc5 e5 31. Rd6 Rb8 32. Rhd1 Rb7 33. Rd8 Rxd8 34. Rxd8+ Kh7 35. Rf8 f6 36. Be1 Rd7 37. Bc3 Ng8 38. a4  g6 39. a5  gxh5 40. gxh5 Kg7 41. Rb8 Ne7 42. a6 Kf7 43. Ba5  Nf5 44. Bb6  Ne3+ 45. Kc3 Ke6 46. Rc8 Kf5 47. Rxc6 Nd1+ 48. Kb4 Rd2 49. Bxa7 Rb2+ 50. Ka3 Rb1 51. Rb6 Ra1+ 52. Kb3 e4 53. fxe4+ Kxe4 54. c6 Kd3 55. c7 Rb1+ 56. Ka3 1-0 "

; sample game 192
EventSites(192) = "Sofia MTel Masters 2nd  Sofia" : GameDates(192) = "20060518" : WhitePlayers(192) = "Ponomariov, Ruslan   G#192" : WhiteElos(192) = "2738" : BlackPlayers(192) = "Svidler, Peter   G#192" : BlackElos(192) = "2743" : Each_Game_Result(192) = "1-0"

FilePGNs(192) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 a6 5. Bd3 Nf6 6. O-O Qc7 7. Qe2 d6 8. c4 g6 9. Nc3 Bg7 10. Nf3 O-O 11. Bf4 Nc6 12. Rac1 Nd7 13. Qe3 Nce5 14. Nxe5 Nxe5 15. Be2 b6 16. Rfd1 Re8 17. Qd2 Nxc4 18. Bxc4 Qxc4 19. Qxd6 Bb7 20. Be5  Bxe5 21. Qxe5 Rad8 22. f3 b5 23. Kf2  Qc6 24. Ne2 Qb6+ 25. Rd4 Rd7 26. b4 Red8 27. Ke3  Rxd4 28. Nxd4 Rd6 29. Qf6 Rd7 30. Rc5 Qd6 31. g3 a5 32. a3 axb4 33. axb4 Qa6 34. Ne2 Qd6 35. Qc3 h5 36. Qd4 Qe7 37. Qe5 f6 38. Qb8+ Kg7 39. Nc3 e5 40. Nd5 Bxd5 41. exd5 f5 42. Qxb5 f4+ 43. Kf2 e4 44. fxe4 fxg3+ 45. hxg3 Qf6+ 46. Kg2 Qb2+ 47. Kh3 Rf7 48. Qd3 Qxb4 49. Qc3+ Qxc3 50. Rxc3 Re7 51. Rc4 Kf6 52. Kh4 Ke5 53. Rc6 1-0 "

; sample game 193
EventSites(193) = "Sofia MTel Masters 2nd  Sofia" : GameDates(193) = "20060519" : WhitePlayers(193) = "Topalov, Veselin   G#193" : WhiteElos(193) = "2804" : BlackPlayers(193) = "Ponomariov, Ruslan   G#193" : BlackElos(193) = "2738" : Each_Game_Result(193) = "1-0"

FilePGNs(193) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. h3 Bb7 9. d3 d6 10. a4 Na5 11. Ba2 c5 12. Nbd2 Nd7  13. Nf1 Nb6 14. Bd2 b4 15. c3 bxc3 16. Bxc3 Nc6 17. a5 Nc8 18. Ne3 N8a7 19. Nf5 Bc8 20. Nd2 Rb8 21. f4 Bxf5 22. exf5 exf4 23. Qg4 Nd4 24. Ne4 Nab5 25. Bd2 Nc2 26. Bxf4 Kh8 27. Qh5 Nxe1 28. Rxe1 Qxa5 29. Ra1 Rbd8  30. f6  gxf6 31. Kh2  d5  32. Nxf6 Bxf6 33. d4  Qxa2 34. Rxa2 Nxd4 35. b4  Ne6 36. Be5 Bg7 37. bxc5 Rc8 38. Bd6 Rfd8 39. Ra5 Kg8 40. Rxa6 Rd7 41. Qxd5 Bf8 42. Qf3 Bxd6+ 43. cxd6 Rcd8 44. Qd5 Ng7 45. Ra8 Ne6 46. Rxd8+ Rxd8 47. g4 h6 48. h4 Rb8 49. Kg3 Re8 50. Kf3 Nf8 51. Qd2 Kg7 52. Qd4+ Kg8 53. Qf6 Re6 54. Qe7 Kg7 55. Qc7 Kg8 56. d7 Nxd7 57. Qxd7 Kg7 58. Qd4+ Kg8 59. Kf4 Rg6 60. Kf5 Re6 61. Qd7 Rg6 62. h5 Rg5+ 63. Kf6 Kh8 64. Qe8+ Rg8 65. Kxf7 1-0 "

; sample game 194
EventSites(194) = "GRE-chT 35th  Ermioni" : GameDates(194) = "20060710" : WhitePlayers(194) = "Azmaiparashvili, Zurab   G#194" : WhiteElos(194) = "2669" : BlackPlayers(194) = "Macieja, Bartlomiej   G#194" : BlackElos(194) = "2613" : Each_Game_Result(194) = "0-1"

FilePGNs(194) = "1. d4 e6 2. c4 Nf6 3. Nf3 b6 4. a3 Bb7 5. Nc3 d5 6. cxd5 Nxd5 7. Qa4+ Nd7 8. Nxd5 Bxd5 9. Bg5 Be7 10. Bxe7 Qxe7 11. Rc1  O-O  12. e4  Bxe4 13. Rxc7 Nc5  14. dxc5 Qxc7 15. Qxe4 Qxc5 16. Qe3 Qc2  17. Bd3 Qxb2 18. O-O Rad8  19. h4 Qf6  20. Rb1 Rd5 21. Rb4 Rc8  22. Ng5 h6 23. Ne4 Qe5  24. f4 Qh5 25. Nf2 Qxh4 26. f5 Qf6 27. fxe6 Qxe6 28. Re4 Qc6 29. Qe2 g6 30. Re7 Qc1+  31. Kh2 Rc7  32. Re8+ Kg7 33. Nh3  Qxa3 34. Nf4 Rg5 35. Qf2 Qc5 36. Qb2+ Qc3 37. Qf2 Qc5 38. Qb2+ Qc3 39. Qf2 Kh7 40. Qf3 Qd4 41. g3 b5 42. Ne2 Qb2 43. Kh3 a5 44. Rd8 Qe5 45. Nf4 Qe1 46. g4 Re7 47. Ng2 Qe5 48. Nf4 Qe3 49. Kg2 Qxf3+ 50. Kxf3 Ra7 51. Nh5 a4 52. Rb8 Ra6 0-1 "

; sample game 195
EventSites(195) = "North Urals Cup (Women) 4th  Krasnoturinsk" : GameDates(195) = "20060724" : WhitePlayers(195) = "Cmilyte, Viktorija   G#195" : WhiteElos(195) = "2476" : BlackPlayers(195) = "Lahno, Kateryna   G#195" : BlackElos(195) = "2449" : Each_Game_Result(195) = "0-1"

FilePGNs(195) = "1. d4 Nf6 2. c4 e6 3. Nf3 c5 4. d5 exd5 5. cxd5 d6 6. Nc3 g6 7. e4 Bg7 8. Be2 O-O 9. O-O Re8 10. Nd2 Na6 11. f4 Rb8 12. a4  Nb4 13. Ra3  b6 14. Bf3 a6  15. Nc4 b5 16. axb5 axb5 17. Na5 Rb6  18. Re1  c4  19. Na2  Nd3 20. Rxd3 cxd3 21. Nb4 Nd7 22. Nbc6 Qc7 23. Qxd3  b4  24. Qc2  Nc5 25. Nc4 b3 26. Qd1 Ba6  27. Nxb6 Qxb6 28. e5 Nd3+ 29. Be3 Qc7 30. Bd4 Nxe1 31. Qxe1 Bb7 32. Qb4 Bxc6 33. Bb6 Qc8 34. dxc6 dxe5 35. fxe5 Bxe5 36. Bg4  Qxc6 37. Be3 Bd6 38. Qd2 Rxe3  0-1 "

; sample game 196
EventSites(196) = "North Urals Cup (Women) 4th  Krasnoturinsk" : GameDates(196) = "20060726" : WhitePlayers(196) = "Kosintseva, Nadezhda   G#196" : WhiteElos(196) = "2472" : BlackPlayers(196) = "Lahno, Kateryna   G#196" : BlackElos(196) = "2449" : Each_Game_Result(196) = "0-1"

FilePGNs(196) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O b5 6. Bb3 Bc5 7. c3 d6 8. a4 Rb8 9. d4 Bb6 10. axb5 axb5 11. Na3 O-O 12. Nxb5 Bg4 13. Bc2 Bxf3 14. gxf3 Nh5 15. Kh1 Qf6 16. Ra4 Ne7   17. Rg1 Ng6 18. Bg5 Qe6 19. Bd3  Nhf4 20. Bf1 c6  21. Na3 d5 22. exd5 cxd5 23. Nc2 Ra8 24. Ne3 Rxa4 25. Qxa4 exd4 26. cxd4 Bc7 27. Qa7 Bb8 28. Qa6 Qxa6 29. Bxa6 Nh3 30. Nxd5 Nxg1 31. Kxg1 Ba7 32. Be3 Rd8 33. Bc4 Kf8 34. Kf1 Ne7 35. Nxe7 Kxe7 36. d5 Bb8 37. h3 Bd6 38. Ke2 Ra8 39. f4 Ra1 40. Kf3 Rh1 41. Kg2 Rb1 42. b3 f6 43. Kf3 Bb4 44. Ba7 Ra1 45. Bd4 Rh1 46. Kg2 Rd1 47. Ba7 Bd6 48. Be3 Ra1 49. Kf3 Bb4 50. Bd4 Ra2 51. Bd3 Ra3 52. Bc4 Kd6 53. Ke4 Ra2 54. Be3 Ra1 55. Kf3 Rg1 56. Ba7 Rh1 57. Kg2 Rd1 58. Bb8+ Kd7 59. Ba7 Bd2 60. Kf3 Rh1 61. Kg2 Ra1 62. Bd4 Rd1 63. Be3 Bxe3 64. fxe3 f5 65. Kf3 Kd6 66. Kg3 Kc5 67. Kf3 Rd2 68. Kg3 Ra2 69. Kf3 Ra8 70. Ke2 Ra1 71. Kf3 Rg1 72. Kf2 Rg6 73. Bd3 Rf6 74. Bc4 Rh6 75. Kg3 Kb4 76. Bd3 Rf6 77. e4  fxe4 78. Bxe4 h6 79. Bh7 Kxb3 80. Bg8 Kc3 81. Kg4 Kd4 82. Be6 g6 83. Kf3  Rf8 84. h4 Rf6 85. f5  Ke5 86. d6 Kxd6 87. Kf4 Ke7  88. Ke5 g5  89. h5  Rf8 90. Bd5 g4 91. Kf4 Rd8  92. Be4 Rd4 93. Ke5 Ra4 94. f6+ Kf7 95. Bg2 g3 96. Kf5 Ra2 97. Bd5+ Kf8 98. Bxa2 g2 0-1 "

; sample game 197
EventSites(197) = "Biel GM  Biel" : GameDates(197) = "20060724" : WhitePlayers(197) = "Bruzon Bautista, Lazaro   G#197" : WhiteElos(197) = "2667" : BlackPlayers(197) = "Morozevich, Alexander   G#197" : BlackElos(197) = "2731" : Each_Game_Result(197) = "0-1"

FilePGNs(197) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Re8 10. d4 Bb7 11. Nbd2 Bf8 12. d5 Nb8 13. Nf1 Nbd7 14. N3h2 h6 15. Qf3  Nc5 16. Bc2 c6 17. b4 Na4 18. dxc6 Bxc6 19. Ng4 Nxg4 20. hxg4 Bd7 21. Bd2 Rc8 22. Bb3 Be6 23. Rac1 Nb2 24. Qe2 Nc4 25. Ne3 Qd7 26. f3 Be7 27. Red1 Qa7 28. Bxc4 Bxc4 29. Qf2 Bxa2 30. Ra1 Bb3 31. Rdc1 Qb7 32. Ra3 Be6 33. Rca1 Rc6 34. Rd1 Ra8 35. Qe2 Bd8 36. Nf5 a5 37. bxa5 Rxa5 38. Rxa5 Bxa5 39. Rb1 Bxf5 40. gxf5 Bxc3 41. Bxc3 Rxc3 42. Rxb5 Rc1+ 43. Kf2 Qe7 44. Qd2 Qh4+ 45. Ke3 Qh1 46. Rb2 Rf1 47. Qxd6 f6 48. Qd5+ Kh7 49. Rd2 Qg1+ 50. Kd3 Rc1 51. Qf7 Qf1+ 52. Re2 Rc8 53. Qd7 Qb1+ 0-1 "

; sample game 198
EventSites(198) = "Biel GM  Biel" : GameDates(198) = "20060725" : WhitePlayers(198) = "Carlsen, Magnus   G#198" : WhiteElos(198) = "2675" : BlackPlayers(198) = "Morozevich, Alexander   G#198" : BlackElos(198) = "2731" : Each_Game_Result(198) = "1-0"

FilePGNs(198) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. O-O Nc6 8. d5 Ne7 9. a4 a5 10. b3  Nd7 11. Ba3 Bh6 12. b4 axb4 13. Bxb4 f5 14. Nd2 Kh8 15. a5 Rf7 16. Nb5 Nf6 17. c5 dxc5 18. Bc3  c6 19. dxc6 bxc6  20. Na3 fxe4  21. Nac4  Ned5 22. Bxe5 Bg7 23. Nd6 Re7 24. N2c4 Be6  25. a6  Nb4  26. Qc1 Nd3  27. Bxd3 exd3 28. Qc3  Bxc4  29. Qxc4 Qg8  30. Qxc5 d2 31. Rad1  Rxa6  32. Rxd2  Nd5 33. Bxg7+ Rxg7  34. h3  Qe6  35. Rb1  h6  36. Qc4  Rb6 37. Rxb6 Qe1+ 38. Kh2 Nxb6  39. Qf4  Nd5  40. Rxd5  cxd5 41. Qf8+ Kh7 42. Ne8 1-0 "

; sample game 199
EventSites(199) = "Biel GM  Biel" : GameDates(199) = "20060725" : WhitePlayers(199) = "Pelletier, Yannick   G#199" : WhiteElos(199) = "2583" : BlackPlayers(199) = "Radjabov, Teimour   G#199" : BlackElos(199) = "2728" : Each_Game_Result(199) = "0-1"

FilePGNs(199) = "1. d4 Nf6 2. Nf3 g6 3. c4 Bg7 4. Nc3 d6 5. e4 O-O 6. Be2 e5 7. O-O Nc6 8. d5 Ne7 9. Bg5 Nh5  10. Ne1 Nf4 11. Nd3 Nxe2+ 12. Qxe2 h6 13. Bd2 g5  14. g4 Ng6  15. f3 Nf4 16. Nxf4 exf4 17. Rfd1 h5  18. h3 Be5 19. Be1 Kg7 20. Rd3 Rh8 21. Nd1 hxg4 22. fxg4 Qf6 23. Bc3 Bd7 24. Nf2 Rae8 25. Qf3 Bxc3 26. Rxc3 c5 27. Re1 a6 28. Rc2 b5 29. b3 Re7 30. Kg2 Rhe8 31. Rce2 Qh6 32. Nd3 f6 33. Nf2 Qh4 34. Qc3 a5  35. Qf3 Rb8 36. Rc1 Be8 37. Qd3 Ra7 38. Qf3 Bg6 39. Nd3 Re7 40. Nf2 Reb7 41. Rec2 b4  42. Qd3 a4 43. Qf3 Ra8 44. Re1 Re7 45. Rce2 axb3 46. axb3 Ra3  47. Rb1 Re8 48. Qd3 Rea8 49. Kf1 R8a7  50. Qf3 Ra2 51. Rbe1 Rxe2 52. Rxe2 Ra1+ 53. Re1 Ra3  54. Re2 Qg3 0-1 "

; sample game 200
EventSites(200) = "Biel GM  Biel" : GameDates(200) = "20060728" : WhitePlayers(200) = "Radjabov, Teimour   G#200" : WhiteElos(200) = "2728" : BlackPlayers(200) = "Bruzon Bautista, Lazaro   G#200" : BlackElos(200) = "2667" : Each_Game_Result(200) = "1-0"

FilePGNs(200) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 c6 5. Bg5 Nbd7 6. e3 Be7  7. cxd5 exd5 8. Bd3 O-O 9. Qc2 Re8 10. O-O Nf8 11. h3 g6 12. Bf4 Ne6 13. Be5 Ng7 14. Rab1 Bf5 15. b4 a6 16. a4 Bxd3 17. Qxd3 b5  18. Rfc1 Nf5 19. e4  dxe4 20. Nxe4 Nxe4 21. Qxe4 Qd5 22. Qxd5 cxd5 23. axb5 axb5 24. Rc6  Ra2 25. Rb6 f6  26. Bh2 Bxb4  27. g4  Ba5 28. Ra6  Ng7 29. Rxb5 Ra3 30. Kg2 Bb4 31. Rxa3 Bxa3 32. Rxd5 Be7 33. Ra5  Rd8 34. d5  Bb4 35. Rb5 Bc3 36. Kf1  h5 37. Ke2 hxg4 38. hxg4 Ra8 39. Rb3 Ba5 40. Nd4 Re8+ 41. Kd3 Be1 42. d6 Rd8 43. Rb7 1-0 "

; sample game 201
EventSites(201) = "Biel GM  Biel" : GameDates(201) = "20060731" : WhitePlayers(201) = "Morozevich, Alexander   G#201" : WhiteElos(201) = "2731" : BlackPlayers(201) = "Carlsen, Magnus   G#201" : BlackElos(201) = "2675" : Each_Game_Result(201) = "0-1"

FilePGNs(201) = "1. e4 c5 2. Nf3 Nc6 3. Bb5 Nf6 4. Bxc6 dxc6 5. d3 Nd7 6. Bf4  g6 7. Qc1 Bg7  8. Bh6 Qa5+  9. c3 Ne5 10. Nxe5 Bxe5 11. Nd2 Qa6 12. Qc2 Be6 13. f4 Bc7 14. O-O f6 15. c4  O-O-O 16. a4  Rd7 17. a5 Rhd8 18. Ra3 Bxa5  19. f5 Bf7 20. fxg6 hxg6 21. e5 Be6 22. exf6 exf6 23. Nb3 Rxd3 24. Nxc5 Bb6 25. Rxa6 Bxc5+ 26. Kh1 bxa6 27. Bg7  Bg4  28. b4 Be3 29. h3 Rd1 30. Rxd1 Rxd1+ 31. Kh2 Bf4+ 32. g3 Rd2+ 33. Qxd2 Bxd2 34. hxg4 Bxb4  35. Bxf6 a5 36. Kg2 Kd7 37. Kf3 Bd6  38. Ke4 Bxg3 39. Kd3 Ke6 40. Bd4 a6 41. Kc2 a4 42. Kb1 Be5 43. Bf2 Kd6 44. Ka2 Bc3 45. Ka3 Ke5 46. Kxa4 Kf4 47. Bb6 Kxg4 48. Ba5 Bxa5 49. Kxa5 Kf4 50. Kb6 a5 0-1 "

; sample game 202
EventSites(202) = "Biel GM  Biel" : GameDates(202) = "20060731" : WhitePlayers(202) = "Radjabov, Teimour   G#202" : WhiteElos(202) = "2728" : BlackPlayers(202) = "Pelletier, Yannick   G#202" : BlackElos(202) = "2583" : Each_Game_Result(202) = "1/2-1/2"

FilePGNs(202) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 Qc7 6. f4 Nxd4 7. Qxd4 a6 8. Be3 b5 9. O-O-O Bb7 10. Bd3 Rc8 11. Kb1 Qc5 12. Qxc5 Bxc5 13. Bxc5 Rxc5 14. e5 f5 15. a4 Bxg2  16. Rhg1 Bc6 17. axb5 axb5 18. Rxg7 Ne7 19. Rg3 Ng6 20. Ne2  b4 21. Rdg1 Kf7  22. Rh3  Ra5 23. Rg5 h6  24. Rgh5 Bg2 25. Rg3 Bf1 26. Bxf5  exf5 27. Rxf5+ Ke7 28. Rxg6 Bxe2 29. Rg7+ Kd8 30. b3 Rd5 31. Rff7 Re8 32. Rf6 Re6 33. Rf8+ Kc7 34. Ra8 Ra6  35. Rxa6 Bxa6 36. e6 Kd8 37. Rg6  Rd6  38. f5 dxe6 39. Rxh6 Ke7 40. Rxe6+ Rxe6 41. fxe6 Kxe6 1/2-1/2 "

; sample game 203
EventSites(203) = "Biel GM  Biel" : GameDates(203) = "20060801" : WhitePlayers(203) = "Pelletier, Yannick   G#203" : WhiteElos(203) = "2583" : BlackPlayers(203) = "Bruzon Bautista, Lazaro   G#203" : BlackElos(203) = "2667" : Each_Game_Result(203) = "1-0"

FilePGNs(203) = "1. Nf3 c5 2. c4 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e6 6. Bg5 h6 7. Bh4 Qb6 8. Bxf6  gxf6 9. Nb3 f5 10. e3 Rg8 11. Qd2 a6 12. O-O-O Qc7 13. Kb1 b6 14. e4 f4 15. g3 Bb7 16. gxf4 Rg4 17. Qe3  Qxf4 18. Qxb6 Rb8 19. f3 Rg5 20. Qf2 Bc8 21. Bg2 Bg7 22. Ne2 Qf6 23. Rd2 Na5  24. f4 Nxc4 25. Rd4 Na5 26. Bf3 Rgb5   27. e5 Qe7 28. Nec1 Nxb3  29. Nxb3 f6 30. Rc1  Kf8 31. Rdc4  Bb7  32. Bxb7 R8xb7 33. Rc8+ Kf7 34. Qf3 Kg6 35. Rg1+ Kh7 36. Qd3+   f5 37. Rg2 d6 38. exd6 Qd7 39. Rcc2  Rd5 40. Qg3 Qxd6   41. Qg6+ Kh8 42. Rc8+ Qd8 1-0 "

; sample game 204
EventSites(204) = "Biel GM  Biel" : GameDates(204) = "20060802" : WhitePlayers(204) = "Volokitin, Andrei   G#204" : WhiteElos(204) = "2662" : BlackPlayers(204) = "Carlsen, Magnus   G#204" : BlackElos(204) = "2675" : Each_Game_Result(204) = "1-0"

FilePGNs(204) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 Nc6 6. Bg5 g6  7. Bxf6  exf6 8. Bc4  Bg7 9. Ndb5 O-O 10. Qxd6 f5 11. O-O-O Qa5 12. Qc7  fxe4 13. Qxa5 Nxa5 14. Bd5 Bg4 15. Rde1  Rad8 16. Rxe4 Bf5 17. Ra4 b6 18. Rd1 a6 19. Nd4 Bd7 20. Rb4 b5 21. Nf3 Nc6 22. Re4 b4 23. Bxc6 Bxc6 24. Rxb4 Bh6+ 25. Kb1 Rxd1+ 26. Nxd1 Bxf3 27. gxf3 Rd8 28. Nc3 Rd2 29. a4 Rxf2 30. Rb6 a5 31. Nd5 Rxh2 32. Rb5 Bd2 33. c4 h5 34. c5 Rh1+ 35. Kc2 Bh6 36. f4 Bf8 37. Rb8 Rh2+ 38. Kd3 Rh3+ 39. Kc4 1-0 "

; sample game 205
EventSites(205) = "Biel GM  Biel" : GameDates(205) = "20060803" : WhitePlayers(205) = "Pelletier, Yannick   G#205" : WhiteElos(205) = "2583" : BlackPlayers(205) = "Volokitin, Andrei   G#205" : BlackElos(205) = "2662" : Each_Game_Result(205) = "1-0"

FilePGNs(205) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 O-O 5. Bd3 c5 6. Nf3 d5 7. O-O Nc6 8. a3 Bxc3 9. bxc3 dxc4 10. Bxc4 Qc7 11. Bb2 e5 12. h3 b6 13. Ba2 Ba6 14. Re1 e4 15. Nd2 Rad8 16. f3 exf3 17. Qxf3 Ne5  18. dxe5 Rxd2 19. exf6 Rxb2 20. Qg4 g6 21. Qg5 Rd8  22. Red1 Bb7 23. Qe5   Rxg2+ 24. Kf1 Qb8 25. Bxf7+ Kh8 26. Rxd8+ Qxd8 27. Bd5 Rg5 28. Qxg5 Bxd5 29. Rd1 Bc4+ 30. Ke1 Qb8 1-0 "

; sample game 206
EventSites(206) = "Biel MTO op  Biel" : GameDates(206) = "20060726" : WhitePlayers(206) = "Arizmendi Martinez, Julen Luis   G#206" : WhiteElos(206) = "2542" : BlackPlayers(206) = "Nemet, Ivan   G#206" : BlackElos(206) = "2353" : Each_Game_Result(206) = "1-0"

FilePGNs(206) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. c3 d5 9. d4  exd4 10. e5 Ne4 11. cxd4 Bg4 12. Nc3 Bxf3 13. gxf3 Nxc3 14. bxc3 Qd7 15. Kh1  Nd8  16. f4 f5  17. exf6 Bxf6 18. Qh5 c6 19. Bc2 g6 20. Rg1  Bg7 21. Rxg6  hxg6 22. Bxg6 Rf6 23. Bh7+  Kf8 24. Ba3+ Rd6 25. Qf5+  Ke7 26. Re1+ Ne6 27. Qg6 Re8 28. Qxg7+ Kd8 29. Qf6+ Kc8 30. Bf5 c5 31. Bxc5 Nxc5  32. Bxd7+ Kc7 33. Qxd6+ 1-0 "

; sample game 207
EventSites(207) = "Dortmund SuperGM  Dortmund" : GameDates(207) = "20060804" : WhitePlayers(207) = "Leko, Peter   G#207" : WhiteElos(207) = "2738" : BlackPlayers(207) = "Aronian, Levon   G#207" : BlackElos(207) = "2761" : Each_Game_Result(207) = "1-0"

FilePGNs(207) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Bxc6 dxc6 5. O-O Be7  6. d3 Bf6 7. Nbd2 Ne7 8. Nc4 Ng6 9. b3  O-O 10. Bb2 Re8 11. h3 a5 12. a4 c5 13. Kh1 b6 14. Bc3 Be6 15. Nh2 Bxc4 16. bxc4 Qd7 17. Qg4 Qc6 18. g3 Nf8 19. f4 exf4 20. Bxf6 Qxf6 21. gxf4 Qg6 22. f5 Qxg4 23. hxg4 f6  24. Nf3 Rad8 25. Kg2 Rd6 26. Kg3 Nd7 27. Kf4 h6 28. Ke3 Kf7 29. Rad1 Rc6 30. Rg1 Re7 31. Rd2 Rd6 32. Rdd1 Rc6 33. Rde1 Rd6 34. Rg2 Rc6 35. Rb1 Rd6 36. Ng1 Ne5 37. Ne2 Re8 38. Nc3 Rd4 39. Kf4 Rd7 40. Nd5 Nc6 41. Ke3 Ne5 42. Nc3 Rd6 43. Ne2 Rd7 44. Kf4 Red8 45. Ng1 Rd6 46. Nf3 Nd7 47. Re1 Re8 48. Rge2 Re7 49. Ke3 Re8 50. Rd1 Rd8 51. Red2 Ke7 52. Kf4 Re8 53. Ke3 Rd8 54. c3 Ne5 55. Nxe5 fxe5 56. d4 Kf6 57. dxe5+  Kxe5 58. Rd5+ Rxd5 59. cxd5 b5  60. axb5  a4 61. Kd3 Kd6 62. Ra1 Ra8 63. Ra3 1-0 "

; sample game 208
EventSites(208) = "Montreal Empresa-A  Montreal" : GameDates(208) = "20060809" : WhitePlayers(208) = "Mikhalevski, Victor   G#208" : WhiteElos(208) = "2571" : BlackPlayers(208) = "Onischuk, Alexander   G#208" : BlackElos(208) = "2668" : Each_Game_Result(208) = "1/2-1/2"

FilePGNs(208) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 dxc4 5. a4 Bf5 6. Ne5 Nbd7 7. Nxc4 Qc7 8. g3 e5 9. dxe5 Nxe5 10. Bf4 Nfd7 11. Bg2 f6 12. O-O Nc5 13. Ne3 Bg6 14. b4 Ne6 15. b5 Rd8 16. Qb3 Nd4 17. Qb2 Bc5 18. a5  O-O 19. a6  bxa6 20. bxc6 Ndxc6 21. Rxa6 Qc8 22. Ra4   Bd4 23. Ned5 Kh8 24. Rd1  Bc5 25. Rc1  Qd7  26. Nb5   Bb6 27. Nxb6 axb6 28. Be3 Rc8  29. h3  Na5  30. Rd4  Rxc1+ 31. Bxc1 Qe6 32. Nc7 Qb3 33. Qd2   Qf7 34. Rd8  Nb3  35. Qd6 Rxd8 36. Qxd8+ Qg8 37. Qxg8+ Kxg8  38. Ba3 Nc4 39. Be7  Nd4  40. e3 Ne2+ 41. Kh2 Nc3 42. Nd5 1/2-1/2 "

; sample game 209
EventSites(209) = "Nuremberg LGA Cup 3rd  Nuremberg" : GameDates(209) = "20060909" : WhitePlayers(209) = "Wells, Peter K   G#209" : WhiteElos(209) = "2480" : BlackPlayers(209) = "Fridman, Daniel   G#209" : BlackElos(209) = "2569" : Each_Game_Result(209) = "1/2-1/2"

FilePGNs(209) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 dxc4 5. a4 Bf5 6. Ne5 Nbd7 7. Nxc4 Nd5 8. Bg5  N7b6 9. e3 f6 10. Bh4 e6 11. a5 Bb4 12. Qb3 Nxc4 13. Bxc4 Bxa5 14. Qxb7 O-O 15. Qa6  Bb4 16. O-O Nxc3 17. bxc3 Bxc3 18. Ra3 Bb4 19. Rb3 c5 20. e4 Bg6 21. Bxe6+ Bf7 22. d5 g5  23. Bg3 Qb6 24. Bxf7+ Rxf7 25. Qc4  a5 26. d6   Qa6 27. Qe6 Qc8 28. Qc4 Qa6 29. Qe6 Qc8 30. Qc4  1/2-1/2 "

; sample game 210
EventSites(210) = "ESP-chT Honor Gp2  San Sebastian" : GameDates(210) = "20060916" : WhitePlayers(210) = "Aronian, Levon   G#210" : WhiteElos(210) = "2762" : BlackPlayers(210) = "Arizmendi Martinez, Julen Luis   G#210" : BlackElos(210) = "2542" : Each_Game_Result(210) = "1/2-1/2"

FilePGNs(210) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 a6 5. c5 Nbd7 6. Bf4 Nh5 7. Bd2 Nhf6 8. Qc2 Qc7 9. Bg5 e5 10. Bxf6 gxf6  11. e3 f5  12. g3  f4  13. exf4 exd4 14. Qe2+  Be7 15. Nxd4 Nxc5 16. O-O-O O-O 17. Qh5 Bf6 18. Be2  b5  19. Qh6 Qd6 20. b4  Ne4 21. Nxe4 dxe4 22. Nf5 Bb2+  23. Kxb2 Qxb4+ 24. Ka1 Qc3+ 25. Kb1 Qb4+ 26. Ka1 Qc3+ 27. Kb1 Qb4+ 1/2-1/2 "

; sample game 211
EventSites(211) = "World Championship  Elista" : GameDates(211) = "20060923" : WhitePlayers(211) = "Kramnik, Vladimir   G#211" : WhiteElos(211) = "2743" : BlackPlayers(211) = "Topalov, Veselin   G#211" : BlackElos(211) = "2813" : Each_Game_Result(211) = "1-0"

FilePGNs(211) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. g3 dxc4 5. Bg2 Bb4+ 6. Bd2 a5 7. Qc2 Bxd2+ 8. Qxd2  c6 9. a4 b5 10. axb5 cxb5 11. Qg5 O-O 12. Qxb5 Ba6  13. Qa4 Qb6 14. O-O Qxb2 15. Nbd2 Bb5 16. Nxc4 Bxa4 17. Nxb2 Bb5 18. Ne5 Ra7 19. Bf3 Nbd7 20. Nec4 Rb8 21. Rfb1 g5  22. e3 g4 23. Bd1 Bc6 24. Rc1 Be4 25. Na4 Rb4 26. Nd6 Bf3  27. Bxf3 gxf3 28. Nc8 Ra8 29. Ne7+ Kg7 30. Nc6 Rb3 31. Nc5 Rb5 32. h3  Nxc5 33. Rxc5 Rb2 34. Rg5+ Kh6  35. Rgxa5 Rxa5 36. Nxa5 Ne4 37. Rf1 Nd2 38. Rc1 Ne4 39. Rf1 f6 40. Nc6 Nd2 41. Rd1 Ne4 42. Rf1 Kg6 43. Nd8 Rb6 44. Rc1 h5 45. Ra1 h4 46. gxh4 Kh5 47. Ra2 Kxh4 48. Kh2 Kh5 49. Rc2 Kh6 50. Ra2 Kg6 51. Rc2 Kf5 52. Ra2 Rb5 53. Nc6 Rb7 54. Ra5+ Kg6 55. Ra2 Kh5  56. d5  e5 57. Ra4 f5  58. Nxe5 Rb2 59. Nd3 Rb7 60. Rd4 Rb6 61. d6 Nxd6 62. Kg3 Ne4+ 63. Kxf3 Kg5 64. h4+  Kf6 65. Rd5 Nc3 66. Rd8 Rb1 67. Rf8+ Ke6 68. Nf4+ Ke5 69. Re8+ Kf6 70. Nh5+ Kg6 71. Ng3 Rb2 72. h5+ Kf7 73. Re5 Nd1 74. Ne2 Kf6 75. Rd5 1-0 "

; sample game 212
EventSites(212) = "World Championship  Elista" : GameDates(212) = "20060924" : WhitePlayers(212) = "Topalov, Veselin   G#212" : WhiteElos(212) = "2813" : BlackPlayers(212) = "Kramnik, Vladimir   G#212" : BlackElos(212) = "2743" : Each_Game_Result(212) = "0-1"

FilePGNs(212) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. Nf3 dxc4 5. a4 Bf5 6. e3 e6 7. Bxc4 Bb4 8. O-O Nbd7 9. Qe2 Bg6 10. e4 O-O 11. Bd3 Bh5 12. e5 Nd5 13. Nxd5 cxd5 14. Qe3 Bg6 15. Ng5 Re8 16. f4 Bxd3  17. Qxd3 f5 18. Be3 Nf8 19. Kh1 Rc8  20. g4 Qd7 21. Rg1 Be7 22. Nf3 Rc4 23. Rg2 fxg4 24. Rxg4 Rxa4 25. Rag1 g6 26. h4 Rb4  27. h5 Qb5 28. Qc2  Rxb2  29. hxg6  h5  30. g7  hxg4 31. gxf8=Q+ Bxf8  32. Qg6+  Bg7 33. f5  Re7 34. f6 Qe2 35. Qxg4 Rf7 36. Rc1  Rc2 37. Rxc2 Qd1+  38. Kg2 Qxc2+ 39. Kg3 Qe4 40. Bf4  Qf5 41. Qxf5 exf5 42. Bg5  a5  43. Kf4 a4 44. Kxf5 a3 45. Bc1 Bf8 46. e6 Rc7 47. Bxa3 Bxa3 48. Ke5 Rc1 49. Ng5 Rf1 50. e7 Re1+ 51. Kxd5 Bxe7 52. fxe7 Rxe7 53. Kd6 Re1 54. d5 Kf8 55. Ne6+ Ke8 56. Nc7+ Kd8 57. Ne6+ Kc8 58. Ke7 Rh1  59. Ng5  b5 60. d6 Rd1 61. Ne6 b4 62. Nc5 Re1+ 63. Kf6 Re3 0-1 "

; sample game 213
EventSites(213) = "EU-Cup 22nd  Fuegen" : GameDates(213) = "20061008" : WhitePlayers(213) = "Kovachev, Daniel Jakobsen   G#213" : WhiteElos(213) = "2132" : BlackPlayers(213) = "Schandorff, Lars   G#213" : BlackElos(213) = "2534" : Each_Game_Result(213) = "0-1"

FilePGNs(213) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Na5 10. Bc2 c5 11. d4 Nd7 12. Nbd2 exd4  13. cxd4 Nc6 14. d5 Nce5 15. Nxe5 Nxe5 16. f4 Ng6 17. Nf3 Bh4 18. Nxh4 Qxh4 19. f5 Ne5 20. Rf1 Bd7 21. Bf4 Qe7 22. Kh2 a5 23. Qh5 f6 24. g4  g6  25. fxg6 hxg6 26. Qh6 Bxg4  27. Kh1 Bh5 28. Bg3 Qh7 29. Qe3 Bg4 30. Rf2 Qxh3+ 31. Kg1 Nc4  32. Qc3 b4 33. Qb3 a4 34. Qxc4 Qxg3+ 35. Kf1 Ra7 36. Qd3 Qe5 37. Rg2 Bh5 38. Bd1 Rh7 39. Bxa4 f5 40. exf5 Rxf5+ 41. Kg1 Bf3  42. Rxg6+ Kh8 0-1 "

; sample game 214
EventSites(214) = "EU-Cup 22nd  Fuegen" : GameDates(214) = "20061009" : WhitePlayers(214) = "Agrest, Evgenij   G#214" : WhiteElos(214) = "2557" : BlackPlayers(214) = "Morozevich, Alexander   G#214" : BlackElos(214) = "2747" : Each_Game_Result(214) = "0-1"

FilePGNs(214) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. Nf3 d6 5. Bg5 h6 6. Bh4 g5 7. Bg3 Nh5 8. e3 e6 9. Nd2 Nxg3 10. hxg3 Nd7 11. Qa4   O-O 12. Qc2 c5 13. d5 Nb6 14. Bd3 exd5 15. cxd5 f5 16. a4 f4  17. gxf4 gxf4 18. exf4 Rxf4 19. Bh7+ Kh8 20. Be4 Qg5 21. Ne2 Rf5  22. Nf3 Qf6 23. Ng3  Rf4 24. a5 Nd7  25. O-O-O Nf8 26. Rd2 Bg4 27. Nh2  Re8 28. f3 Bd7 29. Nh5 Qg5 30. Nxg7  Kxg7 31. g3 Rf7 32. f4 Qf6 33. Re2 Rfe7 34. Rhe1 b5 35. Qd2 b4 36. Bd3  Rxe2 37. Rxe2 Qd4  38. Rxe8 Bxe8  39. Qe2 Bf7 40. Bc4 Qg1+ 41. Nf1 Ng6 42. Qe4 h5 43. Be2 Qf2 44. Ne3 Qe1+ 45. Bd1 Kf8  46. Qf3 h4 47. gxh4 Qxh4 48. Ng4  Ne7 49. Ne3 Qf6 50. Qe4 Bg6 51. Qc4 Qh4 52. Qf1 Be4 53. Bb3 Qg3 54. Kd2 Nf5 55. Qe2 Qxf4 56. Bc4 Ke7 57. Qe1 Kf6 58. b3 Qxe3+ 0-1 "

; sample game 215
EventSites(215) = "EU-Cup 22nd  Fuegen" : GameDates(215) = "20061010" : WhitePlayers(215) = "Berg, Emanuel   G#215" : WhiteElos(215) = "2582" : BlackPlayers(215) = "Berelovich, Aleksandar   G#215" : BlackElos(215) = "2551" : Each_Game_Result(215) = "1-0"

FilePGNs(215) = "1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Bxc3+ 6. bxc3 Qc7 7. Qg4 f5 8. Qg3 Ne7  9. Qxg7 Rg8 10. Qxh7 cxd4 11. Ne2 Nbc6 12. h4 dxc3 13. Bg5 Qxe5 14. Qh5+ Ng6 15. f4 Qe4  16. Rh3 d4  17. Qh7  Nge7 18. O-O-O  e5 19. Nxc3  dxc3 20. Bb5 Rxg5  21. hxg5 Be6 22. Qg7 Bd5  23. Rxc3  exf4  24. Qh8+ Bg8 25. Bc4 Kf8 26. Rd6 Rd8 27. Qh6+ Ke8 28. Qh5+ 1-0 "

; sample game 216
EventSites(216) = "EU-Cup 22nd  Fuegen" : GameDates(216) = "20061010" : WhitePlayers(216) = "Mamedyarov, Shakhriyar   G#216" : WhiteElos(216) = "2728" : BlackPlayers(216) = "Areshchenko, Alexander   G#216" : BlackElos(216) = "2640" : Each_Game_Result(216) = "1-0"

FilePGNs(216) = "1. d4 d5 2. c4 c6 3. e3 Nf6 4. Nf3 e6 5. Nbd2 Nbd7 6. Bd3 Bd6 7. O-O O-O 8. e4 e5 9. exd5 cxd5 10. cxd5 exd4 11. Ne4 Nxe4 12. Bxe4 Nc5 13. Bc2 d3  14. Bxd3 Nxd3 15. Qxd3 Qf6 16. Re1  Bf5 17. Qb3 Qg6 18. Ne5 Bxe5 19. Rxe5 Rae8 20. Bf4 Rxe5 21. Bxe5 Re8  22. Qxb7 f6 23. Bg3 Bb1 24. h4 Qd3 25. Kh2 Qf1 26. f4 Re3 27. d6 Rxg3 28. Qb8+ Kf7 29. Qxa7+ Ke6 30. Kxg3 g5 31. Qe3+ 1-0 "

; sample game 217
EventSites(217) = "EU-Cup 22nd  Fuegen" : GameDates(217) = "20061011" : WhitePlayers(217) = "Radjabov, Teimour   G#217" : WhiteElos(217) = "2729" : BlackPlayers(217) = "Morozevich, Alexander   G#217" : BlackElos(217) = "2747" : Each_Game_Result(217) = "1-0"

FilePGNs(217) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 d6 6. Be3 Nf6 7. f4 Be7 8. Qf3 e5 9. Nxc6 bxc6 10. f5 Qa5 11. Bc4 Rb8 12. Bd2  Rxb2 13. Bb3  Rxb3 14. cxb3 Qa6  15. g4  h6 16. Qg3  Bb7 17. O-O-O c5 18. Rhe1 c4 19. Kb2   Nd7 20. b4 Qb6 21. Ka1 Qd8 22. Qe3 Nb6 23. Qg1 O-O 24. g5  Bxg5 25. Bxg5 hxg5 26. Qe3 f6 27. h4  gxh4 28. Rh1  d5 29. exd5 Qd7 30. Qf3 Bc8 31. Rdf1  Qe7 32. a3  e4 33. Qf4 Rd8 34. Rfg1 Qe5 35. Qxe5 fxe5 36. f6 Kf7 37. fxg7 h3 38. Nxe4 Nxd5 39. Nd6+ Kg8 40. Nxc8 Rxc8 41. Rxh3 Kf7 42. g8=Q+ Rxg8 43. Rxg8 Kxg8 44. Rh5 1-0 "

; sample game 218
EventSites(218) = "EU-Cup 22nd  Fuegen" : GameDates(218) = "20061011" : WhitePlayers(218) = "Shirov, Alexei   G#218" : WhiteElos(218) = "2720" : BlackPlayers(218) = "Roiz, Michael   G#218" : BlackElos(218) = "2611" : Each_Game_Result(218) = "1-0"

FilePGNs(218) = "1. e4 c5 2. Nf3 Nc6 3. Nc3 e5 4. Bc4 Be7 5. d3 d6 6. Nd2 Bg5 7. h4 Bh6 8. Qh5  Qd7 9. Nd5 Rb8 10. c3 b5 11. Bb3 Nce7 12. Ne3 Nc6  13. Ndf1 Nf6 14. Qf3 O-O 15. g4  Bxe3 16. Nxe3 Ne7 17. g5 Ne8 18. h5  Bb7 19. Ng4 c4  20. h6  Qf5  21. Qh3 Qg6 22. hxg7 Kxg7 23. Qe3 h5  24. Bc2  hxg4 25. Rh6 Rh8 26. Rxg6+ Nxg6 27. Qxa7 Nc7 28. Be3 b4 29. dxc4 bxc3 30. bxc3 g3 31. O-O-O g2 32. f4  exf4 33. Bd4+ Ne5 34. Qa5 Ne6 35. Bxe5+ dxe5 36. Qxe5+ Kg6 37. Qf5+ Kh5 38. Rg1 1-0 "

; sample game 219
EventSites(219) = "EU-Cup 22nd  Fuegen" : GameDates(219) = "20061013" : WhitePlayers(219) = "Berg, Emanuel   G#219" : WhiteElos(219) = "2582" : BlackPlayers(219) = "Zhang Pengxiang   G#219" : BlackElos(219) = "2636" : Each_Game_Result(219) = "1-0"

FilePGNs(219) = "1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Bxc3+ 6. bxc3 Qa5 7. Bd2 Qa4 8. Qg4 g6 9. Qd1 Nc6 10. Rb1  a6 11. Nf3 b5 12. h4 h6 13. dxc5  Nge7 14. Bd3 Nf5 15. Rb4  Qxa3 16. O-O Bd7 17. Qe2 d4  18. Rxd4 Ncxd4 19. cxd4 Bc6 20. Be4 Rc8 21. Bxc6+ Rxc6 22. Qe4 Ne7 23. Nh2  h5 24. Bg5 Nd5 25. Bf6 Rf8 26. Nf3 Qc3 27. Ng5 Qc4 28. Rd1 Kd7 29. Qf3 Qxc2 30. Bg7 Re8 31. Ne4  Kc7 32. Kh2 Re7 33. Rd2 Qc1 34. Bh6 Rd7 35. Nd6 Qb1 36. Rd1 Qc2 37. Rd2 Qc3 38. Rd3 Qb2 39. Rd2  Qb4  40. Nxf7 Ne7 41. Nd6 Nf5 42. Bg5  a5 43. Rd3 Nxd6 44. exd6+ Kb7 45. Qh3 Rdxd6 46. Bd2  Qc4 47. cxd6 b4 48. Qf3 Qd5 49. Qxd5 exd5 50. Bf4 Rc8 51. Rd1  Rd8 52. Rc1 Kb6 53. Rc5 b3 54. Bd2  b2 55. Bxa5+ Ka6 56. Bxd8 b1=Q 57. Rc6+ Ka7 58. d7 Qf5 59. Bb6+ Kb7 60. d8=Q Qf4+ 61. Kg1 Kxc6 62. g3 1-0 "

; sample game 220
EventSites(220) = "EU-Cup 22nd  Fuegen" : GameDates(220) = "20061013" : WhitePlayers(220) = "Ivanchuk, Vassily   G#220" : WhiteElos(220) = "2741" : BlackPlayers(220) = "Prusikin, Michael   G#220" : BlackElos(220) = "2560" : Each_Game_Result(220) = "1-0"

FilePGNs(220) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. f3 d5 5. a3 Bxc3+ 6. bxc3 c5 7. cxd5 Nxd5 8. dxc5 Qa5 9. e4 Ne7 10. Be3 O-O 11. Qb3 Qc7 12. a4 Nd7 13. a5   Nc6 14. Bb5 Nxa5 15. Qa3 b6 16. Ne2 Bb7 17. O-O Rfc8 18. cxb6 axb6 19. Qe7 Nc5 20. Qxc7 Rxc7 21. Rfd1  Rcc8 22. Ra2 Bc6  23. Bxc5 Bxb5  24. Bxb6 Bxe2 25. Rxe2 Nc4 26. Bf2  h6 27. h3 Rc6 28. Be1 g5 29. Rb1 Kg7 30. Bg3 Kg6 31. Kh2 Ra3 32. Be1 Rc8 33. Rc2 Rc6 34. Bf2 Ra8 35. Rb4 Ra1 36. Bd4 e5 37. Bf2 Rc7 38. Re2 Rc1 39. Be1 Ra1 40. Rb8 Ra3 41. h4 Ra1 42. Kh3 f6 43. Kg4 Ra6 44. Rg8+ Kf7 45. Rd8 Kg6 46. Bf2 Ra3 47. Rc2 Ra1 48. h5+ Kf7 49. Rd5 Ke6 50. Rd8 Kf7 51. Rd5 Ke6 52. Rd8 Kf7 53. Rh8 Kg7 54. Rb8 Kf7 55. Rd8 Ra6 56. Rd1 Ke6 57. Rb1 Kf7 58. Bg1 Ra4 59. Bf2 Ra6 60. Kh3 Ra4 61. Rcc1 Ra2 62. Bg1 Na3  63. Rb8 Nc4 64. Rd1  Rc2  65. Rh8 Kg7 66. Rdd8 Rc1 67. Rdg8+ Kf7 68. Rg6 Ke6 69. Kh2 Nd2 70. Rhxh6 R7xc3 71. Rxf6+ Ke7 1-0 "

; sample game 221
EventSites(221) = "EU-Cup 22nd  Fuegen" : GameDates(221) = "20061014" : WhitePlayers(221) = "Dreev, Alexey   G#221" : WhiteElos(221) = "2655" : BlackPlayers(221) = "Schandorff, Lars   G#221" : BlackElos(221) = "2534" : Each_Game_Result(221) = "1-0"

FilePGNs(221) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Bb4 5. Qa4+ Nc6 6. a3 Bxc3+ 7. bxc3 O-O 8. Bg5 h6 9. Bxf6 Qxf6 10. e3 Rd8 11. Bd3 Bd7 12. cxd5 exd5 13. O-O  b6 14. Qc2 Na5  15. Ne5 c5 16. f4 c4 17. Bh7+  Kh8 18. Rf3  Nb7 19. Qb1  Nd6 20. Bc2 Rac8 21. g4  Qe7 22. Qe1 Kg8 23. Qg3 f6 24. Ng6 Qe8 25. f5 Nb5 26. Qe1 Qf7 27. a4 Nd6 28. Qg3 Be8 29. h4 Qc7 30. Nf4 Nf7 31. e4 Bc6 32. e5 fxe5 33. Ne6 Qd6 34. dxe5 Qxe5 35. Nxd8 Rxd8 36. Re1 Qxg3+ 37. Rxg3 d4 38. cxd4 Rxd4 39. Kf2 Rd2+ 40. Re2 Rd8 41. Rge3 Kf8 42. Re7 Bd7 43. Kg3 a6 44. Kf4 b5 45. g5 hxg5+ 46. hxg5 Be8 47. g6 Nd6 48. f6 gxf6 49. g7+ Kg8 50. Bh7+ 1-0 "

; sample game 222
EventSites(222) = "EU-Cup 22nd  Fuegen" : GameDates(222) = "20061014" : WhitePlayers(222) = "Grischuk, Alexander   G#222" : WhiteElos(222) = "2710" : BlackPlayers(222) = "Babula, Vlastimil   G#222" : BlackElos(222) = "2584" : Each_Game_Result(222) = "1/2-1/2"

FilePGNs(222) = "1. d4 Nf6 2. c4 e6 3. Nf3 Bb4+ 4. Nbd2 O-O 5. a3 Be7 6. e4 d5 7. e5 Nfd7 8. b4 a5 9. b5 c5 10. Bb2 b6 11. a4 Bb7 12. Be2 cxd4 13. O-O d3 14. Bxd3 Nc5 15. Bc2 Nbd7 16. Re1 Rc8 17. Nd4  g6 18. Qg4 Bg5 19. N2f3 Bh6 20. Nc6  Bxc6 21. bxc6 Nb8 22. Rad1 Nxc6 23. cxd5 exd5 24. e6 f5  25. Qg3  Ne4 26. Bxe4 fxe4 27. Ne5  Bg7  28. Rxe4  dxe4  29. Rxd8 Rfxd8 30. Qb3  Ne7  31. h3  Rd2  32. Nc4  Rxc4  33. Qxc4 Bxb2 34. Qxe4 Rd6  35. Qf3  Rxe6 36. Qb3 Kf7 37. Qxb2 h5  38. Qb3 Kf6 39. g3 Rd6 40. Kg2 Re6 41. Qc3+ Kf7 42. Qc4 Kf6 43. Qf4+ Kg7 44. g4  hxg4 45. hxg4 Rc6  46. Kg3 Kg8 47. f3 Kg7 48. Qd4+ Kf7 49. f4 Kf8 50. Qh8+ Kf7 51. Kf3 Re6 52. Qd4 Kf8 53. Qc4 Rc6 54. Qb3 Rf6 55. Ke4 Kg7 56. Qb2 Kf7 57. Qd4 Re6+ 58. Kd3 Rc6 59. Qh8 Rf6 60. Qh7+ Ke8 61. Qh6 Rc6 62. Qg7 Rc5 63. Ke2 Rc6 64. Kf3 Re6 65. Kg3 Rc6 66. Kh4 Rd6 67. Kg5 Rc6 68. Kh6 Re6 69. Kh7 Rc6 70. Qh8+ Kf7 71. Qd4 Kf8 72. f5  gxf5  73. Qh8+ Kf7 74. Qg7+ Ke8 75. Qh8+ Kf7 76. Qg7+ 1/2-1/2 "

; sample game 223
EventSites(223) = "EU-Cup 22nd  Fuegen" : GameDates(223) = "20061014" : WhitePlayers(223) = "Kasimdzhanov, Rustam   G#223" : WhiteElos(223) = "2672" : BlackPlayers(223) = "Naiditsch, Arkadij   G#223" : BlackElos(223) = "2676" : Each_Game_Result(223) = "1-0"

FilePGNs(223) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 O-O 5. a3 Bxc3+ 6. Qxc3 b5 7. cxb5 c6 8. Qd3   d5 9. Bg5 cxb5 10. Nf3 a5 11. e3 Ba6 12. b4 axb4 13. axb4 Nc6  14. Rb1 Qd6 15. Bxf6 gxf6 16. Qd2 Rfb8 17. Bd3 Bc8 18. O-O Ra4 19. e4  dxe4 20. Bxe4 Ne7 21. Rfc1  Kg7 22. Rc5 Nd5 23. Bxd5 exd5 24. Nh4  Bd7 25. Rc3  Kh8 26. Rg3 Rg8 27. Qh6 Ra6  28. Rxg8+ Kxg8 29. h3  Qe7  30. Rb3  1-0 "

; sample game 224
EventSites(224) = "Bundesliga 0607  Germany" : GameDates(224) = "20070331" : WhitePlayers(224) = "Areshchenko, Alexander   G#224" : WhiteElos(224) = "2644" : BlackPlayers(224) = "Shirov, Alexei   G#224" : BlackElos(224) = "2720" : Each_Game_Result(224) = "0-1"

FilePGNs(224) = "1. e4 e5 2. Bc4 Nf6 3. d3 c6  4. Nf3 d5 5. Bb3 Bd6 6. exd5  Nxd5 7. O-O O-O 8. Re1 Bg4  9. h3 Bh5 10. Nbd2  Nd7 11. Ne4 Bc7 12. Bd2 Re8 13. a3 Nf8  14. Ba2 h6 15. Ng3 Bg6 16. Qc1  a5 17. b4  Nf4  18. d4  N4e6  19. Nxe5  Nxd4 20. Nxg6 Bxg3 21. Be3  Bc7  22. Bxd4  Nxg6  23. Rxe8+ Qxe8 24. Qd2 axb4 25. axb4 Nf4 26. Re1  Qd8 27. g3 Nxh3+ 28. Kg2 Rxa2 29. Kxh3 Bb6 30. Re4 f5 31. Rh4 Qd5 32. Kh2  Bd8 0-1 "

; sample game 225
EventSites(225) = "Moscow Tal mem  Moscow" : GameDates(225) = "20061110" : WhitePlayers(225) = "Leko, Peter   G#225" : WhiteElos(225) = "2741" : BlackPlayers(225) = "Gelfand, Boris   G#225" : BlackElos(225) = "2734" : Each_Game_Result(225) = "1-0"

FilePGNs(225) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 dxc4 5. a4 Bf5 6. e3 e6 7. Bxc4 Bb4 8. O-O Nbd7 9. Qe2 Bg4 10. h3 Bxf3 11. Qxf3 O-O 12. Rd1 Rc8 13. e4 e5 14. Be3 Qa5 15. Qf5  exd4 16. Qxa5 Bxa5 17. Bxd4 Rfe8 18. f3 a6 19. Kf2 Ne5 20. Be2 Rcd8 21. Be3  h5  22. g4  hxg4 23. hxg4 Ng6 24. Rxd8  Rxd8 25. Kg3  Re8 26. Rd1  Bc7+ 27. Kf2 Re7 28. Bf1  Nf4  29. g5  Nh7  30. Bxf4  Bxf4 31. Rd8+ Nf8 32. g6  b5  33. Bh3  fxg6 34. Ra8 bxa4  35. Bf1  Kf7 36. Bc4+ Ne6 37. Ne2  Bd6 38. f4 Kf6  39. e5+ Bxe5 40. fxe5+ Kxe5 41. Bxe6  Kxe6 42. Rxa6 Rb7 43. Nf4+  Ke5 44. Ke3 c5 45. Nd3+ Kd5 46. Ra5  Kd6 47. Rxa4 Kd5 48. Ra5 Kd6 49. Ra4 Kd5 50. Kd2 c4 51. Nb4+ Ke4 52. Kc3 g5 53. Nc6 g4 54. Rxc4+ Kf5 55. Nd4+ Kf4 56. Nc6+ Kf5 57. Nb4 g3  58. Nd5  Ke5 59. Ne3 Rf7 60. Rg4 Rc7+ 61. Nc4+ Kf5 62. Rxg3 g5 63. Rf3+ Ke4 64. Rf7 Rc8 65. Rg7 Kf4 66. Kd3 Rd8+ 67. Ke2 Re8+ 68. Kf2 Rb8 69. Rf7+ Ke4 70. Rd7 g4 71. b3 Rb4 72. Nd2+ Kf4 73. Rd3 Kf5 74. Kg3 Ke5 75. Nc4+ Ke4 76. Re3+ Kd4 77. Kxg4 Rb8 78. Kf3 Rh8 79. Ke2 1-0 "

; sample game 226
EventSites(226) = "Moscow Tal mem  Moscow" : GameDates(226) = "20061110" : WhitePlayers(226) = "Shirov, Alexei   G#226" : WhiteElos(226) = "2720" : BlackPlayers(226) = "Aronian, Levon   G#226" : BlackElos(226) = "2741" : Each_Game_Result(226) = "0-1"

FilePGNs(226) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. c3 d5 9. exd5 Nxd5 10. Nxe5 Nxe5 11. Rxe5 c6 12. d4 Bd6 13. Re1 Qh4 14. g3 Qh3 15. Re4 g5 16. Qf1 Qh5 17. Nd2 Bf5 18. f3 Nf6 19. a4 Nxe4 20. Nxe4 Qg6 21. Nxd6 Qxd6 22. Bxg5 Qg6  23. Qc1 Bd3 24. axb5 axb5 25. Rxa8 Rxa8 26. Kf2 Bc4 27. Bxc4 bxc4 28. g4 Re8 29. Bf4 Qd3 30. Kg3 Qe2 31. Qb1 Qe1+ 32. Qxe1 Rxe1 33. Bd6 Rg1+ 34. Kf2 Rb1 35. Ba3 Kg7 36. Kg3 Kg6 37. h3 h5 38. Kh4  Rg1  39. Bc5 Rg2 40. Ba3 f6 41. gxh5+ Kf5 42. f4 Rg8 43. Bd6 Ke6 44. h6  Kxd6 45. Kh5 f5 46. h7 Rh8 47. Kg6 Ke7 48. Kg7 Ke8 49. Kg6 Kf8 50. h4 Ke7 51. Kg7 Ke8 52. Kg6 Kf8 53. h5 Ke7 54. Kg7 Ke8 55. Kg6 Kf8 56. h6 Ke8 57. Kf6 Rxh7 58. Kg6 Rf7 0-1 "

; sample game 227
EventSites(227) = "Bonn Man-Machine  Bonn" : GameDates(227) = "20061125" : WhitePlayers(227) = "Kramnik, Vladimir   G#227" : WhiteElos(227) = "2750" : BlackPlayers(227) = "Comp Deep Fritz 10   G#227" : BlackElos(227) = "2741" : Each_Game_Result(227) = "1/2-1/2"

FilePGNs(227) = "1. d4 Nf6 2. c4 e6 3. g3 d5 4. Bg2 dxc4  5. Qa4+ Nbd7 6. Qxc4 a6 7. Qd3 c5 8. dxc5 Bxc5 9. Nf3 O-O 10. O-O Qe7 11. Nc3 b6 12. Ne4  Nxe4 13. Qxe4 Nf6 14. Qh4  Bb7 15. Bg5 Rfd8 16. Bxf6 Qxf6 17. Qxf6 gxf6 18. Rfd1 Kf8  19. Ne1  Bxg2 20. Kxg2 f5 21. Rxd8+ Rxd8 22. Nd3 Bd4 23. Rc1 e5  24. Rc2 Rd5  25. Nb4  Rb5 26. Nxa6 Rxb2 27. Rxb2 Bxb2 28. Nb4 Kg7 29. Nd5 Bd4 30. a4  Bc5 31. h3 f6 32. f3 Kg6 33. e4  h5  34. g4 hxg4 35. hxg4 fxe4 36. fxe4 Kg5 37. Kf3 Kg6 38. Ke2 Kg5 39. Kd3 Bg1  40. Kc4 Bf2 41. Kb5 Kxg4 42. Nxf6+ Kf3 43. Kc6 Bh4 44. Nd7 Kxe4 45. Kxb6 Be1 46. Kc6 Kf5 47. Nxe5 Kxe5 1/2-1/2 "

; sample game 228
EventSites(228) = "Bonn Man-Machine  Bonn" : GameDates(228) = "20061127" : WhitePlayers(228) = "Comp Deep Fritz 10   G#228" : WhiteElos(228) = "2750" : BlackPlayers(228) = "Kramnik, Vladimir   G#228" : BlackElos(228) = "2750" : Each_Game_Result(228) = "1-0"

FilePGNs(228) = "1. d4 d5 2. c4 dxc4 3. e4 b5 4. a4 c6 5. Nc3 b4 6. Na2 Nf6 7. e5 Nd5 8. Bxc4 e6 9. Nf3 a5 10. Bg5 Qb6 11. Nc1 Ba6 12. Qe2 h6 13. Be3 Bxc4 14. Qxc4 Nd7 15. Nb3 Be7 16. Rc1 O-O 17. O-O Rfc8 18. Qe2 c5 19. Nfd2 Qc6 20. Qh5 Qxa4 21. Nxc5 Nxc5 22. dxc5 Nxe3  23. fxe3 Bxc5 24. Qxf7+ Kh8 25. Qf3 Rf8 26. Qe4 Qd7  27. Nb3 Bb6 28. Rfd1 Qf7 29. Rf1 Qa7  30. Rxf8+ Rxf8 31. Nd4 a4 32. Nxe6 Bxe3+ 33. Kh1 Bxc1 34. Nxf8 Qe3  35. Qh7# 1-0 "

; sample game 229
EventSites(229) = "Bonn Man-Machine  Bonn" : GameDates(229) = "20061129" : WhitePlayers(229) = "Kramnik, Vladimir   G#229" : WhiteElos(229) = "2750" : BlackPlayers(229) = "Comp Deep Fritz 10   G#229" : BlackElos(229) = "2750" : Each_Game_Result(229) = "1/2-1/2"

FilePGNs(229) = "1. d4 Nf6 2. c4 e6 3. g3 d5 4. Bg2 dxc4 5. Qa4+ Nbd7 6. Qxc4 a6 7. Qc2 c5 8. Nf3 b6 9. Ne5 Nd5 10. Nc3 Bb7 11. Nxd5 Bxd5 12. Bxd5 exd5 13. O-O Nxe5 14. dxe5 Qc8 15. Rd1 Qe6 16. Qd3 Be7  17. Qxd5 Rd8 18. Qb3 Rxd1+ 19. Qxd1 O-O 20. Qb3 c4  21. Qc3 f6 22. b3 Rc8 23. Bb2 b5 24. Qe3 fxe5 25. bxc4 Rxc4 26. Bxe5 h6 27. Rd1 Rc2 28. Qb3 Qxb3 29. axb3 Rxe2 30. Bd6 Bf6 31. Bc5 a5 32. Bd4 Be7 33. Bc3 a4 34. bxa4 bxa4 35. Rd7 Bf8 36. Rd8 Kf7 37. Ra8 a3 38. Rxf8+  Kxf8 39. Bb4+ Kf7 40. Bxa3 Ra2 41. Bc5 g6 42. h4 Kf6 43. Be3 h5 44. Kg2 1/2-1/2 "

; sample game 230
EventSites(230) = "Bonn Man-Machine  Bonn" : GameDates(230) = "20061201" : WhitePlayers(230) = "Comp Deep Fritz 10   G#230" : WhiteElos(230) = "2750" : BlackPlayers(230) = "Kramnik, Vladimir   G#230" : BlackElos(230) = "2750" : Each_Game_Result(230) = "1/2-1/2"

FilePGNs(230) = "1. e4 e5 2. Nf3 Nf6 3. d4 Nxe4 4. Bd3 d5 5. Nxe5 Nd7 6. Nxd7 Bxd7 7. O-O Bd6 8. Qh5 Qf6 9. Nc3 Qxd4 10. Nxd5 Bc6 11. Ne3 g6 12. Qh3 Ng5 13. Qg4 Qf4 14. Qxf4 Bxf4 15. Nc4 Ne6 16. Bxf4 Nxf4 17. Rfe1+ Kf8 18. Bf1 Bb5 19. a4 Ba6 20. b4 Bxc4 21. Bxc4 Rd8 22. Re4 Nh5 23. Rae1 Rd7 24. h3 Ng7 25. Re5 Nf5 26. Bb5 c6 27. Bd3 Nd6 28. g4 Kg7 29. f4 Rhd8 30. Kg2 Nc8 31. a5 Rd4 32. R5e4 Kf8 33. Kf3 h6 34. Rxd4 Rxd4 35. Re4 Rd6 36. Ke3 g5 37. Rd4 Ke7 38. c4 Rxd4 39. Kxd4 gxf4 40. Ke4 Kf6 41. Kxf4 Ne7 42. Be4 b6 43. c5 bxc5 44. bxc5 Ng6+ 45. Ke3 Ne7 46. Kd4 Ke6 47. Bf3 f5 48. Bd1 Kf6 49. Bc2 fxg4 50. hxg4 Ke6 51. Bb1 Kf6 52. Be4 Ke6 53. Bh1 Kf6 54. Bf3 Ke6 1/2-1/2 "

; sample game 231
EventSites(231) = "Bonn Man-Machine  Bonn" : GameDates(231) = "20061203" : WhitePlayers(231) = "Kramnik, Vladimir   G#231" : WhiteElos(231) = "2750" : BlackPlayers(231) = "Comp Deep Fritz 10   G#231" : BlackElos(231) = "2750" : Each_Game_Result(231) = "1/2-1/2"

FilePGNs(231) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Bb4 5. e3 O-O 6. a3 Bxc3+ 7. bxc3 c5 8. Bb2 Nc6 9. Rc1 Re8 10. Bd3 dxc4 11. Bxc4 e5 12. dxe5 Qxd1+ 13. Rxd1 Nxe5 14. Nxe5 Rxe5 15. Be2 Bd7 16. c4 Re7 17. h4 Ne4  18. h5 Ba4 19. Rd3 b5  20. cxb5 Bxb5 21. Rd1 Bxe2 22. Kxe2 Rb8 23. Ba1  f5 24. Rd5  Rb3 25. Rxf5 Rxa3 26. Rb1 Re8 27. Rf4 Ra2+ 28. Ke1 h6 29. Rg4 g5  30. hxg6 Nxf2 31. Rh4 Rf8 32. Kf1  Nh3+ 33. Ke1 Nf2 34. Kf1 Nh3+ 35. Ke1 1/2-1/2 "

; sample game 232
EventSites(232) = "RUS-ch superfinal  Moscow" : GameDates(232) = "20061213" : WhitePlayers(232) = "Inarkiev, Ernesto   G#232" : WhiteElos(232) = "2629" : BlackPlayers(232) = "Nepomniachtchi, Ian   G#232" : BlackElos(232) = "2545" : Each_Game_Result(232) = "1-0"

FilePGNs(232) = "1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. e5 Nfd7 5. f4 c5 6. Nf3 Nc6 7. Be3 cxd4 8. Nxd4 Bc5 9. Qd2 O-O 10. O-O-O a6 11. Kb1 Nxd4 12. Bxd4 b5 13. Qe3 Bxd4 14. Rxd4 Qe7  15. Bd3 b4 16. Ne4  a5 17. Nd6 f5 18. g4  fxg4 19. Be2  Nc5  20. Bxg4 Nb7  21. Nxb7 Bxb7  22. Rg1  Rf7  23. Qh3 Re8  24. f5  Qc5  25. Rdd1  Rc7 26. f6  Qxc2+ 27. Ka1 Bc8 28. Bh5   Rd8 29. Qh4 Rf8 30. f7+ Rfxf7 31. Bxf7+ Kxf7 32. Qg5 h6 33. Qd8 Ba6 34. Rxg7+  Kxg7 35. Rg1+ 1-0 "

; sample game 233
EventSites(233) = "Corus  Wijk aan Zee" : GameDates(233) = "20070116" : WhitePlayers(233) = "Kramnik, Vladimir   G#233" : WhiteElos(233) = "2766" : BlackPlayers(233) = "Navara, David   G#233" : BlackElos(233) = "2719" : Each_Game_Result(233) = "1/2-1/2"

FilePGNs(233) = "1. Nf3 Nf6 2. c4 c5 3. g3 Nc6 4. Nc3 d5 5. d4 cxd4 6. Nxd4 dxc4 7. Nxc6 Qxd1+ 8. Nxd1 bxc6 9. Bg2 Nd5 10. Ne3 e6 11. Nxc4 Ba6 12. Na5 Rc8 13. Bd2 Be7 14. Rc1 c5 15. b3 O-O 16. O-O Rfd8 17. Bf3 Kf8 18. Rfd1 Ke8  19. Be1  Rd7 20. e3 Bf6 21. Nc4 Ke7 22. Ba5  Bb5 23. Be2 Nb4 24. Nd6  Rxd6 25. Bxb5 Nxa2 26. Rxd6 Nxc1 27. Rd7+ Kf8 28. Rxa7  Bd8  29. Bc4  Rb8  30. Bxd8 Rxd8 31. Ra1  Rd1+ 32. Kg2 g5  33. Kf3 h5 34. h3 Ke7 35. Ra5 f5 36. Rxc5 g4+ 37. hxg4 hxg4+ 38. Kf4 Kf6  39. e4 Rd4 40. Ke3 Rxe4+ 41. Kd2 Na2  42. Rb5  f4  43. Ra5  Nb4 44. Ra4 fxg3 45. fxg3 Nc6 46. Bb5 Nb4 47. Bc4 Nc6 48. Bb5 Nb4 49. Bc6  Rd4+ 50. Kc3 Rd6 51. Rxb4 Rxc6+ 52. Rc4 Rd6 53. b4 e5 54. b5 Kf5 55. Rb4 e4 56. Rd4  Rh6  57. Rd1 e3  58. Kd3  e2  59. Rb1 Rh2  60. Kd4 Rf2 61. Re1 Rg2 62. b6 Rxg3 63. Rxe2 1/2-1/2 "

; sample game 234
EventSites(234) = "Corus  Wijk aan Zee" : GameDates(234) = "20070127" : WhitePlayers(234) = "Van Wely, Loek   G#234" : WhiteElos(234) = "2683" : BlackPlayers(234) = "Svidler, Peter   G#234" : BlackElos(234) = "2728" : Each_Game_Result(234) = "1-0"

FilePGNs(234) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. e4 Nxc3 6. bxc3 Bg7 7. Bc4 c5 8. Ne2 Nc6 9. Be3 O-O 10. O-O Bd7 11. Rb1 Qc7 12. Bf4 Qc8 13. Rc1  a6  14. Qd2 b5 15. Bd3 Qb7 16. Bh6 Bxh6  17. Qxh6 cxd4 18. cxd4 Qb6  19. Rc5  Bg4  20. Nf4  Nxd4 21. Rg5 Bf3 22. Rg3  1-0 "

; sample game 235
EventSites(235) = "Morelia/Linares 24th  Morelia/Linares" : GameDates(235) = "20070304" : WhitePlayers(235) = "Anand, Viswanathan   G#235" : WhiteElos(235) = "2779" : BlackPlayers(235) = "Carlsen, Magnus   G#235" : BlackElos(235) = "2690" : Each_Game_Result(235) = "1-0"

FilePGNs(235) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Na5 10. Bc2 c5 11. d4 Nd7 12. d5 Nb6 13. Nbd2 g6 14. b4 cxb4 15. cxb4 Nac4 16. Nxc4 Nxc4 17. Bb3  Nb6 18. Be3 Bd7 19. Rc1 Rc8 20. Rxc8 Bxc8 21. Qc2 Bd7 22. Rc1 Na8 23. Qd2 Qb8 24. Bg5  Bxg5 25. Nxg5 Rc8 26. Rf1 h6 27. Ne6  Kh7 28. f4 Qa7+ 29. Kh2 Be8 30. f5 gxf5 31. exf5 f6 32. Re1  Nc7 33. Rc1 Bd7 34. Rc3 e4 35. Rg3 Nxe6 36. dxe6 Be8 37. e7  Bh5 38. Qxd6 1-0 "

; sample game 236
EventSites(236) = "Morelia/Linares 24th  Morelia/Linares" : GameDates(236) = "20070306" : WhitePlayers(236) = "Carlsen, Magnus   G#236" : WhiteElos(236) = "2690" : BlackPlayers(236) = "Ivanchuk, Vassily   G#236" : BlackElos(236) = "2750" : Each_Game_Result(236) = "1-0"

FilePGNs(236) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. e4 Nxc3 6. bxc3 Bg7 7. Bc4 c5 8. Ne2 Nc6 9. Be3 O-O 10. O-O Na5 11. Bd3 b6 12. Rc1 cxd4 13. cxd4 e6 14. Qd2 Bb7 15. h4 Qe7  16. h5 Rfc8 17. e5  Rxc1  18. Rxc1 Rc8 19. Rxc8+ Bxc8 20. Bg5 Qc7  21. Bf6 Nc6 22. Qg5 h6 23. Qc1 g5 24. Bb5 Bd7 25. d5  exd5 26. Nd4 Bxf6 27. exf6 Qd6 28. Bxc6 Qxf6 29. Bxd7 Qxd4 30. g3 Qc5 31. Qxc5 bxc5 32. Bc6 d4 33. Bb5 Kf8 34. f4 gxf4 35. gxf4 1-0 "

; sample game 237
EventSites(237) = "EU-ch (Women) 8th  Dresden" : GameDates(237) = "20070403" : WhitePlayers(237) = "Kadimova, Ilaha   G#237" : WhiteElos(237) = "2333" : BlackPlayers(237) = "Kosintseva, Nadezhda   G#237" : BlackElos(237) = "2496" : Each_Game_Result(237) = "1/2-1/2"

FilePGNs(237) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 O-O 5. a3 Bxc3+ 6. Qxc3 d6 7. e3 b6 8. Nf3 Bb7 9. Be2 Ne4 10. Qc2 f5 11. O-O Rf6 12. b4 Rh6 13. g3  Nd7 14. Bb2 Ndf6 15. d5 Ng4 16. Rad1  Qe8 17. Nh4 Rxh4 18. gxh4 Qg6 19. Bxg4 Qxg4+ 20. Kh1 Qf3+ 21. Kg1 exd5 22. cxd5 Ba6 23. Rfe1  Rf8  24. a4 Bc4  25. Rd4 Qg4+ 26. Kh1 Qf3+ 27. Kg1 Qg4+ 1/2-1/2 "

; sample game 238
EventSites(238) = "EU-ch (Women) 8th  Dresden" : GameDates(238) = "20070406" : WhitePlayers(238) = "Kosintseva, Tatiana   G#238" : WhiteElos(238) = "2474" : BlackPlayers(238) = "Danielian, Elina   G#238" : BlackElos(238) = "2426" : Each_Game_Result(238) = "1-0"

FilePGNs(238) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Nd2 e6 5. Nb3 Nd7 6. Nf3 Bg6 7. Be2 Ne7 8. O-O Nf5 9. a4 a6 10. a5 c5 11. c3 Rc8  12. Nxc5 Nxc5 13. dxc5 Bxc5 14. b4 Be7 15. Qa4+  Kf8  16. b5 axb5 17. Qxb5 Qc7 18. c4  dxc4 19. Rd1 Rd8 20. Rxd8+ Bxd8 21. Ba3+ Be7 22. g4 Nh6 23. Bd6 Qc8 24. a6 bxa6 25. Rxa6 Bxd6 26. exd6 f6 27. d7 Qd8 28. Nd4 Bf7 29. Qc5+ Kg8 30. Qc8 1-0 "

; sample game 239
EventSites(239) = "EU-ch (Women) 8th  Dresden" : GameDates(239) = "20070415" : WhitePlayers(239) = "Lomineishvili, Maia   G#239" : WhiteElos(239) = "2399" : BlackPlayers(239) = "Kosintseva, Tatiana   G#239" : BlackElos(239) = "2474" : Each_Game_Result(239) = "0-1"

FilePGNs(239) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Bb4 5. cxd5 exd5 6. Bg5 Nbd7 7. e3 c5 8. Bd3 Qa5 9. Qc2 c4 10. Bf5 O-O 11. O-O Re8 12. Nd2 g6 13. Bxd7 Nxd7 14. a3 Bxc3 15. Qxc3 Qxc3 16. bxc3 Nb6 17. f3  Na4 18. Rac1 f6 19. Bxf6  Rxe3 20. Rfe1 Rxe1+ 21. Rxe1 Kf7  22. Bg5 Be6 23. Re3 Re8  24. g4 b5 25. Bf4  a5 26. Bc7  Ra8 27. h3  Nb2 28. f4 Nd1 29. Re1 Nxc3 30. Nf3 Ne4 31. Ng5+ Nxg5 32. fxg5 b4  33. Kf2 Ke7 34. Ke3 Kd7 35. Be5 Ra7  36. Kd2 Rb7 37. Ra1 Kc6 38. Kc2 Kb5  39. axb4 axb4 40. Ra8 Kc6  41. Kb2 Kb5  42. Bf6  Bd7 43. Bd8 Be8 44. Ra5+ Kc6 45. Ra6+ Kd7 46. Bf6  b3 47. Ra1 Kc7  48. Be5+ Kb6 49. Ra8 Re7 50. Rb8+ Ka7 51. Rc8 Bd7 52. Rd8  Bc6 53. Rc8 Kb7 54. Rb8+ Ka7 55. Rc8 Bb7 56. Rc7  Re6 57. Rxh7 Ra6 58. Rc7 Ra2+ 59. Kb1 Kb6 60. Rc5 Bc6  61. h4 Bd7 62. Bc7+ Kb7 63. Ba5 Bxg4 64. Rxd5 Be2 65. Bc3 Bd3+ 66. Kc1 Rc2+ 67. Kd1 Rxc3 68. Rb5+ Kc6 69. Rb8 Rc2 70. h5 gxh5 0-1 "

; sample game 240
EventSites(240) = "EU-ch 8th  Dresden" : GameDates(240) = "20070403" : WhitePlayers(240) = "Bindrich, Falko   G#240" : WhiteElos(240) = "2469" : BlackPlayers(240) = "Tiviakov, Sergei   G#240" : BlackElos(240) = "2682" : Each_Game_Result(240) = "0-1"

FilePGNs(240) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 g6 5. Nc3 Bg7 6. Be3 Nf6 7. Bc4 O-O 8. Bb3 a5 9. O-O Nxd4 10. Bxd4 d6 11. h3 Bd7 12. a4 Bc6 13. f4 Nd7 14. Bxg7 Kxg7 15. Qd4+ Kg8 16. f5   Ra6  17. Kh1 Qb6 18. Qd2 Kg7 19. Rf4  Nf6 20. Rh4 Ng8 21. Rf1 Raa8 22. Qf4 f6 23. Qd2  g5 24. Rg4 Nh6 25. Rg3 Nf7 26. h4 h6 27. Re1 Qb4 28. Qe3 Qc5 29. Qe2 Ne5 30. Qd2 Rh8 31. Kh2 Kf8 32. Kh3 Qb4 33. Qe3 Rd8 34. Rd1 Kg7  35. Nd5 Qc5 36. Qe2 Bxd5 37. Rxd5 Qb6 38. Rxe5  dxe5  39. Kh2 Rh7 40. Bd5  Qxb2 41. Rb3 Qc1 42. Rxb7 Kh8  43. Qh5 Qf4+ 44. Kh3 gxh4 45. Qxh4 Qf1 46. Kh2 Rg7 47. Qh3 Qf4+ 48. g3 Qc1 49. Qg2 h5 50. Qe2 h4 51. Rb3 hxg3+ 52. Rxg3 Qf4 53. Qf3 Rxg3 54. Qxg3 Rb8 0-1 "

; sample game 241
EventSites(241) = "EU-ch 8th  Dresden" : GameDates(241) = "20070404" : WhitePlayers(241) = "Avrukh, Boris   G#241" : WhiteElos(241) = "2644" : BlackPlayers(241) = "Neverov, Valeriy   G#241" : BlackElos(241) = "2539" : Each_Game_Result(241) = "1-0"

FilePGNs(241) = "1. d4 d5 2. c4 e6 3. Nf3 Nf6 4. g3 Bb4+ 5. Bd2 Be7 6. Bg2 O-O 7. O-O c6 8. Qc2 Nbd7 9. Rd1 b6 10. Bf4 Bb7 11. Nc3 Nh5 12. Bc1 Nhf6 13. b3 Rc8 14. e4 c5 15. dxc5  dxc4  16. b4  bxc5 17. b5  Qc7 18. Bf4 e5  19. Be3 Rfd8 20. Nd2 Ng4 21. a4 Nxe3 22. fxe3 Bg5 23. Re1 a6   24. a5  axb5 25. Nxb5 Qb8 26. Nxc4 Ba6 27. Nbd6 Rc6 28. Rab1 Qa8 29. Bh3 Nf6 30. Nxf7  Kxf7 31. Nxe5+ Kg8  32. Nxc6 Qxc6 33. Rb6 Qa8 34. e5 Qf3   35. Bg2  Bxe3+ 36. Kh1 Qf2 37. Qxf2 Bxf2 38. Reb1 Bd3 39. Rb8  Rf8 40. exf6 1-0 "

; sample game 242
EventSites(242) = "EU-ch 8th  Dresden" : GameDates(242) = "20070405" : WhitePlayers(242) = "Meier, Georg   G#242" : WhiteElos(242) = "2484" : BlackPlayers(242) = "Vitiugov, Nikita   G#242" : BlackElos(242) = "2604" : Each_Game_Result(242) = "1/2-1/2"

FilePGNs(242) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 a6 6. Nxc6 bxc6 7. Bd3 d5 8. O-O Nf6 9. Qe2 Be7 10. b3 O-O 11. Bb2 a5  12. Rad1 Bb7 13. Na4 Qc7 14. exd5  cxd5 15. Be5 Qc6  16. Bb5 Ba6 17. c4  Bxb5 18. cxb5 Qb7 19. Rc1 Rfc8 20. b6 Ne8 21. Qb5 Bb4 22. Nc5 Bxc5 23. Rxc5 Rxc5 24. Qxc5 Rc8 25. Bc7  Nxc7 26. Rc1 h5  27. h4 d4 28. bxc7 Qb4 29. Qc6  Qd2 30. g3 d3 31. Kg2 Qb2 32. Rc4 Qe5 33. Qd7 Qd5+ 34. Qxd5 exd5 35. Rd4 Rxc7 36. Rxd5 Rc2 37. a4 Rc3 38. Rxh5 Rxb3 39. Rxa5 d2 40. Rd5 Ra3 1/2-1/2 "

; sample game 243
EventSites(243) = "EU-ch 8th  Dresden" : GameDates(243) = "20070411" : WhitePlayers(243) = "Avrukh, Boris   G#243" : WhiteElos(243) = "2644" : BlackPlayers(243) = "Babula, Vlastimil   G#243" : BlackElos(243) = "2586" : Each_Game_Result(243) = "1-0"

FilePGNs(243) = "1. d4 Nf6 2. c4 e6 3. g3 d5 4. Nf3 dxc4 5. Bg2 a6 6. O-O Nc6 7. e3 Bd7 8. Nc3 Nd5 9. Nd2 Nb6 10. Qe2 Na5 11. Nf3   Nc6 12. e4  Bb4 13. Rd1 O-O 14. d5  exd5 15. Nxd5 Nxd5 16. exd5 Ne7  17. Qxc4 Bd6 18. b3 Re8 19. Bb2 Nf5 20. Rac1 Rc8 21. h4 f6  22. g4 Nh6 23. g5 fxg5 24. Nxg5 b5 25. Qc3 Be5 26. Qc2  Bf5 27. Qd2 Nf7  28. Bxe5  Nxe5 29. Qf4 Qf6 30. Qg3 h6 31. Ne6 c6  32. Nf4 cxd5 33. Nxd5 Qf7  34. Ne3  Rxc1   35. Rxc1 Nd7  36. Rc7  Be6 37. Ra7 Rf8 38. Rxa6 Nf6 39. Qe5 Bc8 40. Ra8 Kh8 41. Qc5  Nh5  42. Nf5  1-0 "

; sample game 244
EventSites(244) = "EU-ch 8th  Dresden" : GameDates(244) = "20070411" : WhitePlayers(244) = "Naiditsch, Arkadij   G#244" : WhiteElos(244) = "2654" : BlackPlayers(244) = "Gustafsson, Jan   G#244" : BlackElos(244) = "2588" : Each_Game_Result(244) = "0-1"

FilePGNs(244) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. c3 d5 9. exd5 Nxd5 10. Nxe5 Nxe5 11. Rxe5 c6 12. Re1 Bd6 13. g3 Bf5  14. d4 Qd7 15. Be3 Rae8 16. Nd2 Bg4 17. Qb1 Bf5 18. Bc2  Bxc2 19. Qxc2 f5 20. c4  bxc4   21. Nxc4 f4 22. Bd2 f3 23. Qd3 Re2  24. Rxe2 Qh3 25. Ne3 Rf4  0-1 "

; sample game 245
EventSites(245) = "EU-ch 8th  Dresden" : GameDates(245) = "20070413" : WhitePlayers(245) = "Meier, Georg   G#245" : WhiteElos(245) = "2484" : BlackPlayers(245) = "Kempinski, Robert   G#245" : BlackElos(245) = "2579" : Each_Game_Result(245) = "1-0"

FilePGNs(245) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 a6 5. Bd3 Qc7 6. O-O Nf6 7. Qe2 d6 8. c4 Nbd7 9. Nc3  Ne5 10. Nf3  Nxd3 11. Qxd3 Be7 12. Bf4 O-O 13. Rfd1 Rd8 14. e5  dxe5 15. Bxe5 Rxd3 16. Bxc7 Rxd1+ 17. Rxd1 Bd7 18. Ne5 Be8 19. Bd6 Bxd6  20. Rxd6 Rc8 21. Rb6  Rc7 22. b4  Kf8  23. f3 Ke7 24. Kf2 Nd7 25. Nxd7 Bxd7 26. c5  Bc6  27. Ke3 Kf6  28. a4 Kf5 29. b5  axb5 30. axb5 Bd7 31. Ne4 Ke5 32. f4+ 1-0 "

; sample game 246
EventSites(246) = "Calatrava op rapid 2nd  Canada de Calatrava" : GameDates(246) = "20070408" : WhitePlayers(246) = "Ivanchuk, Vassily   G#246" : WhiteElos(246) = "2750" : BlackPlayers(246) = "Shirov, Alexei   G#246" : BlackElos(246) = "2715" : Each_Game_Result(246) = "0-1"

FilePGNs(246) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O b5 6. Bb3 Bc5 7. a4 Rb8 8. c3 d6 9. d3  O-O 10. Nbd2 Bb6  11. Re1  Ng4 12. Re2 Kh8 13. h3 Nh6 14. g4  Ne7  15. axb5 axb5 16. Nf1 Ng6 17. N1h2  f6 18. Be3 Nf7  19. Qd2 Bxe3 20. fxe3 Ng5  21. Nxg5 fxg5 22. Rf2 Rxf2 23. Qxf2 b4  24. Bc4  bxc3 25. bxc3 c6 26. d4 Qe7 27. Rf1  exd4 28. cxd4 Be6 29. Bxe6 Qxe6 30. Qf5  Qe7  31. e5 dxe5 32. Qe4 exd4  33. Qxe7 Nxe7 34. exd4 h6 35. Nf3 Rb3 36. Kf2 Ng6 37. Rc1 Nf4 38. Rxc6 Nxh3+ 39. Kg2 Nf4+ 40. Kf2 Rb2+ 41. Kf1 Nd5 42. Re6 Kg8 43. Re2 Rxe2  44. Kxe2 Kf7 45. Ne5+ Ke6 46. Kf3 Nf6 47. Ke3 Kd5 48. Kd3 Ne4 49. Ke3 Nd6 50. Kd3 Nb5 51. Nf3 Nc7 52. Ke3  Ne6 53. Kd3 g6 54. Ne5  Nxd4 55. Nxg6 Nc6 56. Ke2 Ke6 57. Nf8+ Ke7 58. Nh7 Kf7 0-1 "

; sample game 247
EventSites(247) = "Sofia MTel Masters 3rd  Sofia" : GameDates(247) = "20070510" : WhitePlayers(247) = "Topalov, Veselin   G#247" : WhiteElos(247) = "2772" : BlackPlayers(247) = "Nisipeanu, Liviu Dieter   G#247" : BlackElos(247) = "2693" : Each_Game_Result(247) = "0-1"

FilePGNs(247) = "1. e4 d5 2. exd5 Qxd5 3. Nc3 Qd6 4. g3  Nf6 5. Bg2 c6 6. d4 g6 7. Bf4 Qb4 8. Ne2 Bg7 9. Qc1 O-O 10. O-O Bg4 11. a3 Qa5 12. h3 Bxe2 13. Nxe2 Nbd7 14. c4 e5 15. b4 Qc7 16. dxe5 Nxe5 17. Qc2  a5  18. Rae1 axb4 19. axb4 Rfe8 20. c5 Nd5 21. Bd2 Nd7  22. Qc4  N7f6 23. g4  h5  24. Ng3 hxg4 25. hxg4 Qd7 26. g5 Rxe1 27. Rxe1 Ne8   28. Bf3 Nec7 29. Bg4 Qd8 30. Kg2 Nb5 31. Rd1 Ra1  32. Rxa1 Bxa1 33. Bf3 Be5 34. Ne2 Ndc7 35. Be3 Ne6 36. Bg4 Nbc7 37. Qe4 Bg7 38. f4 Qd1 39. Kf2 Bc3  40. b5  Qe1+ 41. Kg2 Nd5 42. bxc6 bxc6 43. Qd3  Bd4  44. Bxe6 Nxe3+ 45. Kh2 Qf2+ 46. Kh3 Qf3+ 47. Ng3 Qg2+ 0-1 "

; sample game 248
EventSites(248) = "Sofia MTel Masters 3rd  Sofia" : GameDates(248) = "20070512" : WhitePlayers(248) = "Kamsky, Gata   G#248" : WhiteElos(248) = "2705" : BlackPlayers(248) = "Sasikiran, Krishnan   G#248" : BlackElos(248) = "2690" : Each_Game_Result(248) = "0-1"

FilePGNs(248) = "1. d4 Nf6 2. Nf3 d5 3. c4 dxc4 4. e3 a6 5. Bxc4 e6 6. O-O c5 7. dxc5 Qxd1 8. Rxd1 Bxc5 9. b3 Nbd7 10. Bb2 b6 11. Nc3 Bb7 12. Rac1 Be7  13. Ne2   Rc8 14. Nf4 b5 15. Be2 O-O 16. Nd4 Nc5 17. Bf3 Nce4 18. Nd3 Bd6  19. Ne2 Rfd8 20. Ne5 Bb8 21. Rxc8  Rxc8 22. Ng3 Bd5  23. Nd3 a5 24. b4  a4  25. a3 Nc3  26. Rc1 Bxf3 27. gxf3 Bxg3 28. Rxc3 Rxc3 29. Bxc3 Nd5  30. Bd4 Bd6 31. f4 f6 32. Kg2 Kf7 33. Kf3 h6  34. e4 Nxf4  35. Nxf4 e5 36. Ne2  exd4 37. Nxd4 Bxh2 38. Nxb5 Be5 39. Ke3 g5 40. Nd4 h5  41. Nf5 h4 42. Ke2 Ke6  43. Ne3 h3 44. Kf1 Bd4  45. Kg1 Bxe3 46. fxe3 g4 0-1 "

; sample game 249
EventSites(249) = "Sofia MTel Masters 3rd  Sofia" : GameDates(249) = "20070515" : WhitePlayers(249) = "Kamsky, Gata   G#249" : WhiteElos(249) = "2705" : BlackPlayers(249) = "Mamedyarov, Shakhriyar   G#249" : BlackElos(249) = "2757" : Each_Game_Result(249) = "1-0"

FilePGNs(249) = "1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. Nf3 Bg7 5. h3 O-O 6. Be3 c6 7. Qd2  b5 8. Bd3 Nbd7 9. O-O Qc7 10. Ne2 c5 11. c3 e5 12. Ng3 c4  13. Bc2 Re8  14. a4  bxa4 15. Bxa4  exd4 16. Nxd4 a6 17. Bh6 Bh8 18. Ndf5  Re6 19. Rfd1 Nc5 20. Nxd6 Bb7 21. Nxb7 Qxb7 22. f3 Nd3 23. b3 Bg7 24. Bxg7 Kxg7 25. bxc4 Nb2 26. Rdb1 Qa7+ 27. Kh1 Nxc4 28. Qg5 Rc8 29. Nf5+ Kh8 30. Nd4 Rb6 31. Rxb6 Qxb6 32. Bb3 Rc5 33. Qh6 Kg8 34. Re1 Rh5 35. Qf4 Rc5 36. e5 Nh5 37. Qh4 Nxe5 38. f4 Rxc3 39. fxe5 Rxb3 40. e6 fxe6 41. Nxb3 Qxb3 42. Qd8+ Kg7 43. Qe7+ Kh6 44. Qf8+ 1-0 "

; sample game 250
EventSites(250) = "Sofia MTel Masters 3rd  Sofia" : GameDates(250) = "20070517" : WhitePlayers(250) = "Mamedyarov, Shakhriyar   G#250" : WhiteElos(250) = "2757" : BlackPlayers(250) = "Sasikiran, Krishnan   G#250" : BlackElos(250) = "2690" : Each_Game_Result(250) = "0-1"

FilePGNs(250) = "1. c4 e5 2. g3 d6 3. Bg2 g6 4. Nc3 Bg7 5. d3 f5 6. e4 Nf6 7. Nge2 a5  8. exf5  gxf5 9. d4  O-O 10. Bg5 Qe8 11. O-O h6 12. Bxf6  Bxf6 13. c5  Nc6  14. Nb5 Qe7 15. Nec3 Qg7  16. cxd6 cxd6 17. d5 Nd4 18. Nxd4 exd4 19. Nb5 f4  20. Nxd6 Bg4 21. Qd3 Be7 22. Nb5 f3 23. Bh1 Bc5 24. d6 Kh8 25. Rad1  Rad8 26. a3  Bb6   27. Rfe1  Bf5 28. Qd2 Qf6 29. Re7 Bd7 30. Rde1 Qg5 31. Qd3 Qf5 32. Qd2  Qg5 33. Qc2 Qf5 34. Qxf5 Rxf5 35. Nc7 d3 36. Rd1 Rc5  37. Bxf3 Rc2 38. Rf1  Bh3  39. Ne6  Bxf2+  40. Kh1 Bxf1 41. d7  Rg8 0-1 "

; sample game 251
EventSites(251) = "Sofia MTel Masters 3rd  Sofia" : GameDates(251) = "20070518" : WhitePlayers(251) = "Nisipeanu, Liviu Dieter   G#251" : WhiteElos(251) = "2693" : BlackPlayers(251) = "Adams, Michael   G#251" : BlackElos(251) = "2734" : Each_Game_Result(251) = "1-0"

FilePGNs(251) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Na5 10. Bc2 c5 11. d4 Nd7 12. Kh1 Re8 13. d5 Nb6 14. b3 Bd7 15. Be3 Qc7 16. g4  c4 17. b4 Nb7 18. Nbd2 a5 19. a3 Ra6 20. Nf1 Rea8 21. Bc1   Nd8 22. Ne3 axb4 23. cxb4 f6 24. Nf5  Bc8  25. Rg1 Nf7 26. h4 Bd8 27. Rg3 Kh8 28. g5 g6 29. Ne3 fxg5 30. hxg5 Kg8 31. Kg2  Na4 32. Qe1  Bd7 33. Qh1 Qc8 34. Qh2 Nc3  35. Kf1  Be7 36. Bb2 Na4 37. Bc1 Bf8 38. Qh4 Be7 39. Qh2 Bf8 40. Qh4 Be7 41. Nf5  Qf8 42. Nh2 h6  43. Ng4 hxg5 44. Bxg5   Nxg5 45. Ngh6+ Kh7 46. Nf7+ Kg8 47. N7h6+ Kh7 48. Nf7+ Kg8 49. Nxg5 Bxg5 50. Rxg5 Be8 51. Kg2 R8a7 52. Rh1 Qf6 53. Nh6+ 1-0 "

; sample game 252
EventSites(252) = "Sarajevo Bosnia-A 37th  Sarajevo" : GameDates(252) = "20070522" : WhitePlayers(252) = "Morozevich, Alexander   G#252" : WhiteElos(252) = "2762" : BlackPlayers(252) = "Movsesian, Sergei   G#252" : BlackElos(252) = "2642" : Each_Game_Result(252) = "0-1"

FilePGNs(252) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Bb4 5. cxd5 exd5 6. Bg5 O-O 7. e3 c5 8. dxc5 Nbd7 9. Rc1 Nxc5  10. Bd3 Bg4  11. O-O Bxf3 12. gxf3 Bxc3 13. Rxc3 Ne6 14. Bh4 d4 15. Rc4 b5 16. Rc2 dxe3 17. fxe3 Qb6 18. Bxf6 Qxe3+ 19. Kh1 gxf6 20. Re2 Qh6 21. Bxb5 Kh8 22. Bc4 Rad8 23. Qc1 Qh3 24. Ref2 Rg8 25. Qe3  Ng7  26. Rg1 Nf5 27. Qe1 Rxg1+ 28. Kxg1 Rg8+ 29. Kh1 Ng3+ 30. Kg1 Nf1+ 31. Kh1 Nxh2 0-1 "

; sample game 253
EventSites(253) = "Wch Candidates sf  Elista" : GameDates(253) = "20070601" : WhitePlayers(253) = "Carlsen, Magnus   G#253" : WhiteElos(253) = "2693" : BlackPlayers(253) = "Aronian, Levon   G#253" : BlackElos(253) = "2759" : Each_Game_Result(253) = "1-0"

FilePGNs(253) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. a3 Bb7 5. Nc3 d5 6. cxd5 Nxd5 7. Qc2 Be7 8. e4 Nxc3 9. bxc3 O-O 10. Bd3 c5 11. O-O Qc7 12. Qe2 Nd7 13. Bb2 c4 14. Bc2 b5 15. Bc1 a5 16. Rb1 Ba6  17. e5 b4  18. axb4 axb4 19. Bg5  Nb6 20. Qe4 g6 21. Qh4 Ra7 22. Bf6  Bxf6 23. exf6 Nd5 24. Be4 Qf4 25. Bxd5 Qxh4 26. Nxh4 exd5 27. Rxb4 Bc8 28. Rb6 Ra3 29. Rc1 Be6 30. Nf3 Rfa8 31. h4 h6 32. Ne5 Ra1 33. Rxa1  Rxa1+ 34. Kh2 Ra3 35. Rb8+ Kh7 36. f4  Rxc3 37. h5 gxh5 38. Rf8 Ra3 39. f5 Bxf5 40. Rxf7+ Kg8 41. Rg7+ Kf8 42. Rb7 Ra8 43. Kg3  Rd8 44. Kf4 Be4 45. g3 c3 46. Rf7+ Kg8 47. Rg7+ Kf8 48. Nd7+ Rxd7 49. Rxd7 1-0 "

; sample game 254
EventSites(254) = "Wch Candidates sf  Elista" : GameDates(254) = "20070601" : WhitePlayers(254) = "Gelfand, Boris   G#254" : WhiteElos(254) = "2733" : BlackPlayers(254) = "Kasimdzhanov, Rustam   G#254" : BlackElos(254) = "2677" : Each_Game_Result(254) = "1/2-1/2"

FilePGNs(254) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 e6 5. e3 Nbd7 6. Bd3 dxc4 7. Bxc4 b5 8. Bd3 a6 9. a4 Bb7 10. O-O b4 11. Ne4 c5 12. Nxf6+ gxf6  13. Qe2 Bd6 14. Bd2 Rg8 15. a5  Qb8 16. h3  f5 17. e4 c4  18. Bc2 fxe4 19. Bxe4 Nf6 20. Bxb7 Qxb7 21. Rac1 Ne4 22. d5  Qxd5 23. Rfd1 Qd3 24. Qxd3 cxd3 25. Be3 Ke7  26. Rxd3 Rac8 27. Rcd1 Bc5  28. Rd7+ Kf6 29. Bd4+ e5  30. Bxc5  Rxc5 31. Re1 Ng5 32. Nxg5 Rxg5 33. Rd6+ Kg7 34. Rxa6 Rc2 35. b3 Rf5 36. f3 Rb2 37. Re4 Rg5 38. g4 Rxb3 39. Kf2 Rg6 40. Rb6 Ra3  41. Rxe5 b3 42. Kg3  h6 43. h4 b2 44. Rxb2 Rf6 45. Rf2 Ra6 1/2-1/2 "

; sample game 255
EventSites(255) = "Wch Candidates sf  Elista" : GameDates(255) = "20070603" : WhitePlayers(255) = "Aronian, Levon   G#255" : WhiteElos(255) = "2759" : BlackPlayers(255) = "Carlsen, Magnus   G#255" : BlackElos(255) = "2693" : Each_Game_Result(255) = "1-0"

FilePGNs(255) = "1. d4 Nf6 2. Nf3 e6 3. c4 c5 4. d5 exd5 5. cxd5 d6 6. Nc3 g6 7. g3 Bg7 8. Bg2 O-O 9. O-O a6 10. a4 Re8 11. Bf4 Ne4 12. Nxe4 Rxe4 13. Nd2 Rb4 14. b3  Rxf4  15. gxf4 Bxa1 16. Qxa1 Nd7 17. Ne4  Qe7 18. Rc1 b6 19. Rc3 Nf6 20. Re3 Nxe4 21. Bxe4 Qd8 22. Rg3 Qh4  23. e3 Qe7 24. Bd3 Bb7 25. e4 Re8 26. f5  Qh4 27. h3 Bc8 28. Qc3 Qf4 29. Qf6 Qe5 30. Qxe5 Rxe5 31. f4 Re8 32. f6   Bd7 33. Re3 b5 34. axb5 axb5 35. e5 Kf8 36. Kf2 Kg8 37. Be2 Kf8 38. h4 Kg8 39. Ke1 Kf8 40. Kd2 h6 41. Bd3 h5 42. e6 fxe6 43. Bxg6 exd5 44. Bxe8 Bxe8 45. Re6 c4 46. Rxd6 cxb3 47. Kc3 Kf7 48. Kxb3 Kg6 49. Kb4 Kf5 50. Kc5 Bf7 51. Kxb5 Be6 52. Kc5 Kxf6 53. Kd4 Kf5 54. Ke3 Bf7 55. Kf3 Be6 56. Ra6 Bf7 57. Ra8 Kf6 58. Ra6+ Kf5 59. Ra1 Bg6 60. Rg1 Kf6 61. Ke3 Bf7 62. Rg5 Ke6 63. Kd4 Kf6 64. Kc5 Ke7 65. Rg7 Kf6 66. Rxf7+ 1-0 "

; sample game 256
EventSites(256) = "Wch Candidates final  Elista" : GameDates(256) = "20070608" : WhitePlayers(256) = "Aronian, Levon   G#256" : WhiteElos(256) = "2759" : BlackPlayers(256) = "Shirov, Alexei   G#256" : BlackElos(256) = "2699" : Each_Game_Result(256) = "1/2-1/2"

FilePGNs(256) = "1. d4 d5 2. c4 dxc4 3. e4 e5 4. Nf3 exd4 5. Bxc4 Nc6 6. O-O Be6 7. Bb5 Bc5 8. b4 Bb6 9. a4 a6 10. Bxc6+ bxc6 11. a5 Ba7 12. Bb2 Nf6   13. Nxd4 Bxd4 14. Bxd4 Nxe4 15. Bxg7 Rg8 16. Be5 Bh3  17. Bg3 Nxg3 18. hxg3 Qxd1 19. Rxd1 Be6 20. Nc3 Rg4 21. Rab1 Rb8 22. f4 Bf5 23. Rb2 Rxg3 24. Na4 Kf8 25. Nc5 Ra8 26. Kf2 Rc3 27. Rbd2 Rc4 28. Rd4 Rxd4 29. Rxd4 Ke7 30. Rd1 Be6 31. Re1 Kf6 32. Re5 h6 33. g3 Bc4 34. Nd7+ Kg7 35. Re7 Rd8  36. Ke3  h5  37. f5  Rg8  38. Re4 Bb5 39. Rh4 Rd8 40. Nc5 Kh6 41. Kf4 Be2 42. Rh2 Bb5 43. Ke5 Kg5 44. Ne4+ Kg4 45. Kf6 Kf3 46. Rh4 Bd3 47. Nc5 Kxg3 48. Rxh5 Bc4 49. Rh1 Rb8  50. Rd1  Rxb4 51. Rd4 Kf3 52. Nxa6  c5  53. Nxc5 Ke3 54. Rh4 Kd2 55. Na6 Ra4 56. Nxc7 Kd3  57. a6 Ra5  58. Rf4 Kc3 59. Ke7 Rc5  60. Kd6 Ra5 61. f6  Bxa6 62. Nxa6 Rxa6+ 63. Ke7 Ra7+ 64. Kf8 Kd3 65. Rh4 Ke3 66. Rh7 Kf4  67. Rxf7 Ra6 68. Kg7 1/2-1/2 "

; sample game 257
EventSites(257) = "NED-ch  Hilversum" : GameDates(257) = "20070619" : WhitePlayers(257) = "Hendriks, Willy   G#257" : WhiteElos(257) = "2412" : BlackPlayers(257) = "L'Ami, Erwin   G#257" : BlackElos(257) = "2617" : Each_Game_Result(257) = "0-1"

FilePGNs(257) = "1. e4 e5 2. Bc4 Nf6 3. d3 Nc6 4. Nf3 Bc5 5. c3 a6 6. Nbd2 Ba7 7. Bb3 O-O 8. O-O d6 9. h3 Ne7 10. Re1 Ng6 11. Nf1 b5 12. Ng3 h6 13. d4 c5 14. a4 Qc7  15. Be3 Bd7  16. Qd2 Kh7 17. axb5 axb5 18. Red1 c4 19. Bc2 Bb6 20. Rxa8 Rxa8 21. Nf5 Bxf5 22. exf5 Ne7 23. dxe5 Bxe3 24. Qxe3 dxe5 25. Nxe5  Ned5 26. Qd4 Re8 27. Nf3 b4  28. cxb4 Nxb4 29. Bb1 Nbd5 30. g3  c3 31. Rc1 Rc8 32. bxc3 Nxc3 33. Kh2 Qa5 34. Qd2 Qb6 35. Rxc3  Rxc3 36. Qxc3 Qxf2+ 37. Kh1 Qf1+ 38. Ng1 Qxb1 39. Qf3 Qc2 40. Ne2 Ne4 41. Kg2 Ng5 42. Qg4 Qc6+ 43. Kf2 Ne4+ 44. Ke3 Nf6 45. Qf3 Qc5+ 46. Kd2 Qe5 47. Nc3 Qd4+ 48. Kc2  h5  49. Kb3 Qg1 50. Kc4 Qh2 51. h4 Qd2 52. Kb3 Qd4 53. Kc2 Ng4 54. Ne2  Ne3+ 55. Kb3 Qd3+ 56. Ka4 Qa6+ 57. Kb4 Qc4+ 58. Ka3 Nc2+ 59. Kb2 Ne1  60. Qxh5+ Kg8 61. Nf4 Qc2+ 62. Ka3 Qc3+ 63. Ka4  Nc2 64. Kb5 Nd4+ 65. Kb6 Qc6+ 66. Ka7 Nb5+ 67. Kb8 Qc7+ 68. Ka8 Qa7# 0-1 "

; sample game 258
EventSites(258) = "NED-ch  Hilversum" : GameDates(258) = "20070623" : WhitePlayers(258) = "L'Ami, Erwin   G#258" : WhiteElos(258) = "2617" : BlackPlayers(258) = "Stellwagen, Daniel   G#258" : BlackElos(258) = "2600" : Each_Game_Result(258) = "1/2-1/2"

FilePGNs(258) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. e3 e6 5. Nf3 Nbd7 6. Bd3 dxc4 7. Bxc4 b5 8. Bd3 Bb7 9. e4 b4 10. Na4 c5 11. e5 Nd5 12. Nxc5 Nxc5 13. dxc5 Bxc5 14. O-O Rc8 15. Qe2  h6 16. Bd2 Qb6 17. Rac1 Ke7 18. Qe4  Ne3 19. Qh4+ g5 20. Nxg5 Nxg2 21. Qh5 Rcf8 22. Rxc5 Qxc5 23. Rc1 Qb6 24. Be4  hxg5 25. Bxg5+ Ke8 26. Qd1 Rfg8  27. Rc8+  Bxc8 28. Bc6+ Kf8 29. Be7+  Kg7 30. Qg4+ Kh6 31. Bf8+  Rxf8 32. Qh3+ Kg5 33. Qxg2+ Kf5 34. Qe4+ Kg5 35. Qg2+ Kf5 1/2-1/2 "

; sample game 259
EventSites(259) = "Foros Aerosvit  Foros" : GameDates(259) = "20070621" : WhitePlayers(259) = "Van Wely, Loek   G#259" : WhiteElos(259) = "2674" : BlackPlayers(259) = "Jakovenko, Dmitrij   G#259" : BlackElos(259) = "2708" : Each_Game_Result(259) = "1-0"

FilePGNs(259) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Ba6 5. b3 Bb4+ 6. Bd2 Be7 7. Nc3 c6 8. e4 d5 9. Qe2 dxe4 10. Nxe4 Bb7 11. Neg5 O-O 12. Bh3 h6  13. Nxe6 fxe6 14. Bxe6+ Kh8 15. Ne5 Qxd4 16. O-O Bd6 17. Ng6+ Kh7 18. Bf5  Re8 19. Be3 Qc3 20. Rad1 Ba3  21. Qf3  Bc8  22. Bxc8 Rxc8 23. Qf5 Re8 24. Bd4 Qa5 25. c5 Kg8 26. Ne7+  Rxe7 27. Bxf6 Rd7 28. Qg6 1-0 "

; sample game 260
EventSites(260) = "Dortmund SuperGM  Dortmund" : GameDates(260) = "20070627" : WhitePlayers(260) = "Kramnik, Vladimir   G#260" : WhiteElos(260) = "2772" : BlackPlayers(260) = "Carlsen, Magnus   G#260" : BlackElos(260) = "2693" : Each_Game_Result(260) = "1-0"

FilePGNs(260) = "1. Nf3 Nf6 2. c4 e6 3. g3 d5 4. d4 Be7 5. Bg2 O-O 6. O-O dxc4 7. Qc2 a6 8. Qxc4 b5 9. Qc2 Bb7 10. Bd2 Nc6 11. e3 Nb4 12. Bxb4 Bxb4 13. a3 Be7 14. Nbd2 Rc8 15. b4 a5 16. Ne5 Nd5   17. Nb3  axb4 18. Na5 Ba8 19. Nac6 Bxc6 20. Nxc6 Qd7 21. Bxd5  exd5 22. axb4  Rfe8 23. Ra5 Bf8 24. Ne5 Qe6 25. Rxb5 Rb8  26. Rxb8 Rxb8 27. Qxc7  Bd6 28. Qa5 Bxb4 29. Rb1 Qd6 30. Qa4 1-0 "

; sample game 261
EventSites(261) = "Andorra op 25th  Andorra" : GameDates(261) = "20070705" : WhitePlayers(261) = "Postny, Evgeny   G#261" : WhiteElos(261) = "2598" : BlackPlayers(261) = "Del Rio Angelis, Salvador Gabriel   G#261" : BlackElos(261) = "2504" : Each_Game_Result(261) = "1-0"

FilePGNs(261) = "1. d4 e6 2. c4 b6 3. a3 f5 4. Nc3 Nf6 5. g3 c6  6. Bf4   Ba6  7. Qa4 Bb7 8. Bg2 Be7 9. Nh3  O-O 10. O-O Nh5 11. d5 Nxf4 12. Nxf4 Qc8 13. e4  fxe4  14. Bxe4  Rxf4  15. gxf4 Qf8 16. Ne2 Na6 17. dxc6 dxc6 18. b4 Rc8 19. Qc2 g6 20. Rad1 Nc7 21. Rd7 Ba8 22. Qc3 Qe8 23. Rd2 Qf7 24. Bg2 Ne8 25. Rd7 a6 26. Rfd1 Nf6 27. Ra7 Rf8 28. Qe5 1-0 "

; sample game 262
EventSites(262) = "Montreal 8th  Montreal" : GameDates(262) = "20070724" : WhitePlayers(262) = "Tiviakov, Sergei   G#262" : WhiteElos(262) = "2648" : BlackPlayers(262) = "Eljanov, Pavel   G#262" : BlackElos(262) = "2701" : Each_Game_Result(262) = "1-0"

FilePGNs(262) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. d3 d6 6. c3 g6 7. Bg5 Bg7 8. Nbd2 O-O 9. Nf1 h6 10. Bh4 b5 11. Bb3 Na5 12. Bc2 c5 13. Ne3 Be6 14. O-O Qd7  15. a3  Ng4 16. Nxg4 Bxg4 17. h3 Be6 18. Re1 f5 19. d4  f4  20. dxe5 g5 21. exd6 gxh4  22. e5 Nc6 23. b4   c4 24. a4  bxa4  25. Bxa4 Qb7 26. Bxc6  Qxc6 27. Nd4 Qd7 28. Qf3  Kh8 29. Ra5 Qf7 30. Rc5 Ra7 31. Qe4 Re8 32. Kf1 Rd7 33. Re2 Kg8 34. Ra2 Qh5 35. f3 Qg5 36. Rxa6 Bxh3 37. gxh3 Bxe5 38. Nf5 Qf6 39. Raa5 1-0 "

; sample game 263
EventSites(263) = "Biel GM  Biel" : GameDates(263) = "20070724" : WhitePlayers(263) = "Onischuk, Alexander   G#263" : WhiteElos(263) = "2650" : BlackPlayers(263) = "Grischuk, Alexander   G#263" : BlackElos(263) = "2726" : Each_Game_Result(263) = "1-0"

FilePGNs(263) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. Nf3 dxc4 5. a4 Bf5 6. Ne5 e6 7. f3 Bb4 8. e4 Bxe4 9. fxe4 Nxe4 10. Bd2 Qxd4 11. Nxe4 Qxe4+ 12. Qe2 Bxd2+ 13. Kxd2 Qd5+ 14. Kc2 Na6 15. Nxc4 O-O 16. Qe5 Rab8 17. a5 f6 18. Qxd5 cxd5 19. Ne3 Rfc8+ 20. Kb1 Nc5 21. Ra3 f5 22. Be2 Ne4 23. Rd1 Rc5 24. Nc2 Kf7 25. Nd4 Kf6 26. Rb3 Nd6  27. g4  f4 28. g5+ Ke7 29. Rh3 Rh8 30. Bg4 e5 31. Ne6 Rxa5 32. Nxg7 Ne4 33. Nf5+ Kd8 34. g6 Nf6 35. g7 Re8 36. Bh5 1-0 "

; sample game 264
EventSites(264) = "Biel GM  Biel" : GameDates(264) = "20070728" : WhitePlayers(264) = "Carlsen, Magnus   G#264" : WhiteElos(264) = "2710" : BlackPlayers(264) = "Onischuk, Alexander   G#264" : BlackElos(264) = "2650" : Each_Game_Result(264) = "1-0"

FilePGNs(264) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Bg5 h6 5. Bxf6 Qxf6 6. Nc3 c6 7. Qb3 dxc4 8. Qxc4 Nd7 9. e3 g6 10. Be2 Bg7 11. O-O O-O 12. Rfd1 e5 13. Ne4 Qe7  14. d5 cxd5 15. Qxd5 Nb6 16. Qc5 Qxc5 17. Nxc5 Bg4 18. h3 Rac8 19. Nxb7 Be6 20. b3 Rc2 21. Bf1 Nd5 22. Bc4 Nc3 23. Rd2 Rxd2 24. Nxd2 e4 25. Kf1 Rb8 26. Nc5 Bxc4+  27. Nxc4 Rb5 28. Na6  Bf8 29. b4  Bxb4 30. a4 Rb7 31. Rc1 Nd5 32. Rb1 f5 33. a5 Kg7 34. Ne5 f4 35. exf4 e3 36. fxe3 Nxe3+ 37. Kg1 Nd5 38. Kh1 1-0 "

; sample game 265
EventSites(265) = "Biel GM  Biel" : GameDates(265) = "20070801" : WhitePlayers(265) = "Onischuk, Alexander   G#265" : WhiteElos(265) = "2650" : BlackPlayers(265) = "Avrukh, Boris   G#265" : BlackElos(265) = "2645" : Each_Game_Result(265) = "1-0"

FilePGNs(265) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. Nf3 Bg7 5. Qb3 dxc4 6. Qxc4 O-O 7. e4 Nc6 8. Be2 Bg4 9. d5 Na5 10. Qb4 Bxf3 11. Bxf3 c6 12. O-O Qb6 13. Qa4 Nd7 14. Rd1  Rfd8 15. Qc2 Rac8 16. Be3 Qb4 17. dxc6 bxc6 18. Be2 Nc4 19. Bxc4 Qxc4 20. Rac1 Nb6 21. h3 Bxc3  22. Rxd8+ Rxd8 23. Qxc3 Qxa2 24. b3  Qe2 25. Qe5 Rd1+ 26. Kh2 Rxc1 27. Qxe7  Rh1+ 28. Kxh1 Qd1+ 29. Kh2 Qd7 30. Qf6 Qe6 31. Qd8+ Kg7 32. Bd4+ f6 33. Qc7+ Nd7 34. Qxa7 g5 35. Qc7 Kg6 36. f3 h5  37. f4 gxf4 38. Qxf4 Kf7 39. b4 Kg6 40. Be3 Qe5 41. Kg3  Qxf4+ 42. Kxf4 Nf8 43. g4 Ne6+ 44. Kg3 hxg4 45. Kxg4 Ng7 46. h4 Nh5 47. Bd4 Ng7 48. Bc5 Ne6 49. h5+ Kf7 50. h6  Ng5 51. Kf5 Nf3 52. Bf2 Nd2 53. Bd4 Nc4 54. Bxf6 1-0 "

; sample game 266
EventSites(266) = "Biel GM  Biel" : GameDates(266) = "20070801" : WhitePlayers(266) = "Van Wely, Loek   G#266" : WhiteElos(266) = "2680" : BlackPlayers(266) = "Carlsen, Magnus   G#266" : BlackElos(266) = "2710" : Each_Game_Result(266) = "1-0"

FilePGNs(266) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Bb4 5. Bg5 O-O 6. e3 c5 7. cxd5 exd5 8. Bd3  c4 9. Bc2 Nbd7 10. O-O Qa5 11. Rc1 Bxc3 12. bxc3 Ne4 13. Bb1 Re8 14. Bf4 Nb6  15. Ne5 f6 16. Qh5 Be6 17. f3  fxe5 18. Bxe5 Bf7 19. Qh3  Nf6 20. Bxf6 gxf6 21. Qh6  Bg6 22. Bxg6 hxg6 23. Qxg6+ Kf8 24. Qxf6+ Kg8 25. Qg6+ Kf8 26. Qf6+ Kg8 27. e4 Qb5 28. Qg6+ Kf8 29. Qf6+ Kg8 30. Qg6+ Kf8 31. e5 Qc6 32. Qf5+  Ke7 33. Qh7+ Kd8 34. f4 Qd7 35. Qxd7+  Kxd7  36. g4 Rg8  37. h3 Na4 38. Kg2 b5 39. Kg3 a5 40. a3 b4 41. cxb4 axb4 42. axb4 Nb2 43. Rc3 Nd3 44. b5 Rgb8 45. Rb1 Ra5 46. f5 Raxb5 47. Rxb5 Rxb5 48. e6+  Ke7  49. Ra3 Rb7 50. g5 Nb4 51. Re3  Nc6 52. f6+ Kd6 53. Kg4 c3 54. e7 c2 55. Rc3 Rb8 56. Rxc2 Nxd4 57. Rb2 Rc8 58. g6 Ne6 59. Rb6+ Kd7 60. Rb7+ 1-0 "

; sample game 267
EventSites(267) = "Vlissingen HZ op 11th  Vlissingen" : GameDates(267) = "20070807" : WhitePlayers(267) = "Caruana, Fabiano   G#267" : WhiteElos(267) = "2549" : BlackPlayers(267) = "Zaragatski, Ilja   G#267" : BlackElos(267) = "2480" : Each_Game_Result(267) = "1-0"

FilePGNs(267) = "1. e4 e6 2. d4 d5 3. Nd2 Nc6 4. Ngf3 Nf6 5. e5 Nd7 6. Bd3  f6 7. Ng5  Ndxe5 8. dxe5 fxg5 9. Qh5+ g6  10. Bxg6+ Kd7 11. f4  gxf4 12. Bd3 Qe8 13. Qe2 Nb4 14. O-O Nxd3 15. cxd3 b6  16. Rxf4 Ba6 17. Rf6  Rg8 18. Nf3 Qh5 19. Bf4 Qg4 20. Bg3 Be7 21. Qc2 Bb7 22. Rc1 c6 23. d4 h5 24. Rf4  Qg6 25. Bh4 Raf8 26. Bf6  Qxc2 27. Rxc2 c5 28. Rf2 cxd4 29. Nxd4 Bc5 30. h3  Rg3  31. b4 Bxb4  32. Ne2 Ra3 33. Rxb4 Rxa2 34. Nd4 Rxf2 35. Kxf2 Rc8 36. Rb3 Rc4 37. Ke3 Rc1 38. g4 hxg4 39. hxg4 Re1+ 40. Kf3 Rd1 41. Ke3 Re1+ 42. Kf3 Rd1 43. Nb5 d4+ 44. Ke2 Rg1 45. Nxa7 Rg2+ 46. Ke1 Rg1+ 47. Kd2 Rg2+ 48. Ke1 Rg1+ 49. Kf2 Rg2+ 50. Kf1 Rxg4 51. Rxb6 Bd5 52. Rb4   Re4 53. Nb5 d3 54. Rxe4 Bxe4 55. Nd4 Bd5 56. Ke1 Kc7 57. Kd2 Bc4 58. Be7 Kb7 59. Bb4 Kb6 60. Kc3 Bd5 61. Kxd3 Kc7 62. Ke3 Kd8 63. Kf4 Ke8 64. Kg5 Kf7 65. Kh6 Bc4 66. Nf3 Ba2 67. Ng5+ Ke8 68. Kg7 Bd5 69. Kf6 Kd7 70. Ba3 Ba2 71. Nh7 Kc6 72. Nf8 Kd5 73. Nxe6 Bc4 74. Nf4+ Ke4 75. Nh3 Bb3 76. Ng5+ Kd4 77. e6 Bxe6 78. Nxe6+ Ke4 79. Bf8 Kd5 80. Ng5 Kd4 81. Ke6 Ke3 82. Ke5 Kd3 83. Kd5 Ke3 84. Bd6 Kd3 85. Be5 Ke3 86. Kc4 Ke2 87. Kc3 Ke3 88. Bg3 Ke2 89. Kd4 Kd2 90. Nf3+ Ke2 91. Nh2 Kd2 92. Bf4+ Ke2 93. Be3 Kd1 94. Kd3 Ke1 95. Bd4 Kd1 96. Nf3 Kc1 97. Nd2 Kd1 98. Bf2 Kc1 99. Nc4 Kd1 100. Nb2+ Kc1 101. Kc3 Kb1 102. Kb3 Kc1 103. Be3+ Kb1 104. Na4 Ka1 105. Bc1 Kb1 106. Ba3 Ka1 107. Bb2+ 1-0 "

; sample game 268
EventSites(268) = "George Marx mem 5th  Paks" : GameDates(268) = "20070808" : WhitePlayers(268) = "Acs, Peter   G#268" : WhiteElos(268) = "2530" : BlackPlayers(268) = "Kortschnoj, Viktor   G#268" : BlackElos(268) = "2610" : Each_Game_Result(268) = "0-1"

FilePGNs(268) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Nf3 b6 5. Bg5 Bb7 6. Nd2 h6 7. Bh4 Be7  8. e4  d6 9. Bg3 O-O 10. f3 a6 11. Qc2 c5 12. d5 exd5 13. cxd5 b5 14. a4 b4 15. Ne2  a5 16. Bf2 Ba6 17. Ng3 Bxf1 18. Ngxf1 Nbd7 19. Ne3 Nb6 20. O-O Re8 21. Rad1 Nfd7 22. Kh1 Qc7 23. f4 Bf6 24. Ng4 Rac8 25. e5 dxe5 26. Ne4 exf4 27. d6 Qc6 28. Nexf6+ Nxf6 29. Nxf6+ gxf6 30. Qf5 Re5 31. Qxf6 Rg5 32. Bg3  Nd5 33. Qxh6 Rg6  34. Qh3 fxg3 35. Rxd5 Qxd5 36. Qxc8+ Kg7 37. Qf5 Qxf5 38. Rxf5 Rf6 39. Rf3 Rxf3 40. gxf3 Kf6 0-1 "

; sample game 269
EventSites(269) = "FRA-ch  Aix les Bains" : GameDates(269) = "20070813" : WhitePlayers(269) = "Fontaine, Robert   G#269" : WhiteElos(269) = "2567" : BlackPlayers(269) = "Sokolov, Andrei   G#269" : BlackElos(269) = "2582" : Each_Game_Result(269) = "0-1"

FilePGNs(269) = "1. d4 Nf6 2. c4 e6 3. Nf3 Bb4+ 4. Bd2 Qe7 5. Nc3 O-O 6. Rc1 d6 7. a3 Bxc3 8. Bxc3 Ne4 9. g3 Nd7 10. Bg2 Ndf6 11. O-O Bd7 12. d5 Nxc3 13. Rxc3 e5 14. b4 a5 15. Nd2 axb4 16. axb4 Ra2 17. Qc1 Rfa8 18. c5 e4  19. c6  bxc6 20. dxc6 Bg4 21. e3 d5  22. Rc5 h5 23. Nb3 Be2 24. Re1 Ng4 25. Rxd5 Qf6  26. Rd2 Qxf2+ 27. Kh1 Bf3  28. Bxf3 exf3 29. Red1  Qxh2+ 30. Rxh2 Rxh2+ 31. Kg1 Rg2+ 32. Kf1 Nh2+ 33. Ke1 Re2# 0-1 "

; sample game 270
EventSites(270) = "RUS-CHN Summit (Women) 4th  Nizhnij Novgorod" : GameDates(270) = "20070822" : WhitePlayers(270) = "Kosintseva, Nadezhda   G#270" : WhiteElos(270) = "2475" : BlackPlayers(270) = "Shen, Yang   G#270" : BlackElos(270) = "2439" : Each_Game_Result(270) = "1-0"

FilePGNs(270) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. d3 b5 7. Bb3 d6 8. a4  Bd7 9. Bd2 O-O 10. axb5 axb5 11. Nc3 Rb8 12. h3 Qc8 13. Bg5  Nb4 14. Qe2 h6 15. Bd2 Be6 16. d4 Bxb3 17. cxb3 Qe8  18. Rac1  Bd8 19. d5 Na6 20. Be3 Rb7 21. Ra1 Nb4 22. Rfc1 c5 23. dxc6 Nxc6 24. Ra6  Na5  25. Nd2 b4  26. Na4  Rc7 27. Rd1 Rc6 28. Qd3 Rxa6 29. Qxa6 Qc6 30. Qxc6 Nxc6 31. Nc4 Nxe4 32. Nxd6 Nxd6 33. Rxd6 Na5 34. Rd5 Nxb3 35. Rxe5 Bc7 36. Rb5 Rd8  37. Kf1  Bd6 38. Rd5 Bc7 39. Rxd8+ Bxd8 40. Ke2 Be7 41. Kd3 Na1 42. Nb6  f5 43. Nd5 Bd6 44. Bd2  b3 45. Bb4 Be5 46. Bc3 Bd6 47. Ne3 g6 48. Nc4 Bc5 49. f3 g5 50. Nd2 Bf2 51. g4 fxg4 52. fxg4 h5 53. Ne4 hxg4 54. Nxf2 gxh3 55. Nxh3 g4 56. Nf4 Kf7 57. Ke3 Nc2+ 58. Ke4 Ke7 59. Nd5+ Kd6 60. Ne3 1-0 "

; sample game 271
EventSites(271) = "RUS-CHN Summit (Women) 4th  Nizhnij Novgorod" : GameDates(271) = "20070823" : WhitePlayers(271) = "Kosintseva, Tatiana   G#271" : WhiteElos(271) = "2502" : BlackPlayers(271) = "Huang Qian   G#271" : BlackElos(271) = "2410" : Each_Game_Result(271) = "1-0"

FilePGNs(271) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be3 e5 7. Nb3 Be6 8. Qd2 Be7 9. f4 exf4 10. Bxf4 Nc6 11. O-O-O Ne5 12. Kb1 O-O 13. h3 b5 14. g4 Qc7  15. Nd5 Bxd5 16. exd5 Nc4 17. Qg2 Nd7 18. g5 Rfe8  19. h4 Bf8 20. h5 Nc5 21. Qf3  Na4 22. Bc1 Rac8  23. Nd4 Ne5 24. Qg3 Qc5 25. Bg2 Qb4 26. Nc6 Qg4 27. Qxg4 Nxg4 28. Rde1 Ne5 29. Bf4 Nc4 30. Bh3 Ra8 31. g6 fxg6 32. Be6+ Kh8 33. hxg6 h6 34. b3 Nc3+ 35. Ka1 Nb6 36. Be3 Nbxd5 37. Bd4 Rxe6 38. Rxe6 Rc8 39. Rf1 Kg8 40. Kb2 b4 41. Nxb4 Nb5 42. Nxd5 Nxd4 43. Ne7+ Bxe7 44. Rxe7 Nc6 45. Rd7 1-0 "

; sample game 272
EventSites(272) = "RUS-CHN Summit Men 4th  Nizhnij Novgorod" : GameDates(272) = "20070824" : WhitePlayers(272) = "Ni Hua   G#272" : WhiteElos(272) = "2681" : BlackPlayers(272) = "Alekseev, Evgeny   G#272" : BlackElos(272) = "2689" : Each_Game_Result(272) = "0-1"

FilePGNs(272) = "1. e4 c5 2. Nf3 d6 3. Bb5+ Bd7 4. Bxd7+ Qxd7 5. c4 Nf6 6. Nc3 Nc6 7. d4 cxd4 8. Nxd4 e6 9. O-O Be7 10. Be3 O-O 11. Rc1 a6 12. Qe2 Rac8 13. f3 Qc7 14. b3 Qa5 15. Kh1 Rfe8 16. Nxc6 Rxc6 17. f4 Qh5  18. Qd3 Nd7 19. Rf3 Qa5 20. Bd2 Qd8 21. Rh3 g6 22. Rf1 Bf6 23. g4  Bg7 24. g5 f5  25. exf5  gxf5 26. Ne2  b5 27. Nd4 Rc7 28. Ba5 Qa8+ 29. Nf3 Rc6 30. Bc3 bxc4 31. bxc4 Nc5 32. Qe3 Rc7 33. Bxg7 Rxg7 34. Qd4 Qc6 35. g6  hxg6 36. Rg1 e5 37. fxe5 dxe5 38. Qh4 Nd3 39. Rd1 Nf4 40. Rd6 Qxd6 41. Qh8+ Kf7 42. Ng5+ Kf6  43. Nh7+ Ke7 44. Qxg7+ Kd8 0-1 "

; sample game 273
EventSites(273) = "RUS-CHN Summit Men 4th  Nizhnij Novgorod" : GameDates(273) = "20070826" : WhitePlayers(273) = "Alekseev, Evgeny   G#273" : WhiteElos(273) = "2689" : BlackPlayers(273) = "Zhang Pengxiang   G#273" : BlackElos(273) = "2649" : Each_Game_Result(273) = "1-0"

FilePGNs(273) = "1. d4 d5 2. Nf3 c6 3. c4 dxc4 4. e3 Be6 5. Nc3 Nf6  6. Ng5 Qc8 7. a4  a5  8. e4 h6 9. Nxe6 Qxe6 10. e5 Nbd7 11. Be2 Nd5 12. O-O N7b6 13. Bg4 Qg6 14. e6 Nf6  15. Bh3 Qd3 16. Qe1  O-O-O 17. Qe5  1-0 "

; sample game 274
EventSites(274) = "Amsterdam NH Hotels  Amsterdam" : GameDates(274) = "20070901" : WhitePlayers(274) = "Karjakin, Sergey   G#274" : WhiteElos(274) = "2678" : BlackPlayers(274) = "Beliavsky, Alexander G   G#274" : BlackElos(274) = "2653" : Each_Game_Result(274) = "1-0"

FilePGNs(274) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Bb7 10. d4 Re8 11. a4 Bf8  12. Bg5  h6 13. Bxf6 Qxf6 14. Bd5 Rab8 15. axb5 axb5 16. Na3 Ne7 17. Bxb7 Rxb7 18. d5  Reb8 19. Nc2 c6 20. dxc6 Nxc6 21. Ne3  Qe6 22. Qd3 Qd7 23. Red1 Ra7 24. Nd5 b4 25. Nd2 bxc3 26. bxc3 Rxa1 27. Rxa1 Nd8 28. Nc4 Qb5 29. Ra5  Qb7 30. Ra4 Ne6 31. Rb4 Qa7 32. g3 Ra8 33. Kg2 Qa1 34. Ncb6 Nc5 35. Qf3 Rd8 36. h4 Qe1  37. Na4  Ra8 38. Nxc5 Ra1  39. Kh3 dxc5 40. Rb7 Qh1+  41. Qxh1 Rxh1+ 42. Kg2 Ra1  43. Rb8 g6 44. Re8 h5 45. Rxe5  Ra8 46. Re8  Ra7 47. e5 Kg7 48. Kf3 c4 49. Rc8 Ra5 50. Rd8 Bc5 51. Nf6 Be7 52. Rg8+ Kh6 53. Ke4 Bxf6 54. exf6 Kh7 55. Rg7+ Kh6 56. Rxf7 Ra2 57. f4 1-0 "

; sample game 275
EventSites(275) = "RUS-ch Higher League 60th  Krasnoiarsk" : GameDates(275) = "20070904" : WhitePlayers(275) = "Vitiugov, Nikita   G#275" : WhiteElos(275) = "2608" : BlackPlayers(275) = "Popov, Ivan1   G#275" : BlackElos(275) = "2524" : Each_Game_Result(275) = "1-0"

FilePGNs(275) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 a6 5. Ne5  Nbd7 6. Bf4 dxc4 7. Nxc4 b5 8. Ne5 Bb7 9. e3 e6 10. Qf3 Qb6 11. Nxd7 Nxd7 12. Bd3 c5 13. Be4 Bxe4 14. Nxe4 Rc8 15. O-O f5  16. Ng5 Be7 17. Qh5+ g6 18. Qh6 Bf8 19. Qh3 Bg7 20. Rad1 h6 21. Nf3 cxd4 22. exd4 Nf6 23. Rc1  Rxc1 24. Rxc1 Nd5  25. Be5 O-O 26. Qg3 g5 27. h4 g4 28. Bxg7 Kxg7 29. Qe5+ Kf7  30. Ne1  Qb7 31. Nd3 Rc8 32. Re1 Qc6 33. Nc5 Re8 34. Rc1   Rc8  35. g3 Nf6 36. Qe3 Qd5 37. Re1 Re8  38. Qxh6 Qxd4 39. h5   Qxc5 40. Qg6+ Ke7 41. Qg7+ Kd6 42. Qxf6 Kd7 43. h6 Qe7 44. Qc3 Qd6 45. h7 Qf8 46. Qe3 e5 47. Rd1+ 1-0 "

; sample game 276
EventSites(276) = "RUS-ch Higher League 60th  Krasnoiarsk" : GameDates(276) = "20070905" : WhitePlayers(276) = "Vitiugov, Nikita   G#276" : WhiteElos(276) = "2608" : BlackPlayers(276) = "Vorobiov, Evgeny E   G#276" : BlackElos(276) = "2572" : Each_Game_Result(276) = "1-0"

FilePGNs(276) = "1. d4 d5 2. Nf3 e6 3. g3 b5  4. Bg2 Nf6 5. O-O Nbd7 6. Nbd2 Bb7 7. c3 Be7 8. a4 a6  9. b4 a5  10. bxa5 Rxa5 11. Nb3 Rxa4 12. Rxa4 bxa4 13. Na5 Qa8 14. Nxb7 Qxb7 15. Qxa4 O-O 16. c4  Nb6 17. Qb5 c6 18. Qb1 Qa6 19. c5 Nc4 20. Bf4 Ne4 21. h4 f6  22. Qc2  Ra8 23. Ne1 e5  24. Bxe4 dxe4 25. dxe5 fxe5 26. Bc1  e3 27. Bxe3 Nxe3 28. fxe3 Qa2 29. Qe4 Qxe2  30. Qxc6 Qxe3+ 31. Kh2 Rf8 32. Qd5+ Kh8 33. Rxf8+ Bxf8 34. Nd3 Qe2+ 35. Kg1 h5   36. c6 e4 37. Nf4  Qe3+ 38. Kh2 Qf2+ 39. Ng2 Bc5 40. Qxh5+ Kg8 41. Qe8+ Kh7 42. Qxe4+ g6 43. c7  Qg1+ 44. Kh3 Qh1+ 45. Kg4 Qd1+ 46. Kg5 1-0 "

; sample game 277
EventSites(277) = "Carlsbad Czech Coal  Carlsbad" : GameDates(277) = "20070910" : WhitePlayers(277) = "Laznicka, Viktor   G#277" : WhiteElos(277) = "2594" : BlackPlayers(277) = "Navara, David   G#277" : BlackElos(277) = "2656" : Each_Game_Result(277) = "1/2-1/2"

FilePGNs(277) = "1. d4 Nf6 2. c4 g6 3. f3 Nc6 4. d5 Ne5 5. e4 d6 6. Ne2 Bg7 7. Nec3 c6  8. Be3 cxd5  9. cxd5 O-O 10. Be2  Re8  11. O-O e6 12. f4 Ned7 13. dxe6 Rxe6  14. Nd2  Nxe4  15. Ndxe4 Bxc3 16. bxc3  Rxe4 17. Bd4 Re8  18. Bd3 Nc5 19. f5 Qg5  20. h4  Qxh4 21. Qf3 g5 22. Bxc5 dxc5 23. Bb5 Rf8  24. Rae1  a6 25. Be8  Qh6 26. Qd5 Qf6 27. Qxc5 b6 28. Qc7 Bb7 29. Bd7  Bd5 30. Rd1  Bxa2 31. Rd2  Bb3 32. Rb1  Qe7 33. Qg3  Bc4 34. Re1  Qc5+ 35. Kh1 f6 36. Be6+ Bxe6 37. fxe6 Rae8   38. Qf3 Re7 39. Rd5 Qc4 40. Rd4 Qc7 41. Re3 Kg7 42. Qf5 Qc5 43. Qd3 b5 44. Rd6 a5 45. Rd5 Qc4 46. Qf5 Qf4 47. Qd3 Qc4 48. Qf5 Qh4+ 49. Kg1 Qf4 50. Qd3 Rfe8 51. Re4 Qc1+  52. Kh2 b4 53. Rd7  Qxc3 54. Qd6 Kf8 55. Rxe7 Rxe7 56. Qd8+ Re8 57. Qd6+ Re7 1/2-1/2 "

; sample game 278
EventSites(278) = "Carlsbad Czech Coal  Carlsbad" : GameDates(278) = "20070914" : WhitePlayers(278) = "Movsesian, Sergei   G#278" : WhiteElos(278) = "2667" : BlackPlayers(278) = "Navara, David   G#278" : BlackElos(278) = "2656" : Each_Game_Result(278) = "1-0"

FilePGNs(278) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. h3 Rb8  9. c3 d5 10. exd5 Nxd5 11. Nxe5 Nxe5 12. Rxe5 Bb7 13. d4 Bf6 14. Re1 Re8 15. Na3  b4 16. cxb4 Nxb4 17. Be3 Be4  18. Qe2 Nd3 19. Red1 Bxd4 20. Nc4  Bxe3 21. Nxe3 Rb6 22. Bc4 Rd6 23. Bxd3 Bxd3 24. Qf3 h6 25. Rac1 Be4 26. Qf4 Ree6 27. b3 Qe7 28. Nc4  Rf6 29. Qe5 Rde6 30. Qd4 Rg6 31. Ne3 Kh7 32. Qc5 Qh4 33. Qxc7 Ref6 34. Rd2 Qxh3  35. Qh2 Qf3 36. Re1 Rf5 37. g3 Rh5 38. Qg2 Qf4  39. gxf4 1-0 "

; sample game 279
EventSites(279) = "World Championship  Mexico City" : GameDates(279) = "20070914" : WhitePlayers(279) = "Aronian, Levon   G#279" : WhiteElos(279) = "2750" : BlackPlayers(279) = "Anand, Viswanathan   G#279" : BlackElos(279) = "2792" : Each_Game_Result(279) = "0-1"

FilePGNs(279) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 c6 5. Bg5 h6 6. Bh4 dxc4 7. e4 g5 8. Bg3 b5 9. Ne5 h5 10. h4 g4 11. Be2 Bb7 12. O-O Nbd7 13. Qc2 Nxe5 14. Bxe5 Bg7 15. Rad1 O-O 16. Bg3 Nd7 17. f3 c5   18. dxc5 Qe7 19. Kh1  a6 20. a4 Bc6 21. Nd5  exd5 22. exd5 Be5  23. f4 Bg7 24. dxc6 Nxc5 25. Rd5 Ne4 26. Be1 Qe6 27. Rxh5 f5 28. Kh2 Rac8 29. Bb4 Rfe8 30. axb5 axb5 31. Re1 Qf7 32. Rg5 Nxg5 33. fxg5 Rxc6 34. Bf1 Rxe1 35. Bxe1 Re6 36. Bc3 Qc7+ 37. g3 Re3 38. Qg2 Bxc3 39. bxc3 f4 40. Qa8+ Kg7 41. Qa6 fxg3+ 0-1 "

; sample game 280
EventSites(280) = "World Championship  Mexico City" : GameDates(280) = "20070914" : WhitePlayers(280) = "Kramnik, Vladimir   G#280" : WhiteElos(280) = "2769" : BlackPlayers(280) = "Morozevich, Alexander   G#280" : BlackElos(280) = "2758" : Each_Game_Result(280) = "1-0"

FilePGNs(280) = "1. Nf3 Nf6 2. c4 e6 3. g3 d5 4. d4 dxc4 5. Bg2 a6 6. Ne5 Bb4+ 7. Nc3 Nd5 8. O-O  O-O 9. Qc2 b5 10. Nxd5 exd5 11. b3 c6 12. e4 f6  13. exd5  fxe5 14. bxc4 exd4 15. dxc6 Be6 16. cxb5  d3 17. c7  Qd4  18. Qa4 Nd7 19. Be3 Qd6 20. Bxa8 Rxa8 21. Bf4  Qf8  22. b6  Ne5 23. Bxe5 Qf3 24. Qd1 Qe4 25. b7 Rf8 26. c8=Q Bd5 27. f3 1-0 "

; sample game 281
EventSites(281) = "World Championship  Mexico City" : GameDates(281) = "20070916" : WhitePlayers(281) = "Kramnik, Vladimir   G#281" : WhiteElos(281) = "2769" : BlackPlayers(281) = "Grischuk, Alexander   G#281" : BlackElos(281) = "2726" : Each_Game_Result(281) = "1/2-1/2"

FilePGNs(281) = "1. d4 Nf6 2. c4 e6 3. g3 d5 4. Bg2 Be7 5. Nf3 O-O 6. O-O dxc4 7. Qc2 a6 8. Qxc4 b5 9. Qc2 Bb7 10. Bd2 Ra7 11. a3  Nbd7  12. Ba5 Qa8  13. Qxc7 Rc8 14. Qf4 Rc2 15. Nbd2 Rxb2 16. Rfc1 Nd5 17. Qe4 b4  18. Qd3 bxa3 19. Nc4 Bc6 20. Nxa3 Bb5 21. Nc4 Bb4 22. Qd1 Bxc4 23. Rxc4 Bxa5 24. Rxa5  Qb8 25. Nd2 N5b6 26. Rc1 g6 27. Ne4 Rb5 28. Ra2 a5 29. Nc5  Qd6 30. Nb7 Qb8 31. Qd3  Rh5 32. Nc5  Nd5 33. Qc4 N5b6 34. Qc3 Nd5 35. Qa1 Nxc5 36. Rxc5 Nb4 37. Raxa5 Nc2 38. Rxa7  Nxa1 39. Ra8 Qxa8 40. Bxa8 Rxc5 41. dxc5 Kf8 42. c6 Ke7 43. c7 Kd7 44. Bc6+ Kxc7 45. Ba4 Kb6 46. Kg2 Kc5 47. Kf3 Kb4 48. Be8 f6 49. Bf7 Nb3 50. e3 Nc5 51. h4  Kc3 52. Bg8 h6 53. Bf7 g5 54. Kg4 Ne4 55. hxg5 hxg5 56. Bxe6 Nxf2+ 57. Kf5 Kd3 58. Kxf6 Ne4+ 59. Kg6 Nxg3 60. Kxg5 Kxe3 1/2-1/2 "

; sample game 282
EventSites(282) = "World Championship  Mexico City" : GameDates(282) = "20070919" : WhitePlayers(282) = "Grischuk, Alexander   G#282" : WhiteElos(282) = "2726" : BlackPlayers(282) = "Svidler, Peter   G#282" : BlackElos(282) = "2735" : Each_Game_Result(282) = "1/2-1/2"

FilePGNs(282) = "1. Nf3 d5 2. d4 Nf6 3. c4 c6 4. Nc3 e6 5. Bg5 h6 6. Bh4 dxc4 7. e4 g5 8. Bg3 b5 9. Be2 Bb7 10. h4 g4 11. Ne5 h5 12. O-O Nbd7 13. Qc2 Nxe5 14. Bxe5 Bg7 15. Bg3  Qxd4 16. Rfd1 Qc5  17. Bd6 Qb6 18. a4 a6  19. e5 Nd7 20. a5  Qa7 21. Ne4 c5 22. Ng5 Nxe5  23. Bxe5 Bxe5 24. Bxc4  bxc4 25. Qa4+ Kf8 26. Rd7 Bd5  27. Rd1  Bd4 28. Rxa7 Rxa7 29. b3 Kg7 30. bxc4 Ba8 31. Qc2 g3 32. Rxd4 cxd4 33. Qe2 gxf2+ 34. Qxf2 Rd8 35. Qg3 Kf8 36. Qe5  Ke8   37. Nxe6   fxe6 38. Qh8+ Ke7 39. Qg7+ Ke8 40. Qh8+ Ke7 41. Qg7+ 1/2-1/2 "

; sample game 283
EventSites(283) = "World Championship  Mexico City" : GameDates(283) = "20070924" : WhitePlayers(283) = "Svidler, Peter   G#283" : WhiteElos(283) = "2735" : BlackPlayers(283) = "Morozevich, Alexander   G#283" : BlackElos(283) = "2758" : Each_Game_Result(283) = "1/2-1/2"

FilePGNs(283) = "1. e4 c6 2. d4 d5 3. Nd2 dxe4 4. Nxe4 Nd7 5. Ng5 Ngf6 6. Bd3 e6 7. N1f3 Bd6 8. Qe2 h6 9. Ne4 Nxe4 10. Qxe4 Qc7 11. O-O b6 12. Qg4 Kf8 13. Bd2  Bb7 14. Rfe1 Rd8 15. Rad1 c5   16. dxc5 bxc5 17. h4 Nf6 18. Qh3 c4  19. Bf1 Bd5 20. h5 Kg8 21. Be3 Kh7 22. Bd4 Rhe8 23. b3 cxb3  24. axb3 Ne4  25. Bb5  Re7 26. Qg4 f5 27. Qg6+ Kg8 28. c4 Ba8 29. Be3  Rf8  30. Bd4 a6  31. c5 Bxc5 32. Bc4 Qb6  33. Bxc5  Qxc5  34. Bxe6+ Kh8 35. Rd4 Bc6 36. Bxf5 Nf6 37. Rc4 Rxe1+ 38. Nxe1 Qe7 39. Nd3 Be8 40. Qg3 Nxh5 41. Qg4 Bf7 42. Rc5 Qd6 43. Qb4 Bg8 44. Ra5 Qxb4 1/2-1/2 "

; sample game 284
EventSites(284) = "EU-Cup 23rd  Kemeri" : GameDates(284) = "20071006" : WhitePlayers(284) = "Petrosian, Tigran L   G#284" : WhiteElos(284) = "2604" : BlackPlayers(284) = "Avrukh, Boris   G#284" : BlackElos(284) = "2645" : Each_Game_Result(284) = "0-1"

FilePGNs(284) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. e4 Nxc3 6. bxc3 Bg7 7. Be3 c5 8. Rc1 Qa5 9. Qd2 O-O 10. Nf3 Rd8 11. d5 e6 12. c4 Qxd2+ 13. Kxd2 Na6  14. Bg5  f6 15. Be3 b6 16. Ng1  f5 17. f3 Re8   18. Bg5 fxe4 19. fxe4 exd5 20. exd5 Bf5 21. Ne2 Re4 22. h3 h6 23. Bf4 h5  24. g3   Rae8 25. Rh2 Nb4  26. g4 hxg4 27. hxg4 Bxg4 28. Rf2 Bxe2 29. Bxe2 Rd4+ 0-1 "

; sample game 285
EventSites(285) = "EU-Cup 23rd  Kemeri" : GameDates(285) = "20071007" : WhitePlayers(285) = "Grischuk, Alexander   G#285" : WhiteElos(285) = "2715" : BlackPlayers(285) = "Avrukh, Boris   G#285" : BlackElos(285) = "2645" : Each_Game_Result(285) = "1-0"

FilePGNs(285) = "1. Nf3 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. g3 Bg7 6. Bg2 Nb6 7. d4 Nc6 8. e3 e5 9. d5 Ne7 10. e4 Bg4 11. h3 Bxf3 12. Qxf3 c6 13. O-O cxd5 14. Nxd5 Nexd5   15. exd5 Qd6  16. Qb3 O-O 17. Bd2  Rfc8 18. Bb4 Qd7 19. d6 Rc4 20. a4  e4 21. Rfd1 Rd8 22. Bf1   Rd4 23. a5 Nc8 24. Rxd4 Bxd4 25. Rd1 Be5 26. Qd5  Bxd6 27. Qxe4 Qa4 28. Qd4 Ne7 29. b3  Qxb3 30. Bc3 Kf8 31. Bc4 Qa4 32. Qh8+ Ng8 33. Qg7+ 1-0 "

; sample game 286
EventSites(286) = "Bundesliga 0708  Germany" : GameDates(286) = "20080309" : WhitePlayers(286) = "Postny, Evgeny   G#286" : WhiteElos(286) = "2598" : BlackPlayers(286) = "Fedorchuk, Sergey A   G#286" : BlackElos(286) = "2652" : Each_Game_Result(286) = "1-0"

FilePGNs(286) = "1. d4 Nf6 2. c4 e6 3. g3 Bb4+ 4. Bd2 a5 5. Nf3 b6 6. Bg2 O-O 7. O-O Ba6 8. Ne5 Ra7 9. Bxb4 axb4 10. a3 Bc8  11. Nd3 bxa3 12. Nxa3 Bb7 13. Bxb7 Rxb7 14. Nb5 d5 15. cxd5 Qxd5 16. Qa4 c6 17. Nc3 Qh5 18. Nf4 Qf5 19. Rfe1  e5  20. dxe5 Qxe5 21. Red1 b5 22. Qd4 Qe7 23. Qd6 Qxd6 24. Rxd6 Rd7 25. Rxd7 Nbxd7 26. Nd3 Re8 27. Ra6 c5 28. Kf1  Rb8 29. Rc6 c4 30. Nb4 Kf8 31. Ra6 Nc5  32. Ra5 Nfe4 33. Rxb5  Rxb5 34. Nxb5 Na4 35. Ke1 Nxb2 36. f3 Nc5 37. Kd2 Nba4 38. Nd5  Nb3+ 39. Kc2 h5  40. Ne3 Nb6 41. h3  g5  42. g4 Nc5  43. gxh5 Ne6 44. Nf5  Nd7  45. h6 Kg8 46. Nbd6 Ne5 47. Ne4 Nf4 48. Nf6+ Kh8 49. e3 Ng2 50. Kc3 Nh4 51. Nxh4 gxh4 52. f4 Nf3 53. Ne4  Ng1 54. Nf2 Kh7 55. Kxc4 Kxh6 56. Kd3 f5  57. Kd2 Kg6 58. Nd3  Kh5 59. Ne5 Nxh3 60. Ke2 Ng5 61. fxg5 Kxg5 62. Kf3 Kf6 63. Kf4 h3 64. Nf3 Ke6 65. Ng5+ 1-0 "

; sample game 287
EventSites(287) = "EU-chT (Men) 16th  Crete" : GameDates(287) = "20071030" : WhitePlayers(287) = "Karjakin, Sergey   G#287" : WhiteElos(287) = "2694" : BlackPlayers(287) = "Roiz, Michael   G#287" : BlackElos(287) = "2644" : Each_Game_Result(287) = "0-1"

FilePGNs(287) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Nb8 10. d4 Nbd7 11. Nbd2 Bb7 12. Bc2 Re8 13. Nf1 Bf8 14. Ng3 g6 15. b3 Bg7 16. d5 Qe7 17. c4 c5   18. a3  b4 19. Nh4  Qd8 20. Nhf5  gxf5 21. Nxf5 Nf8 22. axb4 cxb4 23. Qd2  a5 24. Nxg7  Kxg7 25. Qh6+ Kh8 26. Bg5 N8d7  27. f4 Rg8 28. fxe5 Rg6 29. Qh4 Nxe5 30. Rf1 Qb6+ 31. Kh1 Nfd7  32. Rf5 Rag8 33. Re1 a4 34. bxa4 b3 35. Bb1 f6 36. Be3 Qb4 37. Rh5 R8g7 38. Bh6 Rf7 39. Qf2 Ba6 40. Rg1 Bxc4 41. Qf5 Qxa4 42. Qe6 Qa6 43. Bf4 Nc5 44. Qf5 Kg8 45. Be3 Bd3 0-1 "

; sample game 288
EventSites(288) = "EU-chT (Men) 16th  Crete" : GameDates(288) = "20071031" : WhitePlayers(288) = "Vallejo Pons, Francisco   G#288" : WhiteElos(288) = "2660" : BlackPlayers(288) = "Naiditsch, Arkadij   G#288" : BlackElos(288) = "2639" : Each_Game_Result(288) = "1-0"

FilePGNs(288) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. Ng5 d5 5. exd5 b5 6. Bf1 h6 7. Nxf7  Kxf7 8. dxc6 Bc5 9. Be2 Bxf2+ 10. Kxf2  Ne4+ 11. Kf1  Rf8 12. d3 Qd4 13. Qe1  Kg8+ 14. Bf3  Ng5 15. Bxg5 hxg5 16. Ke2  e4 17. Bxe4 Bg4+ 18. Kd2 Rf2+ 19. Kc1 Raf8 20. Nc3  b4 21. Bd5+  Kh8 22. h4  Bh5 23. hxg5 g6 24. Bf3 bxc3 25. Qxc3 Qxc3 26. bxc3 Kg7 27. Rb1 Bxf3 28. gxf3 Re8 29. Rb7 1-0 "

; sample game 289
EventSites(289) = "EU-chT (Men) 16th  Crete" : GameDates(289) = "20071031" : WhitePlayers(289) = "Roiz, Michael   G#289" : WhiteElos(289) = "2644" : BlackPlayers(289) = "Balogh, Csaba   G#289" : BlackElos(289) = "2562" : Each_Game_Result(289) = "1-0"

FilePGNs(289) = "1. Nf3 Nf6 2. g3 d5 3. Bg2 e6 4. O-O Nbd7  5. d3 b6 6. c4  Bb7 7. cxd5 exd5  8. Nc3 Be7 9. e4   dxe4  10. dxe4 Nc5 11. Nd4  O-O 12. e5 Bxg2 13. Kxg2 Nd5 14. Nc6 Nxc3 15. bxc3 Qe8 16. Qd5 Kh8  17. Ba3  f5 18. f4 Rg8 19. Rad1 Bf8 20. Nd8  Rxd8 21. Qxd8 Qa4 22. Bxc5 Bxc5 23. Qd2 Qe4+ 24. Rf3 1-0 "

; sample game 290
EventSites(290) = "EU-chT (Men) 16th  Crete" : GameDates(290) = "20071101" : WhitePlayers(290) = "Vallejo Pons, Francisco   G#290" : WhiteElos(290) = "2660" : BlackPlayers(290) = "Jones, Gawain C   G#290" : BlackElos(290) = "2567" : Each_Game_Result(290) = "1-0"

FilePGNs(290) = "1. e4 c5 2. Ne2 Nc6 3. d4 cxd4 4. Nxd4 g6 5. c4 Bg7 6. Be3 Nf6 7. Nc3 O-O 8. Be2 d6 9. O-O Bd7 10. Qd2 Nxd4 11. Bxd4 Bc6 12. Bd3  a5 13. Rfe1  Ng4   14. Bxg7 Kxg7 15. Be2 Nf6 16. Qd4 e5  17. Qe3 Nd7  18. Rad1 Nc5 19. Rd2 Qe7 20. Bd1  a4 21. Bc2 Rfd8 22. Red1 Ne6 23. Ne2 Qc7  24. f4  Qa5 25. f5  Qc5 26. Kf2  Qxe3+ 27. Kxe3 gxf5 28. exf5 Nc7 29. Nc3  Kf8 30. Rxd6 Rxd6 31. Rxd6 a3 32. b4 Bxg2 33. Kf2  Bh1 34. b5  b6 35. Rxb6 Rd8 36. Ke3 Rd4 37. f6 Rxc4 38. Rb8+ Ne8 39. Ne4  1-0 "

; sample game 291
EventSites(291) = "EU-chT (Men) 16th  Crete" : GameDates(291) = "20071101" : WhitePlayers(291) = "Tkachiev, Vladislav   G#291" : WhiteElos(291) = "2661" : BlackPlayers(291) = "Karjakin, Sergey   G#291" : BlackElos(291) = "2694" : Each_Game_Result(291) = "0-1"

FilePGNs(291) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. e3 a6 5. Bd2 e6 6. Qc2 Nbd7 7. Nc3 c5 8. cxd5 exd5 9. Be2 Be7 10. O-O O-O 11. Rfd1 b5 12. Ne5 cxd4  13. Nc6 Qe8 14. exd4 Bd6 15. a3 Nb6 16. Nb4 Bb7 17. Nd3 Ne4 18. Bf4 Bxf4 19. Nxf4 Rc8 20. Bf3 Na4 21. Nfe2 Qd7 22. Rab1 Ng5  23. Qd3 Nb6 24. h4 Nxf3+ 25. Qxf3 Nc4 26. Nc1  Qe7  27. Qg3  Nd2  28. Ra1 Ne4 29. Nxe4 dxe4 30. Nb3 Bd5 31. Nc5 Rc6 32. Qe5  Qd8  33. Nb7  Qxh4 34. Qxd5 Rh6 35. Kf1 Rf6 36. f3 exf3 37. gxf3 Qh2 38. Qe4 Rg6 39. Qe3 Rg2 0-1 "

; sample game 292
EventSites(292) = "Moscow Tal mem  Moscow" : GameDates(292) = "20071116" : WhitePlayers(292) = "Shirov, Alexei   G#292" : WhiteElos(292) = "2739" : BlackPlayers(292) = "Carlsen, Magnus   G#292" : BlackElos(292) = "2714" : Each_Game_Result(292) = "1-0"

FilePGNs(292) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Nxe4 6. d4 b5 7. Bb3 d5 8. dxe5 Be6 9. Nbd2 Be7 10. c3 O-O 11. Re1 Nc5 12. Nd4 Nxd4 13. cxd4 Nd3 14. Re3 Nxc1 15. Rxc1 c5  16. dxc5 Rc8 17. Rec3   b4 18. R3c2  Bf5 19. c6 Bxc2 20. Rxc2 Qa5 21. Nf3 Rfd8 22. Nd4 g6 23. e6  Bf6 24. exf7+ Kxf7 25. h4  Qb6 26. Rd2 Rd6  27. Nf5  Rdxc6 28. Bxd5+ Kf8 29. Bxc6 Rxc6 30. Ne3 Bxh4 31. Qf3+ Rf6  32. Qa8+ Kg7 33. Qe4 b3 34. axb3 1-0 "

; sample game 293
EventSites(293) = "World Cup  Khanty-Mansiysk" : GameDates(293) = "20071127" : WhitePlayers(293) = "Vallejo Pons, Francisco   G#293" : WhiteElos(293) = "2660" : BlackPlayers(293) = "Inarkiev, Ernesto   G#293" : BlackElos(293) = "2674" : Each_Game_Result(293) = "0-1"

FilePGNs(293) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. Ng5 d5 5. exd5 Na5 6. Bb5+ c6 7. dxc6 bxc6 8. Qf3 Rb8 9. Bd3 Be7  10. Nc3 O-O 11. a3   c5 12. b3  Rb6  13. O-O Bb7  14. Qh3  h6 15. Nge4 Nh7 16. b4  cxb4 17. axb4 Bxb4 18. Ba3 f5 19. Bxb4 Rxb4 20. Nc5 Ng5 21. Qe3 Ba8 22. f4 exf4 23. Rxf4 Re8  24. Rxb4  Rxe3 25. dxe3 Nc6 26. Rb5  f4  27. h4  f3  28. N5e4  Nxe4 29. Nxe4 fxg2 30. Kxg2 Qe8  31. Rab1 a6  32. Rb6 a5  33. R1b5 a4  34. Kf2 a3 35. Ra6 Qc8 36. Rc5  Qf8+  37. Ke2 Nb4 38. Raa5 a2 39. Bc4+  Kh7   40. Rcb5 Bxe4 0-1 "

; sample game 294
EventSites(294) = "World Cup  Khanty-Mansiysk" : GameDates(294) = "20071130" : WhitePlayers(294) = "Inarkiev, Ernesto   G#294" : WhiteElos(294) = "2674" : BlackPlayers(294) = "Aronian, Levon   G#294" : BlackElos(294) = "2741" : Each_Game_Result(294) = "1/2-1/2"

FilePGNs(294) = "1. d4 d5 2. Nf3 Nf6 3. c4 e6 4. g3 Be7 5. Bg2 O-O 6. O-O dxc4 7. Qc2 a6 8. Qxc4 b5 9. Qc2 Bb7 10. Bd2 Be4 11. Qc1 Bb7 12. Bf4 Bd6 13. Nbd2 Nd5 14. Bxd6   cxd6 15. e4 Ne7 16. Qc3 Nd7 17. a4  bxa4 18. Rxa4 Rc8  19. Qa3  d5  20. exd5 Nxd5 21. Ra1 Nc7  22. Rc4 Nb5 23. Qe3 Rxc4 24. Nxc4 Qa8  25. Na5  Bd5 26. Ne1  Bxg2 27. Nxg2 Rc8 28. Ne1  h6 29. Nb3 Rd8 30. Nd3 Qd5  31. Nb4  Qd6 32. Nxa6 Nf6 33. Ra4 Qd5 34. Nac5  Qh5 35. f3 Nd6 36. Qe2 Qd5 37. Kg2  Rb8 38. Qd3 g5  39. Kf2  g4  40. Ra1 gxf3 41. Qxf3 Nde4+ 42. Kg2 Nxc5 43. Qxd5 Nxd5 44. Nxc5 Rxb2+ 45. Kf3  Nc7  46. h4 Nb5 47. Ra8+ Kg7 48. Rd8 Rc2 49. Ne4 f5  50. Rd7+ Kg6 51. Nf2 Rc3+ 52. Kg2  Nc7 53. Re7  Rc2 54. Kf3 Kf6 55. Rh7  Nb5 56. Ke3 Nc3 57. Nd3  Kg6 58. Rd7 Nd5+ 59. Kf3 Rc3 60. Ke2 Rc7 61. Rxc7 Nxc7 62. Nf4+ Kf6 63. Ke3 Nb5 64. Ne2 Nd6 65. Kf4 Nb5 66. Kf3 1/2-1/2 "

; sample game 295
EventSites(295) = "RUS-ch superfinal 60th  Moscow" : GameDates(295) = "20071226" : WhitePlayers(295) = "Morozevich, Alexander   G#295" : WhiteElos(295) = "2755" : BlackPlayers(295) = "Grischuk, Alexander   G#295" : BlackElos(295) = "2715" : Each_Game_Result(295) = "1-0"

FilePGNs(295) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. cxd5 cxd5 5. Bf4 Nc6 6. e3 Bf5 7. Bb5 e6 8. Qa4 Qb6 9. Nf3 Be7 10. Ne5 O-O 11. Bxc6 Rfc8 12. O-O bxc6 13. Rfc1 c5 14. dxc5 Rxc5 15. b4 Rcc8 16. a3 d4  17. exd4 Qxd4 18. Nc6  Qd7 19. b5 Bf8 20. Qa6 Bc5  21. Rd1 Bd3  22. Bg3 Ng4 23. Qa4 f5 24. h3 f4 25. Bh4  Nh6 26. Ne4 Bf8 27. Qb3 1-0 "

; sample game 296
EventSites(296) = "RUS-ch superfinal 60th  Moscow" : GameDates(296) = "20071227" : WhitePlayers(296) = "Svidler, Peter   G#296" : WhiteElos(296) = "2732" : BlackPlayers(296) = "Morozevich, Alexander   G#296" : BlackElos(296) = "2755" : Each_Game_Result(296) = "0-1"

FilePGNs(296) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be3 e5 7. Nb3 Be6 8. f3 Nbd7 9. g4 Nb6 10. g5 Nh5 11. Qd2 Rc8 12. O-O-O Be7 13. Kb1 O-O 14. Rg1 g6 15. h4 Qc7 16. Rg2 f6  17. Qf2 Nc4 18. Bxc4 Bxc4 19. Bb6 Qd7 20. Nc5 Qc6 21. Nd3 Bxd3  22. cxd3 Nf4 23. Rg4 fxg5 24. hxg5 Bxg5 25. Rh1 Ne6 26. Qh2 Qd7 27. Qh3 Rf7 28. Be3 Rxc3  29. bxc3 Qb5+ 30. Kc2 Nd4+ 31. Bxd4 exd4 32. c4  Qa4+ 33. Kb1 Qb4+ 34. Ka1 Qc3+ 35. Kb1 Qxd3+ 36. Ka1 Qc3+ 37. Kb1 Qb4+ 38. Ka1 Bf6 0-1 "

; sample game 297
EventSites(297) = "RUS-ch superfinal 60th  Moscow" : GameDates(297) = "20071229" : WhitePlayers(297) = "Inarkiev, Ernesto   G#297" : WhiteElos(297) = "2674" : BlackPlayers(297) = "Tomashevsky, Evgeny   G#297" : BlackElos(297) = "2646" : Each_Game_Result(297) = "1-0"

FilePGNs(297) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O b5 6. Bb3 Bb7 7. d3 Be7 8. Nc3 O-O 9. Bd2 d6 10. Ne2  Bc8   11. c3 Be6 12. Bxe6  fxe6 13. a4 Qd7 14. Ng3 Rab8 15. b4  Nd8  16. axb5  axb5 17. Ra6 Nf7 18. Qa1  d5 19. Be3 Ng4  20. Ba7  Ra8 21. h3 Nf6 22. Qa2 Rfc8 23. Ra1 c5  24. bxc5 Bxc5 25. Bxc5 Rxa6 26. Qxa6 Rxc5 27. exd5  Rxd5  28. c4   bxc4 29. dxc4 Rc5 30. Rb1  Rc8 31. Rb7 Qd1+ 32. Kh2 Qd6 33. Qa7  Qf8 34. Rc7 Rd8 35. Qb6 Re8 36. Ra7 e4 37. Nd2 Nd6 38. Ra6 Rd8 39. Qb3 Rb8 40. Rb6 Rc8  41. Qb4  Rd8 42. Rc6 h5 43. Qc5  h4 44. Ngf1 Qe7 45. Qe5  Qd7 46. Ra6 Kf8 47. Kg1 Ke7  48. Nb3  Nf7 49. Qa5 Qd1 50. Qb4+ Nd6 51. Ra1  Qe2 52. Ne3  Qb2 53. c5  Nc8 54. c6+ Kf7 55. Nc4 Qe2 56. Nd4  Qh5 57. Qb7+  1-0 "

; sample game 298
EventSites(298) = "Corus  Wijk aan Zee" : GameDates(298) = "20080112" : WhitePlayers(298) = "Radjabov, Teimour   G#298" : WhiteElos(298) = "2735" : BlackPlayers(298) = "Anand, Viswanathan   G#298" : BlackElos(298) = "2799" : Each_Game_Result(298) = "1-0"

FilePGNs(298) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. Nf3 e6 5. Bg5 h6 6. Bh4 dxc4 7. e4 g5 8. Bg3 b5 9. Be2 Bb7 10. O-O Nbd7 11. Ne5 Bg7 12. Nxd7 Nxd7 13. Bd6 a6 14. Re1 Bf8 15. Bg3 Bg7 16. Bd6 Bf8 17. Bxf8 Rxf8  18. b3 b4 19. Na4 c3 20. a3 a5 21. d5  Qe7 22. d6 Qf6 23. e5  Qf4 24. Bd3 bxa3 25. Qe2  Qd2 26. Rxa3 Qxe2 27. Rxe2 g4  28. Nxc3 Rg8 29. Ne4 Kd8 30. Nd2 c5 31. Bb5  Bd5 32. Nc4 Rg5 33. Rea2 Nxe5 34. Nb6  Rb8 35. Rxa5 Be4 36. Ra7 f6 37. R2a6 Rg8 38. Rc7 Rf8 39. Rxc5 Rf7 40. d7 Nxd7 41. Nxd7 Rxd7 42. Bxd7 Kxd7 43. Rc3 f5 44. Ra7+ Kd6 45. Rh7 Bd5 46. Rxh6 Bxb3 47. h3 gxh3 48. Rhxh3 Bd5 49. Rc2 Ke5 50. f3 Kf6 51. Kf2 Rb4 52. Re2 Kg6 53. Kg3 Ra4 54. Rh4 Ra7 55. Rb2 Kf6 56. Rhb4 Ke5 57. Re2+ Kf6 58. Rd2 Ke5 59. Re2+ Kf6 60. Kf4 Ra3 61. Rd2 Ra5 62. Re2 Ra3 63. Kg3 Ra8 64. Rc2 Ke5 65. Rh4 Rg8+ 66. Kh2 Ra8 67. Re2+ Kf6 68. f4 Ke7 69. Rh7+ Kd6 70. Kg3 Rg8+ 71. Kh3 Rg4 72. g3 Rg8 73. Rd2 Rc8 74. Kh4 Rc3 75. Rg7 Ra3 76. Rc2 Bc6 77. Rc1 Rb3 78. Rg1 Bd5 79. Kg5 Kc5 80. Kf6 Kd4 81. Re1 Rb6 82. Rd7 Rc6 83. Ke7 Ra6 84. Rd6 Ra7+ 85. Kf6 1-0 "

; sample game 299
EventSites(299) = "CZE-ch  Havlickuv Brod" : GameDates(299) = "20080212" : WhitePlayers(299) = "Babula, Vlastimil   G#299" : WhiteElos(299) = "2594" : BlackPlayers(299) = "Konopka, Michal   G#299" : BlackElos(299) = "2447" : Each_Game_Result(299) = "1-0"

FilePGNs(299) = "1. d4 d5 2. c4 e6 3. Nc3 Be7 4. Nf3 Nf6 5. Bg5 h6 6. Bh4 O-O 7. e3 b6 8. Bd3 Bb7 9. O-O Nbd7 10. Qe2 c5 11. Bg3 Ne4 12. cxd5 exd5 13. Rad1 Qc8 14. a4 Nxg3 15. fxg3  Bf6 16. Qf2 cxd4  17. exd4 g6 18. h4  Bg7  19. h5 Nf6 20. hxg6 fxg6 21. Rde1  Ng4  22. Qe2  Re8 23. Qd2 Rxe1 24. Rxe1 Qc7 25. Qf4  Qxf4 26. gxf4  Rf8 27. Bxg6  Rxf4 28. Re8+  Bf8  29. Ne2  Rf6 30. Bh5 Bc6  31. Rc8  Ne3 32. b3 Bd7 33. Rc7 Bg4 34. Bxg4 Nxg4 35. Nc3 Ne3 36. Rxa7  Rc6  37. Ne2 Rc2 38. Nf4 Ng4  39. g3 Rc3  40. Kg2 Ne3+ 41. Kh3 Rxb3  42. Nh5   Bd6 43. Nh4 1-0 "

; sample game 300
EventSites(300) = "CZE-ch  Havlickuv Brod" : GameDates(300) = "20080219" : WhitePlayers(300) = "Talla, Vladimir   G#300" : WhiteElos(300) = "2419" : BlackPlayers(300) = "Babula, Vlastimil   G#300" : BlackElos(300) = "2594" : Each_Game_Result(300) = "0-1"

FilePGNs(300) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e6 6. Be3 Be7 7. f3 O-O 8. Qd2 e5  9. Nb3 Be6 10. O-O-O a5 11. Qe1 Qc8 12. Bb5  Na6 13. Na4 Nb4 14. Qf2 Nxa2+ 15. Kb1 Nb4 16. Nb6 Qc7 17. Nxa8 Rxa8  18. Bb6 Qc8 19. Ba4 d5  20. c3  Na6  21. Nd2 dxe4 22. fxe4 Bc5  23. Bxc5 Nxc5 24. Bc2 a4  25. Qe3 Ng4 26. Qg3 a3 27. b4 Qc6  28. Rc1 Na4  29. Bxa4 Qxa4 30. Ka1  Rd8 31. Rhd1 Nf6 32. Qe1 h6 33. Qe2 Rc8 34. h3 Kh7 35. Qd3 Rc7 36. Qe2 Nd7 37. Nf1  Qb3  38. Qd2  Nb6  39. Ne3 Na4 40. Rc2 0-1 "

; sample game 301
EventSites(301) = "Baku FIDE GP  Baku" : GameDates(301) = "20080504" : WhitePlayers(301) = "Gashimov, Vugar   G#301" : WhiteElos(301) = "2679" : BlackPlayers(301) = "Grischuk, Alexander   G#301" : BlackElos(301) = "2716" : Each_Game_Result(301) = "1-0"

FilePGNs(301) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 d6 5. O-O Bg4 6. h3 h5 7. d4 b5 8. Bb3 Nxd4 9. hxg4 Nxb3 10. axb3 hxg4 11. Ng5 Qd7 12. Qd3   Rb8 13. Rxa6 f6 14. Nc3 fxg5 15. Bxg5 Be7 16. f4  gxf3  17. Qxf3 Nf6 18. Nd5 Nxd5 19. Qf7+ Kd8 20. Qxg7  Kc8 21. Qxh8+ Kb7 22. Qh7  Qg4 23. exd5 Qd4+ 24. Kh1 Bxg5 25. Rfa1 Be3 26. Ra7+ Qxa7 27. Rxa7+ Bxa7 28. g4 Rf8 29. g5 Rf2 30. Qe4 Rf1+ 31. Kh2 Rf4 32. Qxf4  exf4 33. c3 1-0 "

; sample game 302
EventSites(302) = "Baku FIDE GP  Baku" : GameDates(302) = "20080423" : WhitePlayers(302) = "Gashimov, Vugar   G#302" : WhiteElos(302) = "2679" : BlackPlayers(302) = "Svidler, Peter   G#302" : BlackElos(302) = "2746" : Each_Game_Result(302) = "1-0"

FilePGNs(302) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 a6 5. Nc3 b5 6. Be2 Bb7 7. Bf3 Qc7 8. O-O Bd6 9. a4   Bxh2+ 10. Kh1 Be5 11. axb5 Nf6 12. Be3 O-O 13. Qd3 d6 14. Rfd1 Nfd7 15. Qd2  Rc8 16. Be2  Nf6 17. f4 Bxd4 18. Qxd4 d5 19. bxa6 Nxa6 20. e5 Ne8 21. f5  Nc5 22. Bb5  Qd8 23. Rxa8 Bxa8 24. f6 Nd7 25. fxg7 Qc7 26. Bf4 Qb7 27. Rd3  Nxg7 28. Bxd7 Rc4 29. Qf2 Qxd7 30. Rg3 Kh8 31. Bg5 1-0 "

; sample game 303
EventSites(303) = "Baku FIDE GP  Baku" : GameDates(303) = "20080428" : WhitePlayers(303) = "Karjakin, Sergey   G#303" : WhiteElos(303) = "2732" : BlackPlayers(303) = "Inarkiev, Ernesto   G#303" : BlackElos(303) = "2684" : Each_Game_Result(303) = "1-0"

FilePGNs(303) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Na5 10. Bc2 c5 11. d4 Qc7 12. Nbd2 cxd4 13. cxd4 Nc6 14. Nb3 a5 15. Be3 a4 16. Nbd2 Bd7 17. Rc1 Qb7 18. Nf1 Rfe8 19. Ng3 Bd8 20. Qe2 h6 21. Bd3  Rb8 22. dxe5 Nxe5 23. Nxe5 dxe5 24. b4 axb3 25. axb3 Bb6  26. b4 Rec8 27. Kh2 Be6 28. Rxc8+ Qxc8 29. Rc1 Qd8 30. Bxb6 Rxb6 31. Qe3 Qb8 32. Qc5 Bd7  33. Ra1 Rc6 34. Qe3 Rd6 35. Ne2 Bc6 36. f3 Nd7  37. Ra5  Rd4  38. Qd2 Rd6 39. Ng3 Nf8 40. Qc3 Qb6  41. Nf5 Rd7 42. Bxb5  Rd1 43. Ne3 1-0 "

; sample game 304
EventSites(304) = "EU-ch 9th  Plovdiv" : GameDates(304) = "20080429" : WhitePlayers(304) = "L'Ami, Erwin   G#304" : WhiteElos(304) = "2600" : BlackPlayers(304) = "Bologan, Viktor   G#304" : BlackElos(304) = "2665" : Each_Game_Result(304) = "1-0"

FilePGNs(304) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. O-O Nc6 8. d5 Ne7 9. b4 Nh5 10. Re1 a5 11. bxa5 Rxa5 12. Nd2 Nf4 13. Bf1 b6  14. a4 Bd7 15. Nb3 Ra8 16. a5 bxa5 17. Rxa5 Rxa5 18. Nxa5 Qb8 19. Nb5 f5 20. Bxf4 exf4 21. exf5 Nxf5 22. Nc6 Qb6 23. Ne7+ Kf7  24. Nxf5 Bxf5 25. Qd2  f3  26. g3 Bd7 27. c5  dxc5 28. d6 Kg8 29. Nxc7 Bd4 30. Ne6 Rf6  31. Nxd4 cxd4 32. Qa2+ Kh8 33. Re7  Qd8 34. Qd5 Bf5 35. d7 1-0 "

; sample game 305
EventSites(305) = "EU-ch 9th  Plovdiv" : GameDates(305) = "20080425" : WhitePlayers(305) = "Movsesian, Sergei   G#305" : WhiteElos(305) = "2695" : BlackPlayers(305) = "Grigoriants, Sergey   G#305" : BlackElos(305) = "2573" : Each_Game_Result(305) = "1-0"

FilePGNs(305) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Nf3 e6 5. Be2 Nd7 6. O-O h6 7. Nbd2 Ne7 8. Nb3 g5  9. Bd2 Bg7 10. Na5  Rb8 11. c4 b6 12. Nb3 O-O 13. Rc1 dxc4 14. Rxc4 Be4 15. h4 g4 16. Ne1 Bd5 17. Rc3  c5 18. Bxg4 cxd4 19. Rg3 Nxe5 20. Bh3  N7g6 21. h5 f5 22. Nxd4 Bc4 23. Nec2 Bxf1 24. Kxf1 Qh4 25. hxg6 Rbd8 26. Bc3 Nc6 27. Rd3 Ne5 28. Rd2 Nc4 29. Re2 e5 30. Qd3 exd4 31. Qxc4+ Kh8 32. Bb4  Rfe8 33. Rxe8+ Rxe8 34. Qd3 f4 35. Ne1 Qh5 36. Nf3 Qd5 37. b3 a5 38. Bd2 Rf8 39. Kg1 a4 40. bxa4 Qxa2 41. Qb5 Qc2 42. Qxb6 Qxa4 43. Qd6 Qe8 44. Bxf4 Rf6 45. Qxd4 Qxg6 46. Qe3 Rf8 47. Be5 Re8 48. Bxg7+ Kxg7 49. Ne5 1-0 "

; sample game 306
EventSites(306) = "EU-ch 9th  Plovdiv" : GameDates(306) = "20080426" : WhitePlayers(306) = "Movsesian, Sergei   G#306" : WhiteElos(306) = "2695" : BlackPlayers(306) = "Werle, Jan   G#306" : BlackElos(306) = "2581" : Each_Game_Result(306) = "1-0"

FilePGNs(306) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. c3 Nf6 5. d3 d6 6. Bb3 h6 7. O-O g5  8. Be3 Bb6 9. Nbd2 Ne7 10. a4  Ng6 11. d4 g4 12. Ne1 c6 13. Nd3 d5 14. Nxe5 Nxe5 15. dxe5 Nxe4 16. Nxe4 dxe4 17. Qxd8+ Bxd8 18. Rfe1 Bf5 19. Bc2 Be7 20. a5  c5 21. Rad1 h5 22. Ba4+ Kf8 23. Bd7 Bg6 24. Rd5 Rd8 25. Red1 b6 26. a6 Kg7 27. Kf1 Rb8 28. c4 f5 29. Bf4 Rbd8 30. e6 Bf6 31. Bc7 Rdg8 32. Bb5 Rh7 33. Rd7+ Kh8 34. Rxh7+ Kxh7 35. Rd7+ Rg7 36. Bxb6 1-0 "

; sample game 307
EventSites(307) = "EU-ch 9th  Plovdiv" : GameDates(307) = "20080502" : WhitePlayers(307) = "Tiviakov, Sergei   G#307" : WhiteElos(307) = "2635" : BlackPlayers(307) = "Sutovsky, Emil   G#307" : BlackElos(307) = "2630" : Each_Game_Result(307) = "1-0"

FilePGNs(307) = "1. e4 c5 2. c3 d5 3. exd5 Qxd5 4. d4 Nf6 5. Nf3 e6 6. Na3 Nc6 7. Be3 cxd4 8. Nb5 Qd8 9. Nbxd4 Nd5 10. Bg5  Qb6 11. Bc4 Nxd4   12. Nxd4 Bc5 13. Bxd5 Bxd4 14. O-O  Bc5  15. Qe2 h6 16. Bf4 O-O 17. Bc4 Bd7 18. Rad1  Rad8 19. Rd3 Bc8 20. Rg3 Bd6 21. Qg4 g6 22. Bxh6 Bxg3 23. Qxg3 Qc5 24. Bxf8 Kxf8 25. Bb3  Kg7  26. Qf4 b6 27. Rd1 Rxd1+ 28. Bxd1 e5 29. Qd2 Be6 30. a3 Bd5 31. Bc2 Qc4 32. Bd3 Qc6 33. Qg5 e4 34. Qe5+ Kh7 35. Be2 Bc4 36. Bd1 f5 37. Qd4 Bf7  38. g3  Qe6 39. b3 g5 40. Qd2 Qf6 41. Qd4 Qe7 42. b4 f4  43. Bg4  e3 44. fxe3 fxe3 45. Kf1 b5 46. Ke1 Bc4 47. Qd7  Qxd7 48. Bxd7 Kg6 49. Bg4 Kf6 50. Be2 Bd5 51. Bxb5 Bf3 52. h4 gxh4 53. gxh4 Ke5 54. Be2 Be4 55. h5 Kf4 56. c4 Ke5 57. c5 Kd4 58. h6 Ke5 59. b5 1-0 "

; sample game 308
EventSites(308) = "EU-ch 9th  Plovdiv" : GameDates(308) = "20080429" : WhitePlayers(308) = "Huzman, Alexander   G#308" : WhiteElos(308) = "2602" : BlackPlayers(308) = "Wells, Peter K   G#308" : BlackElos(308) = "2521" : Each_Game_Result(308) = "0-1"

FilePGNs(308) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 dxc4 5. Bg5 Bb4 6. e4 c5 7. Bxc4 cxd4 8. Nxd4 Bxc3+ 9. bxc3 Qa5 10. Bb5+ Nbd7 11. Bxf6 Qxc3+ 12. Kf1 gxf6 13. h4 a6 14. Rh3 Qb4  15. Be2 O-O 16. Rb3  Qd6 17. Qd2 Kh8 18. Rg3 Rg8 19. Rxg8+ Kxg8 20. Rd1 Qh2  21. Nf3 Qh1+ 22. Ng1 Qxh4 23. Qc3 Kg7 24. Rd4 Ne5 25. g3 Qh1 26. g4  Nc6  27. Rd3 e5 28. Rh3 Qxe4 29. Bd3 Qd4 30. Rxh7+ Kg8 31. Qd2 Qf4  32. Qc2 Nd4 33. Qc7 Be6 34. Bg6 Rc8 0-1 "

; sample game 309
EventSites(309) = "EU-ch 9th  Plovdiv" : GameDates(309) = "20080424" : WhitePlayers(309) = "Pelletier, Yannick   G#309" : WhiteElos(309) = "2607" : BlackPlayers(309) = "Wells, Peter K   G#309" : BlackElos(309) = "2521" : Each_Game_Result(309) = "1/2-1/2"

FilePGNs(309) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. g3 Be7 5. Bg2 O-O 6. O-O dxc4 7. Qc2 a6 8. Qxc4 b5 9. Qc2 Bb7 10. Bd2 Be4 11. Qc1 Nbd7 12. Ba5 Rc8 13. Nbd2 Ba8 14. Qc2 Qe8 15. b4 Nb8 16. Ne5  Bxg2 17. Kxg2 Bd6 18. Rac1 Nd5 19. Nd3 f5 20. e3 Qh5  21. Qd1 Qe8 22. Nb3 Nc6 23. a3 g5 24. Kg1 Rf6  25. Qd2 Rh6 26. f4 gxf4 27. exf4 Bf8  28. Rfe1 Nxa5  29. Nxa5 Nf6 30. Qg2 Ng4  31. h3 Nf6 32. Qc6  Rxh3 33. Qxe8 Rxe8 34. Kg2 Rh6 35. Rxc7 Ng4  36. Re2  Rh2+ 37. Kf3 Rh1 38. Ne1 h5  39. Kg2 Rh2+ 40. Kf3 Rh1 41. Kg2 Rh2+ 42. Kf3 Rh1 1/2-1/2 "

; sample game 310
EventSites(310) = "Sofia MTel Masters 4th  Sofia" : GameDates(310) = "20080511" : WhitePlayers(310) = "Ivanchuk, Vassily   G#310" : WhiteElos(310) = "2740" : BlackPlayers(310) = "Cheparinov, Ivan   G#310" : BlackElos(310) = "2696" : Each_Game_Result(310) = "1-0"

FilePGNs(310) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. O-O Nc6 8. d5 Ne7 9. Ne1 Nd7 10. Nd3 f5 11. Bd2 Nf6 12. f3 f4 13. c5 g5 14. Rc1 Ng6 15. cxd6 cxd6 16. Nb5 Rf7 17. Qc2 Ne8 18. Nf2 h5 19. a4 Bf8 20. h3 Rg7 21. Qb3 Nh4 22. Rc2 g4 23. fxg4 Nf6 24. Be1  hxg4 25. hxg4 Nh5 26. Nh1  f3  27. Bxf3 Nf4 28. Ng3 Bxg4 29. Bxg4 Rxg4 30. Nc7 Rc8  31. Ne6 Rxc2  32. Qxc2 Qb6+  33. Kh1 Nhxg2 34. Nf5  Qa6 35. Rg1 Qd3 36. Qxd3 Nxd3 37. Bh4 Rxe4 38. Rxg2+ Kf7 39. Nxd6+ Bxd6 40. Ng5+ 1-0 "

; sample game 311
EventSites(311) = "Sofia MTel Masters 4th  Sofia" : GameDates(311) = "20080518" : WhitePlayers(311) = "Cheparinov, Ivan   G#311" : WhiteElos(311) = "2696" : BlackPlayers(311) = "Ivanchuk, Vassily   G#311" : BlackElos(311) = "2740" : Each_Game_Result(311) = "0-1"

FilePGNs(311) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 e6 5. Nc3 Qc7 6. Be3 a6 7. Qd2 Nf6 8. O-O-O Bb4 9. f3 Ne5 10. Nb3 b5 11. Bd4 Be7 12. Qf2 d6 13. g4 O-O 14. g5 Nfd7 15. Rg1 Bb7 16. Kb1 Rfc8 17. Rg3   b4 18. Na4 Bd8  19. Nc1 Bc6 20. b3 Bxa4 21. bxa4 Nc6 22. Be3 Qb8  23. Rh3 Nb6 24. Qh4 h6 25. Qg3 Nxa4 26. Rxd6 hxg5 27. Bd3 Bf6 28. e5 Bxe5 29. Rh8+ Kxh8 30. Qh3+ Kg8 31. Qh7+ Kf8 32. Rd7 Nc3+ 33. Ka1 Nb5+ 0-1 "

; sample game 312
EventSites(312) = "Sofia MTel Masters 4th  Sofia" : GameDates(312) = "20080515" : WhitePlayers(312) = "Radjabov, Teimour   G#312" : WhiteElos(312) = "2751" : BlackPlayers(312) = "Bu Xiangzhi   G#312" : BlackElos(312) = "2708" : Each_Game_Result(312) = "1-0"

FilePGNs(312) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. e3 a6 5. Nf3 b5 6. c5 g6 7. Ne5 Bg7 8. Be2 O-O 9. O-O Nfd7 10. f4 a5 11. a3  f6 12. Nf3 f5 13. Bd2 Nf6 14. Be1 Kh8 15. Bh4 Be6 16. Ne5 Qc7 17. Qe1  Nbd7 18. Bg5  Nxe5 19. fxe5 Ne4 20. Nxe4 fxe4 21. Qh4 Rxf1+ 22. Rxf1 Re8 23. Bg4  Qd7 24. Rf7 Bxg4 25. Bf6 exf6 26. Rxd7 Bxd7 27. exf6 a4 28. fxg7+ Kxg7 29. Kf2  h6 30. Ke1 Re6 31. Qg3 Be8 32. Kd2 g5 33. Kc3 Kf8 34. Kb4 Bf7 35. Ka5 Kg7 36. Kb6 Kf8 37. Kc7 Kg7 38. Kd7 Kf8 39. Qf2  Rg6 40. Qf5  h5 41. g3  1-0 "

; sample game 313
EventSites(313) = "Merida Ruy Lopez GM  Merida" : GameDates(313) = "20080407" : WhitePlayers(313) = "Perez Candelario, Manuel   G#313" : WhiteElos(313) = "2537" : BlackPlayers(313) = "Caruana, Fabiano   G#313" : BlackElos(313) = "2598" : Each_Game_Result(313) = "0-1"

FilePGNs(313) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 a6 5. Bd3 Bc5 6. Nb3 Be7 7. Be3  Nf6 8. N1d2 Nc6 9. f4 d6 10. Qf3 O-O 11. O-O-O a5  12. Nc4 a4 13. Bb6 Qe8 14. Nbd2 d5 15. Ne5 a3 16. b3 Nb4 17. Kb1 dxe4 18. Nxe4  Nfd5 19. Bd4 f6 20. Nc4 e5   21. Ned6 Bxd6 22. Nxd6 Qc6 23. Nxc8  Raxc8 24. Bc4 exd4  25. Rxd4 Kh8 26. Rxd5 Nxd5 27. Qxd5 Qc7 28. Rf1 Rcd8 29. Qf5 Rd4 30. g3 b5   31. Qxb5 Rb8 32. Re1 Qd8 33. Kc1 Rxb5 34. Bxb5 Rd7 0-1 "

; sample game 314
EventSites(314) = "GRE-chT  Kallithea" : GameDates(314) = "20080710" : WhitePlayers(314) = "Atalik, Suat   G#314" : WhiteElos(314) = "2585" : BlackPlayers(314) = "Harikrishna, Penteala   G#314" : BlackElos(314) = "2668" : Each_Game_Result(314) = "1-0"

FilePGNs(314) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. e3 a6 5. Qc2  b5 6. b3 Bg4 7. Nge2 Nbd7 8. h3 Bh5 9. Nf4 Bg6 10. Nxg6 hxg6 11. Be2 e6 12. O-O Rc8  13. c5   e5 14. b4 e4 15. a4 Be7 16. axb5 axb5 17. Ra6 Nf8  18. Rxc6  Rxc6 19. Bxb5 Qc8 20. Qa4 Kd7 21. Bxc6+ Qxc6 22. b5 Qc8 23. b6+ Ke6 24. f3 exf3 25. e4 Bxc5 26. exd5+ Ke7 27. Re1+  Ne6  28. dxc5 Qxc5+ 29. Re3  Qxb6 30. Qa3+  Qd6 31. dxe6 fxe6 32. Qa7+ Qd7 33. Ba3+ Kf7 34. Qxd7+ Nxd7 35. Rxf3+ Nf6 36. Ne4 Rb8 37. g4 Kg8 38. Nxf6+ gxf6 39. Rxf6 Rb3 40. Bf8 Rxh3 41. Kg2 Rc3 42. Bh6 Kh7 43. g5 e5 44. Rf7+ Kh8 45. Re7 1-0 "

; sample game 315
EventSites(315) = "Foros Aerosvit 3rd  Foros" : GameDates(315) = "20080608" : WhitePlayers(315) = "Carlsen, Magnus   G#315" : WhiteElos(315) = "2765" : BlackPlayers(315) = "Ivanchuk, Vassily   G#315" : BlackElos(315) = "2740" : Each_Game_Result(315) = "1-0"

FilePGNs(315) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. O-O Nc6 8. d5 Ne7 9. b4 Nh5 10. Re1 f5 11. Ng5 Nf6 12. f3 Kh8 13. b5  Ne8 14. Be3  Bf6 15. Ne6 Bxe6 16. dxe6 Ng7  17. Bh6 Nxe6 18. Bxf8 Qxf8 19. c5  Nxc5 20. Bc4 Bg5  21. Qe2  Qh6 22. Rad1 Rf8 23. a4 b6 24. g3 Qh3 25. Qg2 Qh6 26. Qe2 Qh3 27. Kh1 Nd7  28. Ra1  Qh6 29. Ra2 Nf6  30. Kg2 Nh5  31. Nd5 Nxd5 32. Bxd5 Bf4 33. Qf2 fxe4 34. Bxe4 Qg5 35. Rc2 d5  36. Bxd5 Bxg3 37. hxg3 Nf4+ 38. Kf1 Nxd5 39. Rce2  Qf6 40. Rxe5 Qxf3 41. Qxf3 Rxf3+ 42. Ke2 Rf5 43. Rxf5 gxf5 44. Kd3 c5 45. Re5 Nb4+ 46. Kd2 1-0 "

; sample game 316
EventSites(316) = "Foros Aerosvit 3rd  Foros" : GameDates(316) = "20080610" : WhitePlayers(316) = "Eljanov, Pavel   G#316" : WhiteElos(316) = "2687" : BlackPlayers(316) = "Shirov, Alexei   G#316" : BlackElos(316) = "2740" : Each_Game_Result(316) = "1-0"

FilePGNs(316) = "1. Nf3 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. Qa4+ Bd7 6. Qb3 Nb6 7. d4 Bg7 8. Bf4  O-O 9. e3 Be6 10. Qa3 N8d7 11. Rd1 Nd5   12. Nxd5 Bxd5 13. Be2 c6 14. O-O Re8  15. Bg3 Qb6 16. b3 e5 17. Nxe5 Nxe5 18. dxe5 Bxe5 19. Bc4  Bxc4 20. bxc4 Bxg3 21. hxg3 Re4  22. Rd7  Rae8 23. c5 Qb5 24. Qxa7 Ra4 25. Qb6  Qxb6 26. cxb6 Rb8 27. Rb1  Rxa2 28. Rb4 c5 29. Re4 Rb2 30. Ree7 Rb1+ 31. Kh2 Rxb6 32. Rxf7 Rc6  33. Rg7+ Kf8 34. Rxh7 Ke8 35. Rd5  Rcc8 36. Re5+  Kf8 37. Rxc5  Rxc5 38. Rh8+ Ke7 39. Rxb8 1-0 "

; sample game 317
EventSites(317) = "Foros Aerosvit 3rd  Foros" : GameDates(317) = "20080617" : WhitePlayers(317) = "Volokitin, Andrei   G#317" : WhiteElos(317) = "2684" : BlackPlayers(317) = "Eljanov, Pavel   G#317" : BlackElos(317) = "2687" : Each_Game_Result(317) = "0-1"

FilePGNs(317) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. d4 Nd6 6. Bxc6 dxc6 7. dxe5 Nf5 8. Qxd8+ Kxd8 9. Nc3 Ne7 10. h3 Ng6 11. Ne4 h6 12. b3 a5 13. a4 c5  14. Bb2 Be6 15. Nfd2  Nf4 16. Kh2 g6  17. Nc4 Kd7  18. g3 Nd5 19. f4 h5 20. Rad1 Kc6 21. Ng5 Bg7  22. Nxe6 fxe6 23. Bc1 Bh6 24. Kg2 Rhf8 25. Na3  Rf7  26. c4 Ne7 27. Rd3 Rg8  28. Rfd1 Nf5 29. Nb5  g5 30. g4 gxf4 31. Kf3 Nh4+ 32. Ke4 b6  33. gxh5 Rg2  34. Nc3 Nf5 35. Rd8 Rg3 36. Nb5 Rxb3 37. R1d3 Rxd3 38. Rxd3 f3  39. Bxh6 f2 40. Rd1 Ng3+ 41. Ke3 f1=R 42. Rxf1 Nxf1+ 43. Kd3 Ng3 44. h4 Rf3+ 45. Kd2 Rf5 46. Bg5 Ne4+ 47. Ke3 Nxg5 48. hxg5 Rxg5 0-1 "

; sample game 318
EventSites(318) = "Sarajevo Bosnia-A 38th  Sarajevo" : GameDates(318) = "20080529" : WhitePlayers(318) = "Morozevich, Alexander   G#318" : WhiteElos(318) = "2774" : BlackPlayers(318) = "Sokolov, Ivan   G#318" : BlackElos(318) = "2690" : Each_Game_Result(318) = "1-0"

FilePGNs(318) = "1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Bb4+ 5. c3 Bc5 6. Nxc6 bxc6 7. Bd3 Ne7 8. O-O O-O 9. Bg5   f6 10. Bh4 d6  11. Nd2 Ng6 12. Bg3 f5 13. exf5 Bxf5 14. Bxf5 Rxf5 15. a4 a6 16. Qb3+  Kh8 17. Qb7  Rb8  18. Qxa6 Rxb2 19. Ne4  h5 20. h4  Rb6 21. Qc4 Qg8 22. Qe2 Rb8  23. Ng5  Nf8 24. Qxh5+ Nh7 25. Rae1 Bb6 26. Re7 Rbf8 27. Kh2 R5f6 28. a5 1-0 "

; sample game 319
EventSites(319) = "Foros Aerosvit 3rd  Foros" : GameDates(319) = "20080609" : WhitePlayers(319) = "Karjakin, Sergey   G#319" : WhiteElos(319) = "2732" : BlackPlayers(319) = "Nisipeanu, Liviu Dieter   G#319" : BlackElos(319) = "2684" : Each_Game_Result(319) = "1-0"

FilePGNs(319) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 Qc7 6. Be3 a6 7. Qd2 Nf6 8. O-O-O Bb4 9. f3 Ne7 10. Nde2 b5 11. Bf4 e5 12. Bg5 h5   13. Kb1 Ba5 14. Nc1 b4 15. Na4 b3 16. Nc3 bxc2+ 17. Qxc2 Rb8 18. Nb3 Bb4 19. Rd3 d6  20. a3  Bxa3 21. bxa3 Be6 22. Na2 Qa5 23. Bc1 Qa4 24. Nb4 O-O 25. Nd4  Qxc2+  26. Nxc2 a5 27. Rxd6 axb4 28. Nxb4 Nd7 29. Bb2 Ng6 30. g3 Nc5 31. Be2 Na4 32. Rc1 Nxb2 33. Kxb2 Kh7 34. Rc5 h4 35. Bb5 Bh3 36. a4 Bg2 37. Rc3 f5 38. Na6 Rb7 39. Nc5 Ra7 40. Nd7  1-0 "

; sample game 320
EventSites(320) = "Foros Aerosvit 3rd  Foros" : GameDates(320) = "20080611" : WhitePlayers(320) = "Karjakin, Sergey   G#320" : WhiteElos(320) = "2732" : BlackPlayers(320) = "Jakovenko, Dmitrij   G#320" : BlackElos(320) = "2711" : Each_Game_Result(320) = "1-0"

FilePGNs(320) = "1. e4 e5 2. Nf3 Nf6 3. Nxe5 d6 4. Nf3 Nxe4 5. Nc3 Nxc3 6. dxc3 Be7 7. Bf4 O-O 8. Qd2 Nd7 9. O-O-O Nc5 10. Be3 Re8 11. Bc4 Be6 12. Bxe6 Nxe6 13. h4 Qd7 14. Qd3 Qc6 15. Qf5 Qc4 16. Kb1 g6 17. Qh3 h5 18. Nd2 Qe2 19. Rde1 Qg4 20. Qh2 d5 21. f3 Qa4 22. g4 Bd6 23. Qg1  Ng7 24. Nb3 Qd7 25. Rd1 hxg4 26. fxg4 Re4 27. Rd4 Rae8 28. Bc1 Be5  29. Rxe4 dxe4 30. h5 gxh5 31. gxh5 Kh8 32. Qg5  f6 33. Qh6+ Kg8 34. Rg1 Qf7 35. Nd4  f5 36. Bf4  Bxf4 37. Qxf4 Kh7 38. Rg6 Re7 39. Qh6+ Kg8 40. Qg5 Kh7 41. Nxf5  Nxf5 42. Rf6 1-0 "

; sample game 321
EventSites(321) = "Canadian Open  Montreal" : GameDates(321) = "20080727" : WhitePlayers(321) = "Mikhalevski, Victor   G#321" : WhiteElos(321) = "2592" : BlackPlayers(321) = "Huzman, Alexander   G#321" : BlackElos(321) = "2589" : Each_Game_Result(321) = "1-0"

FilePGNs(321) = "1. d4 Nf6 2. c4 e6 3. g3 d5 4. Bg2 Be7 5. Nf3 O-O 6. O-O dxc4 7. Na3 Bxa3 8. bxa3 Bd7 9. Qc2 Bc6 10. Qxc4 Nbd7  11. Bf4  h6 12. Rfc1 Nb6 13. Qb3  Nfd5 14. Bd2 Nf6  15. Rxc6  bxc6 16. Rc1 Rb8 17. Rxc6 Nbd5  18. Qc2 Rb6 19. Rc4  Qb8 20. Bc1 Ne7 21. Ne5  Rd8 22. Bf3  Ne8 23. e3  Nd6 24. Rc3 f6 25. Nd3 Nf7 26. a4 Nd5 27. Rc5 Rd7 28. Ba3 Nd8 29. Kg2 Nb7 30. Rc6 Na5 31. Rc5 Nb7 32. a5  Nxc5 33. Nxc5 Rc6  34. Qg6  Rf7  35. Be4   f5 36. Bxd5 Rf6 37. Qxf6  1-0 "

; sample game 322
EventSites(322) = "Foros Aerosvit 3rd  Foros" : GameDates(322) = "20080610" : WhitePlayers(322) = "Nisipeanu, Liviu Dieter   G#322" : WhiteElos(322) = "2684" : BlackPlayers(322) = "Ivanchuk, Vassily   G#322" : BlackElos(322) = "2740" : Each_Game_Result(322) = "1/2-1/2"

FilePGNs(322) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Qb6 5. Nb3 Qc7 6. Bd3 Nf6 7. O-O d6 8. c4 Be7 9. Nc3 O-O 10. Be3 b6  11. a4 Nc6 12. a5 bxa5 13. Nb5 Qb8  14. Nxa5 Nxa5 15. Rxa5 a6 16. Nd4 Qxb2 17. c5  dxc5  18. Nc6 Re8 19. e5 Nd5 20. Nxe7+ Rxe7 21. Bxc5 Rc7  22. Bd6 Rc3 23. Ra4 h6  24. Rg4  Bd7  25. Rg3 Bb5 26. Qg4 g5 27. Qh5  Bxd3 28. Qxh6 Bg6 29. Rxg5 Nf4 30. Rg4 Rc1 31. Qxf4 Rxf1+ 32. Kxf1 Qb1+ 33. Ke2 Qd3+ 34. Ke1 Rc8 35. Bb4  a5 36. Bd2 Rb8 37. Qc4 Rb1+ 38. Bc1 Qf5 39. f3 Qxe5+ 40. Kf2  Rb4 41. Qc8+ Kh7 42. h3 1/2-1/2 "

; sample game 323
EventSites(323) = "Foros Aerosvit 3rd  Foros" : GameDates(323) = "20080612" : WhitePlayers(323) = "Nisipeanu, Liviu Dieter   G#323" : WhiteElos(323) = "2684" : BlackPlayers(323) = "Van Wely, Loek   G#323" : BlackElos(323) = "2676" : Each_Game_Result(323) = "1-0"

FilePGNs(323) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be3 e5 7. Nb3 Be6 8. Qd2 Nbd7 9. O-O-O Be7 10. f4 Ng4 11. g3 Nxe3 12. Qxe3 b5 13. Kb1 Qb6  14. Qe1 b4  15. Nd5 Bxd5 16. exd5 O-O 17. Bh3 Nc5 18. fxe5  Nxb3 19. axb3 dxe5 20. Qxe5 Bf6 21. Qf4 Ra7 22. d6 a5 23. d7 a4 24. Qd6   Qxd6  25. Rxd6 axb3  26. cxb3 Be7 27. Rd5 Rfa8  28. Kc2 Kf8 29. Re1 Rc7+ 30. Kd3 g6 31. Rde5  Bd8 32. Re8+  Kg7 33. R1e5 Rc1  34. Bg2 Rb8 35. Rd5  h5 36. Bf3 Rf1 37. Ke2 Rc1 38. Rb5  Rxb5 39. Rxd8 Rc2+ 40. Kd3 Rxb2 41. Rc8 Rxb3+ 42. Kc4 1-0 "

; sample game 324
EventSites(324) = "Foros Aerosvit 3rd  Foros" : GameDates(324) = "20080619" : WhitePlayers(324) = "Svidler, Peter   G#324" : WhiteElos(324) = "2746" : BlackPlayers(324) = "Van Wely, Loek   G#324" : BlackElos(324) = "2677" : Each_Game_Result(324) = "1/2-1/2"

FilePGNs(324) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be3 e5 7. Nb3 Be6 8. f3 Be7 9. Qd2 O-O 10. O-O-O Nbd7 11. g4 b5 12. g5 b4 13. Ne2 Ne8 14. f4 a5 15. f5 a4 16. Nbd4 exd4 17. Nxd4 b3 18. Kb1 bxc2+ 19. Nxc2 Bb3 20. axb3 axb3 21. Na3 Ne5 22. h4 Ra4 23. Qc3  Qa8 24. Rd4 Rxd4 25. Qxd4 Nc7 26. Rh3 Rb8 27. Bf2 Nc6 28. Qd1 Qa4 29. Rc3  d5  30. Qc1  Bxa3  31. bxa3 b2 32. Qc2 Nb5  33. Bxb5 Qxb5 34. Be1  Qf1 35. Qf2 Qb5 36. Qc2 Qf1 37. Qf2 Qb5 1/2-1/2 "

; sample game 325
EventSites(325) = "Staunton Memorial 6th  London" : GameDates(325) = "20080807" : WhitePlayers(325) = "Smeets, Jan   G#325" : WhiteElos(325) = "2593" : BlackPlayers(325) = "Adams, Michael   G#325" : BlackElos(325) = "2735" : Each_Game_Result(325) = "0-1"

FilePGNs(325) = "1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Nf6 5. Nxc6 bxc6 6. e5 Qe7 7. Qe2 Nd5 8. c4 Ba6 9. b3 O-O-O 10. Bb2 Qg5 11. Qf3 Bb4+ 12. Kd1 Nf4  13. h4 Qh6 14. g3 Ne6 15. Bc1 Qg6 16. h5 Qc2+  17. Kxc2 Nd4+ 18. Kd3  Nxf3 19. Ke4 Nxe5 20. h6 Ng4 21. hxg7 Rhg8 22. Kf5 Rxg7 23. f3 Nf2 24. Rh2 Bc5 25. Bh6 Rg6 26. Nd2 Bd4 27. Bg5 Re8 28. Rxf2 Re5+ 0-1 "

; sample game 326
EventSites(326) = "Sochi FIDE GP  Sochi" : GameDates(326) = "20080814" : WhitePlayers(326) = "Aronian, Levon   G#326" : WhiteElos(326) = "2737" : BlackPlayers(326) = "Grischuk, Alexander   G#326" : BlackElos(326) = "2728" : Each_Game_Result(326) = "1-0"

FilePGNs(326) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. e3 e6 5. Nf3 Nbd7 6. Bd3 dxc4 7. Bxc4 b5 8. Bd3 Bb7 9. O-O b4 10. Ne4 Nxe4 11. Bxe4 Bd6 12. a3 bxa3 13. b3 Nf6 14. Nd2 Qc7 15. Bf3 Bxh2+ 16. Kh1 Bd6 17. Nc4 Be7 18. Bxa3 O-O 19. Bc5 Rfd8 20. b4 Bxc5 21. bxc5 a5 22. Re1 Ba6 23. Nb6 Rab8 24. Rxa5 Bb5 25. Qa1 Nd5 26. Ra7 Rb7 27. Rxb7 Qxb7 28. Qa5 Qe7 29. Ra1 Qg5 30. Nxd5 exd5 31. Qc7 g6 32. Ra7 Qf6 33. Bg4 Re8 34. Kg1 Kg7 35. Bd7 Re7 36. Qd8 h5 37. Ra8 Kh6 38. Rc8 Kh7 39. Bxc6 Bxc6 40. Rxc6 Qxc6 41. Qxe7 Kg7 42. Kh2 1-0 "

; sample game 327
EventSites(327) = "Biel GM 41st  Biel" : GameDates(327) = "20080726" : WhitePlayers(327) = "Pelletier, Yannick   G#327" : WhiteElos(327) = "2569" : BlackPlayers(327) = "Carlsen, Magnus   G#327" : BlackElos(327) = "2775" : Each_Game_Result(327) = "0-1"

FilePGNs(327) = "1. d4 Nf6 2. Nf3 e6 3. c4 b6 4. g3 Ba6 5. b3 Bb4+ 6. Bd2 Be7 7. Bg2 d5 8. cxd5 exd5 9. Nc3 O-O 10. O-O Bb7 11. Rc1 Nbd7 12. Bf4 c6 13. Qc2 Re8 14. Rcd1 Bb4  15. Bd2 Rc8 16. Qb2 Qe7 17. Rfe1 Qf8 18. Bh3 Rcd8 19. Qc2 h6  20. Nh4 c5 21. Nf5 a6 22. Qb2 Bxc3 23. Bxc3 Ne4 24. dxc5 Nxc3 25. Qxc3 bxc5 26. Qa5 Nf6 27. Qb6  Bc8  28. Kg2 Ne4 29. f3 Ng5 30. g4 h5 31. Rc1 g6  32. Ng3 Nxh3 33. Kxh3 hxg4+ 34. fxg4  Qh6+ 35. Kg2 Bxg4 36. Qxc5 Re3  37. Qd4 Qh3+ 38. Kg1 Rxg3+ 39. hxg3 Qxg3+ 40. Kh1 Bf5 0-1 "

; sample game 328
EventSites(328) = "Tal Memorial 3rd  Moscow" : GameDates(328) = "20080824" : WhitePlayers(328) = "Mamedyarov, Shakhriyar   G#328" : WhiteElos(328) = "2742" : BlackPlayers(328) = "Gelfand, Boris   G#328" : BlackElos(328) = "2720" : Each_Game_Result(328) = "0-1"

FilePGNs(328) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. Nf3 e6 5. Bg5 h6 6. Bh4 dxc4 7. e4 g5 8. Bg3 b5 9. Be2 Bb7 10. e5 Nd5 11. O-O Nd7 12. Nd2 Qb6 13. a4 a6 14. Nde4 O-O-O 15. Bh5 Nf4  16. Bxf7 Nxe5 17. Bxe6+ Kb8 18. Ne2 Bg7 19. Nxf4 gxf4 20. Bxf4 Rxd4 21. a5  Qd8 22. Qe2 Re8 23. Rad1  Ka8 24. Be3 Rxd1 25. Rxd1 Nd3 26. Bf5  Qd5 27. Qg4 Bxb2 28. h4 Bd4 29. Bg6 Rg8 30. Bxd4 Qxd4 31. Qe6 Qd5 32. Qe7 c5 33. f3 Qd4+ 34. Kh1 Qg7 35. Qxg7 Rxg7 36. h5 b4 37. Kg1 Bxe4 0-1 "

; sample game 329
EventSites(329) = "ROM-chT  Eforie Nord" : GameDates(329) = "20080908" : WhitePlayers(329) = "Kotronias, Vasilios   G#329" : WhiteElos(329) = "2574" : BlackPlayers(329) = "Marin, Mihail   G#329" : BlackElos(329) = "2553" : Each_Game_Result(329) = "1-0"

FilePGNs(329) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Na5 10. Bc2 c5 11. d4 Qc7 12. Nbd2 Nc6 13. d5 Nd8 14. a4 Rb8 15. Nf1 Ne8 16. b4 g6 17. Bh6 Ng7 18. axb5 axb5 19. N3h2 f6 20. f4 exf4 21. Bxf4 Nf7 22. Nf3 Ne5 23. N1d2 Bd7 24. Ra2 Rfc8  25. Qa1 Bd8 26. Be3 cxb4 27. cxb4 Qc3 28. Bd4 Bb6 29. Qxc3 Rxc3 30. Bxb6 Rxb6 31. Ra8+ Kf7  32. Nxe5+  dxe5 33. Bd1  Rb7 34. Nb3 Ne8 35. Nc5 Rc7 36. Bg4  Bxg4 37. hxg4 Ke7 38. Rea1 Rc4 39. R1a6 Nd6  40. Rxd6  1-0 "

; sample game 330
EventSites(330) = "ESP-chT Hon Gp2  Sabadell" : GameDates(330) = "20080907" : WhitePlayers(330) = "Gashimov, Vugar   G#330" : WhiteElos(330) = "2717" : BlackPlayers(330) = "Postny, Evgeny   G#330" : BlackElos(330) = "2661" : Each_Game_Result(330) = "1/2-1/2"

FilePGNs(330) = "1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Bf5 5. Ng3 Bg6 6. h4 h6 7. Nf3 Nd7 8. h5 Bh7 9. Bd3 Bxd3 10. Qxd3 e6 11. Bd2 Qc7 12. O-O-O Ngf6 13. Qe2 Bd6 14. Nf5 Bf4 15. Ne3 Ne4 16. Be1 O-O-O 17. g3 Bxe3+ 18. Qxe3 Ndf6 19. Qe2  Rhe8 20. Ne5 Nd6 21. f3 Nd7 22. f4 f6 23. Ng6 c5 24. dxc5 Nxc5 25. g4 Nde4  26. Rxd8+ Rxd8 27. Rh3 Qd6 28. Re3 Qd4 29. a3 Kb8 30. Kb1 f5 31. Ka2  fxg4 32. Ne5 Nf6 33. Rc3 Nfe4 34. Re3 Nf6 35. Rc3 Nfe4 36. Re3 1/2-1/2 "

; sample game 331
EventSites(331) = "Najdorf Memorial  Warsaw" : GameDates(331) = "20080803" : WhitePlayers(331) = "Sasikiran, Krishnan   G#331" : WhiteElos(331) = "2684" : BlackPlayers(331) = "Rozentalis, Eduardas   G#331" : BlackElos(331) = "2599" : Each_Game_Result(331) = "1-0"

FilePGNs(331) = "1. e4 Nf6 2. e5 Nd5 3. d4 d6 4. Nf3 dxe5 5. Nxe5 c6 6. Be2 Nd7 7. Nf3 N7f6 8. O-O Bg4 9. Ne5 Bxe2 10. Qxe2 e6 11. c4 Ne7 12. Rd1 Ng6 13. Nc3 Qc7 14. g3  Be7  15. h4 O-O 16. Bg5  Rae8 17. Rd2 a6 18. Rad1  c5  19. Nxg6 hxg6 20. Bf4 Bd6  21. Bxd6 Qxd6 22. Qe5  Qxe5 23. dxe5 Ng4 24. Re2 Rd8 25. Rxd8 Rxd8 26. f3  Nh6 27. g4 Rd4 28. Re4 Rd2 29. Na4 b5 30. cxb5 axb5 31. Nxc5 Rxb2 32. Rd4  Rxa2  33. Rd8+ Kh7 34. Ne4 f6 35. exf6 gxf6 36. Rd7+ Kg8 37. Nxf6+ Kf8 38. Nh7+  Ke8 39. Nf6+ Kf8 40. Rb7  Re2 41. Rxb5  Ke7 42. Rb7+  Kxf6 43. g5+ Ke5 44. gxh6 Rd2 45. h7 Rd8 46. Rf7  Rh8 47. Kf2 Kd6 48. Kg3 e5 49. h5  gxh5 50. Kh4 Ke6 51. Ra7 Rf8 52. Rg7 1-0 "

; sample game 332
EventSites(332) = "Najdorf Memorial  Warsaw" : GameDates(332) = "20080805" : WhitePlayers(332) = "Sasikiran, Krishnan   G#332" : WhiteElos(332) = "2684" : BlackPlayers(332) = "Berg, Emanuel   G#332" : BlackElos(332) = "2592" : Each_Game_Result(332) = "1-0"

FilePGNs(332) = "1. d4 Nf6 2. c4 c5 3. d5 e6 4. Nc3 exd5 5. cxd5 d6 6. e4 g6 7. f4 Bg7 8. Bb5+ Nfd7 9. a4 Qh4+ 10. g3 Qd8 11. Nf3 O-O 12. O-O Na6 13. f5   Nf6 14. Bf4  gxf5  15. e5  Ne4  16. Re1  Nb4 17. Bc4 a6  18. a5  dxe5 19. Nxe5 Re8  20. Nxe4 fxe4 21. Rxe4 Bf5 22. Nxf7  Rxe4 23. Nxd8 Rxd8 24. Rc1 Kh8 25. d6 Bxb2 26. Qh5 Bg6 27. Qg5 Nc6 28. Bd5 Rxf4 29. gxf4 Rxd6 30. Re1  Bd4+ 31. Kg2 Kg7 32. Bxc6 Bf6 33. Qg3 Rd2+ 34. Kh1 bxc6 35. f5 c4 36. fxg6 hxg6 37. Qc7+ 1-0 "

; sample game 333
EventSites(333) = "RUS-ch Higher League 61st  Novokuznetsk" : GameDates(333) = "20080904" : WhitePlayers(333) = "Lintchevski, Daniil   G#333" : WhiteElos(333) = "2506" : BlackPlayers(333) = "Vitiugov, Nikita   G#333" : BlackElos(333) = "2616" : Each_Game_Result(333) = "0-1"

FilePGNs(333) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be3 e5 7. Nf3 Be7 8. Bc4 O-O 9. O-O Nc6 10. Qe2 Na5 11. Bb3 h6 12. Rfd1 Nxb3 13. axb3 Qe8 14. Nd2 b5  15. Nxb5 Bg4 16. f3 Qxb5 17. Qxb5 axb5 18. fxg4 Nxg4 19. Nf1 Rxa1 20. Rxa1 Rc8 21. c3 Nf6 22. Ng3 d5 23. Ra5  b4  24. Nf5 Bd8 25. Rb5 bxc3 26. bxc3 g6  27. Nxh6+ Kg7 28. Rb7  Rc7 29. Rxc7 Bxc7 30. exd5 Nxd5 31. Bd2 f5 32. g4  e4 33. g5 Bb6+   34. Kg2   e3 35. Be1 Nf4+ 36. Kf3 Nh3 37. Bh4 Bd8 38. Kxe3 Nxg5 39. Nxf5+ gxf5 40. c4 Bb6+ 41. Kf4  Kg6  42. Bg3  Ne4 43. b4 Bc7+ 44. Kf3 Nxg3   45. hxg3 Kg5 46. c5 Be5  47. Ke3 Bxg3 48. b5 Bh2  49. Kf2 Be5 50. Ke3 Bc3  51. b6 Ba5 0-1 "

; sample game 334
EventSites(334) = "RUS-ch Higher League 61st  Novokuznetsk" : GameDates(334) = "20080908" : WhitePlayers(334) = "Nepomniachtchi, Ian   G#334" : WhiteElos(334) = "2602" : BlackPlayers(334) = "Vitiugov, Nikita   G#334" : BlackElos(334) = "2616" : Each_Game_Result(334) = "1/2-1/2"

FilePGNs(334) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 Qc7 6. Be3 a6 7. Qd2 Nf6 8. O-O-O Bb4 9. f3 Ne5 10. Nb3 b5 11. Qe1 Be7 12. f4 Ng6 13. e5 Ng4 14. Ne4 O-O 15. Bc5 Bb7 16. h3 Nh6 17. Bxe7 Nxe7 18. Bd3 Nd5 19. Rf1 f5  20. Nd6 Bc6 21. g4 fxg4 22. Qg3 Nf7 23. hxg4  Nxd6  24. Qh2  h6 25. exd6 Qb6 26. Rde1  Nb4 27. Bg6 Rf6 28. Qh5 Raf8 29. f5 Bg2 30. g5 Bxf1 31. gxf6 Qf2 32. f7+  Kh8 33. Qd1 Nd3+  34. cxd3 Bxd3 35. Qxd3  Qxe1+ 36. Kc2 Rc8+ 37. Qc3  Qe4+ 38. Kd1 Qg4+  39. Kc1 Qf4+ 40. Nd2 Rxc3+ 41. bxc3 Qxd6 42. Nf3 b4 43. c4 Qc5 44. Ne5  Qe3+ 45. Kb1 Qe4+ 46. Kc1 Qe3+ 47. Kb1 Qe4+ 1/2-1/2 "

; sample game 335
EventSites(335) = "World Championship  Bonn" : GameDates(335) = "20081017" : WhitePlayers(335) = "Kramnik, Vladimir   G#335" : WhiteElos(335) = "2772" : BlackPlayers(335) = "Anand, Viswanathan   G#335" : BlackElos(335) = "2783" : Each_Game_Result(335) = "0-1"

FilePGNs(335) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 e6 5. e3 Nbd7 6. Bd3 dxc4 7. Bxc4 b5 8. Bd3 a6  9. e4 c5 10. e5 cxd4 11. Nxb5 axb5 12. exf6 gxf6 13. O-O Qb6 14. Qe2 Bb7  15. Bxb5  Bd6  16. Rd1 Rg8 17. g3  Rg4  18. Bf4 Bxf4 19. Nxd4  h5 20. Nxe6 fxe6 21. Rxd7 Kf8 22. Qd3 Rg7  23. Rxg7 Kxg7 24. gxf4 Rd8  25. Qe2 Kh6 26. Kf1 Rg8 27. a4  Bg2+ 28. Ke1 Bh3  29. Ra3  Rg1+ 30. Kd2 Qd4+ 31. Kc2 Bg4  32. f3  Bf5+ 33. Bd3 Bh3  34. a5 Rg2 35. a6 Rxe2+ 36. Bxe2 Bf5+ 37. Kb3 Qe3+ 38. Ka2 Qxe2 39. a7 Qc4+ 40. Ka1 Qf1+ 41. Ka2 Bb1+ 0-1 "

; sample game 336
EventSites(336) = "EU-Cup 24th  Kallithea" : GameDates(336) = "20081019" : WhitePlayers(336) = "Bologan, Viktor   G#336" : WhiteElos(336) = "2682" : BlackPlayers(336) = "Sargissian, Gabriel   G#336" : BlackElos(336) = "2642" : Each_Game_Result(336) = "1/2-1/2"

FilePGNs(336) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. a4 b4 9. d4 d6 10. dxe5 dxe5 11. Qxd8 Rxd8 12. Nbd2 Bc5 13. h3 Bb7 14. Bc4 h6 15. Nb3 Bd6 16. a5 Ne7 17. Nfd2 Ng6 18. Bf1 Nf4 19. f3 Nd7 20. Nc4 Be7 21. Be3 Ne6 22. Bf2  Bc6 23. Ne3 Ndc5 24. Bc4 Nxb3 25. cxb3 Bb5 26. Bxb5 axb5 27. Nd5 Bc5  28. a6 Bxf2+ 29. Kxf2 c5 30. a7 Rd7 31. Nb6 Raxa7 32. Nxd7 Rxd7 33. Red1 Rxd1 34. Rxd1 Nd4 35. h4 g6 36. g3 g5 37. h5 Kg7 38. g4 Kf6 39. Ke3 Nc2+ 40. Kf2 Nd4 41. Ke3 1/2-1/2 "

; sample game 337
EventSites(337) = "EU-Cup 24th  Kallithea" : GameDates(337) = "20081023" : WhitePlayers(337) = "Bologan, Viktor   G#337" : WhiteElos(337) = "2682" : BlackPlayers(337) = "Naiditsch, Arkadij   G#337" : BlackElos(337) = "2678" : Each_Game_Result(337) = "1/2-1/2"

FilePGNs(337) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. d3 Be7 5. O-O d6 6. a4 Bg4 7. c3 O-O 8. Re1 d5 9. exd5 Nxd5 10. h3 Bh5 11. a5 a6 12. Nbd2 Kh8 13. Ne4 f6 14. Qb3  Bxf3 15. Bxd5 Bh5 16. Be3 Rb8 17. Bc5 Be8 18. Qc4 Bd6 19. d4  f5 20. Nxd6 cxd6 21. Bb6 Qf6 22. dxe5 Nxe5 23. Qc7 Bc6 24. Bxc6 bxc6 25. Rad1 Rfc8 26. Qxd6 Qxd6 27. Rxd6 Nc4 28. Rd7 Nxb6 29. axb6 Rxb6 30. Ree7 Rg8 31. Rb7  Rxb7 32. Rxb7 g6  33. Ra7 Rb8 34. Rxa6 Rxb2 35. Rxc6 Kg7 36. Rc7+ Kh6  37. f4 Rc2 38. g4 g5 39. Rc6+ Kg7 40. gxf5 gxf4 41. c4 Kf7 42. c5 Ke7 43. h4 h5 44. Re6+ Kf7 45. c6 Rc5 46. Rh6 Kg7 47. Rg6+ Kf7 48. Kf2 f3 49. Rh6 Kg7 50. Rg6+ Kf7 51. Rh6 Kg7 52. Rd6 Rxf5 53. Rd7+ Kf6 54. Rh7 Kg6 55. Rd7 Rc5 56. Rd6+ Kf5 57. Kxf3 Rc3+ 58. Ke2 Ke5 59. Rh6 Kd5 60. Kf2 Rxc6 61. Rxh5+ Ke4 62. Kg3 Rg6+ 63. Kh3 Kf4 64. Ra5 Rg3+ 65. Kh2 Re3 66. h5 1/2-1/2 "

; sample game 338
EventSites(338) = "EU-Cup 24th  Kallithea" : GameDates(338) = "20081022" : WhitePlayers(338) = "Eljanov, Pavel   G#338" : WhiteElos(338) = "2720" : BlackPlayers(338) = "Kamsky, Gata   G#338" : BlackElos(338) = "2729" : Each_Game_Result(338) = "1-0"

FilePGNs(338) = "1. Nf3 Nf6 2. c4 b6 3. d4 e6 4. g3 Ba6 5. Qb3 c6 6. Bg5  h6  7. Bxf6 Qxf6 8. Nc3 g5  9. Bg2 Qe7 10. h4 g4 11. Ne5 Bg7 12. O-O O-O 13. Rfd1 h5 14. e3  Rc8 15. Rac1  d6 16. Nd3 Bh6 17. Qa4 Bb7 18. d5  b5 19. dxc6 Bxc6 20. Nxb5 a6 21. Bxc6 Nxc6 22. Nc3 Bg7 23. Ne4 Ne5 24. Nxe5 Bxe5 25. Qa3 Rc6 26. Rc2 Qc7 27. Rcd2 Rxc4 28. Nxd6 Rc1  29. Ne4 Rb8 30. Qd3 Rxd1+ 31. Rxd1 Rxb2 32. Ng5 Kf8 33. Qh7 Bg7 34. Qxh5  Rxf2  35. Qxg4 Rf5  36. Qb4+  Kg8 37. Kg2 Rb5  38. Qf4   Rb2+ 39. Kh3 Qxf4 40. Rd8+  Bf8 41. exf4 Re2 42. Ra8 f6 43. Nf3 Re3 44. Nd4 Re4 45. Nc6 Re3 46. h5 Kf7 47. Ra7+ Ke8 48. Ra8+ Kf7 49. Rxa6 e5 50. fxe5 fxe5 51. Nd8+ Ke7 52. Ne6 Rf3 53. Ng5 1-0 "

; sample game 339
EventSites(339) = "EU-Cup 24th  Kallithea" : GameDates(339) = "20081022" : WhitePlayers(339) = "Inarkiev, Ernesto   G#339" : WhiteElos(339) = "2669" : BlackPlayers(339) = "Greenfeld, Alon   G#339" : BlackElos(339) = "2560" : Each_Game_Result(339) = "1-0"

FilePGNs(339) = "1. d4 Nf6 2. c4 g6 3. Nf3 Bg7 4. g3 O-O 5. Bg2 d6 6. O-O Nbd7 7. Nc3 e5 8. e4 exd4 9. Nxd4 Re8 10. b3  c6 11. Bb2  Nc5  12. Qc2 a5  13. Rad1 Qb6  14. a3  Bd7  15. Kh1  Re7   16. f3   Rae8 17. Bc1  Bc8 18. Be3 Nfd7 19. Bg1  Nb8  20. Rb1  Nba6 21. Rfd1 f5   22. b4  axb4 23. axb4 Nxb4 24. Qb2 fxe4 25. Qxb4 Qxb4 26. Rxb4  exf3 27. Bxf3 Re3  28. Bxe3 Rxe3 29. Nce2  Nd3 30. Rbb1 Ne5  31. Ng1  Nd3 32. Rxd3  Rxd3 33. Nxc6   bxc6 34. Rb8 Bd4 35. Rxc8+ Kg7 36. Ne2  1-0 "

; sample game 340
EventSites(340) = "World Championship  Bonn" : GameDates(340) = "20081029" : WhitePlayers(340) = "Anand, Viswanathan   G#340" : WhiteElos(340) = "2783" : BlackPlayers(340) = "Kramnik, Vladimir   G#340" : BlackElos(340) = "2772" : Each_Game_Result(340) = "1/2-1/2"

FilePGNs(340) = "1. e4  c5  2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bg5 e6 7. f4 Qc7  8. Bxf6 gxf6 9. f5 Qc5 10. Qd3 Nc6 11. Nb3  Qe5 12. O-O-O exf5  13. Qe3  Bg7 14. Rd5 Qe7 15. Qg3 Rg8 16. Qf4  fxe4 17. Nxe4 f5  18. Nxd6+ Kf8 19. Nxc8 Rxc8 20. Kb1  Qe1+ 21. Nc1 Ne7 22. Qd2 Qxd2 23. Rxd2 Bh6 24. Rf2 Be3 1/2-1/2 "

; sample game 341
EventSites(341) = "World Championship  Bonn" : GameDates(341) = "20081018" : WhitePlayers(341) = "Anand, Viswanathan   G#341" : WhiteElos(341) = "2783" : BlackPlayers(341) = "Kramnik, Vladimir   G#341" : BlackElos(341) = "2772" : Each_Game_Result(341) = "1/2-1/2"

FilePGNs(341) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Be7 5. Bf4 O-O 6. e3 Nbd7 7. a3 c5 8. cxd5 Nxd5 9. Nxd5 exd5 10. dxc5 Nxc5 11. Be5 Bf5 12. Be2 Bf6 13. Bxf6 Qxf6 14. Nd4 Ne6  15. Nxf5 Qxf5 16. O-O Rfd8 17. Bg4 Qe5 18. Qb3 Nc5 19. Qb5 b6 20. Rfd1 Rd6 21. Rd4 a6  22. Qb4 h5 23. Bh3 Rad8 24. g3 g5  25. Rad1 g4 26. Bg2 Ne6 27. R4d3 d4  28. exd4 Rxd4 29. Rxd4 Rxd4 1/2-1/2 "

; sample game 342
EventSites(342) = "World Championship  Bonn" : GameDates(342) = "20081026" : WhitePlayers(342) = "Anand, Viswanathan   G#342" : WhiteElos(342) = "2783" : BlackPlayers(342) = "Kramnik, Vladimir   G#342" : BlackElos(342) = "2772" : Each_Game_Result(342) = "1/2-1/2"

FilePGNs(342) = "1. d4 d5 2. c4 e6 3. Nf3 Nf6 4. Nc3 c6 5. Bg5 h6 6. Bh4 dxc4 7. e4 g5 8. Bg3 b5 9. Be2 Bb7 10. Qc2  Nbd7 11. Rd1 Bb4 12. Ne5 Qe7  13. O-O Nxe5 14. Bxe5 O-O 15. Bxf6 Qxf6 16. f4  Qg7 17. e5 c5   18. Nxb5 cxd4 19. Qxc4 a5 20. Kh1  Rac8 21. Qxd4 gxf4 22. Bf3 Ba6 23. a4  Rc5 24. Qxf4 Rxe5 25. b3 Bxb5 26. axb5 Rxb5  27. Be4 Bc3 28. Bc2 Be5 29. Qf2 Bb8 30. Qf3 Rc5 31. Bd3 Rc3 32. g3 Kh8 33. Qb7 f5 34. Qb6  Qe5 35. Qb7 Qc7  36. Qxc7 Bxc7 37. Bc4 Re8 38. Rd7 a4 39. Rxc7 axb3 40. Rf2 Rb8 41. Rb2  h5 42. Kg2 h4 43. Rc6 hxg3 44. hxg3 Rg8 45. Rxe6 Rxc4 1/2-1/2 "

; sample game 343
EventSites(343) = "World Championship  Bonn" : GameDates(343) = "20081027" : WhitePlayers(343) = "Kramnik, Vladimir   G#343" : WhiteElos(343) = "2772" : BlackPlayers(343) = "Anand, Viswanathan   G#343" : BlackElos(343) = "2783" : Each_Game_Result(343) = "1-0"

FilePGNs(343) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Nf3 c5 5. g3 cxd4 6. Nxd4 O-O 7. Bg2 d5 8. cxd5 Nxd5 9. Qb3 Qa5 10. Bd2 Nc6 11. Nxc6 bxc6 12. O-O Bxc3 13. bxc3 Ba6 14. Rfd1 Qc5 15. e4 Bc4 16. Qa4 Nb6 17. Qb4 Qh5 18. Re1   c5 19. Qa5 Rfc8 20. Be3  Be2 21. Bf4  e5 22. Be3 Bg4  23. Qa6   f6 24. a4 Qf7 25. Bf1 Be6 26. Rab1  c4  27. a5 Na4 28. Rb7 Qe8 29. Qd6 1-0 "

; sample game 344
EventSites(344) = "World Championship  Bonn" : GameDates(344) = "20081021" : WhitePlayers(344) = "Anand, Viswanathan   G#344" : WhiteElos(344) = "2783" : BlackPlayers(344) = "Kramnik, Vladimir   G#344" : BlackElos(344) = "2772" : Each_Game_Result(344) = "1-0"

FilePGNs(344) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 d5 5. cxd5 Qxd5 6. Nf3 Qf5 7. Qb3 Nc6 8. Bd2 O-O 9. h3   b6  10. g4 Qa5 11. Rc1 Bb7 12. a3 Bxc3 13. Bxc3 Qd5 14. Qxd5 Nxd5 15. Bd2  Nf6 16. Rg1 Rac8 17. Bg2 Ne7 18. Bb4 c5  19. dxc5 Rfd8 20. Ne5 Bxg2 21. Rxg2 bxc5 22. Rxc5 Ne4 23. Rxc8 Rxc8 24. Nd3  Nd5 25. Bd2 Rc2 26. Bc1 f5 27. Kd1 Rc8 28. f3 Nd6 29. Ke1  a5 30. e3 e5  31. gxf5 e4 32. fxe4 Nxe4 33. Bd2 a4 34. Nf2 Nd6 35. Rg4 Nc4 36. e4  Nf6 37. Rg3 Nxb2 38. e5 Nd5 39. f6 Kf7 40. Ne4 Nc4 41. fxg7 Kg8 42. Rd3 Ndb6 43. Bh6 Nxe5 44. Nf6+ Kf7 45. Rc3 Rxc3 46. g8=Q+ Kxf6 47. Bg7+ 1-0 "

; sample game 345
EventSites(345) = "EU-Cup 24th  Kallithea" : GameDates(345) = "20081021" : WhitePlayers(345) = "Kamsky, Gata   G#345" : WhiteElos(345) = "2729" : BlackPlayers(345) = "Postny, Evgeny   G#345" : BlackElos(345) = "2674" : Each_Game_Result(345) = "1/2-1/2"

FilePGNs(345) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Nd2 e6 5. Nb3 Nd7 6. Nf3 Ne7 7. Be2 Nc8 8. O-O Be7 9. Bd2 O-O 10. h3 Qc7 11. Bd3  Bxd3 12. cxd3 a5 13. a4 Qb6 14. Rc1 Bb4 15. Bg5 h6 16. Be3 Ne7 17. Nh4 f5  18. g3  Rfc8 19. Ng2 Nf8 20. h4  Qd8 21. h5 b5  22. Nc5 Bxc5 23. Rxc5 b4 24. Nf4 Qe8 25. Rc1 Qf7 26. Kg2 Nd7 27. Qe2 Nb6 28. b3 Kf8 29. Rg1 Ke8 30. Kf1 Nd7 31. Ke1 Kd8 32. Kd2 Nf8 33. f3 Kc7 34. g4 Nh7 35. Ng6  Re8 36. Kc2 fxg4 37. Rxg4 Nf5 38. Kb1 Nf8 39. Nf4 Nd7 40. Qc2 Ra6 41. Bf2 Kb7 42. Ng6 Rg8 43. Rcg1 Raa8 44. Qc1 Rac8 45. Rf4 Rc7 46. Rfg4 1/2-1/2 "

; sample game 346
EventSites(346) = "EU-Cup 24th  Kallithea" : GameDates(346) = "20081023" : WhitePlayers(346) = "Ponomariov, Ruslan   G#346" : WhiteElos(346) = "2719" : BlackPlayers(346) = "Postny, Evgeny   G#346" : BlackElos(346) = "2674" : Each_Game_Result(346) = "1/2-1/2"

FilePGNs(346) = "1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Bf5 5. Ng3 Bg6 6. h4 h6 7. Nf3 Nd7 8. h5 Bh7 9. Bd3 Bxd3 10. Qxd3 e6 11. Bf4 Qa5+ 12. Bd2 Qc7 13. O-O-O Ngf6 14. Kb1 O-O-O 15. c4 Bd6 16. Ne4 Nxe4 17. Qxe4 Nf6 18. Qe2 c5 19. Bc3 Rhe8 20. Ne5 cxd4 21. Bxd4 Bxe5 22. Bxe5 Qc6 23. g4 Rxd1+ 24. Rxd1 Rd8 25. Re1  Ne8 26. f4 Qd7   27. Bc3 Qd3+ 28. Qxd3 Rxd3 29. f5 Kd7 30. fxe6+ fxe6 31. Rf1 Ke7 32. Kc2 Rg3 33. Bb4+ Kd8 34. Rf7 Rxg4 35. Kb3 Kc8 36. Bc5 Rg3+ 37. Ka4 Rg2 38. Kb3 Rg3+ 39. Ka4 Rg2 40. b4 Rxa2+ 41. Kb3 Rg2 42. Re7 Nf6 43. Bxa7 Nxh5 44. b5 Nf6 45. Bd4 Rg4 46. Bb6 h5 47. Rc7+ Kb8 48. Rf7 Kc8 49. Rf8+ Kd7 50. Rb8 h4 51. Rxb7+ Kc8 52. Rc7+ Kb8 53. Rf7 h3 54. c5 Nd5 55. Rf8+ Kb7 56. Ba5 Rg3+ 57. Kc4 Rg4+ 58. Kd3 Nb4+ 59. Kc3 h2 60. Rh8 Nd5+ 61. Kd2 Ra4 62. c6+ Ka7 63. c7 h1=Q 64. Rxh1 Rc4  65. Rh8  Rxc7 66. Bxc7 Nxc7 67. Rh5 Kb6  68. Re5 Nxb5 69. Rxe6+ Kc5 70. Rg6 Nd6 71. Ke3 Kd5 72. Kf4 Ne8 73. Kg5 Ke5 74. Rb6 Nc7 75. Kg6 Ne6 76. Rb1 Nf4+ 77. Kxg7 Ne6+ 78. Kf7 Nc5 79. Ke7 Kd5 80. Rd1+ Ke5 81. Rh1 Kd5 82. Rh5+ Kd4 83. Rxc5 Kxc5 1/2-1/2 "

; sample game 347
EventSites(347) = "EU-Cup 24th  Kallithea" : GameDates(347) = "20081021" : WhitePlayers(347) = "Sasikiran, Krishnan   G#347" : WhiteElos(347) = "2694" : BlackPlayers(347) = "Radjabov, Teimour   G#347" : BlackElos(347) = "2751" : Each_Game_Result(347) = "0-1"

FilePGNs(347) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. f3 O-O 6. Bg5 c5 7. d5 e6 8. Qd2 h6 9. Be3 exd5 10. cxd5 Re8 11. a4 a6 12. Nge2 Nbd7 13. Nc1 Nh7 14. Be2 f5 15. O-O Ng5 16. Nd3 Ne5 17. Nf2  Nef7 18. Rae1 Bd7 19. exf5 gxf5 20. Kh1  Rb8 21. Nd3 Re7 22. Nf4 Qe8 23. Bf2 Ne5 24. a5 b5 25. axb6 Rxb6 26. h4 Nh7 27. Ne6  Qb8  28. f4 Rxb2 29. Rb1  Nc4  30. Bxc4 Bxc3 31. Qd3  Rf7 32. Ra1  Rxf2  33. Qg3+ Rg7  34. Qxc3 Rxf1+ 35. Rxf1 Rf7 36. Qd3 Qb2 37. Kg1 Nf8  38. Rb1 Qf6  39. Qg3+  Kh7 40. Re1  Nxe6 41. dxe6 Rg7  42. Qd3 Bc6 43. Re2  Rg4  44. g3 d5  45. Bxd5 Bb5  46. Bc4 Bxc4 47. Qxc4 Rxg3+ 48. Kf1 Qxh4 49. Rf2 Re3 50. Qd5 Qh3+  51. Rg2 Qh1+ 0-1 "

; sample game 348
EventSites(348) = "World Championship  Bonn" : GameDates(348) = "20081014" : WhitePlayers(348) = "Kramnik, Vladimir   G#348" : WhiteElos(348) = "2772" : BlackPlayers(348) = "Anand, Viswanathan   G#348" : BlackElos(348) = "2783" : Each_Game_Result(348) = "1/2-1/2"

FilePGNs(348) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. cxd5 cxd5 5. Bf4 Nc6 6. e3 Bf5 7. Nf3 e6 8. Qb3 Bb4 9. Bb5 O-O 10. Bxc6 Bxc3+ 11. Qxc3 Rc8 12. Ne5 Ng4 13. Nxg4 Bxg4 14. Qb4 Rxc6 15. Qxb7  Qc8 16. Qxc8 Rfxc8 17. O-O a5 18. f3 Bf5 19. Rfe1 Bg6 20. b3 f6 21. e4 dxe4 22. fxe4 Rd8 23. Rad1 Rc2 24. e5 fxe5 25. Bxe5 Rxa2  26. Ra1 Rxa1 27. Rxa1 Rd5 28. Rc1 Rd7 29. Rc5 Ra7 30. Rc7 Rxc7 31. Bxc7 Bc2 32. Bxa5 Bxb3 1/2-1/2 "

; sample game 349
EventSites(349) = "World Championship  Bonn" : GameDates(349) = "20081023" : WhitePlayers(349) = "Anand, Viswanathan   G#349" : WhiteElos(349) = "2783" : BlackPlayers(349) = "Kramnik, Vladimir   G#349" : BlackElos(349) = "2772" : Each_Game_Result(349) = "1/2-1/2"

FilePGNs(349) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 dxc4 5. a4 Bf5 6. e3 e6 7. Bxc4 Bb4 8. O-O Nbd7 9. Qe2 Bg6 10. e4 O-O 11. Bd3 Bh5 12. e5 Nd5 13. Nxd5 cxd5 14. Qe3 Re8 15. Ne1 Bg6 16. Bxg6 hxg6 17. Nd3 Qb6 18. Nxb4 Qxb4 19. b3 Rac8 20. Ba3 Qc3  21. Rac1 Qxe3 22. fxe3  f6 23. Bd6 g5 24. h3 Kf7 25. Kf2 Kg6 26. Ke2 fxe5  27. dxe5 b6 28. b4  Rc4  29. Rxc4 dxc4 30. Rc1 Rc8 31. g4 a5  32. b5 c3  33. Rc2 Kf7 34. Kd3 Nc5+  35. Bxc5 Rxc5 36. Rxc3 Rxc3+ 37. Kxc3 1/2-1/2 "

; sample game 350
EventSites(350) = "World Championship  Bonn" : GameDates(350) = "20081020" : WhitePlayers(350) = "Kramnik, Vladimir   G#350" : WhiteElos(350) = "2772" : BlackPlayers(350) = "Anand, Viswanathan   G#350" : BlackElos(350) = "2783" : Each_Game_Result(350) = "0-1"

FilePGNs(350) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 e6 5. e3 Nbd7 6. Bd3 dxc4 7. Bxc4 b5 8. Bd3 a6 9. e4 c5 10. e5 cxd4 11. Nxb5 axb5 12. exf6 gxf6 13. O-O Qb6 14. Qe2 Bb7  15. Bxb5 Rg8   16. Bf4 Bd6 17. Bg3 f5 18. Rfc1  f4 19. Bh4 Be7 20. a4 Bxh4 21. Nxh4 Ke7  22. Ra3 Rac8 23. Rxc8 Rxc8 24. Ra1 Qc5 25. Qg4 Qe5 26. Nf3 Qf6 27. Re1 Rc5  28. b4 Rc3 29. Nxd4  Qxd4 30. Rd1 Nf6 31. Rxd4 Nxg4 32. Rd7+ Kf6 33. Rxb7 Rc1+ 34. Bf1 Ne3   35. fxe3 fxe3 0-1 "

; sample game 351
EventSites(351) = "RUS-ch superfinal 61st  Moscow" : GameDates(351) = "20081003" : WhitePlayers(351) = "Vitiugov, Nikita   G#351" : WhiteElos(351) = "2638" : BlackPlayers(351) = "Alekseev, Evgeny   G#351" : BlackElos(351) = "2715" : Each_Game_Result(351) = "1/2-1/2"

FilePGNs(351) = "1. d4 Nf6 2. c4 e6 3. g3 c5 4. Nf3 cxd4 5. Nxd4 Qc7 6. Nc3 a6 7. Bg2 Qxc4 8. O-O Nc6 9. Nb3 d5 10. Bf4 Be7 11. a3 a5 12. Rc1 Qa6 13. a4 O-O 14. Nb5 Qb6  15. Bc7 Qa6 16. Bf4 Qb6 17. Bc7 Qa6 18. Nc5 Bxc5 19. Rxc5 Bd7 20. Bd6 Nb4  21. Bxf8 Rxf8  22. Qd4 Bc6 23. e4  e5  24. Qd2 Qb6 25. Rxd5 Nbxd5 26. exd5 Rd8 27. Nc3 Bd7 28. Re1 Re8 29. d6 Qd4 30. Qxd4   exd4 31. Rxe8+ Nxe8 32. Ne4 b6 33. b3 f5 34. Ng5 Nxd6 35. Bd5+ Kf8 36. Nxh7+ Ke7 37. Ng5 b5  38. axb5 Nxb5 39. Kf1 Kd6 40. Bg8 Nc3 41. Ke1 Ne4 42. Nf3 Kc5 43. Ne5 Bb5 44. f3 Nf6 45. Be6  Kd6 46. Bc4 Be8 47. Nd3 Nd5 48. Bxd5  Kxd5 49. Kd2 Kd6 50. h4 Bh5 51. Ne1 Bf7 52. Nc2 Kc5 53. Kd3 f4 54. gxf4 Bg6+ 55. Kd2 Bh7 56. h5  Bf5 57. Ne1 Be6 58. Nd3+ Kd6 59. Kc2  Bf7 60. Ne5 Bxh5 61. Nc4+ Kd5 62. Nxa5 Bxf3 63. Kd3 Bg2 64. Ke2 Ke4 65. Nc6 Bh3 66. b4 Be6 67. Kd2 Bc4 68. Na5  Bb5 69. Nb7 Kxf4 70. Nd6 Bf1 71. b5 Ke5 72. Nf7+ Kd5 73. b6 Ba6 74. Nd8 g5 75. b7 Bxb7 76. Nxb7 g4 77. Na5 g3 78. Ke1   d3 79. Nb3 Kc4 80. Nd2+ Kc3 81. Ne4+ Kc2 82. Kf1 g2+ 83. Kxg2 d2 84. Nxd2 Kxd2 1/2-1/2 "

; sample game 352
EventSites(352) = "RUS-ch superfinal 61st  Moscow" : GameDates(352) = "20081004" : WhitePlayers(352) = "Inarkiev, Ernesto   G#352" : WhiteElos(352) = "2669" : BlackPlayers(352) = "Vitiugov, Nikita   G#352" : BlackElos(352) = "2638" : Each_Game_Result(352) = "0-1"

FilePGNs(352) = "1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Bxc3+ 6. bxc3 Ne7 7. Nf3 b6 8. Bb5+ Bd7 9. Bd3 Ba4 10. h4 h6 11. Bf4 Nbc6 12. h5 a6  13. Qb1 Qc7 14. O-O Na5 15. Ra2  Rb8  16. Re1 Kd7  17. Rb2 c4 18. Be2  Nac6 19. Qc1 b5  20. Nh2  a5 21. Ra2 Qd8 22. Bg4 Qg8  23. Nf1 Kc7 24. Ne3 Kb7 25. Bh3 Nc8 26. Bg3 Nb6 27. f4  f5  28. Qd1  Ne7 29. Rf1 g5 30. hxg6 Nxg6 31. Bxf5  exf5 32. Nxf5 Ka6 33. Qf3 h5 34. Ne3 h4 35. Bh2 h3 36. g4 Nh4 37. Qg3 Rb7  38. f5 Ng2 39. g5  Rh5 40. g6 Nxe3 41. Qxe3 Rf7  42. f6 Qxg6+ 43. Bg3 h2+ 44. Kh1 Rh3 45. Rf3 Bxc2 0-1 "

; sample game 353
EventSites(353) = "EU-Cup 24th  Kallithea" : GameDates(353) = "20081019" : WhitePlayers(353) = "Alekseev, Evgeny   G#353" : WhiteElos(353) = "2715" : BlackPlayers(353) = "Vitiugov, Nikita   G#353" : BlackElos(353) = "2638" : Each_Game_Result(353) = "1/2-1/2"

FilePGNs(353) = "1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Bxc3+ 6. bxc3 Ne7 7. Qg4 cxd4  8. Qxg7 Rg8 9. Qxh7 Qc7 10. Ne2 Nbc6 11. f4 dxc3 12. Qd3 Bd7 13. Nxc3 a6 14. h4 Nf5 15. Rh3 O-O-O 16. Rb1 Na5 17. Rb4  Nc4  18. h5 Qc5  19. Ne4  Qg1 20. Ng5 Bb5 21. Qe2  Qc5  22. Qf2 Qc7 23. h6 Rxg5 24. h7 Rgg8 25. hxg8=Q Rxg8 26. Bd3 Kb8 27. Rh7  Nxa3  28. Bxa3  Qc3+ 29. Qd2 Qxa3 30. Rxf7  Qa1+ 31. Qd1 Qc3+ 32. Qd2 Qa1+   33. Qd1 Qc3+ 34. Qd2 Qa1+ 1/2-1/2 "

; sample game 354
EventSites(354) = "EU-Cup 24th  Kallithea" : GameDates(354) = "20081020" : WhitePlayers(354) = "Nyback, Tomi   G#354" : WhiteElos(354) = "2634" : BlackPlayers(354) = "Vitiugov, Nikita   G#354" : BlackElos(354) = "2638" : Each_Game_Result(354) = "0-1"

FilePGNs(354) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. e3 Bf5 5. Nc3 e6 6. Nh4 Bg6 7. Nxg6 hxg6 8. g3  Nbd7 9. Bg2 dxc4 10. Qe2 Nb6 11. O-O Bb4 12. Rd1 Qe7 13. e4 e5 14. Be3 O-O 15. a4  Rfd8  16. a5 Nbd7 17. d5 cxd5 18. exd5 e4 19. Bd4 Rac8 20. Ra4  Bxc3 21. bxc3 b5 22. axb6 Nxb6 23. Bxb6 axb6 24. Rxc4 Rxc4 25. Qxc4 Qe5 26. Qb3   Rxd5 27. Rxd5 Nxd5  28. Qb5 Qe6 29. Qc4 f5 30. Qd4 Nf6 31. Bf1 Kh7 32. Bc4 Qc6 33. Kf1 g5 34. h3 Qc5   35. Ke2 Qxd4 36. cxd4 g6 37. Ke3 Kg7 38. f3 exf3 39. Kxf3 Ne4 40. Bd5 Nd6 41. Ke3 Kf6 42. Kd3 Ne4  43. g4 Nf2+ 0-1 "

; sample game 355
EventSites(355) = "Dresden ol (Men) 38th  Dresden" : GameDates(355) = "20081116" : WhitePlayers(355) = "Abdel Razik, Khaled   G#355" : WhiteElos(355) = "2406" : BlackPlayers(355) = "Postny, Evgeny   G#355" : BlackElos(355) = "2674" : Each_Game_Result(355) = "1-0"

FilePGNs(355) = "1. Nf3 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 c5 5. a3 Ba5 6. g4 d6   7. g5 Nfd7  8. Ne4 Bc7 9. b4 Nc6 10. Bb2 e5 11. h4  cxb4 12. d4  bxa3  13. Bxa3 O-O 14. d5 Nd4  15. Nxd4 Ba5+  16. Kd1  exd4 17. Nxd6  Bc3 18. Ra2  Ne5 19. e3  Bg4+ 20. Kc1 Bf3 21. Rh3 Qd7  22. exd4 Bxd4 23. Rxf3  Nxf3 24. Qf5  Ne5  25. Qe4 Qg4 26. Qxg4 Nxg4 27. Nf5 Bb6 28. c5  Bd8 29. Re2  f6 30. Bh3 Ne5 31. Kb1  Nc4  32. Bc1 Ba5 33. Rc2  Ne5 34. Nd6 fxg5 35. Be6+ Kh8 36. hxg5  Bc7 37. Be3 Bxd6 38. cxd6 Nf7 39. d7  b6 40. Bf4 Rad8 41. Rc8 Kg8 42. g6 hxg6 43. Bc7 Rxc8 44. dxc8=Q Rxc8 45. Bxc8 Kf8 46. d6 Ke8 47. f4 g5 48. Be6 1-0 "

; sample game 356
EventSites(356) = "Dresden ol (Men) 38th  Dresden" : GameDates(356) = "20081119" : WhitePlayers(356) = "Hillarp Persson, Tiger   G#356" : WhiteElos(356) = "2543" : BlackPlayers(356) = "Avrukh, Boris   G#356" : BlackElos(356) = "2657" : Each_Game_Result(356) = "1/2-1/2"

FilePGNs(356) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. Bg5 Ne4 5. Bh4 Nxc3 6. bxc3 dxc4 7. e3 Be6 8. Rb1 Nd7  9. Qa4 Bd5  10. Bxc4 Bxg2 11. Qb3 Bh6  12. Bxf7+ Kf8 13. Bd5 Nc5  14. Bxg2 Nxb3 15. Rxb3  Rb8  16. Nf3 Bg7 17. O-O b5 18. Bg3 Rb6 19. c4  bxc4 20. Rc3 Bf6 21. Rxc4 c6 22. Ne5 Bxe5  23. Bxe5 Rg8 24. Rfc1 Kf7 25. d5  cxd5 26. Rc5 Re8  27. Rxd5 Rd6 28. Bxd6 exd6 29. Rc6 Re6  30. Rd4 Kg7  31. h4 Qb8 32. Bd5 Rf6 33. Bb3 Kh6 34. Rcc4 Qb5 35. Rc2 Qa5 36. Rcd2 Qc5 37. Rd5 Qc8 38. Kh2 Qc3 39. Kg2 Qb4 40. R5d4 Qb7+ 41. Bd5 Qc7 42. Bb3 Qe7 43. Rg4 Rf5 44. Rdd4 Qb7+ 45. Kg1 Qc7 46. Rgf4 Rxf4 1/2-1/2 "

; sample game 357
EventSites(357) = "Dresden ol (Men) 38th  Dresden" : GameDates(357) = "20081122" : WhitePlayers(357) = "Sargissian, Gabriel   G#357" : WhiteElos(357) = "2642" : BlackPlayers(357) = "Avrukh, Boris   G#357" : BlackElos(357) = "2657" : Each_Game_Result(357) = "1-0"

FilePGNs(357) = "1. Nf3 c5 2. c4 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e6 6. g3 Qb6 7. Ndb5 Ne5 8. Bf4 Nfg4 9. Qa4  a6   10. f3 g5  11. Bxg5 f6 12. Bf4 Ne3 13. Nc7+ Qxc7 14. Bxe3 Nxc4 15. Bf4 Qc5  16. Ne4  Qb4+ 17. Qxb4 Bxb4+ 18. Kf2 f5  19. b3  fxe4 20. bxc4 b5 21. Rb1 Bc5+ 22. Be3 Be7 23. Bg2 O-O 24. f4  bxc4 25. Bxe4 d5 26. Bf3 Bf6 27. Bc5  Rf7 28. e4 Rc7 29. Be3 d4 30. e5 dxe3+ 31. Kxe3 Raa7 32. exf6 Kf7 33. Rhc1 Rc5 34. Kd4 Rac7 35. Rc3  Kxf6 36. Be4 Ra5 37. Rb2  Ra4   38. g4  h6 39. h4 Kg7 40. g5 Rd7+ 41. Ke3 Rc7 42. a3 Ra5 43. Rb4 Bd7 44. Rb6 Bc8 45. Rb4 Bd7 46. Kd4 Bb5 47. Bc2 Rf7 48. Ke3 Bd7 49. Rb6  Bc8 50. Rc6 Bd7 51. Rd6 Bc8 52. Be4 Rc5 53. Rb6 Ra5  54. Rc6 Bd7 55. Rc7   hxg5 56. fxg5  Be8 57. R7xc4 Rb5 58. Rc8 Bd7 59. Rd8 Ra5 60. g6 Re7 61. Rc7 Rxa3+ 62. Kd2 Ra2+ 63. Kc1 1-0 "

; sample game 358
EventSites(358) = "Dresden ol (Men) 38th  Dresden" : GameDates(358) = "20081114" : WhitePlayers(358) = "Jakovenko, Dmitrij   G#358" : WhiteElos(358) = "2737" : BlackPlayers(358) = "Bartel, Mateusz   G#358" : BlackElos(358) = "2602" : Each_Game_Result(358) = "1-0"

FilePGNs(358) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O b5 6. Bb3 Bb7 7. d3 Be7 8. Re1 O-O 9. h3  h6  10. Nbd2 Re8 11. c3 Bf8 12. a4 Na5 13. Bc2 c5 14. d4  cxd4 15. cxd4 d5  16. dxe5 Nxe4 17. axb5 axb5 18. Qe2 Rc8  19. Nxe4 dxe4 20. Bxe4 Bxe4 21. Qxe4 Nb3 22. Rb1 Rc4 23. Qe2 f6 24. Rd1 Qc7  25. Bxh6  fxe5 26. Be3 Qf7 27. Ng5 Qg6 28. Qf3 Nd4 29. Bxd4 exd4 30. Qd5+ Kh8 31. Nf3 Bd6 32. Ra1 Rd8 33. Ne5 1-0 "

; sample game 359
EventSites(359) = "Dresden ol (Men) 38th  Dresden" : GameDates(359) = "20081122" : WhitePlayers(359) = "Fridman, Daniel   G#359" : WhiteElos(359) = "2630" : BlackPlayers(359) = "Bartel, Mateusz   G#359" : BlackElos(359) = "2602" : Each_Game_Result(359) = "1-0"

FilePGNs(359) = "1. d4 Nf6 2. c4 e6 3. g3 d5 4. Bg2 dxc4 5. Nf3 Bb4+ 6. Bd2 a5 7. Qc2 Nc6 8. Qxc4 Qd5 9. Qd3 O-O 10. Nc3 Qh5 11. h3  Rd8 12. a3  Bxc3  13. bxc3 Qg6 14. Qxg6 hxg6 15. Bg5  Rd7  16. O-O Ne4 17. Rac1  Nxg5 18. Nxg5 Ne7 19. e3 Rb8 20. Rb1 b6 21. c4 Rd8  22. Rfc1 Bd7  23. Ne4 Bc6 24. Nc3 Bxg2 25. Kxg2 Nf5 26. Rc2 Kf8 27. g4 Nd6 28. Na4 Ke8 29. Kf3 Rdc8 30. Rbb2 b5  31. cxb5 Rxb5 32. Ra2 Kd8 33. Nc5 Rcb8 34. Nd3 g5  35. Ne5 Ra8 36. a4 Rb6 37. Rc5 f6  38. Nc6+ Kd7 39. Nxa5 Rba6  40. Nb3 Rxa4 41. Rxa4 Rxa4 42. Rxg5  fxg5 43. Nc5+ Ke7 44. Nxa4 Nf7 45. Ke4 Nd6+ 46. Kd3 Nf7 47. Nc5 e5 48. d5 Nd6 49. f3 g6 50. Kc3  Nc8  51. e4  c6  52. dxc6 Na7 53. Kc4  Nxc6 54. Kd5 Nd4 55. Nd3 Nxf3 56. Nxe5 Ng1 57. h4 gxh4 58. Nxg6+ Kf6 59. Nxh4 Kg5 60. e5  Ne2 61. Ng2  Nc3+ 62. Kd4  Nb5+ 63. Kc5 Kxg4  64. e6 Nc7 65. e7 Kf5 66. Kd6 Ne8+ 67. Kd7 Ng7 68. Ne3+ Ke5 69. Nc4+ Kf6 70. Nd6 Ke5 71. Nf7+ Kf5 72. Nd6+ Ke5 73. Nb7 Kf5 74. Nc5 Nh5 75. Ke8 Kg6 76. Ne6 Kf6 77. Kf8 1-0 "

; sample game 360
EventSites(360) = "Dresden ol (Men) 38th  Dresden" : GameDates(360) = "20081117" : WhitePlayers(360) = "Adams, Michael   G#360" : WhiteElos(360) = "2734" : BlackPlayers(360) = "Caruana, Fabiano   G#360" : BlackElos(360) = "2640" : Each_Game_Result(360) = "0-1"

FilePGNs(360) = "1. e4 e6 2. d4 d5 3. Nd2 Be7 4. Ngf3 Nf6 5. e5 Nfd7 6. Bd3 c5 7. c3 b6 8. Qe2 a5 9. a4 Ba6 10. Bxa6 Nxa6 11. O-O Nc7 12. Re1 Nb8 13. Nb3  Nc6 14. Be3 c4 15. Nc1 b5  16. axb5 Nxb5 17. Qc2 Nba7  18. g3 Nc8 19. h4 h6 20. Ne2 Nb6 21. h5 a4  22. Nh2 Kd7 23. f4 Kc7 24. f5 Bg5 25. Nf4 Ne7 26. fxe6 Bxf4 27. Bxf4 fxe6 28. Rf1 Qd7 29. Rf2 Raf8 30. Raf1 Qe8 31. Qe2 Rf5 32. g4 Rf7 33. Bc1 Rhf8 34. Nf3 Nd7 35. Qc2 Nb6 36. Kg2  Qb5 37. Nh4  Qb3  38. Qh7  Rxf2+ 39. Rxf2 Rxf2+ 40. Kxf2 Kd7 41. Nf3 a3 42. bxa3 Na4  43. Bd2 Nxc3 44. Bxc3 Qxc3 45. Qb1 Kc7 46. a4 Nc6 47. Qg6 Qb2+ 48. Kg3 c3 49. Ne1 Qe2 50. Nc2 Kb6 51. a5+ Kxa5 52. Qxe6 Qd3+   53. Kf4 Qe4+ 54. Kg3 Qd3+ 55. Kf4 Qxc2 56. Qxd5+ Kb4 57. Qc5+ Kb3 58. Qd5+ Kb2 59. Qb5+ Qb3 60. Qxc6 c2 61. Qg2 Qb4 62. Kf5 Qxd4 63. Qe2 Kc3 64. Qe1+ Qd2 65. Qa1+ Kb3 0-1 "

; sample game 361
EventSites(361) = "Elista FIDE GP  Elista" : GameDates(361) = "20081223" : WhitePlayers(361) = "Gashimov, Vugar   G#361" : WhiteElos(361) = "2703" : BlackPlayers(361) = "Mamedyarov, Shakhriyar   G#361" : BlackElos(361) = "2731" : Each_Game_Result(361) = "1-0"

FilePGNs(361) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 d6 6. Bg5 e6 7. Qd2 Be7 8. O-O-O a6 9. f4 Nxd4 10. Qxd4 b5 11. Bxf6 gxf6 12. Bd3 Qc7 13. Qe3 Bd7 14. Kb1 Qc5  15. Qg3 O-O-O 16. Ne2 Kb8 17. f5 Rdg8 18. Qf3 h5 19. Nf4 h4 20. Rhe1 Bd8 21. c3  Bc7 22. Bc2 Qe5 23. g3 Qc5  24. g4 Bc8 25. h3 Qe5 26. Nh5  Bb6 27. Qf1 Re8 28. Nf4 Rhg8 29. Re2 Bc7 30. Nd3 Qg3 31. Nf4 Bb6 32. Rde1 1-0 "

; sample game 362
EventSites(362) = "Elista FIDE GP  Elista" : GameDates(362) = "20081226" : WhitePlayers(362) = "Gashimov, Vugar   G#362" : WhiteElos(362) = "2703" : BlackPlayers(362) = "Jakovenko, Dmitrij   G#362" : BlackElos(362) = "2737" : Each_Game_Result(362) = "1/2-1/2"

FilePGNs(362) = "1. e4 c6 2. d4 d5 3. Nd2 dxe4 4. Nxe4 Bf5 5. Ng3 Bg6 6. h4 h6 7. Nf3 Nd7 8. h5 Bh7 9. Bd3 Bxd3 10. Qxd3 e6 11. Bd2 Ngf6 12. O-O-O Be7 13. Qe2 c5 14. Rhe1 O-O 15. Nf5 cxd4 16. N3xd4 Bc5 17. Nxh6+ gxh6 18. Bxh6 Re8 19. g4  Nd5 20. g5 Qb6  21. Nf3  Qa6 22. Qxa6 bxa6 23. c4 N5b6 24. g6 f6  25. Re2 Rad8 26. b3 Nf8 27. Rxd8 Rxd8 28. Bxf8 Bxf8 29. Rxe6 Kg7 30. Kc2  Bb4 31. Rc6  Kh6 32. Rxf6 Kxh5 33. g7  Rg8 34. Rf7  Nc8  35. Rc7 Ne7  36. Rxa7  Rxg7 37. Ne5 Bc5 38. Rxa6 Bxf2 39. Nd3 Bg1 40. b4 Kg5  41. Kc3 Kf5 42. a4 Rg4 43. Rd6 Nc8  44. Rd8 Nb6 45. c5 Nxa4+ 46. Kb3 Nxc5+ 47. Nxc5 Ke5 48. Rd1 Bxc5 49. bxc5 Ke6 50. c6 Ke7 51. Rd7+ Ke8 52. Rd3 Ke7 53. c7 Rg8 54. Rd8 Rxd8 55. cxd8=Q+ Kxd8 1/2-1/2 "

; sample game 363
EventSites(363) = "Dresden ol (Men) 38th  Dresden" : GameDates(363) = "20081121" : WhitePlayers(363) = "Gelfand, Boris   G#363" : WhiteElos(363) = "2719" : BlackPlayers(363) = "Naiditsch, Arkadij   G#363" : BlackElos(363) = "2678" : Each_Game_Result(363) = "1-0"

FilePGNs(363) = "1. Nf3 Nf6 2. c4 e6 3. d4 d5 4. Nc3 dxc4 5. e4 Bb4 6. Bg5 c5 7. Bxc4 cxd4 8. Nxd4 Bxc3+ 9. bxc3 Qa5 10. Bb5+ Nbd7 11. Bxf6 Qxc3+ 12. Kf1 gxf6 13. h4 a6 14. Rh3 Qb4 15. Be2 Ne5  16. h5  Bd7  17. Rb3 Qd6 18. Rxb7 Rd8 19. Nb3 Qc6  20. Rb4 Qc7 21. Rc1 Nc6 22. Kg1 Qf4 23. Rbc4 O-O 24. R1c3 a5  25. Qc1  Qxc1+ 26. Rxc1 Ne5  27. Rd4 a4 28. Nc5 Bc6 29. Rxd8 Rxd8 30. f4 Rd2 31. fxe5 Rxe2 32. exf6 h6 33. Rd1 Kh7 34. Rd8 Bxe4 35. Kf1 1-0 "

; sample game 364
EventSites(364) = "Dresden ol (Men) 38th  Dresden" : GameDates(364) = "20081122" : WhitePlayers(364) = "Aronian, Levon   G#364" : WhiteElos(364) = "2757" : BlackPlayers(364) = "Gelfand, Boris   G#364" : BlackElos(364) = "2719" : Each_Game_Result(364) = "0-1"

FilePGNs(364) = "1. c4 e5 2. Nc3 Nf6 3. Nf3 Nc6 4. g3 Bb4 5. Bg2 O-O 6. O-O Bxc3 7. bxc3 Re8 8. d3 e4 9. Nd4 exd3 10. exd3 Nxd4 11. cxd4 d5 12. Rb1 h6 13. Bf4 b6 14. Be5 c6 15. h3 Be6 16. Rc1 Rc8 17. f4 dxc4 18. dxc4 b5  19. d5  cxd5 20. cxb5 Rxc1 21. Qxc1 Qb6+ 22. Kh2 Qxb5 23. Bxf6 gxf6 24. f5 Bd7 25. Qxh6 Qb2  26. Kh1 Re2 27. Bxd5  Bxf5 28. Qf4 Be6 29. Bf3 Rh2+ 30. Kg1 Rxh3  31. Bg2 Rh5  32. Qxf6 Qxf6 33. Rxf6 Ra5 34. Rf4 Rxa2 35. Rd4 a5 36. Bd5 Ra1+ 37. Kf2 a4 38. Rd2 a3  39. Bxe6 fxe6 40. Ke3 Kf7 41. g4 Rb1 42. Rf2+ Ke7 43. Ra2 Rb3+ 44. Kf4 Rb4+ 45. Kg5 Ra4 46. Kh6 e5 47. g5 Kf7 48. g6+ Kg8 49. Kg5 e4 0-1 "

; sample game 365
EventSites(365) = "RUS-ch (Women) Superfinal  Moscow" : GameDates(365) = "20081211" : WhitePlayers(365) = "Kosintseva, Tatiana   G#365" : WhiteElos(365) = "2513" : BlackPlayers(365) = "Romanko Guseva, Marina   G#365" : BlackElos(365) = "2398" : Each_Game_Result(365) = "1-0"

FilePGNs(365) = "1. e4 c5 2. Nf3 Nc6 3. Bb5 Nf6 4. Nc3 Nd4 5. e5 Nxb5 6. Nxb5 Nd5 7. Ng5 f5 8. O-O a6 9. Nc3 Nxc3 10. bxc3 e6 11. d4 g6 12. Nf3 h6 13. Be3 b5  14. dxc5 Bb7 15. a4 bxa4  16. Nd2 Qc7 17. Nc4 Qc6 18. f3 Bxc5 19. Nd6+ Ke7  20. Bd4 Rab8 21. Qe1  g5  22. Qf2 Bxd4 23. Qxd4 Ba8 24. Rxa4 Qb6 25. Rfa1 g4 26. Rxa6  Qxd4+ 27. cxd4 gxf3 28. gxf3 Bxf3 29. Kf2 Ba8 30. Rg1 Rhg8 31. Rxg8 Rxg8 32. Ra3 Rg2+  33. Kf1 Bc6  34. Rg3 Rxg3 35. hxg3 Kf8 36. Kf2 Kg7 37. Ke3 Kg6 38. Kf4 Ba8 39. Nc8 Kf7 40. Nb6 Bc6 41. c4 Ke7 42. d5 Bb7 43. Ke3  Kd8  44. d6  Bc6 45. Kf4 Ke8 46. Nc8  Kf7 47. Ne7 Ba4 48. c5 Bb5 49. Kf3 Ba4 50. Kg2 Bc2 51. Kh3 Be4 52. Kh2 Bb7 53. Kg1 Be4 54. Kf2 Bb7 55. Ke3 Bg2 56. Kd4 Bf3 57. Ke3 Bg2 58. Kf4 Bf1 59. c6 dxc6 60. Nxc6 Ke8 61. Ne7 Kf7 62. Ng8 Bb5 63. Nf6  Ba4 64. Ke3 Bd1 65. Kd4 f4 66. gxf4 h5 67. Ke3 h4 68. Kf2 Bc2 69. Kf3 Bf5 70. Ng4 Ke8 71. Ne3 Kd7 72. Nxf5 1-0 "

; sample game 366
EventSites(366) = "Dresden ol (Men) 38th  Dresden" : GameDates(366) = "20081115" : WhitePlayers(366) = "Lie, Kjetil A   G#366" : WhiteElos(366) = "2526" : BlackPlayers(366) = "Bu Xiangzhi   G#366" : BlackElos(366) = "2714" : Each_Game_Result(366) = "1-0"

FilePGNs(366) = "1. c4 c6 2. e4 d5 3. cxd5 cxd5 4. e5 Nc6 5. d4 Bf5 6. Bd3 Bxd3 7. Qxd3 e6 8. Nf3 Nge7 9. h4  Qb6 10. Nc3 Nf5 11. Be3  Rd8 12. g4  Nxe3 13. fxe3 Be7  14. O-O O-O 15. Rf2 Nb4 16. Qd2 Qa6 17. Rd1 f6 18. a3 Nc6 19. exf6 Rxf6 20. Ne2  Bd6 21. Rdf1 Na5  22. Ng5  Rxf2 23. Rxf2 Be7 24. e4  h6 25. Qf4  Rf8 26. Qc7 Rxf2 27. Kxf2 Bxg5 28. hxg5 Qb6  29. Qc8+ Kh7 30. g6+  Kxg6 31. exd5 Qd6 32. Qxe6+ Qxe6 33. dxe6 Kf6 34. d5 Nc4 35. Nd4  g6 36. b3  Nd6 37. Nf3 Nb5 38. Ke3  Nxa3 39. Nd4  Ke7 40. Kf4 Kd6 41. g5  h5 42. Nf5+  Kc7 43. d6+ 1-0 "

; sample game 367
EventSites(367) = "Dresden ol (Men) 38th  Dresden" : GameDates(367) = "20081119" : WhitePlayers(367) = "Nisipeanu, Liviu Dieter   G#367" : WhiteElos(367) = "2684" : BlackPlayers(367) = "Topalov, Veselin   G#367" : BlackElos(367) = "2791" : Each_Game_Result(367) = "0-1"

FilePGNs(367) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bc4 e6 7. Bb3 Nbd7 8. Bg5 Qa5 9. Bxf6 Nxf6 10. O-O Be7 11. f4 Qc5 12. Kh1 b5 13. a3 Bb7 14. Qd3 g6  15. f5  gxf5 16. Nxf5  exf5 17. Rxf5 d5  18. exd5  Qd6  19. Raf1 Ng4 20. Qh3 Rg8  21. Ne4  Qh6  22. Qxh6  Nxh6  23. Re5 Kf8 24. h3  Rg6 25. g4 Re8 26. Re1 Ng8 27. Nc5 Ba8 28. g5  Rd8 0-1 "

; sample game 368
EventSites(368) = "Dresden ol (Men) 38th  Dresden" : GameDates(368) = "20081120" : WhitePlayers(368) = "Naiditsch, Arkadij   G#368" : WhiteElos(368) = "2678" : BlackPlayers(368) = "Nisipeanu, Liviu Dieter   G#368" : BlackElos(368) = "2684" : Each_Game_Result(368) = "0-1"

FilePGNs(368) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Nd2 e6 5. Nb3 Nd7 6. Nf3 Ne7 7. Be2 Nc8 8. a4 Be7 9. a5 a6  10. Be3 Na7 11. O-O O-O 12. c4 dxc4 13. Bxc4 Nb5 14. Ne1  c5  15. Nxc5  Bxc5 16. dxc5 Nxe5  17. Be2 Qxd1  18. Rxd1 Rfd8 19. Nf3  Bd3  20. Nxe5 Bxe2 21. Rxd8+ Rxd8 22. Re1 Na7   23. f3 Bb5 24. Bf2 Rd2 25. b4 Nc6  26. Nxc6 Bxc6 27. Re3 Rb2  28. Be1 Bd5 29. h4 f6 30. Kh2 Kf7 31. Rd3 h5 32. Kg3 Ke7 33. Bc3 Rc2 34. Bd2 Bc6 35. Kf2 Rc4  36. g3  Rc2 37. Ke3 Rb2 38. Bc3 Rb1 39. Kf2 Kf7 40. Re3 Rc1 41. Bd2 Rc2 42. Rd3 Rb2 43. Ke3 Kg6 44. g4 Rb1 45. Kf2 Rh1  46. Kg3 Rf1  47. Re3 e5 48. Rd3 e4  49. fxe4 Bxe4  50. gxh5+ Kxh5 51. Rd7 f5  0-1 "

; sample game 369
EventSites(369) = "Dresden ol (Men) 38th  Dresden" : GameDates(369) = "20081123" : WhitePlayers(369) = "Nisipeanu, Liviu Dieter   G#369" : WhiteElos(369) = "2684" : BlackPlayers(369) = "Papaioannou, Ioannis   G#369" : BlackElos(369) = "2597" : Each_Game_Result(369) = "1-0"

FilePGNs(369) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bc4 e6 7. Bb3 b5 8. Bg5 Be7 9. Qf3 Qc7 10. e5 Bb7 11. exd6 Bxd6 12. Qe3 Be5 13. O-O-O O-O 14. f4 Bxd4 15. Rxd4 Nbd7 16. Rhd1 Bc6 17. Qg3   Kh8 18. Qh3 Qb7  19. f5  Bxg2 20. Qg3 b4 21. Na4 Bd5 22. Nc5  Qb8  23. Qh3  Rc8  24. Nxd7 Nxd7 25. fxe6  Bxb3 26. exd7 1-0 "

; sample game 370
EventSites(370) = "Dresden ol (Men) 38th  Dresden" : GameDates(370) = "20081120" : WhitePlayers(370) = "Postny, Evgeny   G#370" : WhiteElos(370) = "2674" : BlackPlayers(370) = "Illescas Cordoba, Miguel   G#370" : BlackElos(370) = "2604" : Each_Game_Result(370) = "1-0"

FilePGNs(370) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. g3 dxc4 5. Bg2 c5 6. O-O Nc6 7. Qa4 cxd4 8. Nxd4 Qxd4 9. Bxc6+ Bd7 10. Rd1 Qxd1+ 11. Qxd1 Bxc6 12. Nd2 Rd8 13. Qc2 a6   14. Qxc4 Be7 15. Nf1 O-O 16. Bf4 Rd7 17. Rc1 Rfd8 18. Qb3 Bb5 19. Qf3 Nd5 20. Be5 Bf8 21. Qg4  Nb4  22. a3 Nc6 23. Bc3 Nd4 24. Bxd4 Rxd4 25. Qf3 Bc6 26. Qb3 g6 27. f3 Bb5 28. Kf2 b6 29. Ke1 Bc5 30. Ne3 Ba4 31. Qc3 a5 32. Kf1 Bb5 33. Ng4 Rd1+ 34. Kg2 Rxc1  35. Qxc1 Bxe2 36. Qf4   Rd1  37. Nh6+ Kg7 38. Qxf7+ Kxh6 39. Qf4+ Kg7 40. Qe5+ Kf7 41. Qxe2 Rd4 42. Qe5 h5 43. h4 Rd2+ 44. Kh3 Bd6 45. Qc3 Rd5 46. Qe3 Bc5 47. Qf4+ Kg7 48. Qc7+ Kf6  49. b4  axb4 50. axb4 Bd4 51. Qf4+  Ke7 52. Qe4 Kf7 53. g4 b5 54. Qf4+ Kg8  55. Qb8+ Kh7 56. Qe8 Bg7 57. Qxe6 hxg4+ 58. fxg4 Rd3+ 59. Kg2 Rd4 60. h5 gxh5 61. Qf5+ Kg8 62. g5 Rxb4 63. g6 Rb2+ 64. Kf1 1-0 "

; sample game 371
EventSites(371) = "Elista FIDE GP  Elista" : GameDates(371) = "20081216" : WhitePlayers(371) = "Radjabov, Teimour   G#371" : WhiteElos(371) = "2751" : BlackPlayers(371) = "Kasimdzhanov, Rustam   G#371" : BlackElos(371) = "2672" : Each_Game_Result(371) = "1-0"

FilePGNs(371) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 g6 6. Be3 Bg7 7. f3 Nc6 8. Qd2 O-O 9. Bc4 Bd7 10. O-O-O Rc8 11. Bb3 Ne5 12. h4 h5 13. Kb1 Re8 14. g4 hxg4 15. h5 Nxh5 16. Bh6 Kh7 17. Bxg7 Kxg7 18. fxg4 Bxg4 19. Nf5+ Bxf5 20. exf5 Rh8 21. fxg6 Nxg6 22. Ne4   Nf6 23. Rdf1  Rxh1 24. Rxh1 d5 25. Nxf6 Kxf6 26. Qf2+ Kg7 27. Rf1 f6 28. Qf5  Rc6  29. Rg1  Qe8 30. Bxd5 Rc5 31. Qe6  Rb5 32. c4 Rb6 33. Qh3  e6 34. Bf3  Qd8 35. Qg2  1-0 "

; sample game 372
EventSites(372) = "Elista FIDE GP  Elista" : GameDates(372) = "20081225" : WhitePlayers(372) = "Radjabov, Teimour   G#372" : WhiteElos(372) = "2751" : BlackPlayers(372) = "Alekseev, Evgeny   G#372" : BlackElos(372) = "2715" : Each_Game_Result(372) = "1-0"

FilePGNs(372) = "1. c4 e6 2. Nf3 Nf6 3. g3 b6 4. Bg2 Bb7 5. O-O Be7 6. b3 O-O 7. Bb2 d5 8. e3 Nbd7 9. Nc3 a6 10. Qe2 Bd6 11. d3 Qe7 12. Nh4  g6 13. f4  c6  14. e4  dxe4 15. Nxe4  Nxe4 16. Bxe4 Nf6  17. Bg2 Rad8 18. Rad1  Rfe8 19. Ba1  Rd7 20. Kh1 Nh5  21. Qb2 f6 22. d4  Qf8 23. Nf3 Qh6 24. Kg1 c5 25. Ne5  Bxg2 26. Nxd7  Bxf1 27. Rxf1 Qg7 28. Nxb6 g5 29. Qe2  Nxg3 30. hxg3 gxf4 31. Qh5  Rb8 32. Na4 cxd4 33. Bxd4 e5 34. Bf2  fxg3 35. Be3 Qf7 36. Qxf7+  Kxf7 37. Kg2 Rg8 38. Nc3 Ke6 39. Ne4 Be7 40. Bc5 Bd8  41. Nxg3 f5 42. Kh3  f4 43. Ne4 Kf5 44. Re1 h5 45. b4  Rg4 46. Bf2 Be7 47. c5 f3 48. c6 Bd8 49. Rd1  Bc7 50. Ng3+ Ke6 51. Rd7 Bd6 52. Nxh5 Rc4 53. Ng7+ Kd5 54. Bc5 1-0 "

; sample game 373
EventSites(373) = "Dresden ol (Men) 38th  Dresden" : GameDates(373) = "20081115" : WhitePlayers(373) = "Roiz, Michael   G#373" : WhiteElos(373) = "2677" : BlackPlayers(373) = "Rozentalis, Eduardas   G#373" : BlackElos(373) = "2577" : Each_Game_Result(373) = "1-0"

FilePGNs(373) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Bb7 5. Bg2 Be7 6. O-O O-O 7. Re1 Na6 8. Nc3 Ne4 9. Nxe4 Bxe4 10. Ne5 Bxg2 11. Kxg2 Qe8   12. e4 d6 13. Nf3 b5 14. Qe2 Rb8 15. b3 bxc4 16. Qxc4 Qb5 17. Qxb5 Rxb5 18. Bd2 c5 19. Rac1 Rb7 20. Re2 h6 21. Be3 cxd4 22. Nxd4 Nc5 23. f3 Bg5  24. f4 Bd8 25. Kf3 Bb6 26. Rd1  g6 27. Rc2 f5 28. exf5 exf5 29. Nb5 Nxb3  30. Nxd6  Bxe3 31. Kxe3 Re7+ 32. Kf3 Na5  33. Rd5 Rd7  34. Nxf5  Rxd5 35. Ne7+ Kf7 36. Nxd5 Rd8 37. Ne3 Ke6 38. Rc7 a6 39. Rh7 h5 40. Rh6 Kf7 41. f5 Rd3 42. Ke4 Ra3 43. fxg6+ Kf6 44. Nf5 Ra4+ 45. Kf3 1-0 "

; sample game 374
EventSites(374) = "Dresden ol (Men) 38th  Dresden" : GameDates(374) = "20081121" : WhitePlayers(374) = "Khenkin, Igor   G#374" : WhiteElos(374) = "2647" : BlackPlayers(374) = "Roiz, Michael   G#374" : BlackElos(374) = "2677" : Each_Game_Result(374) = "1/2-1/2"

FilePGNs(374) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. Bf4 Bg7 5. e3 c5 6. dxc5 Qa5 7. Rc1 dxc4 8. Bxc4 O-O 9. Nf3 Qxc5 10. Bb3 Nc6 11. O-O Qa5 12. h3 Bf5 13. Qe2 Ne4 14. Nxe4  Bxe4 15. Rfd1 Qh5 16. Rd7 e6  17. Bc2 Bxf3 18. Qxf3 Qxf3 19. gxf3 Ne5 20. Rxb7 Rfc8 21. e4 Nxf3+ 22. Kf1  g5 23. Be3 Bd4 24. Bd1 Bxe3 25. Rxc8+ Rxc8 26. fxe3 Nd2+ 27. Kg2 Nxe4 28. Rxa7 Rc1 29. Bh5 Rc2+ 30. Kg1 Rc1+ 1/2-1/2 "

; sample game 375
EventSites(375) = "Pamplona-A 18th  Pamplona" : GameDates(375) = "20081227" : WhitePlayers(375) = "Sasikiran, Krishnan   G#375" : WhiteElos(375) = "2694" : BlackPlayers(375) = "Vallejo Pons, Francisco   G#375" : BlackElos(375) = "2664" : Each_Game_Result(375) = "1-0"

FilePGNs(375) = "1. d4 d5 2. c4 e6 3. Nc3 c6 4. e3 Nf6 5. Nf3 Nbd7 6. Qc2 Bd6 7. Bd3 O-O 8. O-O dxc4 9. Bxc4 a6 10. Rd1 Qc7 11. Ne4 Nxe4 12. Qxe4 e5 13. Qh4  b5   14. Bb3  Bb7 15. Bc2 h6 16. b4  Qd8  17. Qg3 Qf6 18. Qg4  exd4  19. Bb2  c5 20. bxc5 Bxf3 21. gxf3 Nxc5 22. f4  Ne6 23. f5  Rac8 24. Rac1 Qg5  25. Qg2 Nd8  26. Qxg5 hxg5 27. Be4 Rxc1 28. Bxc1 Re8 29. Bf3  Kf8 30. Bb2  dxe3 31. Rxd6 e2 32. Bxe2 Rxe2 33. Bc3 Nb7  34. Rd7  a5  35. Rxb7 b4 36. Rb8+ Ke7 37. Bxg7 Rxa2 38. Rb7+  Kd6 39. Rxf7 Kc6 40. Rf8 Ra3 41. Kg2 g4 42. f6 Kd7 43. Ra8 Ke6 44. Ra7 Rf3 45. Rxa5 b3 46. Rb5 Kf7 47. h4 1-0 "

; sample game 376
EventSites(376) = "Pamplona-A 18th  Pamplona" : GameDates(376) = "20081228" : WhitePlayers(376) = "Sasikiran, Krishnan   G#376" : WhiteElos(376) = "2694" : BlackPlayers(376) = "Roiz, Michael   G#376" : BlackElos(376) = "2677" : Each_Game_Result(376) = "1-0"

FilePGNs(376) = "1. d4 Nf6 2. Nf3 d5 3. c4 e6 4. Nc3 c6 5. e3 a6 6. b3 Bb4 7. Bd2 Bd6 8. Qc2 O-O 9. g3   c5 10. Bg2 Nc6 11. O-O cxd4  12. exd4 Be7 13. Ne2 Bd7 14. Nf4 a5  15. Bc3  Qb6 16. Ne5 Rfd8 17. Rfe1  dxc4  18. Nxc4 Qa6 19. d5 exd5 20. Nxd5 Nxd5 21. Bxd5 Bf8 22. Qe4  Re8 23. Qf3 Be6 24. Bxe6 fxe6 25. Rad1 Rad8 26. Qg4 Rxd1 27. Rxd1 b5  28. Rd7 Re7 29. Nd6  h5 30. Qg6 b4 31. Rxe7 Nxe7 32. Qxe6+ Kh7 33. Bxg7 1-0 "

; sample game 377
EventSites(377) = "Russia Cup final  Serpuhov" : GameDates(377) = "20081108" : WhitePlayers(377) = "Vitiugov, Nikita   G#377" : WhiteElos(377) = "2638" : BlackPlayers(377) = "Yakovich, Yuri   G#377" : BlackElos(377) = "2567" : Each_Game_Result(377) = "1-0"

FilePGNs(377) = "1. d4 d5 2. c4 dxc4 3. Nf3 a6 4. e3 e6 5. Bxc4 c5 6. d5  Nf6 7. dxe6 Qxd1+ 8. Kxd1 Bxe6 9. Bxe6 fxe6 10. a4  b6 11. Nbd2 Bd6 12. b3 Nc6 13. Bb2 O-O-O  14. Ke2 Rd7  15. Ng5 Re8 16. Nc4 Bc7 17. Rhd1  Rxd1 18. Rxd1 Re7 19. h4 h6 20. Nf3 Rd7 21. Rxd7 Kxd7 22. Nfe5+ Nxe5 23. Nxe5+  Ke7 24. f3 g5  25. hxg5 hxg5 26. g4 Ne8  27. Nd3 Nd6 28. Be5 Bd8 29. Kd2  Nf7 30. Bb8 Kd7 31. a5 Kc6  32. axb6 Bxb6 33. Ne5+  Nxe5 34. Bxe5 Bd8 35. Kd3 Kd5 36. f4 gxf4 37. Bxf4 c4+ 38. bxc4+ Kc6 39. g5 Kd7 40. c5 e5 41. g6 Bf6 42. c6+ Kxc6 43. Bh6 1-0 "

; sample game 378
EventSites(378) = "Russia Cup final  Serpuhov" : GameDates(378) = "20081113" : WhitePlayers(378) = "Vitiugov, Nikita   G#378" : WhiteElos(378) = "2638" : BlackPlayers(378) = "Timofeev, Artyom   G#378" : BlackElos(378) = "2670" : Each_Game_Result(378) = "1-0"

FilePGNs(378) = "1. c4 c5 2. Nc3 g6 3. g3 Bg7 4. Bg2 Nc6 5. Nf3 Nf6 6. d4 cxd4 7. Nxd4 O-O 8. O-O Ng4 9. e3 d6 10. b3 Nxd4  11. exd4 Nh6 12. Bxh6  Bxh6 13. Qe2 Rb8 14. Rfd1 Be6  15. b4 Qc8 16. c5  Rd8 17. Rab1 a6 18. Bd5 Bf5 19. Rb3 Bg7  20. Qxe7 Rd7  21. Qe2 dxc5 22. bxc5 Qd8 23. g4  Qg5  24. h3 Rbd8 25. Rxb7  h5 26. Qe3 Qxe3 27. fxe3 hxg4 28. hxg4 Bxg4 29. Rxd7 Rxd7 30. Rb1 Bh6 31. Kf2 Re7 32. Ne4   Bf5 33. c6 Kg7 34. Rb7 Kf8 35. c7 1-0 "

; sample game 379
EventSites(379) = "Bundesliga 0809  Germany" : GameDates(379) = "20081214" : WhitePlayers(379) = "Chuchelov, Vladimir   G#379" : WhiteElos(379) = "2575" : BlackPlayers(379) = "Wojtaszek, Radoslaw   G#379" : BlackElos(379) = "2599" : Each_Game_Result(379) = "0-1"

FilePGNs(379) = "1. c4 Nf6 2. Nc3 e6 3. Nf3 c5 4. g3 b6 5. Bg2 Bb7 6. O-O Be7 7. d4 cxd4 8. Qxd4 d6 9. b3 Nbd7  10. Nb5 Nc5 11. Rd1 d5 12. cxd5 exd5 13. Bb2 O-O 14. Bh3  Re8 15. Rac1 Bf8 16. Rc2 Nce4 17. b4  Bc8   18. Bxc8 Rxc8 19. Rdc1 Rxc2 20. Rxc2 Qd7 21. Qd3 Rc8  22. Ne5  Qf5 23. f3 Rxc2 24. Qxc2 Nxg3 25. Qc7  Qb1+ 26. Kg2 Qf1+ 27. Kxg3 Nh5+ 28. Kh4  g5+ 29. Kxg5 h6+ 30. Kg4  Qg2+ 0-1 "

; sample game 380
EventSites(380) = "Dresden ol (Men) 38th  Dresden" : GameDates(380) = "20081114" : WhitePlayers(380) = "Grischuk, Alexander   G#380" : WhiteElos(380) = "2719" : BlackPlayers(380) = "Wojtaszek, Radoslaw   G#380" : BlackElos(380) = "2599" : Each_Game_Result(380) = "1/2-1/2"

FilePGNs(380) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. g3 dxc4 5. Bg2 c5 6. O-O Nc6 7. Qa4 Bd7 8. Qxc4 cxd4 9. Nxd4 Rc8 10. Nc3 Nxd4 11. Qxd4 Bc5 12. Qh4 O-O  13. Rd1  Qb6  14. Bg5  Bxf2+  15. Kh1 Nd5 16. Be4 f5 17. Nxd5 exd5 18. Bxd5+ Kh8 19. Rd2 Bc6 20. Qc4 h6 21. Bf4 Rfd8  22. Bxc6 Rxd2  23. Bxd2 Qxb2 24. Bc3 Rxc6 25. Qxc6 Qxa1+ 26. Bxa1 bxc6 27. Kg2 Bc5 28. Kf3 Kg8 29. e4 fxe4+ 30. Kxe4 Kf7 31. g4 Be7 32. Be5 Bf6 33. Bb8 a6 34. Kd3 Ke6 35. Kc4 Be5 36. Bxe5 Kxe5 37. Kc5 Kf4 38. a4 Kxg4 39. a5 Kh3 40. Kxc6 Kxh2 41. Kb6 g5 42. Kxa6 g4 43. Kb5 g3 44. a6 g2 45. a7 g1=Q 46. a8=Q h5 47. Qe4 Qg5+ 48. Ka6 Qf6+ 49. Ka5 h4 50. Qe2+ Kg3 51. Qe1+ Kg4 52. Qe4+ Kg5 53. Qe3+ Qf4 54. Qe7+ Kg4 55. Qe2+ Qf3 56. Qc4+ Kh5 57. Qb5+ Kh6 58. Qb6+ Kg5 59. Qd8+ Qf6 60. Qd2+ Kg6 61. Qh2 Qc3+ 62. Ka4 h3 63. Qf4  Qc2+ 64. Kb4 Qf5  65. Qh4  Qf3 66. Ka4 Kf5 67. Qh7+ Kg4 68. Qg7+ Kh4 69. Qe7+ Kg3 70. Qe1+  Kg4 71. Qe6+ Qf5 72. Qg8+ Kf3 73. Qb3+ Kf4 74. Qa2 Qe4+  75. Kb5 Qb7+ 76. Kc5 Qc7+ 77. Kb5 Qd7+  78. Ka6 Qc6+ 79. Ka7 Kg3 80. Qg8+ Kf4 81. Qf8+ Kg5 82. Qg7+ Qg6 83. Qe5+ Qf5 84. Qg7+ Kf4 85. Qd4+ Qe4 86. Qf6+ Kg4 87. Qg7+ Kf3 88. Qf6+ Qf4 89. Qc6+ Ke2 90. Qc2+ Qd2 91. Qc4+ Kf3 92. Qc6+ Kf2 93. Qf6+ Ke2 94. Qa6+ Qd3 95. Qa2+ Kf1 96. Qf7+ Kg2 97. Qg7+ Kf2 98. Qf6+ Ke2 99. Qb2+ Qd2 100. Qb5+ Qd3 101. Qb2+ Qd2 102. Qb5+ Kf2 103. Qf5+ Kg3 104. Qg6+ Kh2 105. Qg4 Qa2+ 106. Kb8 Qg2 107. Qf5 Qb2+ 108. Ka7 Qa3+ 109. Kb8 Qd6+ 110. Ka7 Qd4+ 111. Ka6 Qc4+ 112. Ka7 Kg2 113. Qg5+ Kf3 1/2-1/2 "

; sample game 381
EventSites(381) = "Corus  Wijk aan Zee" : GameDates(381) = "20090131" : WhitePlayers(381) = "Carlsen, Magnus   G#381" : WhiteElos(381) = "2776" : BlackPlayers(381) = "Smeets, Jan   G#381" : BlackElos(381) = "2601" : Each_Game_Result(381) = "1-0"

FilePGNs(381) = "1. c4 c6 2. e4 d5 3. exd5 cxd5 4. cxd5 Nf6 5. Nc3 Nxd5 6. Nf3 Nc6 7. Bb5 e6 8. O-O Be7 9. d4 O-O 10. Re1 Bd7 11. Bd3 Rc8 12. Nxd5 exd5 13. Ne5 Bf6 14. Bf4 g6  15. Qb3 Na5 16. Qb4 Be6 17. Bh6 Bg7 18. Bxg7 Kxg7 19. h4  Re8  20. h5 f6 21. Nf3  b6 22. Bb5  Re7 23. Re2 Rcc7  24. Rae1 Kf7 25. Qd2 Qf8 26. Qf4 Bf5 27. g4 Bc8 28. b4 Nb7 29. Bc6 1-0 "

; sample game 382
EventSites(382) = "Corus-B  Wijk aan Zee" : GameDates(382) = "20090130" : WhitePlayers(382) = "Caruana, Fabiano   G#382" : WhiteElos(382) = "2646" : BlackPlayers(382) = "Sasikiran, Krishnan   G#382" : BlackElos(382) = "2711" : Each_Game_Result(382) = "1-0"

FilePGNs(382) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be2 e6 7. O-O Qc7 8. f4 Be7 9. Be3 Nc6 10. Kh1 O-O 11. Qe1 Nxd4 12. Bxd4 b5 13. a3 Bb7 14. Qg3 Rad8 15. Rae1 Rd7 16. Bd3 Re8 17. Rf3  Qd8  18. Qh3 g6 19. Ref1 d5  20. f5  dxe4 21. fxg6 fxg6 22. Rxf6 Rxd4 23. Rf7 Bh4 24. Be2 Bc6 25. g3 e3+ 26. Kg1 a5 27. gxh4 b4 28. axb4 axb4 29. Nd1  Qd5 30. Nxe3 Qc5 31. Bd3 b3 32. Qg3 bxc2 33. Bxc2 Rd2 34. R7f2 Red8 35. Rxd2 Rxd2 36. Rf2 Rd4 37. Bxg6 hxg6 38. Qxg6+ Kh8 39. Qh6+ Kg8 40. Qxe6+ Kh8 41. Qh6+ Kg8 42. Qe6+ Kh8 43. Qc8+ Kg7 44. Rg2+ 1-0 "

; sample game 383
EventSites(383) = "Corus-C  Wijk aan Zee" : GameDates(383) = "20090127" : WhitePlayers(383) = "Giri, Anish   G#383" : WhiteElos(383) = "2469" : BlackPlayers(383) = "Pruijssers, Roeland   G#383" : BlackElos(383) = "2444" : Each_Game_Result(383) = "1-0"

FilePGNs(383) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. Be3 Na6 8. O-O Ng4 9. Bg5 Qe8 10. c5  exd4 11. Nd5 Qxe4 12. Ne7+ Kh8 13. cxd6 Nc5 14. Bc4 d3 15. Bd5  Qe2  16. dxc7 Ne6 17. Nxc8  Raxc8 18. Bxe6 Qxe6 19. Bd8 Ne5 20. Re1  Qd5 21. Nxe5  Bxe5 22. Qd2 Bxc7  23. Bf6+ 1-0 "

; sample game 384
EventSites(384) = "Corus-C  Wijk aan Zee" : GameDates(384) = "20090131" : WhitePlayers(384) = "Giri, Anish   G#384" : WhiteElos(384) = "2469" : BlackPlayers(384) = "Leon Hoyos, Manuel   G#384" : BlackElos(384) = "2542" : Each_Game_Result(384) = "1-0"

FilePGNs(384) = "1. d4 d6 2. Nf3 Bg4 3. g3 Bxf3 4. exf3 g6 5. c4  Nd7 6. Bg2 Bg7 7. O-O c6 8. Nc3 Nb6 9. d5  Rc8 10. Qd3 Nf6 11. Be3 cxd5 12. cxd5 Nfd7 13. Bd4 Bxd4 14. Qxd4 O-O 15. Rfe1 Nf6 16. Re2 Rc4 17. Qd3 a6 18. Rae1 Rc7 19. f4 Nc4 20. b3 Na3 21. Bh3  Rc5 22. Ne4  Nxe4 23. Rxe4 Rc7 24. f5 Nb5 25. fxg6 hxg6 26. a4  Na7 27. Qd4 b5 28. Rh4 f6 29. Qe3 g5 30. Qe4  f5 31. Qe6+ Kg7 32. Qh6+ Kf7 33. Bxf5 1-0 "

; sample game 385
EventSites(385) = "Linares 26th  Linares" : GameDates(385) = "20090302" : WhitePlayers(385) = "Carlsen, Magnus   G#385" : WhiteElos(385) = "2776" : BlackPlayers(385) = "Wang Yue   G#385" : BlackElos(385) = "2739" : Each_Game_Result(385) = "0-1"

FilePGNs(385) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. e3 a6 5. Nf3 b5 6. b3 Bg4 7. Bd2 Nbd7 8. h3 Bxf3 9. Qxf3 b4 10. Na4 e5  11. Rc1 Bd6 12. cxd5 cxd5 13. dxe5 Nxe5 14. Qd1 O-O  15. Be2 a5 16. Rc2 Qe7 17. Bc1 Rad8 18. Bb2 Ng6 19. O-O Ne4 20. Bd4 Nh4  21. Bd3 Nf5 22. Bb6 Rb8 23. Bxe4 Qxe4 24. Rd2 Rxb6  25. Nxb6 Qe5 26. Re1  Qh2+ 27. Kf1 Qh1+ 28. Ke2 Qxg2 29. Rxd5 Ng3+ 30. Kd3 Bc7  31. fxg3 Bxb6 32. Kc4 Rb8  33. Kb5 Bd4+  34. Kc4 Bf6 35. Qd3 Qxg3 36. Rd1 Qc7+ 37. Rc5 Qb7 38. Qd6  Qe4+ 39. Rd4 Qc2+ 40. Kd5 Qg2+ 41. e4 Rd8 42. Qxd8+ Bxd8 43. Rc8 g6 44. Rxd8+ Kg7 45. Rd3 Qc2 46. Kd4 a4 47. bxa4 Qxa2 48. Kc5 b3 49. Rb8 b2 50. Rdb3 Qxa4 51. Rxb2 Qxe4 52. R8b3 Kh6 53. Rc3 f5 54. Rbb3 Qe5+ 55. Kc4 Kh5 56. Kd3 Kh4 57. Kd2 f4 58. Rf3 g5 59. Rfd3 Qc5 60. Rbc3 Qf2+ 61. Kd1 Qf1+ 62. Kd2 Qg2+ 63. Kd1 Qe4 64. Kd2 h5 0-1 "

; sample game 386
EventSites(386) = "Linares 26th  Linares" : GameDates(386) = "20090303" : WhitePlayers(386) = "Grischuk, Alexander   G#386" : WhiteElos(386) = "2733" : BlackPlayers(386) = "Radjabov, Teimour   G#386" : BlackElos(386) = "2760" : Each_Game_Result(386) = "1/2-1/2"

FilePGNs(386) = "1. d4 Nf6 2. Nf3 g6 3. c4 Bg7 4. Nc3 O-O 5. e4 d6 6. Be2 e5 7. O-O Nc6 8. d5 Ne7 9. b4 Nh5 10. Re1 f5 11. Ng5 Nf6 12. f3 Kh8 13. c5 h6 14. Ne6 Bxe6 15. dxe6 d5 16. exd5 Nfxd5 17. Nxd5 Qxd5 18. Qb3 Qxb3 19. axb3 Nc6 20. Ra4 Rfe8   21. Bc4 a6  22. b5 axb5 23. Rxa8 Rxa8 24. Bxb5 Re8 25. Rd1 Rxe6 26. Rd7 Bf8 27. Rxc7 Bxc5+ 28. Kf1 Re7 29. Rxe7 Bxe7 30. Bb2 Nd4 31. Bxd4 exd4 32. g4 Kg7 33. gxf5 gxf5 34. Bd3 Kf6 35. h3 Kg5 36. Ke2 Kf4 37. Bc2 h5 38. Bd3 Bf8 39. Kf2 Kg5 40. Kf1 Bc5 41. Ke2 h4 42. Bc2 f4 43. Kd3 b5 44. Ke4 b4 1/2-1/2 "

; sample game 387
EventSites(387) = "Linares 26th  Linares" : GameDates(387) = "20090305" : WhitePlayers(387) = "Carlsen, Magnus   G#387" : WhiteElos(387) = "2776" : BlackPlayers(387) = "Grischuk, Alexander   G#387" : BlackElos(387) = "2733" : Each_Game_Result(387) = "1-0"

FilePGNs(387) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be2 e6 7. O-O Be7 8. a4 Nc6 9. Be3 O-O 10. f4 Qc7 11. Kh1 Re8 12. Bf3 Bf8 13. Qd2 Rb8 14. Qf2 e5 15. fxe5   dxe5 16. Nb3 Nb4 17. Ba7 Ra8 18. Bb6 Qe7 19. Rad1 Be6 20. Nd5 Bxd5 21. exd5 e4 22. d6 Qe6  23. Nc5 Qf5 24. Be2 Qxf2 25. Rxf2 Nbd5 26. a5 Nxb6 27. axb6 Rab8  28. Rxf6  gxf6 29. Nd7 f5 30. c4 a5 31. c5 Bg7 32. Nxb8 Rxb8 33. Ba6  Bf6 34. Bxb7 Rxb7 35. c6 Rxb6 36. Rc1 Bxb2 37. d7 1-0 "

; sample game 388
EventSites(388) = "Linares 26th  Linares" : GameDates(388) = "20090306" : WhitePlayers(388) = "Grischuk, Alexander   G#388" : WhiteElos(388) = "2733" : BlackPlayers(388) = "Anand, Viswanathan   G#388" : BlackElos(388) = "2791" : Each_Game_Result(388) = "1/2-1/2"

FilePGNs(388) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bg5 e6 7. f4 Qb6 8. Qd2 Qxb2 9. Rb1 Qa3 10. f5 Nc6 11. fxe6 fxe6 12. Nxc6 bxc6 13. e5 dxe5 14. Bxf6 gxf6 15. Ne4 Qxa2 16. Rd1 Be7 17. Be2 O-O 18. O-O Ra7 19. Rf3 Rd7 20. Bd3   f5 21. Qh6 Kh8 22. Ng5 Bc5+ 23. Kh1 Qa5 24. Rh3 Qc7 25. Nxe6 Qd6 26. Nxf8 Qxf8 27. Rf1 Rf7 28. Qh5 Qe7 29. Rhf3 f4 30. Be4 Rg7 31. Rb3 Ba7 32. Rd3  Bg4 33. Qh6 Be2 1/2-1/2 "

; sample game 389
EventSites(389) = "Corus-C  Wijk aan Zee" : GameDates(389) = "20090124" : WhitePlayers(389) = "Harika, Dronavalli   G#389" : WhiteElos(389) = "2473" : BlackPlayers(389) = "So, Wesley   G#389" : BlackElos(389) = "2627" : Each_Game_Result(389) = "1/2-1/2"

FilePGNs(389) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. e3 Bf5 5. Nc3 e6 6. Nh4 Bg6 7. Be2 Bd6 8. g3 Nbd7 9. O-O dxc4 10. Bxc4 Nb6 11. Be2 e5  12. a4 a5 13. Bf3  O-O 14. Nxg6 hxg6 15. dxe5 Bxe5 16. Qb3 Qc7 17. e4 Rfd8 18. Be3 Bd4 19. Nd5 cxd5 20. Bxd4 Nc4 21. Bxf6 gxf6 22. Rfd1 dxe4 23. Bxe4 Nd2 24. Qe3 Qd6  25. Rac1  Qe7 26. Rxd2 Rxd2 27. Qxd2 Qxe4  28. Qc2 Qb4 29. Qc3 Qxa4 30. Qxf6 Qd7 31. h4 Re8 32. h5 Qd2 33. Qc3 Qxc3 34. Rxc3 gxh5 35. Rc5 a4 36. Rxh5 Re1+ 37. Kg2 Rb1 38. Ra5 Rxb2 39. Rxa4 b5 40. Ra6 b4 41. Rb6 Rb3 42. Kh3 Rf3 43. Kg2 Rb3 44. Kh3 Rf3 45. Kg2 1/2-1/2 "

; sample game 390
EventSites(390) = "Corus  Wijk aan Zee" : GameDates(390) = "20090117" : WhitePlayers(390) = "Karjakin, Sergey   G#390" : WhiteElos(390) = "2706" : BlackPlayers(390) = "Morozevich, Alexander   G#390" : BlackElos(390) = "2771" : Each_Game_Result(390) = "1-0"

FilePGNs(390) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 Qc7 6. Be3 a6 7. Qd2 Nf6 8. O-O-O Be7 9. f3 O-O 10. g4 b5 11. g5 Ne8 12. h4 Ne5 13. Kb1  Bb7 14. h5 Rc8 15. Qg2  b4 16. Na4 f5  17. gxf6 Nxf6 18. Bd3  Rf7 19. b3 Rcf8 20. Rdg1 Ne8 21. Rh3 Bf6 22. Nb2 Nc6  23. Nxc6 Qxc6 24. Nc4 d5 25. exd5 exd5 26. h6 1-0 "

; sample game 391
EventSites(391) = "Corus  Wijk aan Zee" : GameDates(391) = "20090131" : WhitePlayers(391) = "Karjakin, Sergey   G#391" : WhiteElos(391) = "2706" : BlackPlayers(391) = "Adams, Michael   G#391" : BlackElos(391) = "2712" : Each_Game_Result(391) = "1-0"

FilePGNs(391) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Bb7 10. d4 Re8 11. Nbd2 Bf8 12. a4 Na5 13. Bc2 b4 14. cxb4  Nc6 15. Nb3 exd4  16. Bd2 d5 17. e5 Ne4 18. Nc5  Bxc5 19. bxc5 Rb8  20. b4  Ba8 21. Rb1 g6 22. b5 axb5 23. axb5 Nxe5 24. Nxe5 Rxe5 25. Bf4 Nc3  26. Qxd4 Rxe1+ 27. Rxe1 Nxb5 28. Qe5 Qf8 29. Bd3  Na7 30. Qxc7 Nc6 31. Ra1 Rb7 32. Qd6 Ra7 33. Rxa7 Nxa7 34. Qd7 Nc6 35. Bb5 1-0 "

; sample game 392
EventSites(392) = "Corus  Wijk aan Zee" : GameDates(392) = "20090118" : WhitePlayers(392) = "Movsesian, Sergei   G#392" : WhiteElos(392) = "2751" : BlackPlayers(392) = "Adams, Michael   G#392" : BlackElos(392) = "2712" : Each_Game_Result(392) = "1-0"

FilePGNs(392) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. O-O Nf6 5. d4  Bxd4 6. Nxd4 Nxd4 7. f4 d6 8. fxe5 dxe5 9. Bg5 Qe7 10. c3 Be6 11. Na3 Nc6  12. Kh1 Rd8 13. Qe2 h6 14. Bxf6 gxf6 15. Rf2 Rg8 16. Raf1 Rg6 17. Nc2  Kf8 18. Ne3 Nb8  19. Qh5 Kg7 20. Qf3 Kh7 21. Nd5 Bxd5 22. exd5 e4 23. Qf4 Rd6  24. Re2 Nd7 25. Rxe4 Ne5 26. Bb3 Kg8 27. c4 b6 28. Bc2 Qf8 29. Re3 Rg5 30. Bf5 Kh8 31. Rfe1 a5 32. b3 c6 33. dxc6 Rxc6 34. h4 Rg8 35. Rd1 a4  36. Rd8  Qg7 37. Rxg8+ Kxg8 38. Rg3 1-0 "

; sample game 393
EventSites(393) = "Corus  Wijk aan Zee" : GameDates(393) = "20090124" : WhitePlayers(393) = "Ivanchuk, Vassily   G#393" : WhiteElos(393) = "2779" : BlackPlayers(393) = "Movsesian, Sergei   G#393" : BlackElos(393) = "2751" : Each_Game_Result(393) = "0-1"

FilePGNs(393) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e6 6. f4 Nc6 7. Be3 Bd7  8. Be2 Be7 9. Ndb5 Qb8 10. O-O O-O 11. a4 Rd8 12. Kh1 Nb4 13. Bf3 e5  14. Qe2 Bc6 15. fxe5 dxe5 16. a5 b6 17. axb6 axb6 18. Rxa8 Bxa8 19. Na4 Bc6 20. c4  Nxe4 21. Nxb6 f5  22. Nc3 Qb7 23. c5 Nd3 24. Bxe4  Bxe4 25. b4 Kh8  26. Rb1 f4 27. Bg1  Bg6 28. Nc4 e4 29. Na5 Qa8 30. c6 Bxb4 31. Nb7 f3   32. gxf3 exf3 33. Qxf3 Rf8 34. Qd5 Bxc3 35. c7 Nf4 0-1 "

; sample game 394
EventSites(394) = "Corus  Wijk aan Zee" : GameDates(394) = "20090127" : WhitePlayers(394) = "Dominguez Perez, Leinier   G#394" : WhiteElos(394) = "2717" : BlackPlayers(394) = "Stellwagen, Daniel   G#394" : BlackElos(394) = "2612" : Each_Game_Result(394) = "1-0"

FilePGNs(394) = "1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Bxc3+ 6. bxc3 Ne7 7. Qg4 Qc7 8. Qxg7 Rg8 9. Qxh7 cxd4 10. Ne2 Nbc6 11. f4 Bd7 12. Qd3 dxc3 13. Rb1 O-O-O 14. Nxc3 Na5 15. h3  Kb8 16. g4 Rc8 17. Nb5 Bxb5 18. Rxb5 a6  19. Rb1 Nc4 20. Qc3 d4  21. Qxd4 Rgd8 22. Qxc4 Qa5+ 23. Qb4 Qd5 24. Be3  Qf3  25. Qxb7+ Qxb7 26. Rxb7+ Kxb7 27. Bd3 Nd5 28. Bd2 Nc3 29. Kf2 Rd4 30. Ke3 Ra4 31. Bxc3 Rxc3 32. h4 Raxa3 33. Kd4 Rc8 34. h5 Ra4+ 35. Ke3 a5 36. h6 Rb4 37. g5 a4 38. h7 Rh8 39. Ra1 Kb6 40. c3 Rb3 41. Rxa4 Rxc3 42. Kd2 Rxd3+ 43. Kxd3 Rxh7 44. Ra8 Kb7 45. Ra1 Rh3+ 46. Ke2 Rc3 47. Rh1 Kc8 48. Rh7 Rc7 49. g6  fxg6 50. Rxc7+ Kxc7 51. Kf3 1-0 "

; sample game 395
EventSites(395) = "Linares 26th  Linares" : GameDates(395) = "20090219" : WhitePlayers(395) = "Dominguez Perez, Leinier   G#395" : WhiteElos(395) = "2717" : BlackPlayers(395) = "Grischuk, Alexander   G#395" : BlackElos(395) = "2733" : Each_Game_Result(395) = "1/2-1/2"

FilePGNs(395) = "1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Bxc3+ 6. bxc3 Ne7 7. Qg4 cxd4 8. Qxg7 Rg8 9. Qxh7 Qc7 10. Ne2 Nbc6 11. f4 Bd7 12. Qd3 dxc3 13. Rb1 d4 14. Rg1 O-O-O 15. g4 Nd5 16. Nxd4 Nxd4 17. Qxd4 Kb8 18. Rg3  Bc6 19. Qc5 f6  20. exf6 Nxf6 21. Qe5 Nxg4 22. Qxc7+ Kxc7 23. f5 exf5 24. Bf4+ Kc8 25. Rxc3 Nf6 26. Rc4 Nd5 27. Rd1 Nxf4 28. Rxd8+ Kxd8 29. Rxf4 Be4 30. Bd3 1/2-1/2 "

; sample game 396
EventSites(396) = "Corus  Wijk aan Zee" : GameDates(396) = "20090123" : WhitePlayers(396) = "Radjabov, Teimour   G#396" : WhiteElos(396) = "2761" : BlackPlayers(396) = "Kamsky, Gata   G#396" : BlackElos(396) = "2725" : Each_Game_Result(396) = "1-0"

FilePGNs(396) = "1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Bf5 5. Nc5 b6 6. Nb3 e6 7. Nf3 Nf6 8. g3 Nbd7 9. Bg2 Qc7 10. O-O Rd8 11. Qe2  Bd6 12. Re1 O-O 13. Nh4 Bg4 14. Qc4 Nd5 15. Bg5 Rc8 16. a4 b5 17. Qd3  N7b6  18. Nc5  h6 19. Bd2  Nc4 20. axb5 cxb5 21. h3 Bh5 22. Bxd5  exd5 23. Bc3  Rfe8  24. b3 Ne5 25. Qxb5 Bxc5 26. Qxc5 Qd7 27. Qxa7 Qxa7 28. Rxa7 Nf3+ 29. Nxf3 Bxf3 30. Rxe8+ Rxe8 31. b4 Bd1 32. Ra2 Rc8 33. b5  Rb8 34. Rb2 f6 35. Ba5 Be2 36. b6 Rb7 37. Rb1  Kf7 38. Bd2 g5 39. Bc1   Bf3 40. Ba3 Be4 41. Bd6 1-0 "

; sample game 397
EventSites(397) = "Corus  Wijk aan Zee" : GameDates(397) = "20090130" : WhitePlayers(397) = "Wang Yue   G#397" : WhiteElos(397) = "2739" : BlackPlayers(397) = "Radjabov, Teimour   G#397" : BlackElos(397) = "2761" : Each_Game_Result(397) = "0-1"

FilePGNs(397) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. Be3 Ng4 8. Bg5 f6 9. Bh4 g5 10. Bg3 Nh6 11. d5 Nd7 12. O-O f5 13. exf5 Nxf5 14. Nd2 Nd4 15. Nde4 h6 16. Bg4 b6 17. f3 Nc5 18. Bxc8 Qxc8 19. Bf2 Qd7 20. Ng3 a5 21. Nce2 Nf5  22. Nxf5 Qxf5 23. Ng3 Qg6 24. Bxc5 bxc5 25. Qb1 Qxb1  26. Raxb1 e4  27. Nxe4 Bd4+ 28. Kh1 a4 29. h4 gxh4 30. Kh2 Rfb8 31. b3 axb3 32. axb3 Ra2 33. Rfd1 Kf7 34. Rd2 Ra3  35. Kh3 Raxb3 36. Rxb3 Rxb3 37. Kxh4 Kg6  38. Rc2 Rb1  39. Ng3  h5 40. f4  Bf6+ 41. Kh3 Rb3  42. Kh2 h4 43. Ne2 Kf5 44. Ra2 Rb4  45. Ra8 Rxc4 46. Re8 Rb4 47. Re6 Rb3  48. g4+ hxg3+ 49. Nxg3+ Kg4  50. Ne2 Rb2 51. Kg2 Be5  52. Kf2 Bxf4 53. Re7 Kf5 54. Rf7+ Ke5 55. Kf3 Bd2 56. Rxc7 Kxd5 57. Ng3 Rb3+ 58. Kg2 Bf4 59. Ne2 Be5 60. Kf2 Ke4 61. Rh7 Rf3+ 62. Ke1 d5 63. Kd2 d4 64. Rh4+ Kd5 0-1 "

; sample game 398
EventSites(398) = "Corus  Wijk aan Zee" : GameDates(398) = "20090122" : WhitePlayers(398) = "Van Wely, Loek   G#398" : WhiteElos(398) = "2625" : BlackPlayers(398) = "Radjabov, Teimour   G#398" : BlackElos(398) = "2761" : Each_Game_Result(398) = "1-0"

FilePGNs(398) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. O-O Nc6 8. d5 Ne7 9. b4 Nh5 10. Re1 f5 11. Ng5 Nf6 12. f3 Kh8 13. Rb1 h6 14. Ne6 Bxe6 15. dxe6 fxe4 16. fxe4 Nc6 17. Nd5 Ng8 18. Bd3 Nd4 19. Qg4 g5 20. h4 Nf6 21. Qg3 gxh4  22. Qxh4 Nxe6 23. Bxh6 Kg8  24. Qh3  Bxh6 25. Qxh6 c6 26. Re3  Kf7  27. Rf1  cxd5 28. exd5 Ke7 29. dxe6 Kxe6 30. Ref3 a5 31. Be4 1-0 "

; sample game 399
EventSites(399) = "Moscow op-A  Moscow" : GameDates(399) = "20090202" : WhitePlayers(399) = "Tiviakov, Sergei   G#399" : WhiteElos(399) = "2685" : BlackPlayers(399) = "Pridorozhni, Aleksei   G#399" : BlackElos(399) = "2515" : Each_Game_Result(399) = "1-0"

FilePGNs(399) = "1. e4 e5 2. Bc4 Nf6 3. d3 c6 4. Nf3 d5 5. Bb3 Bb4+ 6. c3 Bd6 7. O-O O-O 8. Re1 dxe4 9. dxe4 Na6 10. Bg5  Nc5 11. Bc2 h6 12. Bh4 a5 13. Nbd2 b5 14. Nf1 g5  15. Bg3 Qe7 16. N3d2 Be6 17. Ne3 Rad8 18. Qe2 Bc7 19. Nf5 Bxf5 20. exf5 Rfe8 21. b4 axb4 22. cxb4 Na4 23. Ne4 Rd4 24. a3 Nxe4 25. Bxe4 Nc3 26. Qf3 Nxe4 27. Rxe4 Rxe4 28. Qxe4 Qf6 29. Rc1 Rd8 30. h3 Rd5 31. Kh2 h5  32. f3 Bb6 33. h4 gxh4 34. Qxh4 Qxh4+ 35. Bxh4 c5  36. Bf2 cxb4 37. Bxb6 bxa3 38. Bc5  a2 39. Be7  Kg7  40. Rc6  f6 41. Ra6 Kf7 42. Bb4 Rd4 43. Bc3 Rf4 44. Ra7+ Kg8 45. Rxa2 Rxf5 46. Bd2 e4 47. fxe4 Re5 48. Ra6 Rxe4 49. Rxf6 Rh4+ 50. Kg3 Rd4 51. Bf4 b4 52. Rf5 h4+ 53. Kf3 Rc4 54. Rh5 Rc6 55. Rxh4 b3 56. Be5 1-0 "

; sample game 400
EventSites(400) = "Moscow op-A  Moscow" : GameDates(400) = "20090206" : WhitePlayers(400) = "Tiviakov, Sergei   G#400" : WhiteElos(400) = "2685" : BlackPlayers(400) = "Vaganian, Rafael A   G#400" : BlackElos(400) = "2596" : Each_Game_Result(400) = "1-0"

FilePGNs(400) = "1. e4 Nf6 2. e5 Nd5 3. d4 d6 4. Nf3 g6 5. Bc4 c6 6. exd6 Qxd6 7. O-O Bg7 8. h3  O-O 9. Nbd2 Nd7 10. Bb3 b6  11. Ne4 Qc7 12. Bg5 N7f6 13. Re1 Ba6  14. Qd2 Rad8 15. Nxf6+  exf6 16. Bh4  Ne7 17. Bg3 Qb7 18. c3 Nf5 19. Bf4 c5 20. Bc2 Nd6 21. dxc5 Nc4 22. Qc1 bxc5 23. b3 Nd6 24. c4 Qb6 25. Re7 f5 26. Bh6  Bf6 27. Bxf8 Rxf8 28. Re1 Bxa1 29. Qxa1 Bb7 30. Ne5 Qc7  31. f3  Rd8 32. Nd3 a5 33. Qf6  Re8 34. Re5 Qb8 35. Rxe8+ Nxe8 36. Qe7 Ng7 37. Ne5 Qe8 38. Qxe8+ Nxe8 39. Nd3 1-0 "

; sample game 401
EventSites(401) = "URS-ch48  Vilnius" : GameDates(401) = "198101??" : WhitePlayers(401) = "Vaganian, Rafael A   G#401" : WhiteElos(401) = "2590" : BlackPlayers(401) = "Psakhis, Lev   G#401" : BlackElos(401) = "2535" : Each_Game_Result(401) = "1-0"

FilePGNs(401) = "1. c4 c5 2. Nc3 b6 3. e4  Bb7 4. g3 g6 5. Bg2 Bg7 6. Nge2 Nc6 7. d3 d6 8. Be3 Nf6 9. h3 O-O 10. O-O a6 11. Qd2  e6 12. Rac1 Re8 13. d4 cxd4 14. Nxd4 Ne5 15. b3 Qc7 16. f4 Ned7 17. Ndb5  axb5 18. Nxb5 Qc6 19. Nxd6 e5  20. Rcd1  Re7 21. f5  Nc5 22. Bg5 Rf8 23. b4 Ncd7 24. a4  Ba8 25. Kh2 Qxa4  26. Ra1 Qc6 27. Ra7   Rd8 28. b5 Qc5 29. Be3  Bf8 30. fxg6 hxg6 31. Bxc5 Nxc5 32. Rxa8  Rxa8 33. Rxf6 Rd7 34. Qd5 Rad8 35. Rxg6+ Kh7 36. Rf6 Bg7 37. Rxf7 Rxd6 38. Qxe5 Rg6 39. Qh5+ Rh6 1-0 "

; sample game 402
EventSites(402) = "URS-ch48  Vilnius" : GameDates(402) = "198101??" : WhitePlayers(402) = "Psakhis, Lev   G#402" : WhiteElos(402) = "2535" : BlackPlayers(402) = "Vasiukov, Evgeni   G#402" : BlackElos(402) = "2545" : Each_Game_Result(402) = "1-0"

FilePGNs(402) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 g6 6. Be3 Bg7 7. f3 Nc6 8. Qd2 O-O 9. O-O-O d5 10. exd5 Nxd5 11. Nxc6 bxc6 12. Bd4 e5 13. Bc5 Be6 14. Ne4 Re8 15. h4 h6 16. g4 Nf4 17. Qc3 Bd5 18. h5 g5 19. Qa3 Qc7 20. Ba6   Red8 21. Rhe1 Rd7  22. Bb4  Bxe4  23. Ba5  Bxf3 24. Bxc7 Bxd1 25. Rxd1 Rxc7 26. Qf3   e4  27. Qxe4 Rb8 28. c3 Nd5 29. Bc4   Nf4 30. Qf5 Nd5  31. Bxd5 cxd5 32. Rxd5 Rc6 33. Qd3 Bf8 34. Rd8 Rxd8 35. Qxd8 a6 36. Qd5 Rd6 37. Qf5 Re6 38. a4 Bd6 39. a5 Kg7 40. b4 Be5 41. Kc2 Bf6 42. b5  axb5 43. Qxe6  1-0 "

; sample game 403
EventSites(403) = "Corus  Wijk aan Zee" : GameDates(403) = "20090131" : WhitePlayers(403) = "Carlsen, Magnus   G#403" : WhiteElos(403) = "2776" : BlackPlayers(403) = "Smeets, Jan   G#403" : BlackElos(403) = "2601" : Each_Game_Result(403) = "1-0"

FilePGNs(403) = "1. c4 c6 2. e4 d5 3. exd5 cxd5 4. cxd5 Nf6 5. Nc3 Nxd5 6. Nf3 Nc6 7. Bb5 e6 8. O-O Be7 9. d4 O-O 10. Re1 Bd7 11. Bd3 Rc8 12. Nxd5 exd5 13. Ne5 Bf6 14. Bf4 g6  15. Qb3 Na5 16. Qb4 Be6 17. Bh6 Bg7 18. Bxg7 Kxg7 19. h4  Re8  20. h5 f6 21. Nf3  b6 22. Bb5  Re7 23. Re2 Rcc7  24. Rae1 Kf7 25. Qd2 Qf8 26. Qf4 Bf5 27. g4 Bc8 28. b4 Nb7 29. Bc6 1-0 "

; sample game 404
EventSites(404) = "Istanbul FIDE GP (Women)  Istanbul" : GameDates(404) = "20090318" : WhitePlayers(404) = "Koneru, Humpy   G#404" : WhiteElos(404) = "2621" : BlackPlayers(404) = "Stefanova, Antoaneta   G#404" : BlackElos(404) = "2557" : Each_Game_Result(404) = "1-0"

FilePGNs(404) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. e3 Bf5 5. Nc3 e6 6. Nh4 Bg6 7. Qb3 Qb6 8. Nxg6 hxg6 9. Bd2 Nbd7 10. Qc2 g5  11. O-O-O  Be7 12. Kb1 O-O-O  13. cxd5 Nxd5  14. Nxd5 exd5 15. Qa4  c5 16. Ba5 Qf6 17. Bxd8 Rxd8 18. dxc5 Nxc5 19. Qxa7 Qxf2 20. Rc1 Qxe3 21. Bb5 Qe4+ 22. Ka1 Qb4 23. Rhe1  Bd6 24. Qb6 Qd4 25. Red1 Qe3 26. Rc3 Qe7 27. Rdc1 Kb8 28. Rxc5 Bxh2 29. Bd7  Qxd7 30. Ra5 1-0 "

; sample game 405
EventSites(405) = "Poikovsky Karpov 10th  Poikovsky" : GameDates(405) = "20090610" : WhitePlayers(405) = "Onischuk, Alexander   G#405" : WhiteElos(405) = "2684" : BlackPlayers(405) = "Shirov, Alexei   G#405" : BlackElos(405) = "2745" : Each_Game_Result(405) = "1-0"

FilePGNs(405) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 e6 5. e3 Nbd7 6. Qc2 Bd6 7. Bd3 O-O 8. O-O e5 9. cxd5 cxd5 10. e4 dxe4 11. Nxe4 Nxe4 12. Bxe4 h6 13. Be3 exd4 14. Bxd4 Nf6 15. Rfe1 Bg4 16. Bxb7 Rb8 17. h3 Bxh3 18. Bc6 Qc8 19. gxh3 Qxh3 20. Ne5  Rfc8 21. Qc3 Qh4 22. Rad1  Bb4 23. Qg3 Qxg3+ 24. fxg3 Bxe1 25. Rxe1 Rd8 26. Bc3 Rd6 27. b4 Rbd8 28. b5 Rd1 29. Kf2 Rxe1 30. Kxe1 h5 31. a4 g5 32. a5 Nd5 33. Bd4 f6 34. Bxa7  fxe5 35. Bc5 Nc3 36. a6 e4 37. a7 1-0 "

; sample game 406
EventSites(406) = "EU-chT (Men) 17th  Novi Sad" : GameDates(406) = "20091023" : WhitePlayers(406) = "Adams, Michael   G#406" : WhiteElos(406) = "2682" : BlackPlayers(406) = "Radjabov, Teimour   G#406" : BlackElos(406) = "2757" : Each_Game_Result(406) = "0-1"

FilePGNs(406) = "1. e4 c5 2. Nf3 Nc6 3. Bb5 e6 4. c3 d5  5. Qe2 a6 6. Bxc6+ bxc6 7. d3 Ne7 8. c4 Ng6 9. O-O Bd6 10. e5 Bc7 11. Nc3 O-O 12. Na4 f6  13. exf6 Qxf6 14. Bg5  Qf5 15. Bh4 Nf4  16. Qe3 Nxd3 17. Bg3  Bf4 18. Qe2 Rb8 19. Qc2 dxc4  20. Rad1 Bxg3 21. fxg3 Nxb2  22. Qxf5 exf5 23. Rb1 c3 24. Nxc3 Be6  25. Ne5 Rfc8 26. Rfe1 Rb4  27. Re2 Nc4  28. Rbe1 Nxe5 29. Rxe5 Bd5 30. Rxf5 Rd4  31. Rc1 c4  32. Rf2 Re8  33. Rb2 Rd3 34. Kf2 Rf8+ 35. Kg1 Re8 36. Kf2 h6 37. g4 Kh7 38. h3 Re6 39. Rcc2 Ree3 40. Ne2 Re7 41. Nc3 a5  42. Rb1 Ree3 43. Ne2 Re6 44. Rbc1 a4  45. Nc3 a3  46. Nb1 Re7  47. Nd2 Bxg2  0-1 "

; sample game 407
EventSites(407) = "EU-chT (Men) 17th  Novi Sad" : GameDates(407) = "20091023" : WhitePlayers(407) = "Wojtaszek, Radoslaw   G#407" : WhiteElos(407) = "2640" : BlackPlayers(407) = "Saric, Ivan   G#407" : BlackElos(407) = "2573" : Each_Game_Result(407) = "1-0"

FilePGNs(407) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. Be3 Na6 8. O-O Ng4 9. Bg5 Qe8 10. Re1 exd4 11. Nd5  c6 12. Ne7+ Kh8 13. Nxc8 Rxc8 14. Nxd4 Nf6 15. f3   Nc5 16. Bf1 Qe5  17. Be3  Rfe8 18. Qd2 a6  19. Rad1 b5  20. b4  Nb7 21. Nb3  Rcd8 22. Bb6 Rd7 23. Nd4 Rc8 24. Rc1  bxc4 25. Bxc4 c5 26. Bxa6 Ng4  27. fxg4 Qxd4+ 28. Qxd4 Bxd4+ 29. Kf1 Re7  30. a4  Rc6 31. a5 d5 32. e5 f6 33. e6 Nd6 34. b5 Rxb6 35. axb6 Ne4 36. Rxe4 dxe4 37. b7 Re8 38. b6 1-0 "

; sample game 408
EventSites(408) = "EU-chT (Women) 08th  Novi Sad" : GameDates(408) = "20091026" : WhitePlayers(408) = "Kosintseva, Tatiana   G#408" : WhiteElos(408) = "2536" : BlackPlayers(408) = "Rajlich, Iweta   G#408" : BlackElos(408) = "2465" : Each_Game_Result(408) = "1-0"

FilePGNs(408) = "1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. e5 Nfd7 5. f4 c5 6. Nf3 Nc6 7. Be3 Be7 8. Qd2 O-O 9. Be2 b6 10. O-O f5 11. exf6 Nxf6 12. Kh1 Bb7 13. Bd3 a6 14. a3  Qc7 15. Qe1 c4 16. Be2 Ng4 17. Bg1 Rxf4 18. h3 Nh6  19. Bh2 Raf8  20. Bxc4 dxc4 21. Qxe6+ Kh8 22. Nd5 Rxf3 23. Bxc7 Rxf1+ 24. Rxf1 Rxf1+ 25. Kh2 Rf2  26. Kg1  Rxc2 27. Nxe7 Nxe7 28. Qxe7 Ng8 29. Qf7 Rxg2+ 30. Kf1 b5 31. Be5 Be4 32. h4 Rg4 33. Kf2 h6 34. d5 Kh7 35. d6 Rg6 36. d7 h5 37. d8=Q Nh6 38. Qff8 Rg2+ 39. Kf1 1-0 "

; sample game 409
EventSites(409) = "World Cup  Khanty-Mansiysk" : GameDates(409) = "20091127" : WhitePlayers(409) = "Sakaev, Konstantin   G#409" : WhiteElos(409) = "2626" : BlackPlayers(409) = "Vitiugov, Nikita   G#409" : BlackElos(409) = "2694" : Each_Game_Result(409) = "0-1"

FilePGNs(409) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 dxc4 5. a4 e6 6. e3 c5 7. Bxc4 Nc6 8. O-O cxd4 9. exd4 Be7 10. Bg5 O-O 11. Re1 Bd7 12. Qd2 Nb4 13. Ne5 Bc6 14. Nxf7 Rxf7 15. Bxe6 Qf8  16. Re5 Kh8 17. d5 Nfxd5  18. Nxd5 Nxd5 19. Bxf7 Bxg5 20. Qxg5 Qxf7  21. f3 h6 22. Qg4 Rd8 23. Rd1 Rd6 24. Rf5 Qe7 25. Qd4 Re6 26. h3  Ne3  27. Qd8+ Kh7 0-1 "

; sample game 410
EventSites(410) = "World Cup  Khanty-Mansiysk" : GameDates(410) = "20091203" : WhitePlayers(410) = "Karjakin, Sergey   G#410" : WhiteElos(410) = "2723" : BlackPlayers(410) = "Mamedyarov, Shakhriyar   G#410" : BlackElos(410) = "2719" : Each_Game_Result(410) = "1-0"

FilePGNs(410) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Nxe4 6. d4 b5 7. Bb3 d5 8. dxe5 Be6 9. Nbd2 Nc5 10. c3 Be7 11. Bc2 d4 12. Nb3 d3 13. Bb1 Nxb3 14. axb3 Bf5 15. b4  O-O 16. Re1 Qd5  17. h3 Rfd8 18. g4  Be6 19. Re3 h5 20. Qxd3 Qxd3 21. Bxd3 hxg4 22. hxg4 Bd5 23. Bc2  Bxf3 24. Rxf3 Nxe5 25. Rh3 g6 26. g5 Re8 27. Bf4 Bf8 28. Re3 Bd6 29. Bb3 Nc4  30. Bxc4 Bxf4 31. Rf3 Bh2+  32. Kxh2 bxc4 33. Rf4 Re5 34. Rxc4 Rxg5 35. Ra5  Rxa5 36. bxa5 Ra7 37. Kg3 Kf8 38. Kf4 Ke7 39. b4 Kd7 40. Ke5 Rb7 41. Rd4+ Kc8 42. Kf6  Rb5 43. Rf4 Rd5 44. Kxf7 g5 45. Rf6 Rd3  46. c4  Rd4 47. c5 Rxb4 48. c6 Kd8  49. Rf5  Rb2  50. f4  Rf2 51. Rd5+ Kc8 52. Ke7 1-0 "

; sample game 411
EventSites(411) = "RUS-ch 62nd  Moscow" : GameDates(411) = "20091220" : WhitePlayers(411) = "Timofeev, Artyom   G#411" : WhiteElos(411) = "2651" : BlackPlayers(411) = "Jakovenko, Dmitrij   G#411" : BlackElos(411) = "2736" : Each_Game_Result(411) = "1/2-1/2"

FilePGNs(411) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 a6 5. Ne5 Nbd7 6. Bf4 dxc4 7. e3 Nxe5 8. dxe5 Qxd1+  9. Rxd1 Nd5 10. Rxd5  cxd5 11. Nxd5 Ra7  12. Nb6 Be6 13. a4 g5  14. Bxg5 Bg7 15. Bf4 O-O 16. Be2 f6 17. e4  f5  18. a5 fxe4 19. g3 Raa8  20. Nxa8 Rxa8 21. Kd2 Rc8 22. Rc1 Bf8 23. f3 exf3 24. Bxf3 Rb8  25. Rd1 b6 26. axb6 Rxb6 27. Kc1 Rb3  28. Be4 c3 29. bxc3 Rxc3+ 30. Kd2 Ra3 31. Rc1 Ra2+ 32. Rc2 Rxc2+ 33. Kxc2  Bg7 34. Kc3 a5 35. Bc6 Kf7 36. Ba4 Kg6 37. Kd4 Bh6 38. Bc2+ Kg7 39. Kc5 Bxf4 40. gxf4 Bd7 41. f5 a4 42. Kb4 h6 43. Be4 Kf8 44. Bc2 Kg7 45. Be4 Kf8 46. Bc2 Kg7 1/2-1/2 "

; sample game 412
EventSites(412) = "RUS-ch 62nd  Moscow" : GameDates(412) = "20091229" : WhitePlayers(412) = "Vitiugov, Nikita   G#412" : WhiteElos(412) = "2694" : BlackPlayers(412) = "Khismatullin, Denis   G#412" : BlackElos(412) = "2643" : Each_Game_Result(412) = "1-0"

FilePGNs(412) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. f3 O-O 6. Be3 a6 7. Qd2 Nbd7 8. Nge2 c6 9. Bh6  b5 10. h4 Bxh6 11. Qxh6 e5  12. h5 b4 13. Na4 d5  14. O-O-O Qe7 15. Qg5 dxe4 16. Ng3 exd4 17. Nf5  Qe5 18. g4 d3   19. Nb6  Qe6  20. Qh6 gxf5 21. gxf5 Qxf5 22. Rg1+ 1-0 "

; sample game 413
EventSites(413) = "WchT 7th  Bursa" : GameDates(413) = "20100109" : WhitePlayers(413) = "Tomashevsky, Evgeny   G#413" : WhiteElos(413) = "2705" : BlackPlayers(413) = "Yilmaz, Mustafa Enes   G#413" : BlackElos(413) = "2478" : Each_Game_Result(413) = "1-0"

FilePGNs(413) = "1. d4 d5 2. c4 c6 3. Nc3 dxc4 4. e4 b5 5. a4 b4 6. Na2 Nf6 7. e5 Nd5 8. Bxc4 e6 9. Nf3 Ba6 10. Bxa6 Nxa6 11. O-O c5 12. Qd3 Qb6 13. Bd2   Be7  14. Qb5+  Qxb5 15. axb5 Nac7 16. dxc5 Bxc5 17. Rfc1 Be7 18. Nxb4  Bxb4 19. Bxb4 Nxb5 20. Bc5 Kd7 21. Ng5  f6 22. exf6 gxf6 23. Ne4 f5 24. Ng5  a5 25. Re1 Ra6 26. Rad1 Nc7 27. Bd4 Rg8 28. Nxh7 Ke7 29. h4 Rg4 30. g3  Rc6 31. Ng5 Rc4 32. Be5 f4 33. Nxe6  Nxe6 34. Rxd5 fxg3 35. fxg3 a4 36. Kg2 Rg6 37. Kh3 Kf7 38. Rd7+ Kg8 39. Re7 Rc2 40. Rf1 Re2 41. Re8+ 1-0 "

; sample game 414
EventSites(414) = "EU-ch 11th  Rijeka" : GameDates(414) = "20100310" : WhitePlayers(414) = "Motylev, Alexander   G#414" : WhiteElos(414) = "2705" : BlackPlayers(414) = "Godena, Michele   G#414" : BlackElos(414) = "2561" : Each_Game_Result(414) = "1-0"

FilePGNs(414) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 g6 4. d4 exd4 5. Bg5 Be7 6. Bxe7 Qxe7 7. Bxc6 Qb4+  8. c3 Qxb2 9. Ba4 Qxa1 10. O-O b5  11. Bb3 c5 12. Nxd4  cxd4 13. Qxd4 f6 14. e5 Bb7 15. Na3 Qb2 16. exf6 Nh6 17. Qe5+ Kd8 18. Nxb5 Qd2 19. Qc7+ Ke8 20. Nd6+ 1-0 "

; sample game 415
EventSites(415) = "RUS-chT 17th  Dagomys" : GameDates(415) = "20100404" : WhitePlayers(415) = "Nepomniachtchi, Ian   G#415" : WhiteElos(415) = "2656" : BlackPlayers(415) = "Eljanov, Pavel   G#415" : BlackElos(415) = "2736" : Each_Game_Result(415) = "0-1"

FilePGNs(415) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. d4 Nd6 6. dxe5 Nxb5 7. a4 Nbd4 8. Nxd4 d5  9. Nxc6 bxc6 10. Qd3 Qd7  11. b3 a5  12. Re1 Bb4 13. c3 Be7 14. Ba3 c5 15. f4 O-O 16. Nd2 Rb8 17. Rf1 g6 18. f5  gxf5 19. Rf3 Rb6  20. Nf1  Rxb3 21. Ne3 d4 22. Nxf5 Rxc3 23. Qe4 Kh8 24. Nxe7 Qxe7 25. Rxc3 dxc3 26. Qe3 Qe6 27. Qxc3 Rg8 28. Bb2 c4  29. Rf1 Qb6+ 30. Kh1 Be6 31. h3 Qc6 32. Qd2 Rg6 33. Kh2 Kg7 34. Bc3 Qxa4  35. Rf4  Qb3  36. Rd4 Qb1 37. Qf2 a4 38. Rd7  Qc1  39. Bb2 Qg5 40. h4 Qxg2+  41. Qxg2 Rxg2+ 42. Kxg2 Bxd7 43. e6+ Kf8 44. exd7  Ke7 45. Kf3 Kxd7  46. Bf6 Ke6 47. Bc3 Kf5  48. Bb2 c6 49. Bc3 a3 50. Bb4 a2 51. Bc3 c5 52. Ba1 Ke6 53. Ke3 Kd5 54. Bc3 Kc6 55. Bf6 Kb5 56. Kd2 c3+  57. Bxc3 f5 58. Kd3 h5 59. Be5 Kb4 60. Kc2 f4 61. Kb2 f3 62. Bg3 Kc4 63. Bf2 Kd3 64. Kxa2 Ke2 65. Bxc5 f2 66. Bxf2 Kxf2 67. Kb2 Kg3 68. Kc2 Kxh4 69. Kd2 Kg3 0-1 "

; sample game 416
EventSites(416) = "RUS-chT 17th  Dagomys" : GameDates(416) = "20100407" : WhitePlayers(416) = "Ivanov, Alexander Al   G#416" : WhiteElos(416) = "2481" : BlackPlayers(416) = "Motylev, Alexander   G#416" : BlackElos(416) = "2705" : Each_Game_Result(416) = "0-1"

FilePGNs(416) = "1. e4 c5 2. Nf3 e6 3. d3 Nc6 4. g3 g6 5. Bg2 Bg7 6. O-O Nge7 7. c3 O-O 8. Re1 e5 9. Nbd2 d6 10. Nf1 h6 11. h4  f5 12. N3h2 f4 13. Bf3  Bd7 14. Bg4 Be8 15. Nf3 Kh8 16. N1h2 d5  17. Qe2  fxg3  18. fxg3 c4  19. dxc4 dxe4 20. Qxe4 Nf5  21. Kg2 Qc7  22. b3 Nce7  23. Nf1  Bc6 24. Qc2 h5 25. Bxf5 Nxf5  26. Re4 Nd6  27. N1d2 Rxf3 28. Kxf3 Qf7+ 29. Ke2 Nxe4 30. Nxe4 Qf5 0-1 "

; sample game 417
EventSites(417) = "World Championship  Sofia" : GameDates(417) = "20100424" : WhitePlayers(417) = "Topalov, Veselin   G#417" : WhiteElos(417) = "2805" : BlackPlayers(417) = "Anand, Viswanathan   G#417" : BlackElos(417) = "2787" : Each_Game_Result(417) = "1-0"

FilePGNs(417) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. e4 Nxc3 6. bxc3 Bg7 7. Bc4 c5 8. Ne2 Nc6 9. Be3 O-O 10. O-O Na5 11. Bd3 b6 12. Qd2 e5 13. Bh6 cxd4 14. Bxg7 Kxg7 15. cxd4 exd4 16. Rac1 Qd6  17. f4 f6 18. f5 Qe5 19. Nf4 g5 20. Nh5+ Kg8 21. h4 h6 22. hxg5 hxg5 23. Rf3 Kf7  24. Nxf6  Kxf6 25. Rh3 Rg8 26. Rh6+ Kf7 27. Rh7+ Ke8 28. Rcc7 Kd8 29. Bb5  Qxe4 30. Rxc8+ 1-0 "

; sample game 418
EventSites(418) = "Astrakhan FIDE GP  Astrakhan" : GameDates(418) = "20100516" : WhitePlayers(418) = "Ivanchuk, Vassily   G#418" : WhiteElos(418) = "2741" : BlackPlayers(418) = "Radjabov, Teimour   G#418" : BlackElos(418) = "2740" : Each_Game_Result(418) = "1/2-1/2"

FilePGNs(418) = "1. c4 Nf6 2. Nc3 g6 3. g3 c6 4. e4 d5 5. cxd5 cxd5 6. e5 Ne4 7. Bg2 Nc6 8. d4 Nxc3 9. bxc3 Bf5 10. Ne2 e6 11. Nf4 h5 12. h3 Bh6  13. Ne2 Bf8 14. f3 g5  15. h4 gxh4 16. Rxh4 Be7 17. Rh2 Qa5 18. Bh3 Bxh3 19. Rxh3 O-O-O 20. Qd3 Kb8 21. Kf2 Qa4  22. Be3 Rc8 23. Rah1 Qxa2 24. Rxh5 Rxh5 25. Rxh5 a5 26. Rh7 a4 27. Rxf7 a3 28. Rh7 Qb2  29. Bc1 Qb3 30. Bxa3 Bxa3 31. g4 Na5  32. Qg6 Qb2 33. Qxe6 Rxc3 34. Qxd5 Nc6 35. e6 Rc2 36. Qe4 Qxd4+ 37. Qxd4 Nxd4 38. Ke3 Nxe6 39. f4 Rc4 40. Rf7 Rc7 41. Rf6 Re7 42. Kf3 b5 43. Rg6 Bc5  44. f5 Nf8  45. Rc6 Nd7 46. Re6 b4  47. g5 b3 48. Nc3 Ne5+   49. Ke4 Nf7 50. Rxe7 Bxe7 51. g6 Nd6+ 52. Kd3 Nxf5 53. Kc4 b2 54. Kb3 Bf6 55. Kxb2 Ne7 56. Kc2 Bxc3 57. Kxc3 Nxg6 1/2-1/2 "

; sample game 419
EventSites(419) = "Astrakhan FIDE GP  Astrakhan" : GameDates(419) = "20100519" : WhitePlayers(419) = "Radjabov, Teimour   G#419" : WhiteElos(419) = "2740" : BlackPlayers(419) = "Eljanov, Pavel   G#419" : BlackElos(419) = "2751" : Each_Game_Result(419) = "0-1"

FilePGNs(419) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Bb4 5. cxd5 exd5 6. Bg5 h6 7. Bh4 c5 8. e3 c4  9. Nd2 g5 10. Bg3 Bf5 11. Be5 Bxc3 12. bxc3 Nbd7 13. Bd6 Qb6 14. Bg3 Qb2  15. Qc1 Qxc1+ 16. Rxc1 b5 17. f3 O-O 18. Kf2 Rfe8 19. a4 a6  20. Be2 Re6 21. Rhe1 Nb6 22. axb5 axb5 23. Ra1 Na4 24. Ra3 Bg6 25. Bf1 Nd7  26. h4  f5 27. hxg5 hxg5 28. f4 g4  29. Rb1 Ra5 30. Be2 Rea6 31. Bh4 Nab6 32. Rxa5 Rxa5 33. Bd8 Be8  34. Ke1 Ra8 35. Be7  Kf7 36. Bb4 Ra2 37. Bd1 Ke6 38. Rc1 Nb8  39. Rc2 Ra1 40. Rb2 Na6 41. Rb1 Ra2 42. g3 Nd7 43. Be2 Nxb4 44. Rxb4 Nf6 45. Kd1 Ra1+ 46. Rb1 Rxb1+ 47. Nxb1 Ne4 48. Bf1 Nxg3 49. Bg2 Ne4 50. Ke2 Kd6 51. Bxe4 dxe4 52. Na3 Kc6 53. Nc2 Kb6 54. Kf2 Ka5 55. Kg3 Ka4 56. d5 Bd7 0-1 "

; sample game 420
EventSites(420) = "Astrakhan FIDE GP  Astrakhan" : GameDates(420) = "20100521" : WhitePlayers(420) = "Akopian, Vladimir   G#420" : WhiteElos(420) = "2694" : BlackPlayers(420) = "Radjabov, Teimour   G#420" : BlackElos(420) = "2740" : Each_Game_Result(420) = "0-1"

FilePGNs(420) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 e5 5. Nb5 d6 6. c4 Be7 7. N1c3 a6 8. Na3 f5 9. exf5 Bxf5 10. Bd3 Be6 11. O-O Nf6 12. Nc2 Qd7 13. Bg5 O-O 14. Bxf6 gxf6 15. Ne3 f5 16. Ned5 Bd8 17. Qh5 Qg7 18. Rad1 Kh8 19. Kh1 Rc8 20. f3 Ba5 21. Ne2  e4  22. Bb1 exf3 23. gxf3 Qf7  24. Qxf7  Rxf7 25. b3 Bd7 26. Ndf4 Bb4  27. Nd5 Bc5  28. f4  Ne7  29. Ng3 Bc6  30. Kg2 Rg8 31. Rfe1 Rg4  32. h3 Rxf4 33. Rf1 Rxf1 34. Kxf1 Nxd5 35. cxd5 Bd7 36. Nh1 Rg7 37. Nf2 Rg3 38. Nd3 Be3 39. Ke2 f4 40. Ne1 Rxh3 0-1 "

; sample game 421
EventSites(421) = "USA-ch  Saint Louis" : GameDates(421) = "20100516" : WhitePlayers(421) = "Kamsky, Gata   G#421" : WhiteElos(421) = "2702" : BlackPlayers(421) = "Nakamura, Hikaru   G#421" : BlackElos(421) = "2733" : Each_Game_Result(421) = "1/2-1/2"

FilePGNs(421) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. O-O Nc6 8. d5 Ne7 9. b4 Ne8 10. a4 f5 11. a5 Nf6 12. Bg5 Nh5 13. Nd2 Nf4 14. c5 h6 15. Bxf4 exf4 16. Rc1 fxe4 17. Ndxe4 Nf5 18. Re1 Be5  19. Nd2  Nd4 20. Nf3 Nxf3+ 21. Bxf3 a6 22. Na4 Bf5 23. cxd6 Bxd6 24. Nc5 Rb8 25. Ne6 Bxe6 26. dxe6 Qe7 27. Qd3 Kg7 28. b5  axb5 29. Qxb5 Rf5 30. Qb2+ Qf6 31. Qd2  Rd8 32. h3  h5 33. Rc4 Be7 34. Qc1 c6 35. a6 bxa6 36. Rxc6 Re5 37. Rxa6 Rd6 1/2-1/2 "

; sample game 422
EventSites(422) = "USA-ch Quads  Saint Louis" : GameDates(422) = "20100523" : WhitePlayers(422) = "Nakamura, Hikaru   G#422" : WhiteElos(422) = "2733" : BlackPlayers(422) = "Shulman, Yuri   G#422" : BlackElos(422) = "2613" : Each_Game_Result(422) = "0-1"

FilePGNs(422) = "1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Bxc3+ 6. bxc3 Qa5 7. Bd2 Qa4 8. Nf3 Nc6 9. h4 cxd4 10. cxd4 Nge7 11. h5 Nxd4 12. Bd3 h6 13. Kf1  Nxf3 14. Qxf3 b6  15. Qg3 Ba6 16. Qxg7 Bxd3+ 17. cxd3 Rg8 18. Qxh6 Qd4 19. Re1 Qxd3+ 20. Kg1 Rc8 21. Bg5 Qf5 22. f4 Rc2 23. Rh2  Qd3  24. Qf6 Rxg5  25. Qxg5 Qd4+ 26. Kh1 Qe3 0-1 "

; sample game 423
EventSites(423) = "Poikovsky Karpov 11th  Poikovsky" : GameDates(423) = "20100610" : WhitePlayers(423) = "Riazantsev, Alexander   G#423" : WhiteElos(423) = "2674" : BlackPlayers(423) = "Karjakin, Sergey   G#423" : BlackElos(423) = "2739" : Each_Game_Result(423) = "0-1"

FilePGNs(423) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Ba6 5. Qc2 Bb7 6. Bg2 c5 7. d5 exd5 8. cxd5 Nxd5 9. O-O Be7 10. Qe4 Na6 11. Nh4 g6 12. Nf5   gxf5 13. Qe5 O-O 14. Qxf5 Re8 15. Nc3 Nac7 16. Be4 Bf6 17. Qxh7+ Kf8 18. Bxd5 Bxd5 19. Nxd5 Nxd5 20. e4 Nc7 21. Bh6+ Ke7 22. e5 Bxe5 23. Qe4  f6 24. f4 d5 25. Qh7+ Kd6 26. fxe5+ fxe5 27. Rf7 Ne6 28. Qg6 Kc6  29. Raf1  d4 30. R1f6 Qd5 31. Rxa7 Rad8 32. a4  c4  33. Qf7  Kc5 34. Bd2 c3 35. Rc7+  Kb4 36. bxc3+ Kb3  37. c4  Qd6 38. Rb7  d3 39. a5 Qd4+ 40. Kf1 Qe4 41. Kg1 Kc2  42. Rxb6 Kxd2 43. Rbxe6 Rxe6 44. Qxe6 Kc2 45. c5 Qd5 46. Qg4 Qd4+ 47. Rf2+ d2 48. Qf3 e4 49. Qf7 Kc3 0-1 "

; sample game 424
EventSites(424) = "Poikovsky Karpov 11th  Poikovsky" : GameDates(424) = "20100611" : WhitePlayers(424) = "Vitiugov, Nikita   G#424" : WhiteElos(424) = "2707" : BlackPlayers(424) = "Rublevsky, Sergei   G#424" : BlackElos(424) = "2704" : Each_Game_Result(424) = "1-0"

FilePGNs(424) = "1. d4 d5 2. Nf3 e6 3. c4 dxc4 4. e3 c5 5. Bxc4 a6 6. d5 b5 7. Bb3 exd5 8. Bxd5 Ra7 9. e4 Nf6 10. Nc3 Nxd5  11. Nxd5 Nc6  12. O-O Be6 13. a4 Be7  14. axb5 axb5 15. Ne5   Na5 16. b4  Bxd5 17. exd5 cxb4 18. Rxa5 Qxa5 19. Nc6 Qa4 20. Qd4 Bf6 21. Qe3+ Kd7 22. Nxa7 b3 23. Qb6 1-0 "

; sample game 425
EventSites(425) = "Bazna Kings 4th  Medias" : GameDates(425) = "20100614" : WhitePlayers(425) = "Nisipeanu, Liviu Dieter   G#425" : WhiteElos(425) = "2672" : BlackPlayers(425) = "Radjabov, Teimour   G#425" : BlackElos(425) = "2740" : Each_Game_Result(425) = "1-0"

FilePGNs(425) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5 6. Ndb5 d6 7. Bg5 a6 8. Na3 b5 9. Nd5 Be7 10. Bxf6 Bxf6 11. c4 b4 12. Nc2 O-O 13. g3 Be6  14. Bg2 a5 15. O-O Rc8 16. Qd3 g6 17. Nxf6+  Qxf6 18. b3  Qe7 19. Rad1  Rfd8 20. h4  Kh8 21. Kh2 f5  22. exf5 gxf5 23. Bxc6  Rxc6 24. f4  Rcc8 25. Qe3 Qg7 26. Rf2  Rd7  27. Nd4  Qg4 28. Rdd2 Re8 29. Nb5 d5 30. Nd6   Red8 31. Qxe5+ Qg7 32. c5 Qxe5 33. fxe5 Rc7 34. Rc2 d4 35. Rfd2 f4 36. gxf4 d3 37. Rxd3 Bf5 38. Nf7+ Kg7 39. Rg2+ 1-0 "

; sample game 426
EventSites(426) = "Bazna Kings 4th  Medias" : GameDates(426) = "20100624" : WhitePlayers(426) = "Carlsen, Magnus   G#426" : WhiteElos(426) = "2813" : BlackPlayers(426) = "Nisipeanu, Liviu Dieter   G#426" : BlackElos(426) = "2672" : Each_Game_Result(426) = "1/2-1/2"

FilePGNs(426) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 f5 4. Nc3 fxe4 5. Nxe4 d5 6. Nxe5 dxe4 7. Nxc6 Qg5 8. Qe2 Nf6 9. f4 Qxf4 10. Ne5+ c6 11. d4 Qh4+ 12. g3 Qh3 13. Bc4 Be6 14. Bg5 O-O-O 15. O-O-O Bd6 16. Rhf1 Rhe8 17. Bxf6 gxf6 18. Rxf6 Bxe5 19. Rxe6 Rxe6 20. Bxe6+ Qxe6 21. dxe5 Qh6+  22. Rd2 Rxd2 23. Qxd2 e3 24. Qe2 Qg5 25. Kd1 Kc7  26. Qd3 Qh5+ 27. Kc1 Qh6  28. Kd1 Qh5+ 29. Ke1 Qxh2  30. Qd6+ Kc8 31. Qf8+ Kc7 32. Qe7+ Kc8 1/2-1/2 "

; sample game 427
EventSites(427) = "Amsterdam NH Hotels 5th  Amsterdam" : GameDates(427) = "20100815" : WhitePlayers(427) = "Van Wely, Loek   G#427" : WhiteElos(427) = "2677" : BlackPlayers(427) = "Giri, Anish   G#427" : BlackElos(427) = "2672" : Each_Game_Result(427) = "0-1"

FilePGNs(427) = "1. c4 c6 2. Nf3 d5 3. e3 Nf6 4. Nc3 e6 5. b3 Nbd7 6. Bb2 e5  7. Qc2 a6 8. cxd5 cxd5 9. g4  h6 10. Rg1  e4 11. Nxd5 Nxd5 12. Qxe4+ Ne7 13. Rc1 Nf6  14. Bxf6 gxf6 15. Bc4 Bg7 16. h4 Qd6 17. Nd4 Kf8 18. f4  h5 19. Nf5 Bxf5 20. gxf5 Rd8 21. Ke2  b5  22. Bd3 Nd5 23. Kf3 Nxf4  24. Qxf4 Qxd3 25. Rg2 Re8  26. Rcg1 Rh7 27. Qb4+ Kg8 28. Qc5 Kh8 29. b4 Bh6 30. Rc1 Rg7 31. Rxg7 Kxg7 32. Rg1+ Kh7 33. Qa7 Qxf5+ 34. Ke2 Qe6 0-1 "

; sample game 428
EventSites(428) = "Khanty-Mansiysk ol (Men) 39th  Khanty-Mansiysk" : GameDates(428) = "20100924" : WhitePlayers(428) = "Karjakin, Sergey   G#428" : WhiteElos(428) = "2747" : BlackPlayers(428) = "Onischuk, Alexander   G#428" : BlackElos(428) = "2688" : Each_Game_Result(428) = "1-0"

FilePGNs(428) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. h3 Bb7 9. d3 d5 10. exd5 Nxd5 11. Nxe5 Nd4 12. Bd2 c5 13. Nc3 Nxb3 14. axb3 Nb4 15. Ne4 f5 16. Ng3 Qd5 17. Nf3 Qd7 18. Ne5 Qd5 19. Nf3 Qd7 20. Bxb4  cxb4 21. d4 Rac8 22. Qd3 Bd6  23. Ne5  Qc7  24. Nxf5 Bxe5 25. Rxe5 Qxc2 26. Ne7+  Kh8 27. Qg3 Rcd8 28. Rae1 Qd2 29. R1e3  Qxb2 30. Qh4 Rd6 31. Rf5 Ra8 32. Qf4 Rdd8 33. Rf7 1-0 "

; sample game 429
EventSites(429) = "Khanty-Mansiysk ol (Men) 39th  Khanty-Mansiysk" : GameDates(429) = "20100928" : WhitePlayers(429) = "Karjakin, Sergey   G#429" : WhiteElos(429) = "2747" : BlackPlayers(429) = "Tomashevsky, Evgeny   G#429" : BlackElos(429) = "2701" : Each_Game_Result(429) = "1-0"

FilePGNs(429) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Nb8 10. d4 Nbd7 11. Nbd2 Bb7 12. Bc2 Re8 13. a4 Bf8 14. Bd3 c6 15. b3 Qc7 16. Bb2 Rac8 17. axb5  cxb5  18. c4 exd4  19. cxb5  Nc5 20. Bf1 axb5 21. Bxb5 Re7 22. Nxd4 Nfxe4 23. Nxe4 Rxe4  24. b4  Qb6  25. bxc5  dxc5 26. Rxe4 Bxe4 27. Qg4 Qb7 28. Nf5 Bxf5 29. Qxf5 Qxb5 30. Bxg7  Rb8 31. Bc3 Qb6 32. Qg5+ Qg6 33. Qe5 1-0 "

; sample game 430
EventSites(430) = "Khanty-Mansiysk ol (Men) 39th  Khanty-Mansiysk" : GameDates(430) = "20100929" : WhitePlayers(430) = "L'Ami, Erwin   G#430" : WhiteElos(430) = "2485" : BlackPlayers(430) = "Sutovsky, Emil   G#430" : BlackElos(430) = "2665" : Each_Game_Result(430) = "0-1"

FilePGNs(430) = "1. Nf3 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. Qa4+ Nc6  6. Ne5 Qd6 7. Nxc6 Qxc6 8. Qxc6+ bxc6 9. g3 Bg7 10. Bg2 Be6 11. b3 O-O-O 12. Bxd5  cxd5 13. Bb2 d4 14. Na4 Bd5 15. f3 e5 16. Nc5 f5 17. Rc1 Bh6 18. Rf1 Rhe8 19. Rc2 Rd6  20. Kd1 Rc6 21. Bc1 Bf8 22. Nd3 Ra6  23. f4 e4 24. Ne5 d3  25. exd3 exd3 26. Nxd3 Be4 27. Rc3 Rxa2 28. Rf2 Bd5  29. b4 Re6 30. Ra3 Rxa3 31. Bxa3 a5  32. Nc5 axb4 33. Bxb4 Rb6 34. Ba3 Rb1+ 35. Kc2 Ra1 36. Bb4 Ra2+ 37. Kc3 Bg7+ 38. Kd3 Bc6 39. Kc4 Rc2+ 40. Kb3 Rc1 41. Bc3 Bf8 42. d4 Rb1+ 43. Rb2  Bd5+ 44. Kb4 Rc1 45. Re2 Kd8 46. Bb2  Rc4+ 47. Kb5 Bd6 48. Rd2 Kc8  49. Ba3 c6+ 50. Kb6 Rc3 51. Bb2 Bc7+ 52. Ka7 Re3 53. Na6 Ba5 0-1 "

; sample game 431
EventSites(431) = "Khanty-Mansiysk ol (Men) 39th  Khanty-Mansiysk" : GameDates(431) = "20100929" : WhitePlayers(431) = "Efimenko, Zahar   G#431" : WhiteElos(431) = "2683" : BlackPlayers(431) = "Malakhov, Vladimir   G#431" : BlackElos(431) = "2725" : Each_Game_Result(431) = "1-0"

FilePGNs(431) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. d4 Nd6 6. Bxc6 dxc6 7. dxe5 Nf5 8. Qxd8+ Kxd8 9. Nc3 Ke8 10. Ne2 Ne7 11. h3 Ng6 12. b3 h6 13. Bb2 c5 14. Rad1 Be6 15. Nc3 Be7 16. Nd5 Bd8 17. c4 a5 18. a4 c6 19. Nc3 Be7 20. Ne4 Rd8 21. Rfe1 Rxd1 22. Rxd1 Nf4 23. Ba3  b6 24. Nd6+ Kf8 25. Kf1 g5  26. Bc1 Kg7 27. Bxf4 gxf4 28. Nd2  Bxd6  29. exd6 Rd8 30. Ne4 f5  31. Nc3 Kf6 32. Ke2 Bf7 33. d7 Bh5+  34. f3 Ke6 35. Ke1  Bf7 36. Ne2 Ke5 37. Nc1  Be6 38. Nd3+ Kf6 39. Nxf4 Bxd7 40. Kf2 Ke7 41. Ng6+ Ke6 42. f4 Rb8 43. g4  Be8 44. Nh4  fxg4 45. hxg4 b5 46. Nf5 bxa4 47. bxa4 Rb4 48. Rd6+ Kf7 49. Rxh6 Rxa4 50. g5 Kg8 51. Nd6 Bf7 52. Nxf7 Kxf7 53. f5 Rxc4 54. Kf3 Rb4 55. Rh7+ Kg8 56. g6 1-0 "

; sample game 432
EventSites(432) = "Khanty-Mansiysk ol (Men) 39th  Khanty-Mansiysk" : GameDates(432) = "20100930" : WhitePlayers(432) = "Bartel, Mateusz   G#432" : WhiteElos(432) = "2599" : BlackPlayers(432) = "Adhiban, Baskaran   G#432" : BlackElos(432) = "2516" : Each_Game_Result(432) = "1-0"

FilePGNs(432) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Qc2 g6 5. Bf4 dxc4 6. Qxc4 Bg7 7. Nc3 O-O 8. e4 b5 9. Qb3 Na6  10. e5  Be6 11. exf6  Bxb3 12. fxg7 Re8  13. axb3 Nb4 14. Rc1 c5  15. dxc5 e5 16. Be3 f5  17. Bxb5 f4 18. Rd1 Qf6 19. Ne4 Qxg7 20. Rd7 Re7 21. Bc4+ Kh8 22. Rxe7 Qxe7 23. Bd2 Nc2+ 24. Kd1 Nd4 25. Nxd4 exd4 26. Re1 Rf8 27. f3 h6 28. b4 Qd7 29. b5 g5 30. c6 Qe7 31. Kc2 a6 32. bxa6 Qc7 33. Bb4 Qxc6 34. Bc5 d3+ 35. Kxd3 Rd8+ 36. Kc3 Qa4 37. Nd6 Kg7 38. Re7+ Kg6 39. Re6+ Kh7 40. Bd3+ 1-0 "

; sample game 433
EventSites(433) = "Khanty-Mansiysk ol (Men) 39th  Khanty-Mansiysk" : GameDates(433) = "20101001" : WhitePlayers(433) = "Movsesian, Sergei   G#433" : WhiteElos(433) = "2723" : BlackPlayers(433) = "Topalov, Veselin   G#433" : BlackElos(433) = "2803" : Each_Game_Result(433) = "1-0"

FilePGNs(433) = "1. e4 c5 2. Nf3 d6 3. Bb5+ Nd7 4. d4 cxd4 5. Qxd4 a6 6. Bxd7+ Bxd7 7. Bg5 Rc8 8. Nc3 h6 9. Bh4 e5  10. Qd3 g5 11. Bg3 Nf6 12. h4 g4   13. Nd2 b5 14. a3 Be6 15. O-O Be7 16. Rfd1 Qb6 17. Nf1 Rc4 18. Nd2 Rd4  19. Qe3 Qc6 20. Re1 Bd8  21. Nb3 Rc4  22. Rad1 Bb6 23. Qd3  Rxc3 24. bxc3 Ke7 25. Qd2 Rg8  26. Kh2 Rg6 27. c4  bxc4  28. Na5 Qc7 29. Nb7  Ne8 30. Rb1 a5 31. h5 Rg5 32. Bh4 f6 33. Bxg5 fxg5 34. c3   Ba7 35. Red1 Bd7 36. Qd5 g3+ 37. Kxg3 1-0 "

; sample game 434
EventSites(434) = "Khanty-Mansiysk ol (Men) 39th  Khanty-Mansiysk" : GameDates(434) = "20101001" : WhitePlayers(434) = "Sedlak, Nikola   G#434" : WhiteElos(434) = "2550" : BlackPlayers(434) = "Wojtaszek, Radoslaw   G#434" : BlackElos(434) = "2711" : Each_Game_Result(434) = "0-1"

FilePGNs(434) = "1. e4 c6 2. Nf3 d5 3. exd5 cxd5 4. Ne5 Nc6 5. d4 e6  6. c3 Bd6 7. f4 Nge7 8. Bd3 O-O 9. O-O f6 10. Qh5 Nf5 11. Nxc6 bxc6 12. Nd2 g6 13. Qe2 Qc7 14. g4  Ng7 15. Nb3 Bd7 16. Bd2 Rae8 17. Rae1 e5 18. fxe5 fxe5 19. Rxf8+ Kxf8 20. dxe5 Bxe5  21. Qf3+ Kg8 22. Rf1  Bxh2+  23. Kg2 Bc8  24. Nd4 Bd6 25. Nxc6  Qxc6 26. Qf7+ Kh8 27. Bh6 Rg8   28. Re1 Bf8 29. Rf1 d4+ 30. Kh3 Bxg4+  31. Kxg4 Qg2+ 32. Kh4 Nf5+ 0-1 "

; sample game 435
EventSites(435) = "Nanjing Pearl Spring 3rd  Nanjing" : GameDates(435) = "20101022" : WhitePlayers(435) = "Topalov, Veselin   G#435" : WhiteElos(435) = "2803" : BlackPlayers(435) = "Anand, Viswanathan   G#435" : BlackElos(435) = "2800" : Each_Game_Result(435) = "0-1"

FilePGNs(435) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Be7 5. Bg5 h6 6. Bh4 O-O 7. e3 Ne4 8. Bxe7 Qxe7 9. cxd5 Nxc3 10. bxc3 exd5 11. Qb3 Rd8 12. c4 Be6 13. c5 b6 14. Rc1 bxc5 15. Qa3 Nd7 16. Bb5 Bg4  17. Bxd7 Rxd7 18. Qxc5 Qe4 19. Rg1 Re8 20. Qb5 Rdd8 21. Qe2 Rb8 22. h3 Bxf3 23. gxf3 Qf5 24. f4 Rb1 25. Rxb1 Qxb1+ 26. Qd1 Rb8 27. Ke2 Qf5  28. Rh1 Rb2+ 29. Kf3 h5  30. a4 Qe4+ 31. Kg3 h4+ 32. Kxh4 Rxf2 33. Qg4 Rg2 0-1 "

; sample game 436
EventSites(436) = "Wch (Women)  Antakya" : GameDates(436) = "20101205" : WhitePlayers(436) = "Zuriel, Marisa   G#436" : WhiteElos(436) = "2208" : BlackPlayers(436) = "Muzychuk, Anna   G#436" : BlackElos(436) = "2530" : Each_Game_Result(436) = "0-1"

FilePGNs(436) = "1. e4 c5 2. Nf3 e6 3. c3 d5 4. exd5 exd5 5. d4 Nf6 6. Bb5+ Bd7 7. Qe2+  Be7 8. dxc5 O-O 9. O-O  Bxc5 10. Bg5 Re8 11. Qd3 Qb6 12. Bxd7  Nbxd7 13. Nbd2  Qxb2 14. Rfb1 Qa3 15. Rxb7 Bxf2+  16. Kxf2 Nc5 17. Qb5  Nxb7 18. Bxf6 Nd6 19. Qd7 gxf6  20. Qg4+ Kf8 21. Qf4 Ne4+ 22. Nxe4 dxe4 23. Qxf6 Qb2+ 24. Kg3 Qb8+ 25. Kh3 Re6 26. Qh8+ Ke7 27. Qxb8 Rxb8 28. Nd4 Rh6+ 29. Kg3 Rg8+ 30. Kf4 Rxh2 31. g4 Rc8 32. Rb1 Rxa2 33. Nf5+ Ke6 34. Rd1 Rf2+ 35. Kxe4 Rc4+ 36. Nd4+ Kf6 37. Kd3 Rc8 38. Ra1 Kg5 39. Ke3 Rf6 40. Nf3+ Kxg4 41. Rg1+ Kh5 42. Rh1+ Kg6 43. Ne5+ Kf5 44. Nd3 Rxc3 45. Rxh7 Kg6 0-1 "

; sample game 437
EventSites(437) = "Wch (Women)  Antakya" : GameDates(437) = "20101224" : WhitePlayers(437) = "Hou, Yifan   G#437" : WhiteElos(437) = "2591" : BlackPlayers(437) = "Ruan, Lufei   G#437" : BlackElos(437) = "2480" : Each_Game_Result(437) = "1-0"

FilePGNs(437) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nd4 4. Nxd4 exd4 5. O-O Bc5 6. Bc4 d6 7. c3 Ne7 8. d3  O-O 9. Bg5 Kh8 10. Nd2  f6 11. Bh4 c6 12. Qe2 d5 13. Bb3 dxc3 14. bxc3 d4 15. cxd4 Bxd4 16. Rad1 Ng6 17. Bg3 Ne5 18. h3 a5 19. a4 Qe7 20. Kh1 c5  21. f4 Nc6 22. Nf3 Be6 23. Bxe6 Qxe6 24. Rb1 Qd7 25. Rfd1 Rfc8 26. Rb5 Nb4 27. Be1 b6  28. Nxd4  Qxd4 29. Bf2 Qd6 30. e5 fxe5 31. fxe5 Qe6 32. d4 c4 33. d5 Qf5 34. d6 Nd3 35. Bxb6 Re8 36. Qg4 Qf7 37. d7 Re7 38. e6 Rxe6 39. Qxc4 Qxd7 40. Rxd3 Re1+ 41. Kh2 Qe7 42. Qc7 1-0 "

; sample game 438
EventSites(438) = "London Classic 2nd  London" : GameDates(438) = "20101208" : WhitePlayers(438) = "McShane, Luke J   G#438" : WhiteElos(438) = "2645" : BlackPlayers(438) = "Carlsen, Magnus   G#438" : BlackElos(438) = "2802" : Each_Game_Result(438) = "1-0"

FilePGNs(438) = "1. c4 c5 2. g3 g6 3. Bg2 Bg7 4. Nc3 Nc6 5. Nf3 d6 6. O-O Nh6 7. d4  cxd4 8. Bxh6 Bxh6 9. Nxd4 Ne5 10. Qb3 O-O 11. Rfd1 Nd7 12. Qa3 a5 13. b4  Ra6 14. b5 Ra8 15. e3 a4 16. Rab1 Bg7 17. Ne4 Qb6 18. Nc6  Re8 19. Nb4 f5 20. Nc3  Qc5  21. Nxa4 Qa7 22. Na6  bxa6 23. b6 Nxb6 24. Rxb6  Rb8 25. c5  Be6 26. Rdb1 dxc5 27. Rb7 Rxb7 28. Rxb7 Qa8 29. Nxc5 Qc8 30. Qxa6 Bf7 31. Bc6 Rd8 32. Nd7  Rxd7 33. Bxd7 Qc1+ 34. Qf1 Qxf1+ 35. Kxf1 Bc4+ 36. Kg1 Bxa2 37. Ba4  e5 38. f3  Bh6 39. Bb3+ 1-0 "

; sample game 439
EventSites(439) = "Reggio Emilia 53rd  Reggio Emilia" : GameDates(439) = "20101229" : WhitePlayers(439) = "Navara, David   G#439" : WhiteElos(439) = "2708" : BlackPlayers(439) = "Caruana, Fabiano   G#439" : BlackElos(439) = "2709" : Each_Game_Result(439) = "1-0"

FilePGNs(439) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5 6. Ndb5 d6 7. Bg5 a6 8. Na3 b5 9. Nd5 Be7 10. Bxf6 Bxf6 11. c3 O-O 12. Nc2 Rb8 13. Be2 Bg5 14. O-O Be6 15. Ncb4  Qc8  16. Qd3  Nxb4 17. Nxb4 a5 18. Nd5 Qd7 19. Rad1 Rfc8 20. Qg3  Qd8 21. a3 h6 22. Bg4  Rc5 23. Bxe6  fxe6 24. Ne3 Qe7 25. Rd3 Rf8  26. f3 Bh4  27. Qg6 Rf6 28. Qh5 Rf8 29. Rfd1  Rc6 30. g3 Bg5 31. Nc2  Qd7 32. h4 Bd8 33. Kg2 Qe7 34. Qg4 Bb6 35. h5  Kh8  36. Kh3  Rf7 37. Ne1 a4  38. Ng2 Bc7 39. f4   Rc4 40. Nh4 Kh7 41. fxe5 dxe5 42. Rd7 Qe8 43. Qg6+ Kg8 44. R1d3 Rc6 45. Rxf7 Qxf7 46. Qxf7+ Kxf7 47. Rd7+ Kf6 48. Ng6 Bd6 49. Kg4 Rb6 50. Nh8 Be7 51. Rd3 Bc5 52. Rf3+ Ke7 53. Rf7+ Ke8 54. Rxg7 Be3 55. Rg8+ Ke7 56. Ng6+ Kf6 57. Rf8+ Kg7 58. Rf3 Bc1 59. Rf2 Rd6 60. Rc2 Rd1 61. Nxe5 Re1 62. Nc6 Rxe4+ 63. Kf3 Re1 64. Nd4 e5 65. Nxb5 e4+ 66. Kg4 e3 67. c4 Bd2 68. c5 Rd1 69. Nd4 Ba5 70. Nf5+ 1-0 "

; sample game 440
EventSites(440) = "Reggio Emilia 53rd  Reggio Emilia" : GameDates(440) = "20110104" : WhitePlayers(440) = "Vallejo Pons, Francisco   G#440" : WhiteElos(440) = "2698" : BlackPlayers(440) = "Gashimov, Vugar   G#440" : BlackElos(440) = "2733" : Each_Game_Result(440) = "0-1"

FilePGNs(440) = "1. e4 g6 2. d4 Bg7 3. Nc3 c6 4. Nf3 d6 5. Be2 Nf6 6. O-O O-O 7. h3 Nbd7 8. Bf4  Qa5  9. Nd2 Qc7 10. a4 e5 11. Be3  Ng4  12. Bxg4 exd4 13. Bxd4 Bxd4 14. Nc4 Bc5 15. a5 Ne5 16. Nxe5 dxe5 17. Bxc8 Raxc8 18. Qe2 Bb4 19. a6 b5 20. Na2 Be7 21. Nc1 Rfd8 22. Nb3 Qb6 23. Rfd1 Kg7 24. Qg4  c5 25. Nd2 c4 26. Nf1 Bc5 27. Qg3 Rxd1 28. Rxd1 Qxa6 29. Qxe5+ Qf6 30. Qxf6+ Kxf6  31. Rd5 Ke6  32. g4 a6  33. Nd2 c3 34. bxc3 Bb6 35. c4 bxc4 36. Kf1 a5 37. Rb5 Bd8 38. Ke2 a4 39. Nb1 Ra8 40. Na3 Be7 41. Nxc4 a3 42. Rb6+ Kd7 43. Rb1 Kc6 44. c3 a2 45. Ra1 Kb5 46. Ne3  Bc5  47. Kd3 Bxe3 48. fxe3 f6  49. h4 h5 50. gxh5 gxh5 51. Kc2 Kc4 52. Kb2 Rb8+ 53. Kc2 Rg8 54. Rxa2 Rg2+ 55. Kb1 Rxa2 56. Kxa2 Kxc3 57. Kb1 Kd2 0-1 "

; sample game 441
EventSites(441) = "Tata Steel-A 73rd  Wijk aan Zee" : GameDates(441) = "20110125" : WhitePlayers(441) = "Kramnik, Vladimir   G#441" : WhiteElos(441) = "2784" : BlackPlayers(441) = "L'Ami, Erwin   G#441" : BlackElos(441) = "2628" : Each_Game_Result(441) = "1-0"

FilePGNs(441) = "1. Nf3 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. d3 Nxc3 6. bxc3 Bg7 7. Qc2 O-O 8. g3 c5 9. Bg2 Nc6 10. h4  Nb4 11. Qd2 Nd5 12. Bb2 Qa5 13. h5  Nb6  14. hxg6 hxg6 15. a4  Bd7  16. Kf1  Nxa4 17. Qg5  Qb6 18. Qh4 Rfe8 19. Bc1  e5 20. Qh7+ Kf8 21. Bh6 Bxh6 22. Qxh6+ Ke7 23. Nxe5 1-0 "

; sample game 442
EventSites(442) = "Tata Steel-A 73rd  Wijk aan Zee" : GameDates(442) = "20110126" : WhitePlayers(442) = "Carlsen, Magnus   G#442" : WhiteElos(442) = "2814" : BlackPlayers(442) = "Nepomniachtchi, Ian   G#442" : BlackElos(442) = "2733" : Each_Game_Result(442) = "0-1"

FilePGNs(442) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be2 e5 7. Nb3 Be7 8. O-O O-O 9. Kh1 Nc6 10. f4 b5 11. Be3 Bb7 12. a4 exf4  13. Rxf4 Ne5 14. Qd4 Nc6 15. Qd2 Ne5 16. Qd4 Nc6 17. Qd2 Ne5 18. axb5 axb5 19. Re1  Ng6 20. Rff1 b4 21. Nd5 Nxe4 22. Nxe7+ Qxe7 23. Qxb4 Nh4 24. Bf3 Nxf3 25. gxf3 Qd7  26. Bf4  Ra4 27. Qb6 Nf6 28. Qxd6 Qg4 29. Nd4 Rxd4 30. Qxd4 Bxf3+ 31. Rxf3 Qxf3+ 32. Kg1 Qg4+ 33. Kh1 Qc8 34. Qf2 Qb7+ 35. Kg1 Ne4 36. Qd4 Re8 37. Re2  h6  38. h3 Re6 39. Kh2 f5  40. b4  Kh7 41. Re3 Rg6 42. Re2 Qb5 43. Re1 Rc6  44. Rxe4 fxe4 45. Qxe4+ Rg6 46. Bg3 Qd7  47. h4 h5 48. c4 Qd2+ 49. Kh3 Qc3 50. Qf4 Qxb4 51. Qf5 Qxc4 52. Qxh5+ Rh6 53. Qf3 Qe6+ 54. Kh2 Rf6 55. Qd3+ Rf5 56. Qc2 Qd5 57. Bf2 Kh6 58. Be3+ Kg6 59. Bf2 Kf6 60. Bg3 Rf1 61. Bf2 Rd1 62. Qc3+ Qe5+ 63. Qxe5+ Kxe5 64. h5 Kf6 65. Bh4+ Kf5 66. Be7 Rd7 0-1 "

; sample game 443
EventSites(443) = "Tata Steel-B 73rd  Wijk aan Zee" : GameDates(443) = "20110117" : WhitePlayers(443) = "McShane, Luke J   G#443" : WhiteElos(443) = "2664" : BlackPlayers(443) = "Tkachiev, Vladislav   G#443" : BlackElos(443) = "2636" : Each_Game_Result(443) = "1-0"

FilePGNs(443) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O b5 6. Bb3 Bc5 7. c3 d6 8. d3 h6 9. Nbd2 O-O 10. Re1 Ne7  11. Nf1 Ng6 12. Ng3 Re8 13. h3 Bb7 14. Nh2 d5 15. Qf3 Nh4 16. Qe2 Ng6  17. Ng4 Nf4 18. Qf3 dxe4 19. dxe4 Nxg4 20. hxg4 Qf6 21. Nf5 Rad8 22. Bxf4 exf4 23. Qxf4 Bd6 24. Nxh6+  Qxh6 25. Bxf7+ Kh7 26. Qxh6+ Kxh6 27. Bxe8 Rxe8 28. f3 Kg5 29. Kf2 Bc5+ 30. Kg3 Kf6 31. Rad1 Bd6+ 32. Kf2 Bc5+ 33. Kg3 Bd6+ 34. Kf2 Bc5+ 35. Ke2 Bd6 36. Rh1 Bc8 37. a3  Be6 38. Kf2 Bb3 39. Rde1 Bc5+ 40. Kg3 Bc2 41. Rh5 Bd6+ 42. Kf2 g6 43. Rh7 Bc5+ 44. Kg3 Bd6+ 45. Kf2 Bc5+ 46. Kg3 Bd6+ 47. Kh3 g5 48. Rh6+ Kg7 49. Rh5 Kg6 50. g3 Rd8 51. f4  gxf4 52. e5 Bc5 53. gxf4 Rd3+ 54. Kg2 Rd2+ 55. Kf3 Rf2+ 56. Kg3 1-0 "

; sample game 444
EventSites(444) = "Tata Steel-B 73rd  Wijk aan Zee" : GameDates(444) = "20110121" : WhitePlayers(444) = "Fressinet, Laurent   G#444" : WhiteElos(444) = "2707" : BlackPlayers(444) = "So, Wesley   G#444" : BlackElos(444) = "2673" : Each_Game_Result(444) = "0-1"

FilePGNs(444) = "1. Nf3 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. Qb3  Nb6 6. d4 Bg7 7. e4 Bg4  8. Be3  Bxf3 9. gxf3 Bxd4 10. O-O-O e5 11. h4 Bxe3+ 12. fxe3 Qf6 13. h5  g5  14. f4  exf4 15. Nd5  Nxd5 16. Rxd5 Nc6  17. Rg1 h6  18. Bc4 Ne7  19. Rdd1 O-O  20. Rdf1  b5  21. Qxb5 Rab8 22. e5 Rxb5  23. exf6 Rc5 24. b3  Nf5 25. exf4 Ne3 26. Rf2 Kh7  27. Kb2  Nxc4+ 28. bxc4 Rf5  29. Kc3 Rxf6 30. f5 Re8 31. Rd1 Re5 32. Rd5 Re3+ 33. Kd4 Rh3 34. Rd7 Rxh5 35. Rxc7 g4 36. Ke4 Rg5 37. c5 g3 38. Rg2 h5 39. Rxa7 h4 40. Ra3 h3 41. Raxg3 Rxg3 42. Rxg3 h2 0-1 "

; sample game 445
EventSites(445) = "Tata Steel-B 73rd  Wijk aan Zee" : GameDates(445) = "20110123" : WhitePlayers(445) = "Spoelman, Wouter   G#445" : WhiteElos(445) = "2547" : BlackPlayers(445) = "So, Wesley   G#445" : BlackElos(445) = "2673" : Each_Game_Result(445) = "0-1"

FilePGNs(445) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 b6  5. Ne2 c5 6. a3 Ba5 7. Rb1 Na6 8. g3  Bb7 9. d5 b5 10. Bg2 bxc4 11. O-O O-O 12. e4 d6  13. Qa4  exd5 14. exd5 Bxc3  15. bxc3 Qc8 16. Nf4  Nc7  17. Bh3 Qb8 18. Qd1  Re8 19. Re1  Rxe1+ 20. Qxe1 Ncxd5 21. Nxd5 Nxd5 22. Rxb7 Qxb7 23. Bg2 Rb8 24. Qd2 Qb1 25. Bxd5 Qd3 26. Qxd3  cxd3 27. Kg2 Rb1 28. Bd2 Rb2 29. Bf4 d2 30. Bf3 d5 31. Be3 d4 32. cxd4 c4 33. d5 c3 34. d6 Rb1 0-1 "

; sample game 446
EventSites(446) = "Gibraltar Masters 9th  Caleta" : GameDates(446) = "20110126" : WhitePlayers(446) = "Kosintseva, Tatiana   G#446" : WhiteElos(446) = "2570" : BlackPlayers(446) = "Urbina Perez, Juan Antonio   G#446" : BlackElos(446) = "2189" : Each_Game_Result(446) = "1-0"

FilePGNs(446) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bg5 e6 7. f4 Be7 8. Qf3 Qc7 9. O-O-O h6 10. Bh4 Nc6  11. Nxc6 Qxc6 12. Be2 Rb8 13. Qg3  g5 14. fxg5 Nxe4 15. Nxe4 Qxe4 16. Rxd6 hxg5  17. Bxg5 Qg6 18. Rd2 Ra8  19. Qc3 Rg8  20. Bxe7 Kxe7 21. Qc5+ Ke8 22. Rhd1 Qg5 23. Qd6 1-0 "

; sample game 447
EventSites(447) = "Moscow Aeroflot op-A 10th  Moscow" : GameDates(447) = "20110210" : WhitePlayers(447) = "Lenic, Luka   G#447" : WhiteElos(447) = "2613" : BlackPlayers(447) = "Le Quang, Liem   G#447" : BlackElos(447) = "2664" : Each_Game_Result(447) = "0-1"

FilePGNs(447) = "1. Nf3 g6 2. c4 Bg7 3. e4 c5 4. d4 cxd4 5. Nxd4 Nc6 6. Be3 Nf6 7. Nc3 O-O 8. Be2 d6 9. O-O Bd7 10. Rc1 Nxd4 11. Bxd4 Bc6 12. f3 Nd7 13. Be3 a5 14. b3 Nc5 15. Qd2 Qb6 16. Nb5 Rfc8 17. Kh1 Qd8 18. Nd4 Bd7 19. Rfd1 h5 20. Bf1 Kh7 21. Ne2 Bc6 22. Nf4 Bh6 23. Qf2 Qh8 24. Rc2 Qf6 25. Nd5 Bxd5 26. Rxd5 Bxe3 27. Qxe3 Qa1 28. Kg1 Nd7 29. Qg5  Nf6  30. Rxa5 Qd4+ 31. Rf2 Rc5 32. Qxc5 dxc5 33. Rxa8 h4  34. b4 cxb4 35. Ra5 Nh5 36. Rd5 Qe3 37. Rd3 Qa7 38. Rd5 Ng3 39. c5 e6 40. Rd7 Qxc5 41. Rxf7+ Kh6 42. Rxb7 Nh1  0-1 "

; sample game 448
EventSites(448) = "Reykjavik op  Reykjavik" : GameDates(448) = "20110315" : WhitePlayers(448) = "Jones, Gawain C   G#448" : WhiteElos(448) = "2578" : BlackPlayers(448) = "Sveshnikov, Vladimir   G#448" : BlackElos(448) = "2379" : Each_Game_Result(448) = "1-0"

FilePGNs(448) = "1. e4 Nf6 2. e5 Nd5 3. d4 d6 4. c4 Nb6 5. f4 dxe5 6. fxe5 Nc6 7. Be3 Bf5 8. Nc3 e6 9. Nf3 Bg4 10. Be2 Bxf3 11. gxf3 Qh4+ 12. Bf2 Qf4 13. c5 Nd5 14. Nxd5 exd5 15. Qd2 Qf5 16. O-O-O a5  17. Qd3 Qd7 18. a3 a4 19. f4 g6 20. Rhg1 h5 21. Bf1  Bh6 22. Bh3  Bxf4+ 23. Kb1 Qe7 24. e6 O-O-O 25. exf7+ Kb8 26. Rxg6 Bxh2 27. Be6 h4 28. Rh1 Be5  29. Be3 Bf6 30. Rf1 h3 31. Rgxf6 h2 32. Bxd5 1-0 "

; sample game 449
EventSites(449) = "Reykjavik op  Reykjavik" : GameDates(449) = "20110316" : WhitePlayers(449) = "Chatalbashev, Boris   G#449" : WhiteElos(449) = "2602" : BlackPlayers(449) = "Jones, Gawain C   G#449" : BlackElos(449) = "2578" : Each_Game_Result(449) = "1/2-1/2"

FilePGNs(449) = "1. d4 e6 2. c4 f5 3. g3 Nf6 4. Bg2 Be7 5. Nf3 O-O 6. O-O d6 7. Nc3 Ne4 8. Qc2 Nxc3 9. bxc3 Nc6 10. Rd1 Qe8 11. c5  e5 12. cxd6 cxd6 13. Rb1 Kh8 14. Ba3 e4 15. Nd2 d5 16. Bxe7 Qxe7 17. e3 Be6 18. c4 Rac8 19. Qa4 Rc7 20. Rdc1 dxc4 21. Nxc4 Bd5  22. Na5 Qf7 23. Nxc6 bxc6 24. Rb2 g5 25. Qc2 Re7 26. a4  Kg7 27. a5 f4 28. a6 Qe6 29. Qc5 Rff7 30. Rcb1 Qc8 31. Qa5 Qf5 32. Qc5 Qc8 33. Bf1 h5 34. Rb8 Qf5 35. R8b7 fxg3 36. fxg3 Qf2+ 37. Kh1 Qa2  38. R7b2 Qxb2  39. Rxb2 Rxf1+ 40. Kg2 Ref7 41. Qd6 R1f6 42. Qe5 Kg6 43. Qe8 g4 44. h3 Kg7 45. hxg4 hxg4 46. Qe5 1/2-1/2 "

; sample game 450
EventSites(450) = "Agzamov Memorial 05th  Tashkent" : GameDates(450) = "20110318" : WhitePlayers(450) = "Roiz, Michael   G#450" : WhiteElos(450) = "2661" : BlackPlayers(450) = "Alikulov, Elbek   G#450" : BlackElos(450) = "2180" : Each_Game_Result(450) = "1-0"

FilePGNs(450) = "1. d4 Nf6 2. Nf3 g6 3. g3 Bg7 4. Bg2 O-O 5. O-O d6 6. Nc3 Nbd7 7. d5  Nc5 8. Nd4 e5 9. dxe6 fxe6  10. b4  Na6 11. a3 c5  12. bxc5 Nxc5 13. a4 Kh8  14. Ba3 Ng4  15. e3 Ne5 16. Ndb5 Qa5 17. Qxd6  Na6 18. Qd1 Rd8 19. Qe2 Nc6 20. Rab1 Nab8 21. Ne4 a6 22. Nbd6 Qc7 23. Rfd1 Kg8 24. Nxc8 Rxc8 25. Nc5 Qe5 26. Nxe6 1-0 "

; sample game 451
EventSites(451) = "Agzamov Memorial 05th  Tashkent" : GameDates(451) = "20110321" : WhitePlayers(451) = "Tseshkovsky, Vitaly   G#451" : WhiteElos(451) = "2493" : BlackPlayers(451) = "Roiz, Michael   G#451" : BlackElos(451) = "2661" : Each_Game_Result(451) = "0-1"

FilePGNs(451) = "1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Bf5 5. Ng3 Bg6 6. h4 h6 7. Nf3 e6 8. h5 Bh7 9. Bd3 Bxd3 10. Qxd3 Nf6 11. Bd2 Be7 12. O-O-O O-O  13. Kb1 Nbd7 14. Ne4 Nxe4 15. Qxe4 Nf6 16. Qe2 Qd5 17. Ne5 Qe4 18. Qxe4 Nxe4 19. Be1  Rfd8 20. f3 Nf6 21. Bf2 Rac8 22. g4 Kf8  23. c4 a6  24. Rhf1 Ke8 25. Be3 Bd6 26. b3 Bb8 27. Bc1  b5 28. Bb2 bxc4 29. bxc4  c5 30. dxc5 Rxd1+ 31. Rxd1 Rxc5 32. Nd3  Rxc4 33. g5 Nxh5 34. Rh1 Nf4 35. Bxg7   hxg5 36. Nf2 f5   37. Bf6 Ba7 38. Nd1 g4 39. Nb2 Rc6 40. fxg4 fxg4 41. Rh8+ Kf7 42. Be5 Be3 0-1 "

; sample game 452
EventSites(452) = "EU-ch 12th  Aix-les-Bains" : GameDates(452) = "20110324" : WhitePlayers(452) = "Inarkiev, Ernesto   G#452" : WhiteElos(452) = "2674" : BlackPlayers(452) = "Markos, Jan   G#452" : BlackElos(452) = "2546" : Each_Game_Result(452) = "1-0"

FilePGNs(452) = "1. e4 c5 2. Nf3 Nc6 3. Nc3 Nf6 4. Bb5 Qc7 5. d3 d6 6. O-O e6 7. Bxc6+  bxc6 8. Qe2 e5 9. Nh4 g6  10. f4  Bg4  11. Qf2 exf4 12. Bxf4 Be6  13. Qxc5  O-O-O 14. Qd4  Bg7 15. Bg5  Nh5 16. Qe3 f6 17. Bh6 Bxh6 18. Qxh6 Qb6+ 19. Kh1 Qxb2 20. Qd2 Qa3 21. Rab1 Kc7 22. Rb4  Rb8 23. Ra4 Qc5 24. Nf3  Rb2 25. Nd4 Re8 26. g4  Bxg4 27. Rc4 Qg5 28. Nd5+ 1-0 "

; sample game 453
EventSites(453) = "EU-ch 12th  Aix-les-Bains" : GameDates(453) = "20110325" : WhitePlayers(453) = "Ter Sahakyan, Samvel   G#453" : WhiteElos(453) = "2575" : BlackPlayers(453) = "Potkin, Vladimir   G#453" : BlackElos(453) = "2653" : Each_Game_Result(453) = "0-1"

FilePGNs(453) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 Qc7 6. Be3 a6 7. Qd2 Nf6 8. O-O-O Bb4 9. f3 Ne5 10. Nb3 b5 11. Qe1 Be7 12. f4 Ng6 13. e5 Ng4 14. Ne4 Nxe3 15. Qxe3 O-O 16. h4 Bb7 17. h5 Rac8 18. Bd3 Nxe5 19. fxe5 Qxe5 20. Nbd2 f5 21. Nf3 Qc7 22. Neg5 Bd5 23. Nh4 Qc5 24. Qd2 Bf6 25. a3 b4 26. axb4 Qd4 27. c3 Bxg5 28. Qxg5 Rxc3+ 29. Bc2 Rxc2+ 30. Kxc2 Rc8+ 31. Kb1 Be4+ 32. Ka1 Qxb4 33. Qe3 Rc5 34. Rd3 Rb5 0-1 "

; sample game 454
EventSites(454) = "EU-ch 12th  Aix-les-Bains" : GameDates(454) = "20110326" : WhitePlayers(454) = "Edouard, Romain   G#454" : WhiteElos(454) = "2600" : BlackPlayers(454) = "Zhukova, Natalia   G#454" : BlackElos(454) = "2443" : Each_Game_Result(454) = "1-0"

FilePGNs(454) = "1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Bxc3+ 6. bxc3 Ne7 7. Qg4 cxd4 8. Qxg7 Rg8 9. Qxh7 Qc7 10. Ne2 Nbc6 11. f4 dxc3 12. h4  Bd7 13. h5 O-O-O 14. Qd3 Nf5 15. Rb1  Na5  16. Rg1  Nc4 17. g4 Qc5 18. Qxc3 Nh4  19. Rg3  b6  20. Qb4   Qc7  21. Qe7  Nxe5 22. fxe5 Nf5 23. gxf5 Rxg3 24. Nxg3 Qc3+ 25. Kd1 Rg8 26. Ba6+ Kb8 27. Qd6+ Ka8 28. Qxd7 Qf3+ 29. Ne2 1-0 "

; sample game 455
EventSites(455) = "EU-ch 12th  Aix-les-Bains" : GameDates(455) = "20110327" : WhitePlayers(455) = "Jones, Gawain C   G#455" : WhiteElos(455) = "2578" : BlackPlayers(455) = "Bologan, Viktor   G#455" : BlackElos(455) = "2671" : Each_Game_Result(455) = "1-0"

FilePGNs(455) = "1. e4 c5 2. Nf3 d6 3. Bb5+ Nd7 4. d4 a6 5. Bxd7+ Bxd7 6. dxc5 dxc5 7. Nc3 e6 8. Bf4 Ne7 9. Ne5 Ng6 10. Qh5 Nxe5 11. Bxe5 h6 12. h4 Bc6 13. Rd1 Qa5 14. O-O c4 15. Nd5  exd5 16. exd5 Bd7 17. Bc3 Bb4  18. Bxg7 O-O-O 19. Bxh8 Rxh8 20. Qxf7 Rf8 21. Qg7 Qd8  22. Rd4  Bd6 23. Qxh6 Rf6 24. Qg5 b5 25. b3 Qh8 26. Re4 Rf5 27. Qe3 cxb3 28. Qb6  Qf6 29. Qxa6+ Kb8 30. Re6  Bh2+ 31. Kxh2 Qxh4+ 32. Kg1 Bxe6 33. Qb6+ Ka8 34. axb3  1-0 "

; sample game 456
EventSites(456) = "EU-ch 12th  Aix-les-Bains" : GameDates(456) = "20110328" : WhitePlayers(456) = "Pantsulaia, Levan   G#456" : WhiteElos(456) = "2595" : BlackPlayers(456) = "Polgar, Judit   G#456" : BlackElos(456) = "2686" : Each_Game_Result(456) = "0-1"

FilePGNs(456) = "1. c4 e6 2. Nf3 Nf6 3. g3 d5 4. Qc2 c5 5. d4 cxd4 6. Nxd4 e5 7. Nb3 Nc6  8. Bg2 Nb4 9. Qd1 dxc4 10. N3d2 Bf5 11. Na3 b5  12. Bxa8 Qxa8 13. Nf3 Nd3+  14. exd3 Bxd3 15. Nxb5 Bb4+ 16. Nc3 O-O 17. Rg1 Ne4 18. Bd2 Rd8 19. Rc1 Nxc3 20. bxc3 Ba3 21. Be3 Bxc1 22. Bxc1 Rb8  23. Nd2 Qd5 24. Qa4 a5 25. Qd1 h6 26. Qf3  Rb1  27. Kd1 e4 28. Qf4 Ra1 29. Qb8+  Kh7 30. g4 Qd7 31. Qe5 e3 32. fxe3 Qa4+ 33. Ke1 Rxc1+ 34. Kf2 Rxg1 0-1 "

; sample game 457
EventSites(457) = "EU-ch 12th  Aix-les-Bains" : GameDates(457) = "20110331" : WhitePlayers(457) = "Postny, Evgeny   G#457" : WhiteElos(457) = "2585" : BlackPlayers(457) = "Caruana, Fabiano   G#457" : BlackElos(457) = "2716" : Each_Game_Result(457) = "1-0"

FilePGNs(457) = "1. d4 Nf6 2. Nf3 g6 3. c4 Bg7 4. Nc3 d5 5. Bf4 dxc4 6. e3 c5 7. dxc5 Qa5 8. Bxc4 O-O 9. O-O Qxc5 10. Bb3 Nc6 11. Rc1 Qa5 12. h3 Bf5 13. Qe2 Ne4 14. g4 Nxc3 15. bxc3 Bd7 16. Rfd1 Rad8 17. Rd5 Qb6 18. Rb1 Bc8  19. Rg5  Be6 20. Rb5 Qa6 21. Bxe6 fxe6 22. Ng5  Na5 23. a4 Rc8  24. Qa2  Nc4 25. Rxb7 e5 26. Bg3 Qc6  27. Qc2 h6 28. Ne4 Kh8 29. R7b3 Rfd8  30. Ra1 a6 31. Rbb1  Rd7 32. Rd1 Rcd8 33. Rxd7 Rxd7 34. Kh2 g5  35. Qb1  Rb7 36. Qh1  Rb2 37. Rd1 Rb8 38. h4 gxh4 39. Bxh4 Qg6 40. Qf3 Rf8 41. Qg2 Rf7 42. Rd7 Nb6 43. Rd8+ Kh7 44. Nc5 Bf6 45. Bxf6 Rxf6 46. a5  Nc4 47. Nd7 1-0 "

; sample game 458
EventSites(458) = "EU-ch 12th  Aix-les-Bains" : GameDates(458) = "20110401" : WhitePlayers(458) = "Jobava, Baadur   G#458" : WhiteElos(458) = "2707" : BlackPlayers(458) = "Potkin, Vladimir   G#458" : BlackElos(458) = "2653" : Each_Game_Result(458) = "0-1"

FilePGNs(458) = "1. c4 c6 2. d4 d5 3. Nf3 Nf6 4. Qb3 e6 5. Bg5 h6 6. Bh4 dxc4 7. Qxc4 b5 8. Qc2 Bb7 9. Nc3 Nbd7 10. e4 Qb6 11. Be2 Nh5 12. d5 Nf4 13. dxe6 Nxe6 14. O-O-O Bb4 15. Kb1 Ndc5 16. Rd6 O-O 17. Nd5 cxd5 18. Rxb6 axb6 19. a3 dxe4 20. axb4 exf3 21. bxc5 fxe2 22. c6 Nd4 23. Qd3 Nxc6 24. f3 Ra4 25. Qd7 Rxh4 26. Qxb7 Rd4 0-1 "

; sample game 459
EventSites(459) = "EU-ch 12th  Aix-les-Bains" : GameDates(459) = "20110402" : WhitePlayers(459) = "Inarkiev, Ernesto   G#459" : WhiteElos(459) = "2674" : BlackPlayers(459) = "Khalifman, Alexander   G#459" : BlackElos(459) = "2638" : Each_Game_Result(459) = "1-0"

FilePGNs(459) = "1. d4 Nf6 2. c4 g6 3. g3 c5 4. d5 b5 5. cxb5 a6 6. bxa6 Bxa6 7. Bg2 d6 8. Nf3 Bg7 9. O-O Nbd7 10. Nc3 Nb6  11. Rb1 Bc4 12. Ne1 Nfd7   13. a3 O-O 14. Bd2 Nf6 15. Bc1 Nfd7 16. Bd2 Nf6 17. b3  Bxd5 18. Nxd5 Nfxd5  19. a4  e6 20. a5 Nd7 21. b4   N7f6 22. Nc2 Re8 23. Qc1 cxb4 24. Nxb4 Qd7 25. Qc6  Qxc6 26. Nxc6  Nd7 27. Rfc1 Ra6 28. Bf1 Nc3 29. Bxc3 Rxc6 30. Bxg7 Rxc1 31. Rxc1 Kxg7 32. a6 Ra8 33. Rc6  d5 34. Rc7  Nf6 35. e3 Ne8 36. Rd7 Nf6 37. Rb7 Ne4 38. a7 Kf6 39. Rc7 Nd6 40. Ba6 e5 41. Kf1 e4 42. Ke2 Ke5 43. Kd2 d4 44. exd4+ Kxd4 45. Kc2 f5 46. Kb3 Ne8 47. Rxh7 Kc5 48. h4 Kb6 49. Bc4  Nc7 50. Bf7 Rxa7 51. Bxg6 Ra5 52. Rf7 e3 53. Rf6+  Kb7 54. fxe3 Re5 55. h5 Rxe3+ 56. Kc4 Rxg3 57. h6 Rg4+ 58. Kc5 Rh4 59. h7 1-0 "

; sample game 460
EventSites(460) = "RUS-chT  Olginka" : GameDates(460) = "20110420" : WhitePlayers(460) = "Ivanchuk, Vassily   G#460" : WhiteElos(460) = "2779" : BlackPlayers(460) = "Ponomariov, Ruslan   G#460" : BlackElos(460) = "2743" : Each_Game_Result(460) = "0-1"

FilePGNs(460) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. d3 Bc5 5. O-O d6 6. c3 O-O 7. Nbd2 a6 8. Bxc6 bxc6 9. d4 exd4 10. cxd4 Bb6 11. Qc2 Re8 12. Re1 Bd7 13. b3 c5 14. d5 c6  15. dxc6 Bxc6 16. Bb2 Ba5 17. Rad1 h6 18. Re3 Re6 19. Nc4 Bc7 20. e5  Nd5 21. Ree1 Nf4 22. Qf5  Bxf3 23. gxf3 Qh4 24. Re4 dxe5 25. Rd7 Rg6+ 26. Kf1 Rg2 0-1 "

; sample game 461
EventSites(461) = "RUS-chT  Olginka" : GameDates(461) = "20110422" : WhitePlayers(461) = "Caruana, Fabiano   G#461" : WhiteElos(461) = "2716" : BlackPlayers(461) = "Areshchenko, Alexander   G#461" : BlackElos(461) = "2687" : Each_Game_Result(461) = "1-0"

FilePGNs(461) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. e4 Nxc3 6. bxc3 Bg7 7. Nf3 c5 8. Be3 Bg4 9. Rc1 Bxf3 10. gxf3 cxd4 11. cxd4 O-O 12. d5   Nd7 13. Bh3 Kh8 14. f4 f5  15. e5 g5 16. Rg1 gxf4 17. Rxg7 Kxg7 18. Bxf4 Kh8 19. Kf1  Rc8 20. Rxc8 Qxc8 21. Qd4 b6  22. e6+ Nf6 23. Bxf5 Qa6+ 24. Bd3 Qxa2 25. Be5 Qb3 26. Ke2 Qa2+ 27. Ke1 Kg8 28. Qh4 Qa5+ 29. Ke2 Qa2+ 30. Ke1 Qa5+ 31. Kd1 Qa3 32. Qg5+ Kh8 33. Qf5 Qa4+ 34. Ke2 Qh4 35. d6 exd6 36. e7 1-0 "

; sample game 462
EventSites(462) = "RUS-chT  Olginka" : GameDates(462) = "20110422" : WhitePlayers(462) = "Gelfand, Boris   G#462" : WhiteElos(462) = "2733" : BlackPlayers(462) = "Ponomariov, Ruslan   G#462" : BlackElos(462) = "2743" : Each_Game_Result(462) = "1/2-1/2"

FilePGNs(462) = "1. Nf3 Nf6 2. c4 e6 3. g3 d5 4. d4 Be7 5. Bg2 O-O 6. O-O dxc4 7. Qc2 b5  8. a4 b4 9. Nfd2 c6 10. Nxc4 Qxd4 11. Rd1 Qc5 12. Be3 Qh5 13. Nbd2 Ng4 14. Nf3 Nxe3 15. Nxe3 a5 16. Nc4 Ba6 17. Rac1 Ra7 18. Nfe5 Bxc4 19. Nxc4 Bf6 20. Qe4 Qc5 21. h4 Qe7  22. Qe3  c5 23. Qf4 Rd8 24. b3 Nd7 25. Kh2  Nf8 26. Rxd8 Qxd8 27. Qd6 Qxd6 28. Nxd6 Nd7 29. Nb5 Ra6 30. Bb7 Rb6 31. Bc8 Ne5 32. Rxc5 Rc6 33. Rxc6 1/2-1/2 "

; sample game 463
EventSites(463) = "Wch Candidates  Kazan" : GameDates(463) = "20110506" : WhitePlayers(463) = "Topalov, Veselin   G#463" : WhiteElos(463) = "2775" : BlackPlayers(463) = "Kamsky, Gata   G#463" : BlackElos(463) = "2732" : Each_Game_Result(463) = "0-1"

FilePGNs(463) = "1. Nf3 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. Qb3 Nb6 6. d4 Bg7 7. Bf4 Be6 8. Qa3 Nc6 9. O-O-O   Nd5 10. Bg3 Bh6+  11. e3 a5 12. h4  Ncb4 13. h5 c6 14. hxg6 hxg6 15. Rd2  f6 16. Ne4 b6 17. Be2 Qc8 18. Rh4 Kf7 19. Rd1 g5 20. Rh2 g4 21. Nfd2 c5 22. dxc5 f5 23. Rxh6 Rxh6 24. Ng5+ Kf8 25. Nxe6+ Qxe6 26. Bc4 Rc8 27. Bf4 Rf6 28. e4 Rxc5 29. exd5 Qxd5 30. b3 Qd4 31. Be3 Qc3+ 0-1 "

; sample game 464
EventSites(464) = "Wch Candidates  Kazan" : GameDates(464) = "20110520" : WhitePlayers(464) = "Gelfand, Boris   G#464" : WhiteElos(464) = "2733" : BlackPlayers(464) = "Grischuk, Alexander   G#464" : BlackElos(464) = "2747" : Each_Game_Result(464) = "1/2-1/2"

FilePGNs(464) = "1. Nf3 c5 2. c4 Nc6 3. Nc3 e5 4. g3 g6 5. Bg2 Bg7 6. a3 Nge7 7. b4 d5 8. cxd5 Nxd5 9. Ng5  Nc7 10. d3 cxb4 11. axb4 e4  12. Ngxe4 f5 13. Bg5 Bxc3+ 14. Kf1 Qd4 15. Nxc3  Qxc3 16. Bf4 Nb5 17. Rc1 Qf6 18. Rc5  a6 19. Bxc6+ bxc6 20. Be5 Qf8 21. Qc1 Bd7 22. Bxh8 Qxh8 23. Qe3+  Kf7 24. Re5 Qf8 25. h4 h5 26. Qf4 Qd6  27. Kg2 Kf6 28. Re4 Qxf4 29. Rxf4 Be6 30. Rc1 Ke7 31. f3 Kd6 32. Kf2 Rb8 33. e4 Nc7 34. g4  fxg4 35. Rf6 gxf3 36. Rxg6 Rxb4 37. Rh6 a5 38. Rxh5 a4 39. Rhc5 Bd7 40. Kxf3 Ne6 41. R5c4  c5 42. h5 Rb2 43. Rh1 Nd4+ 44. Ke3 Be6 45. e5+  Kxe5 46. Rxc5+ Bd5 47. Rxd5+ Kxd5 48. h6 Re2+ 49. Kf4 Ne6+ 50. Kg3 Nf8 51. h7 Nxh7 52. Rxh7 a3 53. Kf3 Re1 54. Ra7 Ra1 55. Ke3 a2 56. Ra5+ Kc6 57. Kd4 Kb6 58. Ra8 Kb7 1/2-1/2 "

; sample game 465
EventSites(465) = "Wch Candidates  Kazan" : GameDates(465) = "20110525" : WhitePlayers(465) = "Gelfand, Boris   G#465" : WhiteElos(465) = "2733" : BlackPlayers(465) = "Grischuk, Alexander   G#465" : BlackElos(465) = "2747" : Each_Game_Result(465) = "1-0"

FilePGNs(465) = "1. d4 Nf6 2. c4 g6 3. Nf3 Bg7 4. g3 d5 5. cxd5 Nxd5 6. Bg2 Nb6 7. Nc3 Nc6 8. e3 O-O 9. O-O Re8 10. Re1 a5 11. Qe2 Bg4 12. h3 Be6 13. b3  a4 14. Rb1 axb3 15. axb3 Qc8 16. Kh2 Ra5 17. Rd1 Rh5 18. Nh4  Bf6 19. f4  Rd8 20. Qf2 Bxh4  21. gxh4 Nd5 22. Nxd5 Rhxd5 23. Bb2  Rb5  24. Qe2 Rh5 25. e4 Bxb3 26. Rdc1 Na5 27. d5 b6 28. Be5 c5 29. dxc6 f6 30. Ba1 Rc5 31. Rxc5 bxc5 32. Qb5 Qc7 33. Rxb3 Nxc6 34. e5 Nd4 35. Qc4+ 1-0 "

; sample game 466
EventSites(466) = "Wch Candidates - Rapid tiebreaks  Kazan" : GameDates(466) = "20110509" : WhitePlayers(466) = "Aronian, Levon   G#466" : WhiteElos(466) = "2808" : BlackPlayers(466) = "Grischuk, Alexander   G#466" : BlackElos(466) = "2747" : Each_Game_Result(466) = "0-1"

FilePGNs(466) = "1. Nf3 c5 2. c4 Nc6 3. Nc3 e5 4. g3 g6 5. Bg2 Bg7 6. O-O Nge7 7. Ne1 d6 8. Nc2 Be6 9. Ne3 O-O 10. d3 Qd7 11. Ned5 Bh3 12. Rb1 Bxg2 13. Kxg2 Rac8 14. e4 Nxd5 15. Nxd5 Ne7 16. Nc3 Nc6 17. Be3 f5 18. f3  f4 19. Bg1 h5 20. Nd5 Rf7 21. g4 hxg4 22. fxg4 Rcf8 23. Qf3 Bf6 24. Bf2  Rh7 25. Nxf6+ Rxf6 26. Rh1 g5  27. h3 b6 28. Rh2 Nd8 29. b3 Ne6 30. Kf1 b5 31. Kg2 a5 32. Rhh1 Rf8 33. Rhc1 Rb8 34. Rh1 b4 35. Rh2 a4 36. Kh1 Ra8 37. Bg1 axb3 38. Rxb3 Ra4 39. Rbb2 Ra3 40. Rbg2 Qa4 41. h4 Rc3 42. Qf1 Qa3 43. hxg5 Rc1 44. Qf2 Rxh2+ 45. Kxh2 Nxg5 46. Kh1 Qxd3 47. Qh4 Qh3+ 0-1 "

; sample game 467
EventSites(467) = "Wch Candidates - Rapid tiebreaks  Kazan" : GameDates(467) = "20110509" : WhitePlayers(467) = "Grischuk, Alexander   G#467" : WhiteElos(467) = "2747" : BlackPlayers(467) = "Aronian, Levon   G#467" : BlackElos(467) = "2808" : Each_Game_Result(467) = "1-0"

FilePGNs(467) = "1. d4 d5 2. Nf3 Nf6 3. c4 e6 4. Nc3 Be7 5. Bf4 O-O 6. e3 Nbd7 7. c5 c6 8. h3 b6 9. b4 a5 10. a3 Ba6 11. Bxa6 Rxa6 12. O-O Qa8 13. Rb1 axb4 14. axb4 Qb7 15. Qc2 Rfa8 16. Ne1  Bd8 17. Nd3 Ra3  18. b5  bxc5 19. dxc5 Be7 20. Rfc1 g5  21. Bg3 R8a5 22. Qd1 Bf8 23. bxc6 Qxc6 24. Nb4  Qxc5 25. Ncxd5 Nxd5 26. Rxc5 Rxc5 27. Nxd5 Rxd5 28. Qc2 Rc5 29. Qb2 Rd3 30. Ra1 Bg7 31. Ra8+ Nf8 32. Qb8 Rcd5 33. Qe8 h6 34. Kh2 Rd2 35. Qe7 Rd7 36. Qe8 Kh7 37. Qb8 Rb2 38. Qc8 Kg6 39. Qc1 Rdb7 40. Rd8 Nh7 41. Qd1 R2b3  42. Qc2+ f5 43. Qc6 Nf8 44. Bd6 R3b6 45. Qe8+ Rf7 46. Bxf8 Be5+ 47. g3 f4 48. Rd7 fxg3+ 49. Kg2 1-0 "

; sample game 468
EventSites(468) = "Lublin 3rd  Lublin" : GameDates(468) = "20110517" : WhitePlayers(468) = "Wojtaszek, Radoslaw   G#468" : WhiteElos(468) = "2721" : BlackPlayers(468) = "Sasikiran, Krishnan   G#468" : BlackElos(468) = "2676" : Each_Game_Result(468) = "0-1"

FilePGNs(468) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 O-O 5. Bd3 c5 6. Nf3 d5 7. O-O Nc6 8. a3 Bxc3 9. bxc3 dxc4 10. Bxc4 Qc7 11. h3 e5 12. Ba2 Bf5 13. d5 Rad8 14. c4  e4 15. Nh4 Bc8 16. f4  b5  17. Bb2 bxc4 18. Bxf6 gxf6 19. Qh5 Ne7 20. Bxc4 Kh8  21. d6 Rxd6 22. Bxf7 f5 23. g4  c4  24. gxf5 Qc5 25. Kh2 Rd2+ 26. Kh1 Qxe3 27. Ng6+ Nxg6 28. Bxg6 Rd7 29. Qh6 Qc5  30. Rad1 Rg7 31. Rg1 Qb6  32. Qh4 e3 33. Kh2 Bb7 34. Rb1 Qd4 35. Rgd1 Qe4 36. Rb2 e2 37. Rg1 c3 38. Rb4 Qc2 39. Re1 Bf3 40. Rd4 Qd2  0-1 "

; sample game 469
EventSites(469) = "FRA-chT Top 12  Mulhouse" : GameDates(469) = "20110530" : WhitePlayers(469) = "Postny, Evgeny   G#469" : WhiteElos(469) = "2612" : BlackPlayers(469) = "Williams, Simon Kim   G#469" : BlackElos(469) = "2520" : Each_Game_Result(469) = "1-0"

FilePGNs(469) = "1. d4 Nf6 2. c4 e6 3. Nf3 c5 4. d5 exd5 5. cxd5 d6 6. Nc3 g6 7. Nd2 Bg7 8. e4 O-O 9. Be2 Re8 10. O-O Nbd7 11. Re1 Ne5 12. h3 g5 13. Nf1 h6 14. a4 Ng6 15. Ng3 a6 16. Bd2 Bd7 17. Ra3  Qc7  18. Qc2 Re7  19. Nd1  Rae8 20. f3 Nf4 21. Ne3 N6h5  22. Ngf5 Bxf5 23. Nxf5 Re5  24. Nxg7 Kxg7  25. Bc3 Ng3 26. Bf1 h5 27. Kh2 h4 28. a5 Qd8 29. Rb3 Qd7 30. Rb6 f6 31. Bxe5 Rxe5 32. Qb3 Re7 33. Bc4 Ng6 34. Qc3 Ne5 35. Bd3 Nh5 36. Rb1 Nf4 37. Bf1 f5 38. b4 c4 39. b5 fxe4 40. fxe4 g4 41. bxa6 bxa6 42. Qe3 g3+ 43. Kg1 Neg6 44. Qa3  Rf7 45. Qxd6 Qa4 46. Rb7 Rxb7 47. Rxb7+ Kh6 48. Rf7 Nxh3+ 49. gxh3 c3 50. Qc5 Qxe4 51. Qxc3 Ne5 52. Bg2 1-0 "

; sample game 470
EventSites(470) = "UKR-ch 80th  Kiev" : GameDates(470) = "20110612" : WhitePlayers(470) = "Eljanov, Pavel   G#470" : WhiteElos(470) = "2712" : BlackPlayers(470) = "Volokitin, Andrei   G#470" : BlackElos(470) = "2677" : Each_Game_Result(470) = "1-0"

FilePGNs(470) = "1. d4 Nf6 2. Nf3 g6 3. Bg5  Bg7 4. Nbd2 c5 5. e3 d5 6. c3 Qb6 7. Qb3 Nc6 8. Be2 c4 9. Qa3  h6 10. Bh4 g5 11. Bg3 Nh5 12. O-O Nxg3 13. hxg3 Bf5 14. b3 cxb3 15. axb3 O-O 16. b4 a6 17. Nb3 Rfc8 18. Nc5 a5 19. b5 Nb8 20. Nd2 Qc7 21. Rac1 Nd7 22. c4  dxc4 23. g4  Nxc5  24. gxf5 Qd8 25. Bxc4 Nd7 26. Qa2 Qe8 27. Bd5 Rxc1 28. Rxc1 Ra7 29. Nc4 b6 30. Bc6 Qb8 31. Bd5 Qe8 32. Nb2  Nf6 33. Na4 Nxd5 34. Qxd5 Qd7 35. Nxb6 Qxd5 36. Nxd5 Rd7 1-0 "

; sample game 471
EventSites(471) = "Bazna Kings 5th  Medias" : GameDates(471) = "20110613" : WhitePlayers(471) = "Nisipeanu, Liviu Dieter   G#471" : WhiteElos(471) = "2776" : BlackPlayers(471) = "Ivanchuk, Vassily   G#471" : BlackElos(471) = "2776" : Each_Game_Result(471) = "1-0"

FilePGNs(471) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. d4 Nd6 6. Bxc6 dxc6 7. dxe5 Nf5 8. Qxd8+ Kxd8 9. Nc3 Ne7 10. Ne4 Ng6 11. b3 Ke8 12. Bb2 c5 13. Nfd2  h5 14. Nc4 b6 15. f4 Ne7 16. Ne3 Nf5 17. Nd5 Bb7 18. Rfd1 Bxd5 19. Rxd5  a5  20. Re1   Rd8 21. Nf6+ Ke7 22. e6  Rxd5 23. Nxd5+ Kd6 24. exf7 Kxd5 25. Re5+ Kd6 26. Rxf5 Ke6 27. Rg5 Kxf7 28. Be5 c4  29. Bxc7 Bc5+ 30. Kf1 Rc8 31. Be5 g6 32. f5  gxf5 33. Rxh5  Rd8 34. Bc3 cxb3 35. cxb3 Kg6 36. Rh8 Rd3 37. Rh3 Be3  38. Be1  f4 39. Ke2 Rd8 40. g3 Rc8 41. gxf4 Bxf4 42. Rc3 Re8+ 43. Kd1 Rd8+ 44. Kc2 Re8 45. Bg3 Be3  46. Kd3 Bc5 47. Kc4  a4 48. Kb5 axb3 49. axb3 Re2 50. Bc7 Re6 51. b4 Be7 52. Rc4 Kf5 53. Bxb6 Bd6 54. Bc7 1-0 "

; sample game 472
EventSites(472) = "Bazna Kings 5th  Medias" : GameDates(472) = "20110618" : WhitePlayers(472) = "Carlsen, Magnus   G#472" : WhiteElos(472) = "2815" : BlackPlayers(472) = "Ivanchuk, Vassily   G#472" : BlackElos(472) = "2776" : Each_Game_Result(472) = "1-0"

FilePGNs(472) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Bb4 5. Bg5 Nbd7 6. cxd5 exd5 7. Qc2 c5 8. dxc5 h6 9. Bd2 O-O 10. e3 Bxc5 11. Rc1 Qe7 12. Be2 a6 13. Qd3 Nb6 14. O-O Bg4 15. Nd4 Bd7 16. Bf3 Rfe8 17. b3 Ba3 18. Rc2 Rac8 19. Nce2 Rxc2 20. Qxc2 Be6 21. Bc1 Rc8 22. Bxa3 Qxa3 23. Qd2 Bg4  24. Bxg4 Nxg4 25. Nf5 Nf6 26. h3 Kh7 27. Qd4 Nbd7 28. Qf4 Nf8 29. Neg3 Ng6 30. Qd4 Qc5 31. f3 Qxd4 32. Nxd4 Ne5 33. Rd1 g6 34. Kf2 Kg7 35. Nge2 Kf8 36. g4 Nc6 37. Rc1 Ke7 38. h4 Kd6 39. h5 Ne7 40. Rh1 gxh5 41. gxh5 Rg8 42. Ng3 Rg5 43. b4 Kd7 44. Rh4 Ne8 45. Rf4 Nd6 46. a4 b6 47. a5 bxa5 48. bxa5 f5  49. Rh4 Nc4  50. f4 Rg4 51. Rh3 Nd6 52. Rh1 Rg8 53. Rb1 Ra8 54. Kf3 Kc7 55. Ne6+ Kc8 56. Nc5 Rb8 57. Rxb8+ Kxb8 58. Nxa6+ Kb7 59. Nb4 Nc4 60. a6+ Kb6 61. Ke2 Nd6 62. Kd3 Nb5 63. Ne2 Ka5 64. Nc3 Nc7 65. Nbxd5  Nexd5 66. Nxd5 Nxd5 67. a7 Nc7 68. Kd4 Kb6 69. Ke5 Kxa7 70. Kxf5 Nd5 71. Kg6 Nxe3 72. Kxh6 1-0 "

; sample game 473
EventSites(473) = "Bazna Kings 5th  Medias" : GameDates(473) = "20110620" : WhitePlayers(473) = "Karjakin, Sergey   G#473" : WhiteElos(473) = "2776" : BlackPlayers(473) = "Ivanchuk, Vassily   G#473" : BlackElos(473) = "2776" : Each_Game_Result(473) = "1-0"

FilePGNs(473) = "1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. f4 Bg7 5. Nf3 O-O 6. Bd3 Na6 7. O-O c5 8. d5 Nc7 9. a4 b6 10. Qe1 e6  11. dxe6 fxe6 12. e5   Nfd5 13. Ne4 dxe5  14. fxe5  Bb7 15. Bg5 Qd7 16. Qh4 Nb4 17. Rad1 Qc6 18. Nf6+ Bxf6 19. Bxg6  hxg6 20. Bxf6 Rxf6 21. exf6 Rf8 22. Qg5 1-0 "

; sample game 474
EventSites(474) = "WchT 8th  Ningbo" : GameDates(474) = "20110723" : WhitePlayers(474) = "Seirawan, Yasser   G#474" : WhiteElos(474) = "2635" : BlackPlayers(474) = "Polgar, Judit   G#474" : BlackElos(474) = "2699" : Each_Game_Result(474) = "1-0"

FilePGNs(474) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 O-O 5. a3 Bxc3+ 6. Qxc3 d6  7. Bg5 Nbd7 8. e3 b6 9. Ne2 Ba6 10. Qc2 c5  11. dxc5 bxc5 12. Nc3 Qb6 13. O-O-O Bb7 14. e4  Rab8 15. Rd2 Rfc8 16. Be2 Ne8 17. f4 Nf8 18. Rhd1 f6 19. Bh4 Ng6 20. g3  Rd8  21. Bg4 e5 22. Be6+ Kf8 23. f5 Ne7  24. g4 h6  25. Bf2 Nc6 26. Nd5 Qa5 27. h4  Nd4 28. Bxd4 cxd4 29. g5  Bxd5  30. exd5 hxg5  31. hxg5 fxg5  32. f6  Rxb2 33. Kxb2  Nxf6 34. Ka2 Qc7 35. Rg2 Rc8 36. Bxc8 Qxc8 37. Rxg5 Nxd5 38. Qf5+ Qxf5 39. Rxf5+ Nf6 40. c5 Ke7 41. c6 Nd5 42. Rg1 d3 43. Kb3 Ke6 44. Rfg5 1-0 "

; sample game 475
EventSites(475) = "Dortmund SuperGM 39th  Dortmund" : GameDates(475) = "20110722" : WhitePlayers(475) = "Ponomariov, Ruslan   G#475" : WhiteElos(475) = "2764" : BlackPlayers(475) = "Giri, Anish   G#475" : BlackElos(475) = "2701" : Each_Game_Result(475) = "1-0"

FilePGNs(475) = "1. Nf3 d5 2. c4 c6 3. e3 Nf6 4. Nc3 e6 5. d4 Nbd7 6. Qc2 Bd6 7. Bd3 O-O 8. O-O dxc4 9. Bxc4 b5 10. Bd3 Bb7 11. Rd1 b4   12. Na4 c5 13. dxc5 Rc8 14. Qe2 Nxc5 15. Nxc5 Rxc5 16. Bd2 a5 17. e4 Qb8 18. h3 Bf4  19. a3   Bxd2 20. Nxd2 Ba8  21. Qe3 Rc7 22. a4  Bc6 23. Nb3 Qa7 24. Qxa7 Rxa7 25. f3  Rd8  26. Bb5 Rxd1+ 27. Rxd1 Bxb5 28. axb5 Kf8 29. Nc5   Ra8 30. b6 Ke7 31. b7 Rb8 32. e5 Nd5 33. Ra1 Kd8 34. Rxa5 1-0 "

; sample game 476
EventSites(476) = "Dortmund SuperGM 39th  Dortmund" : GameDates(476) = "20110724" : WhitePlayers(476) = "Nakamura, Hikaru   G#476" : WhiteElos(476) = "2770" : BlackPlayers(476) = "Kramnik, Vladimir   G#476" : BlackElos(476) = "2781" : Each_Game_Result(476) = "0-1"

FilePGNs(476) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Nf3 c5 5. g3 cxd4 6. Nxd4 O-O 7. Bg2 d5 8. Qb3 Bxc3+ 9. bxc3 Nc6 10. cxd5 Na5 11. Qc2 Nxd5 12. O-O Qc7 13. Re1 Bd7 14. e4 Nb6 15. e5 Ba4 16. Qd3 Qc4 17. Qf3 Nc6 18. Re4 Nxd4 19. Rxd4 Bc6 20. Rxc4 Bxf3 21. Rc7 Bxg2 22. Kxg2 Rab8 23. Rb1 Rfc8 24. Rxc8+ Rxc8 25. Rb3 h5 26. Be3 Nd5 27. Bd4  b6 28. f4 Rc4 29. Kf1 Ra4 30. Rb2 Kh7 31. Kf2 Kg6 32. Rc2 Ra3 33. h3 b5 34. Rb2 a6 35. Rc2 Kf5 36. Kf3 b4 37. g4+ hxg4+ 38. hxg4+ Kg6 39. Ke4 bxc3 40. Rh2 Ra4 41. Rf2 a5 42. Kd3 c2 43. f5+ Kg5 44. Bb2 Nb4+ 45. Kc3 Rxa2 46. Rf1 Kxg4 47. fxe6 fxe6 0-1 "

; sample game 477
EventSites(477) = "Dortmund SuperGM 39th  Dortmund" : GameDates(477) = "20110725" : WhitePlayers(477) = "Le Quang, Liem   G#477" : WhiteElos(477) = "2715" : BlackPlayers(477) = "Ponomariov, Ruslan   G#477" : BlackElos(477) = "2764" : Each_Game_Result(477) = "1-0"

FilePGNs(477) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Nbd7 5. cxd5 exd5 6. Bf4 c6 7. Qc2 Nh5 8. Bd2 Nhf6 9. Bf4 Nh5 10. Bg5 Be7 11. Bxe7 Qxe7 12. e3 Nb6 13. Ne5 g6 14. O-O-O Bf5 15. Qe2 Nf6 16. g4 Be6 17. f3 O-O-O 18. h4 Nfd7 19. Nd3 Rhe8 20. Bg2 f6 21. Qf2 Qd6 22. Kb1 Kb8 23. Ka1 h6 24. Rhg1 Bf7  25. g5 hxg5 26. hxg5 f5  27. e4  dxe4 28. fxe4 Ka8 29. Nc5 Nc4  30. Nb3  Qb4 31. d5 Qb6  32. Qxb6 Ndxb6 33. dxc6 Rxd1+ 34. Nxd1 fxe4 35. cxb7+ Kb8 36. Nc3 Re5  37. Bxe4 Nd6 38. Nd4  Rc5 39. Rf1 Nxe4 40. Nxe4 Rc4 41. Rd1 Bd5 42. Nd6 Rc7 43. Rf1 Bxb7 44. Rf8+ Nc8 45. b4 Rd7 46. Nc6+ Kc7 47. Nxb7 Kxb7 48. Rf6 Rd6 49. Ne5 Rd5 50. Nf3 Rd3 51. Kb2 Nb6 52. Ne5 Rd5 53. Nf7 a5  54. bxa5 Rb5+ 55. Ka1 Rxa5 56. Rxg6 Rc5 57. Kb2 Rb5+ 58. Kc3 Ra5 59. Nd6+ Kc7 60. Kb3 Rd5 61. Ne8+ Kb7 62. Rg7+ Kc6 63. Rc7+ Kb5 64. g6 Rg5 65. Nd6+ Ka6 66. g7 Rg3+ 67. Kc2 Nd5 68. Rf7 Rg2+ 69. Kb3 Ne3 70. Ne8 Rg3 71. Rf3 1-0 "

; sample game 478
EventSites(478) = "Dortmund SuperGM 39th  Dortmund" : GameDates(478) = "20110731" : WhitePlayers(478) = "Kramnik, Vladimir   G#478" : WhiteElos(478) = "2781" : BlackPlayers(478) = "Nakamura, Hikaru   G#478" : BlackElos(478) = "2770" : Each_Game_Result(478) = "0-1"

FilePGNs(478) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. O-O Nc6 8. d5 Ne7 9. b4 Nh5 10. c5 Nf4 11. a4 f5 12. Bc4 fxe4 13. Nxe4 h6 14. Re1 Bg4 15. Ra3 g5 16. h3 Bh5 17. Bxf4 Rxf4 18. g3 Rf8 19. a5 Kh8 20. Kg2 Rb8 21. Qd2 b6 22. axb6 axb6  23. Nfxg5  hxg5 24. Qxg5 Bg6 25. cxd6 cxd6 26. Ra7 Rc8 27. Rxe7 Rxc4 28. f3 Rc2+ 29. Kg1 Rc8 30. Ra1 Rf7 31. Qxg6 Qxe7 32. Ng5  Kg8 33. Qh7+ Kf8 34. Ne6+ Ke8 35. Qh5 Bf6 36. g4  Qb7 37. Rd1 Qa6 38. Qg6 Ke7 39. g5 Bh8 40. Re1 Qa3 41. Nd4 Qxb4 42. Nf5+ Kf8 43. Rd1 Rc2 44. Nd4 exd4 45. Qxc2 Qc3 46. Qe4 Qe3+ 47. Qxe3 dxe3 48. Kg2 Bc3 49. Kf1 Rxf3+ 50. Ke2 Rxh3 0-1 "

; sample game 479
EventSites(479) = "GBR-ch 98th  Sheffield" : GameDates(479) = "20110804" : WhitePlayers(479) = "Short, Nigel D   G#479" : WhiteElos(479) = "2687" : BlackPlayers(479) = "Wells, Peter K   G#479" : BlackElos(479) = "2489" : Each_Game_Result(479) = "1-0"

FilePGNs(479) = "1. b3 d5 2. Bb2 c5 3. e3 a6  4. Nf3 Nc6 5. d4 Bg4 6. Be2 e6 7. O-O Nf6 8. Nbd2 Rc8 9. c4 cxd4  10. Nxd4 Bxe2 11. Qxe2 Nxd4 12. Bxd4 Bc5 13. Bxf6  Qxf6 14. cxd5 exd5 15. Nf3  O-O 16. Rad1 Rfd8 17. Rd3 d4 18. exd4 Bxd4 19. Qe4  Bb6 20. Rxd8+ Rxd8 21. Qxb7 g6 22. b4 Rd3 23. a4 Qd6 24. a5 Bc7 25. g3 Rb3 26. Rc1 Bd8 27. Re1 Bf6 28. Re4 Qd1+ 29. Ne1 Kg7 30. Kg2 Rb2   31. Qxa6  Bc3 32. Qc4 Qd2 33. Nd3 Rc2 34. Re7 1-0 "

; sample game 480
EventSites(480) = "Rostov on Don FIDE GP (Women)  Rostov on Don" : GameDates(480) = "20110803" : WhitePlayers(480) = "Hou, Yifan   G#480" : WhiteElos(480) = "2575" : BlackPlayers(480) = "Galliamova, Alisa   G#480" : BlackElos(480) = "2492" : Each_Game_Result(480) = "1-0"

FilePGNs(480) = "1. e4 c5 2. Nf3 e6  3. d4 cxd4 4. Nxd4 a6 5. Nc3 d6 6. Be2 b5 7. a3 Bb7 8. f4 Nf6 9. Bf3 d5  10. exd5 Nxd5 11. Nxd5 Bxd5 12. Be3 Qd7 13. Qe2 Nc6  14. O-O-O Rc8 15. f5 Nxd4 16. Bxd4 Bxf3 17. gxf3 Qc6 18. Rhe1 Qc4 19. fxe6  Qxe2 20. Rxe2 Ke7 21. exf7+  Kxf7 22. Bb6 h5 23. Rd7+ Kg8 24. Bd4 h4 25. h3 Rh6 26. Rg2 g6  27. Be3 Rc6 28. Bxh6 Bxh6+ 29. Kd1 Bf4 30. Re2 Kf8 31. Ree7 g5 32. c3 Rf6 33. Ke2 Bc1 34. Rh7 Kg8 35. Rdg7+ Kf8 36. Ra7 1-0 "

; sample game 481
EventSites(481) = "Barcelona Sants op 13th  Barcelona" : GameDates(481) = "20110822" : WhitePlayers(481) = "Matnadze, Ana   G#481" : WhiteElos(481) = "2428" : BlackPlayers(481) = "Marin, Mihail   G#481" : BlackElos(481) = "2548" : Each_Game_Result(481) = "0-1"

FilePGNs(481) = "1. d4 e6 2. c4 Bb4+ 3. Bd2 a5 4. Nf3 d6 5. Nc3 f5 6. Qc2  Nf6 7. e3 O-O 8. Bd3 Nc6 9. d5  Ne5 10. Nxe5 dxe5 11. O-O-O e4 12. Be2 Qe7 13. h3 exd5 14. Nxd5 Nxd5 15. cxd5 Bd6  16. Bc3 Bd7 17. g4 f4  18. exf4 Rxf4  19. Bd4 a4 20. Rhe1 a3  21. b3 c5  22. dxc6 Bxc6 23. Bc4+  Kh8 24. Bb6  Bc5   25. Bxc5 Qxc5 26. Re2 Rf3 27. Kb1 Rxh3 28. Red2 Rf8 29. Bd5 Qxc2+ 30. Rxc2  Rd3   31. Rxd3 exd3 32. Rc5 d2 33. Kc2 Rd8 0-1 "

; sample game 482
EventSites(482) = "FIDE World Cup  Khanty-Mansiysk" : GameDates(482) = "20110828" : WhitePlayers(482) = "Fier, Alexandr Hilario T   G#482" : WhiteElos(482) = "2566" : BlackPlayers(482) = "Wang Yue   G#482" : BlackElos(482) = "2709" : Each_Game_Result(482) = "1-0"

FilePGNs(482) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 dxc4 5. a4 Bf5 6. Ne5 e6 7. f3 c5 8. e4 Bg6 9. Be3 cxd4 10. Qxd4 Qxd4 11. Bxd4 Nfd7 12. Nxd7 Nxd7 13. Bxc4 Rc8 14. Bb3   a5 15. Ke2 Rg8 16. Nb5 Bc5 17. Bc3 b6 18. Be1  Ne5 19. Bh4 Bh5 20. Rhd1 g5 21. Bg3 Nc6 22. Nd6+ Bxd6 23. Bxd6 g4 24. Kf2 gxf3 25. gxf3 Rg6 26. Bc4  Rf6 27. Ra3 Na7 28. Rc1 e5 29. Bxe5 Rfc6 30. Rac3 Ke7 31. Bd5 Rxc3 32. Rxc3 Rxc3 33. Bxc3 f6 34. Bd4 Nc8 35. Bb7 Nd6 36. Ba6 Be8 37. Bxb6 Bxa4 38. Bxa5 Bb5 39. Bxb5 Nxb5 40. Kg3 Kf7 41. Kf4 h5 42. e5 Ke6 43. exf6 Kxf6 44. Bc3+ Kg6 45. Be5 Na7 46. b4 Nb5 47. Ke4 1-0 "

; sample game 483
EventSites(483) = "FIDE World Cup  Khanty-Mansiysk" : GameDates(483) = "20110901" : WhitePlayers(483) = "Shirov, Alexei   G#483" : WhiteElos(483) = "2714" : BlackPlayers(483) = "Potkin, Vladimir   G#483" : BlackElos(483) = "2682" : Each_Game_Result(483) = "0-1"

FilePGNs(483) = "1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. e5 Nfd7 5. f4 c5 6. Nf3 Nc6 7. Be3 a6 8. Ne2 Qb6 9. Qc1 Be7 10. g3 cxd4 11. Nexd4 Nc5 12. Bh3 Qa5+ 13. Kf2 Bd7 14. Nb3 Ne4+ 15. Kg2 Qc7 16. c4 Nb4 17. cxd5 Qc2+ 18. Qxc2 Nxc2 19. Bb6 Nxa1 20. dxe6 fxe6 21. Rxa1 Rc8 22. Nbd4 Bc5 23. Bxc5 Nxc5 24. b4 Nd3 25. Rd1 Nb2 26. Rb1 Nd3 27. Bxe6 Bxe6 28. Nxe6 Rc2+ 29. Kh3 g6 30. Nc5 Nf2+ 31. Kh4 b6 32. Nxa6 O-O 33. e6 Rf5 0-1 "

; sample game 484
EventSites(484) = "FIDE World Cup  Khanty-Mansiysk" : GameDates(484) = "20110905" : WhitePlayers(484) = "Svidler, Peter   G#484" : WhiteElos(484) = "2739" : BlackPlayers(484) = "Caruana, Fabiano   G#484" : BlackElos(484) = "2711" : Each_Game_Result(484) = "1-0"

FilePGNs(484) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. e3 Bg4 5. Qb3 Qc7 6. Ne5 e6 7. Nxg4 Nxg4 8. Be2 Nf6 9. Nc3 Nbd7 10. Bd2 Bd6 11. Rc1 dxc4 12. Qxc4 a6 13. h3 O-O 14. O-O e5 15. dxe5 Nxe5 16. Qb3 Rad8 17. Rfd1 Qe7 18. Be1 Ng6 19. Rd3 b5 20. Rcd1 h5  21. Qc2 h4 22. f4  Bc5 23. Bf2 Rxd3 24. Qxd3 Re8 25. Bf3 Bxe3 26. Qxe3 Qxe3 27. Bxe3 Rxe3 28. Rd8+ Kh7 29. Ne2 c5  30. Ra8 Rd3  31. Rxa6 Rd1+  32. Kf2 Rd2 33. b3 Rb2 34. Ke1 Ne7  35. Kd1  Rb1+ 36. Nc1 Rb2 37. Nd3 Rb1+ 38. Kc2 Rg1 39. a4 bxa4 40. Rxa4 Nfd5 41. Kd2 Rb1 42. Nxc5 Rb2+ 43. Kc1 Rf2 44. Nd3 Rf1+ 45. Kd2 Rb1 46. Ra5 Nb6 47. Rb5 Nbc8 48. Kc2 Ra1 49. Kb2 Ra6 50. Rb7 Re6 51. b4 Nd6 52. Rc7 Nb5 53. Rc5 Nd4 54. Re5 Rd6 55. Be4+ f5 56. Rxe7 fxe4 57. Rxe4 Nf5 58. Kc3 Rg6 59. Re5 Nd6 60. Ne1 Rg3+ 61. Kd4 Rb3 62. Nd3 Rb1 63. Rd5 Ne8 64. Rh5+ Kg6 65. Rxh4 Nd6 66. Rh8 Kf6 67. Rb8 Rd1 68. g4 Ke7 69. f5 Kd7 70. Rg8 Ne8 71. Ke3 Ke7 72. Ne5 Rb1 73. h4 Rb3+ 74. Kf4 Rxb4+ 75. Kg5 Re4 76. Ng6+ Kd7 77. Rf8 Nd6 78. Ra8 Ne8 79. h5 Rb4 80. Ra7+ Kd6 81. Re7 Nf6 82. Re6+ Kd7 83. Ne5+ Kc8 84. Rxf6 gxf6+ 85. Kxf6 1-0 "

; sample game 485
EventSites(485) = "FIDE World Cup  Khanty-Mansiysk" : GameDates(485) = "20110914" : WhitePlayers(485) = "Grischuk, Alexander   G#485" : WhiteElos(485) = "2746" : BlackPlayers(485) = "Ivanchuk, Vassily   G#485" : BlackElos(485) = "2768" : Each_Game_Result(485) = "1-0"

FilePGNs(485) = "1. e4 e6 2. d4 d5 3. e5 c5 4. c3 Nc6 5. Nf3 Bd7 6. Be2 Nge7 7. O-O Ng6 8. g3 Be7 9. h4 O-O 10. h5 Nh8 11. dxc5 Bxc5 12. b4  Be7 13. b5 Na5 14. h6 f5 15. hxg7 Kxg7  16. Kg2 Ng6 17. Rh1 Rf7 18. Bh6+ Kh8 19. Nbd2 Qc7 20. Rc1 Rg8 21. c4 d4 22. Bd3 b6 23. Nxd4 Qxe5 24. N2f3 Qc7 25. Ng5 Bxg5 26. Bxg5 e5  27. Qh5 Bc8 28. c5  exd4 29. cxb6 Bb7+  30. Kg1  Qe5  31. Rc7 Rxc7 32. bxc7 Rg7 33. Rh2  Rxc7  34. Qxg6  Rc1+  35. Bxc1 1-0 "

; sample game 486
EventSites(486) = "ESP-chT 1st Division  Parc Central del Valles" : GameDates(486) = "20110830" : WhitePlayers(486) = "Peralta, Fernando   G#486" : WhiteElos(486) = "2601" : BlackPlayers(486) = "Marin, Mihail   G#486" : BlackElos(486) = "2548" : Each_Game_Result(486) = "1/2-1/2"

FilePGNs(486) = "1. d4 e6 2. c4 Bb4+ 3. Bd2 a5 4. Nc3 Nf6 5. e3 b6 6. Bd3 Bb7 7. Nge2  O-O  8. a3 Bxc3 9. Nxc3 d5 10. O-O  c5  11. dxc5 bxc5 12. Ne2 Nbd7 13. Bc3 a4 14. Qc2 Qb6 15. Rac1 dxc4 16. Bxc4 Qc6 17. f3 Ng4 18. Bd3  Nxe3  19. Bxh7+ Kh8 20. Qd2  Kxh7 21. Qxe3  f6 22. Nf4 e5 23. Rfd1 Rf7 24. Nd5 Rc8 25. Qd3+ g6 26. Qc4 Kg7 27. Ne3 Nf8 28. Qg4 Qe6 29. Qxa4  Rd7 30. Rxd7+ Qxd7 31. Qxd7+ Nxd7 32. Rd1 Nf8 33. f4 exf4 34. Ng4 f3 35. Rd6  fxg2 36. Rxf6 Kg8 37. Nh6+ Kh7 38. Rf7+ Kxh6 39. Rxb7 Ne6 40. Kxg2 Rf8 41. Bd2+ Kh5 42. Re7 Rd8 43. Be3 Rd6 44. Kf3 g5 45. Ke4 Kg4 46. a4 Ra6 47. a5 Nf4 48. Bd2 Rh6 49. Bc3  Rxh2   50. Ke5  Ng6+ 51. Kf6 Nxe7 52. Kxe7 Kf5 53. Kd7 g4 54. Kc6 g3 55. Be1 Rxb2   56. Bxg3 c4 57. a6 c3 58. Be1 c2 59. Bd2 Ra2 60. Kb7 Ke4 61. a7 Kd3 62. Bg5 Ke2 63. a8=Q Rxa8 64. Kxa8 1/2-1/2 "

; sample game 487
EventSites(487) = "Moscow Botvinnik Memorial  Moscow" : GameDates(487) = "20110902" : WhitePlayers(487) = "Aronian, Levon   G#487" : WhiteElos(487) = "2807" : BlackPlayers(487) = "Anand, Viswanathan   G#487" : BlackElos(487) = "2817" : Each_Game_Result(487) = "0-1"

FilePGNs(487) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. e3 g6 5. Nf3 Bg7 6. h3 O-O 7. Bd3 a6 8. O-O Nbd7 9. a4 Re8 10. cxd5 cxd5 11. Bd2 b6 12. Qe2  Bb7 13. Rfd1 e5  14. dxe5 Nxe5 15. Be1  Nxf3+ 16. Qxf3 Qb8  17. Qf4 Qxf4 18. exf4 Nd7  19. a5 Nc5 20. Bf1 b5 21. f3 Nb3 22. Rab1 Nxa5 23. Bf2 Nc4 24. Bd4 Ne3 25. Rd3 Bxd4 26. Rxd4 Rac8 27. Bd3 Kg7 28. Kf2 Nc4 29. Ne2 Nd2  30. Rd1  Nb3 31. Rb4 Nc5 32. Rd4 Bc6 33. f5 a5 34. Bb1 b4 35. h4 Ba4 36. Rh1 Bb3 37. fxg6 hxg6 38. h5 Ne6 39. hxg6 fxg6 40. Rd2 Bc4 41. Rh4 Kf6 42. Rh6 Rg8 43. Nd4 Nxd4 44. Rxd4 a4 45. Rh7 a3 46. bxa3 bxa3 47. Rf4+ Ke5 48. g3 Rb8 0-1 "

; sample game 488
EventSites(488) = "Moscow Botvinnik Memorial  Moscow" : GameDates(488) = "20110903" : WhitePlayers(488) = "Kramnik, Vladimir   G#488" : WhiteElos(488) = "2791" : BlackPlayers(488) = "Carlsen, Magnus   G#488" : BlackElos(488) = "2823" : Each_Game_Result(488) = "1-0"

FilePGNs(488) = "1. Nf3 b5  2. e4  Bb7  3. Bxb5 Bxe4 4. O-O Nf6 5. d4 e6 6. c4 Be7 7. Nc3 Bb7 8. d5 O-O 9. Bf4   Na6 10. Re1 Qc8 11. Nd4 Bb4 12. Bg5  Ne8 13. Re3 c6 14. Bxa6 Bxa6 15. Qh5 f6 16. Rh3  fxg5 17. Qxh7+ Kf7 18. Qh5+ Kg8 19. Qh7+ Kf7 20. Ne4 Bxc4 21. Qh5+ Ke7 22. Qxg5+ Kf7 23. Qh5+ Ke7 24. Qg5+ Kf7 25. dxe6+ dxe6 26. Nf3  Kg8 27. Qh4 Rxf3 28. Qh7+ 1-0 "

; sample game 489
EventSites(489) = "EU-Cup 27th  Rogaska Slatina" : GameDates(489) = "20110929" : WhitePlayers(489) = "Postny, Evgeny   G#489" : WhiteElos(489) = "2622" : BlackPlayers(489) = "Eljanov, Pavel   G#489" : BlackElos(489) = "2683" : Each_Game_Result(489) = "1/2-1/2"

FilePGNs(489) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 e6 5. g3 dxc4 6. Bg2 b5 7. Ne5 a6  8. a4 Bb7 9. O-O Qc8  10. axb5 cxb5 11. d5 Bb4  12. e4 Nbd7 13. Nxd7 Qxd7 14. Bg5 Be7 15. Bxf6  Bxf6 16. e5  Bxe5 17. Qh5 Bxc3 18. dxe6 Qc7 19. exf7+ Qxf7 20. Rfe1+ Bxe1 21. Rxe1+ Kf8 22. Qc5+ Kg8 23. Bxb7 Qxb7 24. Re7 Qf3 25. Qe5 Qf6 26. Qd5+ Kf8 27. Re6 Re8  28. Qd6+  Kf7 29. Rxf6+ gxf6 30. Qxa6 Rb8 31. Qa7+ Kg6 32. h4 h5 33. Qd4 Rhe8 34. g4 hxg4 35. Qxg4+ Kf7 36. Qd7+ Re7 37. Qd5+ Kg7 38. Kf1 Rbb7 39. h5 Kh6 40. Qf5 Rg7 41. Qxf6+ Kxh5 42. Qf5+ Kh6 43. Qf6+ Kh7 44. Qf5+ Kg8 1/2-1/2 "

; sample game 490
EventSites(490) = "EU-Cup 27th  Rogaska Slatina" : GameDates(490) = "20110929" : WhitePlayers(490) = "Bartel, Mateusz   G#490" : WhiteElos(490) = "2627" : BlackPlayers(490) = "Predojevic, Borki   G#490" : BlackElos(490) = "2643" : Each_Game_Result(490) = "1-0"

FilePGNs(490) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. Ng5 d5 5. exd5 Na5 6. Bb5+ Bd7 7. Qe2 Be7 8. Nc3 O-O 9. O-O Bg4 10. Qxe5  a6 11. Be2 Bd6 12. Qe3 Re8 13. Qd3 Bxe2 14. Nxe2 Re5  15. f4 Rxd5 16. Qf3 Bc5+ 17. Kh1 Nc6 18. d3 Qd7 19. Nc3 Nd4 20. Qd1 Rf5 21. Nce4 Bb6 22. c3 Ne6 23. Nxf6+ Rxf6 24. Ne4 Rf5 25. Ng3  Rd5 26. f5 Nf8 27. d4 c5 28. Qg4 Kh8 29. Bh6  f6 30. Nh5 gxh6 31. Nxf6 Qf7 32. Nxd5 Qxd5 33. Rae1 Qf7 34. f6 cxd4 35. Re7 Qg6 36. Qf3 Bd8 37. Qxb7 dxc3 38. Qxa8 1-0 "

; sample game 491
EventSites(491) = "EU-Cup 27th  Rogaska Slatina" : GameDates(491) = "20111001" : WhitePlayers(491) = "Sutovsky, Emil   G#491" : WhiteElos(491) = "2690" : BlackPlayers(491) = "Naiditsch, Arkadij   G#491" : BlackElos(491) = "2707" : Each_Game_Result(491) = "1-0"

FilePGNs(491) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. d4 Nd6 6. Bxc6 dxc6 7. dxe5 Nf5 8. Qxd8+ Kxd8 9. h3 Ne7 10. Nc3 h6 11. Rd1+ Ke8 12. Bf4 Ng6 13. Bh2 Bb4 14. Ne2 a6 15. Nfd4  Be7 16. e6 c5 17. Nf5 Bf6 18. Bxc7 Bxe6 19. Neg3 h5 20. Bb6 Bxb2 21. Nd6+ Kf8 22. Rab1 Bd4 23. c3 Bxc3 24. Bxc5 Kg8 25. Rxb7 Bxa2 26. Nge4 Be5 27. Ng5 Rd8 28. Rd2  Bxd6 29. Rxd6 Re8 30. Rxa6 Bd5 31. Rd7 Be6 32. Rda7 Bd5 33. Rd6 Be6 34. Rda6 Bd5 35. Rxg6  fxg6 36. Bd4 Rh7 37. h4  Kh8 38. Rd7 Bg8 39. Kh2 Rf8 40. Kg3 Bb3 41. Nxh7 Kxh7 42. Rxg7+ Kh6 43. Rb7 Bf7 44. Rc7  Rd8 45. Bf6 Rf8 46. Bc3  g5 47. hxg5+ Kg6 48. Rc6+ Kxg5 49. Bf6+ Kf5 50. Bg7 1-0 "

; sample game 492
EventSites(492) = "Grand Slam Final 4th  Sao Paulo/Bilbao" : GameDates(492) = "20111010" : WhitePlayers(492) = "Carlsen, Magnus   G#492" : WhiteElos(492) = "2823" : BlackPlayers(492) = "Ivanchuk, Vassily   G#492" : BlackElos(492) = "2765" : Each_Game_Result(492) = "1-0"

FilePGNs(492) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Nf3 b6 5. Qc2 Bb7 6. a3 Bxc3+ 7. Qxc3 Ne4 8. Qc2 f5 9. g3 Nf6 10. Bh3 O-O 11. O-O a5 12. Rd1 Qe8 13. d5 Na6 14. Bf4 exd5  15. Bxf5 dxc4 16. Ng5  Qh5 17. Rxd7 Kh8 18. Re7  Nd5 19. Bg4  Qg6 20. Nf7+ Kg8 21. Bf5 Qxf5  22. Qxf5 Nxe7 23. Nh6+ gxh6 24. Qg4+ Ng6 25. Bxh6 Rf7 26. Rd1 Re8 27. h4 Nc5 28. h5 Bc8 29. Qxc4 Ne5 30. Qh4 Nc6  31. Rd5 Ne6 32. Qc4 Ncd8  33. Qg4+ Ng7 34. Qxc8 1-0 "

; sample game 493
EventSites(493) = "Poikovsky Karpov 12th  Poikovsky" : GameDates(493) = "20111006" : WhitePlayers(493) = "Karjakin, Sergey   G#493" : WhiteElos(493) = "2772" : BlackPlayers(493) = "Laznicka, Viktor   G#493" : BlackElos(493) = "2701" : Each_Game_Result(493) = "1-0"

FilePGNs(493) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Nf3 e6 5. Be2 c5 6. Be3 Qb6 7. Nc3 Nc6 8. O-O Qxb2 9. Qe1 c4 10. Rb1 Qxc2 11. Rxb7 Bb4  12. Rxb4 Nxb4 13. Bd1   Qd3 14. Ba4+ Kf8 15. Qa1 Bg4 16. Qb2 Rb8 17. Rb1 Bxf3  18. Bc2 Be2  19. Bxd3 Bxd3 20. a3  Bxb1 21. axb4 Bg6 22. Qa3 Rb7 23. b5+ Re7 24. Bf4 h6 25. h4 Rh7 26. Qa6 Bf5 27. Bc1 f6 28. Ba3 fxe5 29. Qc8+ Kf7 30. Nxd5 1-0 "

; sample game 494
EventSites(494) = "ROM-chT  Brasov" : GameDates(494) = "20111008" : WhitePlayers(494) = "Lupulescu, Constantin   G#494" : WhiteElos(494) = "2655" : BlackPlayers(494) = "Marin, Mihail   G#494" : BlackElos(494) = "2550" : Each_Game_Result(494) = "1/2-1/2"

FilePGNs(494) = "1. Nf3 Nf6 2. c4 b6 3. g3 Bb7 4. Bg2 e6 5. d4 Bb4+ 6. Nbd2 O-O 7. O-O d5 8. cxd5 exd5 9. Ne5 Be7  10. b3 Na6 11. Bb2 c5 12. Nd3 Re8 13. Rc1 Bf8  14. e3  Qe7 15. Qe2 Rad8 16. Rfd1 Ne4 17. dxc5 bxc5 18. Ba3 Nxd2 19. Qxd2  d4 20. e4  Rc8 21. Re1 Qd7 22. Rc4 Qb5 23. e5  Bxg2 24. Kxg2 Nb8  25. Kg1 Nd7 26. Rc2  1/2-1/2 "

; sample game 495
EventSites(495) = "Nalchik FIDE GP (Women)  Nalchik" : GameDates(495) = "20111014" : WhitePlayers(495) = "Zhao Xue   G#495" : WhiteElos(495) = "2497" : BlackPlayers(495) = "Lahno, Kateryna   G#495" : BlackElos(495) = "2554" : Each_Game_Result(495) = "1-0"

FilePGNs(495) = "1. d4 Nf6 2. c4 g6 3. f3 d5 4. cxd5 c6  5. dxc6 Nxc6 6. e3 e5 7. dxe5 Qa5+ 8. Nc3 Qxe5 9. Bb5 Bc5 10. Nge2 O-O 11. Bxc6 bxc6 12. e4 Bb6 13. Na4 Rd8 14. Qc2 Qa5+ 15. Nec3 Nd5  16. exd5 Bf5 17. Qd2 Re8+ 18. Kd1 Be3 19. Qxe3 Rxe3 20. Bxe3 cxd5 21. Ke2 Bc2 22. b3 d4  23. Bxd4 Qg5 24. Kf1 Qd2 25. Bf2 Rc8 26. Re1 Rxc3 27. Nxc3 Qxc3 28. h4  h5 29. Kg1 Qd2 30. Bg3 Bd1 31. Rh3 Be2 32. Bf2 Qxa2 33. Rg3 Qd2 34. Rg5 a6 35. Rc5 Qb2  36. Rd5   f6 37. Rd7 g5 38. hxg5 fxg5 39. Be3 Bb5 40. Bc1 1-0 "

; sample game 496
EventSites(496) = "Nalchik FIDE GP (Women)  Nalchik" : GameDates(496) = "20111017" : WhitePlayers(496) = "Zhao Xue   G#496" : WhiteElos(496) = "2497" : BlackPlayers(496) = "Kosintseva, Nadezhda   G#496" : BlackElos(496) = "2560" : Each_Game_Result(496) = "1-0"

FilePGNs(496) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Ba6 5. Qa4 Bb7 6. Bg2 c5 7. dxc5 bxc5 8. O-O Be7 9. Nc3 O-O 10. Rd1 Qb6 11. Bf4 Rd8 12. Rd2 d6 13. Rad1 h6 14. h3 e5 15. Be3 Nc6 16. Nh2   Nd4 17. Ng4 Nd7  18. Nd5 Bxd5 19. Bxd5 Rab8 20. Bxh6 Qc7 21. Rxd4  exd4 22. Qc2 Ne5 23. Bf4 Rb6 24. Qe4 Bf8 25. Bg5  Re8 26. f4 Nxg4 27. Qxe8 Ne3  28. Bd8 Rb8 29. Qxf8+  Kxf8 30. Bxc7 Rxb2 31. Bxd6+ Ke8 32. Rc1 Nxd5 33. cxd5 Rxe2 34. Bxc5 d3 35. Rd1 1-0 "

; sample game 497
EventSites(497) = "Bundesliga 1112  Germany" : GameDates(497) = "20111015" : WhitePlayers(497) = "Postny, Evgeny   G#497" : WhiteElos(497) = "2622" : BlackPlayers(497) = "L'Ami, Erwin   G#497" : BlackElos(497) = "2592" : Each_Game_Result(497) = "1/2-1/2"

FilePGNs(497) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. Nc3 Bb4 5. e3 Bb7 6. Bd3 Ne4 7. O-O Bxc3 8. bxc3 Nxc3  9. Qc2 Bxf3 10. gxf3 Qg5+ 11. Kh1 Qh5 12. Rg1 Qxf3+ 13. Rg2 f5 14. Bb2 Ne4 15. Rf1 Nc6 16. Be2 Qh3 17. f3 Nf6 18. d5 Ne7 19. Rxg7 Qh6 20. Rfg1 Rf8 21. dxe6 dxe6 22. c5  Rf7 23. cxb6  Rxg7 24. Rxg7 axb6  25. Bb5+ Kf8 26. Rxe7 Kxe7 27. Qxc7+ Kf8 28. Qd6+ Kf7 29. Qc7+ Kf8 30. Qd6+ Kf7 31. Qc7+ 1/2-1/2 "

; sample game 498
EventSites(498) = "Bundesliga 1112  Germany" : GameDates(498) = "20111015" : WhitePlayers(498) = "Reeh, Oliver   G#498" : WhiteElos(498) = "2453" : BlackPlayers(498) = "Edouard, Romain   G#498" : BlackElos(498) = "2608" : Each_Game_Result(498) = "0-1"

FilePGNs(498) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 Nc6 6. Bc4 Qb6 7. Nde2 e6 8. O-O a6 9. Bb3 Be7 10. Bg5 Qc7 11. Ng3 h6  12. Bxf6  Bxf6 13. Nh5 Be5  14. f4 Bd4+ 15. Kh1 g6 16. Ne2  Bxb2 17. Rb1 gxh5 18. Rxb2 Bd7 19. Rf3 O-O-O 20. Rc3 d5  21. exd5 exd5 22. Nd4 Rhe8  23. Rb1 Re4 24. Bxd5  Rxd4 25. Qxd4 Nxd4 26. Bxb7+ Kb8 27. Bxa6+ Nb5  28. Rxc7 Kxc7 29. h3 Nd4 30. c3 Ne6 31. Rb7+ Kd6 32. Bc4 Nxf4 33. Bxf7 Bc6 34. Rb4 Ke5 35. Rb2 Rf8 36. Bc4 Nxg2 37. Re2+ Ne3+ 38. Kh2 Ke4 39. Kg3 Rf3+ 40. Kh4 Kf4 41. Be6 Rg3 0-1 "

; sample game 499
EventSites(499) = "Bundesliga 1112  Germany" : GameDates(499) = "20111016" : WhitePlayers(499) = "L'Ami, Erwin   G#499" : WhiteElos(499) = "2591" : BlackPlayers(499) = "Miroshnichenko, Evgenij   G#499" : BlackElos(499) = "2624" : Each_Game_Result(499) = "1-0"

FilePGNs(499) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Bb4 5. Bg5 dxc4 6. e4 h6  7. Bxf6 Qxf6 8. Bxc4 c5 9. e5 Qd8 10. O-O O-O 11. Ne4 cxd4 12. Qe2 Bd7 13. Rad1 Nc6 14. Ng3  Bc5  15. Qe4 Ne7 16. Qg4 Bc6 17. Ne4 Bxe4  18. Qxe4 Qb6 19. Bd3 g6 20. h4 Kg7 21. h5 Qc6  22. Qg4 Nf5 23. Rc1  Qb6 24. Nh4 Nxh4 25. Qxh4 f5 26. exf6+ Rxf6 27. hxg6 Qd6 28. Qe4 Rb8 29. g3 a5 30. Kg2 b6 31. Rh1 Rbf8 32. f4 Qd5 33. Qxd5 exd5 34. Rce1 Rd8 35. Rh5 Bf8 36. Ree5 Rxg6 37. Bxg6 Kxg6 38. Rxd5 Rc8 39. Rh2  1-0 "

; sample game 500
EventSites(500) = "Lubbock SPICE Cup-A 5th  Lubbock" : GameDates(500) = "20111021" : WhitePlayers(500) = "Le Quang, Liem   G#500" : WhiteElos(500) = "2717" : BlackPlayers(500) = "Shulman, Yuri   G#500" : BlackElos(500) = "2608" : Each_Game_Result(500) = "1-0"

FilePGNs(500) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 dxc4 5. e4 Bb4 6. Bg5 c5 7. Bxc4 cxd4 8. Nxd4 Qa5 9. Bd2 Qc5 10. Bb5+ Bd7 11. Nb3 Qe7 12. Bd3 Nc6 13. O-O O-O 14. a3 Bd6 15. Kh1 Ne5 16. Be2  Ng6 17. f4 e5 18. f5 Nf4 19. Bf3 Bc6  20. Qc2 Rfc8 21. g3 Ne2 22. Nxe2 Bxe4 23. Bxe4 Rxc2 24. Bxc2 Qc7 25. Nc3 Qc6+ 26. Kg1 Bc5+  27. Nxc5 Qxc5+ 28. Kg2 Qb6 29. Rab1 Rd8 30. Bc1 h6 31. Re1 Qc6+ 32. Kg1 Ng4  33. Re2 Qf3 34. Bg5 Rd4 35. Rf1 Qc6 36. Bc1 Qc5 37. Kg2 b5 38. Be4 a5 39. Bf3 Qc4 40. Ne4 Nxh2 41. b3 Qd3 42. Nc5 Qc3 43. Kxh2 Qxc5 44. Be3 a4 45. Rc1 Qd6 46. Bxd4 Qxd4 47. bxa4 bxa4 48. Kg2 Qd7 49. Rb1 Kh7 50. Rxe5 Qd3 51. Rb8 Qxa3 52. Ree8 g5 53. Rg8 Qd3 54. f6 Qc2+ 55. Kh3 Qf5+ 56. Kh2 1-0 "

; sample game 501
EventSites(501) = "EU-chT (Men) 18th  Porto Carras" : GameDates(501) = "20111105" : WhitePlayers(501) = "Jones, Gawain C   G#501" : WhiteElos(501) = "2635" : BlackPlayers(501) = "Akopian, Vladimir   G#501" : BlackElos(501) = "2681" : Each_Game_Result(501) = "1-0"

FilePGNs(501) = "1. e4 e6 2. d4 d5 3. Nd2 c5 4. Ngf3 cxd4 5. Nxd4 Nf6 6. exd5 Qxd5 7. Nb5 Na6 8. Nc3 Qd8 9. a3  Be7 10. Qf3  Nc5 11. b4  Ncd7 12. Nc4 O-O 13. Bb2 a5  14. Nxa5 Rxa5 15. bxa5 Ne5 16. Qf4 Qxa5 17. Qa4 Qb6 18. Nb5 Neg4 19. Bd4 Qc6 20. Nc3 Qc7 21. Qc4 Qa5 22. Qa4 Bd8  23. Qb4  Qg5 24. Bb5 b6 25. Bc6 Ba6 26. Qa4 e5 27. Qxa6 exd4 28. Qb5 Qf4 29. Nd1 d3  30. cxd3 Bc7 31. g3 Qh6 32. Ra2  Ne5 33. d4 Neg4 34. h3 Nxf2 35. Nxf2 Bxg3 36. O-O  Qe3 37. Kg2 Bb8 38. Qd3 Qe6 39. Rc2 Nh5 40. Ng4 Nf4+ 41. Rxf4 Bxf4 42. Qf3 Bb8 43. Bd5 Qe7 44. Re2 1-0 "

; sample game 502
EventSites(502) = "EU-chT (Men) 18th  Porto Carras" : GameDates(502) = "20111109" : WhitePlayers(502) = "Bartel, Mateusz   G#502" : WhiteElos(502) = "2653" : BlackPlayers(502) = "Jones, Gawain C   G#502" : BlackElos(502) = "2635" : Each_Game_Result(502) = "1/2-1/2"

FilePGNs(502) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. f3 O-O 6. Nge2 a6  7. Be3 Nc6 8. Qd2 Rb8 9. Rc1 Bd7 10. Nd1 e6 11. g3 Re8  12. Bg2 b5 13. c5 dxc5 14. Rxc5 Bf8  15. Rc1 e5 16. d5 Bb4 17. Nec3 Nd4  18. f4  c5 19. O-O Ng4 20. fxe5 Nxe3 21. Qxe3 Ba5  22. d6 Rxe5 23. Nd5 Rxd5  24. exd5 Nf5 25. Qf4 c4 26. Kh1 Qf8 27. Nc3 Nxd6 28. Ne4 Nxe4 29. Qxe4 Qd6 30. b3 Bd2 31. Rcd1 c3 32. Qd4 Rc8 33. Rxd2 cxd2 34. Qxd2 Bf5 35. Qd4 h5 36. Re1 Bd7 37. Qf2 1/2-1/2 "

; sample game 503
EventSites(503) = "EU-chT (Men) 18th  Porto Carras" : GameDates(503) = "20111111" : WhitePlayers(503) = "Laznicka, Viktor   G#503" : WhiteElos(503) = "2703" : BlackPlayers(503) = "Van Wely, Loek   G#503" : BlackElos(503) = "2686" : Each_Game_Result(503) = "1/2-1/2"

FilePGNs(503) = "1. d4 f5  2. g3 Nf6 3. Bg2 g6 4. Nf3 Bg7 5. O-O O-O 6. c4 d6 7. Nc3 Qe8 8. d5 h6  9. Qc2 Na6 10. Rb1 e5 11. dxe6 Bxe6 12. Nd2 c6 13. b4 Rc8 14. Ba3 Nd7 15. Rfd1 Qe7 16. b5 Nac5 17. bxc6 bxc6 18. Nb3 f4  19. Nd4 Bxd4  20. Rxd4 Bf5 21. Qd2 Bxb1 22. Nxb1 fxg3 23. hxg3 Qf7 24. Rf4 Qe6 25. Rxf8+  Rxf8 26. Nc3 Ne5 27. Qxh6 Ng4 28. Qg5 Nxf2 29. Bxc5 dxc5 30. Qxc5 Qf6 31. Qxc6  Qxc3 32. Qxg6+ Qg7 33. Bd5+ Kh8 34. Qh5+ Qh7 35. Qe5+ Qg7 36. Qh5+ 1/2-1/2 "

; sample game 504
EventSites(504) = "Bundesliga 1112  Germany" : GameDates(504) = "20111120" : WhitePlayers(504) = "Postny, Evgeny   G#504" : WhiteElos(504) = "2622" : BlackPlayers(504) = "Malakhatko, Vadim   G#504" : BlackElos(504) = "2543" : Each_Game_Result(504) = "1-0"

FilePGNs(504) = "1. c4 c6 2. Nf3 d5 3. d4 Nf6 4. Nc3 e6 5. g3 dxc4 6. Bg2 c5  7. Qa4+ Nbd7 8. O-O a6 9. Rd1 Rb8  10. Bf4 b5 11. Qc2 Rb6 12. d5 Bb7 13. dxe6 fxe6 14. a4 Qc8  15. axb5 axb5 16. Ra5 Ba6 17. Ng5 Be7 18. Bh3 Nf8 19. Rda1 h6 20. Nge4 Kf7 21. Nxf6 gxf6 22. Nd5 Rc6 23. Nc7  Bb7 24. Nxb5 Rb6 25. Na3 Qc6 26. f3 Ng6 27. Nxc4  Nxf4 28. gxf4 Rb4 29. Kf2 h5  30. Rg1 Rh6 31. f5 Qc7 32. fxe6+ Kf8 33. Rg2  Qf4 34. Ne3 Qd4 35. Qc3 Rh7  36. Qxd4 cxd4 37. Nf5 Bd8 38. Ra1 Rxb2  39. Rag1 1-0 "

; sample game 505
EventSites(505) = "London Classic 3rd  London" : GameDates(505) = "20111204" : WhitePlayers(505) = "Short, Nigel D   G#505" : WhiteElos(505) = "2698" : BlackPlayers(505) = "Kramnik, Vladimir   G#505" : BlackElos(505) = "2800" : Each_Game_Result(505) = "0-1"

FilePGNs(505) = "1. e4 e5 2. Nf3 Nc6 3. Nc3 Nf6 4. Bb5 Nd4 5. Nxd4 exd4 6. e5 dxc3 7. exf6 Qxf6 8. dxc3 Bc5 9. Qe2+ Qe6 10. O-O O-O 11. Qf3 d6 12. Bg5 Qf5 13. Be7 Qxf3 14. gxf3 a6 15. Ba4 b5 16. b4 Re8 17. Rfe1 Bb6 18. Bb3 Bb7 19. Kg2 d5 20. Re5 c6 21. Rae1 Bc7 22. R5e2 Bc8 23. a4 Bd7 24. Bh4 Rxe2 25. Rxe2 Re8 26. Rxe8+ Bxe8 27. Bg3 Bd8 28. Be5 f6 29. Bb8 Bg6 30. axb5 axb5 31. Kf1 Kf7 32. Ke2 Ke6 33. Ke3 Bb6+ 34. Ke2 Bh5 35. Ba2 g5 36. Bb3 f5 37. Ba2 f4 38. Bb3 Kf5 39. Bd6 g4 40. Kf1 g3 41. fxg3 fxg3 42. Bxg3 Bxf3 43. Ba2 Be3 0-1 "

; sample game 506
EventSites(506) = "London Classic 3rd  London" : GameDates(506) = "20111211" : WhitePlayers(506) = "McShane, Luke J   G#506" : WhiteElos(506) = "2671" : BlackPlayers(506) = "Kramnik, Vladimir   G#506" : BlackElos(506) = "2800" : Each_Game_Result(506) = "0-1"

FilePGNs(506) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. d3 Bc5 5. Bxc6  dxc6 6. b3  Bg4   7. Nbd2 Nd7 8. Bb2 f6 9. Nf1 Nf8 10. h3 Bxf3 11. Qxf3 Ne6 12. Ne3 Qd7 13. h4 a5 14. a4 O-O 15. h5 Bxe3  16. Qxe3 c5 17. Qh3 Qc6 18. O-O Nf4 19. Qh2 Qe8 20. h6 g5 21. g3 Ne6 22. f4  gxf4 23. gxf4 Nxf4 24. Rxf4 exf4 25. Kf2 Rf7 26. Qh5 Qe6 27. Qxc5 Kh8 28. Qc4  Re8 29. Rh1 Qd7 30. Qb5 Re6 31. Qxd7 Rxd7 32. Rg1 Rc6 33. Kf3 Rd8 34. Rg5 Rf8 35. Rg2  Rg8  36. Rh2 Rg1  37. d4 Rf1+ 38. Kg4 f3 39. d5 Rd6 40. c4 Kg8 41. c5 f5+ 42. Kxf5 Rg6 43. Bd4 Rd1 44. Be3 Rg2 45. Rh3 f2 46. Bxf2 Rxf2+ 47. Ke6 Rf7 48. d6 c6  49. Ke5 Kf8 50. Rh2 Rg1 51. b4 axb4 52. Rb2 Rg5+ 53. Ke6 Rg6+ 54. Ke5 Rxh6 55. a5 Rh5+ 56. Ke6 Rh6+ 57. Ke5 Rh5+ 58. Ke6 Ke8 59. a6 Rh6+ 60. Ke5 bxa6 61. Rxb4 Ra7 62. Rb8+ Kf7 63. Rc8 Re6+ 64. Kf5 a5 65. Rh8 Rf6+ 66. Ke5 Kg7 67. Rc8 a4 68. Rxc6 a3 69. d7 a2 0-1 "

; sample game 507
EventSites(507) = "Reggio Emilia 54th  Reggio Emilia" : GameDates(507) = "20120102" : WhitePlayers(507) = "Morozevich, Alexander   G#507" : WhiteElos(507) = "2762" : BlackPlayers(507) = "Caruana, Fabiano   G#507" : BlackElos(507) = "2727" : Each_Game_Result(507) = "0-1"

FilePGNs(507) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. Bg5 Ne4 5. h4 Bg7 6. e3 c5 7. cxd5 Nxc3 8. bxc3 Qxd5 9. Qf3 Qxf3 10. Nxf3 Nc6 11. Rb1 Na5 12. Bb5+ Bd7 13. Ke2 Rc8 14. Bxd7+ Kxd7 15. Rb5  b6 16. dxc5 Rxc5 17. Rxc5 bxc5 18. Rd1+ Ke6 19. e4 Bxc3 20. Be3 Bf6 21. h5  Rc8 22. h6 Nc4 23. Bf4 Nb2 24. Rd5 c4 25. Ra5 Nd3 26. Be3 Rb8 27. Nd4+ Kd7 28. Kd2 Rb7 29. g4  e6  30. f3 Bd8 31. Ra4 Nb2 32. Ra6 Bb6 33. Nc2 Nd3 34. Bxb6 axb6 35. g5 Nf4 36. Ne3 Kc6 37. Ng4 Kb5 38. Ra8 Rc7 39. Nf6  c3+ 40. Kc2 Ne2 41. Rd8 Kc4 42. Nd7 Nd4+ 43. Kc1 c2 44. Nxb6+ Kd3 0-1 "

; sample game 508
EventSites(508) = "Hastings Masters op 87th  Hastings" : GameDates(508) = "20120103" : WhitePlayers(508) = "Edouard, Romain   G#508" : WhiteElos(508) = "2621" : BlackPlayers(508) = "Haydon, David Leslie   G#508" : BlackElos(508) = "2296" : Each_Game_Result(508) = "1-0"

FilePGNs(508) = "1. d4 c6 2. c4 d5 3. Nf3 Nf6 4. e3 e6 5. Bd3 c5 6. O-O Nc6 7. Nc3 dxc4 8. Bxc4 cxd4 9. exd4 Be7 10. a3 O-O 11. Qd3 a6  12. Bg5 b5 13. Bb3  b4  14. Na4 bxa3 15. bxa3 Na5  16. Bc2 g6 17. Ne5 Nd5 18. Bh6 Re8 19. Bd2  Nb7 20. Rab1 Nd6 21. Nc5 Bf6 22. Ba4 Nb5 23. Bxb5  axb5 24. Rxb5 Nc7  25. Nc6   Qd5  26. Ne4 Qxc6 27. Nxf6+ Kg7 28. Rc5 Qa4 29. Rxc7 1-0 "

; sample game 509
EventSites(509) = "Reggio Emilia 54th  Reggio Emilia" : GameDates(509) = "20120105" : WhitePlayers(509) = "Caruana, Fabiano   G#509" : WhiteElos(509) = "2727" : BlackPlayers(509) = "Vitiugov, Nikita   G#509" : BlackElos(509) = "2729" : Each_Game_Result(509) = "1-0"

FilePGNs(509) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 a6 5. Be2 Nf6 6. Nc3 Qc7 7. O-O Bb4 8. Qd3 Nc6 9. Kh1 Nxd4 10. Qxd4 Bc5 11. Qd2  h6 12. f4 d6 13. Qe1 Bd7 14. Qg3 Bd4 15. Bf3 Qc4 16. Bd2 Bc6 17. Rae1  O-O-O  18. Be2 Qc5 19. Bd3 g5 20. Qf3 Rhg8  21. Na4  g4 22. Qe2 Qh5 23. Bc3 Bxc3 24. Nxc3  Qc5  25. e5  Nd7 26. Ne4 Bxe4 27. Bxe4 d5 28. Bd3  Kb8 29. Rb1  Rc8 30. b4 Qd4 31. Qe1  Nb6 32. b5 axb5 33. Rxb5  Rc7 34. Qa5 Nd7 35. Rfb1 Qa7  36. Qb4  Nc5 37. Bh7  Rgc8 38. Ra5 Na6  39. Qd6 Ka8 40. Rb6  Rc6 41. Raxa6  bxa6 42. Rxc6 Rb8 43. c3  1-0 "

; sample game 510
EventSites(510) = "Tata Steel-B 74th  Wijk aan Zee" : GameDates(510) = "20120114" : WhitePlayers(510) = "L'Ami, Erwin   G#510" : WhiteElos(510) = "2596" : BlackPlayers(510) = "Tiviakov, Sergei   G#510" : BlackElos(510) = "2677" : Each_Game_Result(510) = "1-0"

FilePGNs(510) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Bb7 5. Bg2 Be7 6. O-O O-O 7. Nc3 Ne4 8. Bd2 f5 9. Ne5  Nxc3 10. Bxc3 Bxg2 11. Kxg2 Bf6 12. Qd3 d5 13. Rfd1 Qd6 14. Qf3 c6 15. Rac1 Nd7  16. Bb4  Nxe5 17. Bxd6 Nxf3 18. Bxf8 Nxd4 19. e3 Ne2 20. Rc2 Kxf8 21. Rxe2 Ke7 22. Rc2 Kd6 23. b4 a5  24. cxd5 exd5 25. Rdc1  Rc8 26. bxa5 bxa5 27. Rb1 d4  28. Kf3 dxe3 29. Kxe3 Re8+ 30. Kf4 Bd4 31. Kxf5 Bxf2 32. Rd1+ Kc7 33. Rdd2  Bb6 34. Re2 Rf8+ 35. Kg4 Bd4 36. Re6 c5 37. Ra6 Kb7 38. Rxa5 Kc6 39. a4 Kd5 40. Ra7 Ke4 41. a5 Rc8 42. a6 c4 43. Rd7 c3 44. a7 Ra8 45. Ra2 Ke3 46. Ra3 h6 47. Ra2 Bf6 48. Kf5 Bd4 49. Ke6 Bf6 50. Kf5 Bd4 51. g4 Bf6 52. h3 Bd4 53. h4 Bf6 54. g5 hxg5 55. hxg5 Bd4 56. Kg6  Be5 57. Re7 1-0 "

; sample game 511
EventSites(511) = "Tata Steel-A 74th  Wijk aan Zee" : GameDates(511) = "20120114" : WhitePlayers(511) = "Carlsen, Magnus   G#511" : WhiteElos(511) = "2835" : BlackPlayers(511) = "Gashimov, Vugar   G#511" : BlackElos(511) = "2761" : Each_Game_Result(511) = "1-0"

FilePGNs(511) = "1. Nf3 Nf6 2. c4 c5 3. Nc3 e6 4. g3 b6 5. Bg2 Bb7 6. O-O Be7 7. d4 cxd4 8. Qxd4 d6 9. Bg5 a6 10. Bxf6 Bxf6 11. Qf4 O-O 12. Rfd1 Be7 13. Ne4 Bxe4 14. Qxe4 Ra7 15. Nd4 Rc7 16. Rd2 Rc5 17. Rad1 Qc7 18. b3 Kh8 19. Qb1 Nd7 20. e3 Qc8 21. Rc2 Rc7 22. a4 Rd8 23. Qa2 Ne5 24. h3  Bf6 25. Rcd2 Rc5 26. f4 Ng6 27. Rd3 h6 28. Qd2 e5 29. Nc2  b5 30. axb5 axb5 31. Na3 bxc4 32. Nxc4 d5 33. Bxd5 Qxh3 34. Qg2 Qxg2+ 35. Kxg2 exf4 36. exf4 Rc7 37. Ne3 Rcd7 38. Ng4 Bb2  39. Nf2 f6 40. Be4 Nf8 41. b4 Rxd3 42. Nxd3 Bc3 43. Rc1 Bd4 44. Nc5 Be3 45. Rc3 Rd2+ 46. Kf3 Bd4 47. Rc4 g6 48. Nd3 Bg1 49. Rc8  Kg7 50. Rc7+ Kg8 51. f5 g5  52. g4 Bh2 53. Rb7 Rc2 54. Nc5 Rc3+ 55. Ke2 h5 56. gxh5 g4 57. Ne6 Rc8 58. b5 Rb8 59. Rxb8 Bxb8 60. Bd5 Ba7 61. Kf1 Be3 62. Kg2 Kf7 63. Nxf8+ Kxf8 64. Kg3 Ke7 65. Kxg4 Kd6 66. Kf3 Bd2 67. b6 1-0 "

; sample game 512
EventSites(512) = "Tata Steel-B 74th  Wijk aan Zee" : GameDates(512) = "20120117" : WhitePlayers(512) = "Motylev, Alexander   G#512" : WhiteElos(512) = "2677" : BlackPlayers(512) = "Tiviakov, Sergei   G#512" : BlackElos(512) = "2677" : Each_Game_Result(512) = "1-0"

FilePGNs(512) = "1. e4 d5 2. exd5 Qxd5 3. Nc3 Qd6 4. d4 Nf6 5. Nf3 g6  6. Nb5  Qd8  7. c4 Bg7 8. h3  O-O 9. Be2 c5  10. d5 a6 11. Nc3 b5  12. O-O  Nbd7  13. cxb5  Nb6  14. Ne5  Nfxd5  15. Nxd5 Bxe5 16. Nxb6 Qxb6 17. Qd5  Qb8  18. b6  Bb7 19. Qxc5 Rc8  20. Qa3  Bd5  21. Rd1  e6 22. Be3  Rc2 23. Bf3  Bxb2 24. Qa4  Rc4 25. Qxc4  Bxc4 26. Rab1  Be5 27. b7  Bd5 28. Bxd5 exd5 29. Rxd5 Bc7 30. Rd7 Be5 31. bxa8=Q Qxa8 32. Bh6  Qe8 33. Rbd1 Bf6 34. R7d6  Be7 35. Re1 a5 36. Rb6 Qd8 37. Rxe7  1-0 "

; sample game 513
EventSites(513) = "Tata Steel-A 74th  Wijk aan Zee" : GameDates(513) = "20120121" : WhitePlayers(513) = "Van Wely, Loek   G#513" : WhiteElos(513) = "2692" : BlackPlayers(513) = "Giri, Anish   G#513" : BlackElos(513) = "2714" : Each_Game_Result(513) = "1/2-1/2"

FilePGNs(513) = "1. d4 Nf6 2. Bg5  c5 3. Bxf6 gxf6 4. d5 Qb6 5. Qc1 f5 6. g3 Bg7 7. c3 Qf6 8. e3 Na6 9. Ne2 Nc7 10. Nf4 Bh6 11. c4 d6 12. Nc3 Bd7 13. Be2 a6 14. a4 b6 15. Nh5 Qg6 16. Bf3 Rb8 17. Ne2 Rf8 18. Qd2 a5 19. O-O Kd8 20. Rfe1 Ne8 21. Nef4 Qg8 22. e4 Qh8 23. Qe2 Rb7 24. e5 Qxe5 25. Qxe5 dxe5 26. Rxe5 Nd6 27. b3 Rg8 28. Rae1 Bf8 29. R5e3 Rb8 30. h4 Kc7 31. Bd1 Re8 32. Bc2 Kd8 33. R3e2 Rg4 34. Kh2 Rg8 35. f3 Kc7 36. Nd3 Rg6 37. Ne5 Rh6 38. Nxd7 Kxd7 39. g4 e6 40. Re5  Be7 41. Kh3 Bd8 42. R1e2 Rf8  43. Bd3 fxg4+  44. fxg4 exd5 45. Rxd5 Kc7 46. Bf5 Rg8 47. Re3 Rf8 48. Ree5 Rg8 49. Bc2 Rf8 50. Bd1 Re8 51. Rxe8 Nxe8 52. g5 Rd6 53. Rxd6 Kxd6 54. Bc2 f6 55. g6 hxg6 56. Bxg6 Nc7 57. Bf5 Ne6 58. Bxe6 Kxe6 59. Ng7+ Ke5 60. Kg4 f5+  61. Nxf5 Bxh4  62. Nxh4 Kd4 63. Kf3 Kc3 64. Ke3 Kxb3 65. Kd3 Kxa4 66. Kc3 b5 1/2-1/2 "

; sample game 514
EventSites(514) = "Tata Steel-A 74th  Wijk aan Zee" : GameDates(514) = "20120121" : WhitePlayers(514) = "Carlsen, Magnus   G#514" : WhiteElos(514) = "2835" : BlackPlayers(514) = "Gelfand, Boris   G#514" : BlackElos(514) = "2739" : Each_Game_Result(514) = "1-0"

FilePGNs(514) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. e3 Bf5 5. Nc3 e6 6. Nh4 Bg6 7. Nxg6 hxg6 8. Bd3 Nbd7 9. O-O Bd6 10. h3 dxc4 11. Bxc4 O-O 12. Qc2 Qe7 13. Rd1 Rac8 14. Bd2 Nb6 15. Bf1 e5 16. dxe5 Bxe5 17. Rac1 Rcd8 18. Be1 Rxd1 19. Rxd1 Rd8 20. Rxd8+ Qxd8 21. g3 Qe7 22. Bg2 Bd6 23. Bd2 Qe6 24. b3 Nbd5 25. Ne2  Nb4 26. Qb1 Qf5  27. e4 Qc5 28. Nf4  g5  29. Ne2 g4 30. h4 Nd7  31. Be3 Qc2 32. Qxc2 Nxc2 33. Bxa7 Ba3 34. Nc3 Bb2 35. Nd1 Bc1 36. Bf1 Nb4 37. a4 Nf6 38. e5 Nd7 39. Bd4 Nc2 40. Bc3 Nc5 41. Be2 Ne4 42. Bxg4 Nxc3 43. Nxc3 Bb2 44. e6  fxe6 45. Bxe6+ Kf8 46. Ne4 Nd4 47. Ng5 Ke7 48. Bg8 Kf8 49. Bc4 Ke7 50. Kg2 b5 51. Bg8 Kf8 52. a5  1-0 "

; sample game 515
EventSites(515) = "Tata Steel-B 74th  Wijk aan Zee" : GameDates(515) = "20120122" : WhitePlayers(515) = "Motylev, Alexander   G#515" : WhiteElos(515) = "2677" : BlackPlayers(515) = "Vocaturo, Daniele   G#515" : BlackElos(515) = "2545" : Each_Game_Result(515) = "1-0"

FilePGNs(515) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. d3  d6 7. c3 O-O 8. Re1 b5 9. Bc2 Re8 10. a4 Bd7 11. Nbd2 Bf8 12. Nf1 g6  13. Bg5  Bg7 14. Qd2 Qc8 15. Ng3 Qb7 16. b4 Bg4 17. Bb3  Nd8 18. d4 Bxf3 19. gxf3 Ne6 20. Be3 Nd7 21. f4  exf4 22. Bxf4 Nxf4  23. Qxf4 Nf6 24. h4  Re7 25. h5 Rae8 26. axb5 axb5 27. Re3 Qc8 28. h6  Bh8 29. e5  dxe5 30. dxe5 Ng4  31. e6  f5 32. Nxf5  gxf5 33. Rg3  Be5 34. Qxe5 Rf8 35. Rxg4+ 1-0 "

; sample game 516
EventSites(516) = "Tata Steel-A 74th  Wijk aan Zee" : GameDates(516) = "20120125" : WhitePlayers(516) = "Giri, Anish   G#516" : WhiteElos(516) = "2714" : BlackPlayers(516) = "Aronian, Levon   G#516" : BlackElos(516) = "2805" : Each_Game_Result(516) = "0-1"

FilePGNs(516) = "1. d4 d5 2. c4 e6 3. Nc3 Be7 4. Nf3 Nf6 5. Bf4 O-O 6. e3 Nbd7 7. Be2 dxc4 8. O-O Nb6 9. Qc2 Nh5 10. Be5 f6 11. Ng5 fxg5 12. Bxh5 Bd7 13. Bf3 Rxf3 14. gxf3 Bd6 15. Qe4 Bc6 16. Qg4 Qe7 17. Bxd6 cxd6 18. Ne4 h6 19. Qg3 d5 20. Nc3 Rf8 21. Ne2 Rf5 22. Kg2 Nd7 23. Rh1 Nf8 24. h4 Ng6 25. f4 Nxh4+ 26. Kf1 Qb4 27. Rb1 Be8 28. Nc3 Qe7 29. b4 Rf8 30. Rb2 Bg6 31. Ke1 Bd3 32. fxg5 Nf3+ 33. Kd1 hxg5 34. Qh3 Qf6 35. Kc1 Bg6 36. a4 Rd8 37. Ne2 e5 38. Qg4 exd4 39. exd4 Re8 40. Qd7 c3 41. Ra2 Ne1 42. Rxe1 Qf4+ 43. Kd1 Qe4 0-1 "

; sample game 517
EventSites(517) = "Gibraltar Masters 10th  Caleta" : GameDates(517) = "20120127" : WhitePlayers(517) = "Le Quang, Liem   G#517" : WhiteElos(517) = "2714" : BlackPlayers(517) = "Felgaer, Ruben   G#517" : BlackElos(517) = "2571" : Each_Game_Result(517) = "1-0"

FilePGNs(517) = "1. d4 d5 2. c4 c6 3. Nc3 dxc4 4. e4 b5 5. a4 b4 6. Nb1 Ba6 7. Qc2 e5 8. Nf3 b3 9. Qc3 Qb6 10. a5 Qb7 11. Bd2 exd4 12. Qxd4 c5 13. Qd5 Nc6 14. Bxc4 Nf6 15. Qd3 Nb4 16. Bxb4 Qxb4+ 17. Nbd2 Bxc4 18. Qxc4 Qxc4 19. Nxc4 Nxe4 20. O-O Be7 21. Rfe1 f5 22. Ra3 O-O 23. Rxb3 Rab8  24. Rxb8 Rxb8 25. Nfe5 Rb4 26. Rd1 Bf6  27. f3 Ng5 28. Rd7 Nf7 29. Nxf7 Rxc4 30. Rxa7 Bd4+ 31. Kf1 Rc1+ 32. Ke2 c4 33. Rb7 Rc2+ 34. Kd1 Rxg2 35. Nd6  g6 36. Nxc4 Rxh2 37. a6 Rh1+ 38. Ke2 Ra1 39. Rd7  Bg1 40. Rd1 Rxd1 41. Kxd1 Kf7 42. Ke2 f4 43. Kf1 Bd4 44. b4 Ke6 45. b5 Kd5 46. b6 Kc6 47. a7 Kb7 48. Na5+ Ka8 49. b7+ Kxa7 50. Nc6+ Kxb7 51. Nxd4 g5 52. Ne6 h6 53. Nd8+ Kc7 54. Nf7 1-0 "

; sample game 518
EventSites(518) = "Gibraltar Masters 10th  Caleta" : GameDates(518) = "20120202" : WhitePlayers(518) = "Berg, Emanuel   G#518" : WhiteElos(518) = "2550" : BlackPlayers(518) = "Vachier Lagrave, Maxime   G#518" : BlackElos(518) = "2699" : Each_Game_Result(518) = "1-0"

FilePGNs(518) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bg5 e6 7. f4 h6 8. Bh4 Qb6 9. Qd3  Qxb2 10. Rb1 Qa3 11. f5 Be7 12. fxe6 fxe6 13. Be2 O-O 14. O-O Kh8  15. Kh1 Nbd7  16. Nxe6  Ne5 17. Nxf8  Nxd3 18. Ng6+ Kh7 19. Bxd3 Kxg6 20. e5+ Kh5 21. exf6 Bxf6 22. Bxf6 gxf6 23. Rb3 Qa5 24. Rxf6 Bd7 25. Ne4 Bg4 26. h3 Rg8 27. hxg4+ Rxg4 28. Be2  Qe1+ 29. Kh2 1-0 "

; sample game 519
EventSites(519) = "Moscow Aeroflot op-A 11th  Moscow" : GameDates(519) = "20120213" : WhitePlayers(519) = "Bartel, Mateusz   G#519" : WhiteElos(519) = "2658" : BlackPlayers(519) = "Caruana, Fabiano   G#519" : BlackElos(519) = "2736" : Each_Game_Result(519) = "1-0"

FilePGNs(519) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. e3 Bg4 5. Nc3 e6 6. h3 Bh5 7. Qb3 Qc7 8. Nh4  Nbd7 9. Bd2 Nb6  10. cxd5 exd5  11. Rc1 Bg6 12. Nxg6 hxg6 13. Bd3 Be7 14. O-O Kf8  15. a4 a5 16. e4 dxe4 17. Nxe4 Rh5 18. Rfe1 Nxe4  19. Bxe4 Bd6 20. Qf3  Nxa4 21. Bxg6 Rh8  22. Bg5 1-0 "

; sample game 520
EventSites(520) = "Moscow Aeroflot op-A 11th  Moscow" : GameDates(520) = "20120215" : WhitePlayers(520) = "Sjugirov, Sanan   G#520" : WhiteElos(520) = "2622" : BlackPlayers(520) = "Sasikiran, Krishnan   G#520" : BlackElos(520) = "2700" : Each_Game_Result(520) = "0-1"

FilePGNs(520) = "1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Nf6 5. Nxc6 bxc6 6. e5 Qe7 7. Qe2 Nd5 8. c4 Nb6 9. Nc3 Bb7 10. Bd2 O-O-O  11. O-O-O Kb8  12. h4 Re8 13. Rh3 Ba6 14. Qg4 Bc8  15. Rg3 Qc5 16. Ne4  Qxe5 17. Ng5 f5  18. Qf3 Rg8  19. Bc3 Qc5 20. b4  Qe7 21. Qxf5 g6 22. Qf4 Bh6 23. Re3 Qf8 24. Qxf8 Rexf8 25. f3 Rf4 26. Rd4  Rxh4  27. Rxh4 Bxg5 28. Re4 Bxe3+ 29. Rxe3 Ba6 30. Re7 Bxc4 31. Bxc4 Nxc4 32. Rxd7 h5 33. Re7 Nb6  34. Bd2   Kc8  35. a3 Nd5 36. Rf7 Re8 37. Rg7 Re6 38. Kc2 Kb7 39. g4 hxg4 40. fxg4 Kb6 41. Kb3 a6 42. Rg8  c5 43. g5 Kc6 44. Bc1 Nb6 45. bxc5 Kxc5 46. Bb2 Nd5 47. Bh8 Rb6+ 48. Kc2 Re6 49. Kb3 c6  50. Bb2 Nf4 51. Bc1 Nd5 52. Bb2 a5  53. Bh8  a4+  54. Kxa4  Re3  55. Rb8 Rh3 56. Bb2 Nb6+ 57. Ka5 Rb3 0-1 "

; sample game 521
EventSites(521) = "POL-ch  Warsaw" : GameDates(521) = "20120223" : WhitePlayers(521) = "Socko, Bartosz   G#521" : WhiteElos(521) = "2636" : BlackPlayers(521) = "Bartel, Mateusz   G#521" : BlackElos(521) = "2658" : Each_Game_Result(521) = "0-1"

FilePGNs(521) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. d3 Be7 5. Nbd2 O-O 6. O-O d6 7. Bb3 Na5 8. Ba4 c5 9. c3 Rb8  10. d4 b5 11. Bc2 Qc7 12. d5 c4  13. h3 Nb7 14. Re1 Bd7 15. Nf1 Nc5 16. g4  Nfxe4  17. Bxe4  Nxe4 18. Rxe4 f5 19. gxf5 Bxf5 20. Ng3 Qd7  21. Re1 Bxh3 22. Nh2 Rf6  23. Be3 Rbf8  24. a4  Rg6 25. Qh5  bxa4 26. Ra2 Bd8  27. Rea1 Bb6  28. Bxb6 axb6 29. Rxa4 Qf7 30. Qe2  h5  31. Ra8 h4 32. Rxf8+ Qxf8 33. Qf3 hxg3 34. fxg3 Qxf3 35. Nxf3 Rxg3+ 36. Kf2 Rg2+ 37. Ke3 Bg4 38. Ra8+ Kf7 39. Ra7+ Kf6 0-1 "

; sample game 522
EventSites(522) = "ISR-chT 1112  Israel" : GameDates(522) = "20120302" : WhitePlayers(522) = "Sutovsky, Emil   G#522" : WhiteElos(522) = "2696" : BlackPlayers(522) = "Finkel, Alexander   G#522" : BlackElos(522) = "2499" : Each_Game_Result(522) = "1-0"

FilePGNs(522) = "1. e4 Nf6 2. e5 Nd5 3. d4 d6 4. Nf3 dxe5 5. c4  e4 6. cxd5 exf3 7. Qxf3 c6 8. Bc4 cxd5 9. Bxd5 e6 10. Bxb7 Qc7 11. Bxc8  Qxc1+ 12. Ke2 Qc4+ 13. Kd1 Nc6  14. Nd2 Qb5 15. a4  Qb6 16. Bxe6  fxe6 17. Re1 Kd7 18. d5 exd5 19. Qf5+  Kc7 20. Qf7+ Be7 21. Rxe7+ Nxe7 22. Qxe7+ Kb8 23. Ra3  1-0 "

; sample game 523
EventSites(523) = "EU-ch 13th  Plovdiv" : GameDates(523) = "20120321" : WhitePlayers(523) = "Zoler, Dan   G#523" : WhiteElos(523) = "2541" : BlackPlayers(523) = "Jones, Gawain C   G#523" : BlackElos(523) = "2635" : Each_Game_Result(523) = "0-1"

FilePGNs(523) = "1. d4 Nf6 2. c4 g6 3. g3 Bg7 4. Bg2 O-O 5. Nc3 d6 6. Nf3 Nc6 7. O-O Rb8 8. Re1 a6 9. Rb1 Na5  10. Qa4 b6 11. c5 Bd7 12. Qa3 Nc4  13. Qxa6 b5 14. Nh4 dxc5 15. dxc5 c6  16. Bxc6 Qc7 17. Bxd7 Nxd7 18. Nd5 Qxc5 19. Qc6 Qa7 20. Nxe7+ Kh8 21. Qg2 Rbe8 22. Bg5 Qc5 23. Qd5 Qxd5 24. Nxd5 Re5 25. Be7 Rxd5 26. Bxf8  Nxf8 27. b3 Na3 28. Rbd1 Rc5 29. Rc1 Bc3 30. Red1 b4 31. Rd8 Kg7 32. Nf3 Ne6 33. Rd7 g5  34. h3 h5 35. Rcd1 Bf6 36. Rb7 Nb5 37. e3  Kg6 38. Kg2 Nc3 39. Rd2 Ne4 40. Re2 Bc3 41. Ra7 Rd5  42. a3 bxa3 43. Rxa3 N6c5 44. Rc2 g4 45. hxg4 hxg4 46. Nh4+ Kg7 47. f3 Nd3  48. Re2 gxf3+ 49. Nxf3 Rd6 50. Ra4 Bb4 51. Nd4 Rg6 52. Ra7  Ne1+  53. Kh2 Rh6+ 54. Kg1 Nxg3 55. Rh2 Rg6 56. Kf2 Nd3+ 57. Kg1 Bd6 58. Rg2  Be5  59. Nf3 Bd6 60. Rd7 Nc1 61. Rxd6  Nce2+ 62. Kf2 Ne4+  63. Kf1 N2g3+ 64. Ke1 Rxd6 65. Nd4 Kf8 66. Ra2 Rh6 67. Ra8+ Kg7 68. Kd1 Rh2 69. b4 Nc3+ 70. Ke1 Nge4 71. Kf1 Nd5 72. Kg1 Rb2 73. b5 Nxe3 74. Rd8 Rg2+ 0-1 "

; sample game 524
EventSites(524) = "EU-ch 13th  Plovdiv" : GameDates(524) = "20120322" : WhitePlayers(524) = "Rakhmanov, Alexander   G#524" : WhiteElos(524) = "2602" : BlackPlayers(524) = "Jakovenko, Dmitrij   G#524" : BlackElos(524) = "2729" : Each_Game_Result(524) = "1/2-1/2"

FilePGNs(524) = "1. c4 c6 2. d4 d5 3. Nf3 Nf6 4. cxd5 cxd5 5. Nc3 Nc6 6. Bf4 Bf5 7. e3 e6 8. Bb5 Nd7 9. Qb3 Be7 10. O-O g5  11. Bg3 h5 12. h3 g4 13. hxg4 hxg4 14. Nd2 Kf8 15. Rfc1 Kg7 16. Ne2 Rc8 17. Bxc6 bxc6 18. Qb7 Rh7 19. Bf4 c5  20. e4  dxe4 21. Nxe4 e5  22. N4g3  Be6  23. Bxe5+ Nxe5 24. dxe5 Bg5 25. Rd1 Qb6 26. Qe4 Qb4 27. Qxb4 cxb4 28. Nd4 Bd7 29. Nf3  gxf3 30. Rxd7 Bf4  31. e6 Kg6 32. e7 Bxg3 33. fxg3 Rc2  34. gxf3 Re2  35. Rd2 Rxe7 36. Rc1 f6 37. Kg2 Rd7 38. Re2  Rhe7 39. Rxe7  Rxe7 40. Kf2 Rh7 41. Kg2 Rd7 42. Rc2 b3  43. axb3 Rd3 44. Rc3 Rd2+ 45. Kh3 Rxb2 46. Kg4 Rd2 47. f4 Rd4 48. Kh4 a5 49. Rf3 a4 50. bxa4 Rxa4 51. g4 Ra1 52. f5+ Kh6 53. Rh3 Kg7 54. Rb3 Ra7 55. Kh5 Rc7 56. Rb6 Ra7 57. Rc6 Rb7 58. Ra6 Rc7 59. Re6 Ra7 60. g5 fxg5 61. Kxg5 Ra1 62. Re7+ Kf8 63. Kf6 Rf1  64. Ra7 Kg8 65. Ra8+ Kh7 66. Ra2 Kg8 67. Ra8+ Kh7 68. Rf8 Ra1 69. Rf7+ Kg8 70. Re7 Rf1 71. Re5 Kf8 72. Ra5 Kg8 73. Ra8+ 1/2-1/2 "

; sample game 525
EventSites(525) = "EU-ch 13th  Plovdiv" : GameDates(525) = "20120323" : WhitePlayers(525) = "L'Ami, Erwin   G#525" : WhiteElos(525) = "2611" : BlackPlayers(525) = "Tomic, Bosko   G#525" : BlackElos(525) = "2404" : Each_Game_Result(525) = "1-0"

FilePGNs(525) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 O-O 5. Nf3 d6 6. Be2 c5 7. O-O Nc6 8. d5 Na5 9. h3 e6 10. Bd3  a6 11. Bd2 exd5 12. exd5 b5 13. b3  Bd7 14. Ne2 Qc7 15. Bc3 Rae8 16. Ng3 Nh5 17. Bxg7 Nxg7 18. Qd2  Nb7 19. Qh6 f6 20. Nh4  Re7 21. Bxg6 hxg6 22. Nxg6 Ree8 23. Nh5 Nxh5 24. Qxh5 Kg7 25. Nxf8 Kxf8 26. Qh8+ Ke7 27. Rae1+ Kd8 28. Qxf6+ Kc8 29. Rxe8+ Bxe8 30. Re1 Bd7 31. h4 Qa5 32. Qa1 bxc4 33. bxc4 Qd2 34. Rb1 Bf5 35. Rb3 Qh6 36. Qb2 Nd8 37. Rb8+ Kd7 38. Ra8 Qxh4 39. Qg7+ Ke8 40. Ra7 1-0 "

; sample game 526
EventSites(526) = "EU-ch 13th  Plovdiv" : GameDates(526) = "20120327" : WhitePlayers(526) = "Nisipeanu, Liviu Dieter   G#526" : WhiteElos(526) = "2643" : BlackPlayers(526) = "Prohaszka, Peter   G#526" : BlackElos(526) = "2553" : Each_Game_Result(526) = "1-0"

FilePGNs(526) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. d3 Bc5 5. c3 O-O 6. Nbd2 d6 7. h3 a6 8. Ba4 b5 9. Bc2 Re8 10. O-O Bb6 11. Re1 h6 12. Nf1 d5 13. exd5 Qxd5 14. Ng3 Bb7 15. Bd2 Rad8 16. Qc1  Qc5  17. Re2 Ne7  18. Nxe5 Nf5  19. Nxf5 Rxe5 20. d4 Qc6 21. Ne3 Rh5 22. Qf1 Qd7 23. Rae1 c5 24. Ng4   cxd4 25. Nxf6+ gxf6 26. Re7 Qc8 27. Qd3 f5 28. Qg3+ Kf8 29. Bb3 Bd5 30. Qe5 1-0 "

; sample game 527
EventSites(527) = "EU-ch 13th  Plovdiv" : GameDates(527) = "20120329" : WhitePlayers(527) = "Inarkiev, Ernesto   G#527" : WhiteElos(527) = "2695" : BlackPlayers(527) = "Sokolov, Ivan   G#527" : BlackElos(527) = "2657" : Each_Game_Result(527) = "1-0"

FilePGNs(527) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nge7 4. Nc3 d6 5. d4 a6 6. Be2 Nxd4 7. Nxd4 exd4 8. Qxd4 Nc6 9. Qd3 g6 10. h4   Bg7 11. Bg5 f6 12. Be3 Be6  13. Nd5 Qd7 14. O-O-O f5 15. h5 Ne5  16. Qb3 Bxd5 17. Qxd5 O-O-O 18. Bg5  c6  19. Qb3  Rdf8 20. f4   h6 21. fxe5 hxg5 22. Rxd6 Qc7 23. Rhd1  Rd8 24. hxg6 Kb8 25. Rxd8+ Rxd8 26. Rxd8+ Qxd8 27. Bxa6 Qc7 28. Qxb7+  Qxb7 29. Bxb7 Bxe5 30. Bxc6 Kc7 31. Bd5 Kd6 32. b4 g4 33. Kd2 f4 34. Ke2 Ke7 35. Bc6 Kf6 36. Bd7 Kxg6 37. Bxg4 Kf6 38. Kd3 1-0 "

; sample game 528
EventSites(528) = "EU-ch 13th  Plovdiv" : GameDates(528) = "20120329" : WhitePlayers(528) = "Esen, Baris   G#528" : WhiteElos(528) = "2555" : BlackPlayers(528) = "Postny, Evgeny   G#528" : BlackElos(528) = "2662" : Each_Game_Result(528) = "0-1"

FilePGNs(528) = "1. d4 d5 2. Nf3 Nf6 3. c4 dxc4 4. e3 e6 5. Bxc4 a6 6. a4 b6 7. O-O Bb7 8. Nc3 c5 9. Qe2 Nbd7 10. Rd1 Qc7 11. e4 cxd4 12. Nxd4 Bc5 13. Bxe6  fxe6 14. Nxe6 Qe5 15. Nxg7+ Kf7 16. Nf5 Rag8   17. Be3 Rxg2+  18. Kxg2 Qxf5 19. f3 Qh5 20. Kh1 Ne5 21. Rf1 Rg8 22. Bf4  Bc8   23. Be3 Bxe3 24. Qxe3 Qh3 0-1 "

; sample game 529
EventSites(529) = "EU-ch 13th  Plovdiv" : GameDates(529) = "20120330" : WhitePlayers(529) = "Kuzubov, Yuriy   G#529" : WhiteElos(529) = "2615" : BlackPlayers(529) = "Azarov, Sergei   G#529" : BlackElos(529) = "2667" : Each_Game_Result(529) = "0-1"

FilePGNs(529) = "1. d4 d5 2. c4 e6 3. Nc3 Be7 4. cxd5 exd5 5. Bf4 Nf6 6. e3 Bf5 7. Nge2 O-O 8. Ng3 Be6 9. Be2 c5  10. dxc5 Bxc5 11. O-O Nc6 12. Rc1 d4   13. Nce4 Bb6 14. Bg5 dxe3 15. Nxf6+ gxf6 16. Bxe3 Qxd1 17. Bxd1 Rfd8 18. Ne4 Kg7 19. a3 Rac8 20. Nc5  Bxc5 21. Rxc5 b6 22. Rc3  Ne5 23. Rxc8 Rxc8 24. Re1 b5 25. h3 a5 26. Be2 Bc4 27. Bd4 Nc6 28. Bg4 Be6 29. Bxe6 fxe6 30. Rc1 Kf7 31. Rc5 b4 32. a4  e5 33. Be3 Ke6 34. g4 f5  35. gxf5+ Kxf5 36. Kf1 Ke6  37. b3  Kd6  38. Rc4 Rg8 39. Rh4 Rg7 40. Ke2 Kd5  41. Kd3 Rf7 42. Rh6  Nd4  43. Rh5 Ne6  44. Kc2  Rc7+ 45. Kb2 Ke4 46. Bb6 Rf7 47. Bxa5 Rxf2+ 48. Kb1 Rf1+ 49. Kb2 Nf4 50. Rxh7 Nd3+ 51. Kc2  Ke3 52. Bb6+ Ke2 0-1 "

; sample game 530
EventSites(530) = "RUS-chT 19th  Sochi" : GameDates(530) = "20120413" : WhitePlayers(530) = "Rublevsky, Sergei   G#530" : WhiteElos(530) = "2686" : BlackPlayers(530) = "Bologan, Viktor   G#530" : BlackElos(530) = "2687" : Each_Game_Result(530) = "1/2-1/2"

FilePGNs(530) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Nd2 e6 5. Nb3 Nd7 6. Nf3 Qc7  7. Be2 c5  8. dxc5 Bxc5 9. Nxc5 Qxc5  10. c3 Ne7 11. O-O O-O 12. Bf4 Bg4  13. Re1 Ng6 14. Bg3 b5 15. Rc1 Rac8 16. Qd2 Qb6 17. h3 Bh5  18. Bh2 Bxf3 19. Bxf3 Rc6  20. Bg3 Rfc8 21. a3  a5 22. h4  Nc5 23. Rcd1 Ne7 24. Qg5 R6c7 25. Bf4 b4 26. axb4 axb4 27. h5 bxc3 28. h6 Ng6 29. bxc3 Na4 30. Be3 Qa5 31. hxg7 Nxc3 32. Ra1 Qb4 33. g3  Qb2 34. Kg2 Ne4 35. Bxe4 dxe4 36. Ra5 Rd7 37. Qh5  f5  38. exf6 Qxf6 39. Bg5 Qc3 40. Rc1 Qf3+ 41. Qxf3 exf3+ 42. Kxf3 Rxc1 43. Bxc1 1/2-1/2 "

; sample game 531
EventSites(531) = "RUS-chT 19th  Sochi" : GameDates(531) = "20120413" : WhitePlayers(531) = "Jakovenko, Dmitrij   G#531" : WhiteElos(531) = "2729" : BlackPlayers(531) = "Karjakin, Sergey   G#531" : BlackElos(531) = "2766" : Each_Game_Result(531) = "0-1"

FilePGNs(531) = "1. Nf3 Nf6 2. c4 b6 3. g3 c5 4. Bg2 Bb7 5. O-O g6 6. Nc3 Bg7 7. d4 cxd4 8. Qxd4 d6 9. Rd1 Nbd7 10. Be3 Rc8 11. Rac1 a6 12. b3 O-O 13. Qh4 Rc7 14. g4 Rc8 15. Bh3 b5 16. cxb5 Qa5 17. Bd2 Bxf3 18. exf3 axb5 19. g5 b4 20. gxf6 Bxf6 21. Qe4 bxc3 22. Bxd7 Rcd8 23. Bxc3 Bxc3 24. Qxe7 d5 25. Bb5  d4 26. a4 Rd5 27. Qe4 Rf5 28. Kh1 Qb6 29. Rg1 Qf6 30. Rg3 Rd8 31. Bd3 Rf4 32. Qb7 Qd6 33. Kg2 Rb8 34. Qa6 Qxa6 35. Bxa6 Rxb3 36. Rg4 Rf6 37. Bb5 Kg7 38. Re4  d3  39. Rd1  d2 40. Re3 Rd6 41. Be2 Re6 42. Rxe6  fxe6 43. Bc4 Rb4 44. Bxe6 Rxa4 45. Bd5 Rd4 46. Be4 Bb4 47. Kf1 Bd6 48. Ke2 Bf4 49. h3 Kh6 50. Rg1 Rc4 51. Bd3 Rc1 52. Rd1 Kg5 53. Bb5 Kh4 0-1 "

; sample game 532
EventSites(532) = "Bundesliga 1112  Germany" : GameDates(532) = "20120414" : WhitePlayers(532) = "Tiviakov, Sergei   G#532" : WhiteElos(532) = "2673" : BlackPlayers(532) = "Anand, Viswanathan   G#532" : BlackElos(532) = "2799" : Each_Game_Result(532) = "1-0"

FilePGNs(532) = "1. e4 c5 2. Nf3 d6 3. Bb5+ Nd7 4. d4 cxd4 5. Qxd4 a6 6. Bxd7+ Bxd7 7. c4 e5 8. Qd3 h6 9. Nc3 Nf6 10. O-O Be7 11. a4 b6  12. b3  Ra7  13. Rd1 Bc8  14. Ba3 Rd7 15. Nd2 O-O 16. Nf1 Bb7 17. Ne3 Re8 18. Ncd5 Nxd5 19. Nxd5 Bxd5  20. Qxd5 Qa8 21. Qxa8 Rxa8 22. Rd5 f6 23. Rad1 Rad8  24. g3  g5 25. f4 gxf4 26. gxf4 Kf7 27. Kf2 exf4 28. Kf3 Ke6 29. Bc1  Rc8 30. Bxf4 Bf8 31. h4  Rc6 32. h5 Rb7 33. Be3 Rb8 34. Bd4 Rc7 35. Rg1 Bg7 36. Rg6 Rf7 37. Be3 Rd7 38. Rf5 Rf7 39. Kg4 Bf8 40. Bxh6 Bxh6 41. Rxh6 Rg7+ 42. Kf4 Rf8 43. a5  Rg1 44. axb6 Rb1 45. b7 Rxb3 46. e5 dxe5+ 47. Rxe5+ Kd6 48. Rf5 Ke6 49. Rh7 Rd8 50. Rd5 1-0 "

; sample game 533
EventSites(533) = "World Championship  Moscow" : GameDates(533) = "20120517" : WhitePlayers(533) = "Anand, Viswanathan   G#533" : WhiteElos(533) = "2791" : BlackPlayers(533) = "Gelfand, Boris   G#533" : BlackElos(533) = "2727" : Each_Game_Result(533) = "1/2-1/2"

FilePGNs(533) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5 6. Ndb5 d6 7. Bg5 a6 8. Na3 b5 9. Nd5 Be7 10. Bxf6 Bxf6 11. c4 b4 12. Nc2 O-O 13. g3 a5 14. Bg2 Bg5 15. O-O Be6 16. Qd3 Bxd5 17. cxd5 Nb8 18. a3 Na6 19. axb4 Nxb4 20. Nxb4 axb4 21. h4 Bh6 22. Bh3 Qb6 23. Bd7 b3 24. Bc6 Ra2  25. Rxa2 bxa2 26. Qa3 Rb8 27. Qxa2 1/2-1/2 "

; sample game 534
EventSites(534) = "World Championship  Moscow" : GameDates(534) = "20120520" : WhitePlayers(534) = "Gelfand, Boris   G#534" : WhiteElos(534) = "2739" : BlackPlayers(534) = "Anand, Viswanathan   G#534" : BlackElos(534) = "2799" : Each_Game_Result(534) = "1-0"

FilePGNs(534) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. e3 e6 5. Nf3 a6 6. c5 Nbd7 7. Qc2  b6 8. cxb6 Nxb6 9. Bd2 c5 10. Rc1 cxd4 11. exd4 Bd6 12. Bg5 O-O 13. Bd3 h6 14. Bh4 Bb7 15. O-O Qb8  16. Bg3  Rc8 17. Qe2 Bxg3 18. hxg3 Qd6 19. Rc2 Nbd7 20. Rfc1 Rab8  21. Na4 Ne4  22. Rxc8+ Bxc8 23. Qc2  g5  24. Qc7 Qxc7  25. Rxc7 f6  26. Bxe4  dxe4 27. Nd2 f5 28. Nc4 Nf6 29. Nc5 Nd5 30. Ra7 Nb4 31. Ne5  Nc2  32. Nc6 Rxb2 33. Rc7 Rb1+  34. Kh2 e3 35. Rxc8+ Kh7 36. Rc7+ Kh8 37. Ne5 e2 38. Nxe6  1-0 "

; sample game 535
EventSites(535) = "World Championship  Moscow" : GameDates(535) = "20120521" : WhitePlayers(535) = "Anand, Viswanathan   G#535" : WhiteElos(535) = "2791" : BlackPlayers(535) = "Gelfand, Boris   G#535" : BlackElos(535) = "2727" : Each_Game_Result(535) = "1-0"

FilePGNs(535) = "1. d4 Nf6 2. c4 g6 3. f3 c5 4. d5 d6 5. e4 Bg7 6. Ne2 O-O 7. Nec3  Nh5  8. Bg5 Bf6 9. Bxf6 exf6 10. Qd2  f5 11. exf5 Bxf5 12. g4  Re8+  13. Kd1 Bxb1 14. Rxb1 Qf6  15. gxh5  Qxf3+ 16. Kc2 Qxh1 17. Qf2 1-0 "

; sample game 536
EventSites(536) = "Moscow Tal Memorial 7th  Moscow" : GameDates(536) = "20120608" : WhitePlayers(536) = "Radjabov, Teimour   G#536" : WhiteElos(536) = "2784" : BlackPlayers(536) = "Tomashevsky, Evgeny   G#536" : BlackElos(536) = "2738" : Each_Game_Result(536) = "1-0"

FilePGNs(536) = "1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Bc5 5. Nb3 Bb6 6. Nc3 d6 7. Qe2 Nge7 8. Be3 O-O 9. O-O-O f5 10. exf5 Bxf5 11. h3  Bd7  12. Qd2  Bxe3 13. Qxe3 Kh8 14. Bd3 Qe8 15. f4 Qf7 16. Rhf1 Rae8 17. Qd2 Nb4 18. Be4 Bc6 19. Rde1  Bxe4 20. Nxe4 Qc4 21. a3 Nbc6 22. Qc3 Qd5  23. Nbd2  Nf5 24. g4 Nfd4 25. Qd3  b5 26. Kb1 b4 27. a4  h6 28. Nb3 Re7  29. Ned2   Rxe1+ 30. Rxe1 g5 31. f5 1-0 "

; sample game 537
EventSites(537) = "FRA-chT Top 12  Belfort" : GameDates(537) = "20120609" : WhitePlayers(537) = "Riazantsev, Alexander   G#537" : WhiteElos(537) = "2714" : BlackPlayers(537) = "Edouard, Romain   G#537" : BlackElos(537) = "2625" : Each_Game_Result(537) = "0-1"

FilePGNs(537) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. Bd2 Bg7 6. e4 Nxc3 7. Bxc3 O-O  8. Qd2 c5 9. d5 Bxc3 10. bxc3 Qd6  11. f4   Nd7  12. e5 Qc7 13. h4 c4 14. h5 Nb6 15. Nf3 Bg4 16. hxg6 fxg6 17. Ng5 Rad8  18. d6  exd6 19. Rxh7 Qc5 20. Rh6  dxe5 21. Rxg6+ Kh8 22. Nf7+ Kh7 23. Rh6+  Kg7 24. Nxd8 Rxd8 25. Rh4 Rxd2 26. Rxg4+ Kf8 27. Kxd2 Qf2+ 28. Be2 Nd5 29. Rh1 Qe3+ 30. Ke1 Qxc3+ 31. Kf2 Qe3+ 32. Ke1 Nxf4 33. Rh8+ Kf7 34. Rxf4+ exf4 35. Rh7+ Kf6 36. Rxb7 c3 0-1 "

; sample game 538
EventSites(538) = "Moscow Tal Memorial 7th  Moscow" : GameDates(538) = "20120610" : WhitePlayers(538) = "Aronian, Levon   G#538" : WhiteElos(538) = "2825" : BlackPlayers(538) = "McShane, Luke J   G#538" : BlackElos(538) = "2706" : Each_Game_Result(538) = "0-1"

FilePGNs(538) = "1. d4 d5 2. Nf3 Nf6 3. c4 c6 4. Nc3 a6 5. Bg5 dxc4 6. a4 h6 7. Bh4 b5 8. axb5 cxb5 9. Nxb5 axb5 10. Rxa8 Bb7 11. Ra1 g5 12. Bg3 e6 13. e3 Bb4+ 14. Ke2 Nc6 15. Ne1 Na5 16. Be5 O-O 17. h4 g4 18. Nc2 Be7 19. Ke1 Nb3 20. Ra2 h5 21. Be2 Bd6  22. f3 Nd5 23. fxg4 Bxe5 24. dxe5 Qb6 25. Bf3 Nxe3 26. Nxe3 Qxe3+ 27. Qe2 Qc1+ 28. Qd1 Qe3+ 29. Qe2 Qc1+ 30. Qd1 Bxf3 31. gxf3 Qe3+ 32. Qe2 Qc1+ 33. Qd1 Qe3+ 34. Qe2 Qf4 35. Qh2 Qxf3 36. Rf1 Qe4+ 37. Kf2 Nd2 38. Rg1 Qf3+ 0-1 "

; sample game 539
EventSites(539) = "Moscow Tal Memorial 7th  Moscow" : GameDates(539) = "20120613" : WhitePlayers(539) = "Aronian, Levon   G#539" : WhiteElos(539) = "2825" : BlackPlayers(539) = "Morozevich, Alexander   G#539" : BlackElos(539) = "2769" : Each_Game_Result(539) = "0-1"

FilePGNs(539) = "1. d4 d5 2. c4 e6 3. Nc3 c6 4. e3 Nd7 5. Nf3 f5 6. Bd3 Nh6 7. b3 Bd6 8. Bb2 O-O 9. O-O Rf6 10. Qc2 Nf7 11. Nd2 e5  12. Bxf5 e4 13. Bxh7+  Kxh7 14. cxd5 Rg6  15. Ndxe4 Nf6 16. Nxf6+ Qxf6 17. f4 Nh6 18. Ne4 Qf5 19. dxc6 Be7 20. c7 Rc6 21. Qb1 Rxc7 22. Nc3  Qxb1 23. Raxb1 Rd7 24. Rbd1 b6 25. e4 Bb7 26. h3 Ng8 27. e5 Rc8 28. d5 Bb4 29. e6 Rdd8 30. Ne4 Rxd5 31. Ng5+ Kg6 32. Rxd5 Bxd5 33. Rd1 Ne7 34. Bd4 Rc2 35. g4 Bd2 36. Rf1 Bc1 37. Nf3 Bxf4 38. Nh4+ Kg5 39. Nf3+ Kh6 40. h4 Rxa2 0-1 "

; sample game 540
EventSites(540) = "Voronezh op 16th  Voronezh" : GameDates(540) = "20120616" : WhitePlayers(540) = "Zakhartsov, Viacheslav V   G#540" : WhiteElos(540) = "2562" : BlackPlayers(540) = "Baryshpolets, Andrey   G#540" : BlackElos(540) = "2487" : Each_Game_Result(540) = "0-1"

FilePGNs(540) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. d5 a5 8. h3 Na6 9. Bg5 Qe8 10. Nd2 Kh8 11. h4 h6  12. Be3 Ng8 13. g4 f5 14. gxf5 gxf5 15. exf5 Bxf5 16. Nde4 Nf6 17. Nxf6 Rxf6 18. Bd3 e4 19. Be2 Nc5 20. Qd2 a4 21. Nb5 Nd3+ 22. Bxd3 exd3 23. O-O-O a3 24. Bd4 axb2+ 25. Qxb2 d2+ 26. Rxd2 Ra4  27. Rc2  Qe4  28. Rg1 Qf4+ 29. Be3 Rg6 30. Rxg6 Bxb2+ 31. Kxb2 Bxc2 32. Bxf4 Bxg6 33. Kb3 Bc2+  34. Kc3 Bd1 35. Kd3  Rxa2 36. Nc3  Rxf2 37. Bxh6 Bc2+ 38. Ke3 Rh2 39. Bg5 Rh3+ 40. Kd2 Bb3 41. Nb5 Bxc4 42. Nxc7 Kg8 43. Ne8 Kf8 44. Nxd6 Bxd5 45. Nf5 Kf7 46. Ne3 Ke6 47. Kc3 Kd6 48. Kd4 Be6 49. Bf4+ Kc6 50. Bg5 Rh1 51. Ke5 Bd7 52. Be7 Bc8 53. Kd4 Kb5 54. Nd5 Bd7 55. Nc3+ Kc6 56. Bg5 b5 57. Be7 b4 58. Ne4 Rd1+ 59. Ke5 b3 60. Ba3 Ra1 61. Bb2 Ra2 62. Bd4 Re2 63. Kf4 Kd5 64. Nc3+ Kxd4 65. Nxe2+ Kc4 66. Ng3 b2 67. Ne4 Kd3 0-1 "

; sample game 541
EventSites(541) = "Moscow Tal Memorial 7th  Moscow" : GameDates(541) = "20120617" : WhitePlayers(541) = "Grischuk, Alexander   G#541" : WhiteElos(541) = "2761" : BlackPlayers(541) = "Nakamura, Hikaru   G#541" : BlackElos(541) = "2775" : Each_Game_Result(541) = "1-0"

FilePGNs(541) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 g6 6. Be3 Bg7 7. f3 Nc6 8. Qd2 O-O 9. g4 Nxd4 10. Bxd4 Be6 11. Nd5  Bxd5 12. exd5 Qc7 13. h4 Rac8 14. Rh2  e5 15. dxe6 fxe6 16. O-O-O  e5 17. Be3 Qf7 18. Kb1 d5 19. h5 e4 20. hxg6 hxg6 21. Be2 Qe6 22. Bd4 Rc7 23. Rdh1 Rff7 24. a3 b6 25. fxe4 Qxe4 26. g5 Nh5 27. Bxg7 Kxg7 28. Bxh5 gxh5 29. Rxh5 Qc4 30. Qd1 Qe4 31. g6 Rfe7 32. R5h4 Qe5 33. Rh7+ Kg8 34. R7h5 Qe4 35. Qd2 1-0 "

; sample game 542
EventSites(542) = "Amsterdam ACP Golden Classic  Amsterdam" : GameDates(542) = "20120714" : WhitePlayers(542) = "Sasikiran, Krishnan   G#542" : WhiteElos(542) = "2707" : BlackPlayers(542) = "Muzychuk, Anna   G#542" : BlackElos(542) = "2606" : Each_Game_Result(542) = "0-1"

FilePGNs(542) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 e6 5. e3 Nbd7 6. Qc2 Bd6 7. Bd3 O-O 8. O-O dxc4 9. Bxc4 b5 10. Bd3 Bb7 11. a3 a5 12. e4 e5 13. Rd1 Qc7 14. h3 Rfd8  15. Bg5  h6 16. Be3 exd4 17. Nxd4 Ne5  18. Bf1 Ng6 19. Nf5 Bh2+ 20. Kh1 Be5 21. Rac1 Rxd1 22. Nxd1 Rd8 23. Nc3 Qb8 24. Bb6  Bc7 25. Be3  Bf4 26. a4  Qe5 27. Re1  b4 28. Bxf4 Qxf4 29. Nd1 Rd2  30. Qc1 c5 31. f3  Ne5  32. Be2 Bxe4 33. fxe4 Nxe4 34. Rf1 Qg5 35. h4 Qd8 36. Ba6 Rxd1 37. Rxd1 Qxd1+ 38. Qxd1 Nf2+ 39. Kg1 Nxd1 40. b3 c4 0-1 "

; sample game 543
EventSites(543) = "Dortmund SuperGM 40th  Dortmund" : GameDates(543) = "20120721" : WhitePlayers(543) = "Caruana, Fabiano   G#543" : WhiteElos(543) = "2775" : BlackPlayers(543) = "Kramnik, Vladimir   G#543" : BlackElos(543) = "2799" : Each_Game_Result(543) = "1-0"

FilePGNs(543) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. d3 Bc5 5. O-O d6 6. c3 O-O 7. Nbd2 Ne7 8. d4 exd4 9. cxd4 Bb6 10. b3 d5 11. e5 Ne4 12. Bd3 Bf5 13. Qe2 Nc6 14. Bb2 Nxd2 15. Qxd2 Be4 16. Be2  f6 17. b4  fxe5 18. dxe5 Kh8  19. b5 Ne7 20. Ng5 Ng6 21. g3  Qe7 22. e6 Rf5 23. Nxe4 dxe4 24. Qd7 Raf8 25. Qxe7 Nxe7 26. Ba3 Re8 27. Rad1 h5  28. Rd7 Nd5 29. Rf7 Nf6 30. Bc4 Bc5 31. Bb2 Re7 32. Bd4 Bd6 33. Re1 b6 34. Rf8+ Kh7 35. Rxe4 Rxf2  36. Kxf2  Nxe4+ 37. Kg2 Nc5 38. Ra8 Nxe6  39. Bd3+ Kh6 40. h4 g6 41. Rh8+ Rh7 42. Rg8 Rg7 43. Bxg7+ Kh7 44. Re8 Nxg7 45. Re3 Kh6 46. a4 Kh7 47. Kh3 Kh6 48. Bc2 Kh7 49. g4 hxg4+ 50. Kxg4 Kh6 51. Re2 Bb4 52. Re5 Nh5 53. Re6 1-0 "

; sample game 544
EventSites(544) = "Biel GM 45th  Biel" : GameDates(544) = "20120725" : WhitePlayers(544) = "Giri, Anish   G#544" : WhiteElos(544) = "2696" : BlackPlayers(544) = "Bacrot, Etienne   G#544" : BlackElos(544) = "2713" : Each_Game_Result(544) = "1-0"

FilePGNs(544) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. O-O Nc6 8. d5 Ne7 9. b4 Nh5 10. g3 f5 11. Ng5 Nf6 12. f3 f4 13. b5 fxg3 14. hxg3 h6 15. Ne6 Bxe6 16. dxe6 Qc8 17. Nd5 Qxe6 18. Nxc7 Qh3 19. Rf2  Rac8  20. Rh2  Qxg3+ 21. Rg2 Qh3 22. Qxd6 Rf7  23. c5 Nf5 24. exf5 Rfxc7 25. Be3  Qxf5  26. Rf1  Bf8  27. Bd3  e4 28. fxe4 Qxf1+ 29. Bxf1  Bxd6 30. cxd6 Rc3  31. Bd4 Rf3 32. e5  Rf4  33. Bb2  Nh7 34. e6 Ng5 35. Rxg5  hxg5 36. d7 Rg4+ 37. Bg2 1-0 "

; sample game 545
EventSites(545) = "Biel GM 45th  Biel" : GameDates(545) = "20120802" : WhitePlayers(545) = "Wang Hao   G#545" : WhiteElos(545) = "2739" : BlackPlayers(545) = "Giri, Anish   G#545" : BlackElos(545) = "2696" : Each_Game_Result(545) = "1-0"

FilePGNs(545) = "1. Nf3 Nf6 2. c4 g6 3. Nc3 d5 4. Qa4+ Bd7 5. Qb3 dxc4 6. Qxc4 a6 7. d4 b5 8. Qb3 c5 9. dxc5 Bg7 10. e4 O-O 11. Be2 Be6 12. Qc2 Nbd7 13. Be3 Rc8 14. Rd1 b4 15. Nd5 Bxd5 16. exd5 Nxc5 17. O-O a5 18. Bb5 Nce4 19. Bc6 Qc7  20. Rc1 Nd6 21. Qe2 Nf5 22. Bc5 Bh6 23. Rc2 Rfd8 24. Rd1 e6  25. dxe6  Rxd1+ 26. Qxd1 fxe6 27. Ba4  Qd8  28. Qe2 Ng7 29. Ne5  Ne4 30. Nc6 Rxc6 31. Bxc6 Nxc5 32. Rxc5 1-0 "

; sample game 546
EventSites(546) = "Istanbul ol (Men) 40th  Istanbul" : GameDates(546) = "20120830" : WhitePlayers(546) = "Avrukh, Boris   G#546" : WhiteElos(546) = "2605" : BlackPlayers(546) = "Eljanov, Pavel   G#546" : BlackElos(546) = "2693" : Each_Game_Result(546) = "1-0"

FilePGNs(546) = "1. d4 Nf6 2. c4 e6 3. g3 c5 4. d5 exd5 5. cxd5 d6 6. Nc3 g6 7. Bg2 Bg7 8. Nf3 O-O 9. O-O Qe7 10. Bf4 Nbd7 11. a4  Ng4 12. Bg5  f6 13. Bd2  a6 14. Rb1  Nge5 15. b4 cxb4  16. Rxb4 Nxf3+ 17. exf3   f5 18. a5 Qd8 19. Qa4 Nc5 20. Qa3 Bd7 21. Rb6 Qf6 22. Rc1 Rfe8 23. Bf1  Rac8 24. Nd1 Qd4 25. Qa2 Qf6 26. Be3 Qf8 27. Bxc5 Rxc5 28. Rxc5 dxc5 29. Rxb7 Qd6 30. Ne3 Kh8 31. Rb6  Qe5 32. Qc4 Qa1 33. Qxc5 f4  34. gxf4 Bh3 35. Qc2   Qxa5  36. Qc6  Rc8 37. Bxh3  Rxc6 38. Rb8+ Bf8 39. dxc6 Qc5 40. Rxf8+ 1-0 "

; sample game 547
EventSites(547) = "Istanbul ol (Men) 40th  Istanbul" : GameDates(547) = "20120901" : WhitePlayers(547) = "Grischuk, Alexander   G#547" : WhiteElos(547) = "2763" : BlackPlayers(547) = "Almasi, Zoltan   G#547" : BlackElos(547) = "2713" : Each_Game_Result(547) = "1-0"

FilePGNs(547) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. d3 d6 7. c3 O-O 8. Re1 Re8 9. Nbd2 Bf8 10. Nf1 h6 11. Ng3 b5 12. Bc2 Ne7 13. d4 Ng6 14. b3 c6  15. Be3 Qc7 16. Bd3 Bb7 17. Qc2 Rac8 18. h3 Nf4 19. Bf1 Ng6 20. Bd3 Nf4 21. Bf1 Ng6 22. a4 Qb8 23. Bd3 Nf4 24. Bxf4 exf4 25. Nf5 bxa4 26. bxa4 c5  27. e5 dxe5 28. dxe5 Nd7  29. Rab1 Qa8  30. N5h4   Rc6 31. Be4 Rb6 32. Bh7+ Kh8 33. Rxb6  Nxb6 34. e6 Bxf3  35. Nxf3 g6 36. Bxg6  fxg6 37. Qxg6  Qc8 38. Ne5 Bg7 39. Nf7+ Kg8 40. Nxh6+ 1-0 "

; sample game 548
EventSites(548) = "Istanbul ol (Women) 40th  Istanbul" : GameDates(548) = "20120903" : WhitePlayers(548) = "Kosintseva, Nadezhda   G#548" : WhiteElos(548) = "2524" : BlackPlayers(548) = "Zhao Xue   G#548" : BlackElos(548) = "2549" : Each_Game_Result(548) = "1-0"

FilePGNs(548) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Nb8 10. d4 Nbd7 11. Nbd2 Bb7 12. Bc2 Re8 13. Nf1 Bf8 14. Ng3 g6 15. Bg5  h6 16. Bd2 c5  17. d5 c4 18. b4  cxb3 19. axb3 Rc8 20. Bd3 Nb6 21. Bf1 Bg7 22. Qc1  h5 23. c4 bxc4 24. bxc4  Nbd7 25. Rb1  Nc5 26. Be3 Nfd7 27. Qc2 Qe7 28. Nd2 Kh7 29. Nb3 Bh6 30. Bxh6 Kxh6 31. Na5  Rc7  32. Ne2 Qg5 33. Nc3 Bc8 34. Nc6  Nf6  35. Na4  Bxh3 36. Nxc5 dxc5 37. Qc3 Bc8  38. Qa5 Ng4 39. f3 Qh4 40. fxg4 hxg4 41. Be2 Rb7 42. Qc3 g3 43. Qe3+ Kg7 44. Rxb7  Bxb7 45. Bf3 g5 46. Kf1 g4 47. Bd1 Bxc6 48. dxc6 Re6 49. Ke2 Rxc6 50. Rf1 Rb6 51. Qc3 f6 52. Qd2 Qh2 53. Ke1 Kg6 54. Qe2 Kf7 55. Qd2 Ke7 56. Bxg4 Rb1+ 57. Bd1 Qh4 58. Qd3 Rb6 59. Qe3 Rd6 60. Bf3 Rd4 61. Ke2 Kf7 62. Rd1 Kg6 63. Rxd4  cxd4  64. Qc1 f5 65. Qc2 Qf4 66. exf5+ Kf6 67. Qe4 Qc1 68. Qc6+ Kg7 69. Qg6+ Kf8 70. Qf6+ 1-0 "

; sample game 549
EventSites(549) = "Istanbul ol (Men) 40th  Istanbul" : GameDates(549) = "20120903" : WhitePlayers(549) = "Giri, Anish   G#549" : WhiteElos(549) = "2711" : BlackPlayers(549) = "Dgebuadze, Alexandre   G#549" : BlackElos(549) = "2556" : Each_Game_Result(549) = "1-0"

FilePGNs(549) = "1. e4 e6 2. d4 d5 3. e5 c5 4. c3 Bd7 5. Nf3 Nc6 6. Be2 Nge7 7. O-O cxd4 8. cxd4 a6 9. Nc3 Nf5 10. Bg5  Qb6 11. Na4 Qa7 12. Be3   b5 13. Nc3 Be7 14. Bd3 Nxe3 15. fxe3 O-O 16. Ne2 f5 17. h4 Be8  18. Nf4 Qd7 19. g4  fxg4  20. Ng5 Bxg5 21. hxg5  Nb4 22. Bb1 Bg6  23. Nxg6 Rxf1+ 24. Qxf1 Qd8 25. a3 Nc6 26. Nf4  Qxg5 27. Kg2 Ne7 28. Bd3 Nf5 29. Bxf5 Qxf5 30. Qd3 Qf7 31. Rf1 Rf8 32. Qd1 h5 33. Rf2 g5 34. Nd3 Qg6 35. Rxf8+ Kxf8 36. Nc5 Ke8 37. Qd3 Qf7 38. Qf1 Qg6 39. Qf6 Qc2+ 40. Kg3 Qe2 41. Qh8+ Ke7 42. Qg7+ 1-0 "

; sample game 550
EventSites(550) = "Istanbul ol (Men) 40th  Istanbul" : GameDates(550) = "20120903" : WhitePlayers(550) = "Avrukh, Boris   G#550" : WhiteElos(550) = "2605" : BlackPlayers(550) = "Gupta, Abhijeet   G#550" : BlackElos(550) = "2637" : Each_Game_Result(550) = "1-0"

FilePGNs(550) = "1. d4 Nf6 2. c4 g6 3. g3 c6 4. Bg2 d5 5. Qa4 dxc4 6. Qxc4 Bg7 7. Nf3 O-O 8. O-O Bf5 9. Nc3 Nbd7 10. h3 Ne4 11. Qb3   Nb6 12. a4  a5 13. Rd1 Ra6 14. Ne1 Be6 15. Qc2 Nxc3 16. bxc3 Qc8  17. Kh2 c5   18. d5 Bd7 19. Nd3 c4 20. Nb2 e6 21. dxe6 Bxe6 22. Be3  Nd7 23. Bd5  Nf6  24. Bg2 Nd7 25. Bd5 Nf6 26. Bg2 Bf5 27. Qc1 Be4  28. f3 Bf5 29. Bd4 Be6 30. e4 h5  31. Qe3 Re8 32. Rd2 Qb8  33. h4  Kh7 34. Qe2  Rc8 35. Nd1  Nd7 36. Qe3 Bf8 37. f4 Bg4 38. Nf2  Nc5 39. Nxg4 hxg4 40. Bxc5 Bxc5 41. Qe2 Rd6 42. Rxd6 Qxd6 43. Qxg4 Rd8 44. Rf1  Qb6  45. f5 Rd3 46. e5  Bf2 47. Qxc4 Bxg3+ 48. Kh1 Rd7 49. e6 Rc7 50. Qg4 Bd6 51. Be4 Kh8 52. fxg6 f5 53. Qxf5 Qe3 54. g7+ 1-0 "

; sample game 551
EventSites(551) = "Istanbul ol (Men) 40th  Istanbul" : GameDates(551) = "20120904" : WhitePlayers(551) = "Kosic, Dragan   G#551" : WhiteElos(551) = "2526" : BlackPlayers(551) = "Macieja, Bartlomiej   G#551" : BlackElos(551) = "2594" : Each_Game_Result(551) = "0-1"

FilePGNs(551) = "1. d4 Nf6 2. Nf3 d5 3. c4 e6 4. Nc3 dxc4 5. e4 Bb4 6. Bg5 c5 7. Bxc4 cxd4 8. Nxd4 Bxc3+ 9. bxc3 Qa5 10. Bb5+ Nbd7 11. Bxf6 Qxc3+ 12. Kf1 gxf6 13. h4 a6 14. Rh3 Qb4 15. Ba4  b5 16. Bb3 Bb7 17. Rc1 Rd8  18. Nxe6  fxe6 19. Qh5+ Kf8  20. Rg3 Bxe4 21. Bxe6 Qe7  22. Bb3 Ne5 23. Qh6+ Ke8 24. Rg7 Qd6 25. Re1 Bg6  26. h5 Bd3+ 27. Kg1 Bc4 28. Bxc4 bxc4 29. f4 Qd4+ 30. Kh1  Rd6  31. Rb7  Qd2  32. Reb1 Qd1+ 0-1 "

; sample game 552
EventSites(552) = "Istanbul ol (Women) 40th  Istanbul" : GameDates(552) = "20120907" : WhitePlayers(552) = "Danielian, Elina   G#552" : WhiteElos(552) = "2476" : BlackPlayers(552) = "Kosintseva, Tatiana   G#552" : BlackElos(552) = "2530" : Each_Game_Result(552) = "0-1"

FilePGNs(552) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Bb4 5. cxd5 exd5 6. Bg5 h6 7. Bh4 c5 8. e3 c4 9. Be2 g5 10. Bg3 Ne4 11. Rc1 Qa5 12. Ne5 Nc6 13. O-O Nxg3 14. fxg3 Nxe5 15. dxe5 Be6 16. Bg4 O-O-O 17. Rxf7 Qb6 18. Bxe6+ Qxe6 19. Qf3 Bc5 20. Na4 Rhf8 21. Rxf8 Bxf8 22. b3 Ba3 23. Rd1 cxb3 24. axb3 Qxe5 25. h3  Kb8 26. Rd3 Bb4 27. Rd4 Rf8  28. Rxd5 Qe6 29. Qd1 Qxe3+ 30. Kh2 a6 31. Rd3 Qf2 32. Rd7 Bc5  33. Nxc5  Qxc5 34. Qd3  Rc8 35. Rh7 Qb6 36. Qd1 Ka7 37. h4 Rc3  38. hxg5  hxg5 39. Rh5 Rxb3 40. Rxg5 Rb1 41. Qe2  Qg1+ 42. Kh3 Rb4 0-1 "

; sample game 553
EventSites(553) = "Istanbul ol (Men) 40th  Istanbul" : GameDates(553) = "20120909" : WhitePlayers(553) = "Karjakin, Sergey   G#553" : WhiteElos(553) = "2785" : BlackPlayers(553) = "Fridman, Daniel   G#553" : BlackElos(553) = "2653" : Each_Game_Result(553) = "1-0"

FilePGNs(553) = "1. e4 e5 2. Bc4 Nf6 3. d3 c6 4. Nf3 d5 5. Bb3 Bb4+ 6. Bd2 Bxd2+ 7. Qxd2 O-O 8. Nxe5 Qe7 9. f4 dxe4 10. d4   Nd5 11. O-O f6 12. Nc4 Kh8  13. Nc3  Nxc3 14. Qxc3 f5 15. Ne5 Be6 16. Qh3  Kg8  17. g4  fxg4 18. Qxg4 Bxb3 19. axb3 Na6 20. Rae1 Nc7 21. Rxe4 Ne8 22. Qd7 Qxd7 23. Nxd7 Rf7 24. Ne5 Re7 25. Ree1 Nd6 26. Nd3  Rf7 27. c3 Raf8 28. Re6 Nb5 29. Rfe1 g6 30. Kg2 Nc7 31. Re7 Nd5 32. Rxf7 Rxf7 33. Re8+ Kg7 34. Kg3 Nf6 35. Rb8 Ne4+ 36. Kg2 Kh6 37. b4 Kh5 38. Re8 Nd6 39. Re3  Nf5 40. Re5 a6 41. h3 h6 42. Nf2  g5 43. fxg5 Nh4+ 44. Kf1 hxg5 45. Re8 Ng6 46. Re3 Nf4  47. Kg1 Nd5 48. Re8 Nf4 49. Kh2 Kg6 50. Re5 Rh7 51. Kg3 Nh5+ 52. Kg4 Nf6+ 53. Kf3 Nd5 54. Re6+ Kf5 55. Rd6 Nf4  56. Ne4   Ne6 57. Rxe6 Rxh3+ 58. Kg2 Re3 59. Re5+ Kf4 60. Nc5 1-0 "

; sample game 554
EventSites(554) = "Burgas Black Sea  Burgas" : GameDates(554) = "20120919" : WhitePlayers(554) = "Areshchenko, Alexander   G#554" : WhiteElos(554) = "2702" : BlackPlayers(554) = "Atalik, Suat   G#554" : BlackElos(554) = "2603" : Each_Game_Result(554) = "1/2-1/2"

FilePGNs(554) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 d6  5. c3 Bd7 6. O-O g6 7. d4 Bg7 8. Be3  Nf6 9. Nbd2 O-O 10. Re1 Ng4 11. Bg5 f6 12. Bh4 g5 13. Bg3 Nh6  14. Nf1  exd4 15. Nxd4  Nxd4 16. Qxd4 f5 17. Qd5+ Kh8 18. Bxd7 Qxd7 19. exf5 Nxf5 20. Re2 Qb5  21. Qd2 Rae8 22. Rae1 Rxe2 23. Rxe2 g4 24. Re4 h5 25. Bf4 Kg8 26. Bg5  d5 27. Re2 d4  28. cxd4 Nxd4 29. Re7 Rf7 30. Re4 Rd7 31. Re8+ Kh7  32. Qe3 Nf5 33. Qe1 Nd6   34. Re7 Rxe7 35. Qxe7 Qxb2 36. Qxc7 Ne4 37. Be3   Nc3 38. h3 Ne2+ 39. Kh2 Qe5+   40. Qxe5 Bxe5+ 41. g3 Nc3 42. a3 b5  43. hxg4 hxg4 44. Bc1  Nd1 45. Kg2 Kg6 46. f3 Kf5 47. fxg4+ Kxg4 48. Nh2+  Kf5 49. Kf3 Bb2  50. Bxb2 Nxb2 51. Ng4   Nc4 52. Ne3+ Nxe3 53. Kxe3 a5 54. Kd4 b4 55. axb4 axb4 56. Kc4 Kg4 57. Kxb4 Kxg3 1/2-1/2 "

; sample game 555
EventSites(555) = "SRB-chT  Vrnjacka Banja" : GameDates(555) = "20121004" : WhitePlayers(555) = "Atalik, Suat   G#555" : WhiteElos(555) = "2603" : BlackPlayers(555) = "Pap, Gyula   G#555" : BlackElos(555) = "2569" : Each_Game_Result(555) = "1-0"

FilePGNs(555) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Be2 O-O 6. Bg5 c5 7. d5 e6 8. Qd2 exd5 9. exd5 Re8 10. Nf3 Bg4 11. O-O Nbd7 12. h3 Bxf3 13. Bxf3 Qb6 14. Qc2 Kh8  15. Bd2 a6 16. Rae1 Rxe1 17. Rxe1 Re8 18. Bd1 Rxe1+ 19. Bxe1 Qd8 20. Qe2  Ne8 21. g4  Nc7 22. f4 Bd4+ 23. Kg2 Kg8 24. b3 Kf8 25. Ne4 Qe7 26. g5  Ne8 27. h4 Ng7 28. Ng3 f6 29. Qxe7+ Kxe7 30. Bg4 b6 31. Bd2 a5 32. Ne2 Bb2 33. Kh3 Nb8 34. Ng3 Na6 35. h5 gxh5   36. Bf5   Nb4 37. a4 fxg5 38. fxg5 Na2 39. Bxh7 Nc1  40. Bc2 1-0 "

; sample game 556
EventSites(556) = "IND-ch 50th  Kolkata" : GameDates(556) = "20121006" : WhitePlayers(556) = "Grover, Sahaj   G#556" : WhiteElos(556) = "2516" : BlackPlayers(556) = "Lalith, Babu MR   G#556" : BlackElos(556) = "2540" : Each_Game_Result(556) = "1-0"

FilePGNs(556) = "1. d4 g6 2. c4 d6 3. Nc3 Bg7 4. Nf3 Bg4  5. g3 Bxf3  6. exf3 e5  7. dxe5 dxe5 8. Qxd8+ Kxd8 9. Bg5+ Kc8 10. O-O-O Nc6 11. h4  h6 12. Be3 Nge7 13. Bh3+ f5 14. f4 a5 15. g4  Ra6  16. gxf5 gxf5 17. Rhg1 Bf6 18. Ne4  exf4 19. Bxf4 Bxh4 20. Rg7 Nd8 21. Bxf5+  Kb8  22. Rh7   Rg8 23. Bh3 Ne6 24. Be3 Rc6 25. b3 Ng6 26. Rxh6 Be7 27. Rh7 Ba3+ 28. Kb1 Ngf4 29. Nf6 1-0 "

; sample game 557
EventSites(557) = "EU-Cup 28th  Eilat" : GameDates(557) = "20121011" : WhitePlayers(557) = "Topalov, Veselin   G#557" : WhiteElos(557) = "2751" : BlackPlayers(557) = "Eljanov, Pavel   G#557" : BlackElos(557) = "2681" : Each_Game_Result(557) = "0-1"

FilePGNs(557) = "1. Nf3 d5 2. d4 Nf6 3. c4 c6 4. e3 Bg4 5. h3 Bh5 6. Nc3 e6 7. g4 Bg6 8. Ne5 Nbd7 9. Nxg6 hxg6 10. Bd2 g5 11. Qb3 Qc7  12. Bg2 Be7 13. cxd5  exd5 14. O-O-O Nb6 15. e4  Nxe4 16. Nxe4 dxe4 17. Rhe1 Nd5  18. Rxe4 O-O-O 19. Qa4 Kb8 20. Ba5 Nb6 21. Qb3 Bf6 22. Kb1 Rd5 23. Bb4 Rhd8 24. Bc5 R5d7 25. Bf1 Be7 26. Rde1 Bxc5 27. dxc5 Nd5  28. a3 Nf4 29. Ka2 f6 30. Re8 Ng6  31. R1e6 Ne5 32. Ba6 Kc8 33. Bc4 Rxe8 34. Rxe8+ Rd8 35. Re6 Rd4 36. Re8+ Rd8 37. Re6 Kb8  38. Qc3  a6 39. Be2 Ka7  40. Bc4  Rd1 41. Re8 Qd7 42. Rg8 Nd3  43. Bxd3 Rxd3 44. Qc4 Rxh3 45. Rf8 Rd3  46. Rf7 Qd4 47. Qxd4 Rxd4 48. f3 a5  49. Rxg7 Rf4 50. Rf7 Rxf3 51. a4 Rf4 52. Ka3 Kb8  53. Rf8+ Kc7 54. Rf7+ Kc8 55. b3 Rxg4 56. Rxf6 Rf4 57. Rg6 g4 58. Rg7 Rb4  59. Kb2 Kd8 60. Kc3 Ke8 61. Rh7 Kf8 62. Kd2 Rxb3 63. Rh8+ Kf7 64. Ra8 Ke6 65. Rxa5 Kd5 66. Ra7 Kxc5 67. a5 g3 68. Ke2 Kc4 69. a6 bxa6 70. Rxa6 c5 71. Rg6 Kb4 72. Rg4+ c4 73. Kd1 Rb1+ 74. Kc2 Rg1 0-1 "

; sample game 558
EventSites(558) = "EU-Cup 28th  Eilat" : GameDates(558) = "20121012" : WhitePlayers(558) = "Roiz, Michael   G#558" : WhiteElos(558) = "2618" : BlackPlayers(558) = "Gofshtein, Leonid D   G#558" : BlackElos(558) = "2480" : Each_Game_Result(558) = "1-0"

FilePGNs(558) = "1. d4 d5 2. c4 e6 3. Nf3 Nf6 4. g3 Bb4+ 5. Bd2 Be7 6. Bg2 c6 7. Qc2 b6 8. O-O Bb7 9. Rd1 O-O 10. b3 Nbd7 11. Nc3 c5 12. cxd5 Nxd5 13. Nxd5 exd5 14. Bc3 Qc7 15. dxc5 bxc5 16. Rac1 Qb6 17. e3 Rfd8 18. Qb2  Nf6 19. Ne1 a5 20. Be5 Ne8 21. Qc2  a4 22. Nd3 axb3 23. axb3 d4 24. Bxb7 Qxb7 25. exd4 cxd4 26. b4   Ra3 27. Qc4 Qd5  28. Qxd5 Rxd5 29. Rc8 Kf8 30. Bxg7+ Kxg7 31. Rxe8 Rd7 32. Ne5 Rb7 33. Rxd4 Bxb4 34. Rg4+ Kf6 35. Rf4+   Kg7 36. Rg4+ Kf6 37. Rh4 Re7  38. Ng4+ Kg7 39. Rxe7 Bxe7 40. Rh5 Rc3 41. Re5 Kf8 42. Kg2 f6 43. Rb5 Kf7 44. Rb7 h5 45. Ne3 Rc5 46. Kf3 Re5  47. Ng2 Kg6 48. Nf4+ Kh6 49. h4 Bd6 50. Rd7 Bf8 51. Rf7 Be7 52. Kg2 f5 53. Nd3 1-0 "

; sample game 559
EventSites(559) = "EU-Cup 28th  Eilat" : GameDates(559) = "20121014" : WhitePlayers(559) = "Wojtaszek, Radoslaw   G#559" : WhiteElos(559) = "2733" : BlackPlayers(559) = "Roiz, Michael   G#559" : BlackElos(559) = "2618" : Each_Game_Result(559) = "1/2-1/2"

FilePGNs(559) = "1. d4 e6 2. c4 d5 3. Nc3 Nf6 4. cxd5 Nxd5 5. e4 Nxc3 6. bxc3 c5 7. a3 cxd4 8. cxd4 e5  9. Nf3 exd4 10. Qxd4  Qxd4 11. Nxd4 Bc5 12. Nb5 Na6 13. Bf4 O-O 14. Bd3 Be6 15. Ke2 Rfd8 16. Rhd1 Bb6  17. Rac1 Nc5 18. Nd6 Nxd3 19. Rxd3 Rd7 20. Be3 Bd8  21. Nb5  Rxd3 22. Kxd3 Bd7 23. Nxa7 Kf8 24. Ke2 b6 25. Nc6 Bxc6 26. Rxc6 Rxa3 27. Bxb6 Bxb6 28. Rxb6 Ra2+ 29. Kf3 Ra3+ 30. Kf4 Ra2 31. Kg3 h5   32. h4 g6 33. Rb3 Kg7 34. Kf3 Rc2 35. g3 Ra2 36. Ke3 Rc2 37. Rd3 Ra2 38. Rd2 Ra3+ 39. Kf4 Rb3 40. f3 Ra3 41. Rd5 Ra1 42. g4 hxg4 43. Kxg4 Rg1+ 44. Kf4 Rh1 45. Kg3 Kf6 46. Rd6+ Kg7 47. Rd2 Rg1+ 48. Rg2 Re1 49. Rh2 Ra1 50. h5 gxh5 51. Rxh5 Kg6 52. Rb5 Ra3 53. Rb6+ f6 54. Kf4 Ra5 55. Rd6 Rb5 56. Ke3 Rb3+ 57. Rd3 Rb4 58. Rc3 Ra4 59. Rd3 Rb4 60. f4 Ra4 61. Kf3 Rb4 62. Ra3 Rc4 63. Ra6 Kf7 64. Ra7+ Kf8 65. Rh7 Ra4 66. Rb7 Rc4 67. Rb6 Kf7 68. Rb7+ Kf8 69. f5 Rc1 70. Ke3 Rc4 71. Kd3 Ra4 72. Rc7 Ke8 73. Rc4 Ra6 74. Kd4 Kd7 75. Rb4 Rd6+ 76. Kc5 Rc6+ 77. Kd4 Rd6+ 78. Ke3 Ke7 79. Rb7+ Ke8 80. Kf4 Rd1 81. Kg4 Rg1+ 82. Kf4 Re1 83. Rb6 Ke7 84. Rb7+ Ke8 85. Rc7 1/2-1/2 "

; sample game 560
EventSites(560) = "EU-Cup 28th  Eilat" : GameDates(560) = "20121017" : WhitePlayers(560) = "Sutovsky, Emil   G#560" : WhiteElos(560) = "2685" : BlackPlayers(560) = "Khismatullin, Denis   G#560" : BlackElos(560) = "2638" : Each_Game_Result(560) = "1-0"

FilePGNs(560) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be3 e5 7. Nf3 Be7 8. Bc4 O-O 9. O-O Qc7 10. Bb3 Be6 11. Nh4  g6 12. Bh6 Re8 13. Qf3  Ng4 14. Nf5  Bxf5 15. Be3  Be6 16. Bxe6 fxe6 17. Qxg4 Bf6 18. h4  Kh8 19. f4  Nd7 20. f5 gxf5 21. exf5 Rg8 22. Qe2  Rae8 23. fxe6 Rxe6 24. Nd5 Qc6 25. c4  b5 26. Rac1  Bxh4 27. Rf7 Nf6 28. Rf1 Rg6 29. Ne7 Rxe7 30. Rxe7 bxc4 31. Qf3 Qc8 32. Ra7 Rg8 33. Qf5 Qc6 34. Rf3 c3 35. bxc3 Qxc3 36. Qh3 Qc2 37. Rf7 Ng4  38. Qxh4 Qb1+ 39. Rf1 Qg6 40. Rf8 1-0 "

; sample game 561
EventSites(561) = "Hoogeveen Unive Crown 16th  Hoogeveen" : GameDates(561) = "20121021" : WhitePlayers(561) = "Nakamura, Hikaru   G#561" : WhiteElos(561) = "2775" : BlackPlayers(561) = "Giri, Anish   G#561" : BlackElos(561) = "2693" : Each_Game_Result(561) = "1-0"

FilePGNs(561) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. Re1 Nd6 6. Nxe5 Be7 7. Bf1 Nxe5 8. Rxe5 O-O 9. d4 Bf6 10. Re1 Re8 11. c3 Rxe1 12. Qxe1 Nf5 13. Bf4 c6 14. a4  a5 15. Bc7  Qf8 16. Bd3 d5 17. Bb6 Nd6 18. Nd2 Be6 19. Qb1  g6 20. b4 axb4 21. Qxb4 Bf5 22. Bc5 Bxd3 23. Bxd6 Qe8  24. Nf3 Ba6 25. Be5 Be7 26. Bd6 Bf6 27. Re1 Qd7 28. Be7 Bg7 29. Ne5 Qf5  30. Qd6  Re8 31. h3 Qe6 32. Qxe6 fxe6  33. Bc5 g5  34. Bb4  h6 35. Nd7  Kf7 36. Re3  Kg6 37. Bd6   h5 38. Nc5 Bf6 39. g4 hxg4 40. hxg4 Kf7 41. Kg2 Ra8 42. a5 Re8 43. Re1  Bd8  44. Ra1 Rh8 45. Be5 Rh7 46. Bd6 Rh8 47. f3 Rh6 48. Be5  Rh7 49. Kg3 Rh6  50. Rb1 Bxa5 51. Nxb7 Bxb7 52. Rxb7+ Ke8 53. Rg7  Bd8 54. Kg2  Be7 55. Rg8+ Kd7 56. Ra8 c5 57. Rg8 cxd4 58. cxd4 Rh7 59. f4 gxf4  60. g5 Bd6 61. Bf6 Be7 62. g6 f3+ 63. Kxf3 Rh5 64. Be5 1-0 "

; sample game 562
EventSites(562) = "ESP-chT  Leon" : GameDates(562) = "20121106" : WhitePlayers(562) = "Marin, Mihail   G#562" : WhiteElos(562) = "2547" : BlackPlayers(562) = "Ponomariov, Ruslan   G#562" : BlackElos(562) = "2741" : Each_Game_Result(562) = "1/2-1/2"

FilePGNs(562) = "1. d4 g6 2. Nf3 Bg7 3. e4 d6 4. c3 Nf6 5. Bd3 O-O 6. O-O Nc6 7. Bg5 h6 8. Bh4 e5 9. Na3  Bg4 10. Nc2 Qe8 11. Re1  exd4 12. cxd4 Nd7 13. Rc1  Rc8 14. Bb5 Bxf3  15. gxf3 a6 16. Bf1   Nd8  17. f4 c5 18. d5 Bxb2 19. Rb1 Bg7 20. Bh3  f6 21. a4  Rc7 22. Bg3 Qe7 23. Ne3 c4  24. Be6+  Kh8 25. f5 g5 26. Qe2 c3 27. Rec1 Nf7 28. Nc4 Nfe5 29. Rxc3 Nc5 30. a5 Na4 31. Bxe5 fxe5 32. Rc2 Rd8 33. Rbc1 Nc5 34. Qe3 Bf8 35. Nb6 Qe8 36. Qe2  Rg7  37. Rb1  g4 38. f6  Rg6 39. Bf5 Rg5 40. Kh1 Qf7 41. Bxg4 Qxf6 1/2-1/2 "

; sample game 563
EventSites(563) = "ESP-chT  Leon" : GameDates(563) = "20121106" : WhitePlayers(563) = "Fier, Alexandr Hilario T   G#563" : WhiteElos(563) = "2567" : BlackPlayers(563) = "Ganguly, Surya Shekhar   G#563" : BlackElos(563) = "2619" : Each_Game_Result(563) = "1-0"

FilePGNs(563) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O b5 6. Bb3 Bc5 7. a4 Rb8 8. c3 d6 9. d4 Bb6 10. axb5 axb5 11. Na3 O-O 12. Nxb5 Bg4 13. Bc2 exd4 14. Nbxd4 Nxd4 15. cxd4 Bxf3 16. gxf3 Nh5 17. Kh1 Qf6 18. Be3 Ra8 19. Rxa8 Rxa8 20. Rg1 Nf4 21. Bb3 Ne6 22. Bd5   Rb8 23. Bxe6 Qxe6 24. Qd3 g6 25. Bd2 Ra8 26. Bc3 d5 27. e5 c5 28. Rd1 cxd4 29. Bxd4 Bxd4 30. Qxd4 Rb8 31. Kg2 Rb5  32. Ra1  Kg7 33. Ra8 h6 34. Qc3 Rb7 35. h4 h5 36. b4 Kh7 37. Rd8 Rd7 38. Rxd7 Qxd7 39. Qc5 Kg7 40. Qd6  Qb7 41. Kg3 Kh7 42. Kf4 Qc8 43. Qxd5 Qc1+ 44. Ke4 Qe1+ 45. Kd3 Qd1+ 46. Kc4 Qe2+ 47. Kc5 Qxf2+ 48. Kc6 Qc2+ 49. Kd6 Kg7 50. b5 Qf2 51. Kc6 Qxh4 52. b6 Qb4 53. b7 h4 54. Qd6 Qc4+ 55. Kb6 Qb3+ 56. Kc7 Qc3+ 57. Kd7 1-0 "

; sample game 564
EventSites(564) = "Bucharest Kings 6th  Bucharest" : GameDates(564) = "20121109" : WhitePlayers(564) = "Nisipeanu, Liviu Dieter   G#564" : WhiteElos(564) = "2661" : BlackPlayers(564) = "Topalov, Veselin   G#564" : BlackElos(564) = "2751" : Each_Game_Result(564) = "1/2-1/2"

FilePGNs(564) = "1. e4 c5 2. c3 d5 3. exd5 Qxd5 4. d4 Nf6 5. Nf3 Nc6 6. dxc5 Qxd1+ 7. Kxd1 e5 8. Be3 Nd5 9. b4 g6 10. Kc2 Bf5+ 11. Kb3 a5 12. Bc4  Be6 13. Ng5 axb4 14. cxb4 Ncxb4 15. Nc3 Nxc3 16. Nxe6 fxe6 17. Kxb4 Nd5+ 18. Kb5 Be7  19. Rac1 Bd8 20. Bb3 Rf8 21. Rhd1 Ra5+ 22. Kc4 Be7  23. Kd3 Nxe3 24. fxe3 Bxc5 25. Rf1  Rxf1 26. Rxf1 Ke7 27. Rc1  b6 28. Rc4 Ra8 29. Ra4 Rxa4 30. Bxa4 g5 31. Ke4 1/2-1/2 "

; sample game 565
EventSites(565) = "Wch World Cup (Women)  Khanty-Mansiysk" : GameDates(565) = "20121121" : WhitePlayers(565) = "Ushenina, Anna   G#565" : WhiteElos(565) = "2452" : BlackPlayers(565) = "Kosintseva, Nadezhda   G#565" : BlackElos(565) = "2539" : Each_Game_Result(565) = "1-0"

FilePGNs(565) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 O-O 5. Bd3 d5 6. Nf3 c5 7. O-O Nc6 8. a3 Bxc3 9. bxc3 Qc7 10. cxd5 exd5 11. a4 Re8 12. Ba3 c4 13. Bc2 Bg4 14. Qe1 Bh5 15. Nh4 Ng4 16. g3 Bg6 17. Nxg6 hxg6 18. Qd2 Na5 19. Rae1 Nf6 20. f3 Qc6 21. Qg2 Nb3 22. e4 Qxa4 23. Bb2 Qb5 24. Bb1 dxe4 25. fxe4 Re6 26. Re2 Rae8 27. e5 Nd5 28. Qf3 f5 29. g4 f4 30. Be4 Rd8 31. Bxd5 Qxd5 32. Qxf4  Qd7 33. Ba3 Ra6 34. Bb4 Qe6 35. Qe4 b5 36. Ref2 Ra1 37. Rxa1 Nxa1 38. Ra2 Nb3 39. Rxa7 Nc1 40. Re7 Qa6 41. Qf3 Kh8 42. Qf7 Rg8 43. Ra7 Qc8 44. Qxg6 Ne2+ 45. Kf1 Nf4 46. Qg5 1-0 "

; sample game 566
EventSites(566) = "Tashkent FIDE GP 2nd  Tashkent" : GameDates(566) = "20121123" : WhitePlayers(566) = "Leko, Peter   G#566" : WhiteElos(566) = "2732" : BlackPlayers(566) = "Mamedyarov, Shakhriyar   G#566" : BlackElos(566) = "2764" : Each_Game_Result(566) = "1/2-1/2"

FilePGNs(566) = "1. e4 d6 2. d4 Nf6 3. Nc3 c6 4. Nf3 Bg4  5. h3 Bh5 6. Bd3 e6 7. g4 Bg6 8. g5 Nfd7 9. Nh4 d5  10. Nxg6 hxg6 11. Qg4 Qb6  12. Ne2 Na6 13. c3 dxe4 14. Bxe4 Nc7 15. Qf3 Nb5  16. a4 Nd6 17. a5 Qb5 18. Bd3 Qd5 19. Qxd5 cxd5 20. a6 b6 21. h4 Rc8 22. Ng3 Be7 23. Ke2 Kf8  24. Bf4 Nc4 25. h5 gxh5 26. Nxh5 Kg8 27. Bc1 g6 28. Ng3 Rxh1 29. Nxh1 e5  30. dxe5 Ncxe5 31. Bb5 Nc5 32. Be3 Ne6 33. Rd1 Nc7 34. Bd3  Re8  35. f4  Bxg5  36. Nf2 Nxd3 37. Nxd3 Be7 38. Kf3 f6 39. Bd4 Kf7 40. Rh1 Nxa6 41. Ra1 Nc5 42. Bxc5  bxc5 43. f5  g5 44. Rxa7 Kf8 45. b4  c4 46. Nc5  Bxc5 47. bxc5 Rc8 48. Ra6 Kf7 49. Ra7+ Kg8 50. Ra5 Re8 51. Ra7 Rc8 52. Ra5 Re8 53. Ra7 Rc8 54. Ra5 1/2-1/2 "

; sample game 567
EventSites(567) = "Tashkent FIDE GP 2nd  Tashkent" : GameDates(567) = "20121127" : WhitePlayers(567) = "Ponomariov, Ruslan   G#567" : WhiteElos(567) = "2741" : BlackPlayers(567) = "Morozevich, Alexander   G#567" : BlackElos(567) = "2748" : Each_Game_Result(567) = "1-0"

FilePGNs(567) = "1. e4 e6 2. d4 d5 3. Nd2 c5 4. Ngf3 cxd4 5. Nxd4 Nc6 6. Bb5 Bd7 7. Nxc6 bxc6 8. Bd3 Bd6 9. Qe2 Qc7 10. Nf3 dxe4 11. Qxe4 Nf6 12. Qh4 h6 13. O-O c5 14. Nd2   Nd5 15. Nc4 Bf4 16. Re1 Rb8 17. Be4 Bxc1 18. Raxc1 Nb6  19. Ne3 O-O 20. b3 f5 21. Bd3 e5 22. f3 Rbe8 23. Rcd1 Kh8 24. c3 Rf6 25. Bc2 Be6 26. Rd2 a5 27. c4 Nc8  28. Bxf5  Rxf5 29. Nxf5 Bxf5 30. Qh5 Rf8 31. Rd5 Kh7 32. Rdxe5  Bg6 33. Qh4 Rd8 34. Qg3 Bf7 35. Qf4 Bg6 36. h4 Rd4  37. Qf8 Qd7 38. h5 Bf7 39. Qxc5 a4 40. Re7 Nxe7 41. Rxe7 Rd1+ 42. Kh2 1-0 "

; sample game 568
EventSites(568) = "Tashkent FIDE GP 2nd  Tashkent" : GameDates(568) = "20121127" : WhitePlayers(568) = "Gelfand, Boris   G#568" : WhiteElos(568) = "2751" : BlackPlayers(568) = "Kamsky, Gata   G#568" : BlackElos(568) = "2762" : Each_Game_Result(568) = "0-1"

FilePGNs(568) = "1. d4 f5 2. g3 Nf6 3. Bg2 d6 4. Nf3 g6 5. O-O Bg7 6. c4 O-O 7. Nc3 c6 8. d5 e5 9. dxe6 Bxe6 10. b3 Na6 11. Bb2 Qe7 12. Ng5 Bd7 13. Qd2 h6 14. Nh3 Be6 15. Rad1 Rad8 16. Ba3 Nc5 17. f4 Qc7 18. Nf2 Rfe8 19. Kh1  Qb6 20. Qc2 d5  21. cxd5 cxd5 22. Nxd5 Nxd5 23. Bxc5 Qc7 24. Rd2  Bc3 25. Nd3  b6  26. Bf2 Bxd2 27. Qxd2 Qc3  28. Qc1 Qxc1 29. Rxc1 Rc8 30. Ra1 Nc3 31. Bf3 Nxe2  32. Re1 Nc3 33. Nb4 Ne4 0-1 "

; sample game 569
EventSites(569) = "Tashkent FIDE GP 2nd  Tashkent" : GameDates(569) = "20121129" : WhitePlayers(569) = "Karjakin, Sergey   G#569" : WhiteElos(569) = "2775" : BlackPlayers(569) = "Morozevich, Alexander   G#569" : BlackElos(569) = "2748" : Each_Game_Result(569) = "1-0"

FilePGNs(569) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 Qc7 6. Be3 a6 7. Be2 Nf6 8. O-O Be7 9. f4 d6 10. a4 O-O 11. Kh1 Nxd4 12. Qxd4 Bd7 13. e5 Ne8 14. Bf3 Bc6 15. Qb6 Bxf3 16. Rxf3 Rc8 17. a5 Qc6 18. Na4 f6 19. exd6 Nxd6 20. Qxc6 Rxc6 21. Bc5 Re8 22. Rd1 Ne4 23. Bxe7 Rxe7 24. c3 e5 25. Kg1 exf4 26. Rxf4  g6 27. Rf3 f5 28. Rfd3 Nc5 29. Nxc5 Rxc5 30. Rd5 Rxd5 31. Rxd5 Kf7 32. Rd6 Kg7 33. Kf2 Kh6 34. Kf3 Kh5 35. Rb6 Kg5 36. g3 Rc7 37. h3 Rd7 38. c4 Rd3+ 39. Kf2 Rd7 40. Ke3 Re7+ 41. Kf3 Rc7 42. b3 Kh5 43. Kf4 Rf7 44. Kf3 g5 45. b4 g4+ 46. hxg4+ fxg4+ 47. Ke4 Kg5 48. b5 axb5 49. cxb5 h5 50. a6 Re7+ 51. Kd3 Rd7+ 52. Kc4 Rc7+  53. Rc6 bxc6 54. b6 Rc8 55. b7 Rb8 56. Kc5 h4 57. a7 Rxb7 58. a8=Q Rh7 59. Qg8+ Kh6 60. gxh4 Rg7 61. Qh8+ Kg6 62. h5+ Kf7 63. h6 Rg5+ 64. Kd6 g3 65. Qh7+ Kf6 66. Qe7+ Kf5 67. Qxg5+ Kxg5 68. h7 1-0 "

; sample game 570
EventSites(570) = "Tashkent FIDE GP 2nd  Tashkent" : GameDates(570) = "20121129" : WhitePlayers(570) = "Dominguez Perez, Leinier   G#570" : WhiteElos(570) = "2726" : BlackPlayers(570) = "Caruana, Fabiano   G#570" : BlackElos(570) = "2786" : Each_Game_Result(570) = "0-1"

FilePGNs(570) = "1. e4 d5 2. exd5 Qxd5 3. Nc3 Qd6 4. d4 Nf6 5. Nf3 g6 6. Bc4 Bg7 7. O-O O-O 8. h3 a6 9. Re1 b5 10. Bb3 Bb7 11. Bg5 c5  12. dxc5 Qxc5 13. Qe2 e6 14. Rad1 Nbd7  15. Bf4 Rfe8 16. Bd6 Qb6 17. Qe3 Qxe3 18. Rxe3 Nb6 19. Be5 Rac8 20. Red3 Nc4 21. Bxc4 Rxc4 22. a3 h6 23. Nd2 Rcc8 24. Bxf6  Bxf6 25. Nde4 Bxc3 26. Nxc3 Bc6 27. R1d2 g5 28. Rd6 Kf8 29. Nd1 Ke7 30. Ne3 h5 31. c4  bxc4  32. R6d4 Bb5 33. h4 Rg8 34. Kh2 c3 35. Rc2 cxb2 36. Rxb2 Rc5 37. a4 Bc6 38. Rb6 a5 39. hxg5 Rgxg5 40. Ra6 e5  41. Ra7+  Ke6 42. Rd8 f5  43. Rh8 Rg6 44. Rhh7 f4 45. Rae7+ Kd6 46. Nf5+ Kd5 47. Rxh5 Bxa4 48. Ra7  Kc4  49. Rh8 Bc2 50. Nh4 Rb6  51. Nf3 a4 52. Ng5 Kb4 53. Rha8 Rh6+  54. Nh3 Bb3 55. f3 Rc2 56. Kg1 Rd6 57. Re8 Rdd2 58. Rg7 a3 59. Rxe5 a2 60. Re1 Rb2 61. Kh2 Rb1 62. Re4+ Kc5 63. Ra7 a1=Q 64. Rxa1 Rxa1 65. Nxf4 Ra4 66. Re5+ Kd6 67. Rf5 Bc2 68. Rf7 Ke5 69. Kg3 Rd8 70. Nh3 Rg8+ 71. Kh2 Rh4 72. Rc7 Bf5 73. Rc5+ Ke6 74. g4 Rgh8 75. Rxf5 Rxh3+ 76. Kg2 Rh2+ 77. Kg3 R8h3+ 78. Kf4 Rf2 79. Re5+ Kf6 80. Re3 Ra2 81. g5+ Kf7 82. Kg4 Rh1 83. Rb3 Rg1+ 0-1 "

; sample game 571
EventSites(571) = "Belgrade Trophy 26th  Obrenovac" : GameDates(571) = "20121130" : WhitePlayers(571) = "Atalik, Suat   G#571" : WhiteElos(571) = "2595" : BlackPlayers(571) = "Ermenkov, Evgenij   G#571" : BlackElos(571) = "2421" : Each_Game_Result(571) = "1-0"

FilePGNs(571) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Be2 O-O 6. Bg5 Na6 7. f4 c6  8. Nf3 Nc7 9. Bh4  d5  10. e5 Ne4 11. O-O Ne6 12. g3 f6 13. cxd5  cxd5 14. Qb3 g5 15. fxg5 fxg5 16. Nxe4 gxh4 17. Neg5   hxg3  18. Qc2 gxh2+ 19. Kh1 Rf4 20. Qxh7+ Kf8 21. Nxe6+ Bxe6 22. Ng5 1-0 "

; sample game 572
EventSites(572) = "Tashkent FIDE GP 2nd  Tashkent" : GameDates(572) = "20121203" : WhitePlayers(572) = "Morozevich, Alexander   G#572" : WhiteElos(572) = "2748" : BlackPlayers(572) = "Leko, Peter   G#572" : BlackElos(572) = "2732" : Each_Game_Result(572) = "1-0"

FilePGNs(572) = "1. c4 c5 2. Nf3 Nf6 3. Nc3 Nc6 4. d4 cxd4 5. Nxd4 e6 6. g3 Qb6 7. Nb3 Ne5 8. e4 Bb4 9. Qe2 d6 10. Bd2 a5 11. f4 Nc6 12. Be3 Qc7 13. Bg2 a4 14. Nd2 Bxc3 15. bxc3 b6 16. Rb1 Nd7 17. Qf2 Rb8 18. O-O O-O 19. g4 Ba6 20. Qh4 Rfe8 21. Rf3 Nf8 22. Rh3 b5  23. e5  dxe5  24. Be4 h6 25. f5 f6 26. Bxh6  gxh6 27. Qxh6 Qa7+ 28. Kg2 Qg7 29. Bxc6 Qxh6 30. Rxh6 Red8 31. Ne4 Kg7  32. Rxf6 Rdc8 33. cxb5 Rxc6 34. bxc6 Rxb1 35. fxe6 Bd3 36. e7 Bxe4+ 37. Kg3 Ng6 38. e8=Q Kxf6 39. Qd8+  Kf7 40. c7 Rb2 41. Qd7+ Kf6 42. g5+ 1-0 "

; sample game 573
EventSites(573) = "Tashkent FIDE GP 2nd  Tashkent" : GameDates(573) = "20121203" : WhitePlayers(573) = "Mamedyarov, Shakhriyar   G#573" : WhiteElos(573) = "2764" : BlackPlayers(573) = "Karjakin, Sergey   G#573" : BlackElos(573) = "2775" : Each_Game_Result(573) = "1-0"

FilePGNs(573) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Ba6 5. Qa4 Bb7 6. Bg2 c5 7. dxc5 bxc5 8. O-O Be7 9. Nc3 O-O 10. Rd1 Qb6 11. Bf4 Rd8 12. Rd2 h6 13. Rad1 d6 14. Qb5 Ne8 15. g4 Nd7 16. h4   a6 17. Qxb6 Nxb6 18. b3 Bf6 19. Nb1 d5  20. g5 hxg5 21. hxg5 Be7 22. Ne5 Nd6 23. g6  f6 24. Nf7  e5 25. Nxd6 Rxd6 26. Bg3 f5 27. Bxe5 Rxg6 28. cxd5 c4 29. Bg3 Bb4 30. bxc4  Bxd2 31. Nxd2 Rc8 32. e3 a5 33. Rb1 Ba6 34. d6 Nd7 35. Kf1  Kf8 36. Bf3 Rf6 37. Kg2 g5  38. Bh2 Bxc4  39. Nxc4 Rxc4 40. Rb7 Ke8 41. Be2 Rc8  42. Bb5 Rd8 43. Be5 Re6 44. f4 gxf4 45. Bxf4 Rg6+ 46. Kf3 Rg1 47. Be5 Rg6 48. Kf4 Rh6 49. a4 Re6 50. Rc7 Rh6 51. Kg5 Rh7 52. Bf6 Rb8 53. Bc6 1-0 "

; sample game 574
EventSites(574) = "Bundesliga 1213  Germany" : GameDates(574) = "20121208" : WhitePlayers(574) = "Rustemov, Alexander   G#574" : WhiteElos(574) = "2544" : BlackPlayers(574) = "Postny, Evgeny   G#574" : BlackElos(574) = "2647" : Each_Game_Result(574) = "0-1"

FilePGNs(574) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. e3 a6 5. Qc2 b5 6. b3 Bg4 7. Nge2 Nbd7 8. h3 Bh5 9. Nf4 Bg6 10. Nxg6 hxg6 11. Bb2 e6 12. c5  g5 13. O-O-O g6 14. Bd3  Bg7 15. Ne2  Qe7 16. g4  e5 17. Ng3 O-O 18. Rde1 Rae8 19. Qd2 Nh7  20. f3 exd4 21. exd4 Qf6 22. Ref1  Re7 23. Ne2 Rfe8 24. f4 gxf4  25. Nxf4 Qh4 26. Kb1  Ng5 27. Qg2 Ne4 28. Rhg1 Qh8  29. Bxe4 Rxe4 30. Qf3 R8e7 31. Rd1 Nxc5 32. Qc3 Ne6 33. Nxe6 R7xe6 34. Rg3 Qh4 35. Rgd3 Re2 36. Bc1 Qe7 37. Qa5 c5 38. dxc5 Qxc5  39. R3d2 Rxd2  40. Qxd2 d4 41. Bb2 Qd5 42. Qc2 Re3 43. h4 Qe4 44. Qxe4 Rxe4 45. Rg1 Re2 46. Rh1 Be5 47. Bc1 f6 48. a3 Kf7 49. b4 Rg2 50. g5 f5 51. Re1 Bg3 52. Rd1 Bxh4 53. Rxd4 Bxg5 54. Bxg5 Rxg5 55. Rd7+ Ke6 56. Ra7 f4 57. Rxa6+ Kf5 58. Kc2 Rg2+ 59. Kd3 Ra2 60. Kd4 Rd2+ 61. Kc5 g5 62. Kxb5 f3 63. Ra8 Rd6 64. Kc5 Rf6 65. Rd8 f2 66. Rd1 g4 67. b5 g3 68. b6 Rxb6 69. Kxb6 g2 0-1 "

; sample game 575
EventSites(575) = "Campeonato Paulista Absoluto  Americana" : GameDates(575) = "20121208" : WhitePlayers(575) = "Mekhitarian, Krikor Sevag   G#575" : WhiteElos(575) = "2531" : BlackPlayers(575) = "Fier, Alexandr Hilario T   G#575" : BlackElos(575) = "2567" : Each_Game_Result(575) = "1/2-1/2"

FilePGNs(575) = "1. e4 c5 2. Nf3 Nc6 3. Nc3 g6 4. d4 cxd4 5. Nxd4 Bg7 6. Be3 Nf6 7. Bc4 O-O 8. Bb3 d6 9. f3 Bd7 10. h4  h5 11. Qd2 Rc8 12. O-O-O Ne5 13. g4  hxg4 14. h5 Nxh5 15. Bh6 Kh7  16. Bg5  Rxc3  17. bxc3 gxf3 18. Nf5  Bxf5 19. exf5 Qc7  20. Kb1 d5  21. Qxd5 e6 22. fxg6+ fxg6 23. Qxe6 Qxc3 24. Rd6  Rf7  25. Bd2 Qc7 26. Be3  Qe7 27. Qxe7  Rxe7 28. Bg5  Re8 29. Bd5 Bf8 30. Rd8 Rxd8 31. Bxd8 Bc5  32. Bc7  Bd4 33. Bxe5 Bxe5 34. Bxf3 Kh6 35. Bxb7 Kg5 36. c4 Nf4 37. Kc2 Kf6 38. Be4 Bd4 39. Rh7 g5 40. Rd7 Bb6 41. Bf3 Ne6  42. Bg4 Nf4 43. a4 Ke5 44. Kb3 Bd4 45. Rf7 Ke4 46. Rf5 Ne6 47. Kb4 Be3 48. Rf7 Nd4 49. Bh3 Nc6+ 50. Kb5 Nd4+ 51. Kb4 Nc6+ 52. Kb5 Nd4+ 53. Ka6 Nb3 54. Bg2+  Kd3 55. Re7 Bc5 56. Bf1+ Kc3 57. Re5 Kb4 58. Rxg5  Kxa4 59. Be2 Kb4 60. Bd1 Nd2 61. Rg4 Nf1 62. Be2 Ne3  63. Rg1  Nc2 64. Rc1 Nd4 65. Bf1  Nb3 66. Rb1 Bb6 67. Be2 Kc3 68. Bd1 Nd2 69. Rc1+ Kb4 70. Be2 Nb3 71. Rb1 Kc3 72. Bd1 Nd2 73. Rc1+ Kb4 74. Be2 Nb3 1/2-1/2 "

; sample game 576
EventSites(576) = "World Cities-ch KO  Al Ain" : GameDates(576) = "20121228" : WhitePlayers(576) = "Tiviakov, Sergei   G#576" : WhiteElos(576) = "2663" : BlackPlayers(576) = "Mamedov, Nidjat   G#576" : BlackElos(576) = "2602" : Each_Game_Result(576) = "1-0"

FilePGNs(576) = "1. e4 c5 2. Nf3 e6 3. c3 Nf6 4. e5 Nd5 5. Bc4 d6 6. exd6 Bxd6 7. d4 Nc6 8. dxc5 Bxc5 9. O-O O-O 10. Nbd2 Be7 11. Nb3 b6  12. Bxd5 exd5 13. Nbd4 Nxd4 14. Nxd4 Bf6 15. Be3 Re8 16. Re1 Bxd4 17. Bxd4 Bf5 18. a4 Qd7 19. a5 Rxe1+ 20. Qxe1 Re8 21. Qd1 Qe6 22. h3 Qg6 23. Qf3 h6 24. Kh2 Be4 25. Qg4 Qxg4 26. hxg4 Rb8  27. axb6 axb6 28. Ra6  b5 29. Rd6 b4 30. f3 bxc3 31. Bxc3 Bc2 32. Rxd5 Bb3 33. Rc5 f6 34. Rc7  Rb5 35. Kg3 h5 36. gxh5 Rxh5 37. Rb7 Bc4 38. b4 Rd5 39. Rc7 Bb5 40. Kf4 Rd7 41. Rc5 Bf1 42. Kg3 Kf7 43. Kf2 Bd3 44. Ke3 Bf1 45. g4 Re7+ 46. Kf2 Bd3 47. Bd4 Rb7 48. Ke3 Bb5 49. Kd2 Ke6 50. f4 Bf1  51. Kc3 Be2  52. g5 Rb5 53. Rc8 Kf5 54. Re8 Bf3 55. Be3 Rb7 56. Rc8 Be2 57. Rc5+ Ke4 58. Bd2 Bb5 59. Kb3 Bd7 60. Kc4 Be6+ 61. Kc3 Bd7 62. Rc4+ Kd5 63. Rd4+ Kc6 64. Be3 fxg5 65. fxg5 g6 66. Bf4 Bf5 67. Rd6+ Kb5 68. Rd5+ Kc6 69. Rc5+ Kb6 70. Ra5 Re7 71. Be5 Kc6 72. Bd4 Rc7 73. Be3 Re7 74. b5+ Kd5 75. Kd2 Rb7 76. Ke2 Be4 77. b6+ Ke6 78. Bd4 Bd5 79. Ke3 Rf7 80. Bf6 Rd7 81. Kf4 Bb7 82. Rc5 Rd5 83. Rc7 Rd7 84. Rc3 Rd5 85. Re3+ Kd7 86. Re7+  Kc6 87. Rg7 Rf5+ 88. Kg4 Kxb6  89. Bd4+ 1-0 "

; sample game 577
EventSites(577) = "Tata Steel-A 75th  Wijk aan Zee" : GameDates(577) = "20130115" : WhitePlayers(577) = "Carlsen, Magnus   G#577" : WhiteElos(577) = "2861" : BlackPlayers(577) = "Harikrishna, Penteala   G#577" : BlackElos(577) = "2698" : Each_Game_Result(577) = "1-0"

FilePGNs(577) = "1. e4 e5 2. Nf3 Nc6 3. c3 Nf6 4. d4 d5 5. Bb5 exd4 6. e5 Ne4 7. Nxd4 Bd7 8. Bxc6 bxc6 9. O-O Be7 10. Be3 O-O 11. Nd2 Nc5 12. b4  Nb7  13. f4 a5 14. f5  axb4 15. cxb4 Bxb4 16. Qg4 Bc3 17. Rac1 Bxd4 18. Bxd4 Rxa2 19. e6 f6 20. Nb3 Be8 21. Nc5 Nd6 22. Qf3 Qe7 23. Rf2 Ra5 24. Nb3 Rb5 25. Bc5 Bh5 26. Qc3 Qe8 27. Qe3 Qa8 28. Nd4 Rxc5 29. Rxc5 Ne4 30. Nxc6 Nxf2 31. Kxf2 Qa2+ 32. Kg3 Re8 33. h3  Qa6 34. Qc3 Be2 35. Rxd5 Bb5 36. Nb4 Qb7 37. Qc5 Ba4 38. Rd7 Qe4 39. Rxc7 h5 40. Kh2 Kh7 41. Qf2 Rg8 42. Na6 Be8 43. Rc5 Qd3 44. Nb4 Qd6+ 45. Kh1 Qd1+ 46. Qg1 Qd6 47. Nd5 Rf8 48. Qd4 Kh8 49. Rc8 Bc6 1-0 "

; sample game 578
EventSites(578) = "Tata Steel-B 75th  Wijk aan Zee" : GameDates(578) = "20130117" : WhitePlayers(578) = "Smeets, Jan   G#578" : WhiteElos(578) = "2615" : BlackPlayers(578) = "Naiditsch, Arkadij   G#578" : BlackElos(578) = "2708" : Each_Game_Result(578) = "0-1"

FilePGNs(578) = "1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. exd5 exd5 5. Bd3 Nf6 6. a3 Be7 7. h3 Nbd7 8. Nf3  c5  9. O-O O-O 10. Bf4 a6 11. Re1 Re8 12. Qd2 c4 13. Be2  b5 14. Ne5 Bb7 15. Bf3 Nf8 16. Ng4  Ne4  17. Bxe4 dxe4 18. Rad1 f5 19. Ne5 Ne6 20. Be3 Bf6 21. a4  Nc7 22. axb5 axb5 23. Qe2 Rc8 24. Ra1 Ne6  25. Ra7 Re7 26. Qd2  b4 27. Ne2 c3 28. bxc3 bxc3 29. Qc1 g5  30. g3 Rg7 31. Kh2  f4  32. gxf4 gxf4 33. Bxf4 Nxd4 34. Rd1 Bxe5 35. Nxd4 Qg5  0-1 "

; sample game 579
EventSites(579) = "Tata Steel-A 75th  Wijk aan Zee" : GameDates(579) = "20130119" : WhitePlayers(579) = "L'Ami, Erwin   G#579" : WhiteElos(579) = "2627" : BlackPlayers(579) = "Giri, Anish   G#579" : BlackElos(579) = "2720" : Each_Game_Result(579) = "1/2-1/2"

FilePGNs(579) = "1. Nf3 d5 2. g3 c6 3. c4 Bg4 4. Qb3 Qc7  5. Bg2 e6 6. O-O Nf6 7. d4 Bd6 8. Nc3 O-O 9. Nd2  Nbd7 10. e4 dxe4 11. Ndxe4 Nxe4 12. Nxe4 Be7 13. Bf4 Qb6 14. Qxb6  axb6 15. Bd6 Rfe8 16. Bxe7 Rxe7 17. Nd6 Rb8 18. b4  Nf6 19. a4 Ne8 20. Nxe8 Rexe8 21. c5 e5  22. f3  Bf5 23. cxb6 exd4 24. Rfd1 Rbd8 25. Rd2 d3 26. a5 h5 27. f4 Be4 28. Bxe4 Rxe4 29. Ra3 Red4 30. Kf2 f5 1/2-1/2 "

; sample game 580
EventSites(580) = "Tata Steel-A 75th  Wijk aan Zee" : GameDates(580) = "20130119" : WhitePlayers(580) = "Anand, Viswanathan   G#580" : WhiteElos(580) = "2772" : BlackPlayers(580) = "Van Wely, Loek   G#580" : BlackElos(580) = "2679" : Each_Game_Result(580) = "1-0"

FilePGNs(580) = "1. e4 d5 2. exd5 Qxd5 3. Nc3 Qa5 4. d4 Nf6 5. Bd2 Bg4  6. f3 Bd7  7. Bc4 Qb6 8. Nge2 e6 9. Bb3 Nc6  10. Be3 Na5 11. O-O Nxb3 12. axb3 Be7 13. Nf4 O-O 14. Re1 Rfd8 15. Nd3  Qd6 16. Bf2 Bc6 17. Ne4  Nxe4 18. fxe4 f5  19. exf5 exf5 20. c4 Be4  21. Nc5 Qg6 22. Nxe4 fxe4 23. Qb1 Bf6 24. Qxe4 Qxe4 25. Rxe4 c6 26. Kf1 Rd7 27. Ke2 a6 28. Kd3 Rad8 29. Rae1 Kf7 30. Be3 h5 31. Rf1 Kg6 32. b4 Rd6 33. h3  R6d7 34. g4 hxg4 35. hxg4 Rf8  36. g5  Bxd4 37. Re6+  1-0 "

; sample game 581
EventSites(581) = "Tata Steel-B 75th  Wijk aan Zee" : GameDates(581) = "20130120" : WhitePlayers(581) = "Edouard, Romain   G#581" : WhiteElos(581) = "2686" : BlackPlayers(581) = "Dubov, Daniil   G#581" : BlackElos(581) = "2600" : Each_Game_Result(581) = "1-0"

FilePGNs(581) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 d6 6. Bg5 e6 7. Qd2 a6 8. O-O-O Bd7 9. f4 b5 10. Bxf6 gxf6 11. Kb1 Qb6 12. Nf3  Qc5  13. f5  Ne5 14. Nxe5 Qxe5 15. Bd3 b4 16. Ne2 a5 17. Bc4  Rc8 18. b3 a4 19. Nd4 axb3  20. Bxb3 Be7 21. Rhe1 Rc3 22. Qh6 Bf8 23. Qh4 Be7 24. Qh6 Bf8 25. Qh4 Be7 26. Qg4 h5 27. Qg7 Rf8 28. Qh7 Kd8 29. Qxh5 Qc5 30. Qh6 e5 31. Ne2 Re3 32. Nc1  Rxe1 33. Rxe1 Bb5 34. Qd2 Rh8 35. h3 Bf8 36. Nd3 Bxd3 37. Qxd3 Bh6 38. Bxf7 Ke7 39. Bb3 Rc8 40. Qe2 Qc3 41. Rd1 Qe3 42. Qh5 Rf8 43. Qg6 Qg5 44. h4 Qxg6 45. fxg6 Bg7 46. g4 Rh8 47. h5 Rc8 48. Rf1 Rc7 49. Kc1 Bh6+ 50. Kd1 Bg7 51. Ke2 Bh6 52. Rf5 Bg7 53. g5 fxg5 54. Rf7+ Kd8 55. Rxg7  Rxg7 56. Bf7 Rxf7 57. h6 1-0 "

; sample game 582
EventSites(582) = "Tata Steel-A 75th  Wijk aan Zee" : GameDates(582) = "20130120" : WhitePlayers(582) = "Carlsen, Magnus   G#582" : WhiteElos(582) = "2861" : BlackPlayers(582) = "Karjakin, Sergey   G#582" : BlackElos(582) = "2780" : Each_Game_Result(582) = "1-0"

FilePGNs(582) = "1. Nf3 Nf6 2. g3 d5 3. Bg2 c6 4. O-O Bg4 5. c4 e6 6. d3 Nbd7 7. cxd5 exd5 8. Qc2 Be7 9. Nc3 Bxf3 10. Bxf3 d4 11. Ne4 O-O 12. Nxf6+ Nxf6  13. Bd2 a5 14. a3 Nd5  15. Rab1 Qd7 16. Rfc1 Rfe8 17. Qc4 Nc7 18. h4 a4 19. Bb4 Nb5 20. Kg2 h6 21. Bc5 g6 22. Qb4 Bf6 23. Qd2 Kg7 24. Rc4 Ra6 25. Qd1 b6 26. Bb4 c5 27. Bd2 Nc7  28. Rcc1 Nd5 29. Qh1  Be7 30. Kg1 Rd8 31. Rc2 Qe6 32. Qg2 Ra7 33. Re1 Rad7 34. Kh2 Rc8 35. Qh3 Qxh3+ 36. Kxh3 h5 37. Rb1 Ra8 38. Kg2 Ra6 39. b3 axb3 40. Rxb3 Bf6 41. Rc4 Rd6 42. Kf1 Kf8 43. a4 Nc3  44. Bf4 Re6 45. e3 Nxa4 46. Bd5  Re7 47. Bd6 b5 48. Bxe7+ Bxe7 49. Rxb5 Nb6 50. e4 Nxc4 51. Rb8+ Kg7 52. Bxc4 Ra7 53. f4 Bd6 54. Re8 Rb7 55. Ra8 Be7 56. Kg2 Rb1 57. e5 Re1 58. Kf2 Rb1 59. Re8 Bf8 60. Rc8 Be7 61. Ra8 Rb2+ 62. Kf3 Rb1 63. Bd5 Re1 64. Kf2 Rd1 65. Re8 Bf8 66. Bc4 Rb1 67. g4  hxg4 68. h5 Rh1   69. hxg6 fxg6 70. Re6 Kh6 71. Bd5 Rh2+ 72. Kg3 Rh3+ 73. Kxg4 Rxd3 74. f5 Re3 75. Rxg6+ Kh7 76. Bg8+ Kh8 77. Kf4 Rc3 78. f6 d3 79. Ke3 c4 80. Be6 Kh7 81. Bf5 Rc2 82. Rg2+ Kh6 83. Rxc2 dxc2 84. Bxc2 Kg5 85. Kd4 Ba3 86. Kxc4 Bb2 87. Kd5 Kf4 88. f7 Ba3 89. e6 Kg5 90. Kc6 Kf6 91. Kd7 Kg7 92. e7 1-0 "

; sample game 583
EventSites(583) = "Tata Steel-A 75th  Wijk aan Zee" : GameDates(583) = "20130122" : WhitePlayers(583) = "Sokolov, Ivan   G#583" : WhiteElos(583) = "2663" : BlackPlayers(583) = "Van Wely, Loek   G#583" : BlackElos(583) = "2679" : Each_Game_Result(583) = "0-1"

FilePGNs(583) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 O-O 5. Ne2 d5 6. a3 Be7 7. cxd5 exd5 8. h3  a5 9. g4 c6 10. Bg2 Na6 11. b3 Nc7 12. Ra2 Nfe8  13. O-O f5 14. Ng3 Nd6 15. f3 Bh4 16. Nh5 Ne6 17. Ne2 Qe8 18. a4 g6 19. Ba3 Qe7 20. Nhg3 Ng5 21. Qc1 Bd7 22. gxf5 gxf5 23. Nh5 Kh8 24. Nef4 Be8 25. Kh2  Rg8  26. e4  Bxh5 27. Nxh5 Ne6  28. exd5 cxd5 29. Re2 Qd7 30. Qe3 Ng7  31. Nf4  Nf7  32. Qc3  Rgc8 33. Qd2 Bg5 34. h4  Bxh4 35. Bh3  Bg5 36. Rg1 Qc7 37. Rxg5 Nxg5 38. Kg2 Qc6 39. Nd3 Qh6 0-1 "

; sample game 584
EventSites(584) = "Tata Steel-A 75th  Wijk aan Zee" : GameDates(584) = "20130123" : WhitePlayers(584) = "Carlsen, Magnus   G#584" : WhiteElos(584) = "2861" : BlackPlayers(584) = "L'Ami, Erwin   G#584" : BlackElos(584) = "2627" : Each_Game_Result(584) = "1-0"

FilePGNs(584) = "1. e4 c6 2. d4 d5 3. Nd2 dxe4 4. Nxe4 Bf5 5. Ng3 Bg6 6. Bc4 e6 7. N1e2 b5  8. Bb3 Bd6 9. Nf4 Bxf4 10. Bxf4 Nf6 11. O-O O-O 12. c4  bxc4 13. Bxc4 Qb6 14. Qd2 Rd8 15. Rfd1 Nbd7 16. Rac1 Nd5 17. Bd6 N7f6 18. Bc5 Qb8 19. f3 h6 20. Ne2 Nd7 21. Ba3 e5 22. b3  Qb6 23. Nc3 N7f6  24. Bc5 Qc7 25. dxe5 Qxe5 26. Bd4 Qe7 27. Re1 Qd6 28. Qf2 Nxc3 29. Bxc3 Nd5 30. Be5 Qa3 31. h4 f6 32. Bd4 Kh7 33. Bxd5 Rxd5 34. Rxc6 Qb4 35. Rc4 Qd6 36. Bc5 Qd8 37. Kh2 a6 38. Be7 Qb8+ 39. Qg3 Qxg3+ 40. Kxg3 Ra7 41. Rc6 a5 42. Bc5 Rad7 43. Be3 R7d6 44. Rc4 Re6 45. Kf2 Rde5 46. Rc3 Be8 47. Bd2 a4 48. Rxe5 Rxe5 49. b4 Bb5  50. Be3 h5 51. Rc7 Kg6 52. Ra7 Rd5 53. Kg3 Rd3 54. Bc5 Ra3  55. Bf8 Rxa2 56. Kf4 Kh7 57. Rxg7+ Kh8 58. Kf5  Rc2 59. Kxf6 a3 60. Ra7  a2 61. g3 Rc6+ 62. Kg5 Kg8 63. Bc5 Ba6 64. Bd4 Rd6 65. Ba1 1-0 "

; sample game 585
EventSites(585) = "Tata Steel-A 75th  Wijk aan Zee" : GameDates(585) = "20130125" : WhitePlayers(585) = "Giri, Anish   G#585" : WhiteElos(585) = "2720" : BlackPlayers(585) = "Caruana, Fabiano   G#585" : BlackElos(585) = "2781" : Each_Game_Result(585) = "1-0"

FilePGNs(585) = "1. d4 d5 2. c4 e6 3. Nf3 c6 4. Nc3 dxc4 5. a4 Bb4 6. g3  Nf6 7. Bg2 Nbd7 8. O-O O-O 9. Qc2 Qa5 10. Na2 Bd6 11. Qxc4 Nb6   12. Qc2 Qxa4 13. b3 Qa5  14. Ne5 Nbd7 15. Nc4 Qc7 16. Nxd6 Qxd6 17. Rd1  e5  18. Nc3   exd4 19. Ba3 c5 20. e3 d3 21. Rxd3 Qb8 22. Nd5 Nxd5 23. Rxd5 b6 24. Bb2  a5 25. Ra4 Re8 26. Rg5 g6 27. Bd5 Kf8 28. Rf4 1-0 "

; sample game 586
EventSites(586) = "Tata Steel-A 75th  Wijk aan Zee" : GameDates(586) = "20130126" : WhitePlayers(586) = "Sokolov, Ivan   G#586" : WhiteElos(586) = "2663" : BlackPlayers(586) = "Hou, Yifan   G#586" : BlackElos(586) = "2603" : Each_Game_Result(586) = "0-1"

FilePGNs(586) = "1. d4 e6 2. c4 Nf6 3. Nf3 d5 4. Nc3 Bb4 5. Bg5 h6 6. Bh4 dxc4 7. a3 Bxc3+ 8. bxc3 c5  9. Bxf6 Qxf6 10. e3 Nc6 11. Bxc4 O-O 12. Bb5 Bd7 13. O-O Rfd8  14. a4 Qe7 15. Qb1 Rab8 16. Qe4 cxd4 17. exd4 Qf6 18. Bd3 g6 19. Rfe1 Ne7 20. c4 Nf5 21. d5 exd5 22. cxd5 Re8 23. Ne5  Qd6 24. f4 f6 25. Kh1 h5  26. Qe2 Rbd8 27. Bc4 Re7 28. Qb2 Rde8 29. Nf3 Rxe1+ 30. Nxe1 Qxf4  31. Bd3 Qe3 32. h3 Ng3+ 33. Kh2 Qf4 34. Kg1 h4 35. Qf2 Qxf2+ 36. Kxf2 Ne4+ 37. Kg1 g5  38. a5 Nd6 39. Nf3 Rc8 40. a6 b6 41. Re1 Kf7 42. Rf1 Ke7 43. Re1+ Kd8 44. Bh7 Rc4 45. Bg8 Ra4 46. Be6 Rxa6 47. Nh2 b5 48. Ng4 Ne8 49. Nh6 Bxe6 50. dxe6 Ng7 51. e7+ Ke8 52. Ng8 f5 0-1 "

; sample game 587
EventSites(587) = "Tata Steel-C 75th  Wijk aan Zee" : GameDates(587) = "20130126" : WhitePlayers(587) = "Mekhitarian, Krikor Sevag   G#587" : WhiteElos(587) = "2543" : BlackPlayers(587) = "Gretarsson, Hjorvar Stein   G#587" : BlackElos(587) = "2516" : Each_Game_Result(587) = "1-0"

FilePGNs(587) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. d3 b5 7. Bb3 d6 8. a4 Bd7 9. c3 O-O 10. Bc2  Re8 11. h3 Bf8 12. Re1 g6 13. Nbd2 Bg7 14. Nf1 h6 15. Ne3 Kh7 16. Kh2 Rb8 17. axb5  axb5 18. Bb3 Be6 19. Bxe6 Rxe6 20. Qb3 Nd7 21. Bd2 Nc5 22. Qc2 Re8 23. h4  Ne6 24. g3 Ra8 25. Qb3 Qf6 26. Rxa8 Rxa8 27. Qd1  Nc5 28. Nd5 Qd8 29. Be3 Ne6  30. Qb3 Qb8 31. Kg2 Qb7 32. Rc1 Na5 33. Qd1 Nc6 34. h5  g5 35. Nh2 f5 36. Qf3 f4 37. Qg4  Qc8 38. Qf5+ Kh8 39. Bd2 Nc5 40. Qg6  Qd7 41. Nf6 Bxf6 42. Qxh6+ Qh7 43. Qxf6+ Qg7 44. Qxg7+ Kxg7 45. Rg1  Rh8  46. gxf4 exf4 47. d4  Nxe4 48. Bxf4 Kf6  49. Bc1 Kf5  50. Nf1  d5 51. Rh1 Ne7 52. f3 Nd6 53. Ne3+ Ke6 54. Ng4 Nf7 55. Re1+ Kd6 56. Ne5  Nxe5 57. Rxe5 Rxh5 58. Bxg5 Ng6 59. Be7+ Kd7 60. Rxh5 Nf4+ 61. Kg3 Nxh5+ 62. Kg4 Ng7 63. Bf6 Ne6 64. f4 Ke8 65. Kf5 Kf7 66. Bg5 b4 67. Ke5 c5 68. dxc5 bxc3 69. bxc3 Nxc5 70. Kxd5 Nb7 71. c4 1-0 "

; sample game 588
EventSites(588) = "Tata Steel-A 75th  Wijk aan Zee" : GameDates(588) = "20130126" : WhitePlayers(588) = "Carlsen, Magnus   G#588" : WhiteElos(588) = "2861" : BlackPlayers(588) = "Nakamura, Hikaru   G#588" : BlackElos(588) = "2769" : Each_Game_Result(588) = "1-0"

FilePGNs(588) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 e5 5. Nb5 d6 6. g3  h5  7. N1c3 a6 8. Na3 b5 9. Nd5 Nge7 10. Bg2 Bg4  11. f3 Be6 12. c3 h4 13. Nc2 Bxd5  14. exd5 Na5 15. f4  Nf5  16. g4  h3 17. Be4 Nh4 18. O-O g6 19. Kh1 Bg7 20. f5  gxf5 21. gxf5 Ng2  22. f6  Bf8 23. Qf3 Qc7 24. Nb4 Nb7 25. Nc6 Nc5 26. Bf5 Nd7 27. Bg5 Rg8 28. Qh5 Nb6 29. Be6 Rxg5 30. Qxg5 fxe6 31. dxe6 1-0 "

; sample game 589
EventSites(589) = "Gibraltar Masters 11th  Caleta" : GameDates(589) = "20130126" : WhitePlayers(589) = "Al Sayed, Mohamad Naser   G#589" : WhiteElos(589) = "2507" : BlackPlayers(589) = "Georgiev, Kiril   G#589" : BlackElos(589) = "2643" : Each_Game_Result(589) = "0-1"

FilePGNs(589) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 d5 5. a3 Bxc3+ 6. Qxc3 dxc4 7. Qxc4 b6 8. Bf4 O-O  9. Bxc7 Qd7 10. Be5 Ba6 11. Qb3 Rc8 12. Bxf6 gxf6 13. e3 Bxf1 14. Kxf1 Nc6 15. Qb5 a6  16. Qxb6  Rcb8 17. Qc5 Rxb2 18. g3 e5  19. Nf3 Rc8 20. Qc3 Qb7 21. Qd3 Nxd4  0-1 "

; sample game 590
EventSites(590) = "Tata Steel-A 75th  Wijk aan Zee" : GameDates(590) = "20130127" : WhitePlayers(590) = "Karjakin, Sergey   G#590" : WhiteElos(590) = "2780" : BlackPlayers(590) = "Van Wely, Loek   G#590" : BlackElos(590) = "2679" : Each_Game_Result(590) = "1-0"

FilePGNs(590) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 g6 6. Be3 Bg7 7. f3 Nc6 8. Qd2 O-O 9. O-O-O d5 10. exd5 Nxd5 11. Nxc6 bxc6 12. Bd4 Bxd4 13. Qxd4 Qb6 14. Na4 Qc7 15. Bc4 Rd8 16. Nc5  Bf5 17. Bb3 h5  18. g4  e5 19. Qg1  Nf4 20. Re1  hxg4 21. fxg4 Bc8 22. Qg3  a5  23. Qh4  a4  24. Bxf7+  Kg7 25. Ne4 1-0 "

; sample game 591
EventSites(591) = "Gibraltar Masters 11th  Caleta" : GameDates(591) = "20130131" : WhitePlayers(591) = "Zhao Xue   G#591" : WhiteElos(591) = "2554" : BlackPlayers(591) = "Ivanchuk, Vassily   G#591" : BlackElos(591) = "2758" : Each_Game_Result(591) = "1/2-1/2"

FilePGNs(591) = "1. d4 d5 2. c4 dxc4 3. e3 e6 4. Bxc4 c5 5. Nf3 Nf6 6. O-O a6 7. dxc5 Qxd1 8. Rxd1 Bxc5 9. a3 Nbd7 10. Be2 O-O 11. Bd2 b6 12. Nc3 Bb7 13. Be1 Rfc8 14. Rac1 Be7 15. Nd2 b5 16. b4 Rc7 17. Na2 Rac8 18. Rxc7 Rxc7 19. Rc1 Ne8 20. Rxc7 Nxc7 21. Nb3 Bd5 22. Bd1 Nb6 23. Nc3 Nc4 24. Nb1 f5  25. Bc2 Kf7 26. Bc3 Ne8 27. Kf1 Nf6 28. Bd4 Nd7 29. N3d2 e5 30. Bc3 e4 31. Ke2 g6 32. Bd4 Nde5 33. Nb3 Nd3 34. f3 Ke6 35. N3d2 Bd6 36. h3 exf3+ 37. gxf3 Nde5 38. e4 fxe4 39. Nxe4 Nc6 40. Bf2 Be7 41. Nc5+ Bxc5 42. Bxc5 Ke5 43. Kf2 Kf4 44. a4 bxa4 45. Bxa4 Bxf3 46. Nd2 Nxd2 47. Be3+ Kf5 48. Bxc6 1/2-1/2 "

; sample game 592
EventSites(592) = "Gibraltar Masters 11th  Caleta" : GameDates(592) = "20130131" : WhitePlayers(592) = "Vitiugov, Nikita   G#592" : WhiteElos(592) = "2694" : BlackPlayers(592) = "Vachier Lagrave, Maxime   G#592" : BlackElos(592) = "2713" : Each_Game_Result(592) = "1/2-1/2"

FilePGNs(592) = "1. d4 Nf6 2. c4 g6 3. f3 e6  4. e4 d5 5. e5 Nh5 6. f4  Qh4+ 7. g3 Nxg3 8. Nf3 Qh5 9. hxg3 Qxh1 10. Nc3 h5  11. Be3  h4 12. gxh4 c6 13. Kd2  Rxh4  14. Nxh4 Qxh4 15. Qf3  Bd7  16. Bd3  Na6 17. Rh1 Qd8 18. a3  dxc4 19. Bxc4 Qa5 20. Rh7   O-O-O 21. Rxf7 Nc7 22. Kc2 b5  23. Bb3 b4 24. axb4 Bxb4 25. Ne4  Nd5 26. Bd2  Bxd2 27. Nxd2 Rh8   28. Nf1  Qe1   29. Bxd5  exd5 30. Rxd7  Kxd7 31. Qg4+ Kc7 32. Qxg6 Qf2+  33. Nd2 Rh2  34. Qd6+ Kb7 35. Qb4+ Kc8 36. Qf8+ 1/2-1/2 "

; sample game 593
EventSites(593) = "Grenke Chess Classic 1st  Baden-Baden" : GameDates(593) = "20130207" : WhitePlayers(593) = "Caruana, Fabiano   G#593" : WhiteElos(593) = "2757" : BlackPlayers(593) = "Meier, Georg   G#593" : BlackElos(593) = "2640" : Each_Game_Result(593) = "1-0"

FilePGNs(593) = "1. e4 e6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Nd7 5. Nf3 Ngf6 6. Nxf6+ Nxf6 7. Be3 Nd5 8. Bd2 c5 9. Bb5+ Bd7 10. Bxd7+ Qxd7 11. c4 Nb6 12. Rc1 f6 13. O-O cxd4 14. Re1 Rc8 15. Qb3 Be7 16. c5 Rxc5 17. Rxc5 Bxc5 18. Rxe6+ Kd8 19. Re1 Qd5 20. Qd3 Nd7  21. b4 Bb6 22. a4 a6  23. a5 Ba7  24. Bf4  Nb8 25. Bxb8 Bxb8 26. Nxd4 Qd6 27. Ne6+ Ke7 28. Nc5+ Kf7 29. Qc4+ Kg6 30. g3 h5 31. Qe4+ Kh6 32. Qxb7 Qd2 33. Re7 Qd1+ 34. Kg2 h4 35. Qd7 Bd6 36. Ne4 1-0 "

; sample game 594
EventSites(594) = "Grenke Chess Classic 1st  Baden-Baden" : GameDates(594) = "20130208" : WhitePlayers(594) = "Naiditsch, Arkadij   G#594" : WhiteElos(594) = "2716" : BlackPlayers(594) = "Adams, Michael   G#594" : BlackElos(594) = "2725" : Each_Game_Result(594) = "1-0"

FilePGNs(594) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 O-O 5. Bd3 d5 6. Nf3 c5 7. O-O Nc6 8. cxd5 exd5 9. dxc5 Bxc5 10. h3 Qe7 11. b3 Rd8 12. Bb2 Ne4 13. Rc1 Bf5 14. Ne2 Rac8 15. Nf4 Ba3 16. Qe2 Bg6 17. Rfd1 a6 18. Bb1 Bxb2 19. Qxb2 Nf6 20. Bxg6 hxg6 21. Rc2 Rc7 22. Rcd2 Qc5 23. Nd3 Qb6 24. Nde5 Nxe5 25. Qxe5 Re8 26. Qf4 Re4  27. Rxd5  Rc8  28. Rd6  Qa5 29. Qg3 Ree8 30. Ng5 Qxa2 31. Qh4  Qxb3 32. R1d3 Qc4 33. R3d4 Qc1+ 34. Kh2 Qc7 35. Kg1 Qc1+ 36. Rd1 Qc4 37. e4  Rc5 38. Rd8 Rc8 39. R8d6 Rc5 40. Rd8 Rc8 41. R8d4 Qe2 42. Kh2 Rc5 43. Rd8 Re5 44. f4 Rxd8 45. Rxd8+ Re8 46. Rd4 Qe3 47. Rb4 Nh5 48. e5 f6 49. Nf3 a5 50. Rd4 fxe5 51. fxe5 Rf8 52. Re4 Qb6 53. Qg4 Qc6 54. Rd4 Qe8 55. Qg5 Kh7 56. Qe3 Rxf3  57. gxf3 Qe6 58. Rd6 Qa2+ 59. Rd2 Qe6 60. Rd6 Qa2+ 61. Qd2 Qb3 62. e6  Qxf3 63. Rd3 Qc6 64. Qe3 a4 65. e7 Nf6 66. Kg1 b5 67. Rd4 Ne8 68. Rf4 Qd5 69. Kf2 Qc6 70. Ke1 Qh1+ 71. Kd2 Qd5+ 72. Kc1 Qg5 73. h4 Qd5 74. Kb2 Nd6 75. h5  Qxh5 76. Rd4 Ne8 77. Rf4 Qh2+ 78. Qf2 a3+ 79. Ka2 1-0 "

; sample game 595
EventSites(595) = "Grenke Chess Classic 1st  Baden-Baden" : GameDates(595) = "20130213" : WhitePlayers(595) = "Fridman, Daniel   G#595" : WhiteElos(595) = "2667" : BlackPlayers(595) = "Naiditsch, Arkadij   G#595" : BlackElos(595) = "2716" : Each_Game_Result(595) = "0-1"

FilePGNs(595) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. O-O Nc6 8. Be3 Ng4 9. Bg5 f6 10. Bh4 g5 11. Bg3 Nh6 12. dxe5 fxe5 13. h3 Kh8 14. c5  g4 15. hxg4 Bxg4 16. cxd6 cxd6 17. Nd2  Bc8  18. Nc4 Nd4 19. Ne3 Nf7 20. Nc2  Ng5 21. Bd3 Ndf3+  22. gxf3 Qd7  23. Be2 Rf6 24. Nd5 Rh6 25. f4  Nh3+ 26. Kg2 exf4 27. Bh2 f3+  28. Bxf3 Ng5 29. Nf4 Rxh2+  30. Kxh2 Be5 31. Kg2 Bxf4 32. Rh1 Qg7 33. Kf1 Be6 34. Nd4  Bc4+ 35. Be2 Nxe4  36. Bxc4  Nd2+ 37. Ke2 d5  38. Qc2 Re8+ 39. Kd1 Nxc4 40. Qc3 Re4 41. Nf5 Nxb2+ 42. Kc2 Re2+ 43. Kb3 Qxc3+ 44. Kxc3 Be5+ 45. Nd4 Re4 0-1 "

; sample game 596
EventSites(596) = "Grenke Chess Classic 1st  Baden-Baden" : GameDates(596) = "20130215" : WhitePlayers(596) = "Naiditsch, Arkadij   G#596" : WhiteElos(596) = "2716" : BlackPlayers(596) = "Caruana, Fabiano   G#596" : BlackElos(596) = "2757" : Each_Game_Result(596) = "0-1"

FilePGNs(596) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Bxc6 dxc6 5. O-O Qf6 6. d4 exd4 7. Bg5 Qd6 8. Nxd4 Be7  9. Be3  Nf6 10. f3 O-O 11. Nd2 c5   12. Nc4  Qd8 13. Ne2 Qe8 14. Bf4  b5  15. Ne3 c4 16. Kh1  Qc6 17. Nd4 Qb6 18. Ndf5 Bc5 19. Qe1   g6  20. Nh6+ Kg7 21. g4  Bb7  22. g5 Nh5  23. Be5+ f6 24. gxf6+ Nxf6 25. Neg4  Bd4   26. Bxd4 Qxd4 27. Rd1  Qxb2  28. Nxf6  Qxf6  29. Ng4 Qf4 30. Rd7+ Rf7 31. Qc3+ Kg8 32. Rxf7 Kxf7 33. Rd1 Rf8 34. Kg2 Bc8 35. h3  Kg8  36. e5  Qg5  37. Qd4  Bb7   38. Kh2 Bxf3 39. Nf6+ Kg7 40. Rg1 Qf5 41. Kg3 Bc6 42. h4 Rf7 43. Qe3 Re7 44. Ng4 h5 45. Qh6+ Kg8 46. Nf6+ Kf7 47. Qh7+ Ke6 48. Qg8+ Kxe5 49. Re1+ Kd4 0-1 "

; sample game 597
EventSites(597) = "Grenke Chess Classic 1st  Baden-Baden" : GameDates(597) = "20130216" : WhitePlayers(597) = "Anand, Viswanathan   G#597" : WhiteElos(597) = "2780" : BlackPlayers(597) = "Fridman, Daniel   G#597" : BlackElos(597) = "2667" : Each_Game_Result(597) = "1-0"

FilePGNs(597) = "1. e4 e5 2. Nf3 Nf6 3. Nxe5 d6 4. Nf3 Nxe4 5. d4 d5 6. Bd3 Nc6 7. O-O Be7 8. c4 Nb4 9. Be2 O-O 10. Nc3 Bf5 11. a3 Nxc3 12. bxc3 Nc6 13. Re1 Re8 14. cxd5 Qxd5 15. Bf4 Rac8 16. h3 h6 17. Nd2 Na5  18. Bf3 Qd7 19. Ne4 Rcd8 20. Ra2   b6 21. Rae2 Bxa3  22. Bg4  Rf8  23. Bxf5 Qxf5 24. Bxc7  Rd7 25. Be5  f6  26. Ng3 Qe6 27. Qa4  Nc4  28. Bd6   b5 29. Rxe6 bxa4 30. Bxf8 Kxf8 31. Ra1 Bb2 32. Rxa4 Nb6 33. Ra6 Bxc3 34. Nf5 Bb4 35. Re2 Kf7 36. Rea2 Nc8 37. g4 g6 38. Nxh6+ Kg7 39. g5 fxg5 40. Ng4 Rxd4 41. Rc2 Ne7 42. Rxa7 Bd6 43. Kg2 Kf7 44. Re2 Bb4 45. Re5 Bd6 46. Rxg5 Ke6 47. Ra6 1-0 "

; sample game 598
EventSites(598) = "Grenke Chess Classic 1st  Baden-Baden" : GameDates(598) = "20130217" : WhitePlayers(598) = "Naiditsch, Arkadij   G#598" : WhiteElos(598) = "2716" : BlackPlayers(598) = "Anand, Viswanathan   G#598" : BlackElos(598) = "2780" : Each_Game_Result(598) = "0-1"

FilePGNs(598) = "1. e4 c5 2. Nf3 d6 3. Bb5+ Bd7 4. Bxd7+ Qxd7 5. c4 Nf6 6. Nc3 g6 7. d4 cxd4 8. Nxd4 Bg7 9. O-O Nc6 10. Nde2 Qe6  11. Nd5  Qxe4 12. Nc7+ Kd7 13. Nxa8 Qxc4 14. Nc3 Rxa8 15. Bg5 e6  16. Re1 Nd5  17. Nxd5 Qxd5 18. Qxd5 exd5 19. Rad1 h6 20. Bc1 d4  21. Rd3 Rc8 22. Rb3 b6 23. Kf1 Ne5 24. Ra3 a5  25. b4 Rc2  26. bxa5 bxa5 27. Rxa5  Nd3 28. Ra7+ Kc6 29. Rxf7 Nxe1 30. Kxe1 Rxc1+ 31. Kd2 Rg1 32. Rxg7 Rxg2 33. Ke1  Rxh2 34. Rxg6 Rh1+   35. Kd2 h5 36. Rh6 h4 37. a4 h3 38. a5 h2 39. a6 Kc7  40. Rh7+ Kb8 41. Ke2 d3+ 42. Kd2 Ka8 43. Rh5 Ka7 44. Rh6 d5 45. Rh8 Kxa6 46. Rh6+ Kb5 47. Rh8 Kc4 48. Rc8+ Kd4 49. Rh8 Ke4 0-1 "

; sample game 599
EventSites(599) = "Zurich Chess Challenge  Zurich" : GameDates(599) = "20130225" : WhitePlayers(599) = "Caruana, Fabiano   G#599" : WhiteElos(599) = "2757" : BlackPlayers(599) = "Kramnik, Vladimir   G#599" : BlackElos(599) = "2810" : Each_Game_Result(599) = "1/2-1/2"

FilePGNs(599) = "1. d4 Nf6 2. c4 e6 3. g3 c5 4. d5 exd5 5. cxd5 d6 6. Nc3 g6 7. Bg2 Bg7 8. Nf3 O-O 9. O-O Re8 10. Bf4 a6 11. a4 h6  12. Re1 Bf5 13. Qc1 g5 14. Bd2 Nbd7 15. h4 g4 16. Nh2 Kh7 17. Nf1 Ne5 18. Bf4 Bg6 19. Ne3 h5 20. a5 Qc7 21. Ra4 Kg8 22. Qd2 Nfd7 23. Ra2 b5 24. axb6 Qxb6 25. Be4  Bxe4 26. Nxe4 Ng6 27. Nxd6 Nxf4 28. Nec4 Nh3+ 29. Kf1 Qb8 30. Nxe8 Qxe8 31. Qc2 Ne5 32. Nd6  Qd7 33. Nf5 Bf8 34. Ne3  c4 35. Qf5 Qxf5 36. Nxf5 Bb4 37. Rd1 a5 38. Raa1 f6 39. Rac1  Bc5 40. Nd4 Kf7 41. Kg2 Rb8 42. Rc2 Rb4 43. d6  Rb6 44. Nf5 Bxf2 45. d7 Nxd7 46. Rxd7+ Ke6 47. Rh7 Kxf5 48. Rxh5+ Kg6 49. Rxa5 Rb4 50. Ra6 Bd4 51. Rc6 Bxb2 52. R6xc4 Rxc4 53. Rxc4 Kh5 1/2-1/2 "

; sample game 600
EventSites(600) = "BRA-ch 79th  Montenegro" : GameDates(600) = "20130302" : WhitePlayers(600) = "Mekhitarian, Krikor Sevag   G#600" : WhiteElos(600) = "2546" : BlackPlayers(600) = "Molina, Roberto Junio Brito   G#600" : BlackElos(600) = "2414" : Each_Game_Result(600) = "1-0"

FilePGNs(600) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Nf3 e6 5. Be2 Nd7 6. O-O Bg6 7. a4 Nh6 8. a5 a6 9. Nbd2 Be7 10. c4 dxc4  11. Nxc4 O-O 12. Bxh6 gxh6 13. Qd2  Kg7 14. Rfe1 Qc7 15. Ne3 h5 16. Qc3 Rfc8 17. Rec1 Qd8 18. Ne1 Qf8 19. Nd3 c5  20. Nf4 cxd4 21. Qxd4 Nc5 22. Nxh5+ Kh8 23. Qf4 Nb3 24. Rxc8 Rxc8 25. Rd1 Nxa5  26. Nf6  Rd8 27. h4 Rxd1+ 28. Bxd1 Nc6 29. h5 Bb1 30. Bf3  Nb4 31. Be4 Nd3 32. Qg3 Qg7 33. Neg4  Nc1 34. Qe3 1-0 "

; sample game 601
EventSites(601) = "WchT (Women) 4th  Astana" : GameDates(601) = "20130310" : WhitePlayers(601) = "Khurtsidze, Nino   G#601" : WhiteElos(601) = "2437" : BlackPlayers(601) = "Muzychuk, Mariya   G#601" : BlackElos(601) = "2479" : Each_Game_Result(601) = "0-1"

FilePGNs(601) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. Nf3 Bg7 5. e3 O-O 6. b4 b6 7. Ba3 c5  8. Rc1 cxb4 9. Bxb4 Nc6 10. Ba3 Bb7 11. cxd5 Nxd5 12. Be2 Rc8 13. Qd2 Na5 14. O-O Qd7  15. Bb5 Qe6 16. Ng5  Qg4 17. Nxd5 Rxc1  18. Qxc1  Bxd5 19. e4 Bf6  20. exd5  Bxg5 21. Qc7 Qxd4 22. Qxa7 Qxd5 23. Qxb6 Ra8 24. g3 Qxa2 25. Bb4 Nc4 26. Qc5 Nd2 27. Rd1 Ne4 28. Qd4 Nxf2  29. Qxf2 Qb3 30. Qe1 Rb8 31. Rd3  Qe6  32. Bd7  Qb6+ 33. Kg2 Qxb4 34. Qd1 Qe4+ 35. Qf3 Rb2+ 36. Kh3 Qxf3 37. Rxf3 Kg7 38. Kg4 Bf6 39. h4 h5+ 40. Kf4 Re2 41. Rd3 Re1 42. Kf3 Be5 43. Bc6 f5 44. Be8 Bd6 45. Kf2 Rb1 46. Kf3 Rb8 47. Bd7 Rb6 48. Rc3 Rb2 49. Be8 Be5  50. Rd3 Bc7 51. Ra3 Bb6 52. Kf4 Kf6 0-1 "

; sample game 602
EventSites(602) = "FIDE Candidates  London" : GameDates(602) = "20130327" : WhitePlayers(602) = "Carlsen, Magnus   G#602" : WhiteElos(602) = "2872" : BlackPlayers(602) = "Gelfand, Boris   G#602" : BlackElos(602) = "2740" : Each_Game_Result(602) = "1-0"

FilePGNs(602) = "1. e4 c5 2. Nf3 Nc6 3. Bb5  e6 4. O-O Nge7 5. Re1 a6  6. Bf1 d5 7. exd5  Nxd5 8. d4 Nf6 9. Be3 cxd4 10. Nxd4 Bd7 11. c4 Nxd4 12. Bxd4 Bc6 13. Nc3 Be7 14. a3  a5  15. Qd3 O-O 16. Rad1 Qc7 17. Be5 Qb6 18. Qg3 Rfd8 19. Rxd8+ Qxd8 20. Rd1 Qb6 21. Bd4 Qb3 22. Rd3 Qc2 23. b4  axb4 24. axb4 Nh5 25. Qe5 Bf6 26. Qxh5 Bxd4 27. Rxd4 Qxc3 28. Qa5  Rf8 29. Qb6 e5 30. Rd1 g6 31. b5 Be4 32. Qf6  h5  33. h4 Bf5 34. Rd5 Qc1  35. Qxe5 Be6 36. Rd4 Ra8 37. Qe2 Kh7  38. Rd1 Qc3 39. Qe4 Ra1  40. Rxa1 Qxa1 41. c5  Qc3 42. Qxb7 Qe1  43. b6 Bc4 44. Qf3  Qxf1+ 45. Kh2 Qb1 46. b7 Qb5 47. c6 Bd5 48. Qg3  1-0 "

; sample game 603
EventSites(603) = "Alekhine Memorial  Paris/St Petersburg" : GameDates(603) = "20130422" : WhitePlayers(603) = "Aronian, Levon   G#603" : WhiteElos(603) = "2809" : BlackPlayers(603) = "Kramnik, Vladimir   G#603" : BlackElos(603) = "2801" : Each_Game_Result(603) = "1-0"

FilePGNs(603) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 c5 5. cxd5 Nxd5 6. e4 Nxc3 7. bxc3 cxd4 8. cxd4 Bb4+ 9. Bd2 Bxd2+ 10. Qxd2 O-O 11. Rc1 b6 12. Bd3 Bb7 13. O-O Nd7 14. Qe3 Rc8 15. e5 Bxf3 16. Qxf3 Qh4 17. Qe3 Rfd8 18. f4 Nf8 19. Rxc8 Rxc8 20. f5 exf5 21. Bxf5 Rd8 22. Rd1 Ng6 23. Bxg6 hxg6 24. d5 Qc4 25. d6 Qe6 26. Qg3 b5 27. h3 a6 28. Qe3 Rd7 29. Qc5 Kh7  30. Qd5 Qe8 31. Rc1 Qd8 32. Rc6 Qg5 33. Qd4 Rd8 34. Rc5 Qg3 35. Qf2 Qxf2+ 36. Kxf2 f6 37. Rc6 fxe5 38. Ke3 Kg8 39. Ke4 Kf7 40. Kd5 a5 41. Rc5 b4 42. Rxa5 Kf6 43. Ra7 Rb8 44. Kc6 b3 45. axb3 Rxb3 46. Ra8 Rc3+ 47. Kd7 e4 48. Rf8+ Kg5 49. Ke7 e3 50. d7 e2 51. d8=Q e1=Q+ 52. Kd6+ Qe7+ 1-0 "

; sample game 604
EventSites(604) = "Alekhine Memorial  Paris/St Petersburg" : GameDates(604) = "20130423" : WhitePlayers(604) = "Gelfand, Boris   G#604" : WhiteElos(604) = "2739" : BlackPlayers(604) = "Adams, Michael   G#604" : BlackElos(604) = "2727" : Each_Game_Result(604) = "1-0"

FilePGNs(604) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Nbd7 5. Bf4 dxc4 6. e3 Nd5 7. Bxc4 Nxf4 8. exf4 Nb6 9. Bb3 Bd6 10. g3 Bd7 11. O-O O-O 12. Qd3 Bc6 13. Rad1 Qf6 14. Ng5 g6 15. Nge4 Qf5 16. d5 exd5 17. Nxd5 Nxd5 18. Bxd5 Bxd5 19. Qxd5 Qxd5 20. Rxd5 Rfd8 21. Rc1 Rac8 22. Rc3 Be7 23. Rxd8+ Bxd8 24. f5 Kg7 25. Nd6 Rb8 26. Ne8+ Kf8 27. fxg6 hxg6 28. Nxc7 Bf6 29. Rb3 Be5  30. Nd5 b6 31. Nb4 Rc8 32. Nd3 Bf6 33. h4 Rc2 34. Kf1 Ke7 35. Ke1 Kd6 36. Rb4 Bg7 37. Kd1 Rc7 38. h5  gxh5 39. Rb5  Rd7 40. Rxh5 Ke7 41. Ke2 Rc7 42. Rb5 Rc4 43. Kf3 Ra4 44. a3 Rd4 45. Ke3 Rc4 46. b3 Rc2 47. a4 Rc6 48. g4 Re6+ 49. Kf3 Rc6 50. Ke4 Re6+ 51. Kf3 Rc6 52. Nb4 Rc1 53. Ke4 Kd6 54. Nd3 Rg1 55. Kf5 Bc3 56. f4 f6 57. Nf2 Kc6 58. Ne4 a6 59. Nxc3 axb5 60. axb5+ Kd6 61. Ne4+ Ke7 62. Nxf6 Rd1 63. Kg6 Rd3 64. f5 Rd6 65. g5 Kf8 66. b4 Rd4 67. Kh6 Rh4+ 68. Nh5 Rxb4 69. g6 Rg4 70. f6 Rg1 71. Nf4 Re1 72. Nd5 Rf1 73. Kg5 Rg1+ 74. Kf5 Rf1+ 75. Ke6 Re1+ 76. Kd6 Rf1 77. Kc6 1-0 "

; sample game 605
EventSites(605) = "Zug FIDE GP  Zug" : GameDates(605) = "20130424" : WhitePlayers(605) = "Ponomariov, Ruslan   G#605" : WhiteElos(605) = "2733" : BlackPlayers(605) = "Kamsky, Gata   G#605" : BlackElos(605) = "2741" : Each_Game_Result(605) = "1-0"

FilePGNs(605) = "1. c4 c6 2. e4 d5 3. exd5 cxd5 4. d4 Nf6 5. Nc3 e6 6. Nf3 Bb4 7. Bd3 dxc4 8. Bxc4 O-O 9. O-O b6 10. Bg5 Bxc3  11. bxc3 Nbd7 12. Bd3 Bb7  13. Re1  Qc7 14. c4 Rfe8 15. Bh4 Rad8 16. Qe2  Qf4  17. Qe3 Qg4 18. h3 Qh5 19. Bxf6 Nxf6 20. Ne5 Nd7  21. f4 Nxe5 22. fxe5 Qh4 23. Rad1 Re7 24. Rf1  Kh8 25. Rf4 Qg5 26. Qf2 Red7 27. h4 Qe7 28. Rf1 Rf8 29. d5  f5 30. exf6 Rxf6   31. Re1  Rd6 32. Qe3 Rxf4 33. Qxf4 Bc8 34. h5 Rd8 35. Qe4 g6 36. hxg6 Qf6 37. gxh7  Bd7 38. Rf1 Qg7 39. dxe6 Bxe6 40. Qxe6 Qd4+ 41. Rf2 Rf8 42. Bf5 1-0 "

; sample game 606
EventSites(606) = "Wunsiedel op 7th  Wunsiedel" : GameDates(606) = "20130510" : WhitePlayers(606) = "Peralta, Fernando   G#606" : WhiteElos(606) = "2626" : BlackPlayers(606) = "Kunin, Vitaly L   G#606" : BlackElos(606) = "2503" : Each_Game_Result(606) = "1-0"

FilePGNs(606) = "1. d4 Nf6 2. c4 e6 3. Nc3 d5 4. cxd5 Nxd5 5. Nf3 c5 6. e3 Nc6 7. Bc4 cxd4 8. exd4 Nxc3 9. bxc3 Be7 10. Bd3  O-O 11. Qc2  g6   12. h4 f5 13. Bh6 Re8 14. Qd2  Bf6  15. Ng5 Bg7  16. Bxg7 Kxg7 17. f4 h6 18. Nf3 Bd7 19. h5 Qf6 20. hxg6 Rh8  21. Kf2 Be8 22. Rag1 Ne7 23. g4  fxg4 24. Rxg4 Bc6 25. Ne5  Rac8 26. Rh5  Be8 27. Rgh4 Ng8 28. Ng4 Qd8 29. Qe3 Qd6 30. c4 Rd8 31. Qe5+  Qxe5 32. Rxe5 Rxd4 33. Ke3 Rxd3+  34. Kxd3 Ne7 35. Rc5  Bxg6+ 36. Kc3 Nc6 37. Ne5 Be8 38. Nxc6 Bxc6 39. Re5 Kf7 40. Reh5 Kg6 41. Re5 Kf7 42. Kd4 Rd8+ 43. Ke3 Rh8 44. Reh5 Kg6 45. Kd4 Bf3 46. Ra5 a6 47. Ra3 Rd8+ 48. Ke5 Be2 49. Re3  Bf1 50. Re1 Bd3 51. Rd1  b5  52. Rg1+  Kf7 53. Rxh6 bxc4 54. Rf6+ Ke8 55. Kxe6 1-0 "

; sample game 607
EventSites(607) = "Sigeman & Co 21st  Malmo" : GameDates(607) = "20130522" : WhitePlayers(607) = "Sokolov, Ivan   G#607" : WhiteElos(607) = "2642" : BlackPlayers(607) = "Berg, Emanuel   G#607" : BlackElos(607) = "2561" : Each_Game_Result(607) = "1-0"

FilePGNs(607) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. h3 e5 7. d5 a5 8. Bg5 Na6 9. Bd3 Qe8 10. Qd2 Nd7 11. h4   Ndc5 12. Bc2 f5 13. Be3  Bd7 14. h5 gxh5 15. Qe2 f4 16. Bxc5 Nxc5 17. Nb5 Bxb5 18. cxb5 a4  19. Nd2  f3  20. Nxf3 Ra5 21. b6 cxb6  22. Nd2 b5 23. Qxh5 Qxh5 24. Rxh5 b4 25. Ke2 Rc8 26. Nc4 Ra6 27. Bd3 b3 28. Ne3  a3  29. axb3 axb2 30. Rb1 Ra2 31. Bc2 Na6 32. b4  Nxb4 33. Bb3 Ra1 34. Rxb2 b5 35. Rh3 Rc3 36. Bc4  bxc4 37. Rxb4 Ra2+ 38. Kf3 Rb3 39. Rxc4 Rbb2 40. Rc8+ Kf7 41. Rc7+ Kg8 42. Nd1 Ra3+ 43. Kg4 Rxh3 44. Nxb2 Rh6 45. Nc4 Rf6 46. f3 Bh6 47. Rd7 Rg6+ 48. Kh3 Bf4 49. g4 Rh6+ 50. Kg2 Rh2+ 51. Kf1 Rh1+ 52. Ke2 Rh2+ 53. Kd3 Rf2 54. Nxd6 Rxf3+ 55. Kc4 h6 56. Nf5 Rf1 57. d6 Rd1 58. Re7 Kf8 59. Kc5 Rd2 60. d7 Bg5 61. Re8+ Kf7 62. Nd6+ 1-0 "

; sample game 608
EventSites(608) = "Thessaloniki FIDE GP  Thessaloniki" : GameDates(608) = "20130522" : WhitePlayers(608) = "Kamsky, Gata   G#608" : WhiteElos(608) = "2741" : BlackPlayers(608) = "Dominguez Perez, Leinier   G#608" : BlackElos(608) = "2723" : Each_Game_Result(608) = "1-0"

FilePGNs(608) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be3 Ng4 7. Bc1 Nf6 8. a4 Nc6 9. Be2 g6 10. Be3 Bg7 11. O-O O-O 12. Qd2 Bd7 13. f3 Nxd4 14. Bxd4 Qa5  15. Rfd1 Kh8 16. Nb1  Qxd2 17. Nxd2 Be6 18. a5 Rfc8 19. c3 Nd7 20. Ra4 Rc7 21. Be3 Kg8 22. Rb4 Kf8 23. Kf2 Rac8 24. g4  Ne5  25. Kg3  Nc6 26. Ra4 Ne5 27. f4 Nc4 28. Bxc4 Bxc4 29. Rxc4 Rxc4 30. Nxc4 Rxc4 31. e5 Rc6 32. Kf3 f5  33. gxf5 dxe5 34. fxg6 hxg6 35. Rd7 exf4 36. Bf2  Be5 37. Rxb7 Ke8 38. Ke4 Bc7 39. Bb6 Re6+ 40. Kf3 Bd6 41. b4 Re5 42. Bd4  Rh5 43. h4  Kd8 44. Rb6 Rxh4  45. Rxd6+ 1-0 "

; sample game 609
EventSites(609) = "Moscow Tal Memorial 8th  Moscow" : GameDates(609) = "20130621" : WhitePlayers(609) = "Nakamura, Hikaru   G#609" : WhiteElos(609) = "2784" : BlackPlayers(609) = "Gelfand, Boris   G#609" : BlackElos(609) = "2755" : Each_Game_Result(609) = "0-1"

FilePGNs(609) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5 6. Ndb5 d6 7. Bg5 a6 8. Na3 b5 9. Bxf6 gxf6 10. Nd5 f5 11. c4 b4 12. Nc2 fxe4 13. g3 Bg7 14. Bg2 O-O 15. Bxe4 Rb8 16. b3 f5 17. Bg2 e4 18. Rb1 Qa5  19. O-O Qxa2 20. Nde3 Qa5 21. Qxd6 Rf6 22. Qf4 Qe5 23. Qxe5 Nxe5 24. Nd5  Rf7 25. Ncxb4 a5  26. Nc2 Rfb7 27. Nce3  Nc6 28. c5 Rxb3 29. Nb6  Rxb1 30. Rxb1 Be6 31. Bf1 Bd4 32. Rb5 Kf7 33. Nec4 Kg7  34. Nd6 Kf6 35. Na4 e3  36. fxe3 Bxe3+ 37. Kg2 Bd5+ 38. Kh3 Rxb5 39. Bxb5 Ne5 40. Nc3 Bf3  41. Be2 Bxe2 42. Nd5+ Kg5 43. Nxe3 Ng4  44. Kg2 Nxe3+ 45. Kf2 Nc4 0-1 "

; sample game 610
EventSites(610) = "Biel Breisacher Memorial  Biel" : GameDates(610) = "20130730" : WhitePlayers(610) = "Rapport, Richard   G#610" : WhiteElos(610) = "2693" : BlackPlayers(610) = "Ding, Liren   G#610" : BlackElos(610) = "2714" : Each_Game_Result(610) = "0-1"

FilePGNs(610) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nge2 O-O 6. Ng3 Nbd7 7. Be2 h5 8. h4 a6 9. Bg5 c5 10. d5 b5 11. b3 Nh7 12. Bd2 b4 13. Na4 Bxa1 14. Qxa1 e5 15. Bh6 Re8 16. f4 Ra7 17. f5 Kh8 18. Qc1 Rg8 19. Bg5 Nxg5 20. hxg5 Kg7 21. Qe3 Rh8 22. Bxh5 gxh5 23. Nxh5+ Kf8 24. g6 fxg6 25. fxg6 Kg8 26. Qf3 Qe7 27. g4 Rh6 28. Nb6 Nxb6 29. Nf6+ Qxf6 30. Qxf6 Rxh1+ 31. Kf2 Bxg4 32. Qxd6 Nc8 33. Qd8+ Kg7 34. Qg5 Bd7 35. Qxe5+ Kxg6 36. Qg3+ Kh7 37. Qf4 Be8 38. Qf5+ Bg6 39. Qxc8 Rf7+ 40. Ke3 Re1+ 41. Kd2 Rxe4 42. Qxc5 Rff4 43. d6 Rd4+ 44. Ke3 Rfe4+ 45. Kf2 Rd2+ 46. Kf3 Red4 47. Qxb4 Rxd6 48. Qb8 Rf6+ 49. Ke3 Rd3+ 50. Ke2 Re6+ 51. Kf2 Bh5 52. Kf1 Rf3+ 53. Kg2 Rg6+ 54. Kh2 Rf7 55. Qe5 Rfg7 56. Qf5 Bg4 57. Qe4 Bd7 58. b4 Kh8 59. Qa8+ Rg8 0-1 "

; sample game 611
EventSites(611) = "Dortmund SuperGM 41st  Dortmund" : GameDates(611) = "20130802" : WhitePlayers(611) = "Adams, Michael   G#611" : WhiteElos(611) = "2740" : BlackPlayers(611) = "Khenkin, Igor   G#611" : BlackElos(611) = "2605" : Each_Game_Result(611) = "1-0"

FilePGNs(611) = "1. e4 c6 2. d4 d5 3. Nd2 dxe4 4. Nxe4 Bf5 5. Ng3 Bg6 6. h4 h6 7. Nf3 Nf6 8. Ne5 Bh7 9. Bd3 Nbd7 10. Bxh7 Nxe5 11. dxe5 Qa5+ 12. Kf1 Nxh7 13. e6 Qd5 14. exf7+ Qxf7 15. Ne4 Nf6 16. Nxf6+ Qxf6  17. Rh3 e6 18. Be3  Be7 19. Bd4 Qg6 20. Rg3 Qf5 21. Rxg7 Rf8 22. Qg4 Rd8 23. Re1  Rd6 24. c3 h5 25. Qg6+ Kd8 26. Qxf5 Rxf5 27. Rg8+ Kd7 28. g3 c5 29. Be3 Bf6 30. Rf8 a6 31. Rf7+ 1-0 "

; sample game 612
EventSites(612) = "FIDE World Cup  Tromsoe" : GameDates(612) = "20130812" : WhitePlayers(612) = "Postny, Evgeny   G#612" : WhiteElos(612) = "2628" : BlackPlayers(612) = "Li, Chao B   G#612" : BlackElos(612) = "2693" : Each_Game_Result(612) = "1/2-1/2"

FilePGNs(612) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. Nf3 Bg7 5. cxd5 Nxd5 6. e4 Nxc3 7. bxc3 c5 8. Rb1 O-O 9. Be2 cxd4 10. cxd4 Qa5+ 11. Bd2 Qxa2 12. O-O b6 13. Qc1 Bb7 14. Bc4 Qa4 15. Bb5 Qa2 16. Re1 Rc8 17. Qd1 Qc2 18. Qe2 Qc7  19. Rec1 Qd8 20. Rxc8 Bxc8 21. Bc4   a5 22. Bf4  Na6 23. Ne5 Bxe5  24. Bxe5 Nb4 25. d5 Bd7 26. Ba1 b5  27. Bxb5  Bxb5 28. Qxb5 Nc2 29. Qa4 Nxa1 30. Rxa1 1/2-1/2 "

; sample game 613
EventSites(613) = "FIDE World Cup  Tromsoe" : GameDates(613) = "20130817" : WhitePlayers(613) = "Aronian, Levon   G#613" : WhiteElos(613) = "2813" : BlackPlayers(613) = "Tomashevsky, Evgeny   G#613" : BlackElos(613) = "2706" : Each_Game_Result(613) = "0-1"

FilePGNs(613) = "1. d4 d5 2. c4 e6 3. Nf3 c6 4. e3 Bd6 5. Bd3 f5 6. O-O Nf6 7. b3 Qe7 8. Ne5 O-O 9. Bb2 Bd7  10. Nc3 Be8 11. cxd5  cxd5 12. Rc1 Nc6 13. Nb5 Bb4 14. a3 Ba5 15. Be2 a6 16. Nc3 Ne4 17. b4 Bc7 18. Nxe4 fxe4 19. Qb3  Bxe5 20. dxe5 Qg5 21. Kh1 Bh5 22. f3 Qh6  23. Rce1 exf3 24. gxf3 Rf7 25. Bc1 Bg6  26. e4 Qh3 27. exd5 Nd4 28. Qd1 Nxe2 29. Qxe2 Bh5 30. Kg1 Bxf3 31. Qf2 Qg4+ 32. Qg3 Qxg3+ 33. hxg3 Bxd5 34. Be3 a5  35. b5 a4 36. Rxf7 Kxf7 37. Rf1+ Kg6 38. Rf4 h6 39. Kf2 Bb3  40. Rg4+ Kh7 41. Rd4 Rc8 42. b6 Rc2+ 43. Ke1  Ra2 44. Bc1 Rg2 45. Bf4 Rg1+ 46. Kd2 Ra1 47. Kc3 Rxa3 48. Kb4 Ra1 49. Bd2 Bd5 50. Bc3 Ra2 51. Rd3 Kg6 52. Rd4 a3 53. Rd3 Kf5 54. Bd2 Ra1 55. Bc3 Ra2 56. Bd2 Ke4 57. Re3+ Kd4 58. Bc1 Rc2 0-1 "

; sample game 614
EventSites(614) = "Kings Tournament 7th  Bucharest" : GameDates(614) = "20131009" : WhitePlayers(614) = "Nisipeanu, Liviu Dieter   G#614" : WhiteElos(614) = "2674" : BlackPlayers(614) = "Wang, Hao   G#614" : BlackElos(614) = "2733" : Each_Game_Result(614) = "1-0"

FilePGNs(614) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. e3 O-O 5. Bd3 c5 6. Nf3 b6 7. d5  exd5 8. cxd5 Ba6 9. O-O Re8  10. e4  Bxd3 11. Qxd3 d6 12. Bg5 Nbd7 13. Rae1 h6 14. Bd2 Ng4 15. a3 Ba5 16. Qb1  c4  17. Nd4 Nc5 18. h3 Ne5 19. Re3  Nb3  20. Nxb3 cxb3 21. Rg3 Qh4  22. Be1  Nd7  23. Nb5  Qxe4 24. Bxa5 bxa5 25. Nc7 Qxb1 26. Rxb1 Nc5 27. Nxa8 Rxa8 28. Re3 Kf8 29. Rc1  g5 30. Rc4 Kg7 31. Kf1 Kf6 32. Ke2 h5 33. a4 Rg8 34. Rxc5 dxc5 35. Kd3 g4 36. h4  g3  37. f3  Rb8  38. Kc4  Rb4+ 39. Kxc5 Rxh4 40. d6 Rh1 41. Rd3 Rc1+ 42. Kb5 1-0 "

; sample game 615
EventSites(615) = "Grand Slam Final 6th  Bilbao" : GameDates(615) = "20131010" : WhitePlayers(615) = "Vachier Lagrave, Maxime   G#615" : WhiteElos(615) = "2742" : BlackPlayers(615) = "Aronian, Levon   G#615" : BlackElos(615) = "2795" : Each_Game_Result(615) = "0-1"

FilePGNs(615) = "1. c4 Nf6 2. Nc3 e5 3. Nf3 Nc6 4. g3 g6 5. Bg2 Bg7 6. O-O O-O 7. d3 h6 8. b4 d6 9. Rb1 a6 10. a4 Ne7 11. Ba3 c6 12. c5  Re8 13. e4 Bg4 14. Qb3 Nd7 15. Nd2 Nc8 16. Qc2 Bf8 17. cxd6 Nxd6 18. Nb3 b5  19. h3  Be6 20. Rfd1 bxa4 21. Nxa4 Nb5 22. Bb2 Bxb3  23. Qxb3 c5 24. Rbc1 Rb8 25. Qa2  cxb4 26. Rc6 Kg7 27. d4 b3  28. Qb1 exd4 29. Bxd4+ Nxd4 30. Rxd4 Qa5  31. Rxd7 Qxa4 32. e5  Re7 33. Rdd6 Qa2  34. Rxg6+ fxg6 35. Qxg6+ Kh8 36. Bd5 Rg7 37. Qxh6+ Rh7 38. Qe6  Qb1+ 39. Kg2 Rg7 40. Rc8 Rxc8 41. Qxc8 Rg8  42. Qb7 Qh7 43. Qxb3 Rg5 44. Qe3 Qe7 45. f4 Rg7 46. f5 Qg5  47. Qxg5 Rxg5 48. g4 Bg7  49. e6 Bf6 50. Kg3 a5 51. h4 Rg8 52. g5 Kg7  53. Kf4 Rh8 54. Kg4 Rb8 55. gxf6+ Kxf6 56. e7 a4 0-1 "

; sample game 616
EventSites(616) = "EU-chT (Men) 19th  Warsaw" : GameDates(616) = "20131115" : WhitePlayers(616) = "Berg, Emanuel   G#616" : WhiteElos(616) = "2547" : BlackPlayers(616) = "Tomczak, Jacek   G#616" : BlackElos(616) = "2581" : Each_Game_Result(616) = "1-0"

FilePGNs(616) = "1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. Bg5 dxe4 5. Nxe4 Be7 6. Bxf6 gxf6 7. Nf3 f5 8. Nc3 a6 9. g3 b5 10. Bg2 Bb7 11. O-O O-O 12. Re1 Bf6 13. Ne5 Bxg2 14. Kxg2 c5  15. Qf3 Bxe5  16. Qxa8 Bxd4 17. Qb7  Qa5 18. a3  Bxc3 19. bxc3 Qxc3 20. Rad1 b4 21. Re3 Qxc2 22. Rd6  bxa3  23. Rxa3  Qe4+ 24. Qxe4 fxe4 25. Re3 Rc8 26. Rxe4 Kf8 27. Rc4 Ke7 28. Rb6 h6 29. Rc3 a5 30. Rb5 Nd7 31. Rxa5 Kd6 32. Ra6+ Ke5 33. Re3+ Kf6 34. Rf3+ Ke7 35. Rc3 Rc7 36. Rca3 c4 37. Ra7 Rc6 38. R3a6 Rc5 39. Ra5 Rc6 40. R5a6 Rc5 41. Ra5 Rc6 42. Ra1 Rc5 43. Rb7 Kd6 44. Ra6+ Rc6 45. Rxc6+ Kxc6 46. Ra7 Ne5 47. Kf1 Kd5 48. Ke2 f5 49. Rh7 c3 50. Rxh6 c2 51. Kd2 Ng4 52. Rh4  Nxf2 53. Kxc2 Ke5 54. Kd2 Kf6 55. Ke3 Nd1+ 56. Kd2 Nf2 57. Ke3 Nd1+ 58. Kf3 Nc3 59. Rh6+ Kf7 60. Kf4 Ne4 61. g4 Nd2 62. g5 Ne4 63. h4 Nf2 64. Rh7+ Kg6 65. Re7 e5+ 66. Kxe5 1-0 "

; sample game 617
EventSites(617) = "Bundesliga 1314  Germany" : GameDates(617) = "20131124" : WhitePlayers(617) = "Postny, Evgeny   G#617" : WhiteElos(617) = "2631" : BlackPlayers(617) = "Gonda, Laszlo   G#617" : BlackElos(617) = "2535" : Each_Game_Result(617) = "1/2-1/2"

FilePGNs(617) = "1. d4 e6 2. c4 b6 3. a3 Bb7 4. Nc3 f5 5. d5 Nf6 6. g3 Na6 7. Bg2 Nc5 8. Nh3 Bd6 9. O-O O-O 10. Qc2 a5 11. Rd1 Qe7 12. Rb1 Rae8   13. Be3  Nce4  14. Nxe4 fxe4 15. dxe6 Qxe6 16. c5 bxc5 17. Bxc5 Bxc5 18. Qxc5 Qe5  19. Rbc1 Bc6 20. b4 Qxc5 21. Rxc5 axb4 22. axb4 Ra8 23. g4  Rfb8 24. g5 Ne8 25. b5 Ra5  26. bxc6  Rxc5 27. cxd7 Nd6 28. Bxe4 Rd8 29. Bd5+ Kf8 30. Be6 Ke7 31. Bg4 h5  32. Bxh5  Rxd7 33. Bg4 Rd8 34. Rd3 Nf7 35. Rxd8  Kxd8 36. f4 Ke7 37. Kf2 Rc3 38. Ke1  Rc1+ 39. Kd2 Rh1 40. e4 Rxh2+ 41. Ke3 c5  42. Nf2 Nd6 43. e5 Nc4+ 44. Kf3 Nd2+ 45. Kg3 Nf1+ 46. Kf3 c4 47. f5 c3 48. f6+ gxf6 49. gxf6+ Kf7 50. e6+ Kxf6 51. Ne4+ Ke5 52. Nxc3 Rh8 53. Nd1 Rg8 54. Bh3 Nd2+ 55. Ke2 Ne4 56. Nf2 Nc3+ 57. Kf3 Rf8+ 58. Kg2 Nd5 59. Kg3 Rg8+ 60. Kf3 Ra8 61. Ng4+ Kd4 62. Nh6 Ra3+ 63. Kg4 Ke5 64. Nf7+ Kxe6 65. Ng5+ Ke5 66. Nf3+ Ke4 67. Ng5+ Ke3 68. Bg2 Nf4 69. Be4 Ne2 70. Bc6 Ra1 71. Nf3 Rc1 72. Bb5 Nc3 73. Bc6 Nd1  74. Ba8 Ra1 75. Bc6 Ra5 76. Nh4  Nf2+ 77. Kg3 Rg5+ 78. Kh2 Ng4+ 79. Kh3 Ne5 80. Ng2+ Kf2 81. Kh4 Rg7  82. Ba8 Ra7  83. Bd5 Ra5 84. Nf4 Ke3 85. Kg3 Ra4 86. Ng2+ Kd4 87. Be6 Ra3+ 88. Kf2 Nd3+ 89. Ke2 Nc5 90. Bf5 Ke5 91. Bc2 Ne6 92. Kd2 Kd4 93. Nh4 Ra2 94. Nf3+ Kc4 95. Ne5+ Kd5 96. Nd3 Kd4 97. Nc1 Rb2 98. Nd3 Rb8 99. Nc1 Nc5 100. Ne2+ Kc4 101. Ke3 Rh8 102. Bf5 Re8+ 103. Kf3 Rf8 1/2-1/2 "

; sample game 618
EventSites(618) = "IND-ch 51st  Jalgaon" : GameDates(618) = "20131230" : WhitePlayers(618) = "Shyam, Nikil P   G#618" : WhiteElos(618) = "2420" : BlackPlayers(618) = "Sasikiran, Krishnan   G#618" : BlackElos(618) = "2666" : Each_Game_Result(618) = "0-1"

FilePGNs(618) = "1. d4 Nf6 2. Nf3 g6 3. Bg5 Bg7 4. Nbd2 O-O 5. e4 d5 6. exd5 Nxd5 7. Nb3 a5  8. a4 b6 9. Qd2  Bb7 10. Be2 Nd7  11. O-O N7f6 12. Bh6 Ne4 13. Qc1 Qd6 14. Re1  c5  15. Bf1 Ndf6 16. Bf4 Qd5  17. dxc5 bxc5 18. Ne5 Nh5 19. Bc4  Qd8 20. Ng4  Nd6  21. Bxd6 exd6 22. c3 Kh8  23. Ne3 Nf4 24. Bf1 Qc7 25. Qd1 d5 26. g3 d4  27. gxf4  dxe3 28. fxe3 Qc6  29. e4 Qc7  30. Bg2  Rad8 31. Qe2 c4 32. Nd2  Qb6+ 33. Kh1 Qxb2 34. Rab1 Qxd2 35. Qxd2 Rxd2 36. Rxb7 Bxc3 37. Bf1 Rc2  38. Rd1 Bd2 39. Bxc4 Rxc4 40. Rxd2 Rxe4 41. Ra7 Rxa4 42. f5 g5  43. f6 h6  44. Rdd7 Kg8 45. Kg2 Rg4+ 46. Kh3 Rh4+ 47. Kg3 a4 48. Rdc7 Rf4 49. h3 Kh7 50. Rxf7+ Rxf7 51. Rxf7+ Kg6 52. Ra7 Kxf6 53. Ra6+ Kg7 54. Kg2 Rh4  0-1 "

; sample game 619
EventSites(619) = "Tata Steel-B 76th  Wijk aan Zee" : GameDates(619) = "20140114" : WhitePlayers(619) = "Duda, Jan Krzysztof   G#619" : WhiteElos(619) = "2553" : BlackPlayers(619) = "Muzychuk, Anna   G#619" : BlackElos(619) = "2566" : Each_Game_Result(619) = "0-1"

FilePGNs(619) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. d3 b5 6. Bb3 Bc5 7. O-O d6 8. a4 b4 9. a5 h6 10. Nbd2 O-O 11. h3 Rb8 12. Bc4 Be6  13. Nb3  Qc8  14. Bxe6 Qxe6 15. Nxc5 dxc5 16. b3 Ne8 17. Nh4 Nd6 18. f4  f5 19. Nxf5 Nxf5 20. exf5 Qxf5  21. Be3 exf4 22. Rxf4 Qd5 23. Rc4  Nd4  24. Bxd4 cxd4 25. Rxc7 Qd6  26. Rc4 Rbe8 27. Qd2  Re3 28. Rf1  Rxf1+ 29. Kxf1 Re8  30. Qxb4  Qf4+  31. Kg1 Re2 32. Rc8+ Kh7 33. Rf8 Qg3 34. Qb7 Re1+ 35. Rf1 Qe3+ 0-1 "

; sample game 620
EventSites(620) = "Tata Steel-A 76th  Wijk aan Zee" : GameDates(620) = "20140119" : WhitePlayers(620) = "Nakamura, Hikaru   G#620" : WhiteElos(620) = "2789" : BlackPlayers(620) = "Van Wely, Loek   G#620" : BlackElos(620) = "2672" : Each_Game_Result(620) = "0-1"

FilePGNs(620) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 d6 6. g4 Nge7 7. Nb3 a6 8. h4 b5 9. Bg2 Bb7 10. g5 Rc8 11. Qe2 h5 12. a4 b4 13. Na2 g6 14. Bf4 Bg7 15. Rd1 Ne5 16. Nxb4 Nc4 17. Nd3 Qb6 18. O-O O-O 19. Nd2 Rfd8 20. Nxc4 Rxc4 21. Ne5  dxe5 22. Be3 Rcd4 23. c3 Bc6 24. b3  Qxb3 25. cxd4 exd4 26. Bf4 Qxa4 27. Qf3 Bb5 28. Ra1 Qb4 29. Rfd1 d3 30. Rab1 Qa3 31. Bf1 Nc6 32. Qg3 Qa2 33. Rbc1 d2  34. Rxd2 Rxd2 35. Bxb5 axb5 36. Bxd2 Nd4 37. Rc8+ Kh7 38. Qc7 Qb1+  39. Bc1 Nf3+ 40. Kg2 Nxh4+ 41. Kh3 Qxe4 42. Qf4 Qh1+ 43. Qh2 Qb7  44. Rd8 Be5  45. f4 Qf3+ 46. Qg3 Qh1+ 47. Qh2 Qf3+ 48. Qg3 Qh1+ 49. Qh2 Qxc1 50. fxe5 Qxg5 51. Qf4  Qxd8 52. Qxf7+ Kh6 0-1 "

; sample game 621
EventSites(621) = "Tata Steel-A 76th  Wijk aan Zee" : GameDates(621) = "20140121" : WhitePlayers(621) = "Karjakin, Sergey   G#621" : WhiteElos(621) = "2759" : BlackPlayers(621) = "Gelfand, Boris   G#621" : BlackElos(621) = "2777" : Each_Game_Result(621) = "1-0"

FilePGNs(621) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. h3 e5 7. Nde2 h5 8. g3 b5 9. Bg5 Nbd7 10. Nd5 Bb7 11. Nec3 Rc8 12. Bg2 Be7 13. Nxe7 Qxe7 14. h4 Nb6 15. Qd3 Qc7 16. Bh3 Rb8 17. Bxf6 gxf6 18. O-O-O b4 19. Nd5 Nxd5 20. exd5 Bc8 21. f4 Bxh3  22. Rxh3  Kf8 23. fxe5 fxe5 24. Rh2 Kg7 25. Rf2 Rh6 26. Qxa6  b3  27. axb3 Rxb3 28. Qc6 Qa7 29. Rxf7+ Qxf7 30. cxb3 Rg6  31. b4 Qf3 32. Qc3 Qf2 33. Rd3 Rf6 34. Kb1 Qg1+ 35. Ka2 Qa7+ 36. Kb3 Rf1 37. Rf3 Ra1 38. Qe3  Qxe3+ 39. Rxe3 Kg6 40. b5 Ra8 41. Kb4 Rb8 42. Rf3 e4 43. Rf1 e3 44. Kc4 Rc8+ 45. Kd3 Rc5 46. b4 Rxd5+ 47. Kxe3 Rxb5 48. Rf4 d5 49. Kd3 Rb7 50. Kc2 Rb8 51. Kc3 Rb7 52. Rf8 Rc7+ 53. Kb3 Rd7 54. b5 d4 55. Kc2 d3+ 56. Kd2 Rd5 57. Rg8+ Kh6 58. Rg5 Rd4 59. Rc5 Kg6 60. b6 1-0 "

; sample game 622
EventSites(622) = "Gibraltar Masters 12th  Caleta" : GameDates(622) = "20140129" : WhitePlayers(622) = "Muzychuk, Mariya   G#622" : WhiteElos(622) = "2503" : BlackPlayers(622) = "Fuchs, Judith   G#622" : BlackElos(622) = "2315" : Each_Game_Result(622) = "1-0"

FilePGNs(622) = "1. e4 c6 2. d4 d5 3. Nc3 dxe4 4. Nxe4 Bf5 5. Ng3 Bg6 6. h4 h6 7. Nf3 Nd7 8. h5 Bh7 9. Bd3 Bxd3 10. Qxd3 Qc7 11. Bd2 e6 12. Ne4 Ngf6 13. O-O-O O-O-O 14. g3 Nxe4 15. Qxe4 Bd6 16. Kb1 c5  17. dxc5 Nxc5 18. Qe2 Rhe8 19. Rh4 Kb8 20. Rc4 Qe7 21. Bb4  f6 22. Rcd4  Bc7  23. Qb5 b6 24. Rxd8+ Rxd8 25. Nd4 Kb7 26. Qc6+ Kb8 27. Rd3 e5 28. Qxc5  Qxc5  29. Bxc5 exd4 30. Bxd4 Re8  31. Re3 Rd8 32. c3 Rd7 33. Kc2 Kb7 34. a4 a6  35. Re6 Bd8 36. g4 Rd5 37. Kd3 f5 38. Re5 Rxe5 39. Bxe5 fxg4 40. Bxg7 Bh4 41. Bxh6 Bxf2 42. Ke2 1-0 "

; sample game 623
EventSites(623) = "Gibraltar Masters 12th  Caleta" : GameDates(623) = "20140201" : WhitePlayers(623) = "Tomashevsky, Evgeny   G#623" : WhiteElos(623) = "2715" : BlackPlayers(623) = "Muzychuk, Mariya   G#623" : BlackElos(623) = "2503" : Each_Game_Result(623) = "1/2-1/2"

FilePGNs(623) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. e3 Bg4 5. h3 Bxf3 6. Qxf3 e6 7. Bd3 Bb4+ 8. Nc3 Nbd7 9. Bd2 O-O 10. a3 Bxc3  11. Bxc3 Re8 12. O-O e5 13. dxe5 Nxe5 14. Bxe5 Rxe5 15. Rfd1 Qe7 16. cxd5 Rxd5 17. Bc4 Rxd1+ 18. Rxd1 Rd8 19. Rxd8+ Qxd8 20. g4 h6 21. Kg2 g5 22. Qf5 Kg7 23. Qe5 Qe8 24. Qc3 c5  25. Bd5 Qe7 26. Bf3 b6 27. b4 cxb4 28. axb4 a6 29. Be2 Qa7 30. Qe5 a5 31. f4 Qa8+ 32. Bf3 Qe8 33. bxa5 bxa5 34. Qc5 gxf4 35. exf4 Qd8 36. Qe5 Kg8 37. h4 Qd2+ 38. Kg3 Nd7 39. Qe7 a4 40. g5 hxg5 41. Qxg5+ Kf8 42. Qd8+ Kg7 43. Qg5+ 1/2-1/2 "

; sample game 624
EventSites(624) = "Gibraltar Masters 12th  Caleta" : GameDates(624) = "20140206" : WhitePlayers(624) = "Vitiugov, Nikita   G#624" : WhiteElos(624) = "2737" : BlackPlayers(624) = "Zhao, Xue   G#624" : BlackElos(624) = "2568" : Each_Game_Result(624) = "1-0"

FilePGNs(624) = "1. c4 Nf6 2. Nc3 c5 3. Nf3 d5 4. cxd5 Nxd5 5. g3 Nc6 6. Bg2 e6 7. O-O Be7 8. Nxd5 exd5 9. d4 O-O 10. dxc5 Bxc5 11. Bg5 f6  12. Bd2 Be6 13. a3  Bb6 14. b4 Ne5 15. a4 a6 16. Rb1 Qd7 17. a5 Ba7 18. b5  Rac8 19. Bb4 Nxf3+  20. Bxf3 Bc5  21. bxa6 bxa6 22. Qd3 Bxb4 23. Rxb4 Rc6 24. Rb6  Ra8 25. Rfb1 Rac8 26. h4  Rc3 27. Qxa6 Bg4 28. Bg2 d4 29. Rb8 Qe8 30. Qd6 h5 31. a6 Qa4 32. Bb7 Kh7 33. Bxc8 Bxc8 34. Qd5 Kg6 35. R8b5 Bg4 36. Rb7 Qe8 37. a7 Bf5 38. Rxg7+ 1-0 "

; sample game 625
EventSites(625) = "Minsk Bronstein Memorial op-A  Minsk" : GameDates(625) = "20140217" : WhitePlayers(625) = "Tiviakov, Sergei   G#625" : WhiteElos(625) = "2639" : BlackPlayers(625) = "Rakhmanov, Alexander   G#625" : BlackElos(625) = "2606" : Each_Game_Result(625) = "1-0"

FilePGNs(625) = "1. e4 g6 2. d4 Bg7 3. c3 d6 4. Nf3 Nf6 5. Bd3 O-O 6. O-O Nc6 7. d5  Nb8 8. c4 a5 9. Nc3 Na6 10. Be3 e5 11. dxe6 Bxe6 12. h3  Nb4  13. Nd4  Nxd3 14. Qxd3 Nd7 15. Qe2  Re8 16. Rad1 Qe7 17. Ndb5 Rac8 18. Rfe1 Nf6 19. b3 Bd7 20. f3 h6 21. Qf2 Kh7 22. Bd4 Bxb5 23. cxb5  c6 24. bxc6 bxc6 25. Qd2  Qb7 26. Na4 d5 27. Qc3 Nh5  28. Bxg7 Nxg7 29. Qxa5 Ne6  30. exd5 cxd5 31. Qxd5 Qa7+ 32. Kh1 Rc2 33. Qd7 Re7 34. Qxa7 Rxa7 35. a3 Nf4 36. Rc1  Rf2 37. Rf1 Rd2 38. Rg1 g5   39. Nc3 Rd3 40. a4  Rb7 41. Ne4 Rb8 42. Nc5 Rd2 43. a5 Ne2 44. Rgd1 Rb2 45. Rb1 Rc2 46. Ne4 Nf4 47. Rd2 Rc6 48. b4 f5 49. Rd7+ Kg8 50. Nd2 Rc2 51. a6 Ra2 52. b5 1-0 "

; sample game 626
EventSites(626) = "EU-ch 15th  Yerevan" : GameDates(626) = "20140306" : WhitePlayers(626) = "Motylev, Alexander   G#626" : WhiteElos(626) = "2656" : BlackPlayers(626) = "Kovalev, Vladislav   G#626" : BlackElos(626) = "2548" : Each_Game_Result(626) = "1-0"

FilePGNs(626) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. d4 Nd6 6. Bxc6 dxc6 7. dxe5 Nf5 8. Qxd8+ Kxd8 9. h3 Ke8 10. Nc3 h5 11. Rd1 Be7 12. Ne2 Be6 13. Nf4 Bc8 14. e6  Bf6  15. exf7+ Kxf7 16. Nd3 Re8  17. Bf4 Nd6 18. c3 a5  19. Re1  Rxe1+  20. Rxe1 a4 21. g4  hxg4 22. hxg4 Nc4 23. g5 Bg4  24. Kg2  Rd8  25. Nc5  Be7  26. g6+  Kf8 27. Nxb7  Rd3 28. Nd4 Nxb2 29. Bxc7  Rxc3 30. Bd6  Bxd6 31. Nxd6 Bd7 32. N4f5  Nc4 33. Rh1  Be6 34. Rh8+ Bg8 35. Ne4 1-0 "

; sample game 627
EventSites(627) = "EU-ch 15th  Yerevan" : GameDates(627) = "20140308" : WhitePlayers(627) = "Motylev, Alexander   G#627" : WhiteElos(627) = "2656" : BlackPlayers(627) = "Riazantsev, Alexander   G#627" : BlackElos(627) = "2689" : Each_Game_Result(627) = "1-0"

FilePGNs(627) = "1. e4 c6 2. Nc3 d5 3. Nf3 Bg4 4. h3 Bxf3 5. Qxf3 e6 6. d3 Nf6 7. Bd2 Bd6 8. g4  Bb4  9. a3 Ba5 10. g5 Nfd7 11. d4  O-O 12. O-O-O e5  13. dxe5  d4 14. Ne2 Bxd2+ 15. Rxd2 Qxg5 16. Nxd4  Qxe5 17. Nf5 Nf6 18. Qg2  g6 19. Qg5 Re8  20. f3  Kh8 21. Rg1 Ng8 22. Nd6  Qxg5 23. Rxg5 Re7 24. Re5  Rc7 25. Re8  b5 26. Nf5  1-0 "

; sample game 628
EventSites(628) = "EU-ch 15th  Yerevan" : GameDates(628) = "20140313" : WhitePlayers(628) = "Popov, Ivan1   G#628" : WhiteElos(628) = "2650" : BlackPlayers(628) = "Eljanov, Pavel   G#628" : BlackElos(628) = "2723" : Each_Game_Result(628) = "0-1"

FilePGNs(628) = "1. e4 e5 2. Nf3 Nc6 3. Nc3 Nf6 4. Bb5 Bd6  5. O-O O-O 6. d3 a6 7. Ba4 h6 8. a3 Re8 9. Be3 Bf8 10. Bb3 d6 11. h3 Be6 12. Bxe6 fxe6 13. Ne2 d5 14. Ng3 Bd6 15. c4 d4  16. Bd2 a5   17. b3 Qe7 18. Bc1 Rf8 19. h4  Ng4  20. h5 Bc5 21. Ra2 b6 22. Qe2 Rab8 23. Qd1 Rbe8 24. Qe2 Nb8 25. Rd1 Nd7 26. Nf1 Rf7  27. N1h2 Nxh2 28. Nxh2 Bd6 29. Qg4 Rf6 30. Qh4 Rff8 31. Qxe7 Rxe7 32. Bd2  Nc5 33. Kf1  Nxd3 34. Bg5 Rxf2+  35. Rxf2 Nxf2 36. Kxf2 hxg5 0-1 "

; sample game 629
EventSites(629) = "EU-ch 15th  Yerevan" : GameDates(629) = "20140314" : WhitePlayers(629) = "Moiseenko, Alexander   G#629" : WhiteElos(629) = "2712" : BlackPlayers(629) = "Postny, Evgeny   G#629" : BlackElos(629) = "2635" : Each_Game_Result(629) = "1/2-1/2"

FilePGNs(629) = "1. d4 d5 2. c4 c6 3. Nc3 Nf6 4. e3 g6 5. Nf3 Bg7 6. Bd3 O-O 7. O-O a6 8. Qc2 Bg4 9. Ne5 Be6 10. c5 Nbd7 11. Nxd7 Qxd7 12. Bd2 Bf5 13. Bxf5 Qxf5 14. Qxf5 gxf5 15. Ne2 a5   16. f3 Nd7 17. Rac1 a4 18. Bb4 Rfe8 19. Kf2 e6 20. h3 Bf8 21. Nf4  b6 22. Nd3 bxc5 23. Bxc5 Bxc5 24. Nxc5 Nxc5 25. Rxc5 Reb8  26. Rc2 Rb4 27. Kg3 Kg7 28. a3 Rb3 29. Kf4 h5 30. Rff2 Ra6 31. g4 hxg4 32. hxg4 fxg4 33. fxg4  f6  34. Rh2 Rab6 35. Rcg2 Kf7 36. g5 fxg5+ 37. Rxg5  Rxb2 38. Rh7+ Kf8 39. Ke5 Rf2 40. Kxe6  c5+ 41. Kxd5 cxd4 42. Kxd4 Rb3 43. Rh8+ Kf7 44. Rgg8 Rh2 45. Rf8+ Ke7 46. Re8+ Kf7 47. Rhf8+ Kg7 48. Rg8+ Kf7 49. Rgf8+ Kg7 50. Rg8+ Kf7 51. Rgf8+ 1/2-1/2 "

; sample game 630
EventSites(630) = "FIDE Candidates  Khanty-Mansiysk" : GameDates(630) = "20140322" : WhitePlayers(630) = "Svidler, Peter   G#630" : WhiteElos(630) = "2758" : BlackPlayers(630) = "Karjakin, Sergey   G#630" : BlackElos(630) = "2766" : Each_Game_Result(630) = "0-1"

FilePGNs(630) = "1. Nf3 Nf6 2. g3 d5 3. Bg2 e6 4. O-O Be7 5. d3 c5 6. e4  Nc6 7. Qe2 O-O 8. e5 Nd7 9. c4 d4 10. h4  Kh8 11. Bf4 f5  12. Ng5  Bxg5 13. hxg5 Qc7 14. g6  hxg6 15. Nd2 Kg8 16. Nf3 Re8  17. Ng5 Nf8 18. g4  Nd8 19. Kh2  Bd7  20. gxf5 exf5 21. Bd5+ Nde6 22. Rg1 Bc6 23. Qf3  Rad8 24. Rae1 Qd7 25. Bxe6+  Nxe6 26. Qg3 Rc8 27. Nh3 Qf7 28. Qh4  Bf3  29. Bd2 Bg4 30. Rg3 Qe7  31. Qxe7  Rxe7 32. Ng5 Nxg5 33. Bxg5 Re6 34. f3 Bh5 35. b3 Kf7 36. Rh3 Rce8 37. Bf4 Ra6 38. Re2 Ke6 39. Kg3 Rb8 40. Bg5  f4+  41. Bxf4 Rf8 42. Rf2 Rf5 43. Bc1 Rxe5 44. Rh1 Kf7 45. Bf4 Rf5 46. Bb8  Re6  47. Rh4 Re3 48. Rf4 a6 49. Bd6  Rxf4  50. Kxf4 Kf6  51. Bxc5 g5+ 52. Kg3 Rxd3 53. Kg2 Be8 54. Kf1  Bh5 55. Ke2  Re3+ 56. Kd2 Ke5 57. Rg2 Kf4 58. Bxd4 Re7 59. Re2 Rd7 60. Kc3 Bxf3 61. Re8  Be4  62. Rf8+ Bf5  63. Rg8 g6 64. Rg7 Rxd4  65. Kxd4 b6  66. Kc3  Ke3  67. Rb7 g4 68. Rxb6 g3 69. Rd6 g2 70. Rd1 g5  71. b4 Kf2 72. a4 g1=Q 73. Rxg1 Kxg1 74. b5 axb5 75. axb5 g4  76. c5 g3 77. c6 g2 78. b6 Kf2 79. b7 g1=Q 80. b8=Q Qc1+  81. Kd4 Qe3+  82. Kc4 Be6+  0-1 "

; sample game 631
EventSites(631) = "FIDE Candidates  Khanty-Mansiysk" : GameDates(631) = "20140323" : WhitePlayers(631) = "Anand, Viswanathan   G#631" : WhiteElos(631) = "2770" : BlackPlayers(631) = "Topalov, Veselin   G#631" : BlackElos(631) = "2785" : Each_Game_Result(631) = "1-0"

FilePGNs(631) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. h3 e6 7. g4 Nfd7 8. Bg2 Be7 9. Be3 Nc6 10. h4 Nde5 11. g5 Bd7 12. Nxc6 Bxc6 13. b3 f5 14. f4 Ng4 15. Qe2 Nxe3 16. Qxe3 fxe4 17. O-O-O d5 18. Nxe4 Ba3+ 19. Kb1 Qe7 20. Nf2  Bc5 21. Qg3 Bxf2 22. Qxf2 O-O 23. Qd4  Rf5 24. Rde1  Raf8 25. Rhf1 Qd6 26. Re5 Rxe5 27. fxe5 Rxf1+ 28. Bxf1 Qe7 29. a4 Be8 30. Kb2  Bg6 31. Bh3 h6  32. gxh6 gxh6 33. Qg4 Kf7 34. h5 Be4 35. a5 Bh7 36. c3  Be4 37. c4 Bf5 38. Qf4 dxc4 39. Bxf5 exf5 40. Qxf5+ Ke8 41. Qc8+ Kf7 42. Qxc4+ Kg7 43. Qd5  Kf8 44. Kc3 Ke8 45. b4 Qc7+ 46. Kd4 Qe7 47. Qg8+ Kd7 48. Kd5 Kc7 49. Qg6  Qh4 50. Qd6+ Kc8 51. Kc5  Qf2+ 52. Qd4 Qf7 53. Qc4  Qg7 54. Kb6+ Kb8 55. Qc5 Qf7 56. Qd6+ Kc8 57. e6 1-0 "

; sample game 632
EventSites(632) = "FIDE Candidates  Khanty-Mansiysk" : GameDates(632) = "20140329" : WhitePlayers(632) = "Andreikin, Dmitry   G#632" : WhiteElos(632) = "2709" : BlackPlayers(632) = "Aronian, Levon   G#632" : BlackElos(632) = "2830" : Each_Game_Result(632) = "1-0"

FilePGNs(632) = "1. d4 Nf6 2. Bg5 g6 3. Bxf6 exf6 4. c4 Bb4+ 5. Nd2 c5 6. a3 Bxd2+ 7. Qxd2 cxd4 8. Nf3 Nc6 9. Nxd4 Nxd4 10. Qxd4 Qa5+ 11. b4 Qe5 12. O-O-O  a5 13. b5 d6 14. Qxe5+ dxe5 15. g3 Be6 16. Bg2 Bxc4  17. Bxb7 Rb8 18. Bc6+ Kf8 19. a4 Bb3 20. Kb2  Bxa4  21. Rd5 Ke7 22. Ka3 Bc2 23. Rd7+ Kf8 24. e4  a4 25. Rc1 Bb3 26. Bd5  Bxd5 27. Rxd5 Kg7 28. Rc7 Rb6 29. Rc6 Rb7 30. Kxa4 Ra8+ 31. Ra6 Rc8 32. b6  Rc2 33. Kb5 Rxf2  34. Kc6 Re7 35. Raa5   Re6+ 36. Rd6 Re7 37. Rdd5 Re6+ 38. Kc7 Re7+ 39. Kc8 Re8+ 40. Kd7 Kf8 41. b7 Re7+ 42. Kc6 Re6+ 43. Kc7 Re7+ 44. Kb6 1-0 "

; sample game 633
EventSites(633) = "Asian Continental op 13th  Sharjah" : GameDates(633) = "20140422" : WhitePlayers(633) = "Negi, Parimarjan   G#633" : WhiteElos(633) = "2640" : BlackPlayers(633) = "Idani, Pouya   G#633" : BlackElos(633) = "2502" : Each_Game_Result(633) = "1-0"

FilePGNs(633) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nge7 5. c3 g6 6. d4 exd4 7. cxd4 b5 8. Bc2  d5  9. exd5 Nxd5 10. O-O Be6  11. Nc3 Bg7 12. Bg5 Nxc3  13. bxc3 Qd7 14. Be4   f5 15. Bc2 Na5 16. Ne1  O-O 17. Nd3 Bc4 18. Re1 Rfe8 19. Rxe8+ Rxe8 20. a4 Nb7  21. axb5 axb5 22. Ra7 Qc6 23. Ne5 Bxe5  24. dxe5 Nc5  25. h4 Ne6 26. Bb3  Nxg5 27. hxg5 Bxb3 28. Qxb3+ Kg7 29. Qd1  Qxc3 30. e6  Re7  31. g3  f4  32. Ra8  h6 33. Re8  1-0 "

; sample game 634
EventSites(634) = "Gashimov Memorial-A  Shamkir" : GameDates(634) = "20140423" : WhitePlayers(634) = "Caruana, Fabiano   G#634" : WhiteElos(634) = "2783" : BlackPlayers(634) = "Carlsen, Magnus   G#634" : BlackElos(634) = "2881" : Each_Game_Result(634) = "1-0"

FilePGNs(634) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. d4 Nd6 6. Bxc6 dxc6 7. dxe5 Nf5 8. Qxd8+ Kxd8 9. h3 h6 10. Rd1+ Ke8 11. Nc3 Bd7 12. Bf4 Rd8 13. Ne4 Be7 14. g4 Nh4 15. Nxh4 Bxh4 16. Kg2 Be6 17. f3 b6 18. b3 c5  19. c4 Rd7 20. Bg3 Be7 21. Rxd7 Bxd7 22. Nc3 Kd8  23. Nd5 Re8 24. Rd1 Kc8  25. Nxc7 Rd8 26. Nd5 Re8 27. Be1 Bd8 28. Bc3 g6 29. Kg3 b5 30. cxb5 Bxb5 31. Ne3 Re6 32. f4 Ra6 33. Rd2 h5 34. gxh5 gxh5 35. Nf5 Rg6+ 36. Kh2 Bc6 37. Nd6+ Kb8 38. f5 Rg8 39. f6  Bb6 40. Nc4  Re8  41. Nd6 Rg8 42. Nxf7  c4 43. h4 Rg4 44. e6 Be3 45. Be5+ Ka8 46. Rd8+ Kb7 47. Bg3 c3 48. Rb8+ Ka6 49. Rc8 Bd5 50. Rxc3 Bd4 51. Rd3 Re4 52. Rd2 Rxe6 53. Ng5 1-0 "

; sample game 635
EventSites(635) = "Gashimov Memorial-A  Shamkir" : GameDates(635) = "20140424" : WhitePlayers(635) = "Carlsen, Magnus   G#635" : WhiteElos(635) = "2881" : BlackPlayers(635) = "Radjabov, Teimour   G#635" : BlackElos(635) = "2713" : Each_Game_Result(635) = "0-1"

FilePGNs(635) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nge2 O-O 6. Ng3 e5 7. d5 a5 8. Be2 Na6 9. h4 h5 10. Bg5 Qe8 11. Qd2 Nc5 12. O-O-O Ng4  13. Bxg4 Bxg4 14. f3 Bd7 15. Be3 b6 16. Kb1 Kh7 17. Qc2 a4 18. Nge2 f5 19. exf5 gxf5 20. Rh3 Kh8  21. f4 Ne4  22. Nxe4 fxe4 23. Rg3 Bg4 24. Rxg4  hxg4 25. f5 Rxf5 26. Ng3 Rf8 27. Qxe4 Qd7 28. a3 b5  29. c5 dxc5  30. h5 c4 31. h6 Bf6 32. Bc5 Rf7 33. Rf1 Re8  34. Bb4 Bg5 35. Nf5 c6  36. Bd6 Bf4 37. Ng7 Qxd6 38. Nxe8 Qxd5 39. Qxd5 cxd5 40. g3 Kh7  41. gxf4 exf4 42. Nd6 Rf6 43. Nxb5 f3 44. Nd4 Kxh6 45. Kc2 Kg5 46. Kd2 f2 47. Ne2 Rf3 48. Kc2 Kh4 49. Rh1+ Rh3 50. Rf1 g3 51. Kd2 Kg4 0-1 "

; sample game 636
EventSites(636) = "Poikovsky Karpov 15th  Poikovsky" : GameDates(636) = "20140512" : WhitePlayers(636) = "Bologan, Viktor   G#636" : WhiteElos(636) = "2655" : BlackPlayers(636) = "Jakovenko, Dmitrij   G#636" : BlackElos(636) = "2730" : Each_Game_Result(636) = "0-1"

FilePGNs(636) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 c6 5. Bg5 h6 6. Bh4 dxc4 7. e4 g5 8. Bg3 b5 9. Be2 Bb7 10. O-O Nbd7 11. Ne5 Bb4 12. Qc2 Nxe5  13. Bxe5 O-O 14. Rad1 Qe7 15. b3 cxb3 16. axb3 Rac8  17. Bxf6 Qxf6 18. e5 Qg7 19. Ne4 c5 20. Nf6+ Kh8 21. d5 exd5 22. f4  c4  23. Kh1 d4 24. Rxd4 gxf4 25. Bf3 Bxf3 26. gxf3 cxb3 27. Qxb3 Bc3  28. Rxf4  Bxe5 29. Rg1 Rc1 30. Rxc1 Bxf4 31. Nh5 Qg5 32. Qb4  Bd6  33. Qc3+ Be5 34. f4 Bxc3 35. fxg5 b4 0-1 "

; sample game 637
EventSites(637) = "Capablanca Memorial Elite 49th  Havana" : GameDates(637) = "20140512" : WhitePlayers(637) = "Almasi, Zoltan   G#637" : WhiteElos(637) = "2693" : BlackPlayers(637) = "So, Wesley   G#637" : BlackElos(637) = "2731" : Each_Game_Result(637) = "0-1"

FilePGNs(637) = "1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Bxc3+ 6. bxc3 Ne7 7. Qg4 Qc7 8. Qxg7 Rg8 9. Qxh7 cxd4 10. Ne2 Nbc6 11. f4 dxc3 12. Qd3 d4  13. Ng3 Bd7 14. Be2 O-O-O 15. O-O Nf5 16. Ne4 Nce7 17. Nf6 Rg6 18. Nxd7 Rxd7 19. Bf3 Nd5 20. Rb1 Kb8 21. Be4 Rg8 22. a4 Qc6 23. a5 Qa4 24. a6  b6 25. Rb3 Nde3 26. Ra3 Qb4 27. Rb3 Qa4 28. Ra3 Qb4 29. Rb3 Qe7 30. Bxe3 dxe3  31. Qxc3 e2 32. Re1 Rd1 33. Bxf5 Rc8 34. Qg3  Qc5+ 35. Kh1 exf5 36. Rb1 Qd5 37. h3 Rd8 38. Kh2 Qe4 39. Qh4 R8d7 40. Rb3 Rxe1 41. Qh8+ Kc7 42. Rc3+ Qc6 43. Rxc6+ Kxc6 44. Qc8+ Rc7 45. Qa8+ Kc5 46. Qb8 Rc6 47. Qxa7 Rd1 48. Qe7+ Kb5 0-1 "

; sample game 638
EventSites(638) = "Poikovsky Karpov 15th  Poikovsky" : GameDates(638) = "20140518" : WhitePlayers(638) = "Bologan, Viktor   G#638" : WhiteElos(638) = "2655" : BlackPlayers(638) = "Motylev, Alexander   G#638" : BlackElos(638) = "2687" : Each_Game_Result(638) = "1-0"

FilePGNs(638) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. e3 Bf5 5. Nc3 e6 6. Nh4 Bg6 7. Be2 Nbd7 8. g3 Bd6 9. O-O Qe7 10. Qb3 Rb8 11. Bd2 O-O 12. Nxg6 hxg6 13. Qc2 a6  14. c5  Bc7 15. b4 e5 16. a4 Qe6 17. Kg2 e4 18. f4  exf3+ 19. Bxf3 Rbe8 20. Rab1 Re7 21. b5 axb5 22. axb5 Ba5 23. Nxd5  Nxd5 24. e4  N7f6 25. exd5 Nxd5 26. Rbe1 Qxe1 27. Rxe1 Rxe1 28. Bg5 Nc7  29. bxc6 Ne6 30. cxb7  Nxg5 31. d5 Bc7 32. d6 Bb8 33. Qd2 Rg1+  34. Kf2 Nxf3 35. Kxf3 Rf1+ 36. Kg2 Rf6 37. Qd5 Rf5 38. Qc6 Ba7 39. d7 Rxc5 40. Qd6  Rd8 41. Qe7 Rc2+ 42. Kh3 Rxd7 43. Qxd7 Rb2 44. Qc8+ Kh7 45. Qa8 1-0 "

; sample game 639
EventSites(639) = "RUS-ch Higher League 67th  Vladivostok" : GameDates(639) = "20140610" : WhitePlayers(639) = "Jakovenko, Dmitrij   G#639" : WhiteElos(639) = "2736" : BlackPlayers(639) = "Goganov, Aleksey   G#639" : BlackElos(639) = "2591" : Each_Game_Result(639) = "1-0"

FilePGNs(639) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. e3 e6 5. Bd3 dxc4 6. Bxc4 Nbd7 7. O-O Bd6 8. Nc3 O-O 9. e4 e5 10. Be3 Qc7 11. h3 exd4 12. Nxd4 Ne5 13. Bb3 Ng6 14. Rc1 a6 15. Qd2 Re8 16. Nf3 Bb4  17. Ng5 Bxc3  18. Rxc3 Nxe4 19. Nxe4 Rxe4 20. f4  Bd7  21. f5 Nf8 22. f6   Be6 23. Bc2 Re5 24. fxg7 Ng6 25. Bd4 Rd5  26. Be4  Rd7 27. Qf2 f5  28. Bxf5 Bxf5 29. Qxf5 Re8 30. Bf6 Rf7 31. Qf2 Qd6 32. Rf3  Qe6 33. a3 Qe2 34. Qg3 Qe4 35. Kh2 Ne5 36. Bxe5 Rxf3 37. Rxf3 1-0 "

; sample game 640
EventSites(640) = "Norway Chess 2nd  Stavanger" : GameDates(640) = "20140612" : WhitePlayers(640) = "Karjakin, Sergey   G#640" : WhiteElos(640) = "2771" : BlackPlayers(640) = "Kramnik, Vladimir   G#640" : BlackElos(640) = "2783" : Each_Game_Result(640) = "1-0"

FilePGNs(640) = "1. c4 e6 2. Nc3 d5 3. d4 Nf6 4. cxd5 exd5 5. Bg5 c6 6. e3 h6 7. Bh4 Be7 8. Bd3 O-O 9. Qc2 Nh5 10. Bxe7 Qxe7 11. Nf3 Nf4 12. Bf1 Nd7 13. O-O-O Ng6 14. h4 Qf6 15. Bd3 Nb6 16. h5 Ne7 17. Rh4 Bf5  18. Bxf5 Qxf5 19. Qxf5 Nxf5 20. Rf4 Nd6  21. Ne5 Rae8 22. Rh1 Re7 23. Kc2 Rfe8 24. b3 a5 25. a4 Na8  26. Nd3 Nc7 27. Rg4 Na6 28. Rf4 Ne4 29. Kb2 Kh7 30. Nxe4  dxe4 31. Ne5 Nb4 32. Rf5 c5 33. Rd1 cxd4 34. exd4 Rd8 35. Nc4 Nd3+ 36. Kc3 g6 37. Rxa5 Nxf2 38. Re1 gxh5 39. d5  e3  40. Kc2  Ng4  41. d6 Re6  42. Ra7   Rf6 43. Re2 b6 44. Rb7 Rdxd6 45. Nxd6 Rxd6 46. Rxf7+ Kg6 47. Rf1 Kg5 48. b4 h4 49. Kc3  Nf2  50. Rxe3 Nd1+ 51. Rxd1 Rxd1 52. Re5+  Kg4 53. Re6 Rc1+ 54. Kb3 Kh5 55. Rxb6 Rg1 56. a5 Rxg2 57. a6 Rg3+ 58. Kc4 Rg4+ 59. Kd3 Rg8 60. Rb5+ Kg4 61. Ra5 h3 62. Ra2 Ra8 63. b5 h5 64. Ke3 Kg3 65. a7 h2 66. Rxh2 Kxh2 67. b6 Kh3 68. b7 Rxa7 69. b8=Q Rg7 70. Qe5 Rg3+ 71. Kf2 h4 72. Qe4 1-0 "

; sample game 641
EventSites(641) = "GRE-chT 42nd  Porto Rio" : GameDates(641) = "20140629" : WhitePlayers(641) = "Ganguly, Surya Shekhar   G#641" : WhiteElos(641) = "2619" : BlackPlayers(641) = "Postny, Evgeny   G#641" : BlackElos(641) = "2641" : Each_Game_Result(641) = "1/2-1/2"

FilePGNs(641) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. b4 Bxb4 5. c3 Be7 6. d4 Na5 7. Bd3 d6 8. dxe5 dxe5 9. Nxe5 Nf6 10. O-O O-O 11. Qc2 Qd6   12. Nf3 Rd8 13. Be2 Qc6 14. Nbd2 Be6 15. e5 Nd5 16. Ne4 Nb4  17. Qb1 Bxa2  18. Rxa2 Nxa2 19. Bg5  Nxc3  20. Nxc3 Bxg5 21. Nxg5 Qg6 22. Nce4  h6 23. Nf3 Nc6 24. Bc4 Nd4 25. Nf6+ Kh8  26. Qxg6 fxg6 27. Nd5 b5  28. Nxd4  bxc4 29. Nxc7 Rac8  30. Ncb5 Rd5 31. Nxa7  Rcd8 32. Ndc6  c3  33. Nb4 Rd1  34. e6 Rxf1+ 35. Kxf1 Rd1+ 36. Ke2 Rd6 37. e7 Re6+ 38. Kd3 Rxe7 39. Nb5 Re1 40. Nc2 Rf1 41. Ke2 Rg1 42. g3 g5 43. Ne3 c2 44. Nxc2 Rh1 45. Ne3 Rxh2 46. Nf1 Rh1 47. f3 g4  48. fxg4 h5 49. g5 h4 50. Nd4 Kh7 51. Nf3 hxg3 52. Nxg3 Ra1 53. Ke3 Kg6 54. Kf4 Ra4+ 55. Ne4 Rb4 56. Ne5+ Kh5 57. g6 Kh6 58. Kf5 Rb5 59. Nd6 Rxe5+ 60. Kxe5 Kxg6 1/2-1/2 "

; sample game 642
EventSites(642) = "Dortmund SuperGM 42nd  Dortmund" : GameDates(642) = "20140712" : WhitePlayers(642) = "Kramnik, Vladimir   G#642" : WhiteElos(642) = "2777" : BlackPlayers(642) = "Meier, Georg   G#642" : BlackElos(642) = "2632" : Each_Game_Result(642) = "0-1"

FilePGNs(642) = "1. c4 c5 2. Nf3 Nf6 3. g3 Nc6 4. Bg2 d5 5. O-O d4 6. a3 e5 7. d3 a5 8. e4  Be7 9. Ne1 h5  10. f4 h4 11. f5 hxg3 12. hxg3 g6  13. Nd2 gxf5 14. exf5 Rg8 15. Qf3  Bd7 16. Rf2 Qb6 17. Re2 O-O-O 18. Ne4 Qb3 19. Nf2 a4 20. Bh6 Bf8 21. Bxf8 Rdxf8 22. g4 Rg7 23. Ne4 Nxe4 24. Qxe4 Rfg8 25. Bf3 f6 26. Rg2 Nd8  27. Qe2 Bc6 28. Bxc6 bxc6  29. Qe4 Kc7 30. Nf3 Nf7 31. Rf1 Nd6 32. Qe2 Rxg4 33. Rf2 Nxf5 34. Nd2 Rxg2+ 35. Rxg2 Rxg2+ 36. Kxg2 Qxb2 37. Kf3 Nd6 38. Qh2 Qxa3 39. Ke2 Qb2 40. Qh7+ Kb6 41. Qe7 Nb7 0-1 "

; sample game 643
EventSites(643) = "Dortmund SuperGM 42nd  Dortmund" : GameDates(643) = "20140713" : WhitePlayers(643) = "Caruana, Fabiano   G#643" : WhiteElos(643) = "2789" : BlackPlayers(643) = "Ponomariov, Ruslan   G#643" : BlackElos(643) = "2723" : Each_Game_Result(643) = "1-0"

FilePGNs(643) = "1. e4 e5 2. Nf3 Nf6 3. Nxe5 d6 4. Nf3 Nxe4 5. Nc3 Nxc3 6. dxc3 Be7 7. Be3 Nc6 8. Qd2 Be6 9. O-O-O Qd7 10. Kb1 Bf6 11. h3  h6 12. b3 a6 13. g4 O-O-O 14. Bg2 g5  15. Nd4 Nxd4 16. cxd4 d5 17. f4 gxf4 18. Bxf4 h5 19. g5 Bg7 20. Rde1 h4 21. Be5 Rdg8 22. Qf4 Qd8 23. Bf1 Kb8 24. Bd3 Bc8  25. Kb2 Bxe5 26. Rxe5 Rg7 27. a4 a5 28. Ka2 Ka7 29. Qd2 Kb8 30. Qf4 Ka7 31. Rhe1 Bxh3 32. Rh1 Bc8 33. Rxh4 Rxh4 34. Qxh4 b6  35. Qh6 Rg8 36. Qc6  Be6 37. g6 Rg7  38. gxf7 Bxf7 39. Re7  Qxe7 40. Ba6  Kxa6 41. Qa8# 1-0 "

; sample game 644
EventSites(644) = "Bergamo ACP Golden Classic  Bergamo" : GameDates(644) = "20140713" : WhitePlayers(644) = "Sutovsky, Emil   G#644" : WhiteElos(644) = "2620" : BlackPlayers(644) = "Jobava, Baadur   G#644" : BlackElos(644) = "2713" : Each_Game_Result(644) = "1-0"

FilePGNs(644) = "1. e4 c5 2. Nf3 b6 3. d4 cxd4 4. Nxd4 Bb7 5. Nc3 Nf6 6. e5 Nd5 7. Nxd5 Bxd5 8. Nb5 Be6  9. Bd3 Nc6 10. Be4 g6 11. Bg5  Bg7 12. O-O Bxe5 13. f4 h6 14. fxe5 hxg5 15. Qd2 Qb8 16. Qxg5 Bc4 17. Nd6+  exd6 18. Qf6 Rg8  19. e6  Ne5 20. exf7+ Bxf7 21. Rae1 1-0 "

; sample game 645
EventSites(645) = "EU-ch (Women) 15th  Plovdiv" : GameDates(645) = "20140717" : WhitePlayers(645) = "Kosintseva, Tatiana   G#645" : WhiteElos(645) = "2476" : BlackPlayers(645) = "Zhukova, Natalia   G#645" : BlackElos(645) = "2451" : Each_Game_Result(645) = "1-0"

FilePGNs(645) = "1. e4 Nf6 2. e5 Nd5 3. d4 d6 4. Nf3 Bg4 5. Be2 e6 6. O-O Be7 7. c4 Nb6 8. exd6 cxd6 9. Nc3 O-O 10. h3 Bh5 11. Be3 d5 12. c5 Bxf3 13. Bxf3 Nc4 14. Bf4 Nc6 15. b3 N4a5 16. Rb1 b6 17. b4 Nc4 18. Be2 Bg5 19. Bxg5 Qxg5 20. Bxc4 dxc4 21. b5 Ne7 22. Qe2 Nf5 23. Rfd1 Rad8 24. Qe5 Qh4 25. d5 bxc5 26. dxe6 fxe6 27. Qxe6+ Kh8 28. Rxd8 Qxd8 29. Qxc4 Qd4 30. Qxd4 cxd4 31. Ne4 h6 32. a4 Rb8 33. Kf1 Ne7 34. Ke2 Nd5 35. Kd3 Rd8 36. a5 Nf4+ 37. Kd2 Rb8 38. b6 axb6 39. axb6 Ne6 40. b7 Kg8 41. Nd6 Nd8 42. Kd3 Kf8 43. Kxd4 Ke7 44. Kd5 Kd7 45. Rc1 Ne6 46. Ke5 Nc7 47. f4 h5 48. g4 hxg4 49. hxg4 g6 50. f5 gxf5 51. gxf5 Na6 52. f6 Nb4 53. Rc8 Nd3+ 54. Kd4 1-0 "

; sample game 646
EventSites(646) = "Bergamo ACP Golden Classic  Bergamo" : GameDates(646) = "20140718" : WhitePlayers(646) = "Vocaturo, Daniele   G#646" : WhiteElos(646) = "2584" : BlackPlayers(646) = "Sutovsky, Emil   G#646" : BlackElos(646) = "2620" : Each_Game_Result(646) = "0-1"

FilePGNs(646) = "1. d4 e6 2. c4 Bb4+ 3. Bd2 Qe7 4. g3 Nf6 5. Bg2 Nc6 6. e3 e5 7. d5 Bxd2+ 8. Qxd2 Nb8 9. Nc3 d6 10. Nge2 Nbd7 11. e4 a5 12. Na4 O-O 13. Nec3 Nc5  14. O-O Bd7 15. Nxc5 dxc5 16. Nd1  a4  17. Ne3 Ne8 18. f4 Nd6 19. f5 b5 20. cxb5 Rfb8 21. f6 gxf6 22. Rf2 Rxb5 23. Raf1 Rab8 24. Rxf6  Rxb2 25. Qc1 Rb1  26. Qc2 R8b2 27. Qd3 Qxf6 0-1 "

; sample game 647
EventSites(647) = "Dortmund SuperGM 42nd  Dortmund" : GameDates(647) = "20140718" : WhitePlayers(647) = "Leko, Peter   G#647" : WhiteElos(647) = "2737" : BlackPlayers(647) = "Naiditsch, Arkadij   G#647" : BlackElos(647) = "2705" : Each_Game_Result(647) = "1-0"

FilePGNs(647) = "1. d4 Nf6 2. c4 e6 3. Nc3 d5 4. cxd5 exd5 5. Bg5 c6 6. Qc2 Be7 7. e3 Nbd7 8. Bd3 Nh5 9. Bxe7 Qxe7 10. Nge2 Nhf6 11. O-O Nb6 12. Rae1 O-O 13. Nf4 Bd7  14. g3  Qd6 15. f3 Rfc8  16. g4 g6 17. a3 c5 18. Qd2 cxd4 19. exd4 Bc6  20. g5 Nfd7 21. Re2 Re8 22. Rfe1 Rxe2 23. Rxe2 Nf8 24. h4 Re8 25. Rxe8 Bxe8 26. Qe3 Bc6 27. Kg2 f6 28. gxf6  Qxf6 29. Kg3 Kf7 30. Nd1 Nbd7 31. Nf2 g5  32. hxg5 Qxg5+ 33. Kh2 Qe7 34. Ng4  Qxe3 35. Nxe3 Nf6 36. Kg3 N8d7 37. Kh4 Nb6 38. Kg5 Nc8 39. Ng4  Nxg4 40. fxg4 Nd6 41. Bxh7 Nb5 42. Ne2 Kg7 43. Bd3 Nd6 44. Kf4 Bd7 45. Nc3 Bc6 46. Nd1 Nf7 47. Ne3 Nd8 48. Bf5 Nf7 49. Be6 Nd6 50. Ke5 1-0 "

; sample game 648
EventSites(648) = "Politiken Cup 36th  Helsingor" : GameDates(648) = "20140728" : WhitePlayers(648) = "Negi, Parimarjan   G#648" : WhiteElos(648) = "2645" : BlackPlayers(648) = "Edouard, Romain   G#648" : BlackElos(648) = "2679" : Each_Game_Result(648) = "1-0"

FilePGNs(648) = "1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. e5 Nfd7 5. f4 c5 6. Nf3 Nc6 7. Be3 Be7 8. Qd2 O-O 9. dxc5 Nxc5  10. O-O-O Qc7 11. Kb1 a6 12. Qe1  b5 13. Bxc5  Bxc5 14. Bd3 Be7 15. f5  b4 16. f6  gxf6 17. Qg3+  Kh8 18. Qh3 f5 19. Bxf5  exf5 20. Nxd5 Qb7 21. Nf6 Bxf6 22. exf6 Rg8 23. Qh5  Be6 24. Rd3 Qc7  25. h4  Rg6 26. Ng5 Bxa2+ 27. Kxa2 h6 28. Rhd1 Ne5  29. Rd6  Rf8  30. Kb1  Rc8 31. R1d2 Kg8 32. Qd1 hxg5 33. Rd8+ Kh7 34. Rxc8 Qxc8 35. Rd8 Qxd8 36. Qxd8 gxh4 37. Qe7 1-0 "

; sample game 649
EventSites(649) = "Tromsoe ol (Men) 41st  Tromsoe" : GameDates(649) = "20140805" : WhitePlayers(649) = "Fier, Alexandr   G#649" : WhiteElos(649) = "2570" : BlackPlayers(649) = "Kigigha, Bomo   G#649" : BlackElos(649) = "2197" : Each_Game_Result(649) = "1-0"

FilePGNs(649) = "1. d4 Nf6 2. Bg5 d5 3. e3 Ne4 4. Bf4 c5 5. Bd3 Nc6 6. Bxe4 dxe4 7. d5 Nb4 8. Nc3 e6 9. d6 f6  10. Nxe4 e5 11. Bxe5 Bf5  12. a3  Bxe4 13. axb4 Bxg2 14. Qh5+ g6 15. Qg4 Bxh1 16. Qe6+ Be7 17. Bxf6 Qxd6 18. Qxd6 Bxd6 19. Bxh8 Bxh2 20. bxc5 Kf7 21. Bd4 h5  22. Nh3 Ke6  23. f3 Bg3+ 24. Ke2 1-0 "

; sample game 650
EventSites(650) = "Tromsoe ol (Men) 41st  Tromsoe" : GameDates(650) = "20140806" : WhitePlayers(650) = "Kramnik, Vladimir   G#650" : WhiteElos(650) = "2760" : BlackPlayers(650) = "Topalov, Veselin   G#650" : BlackElos(650) = "2772" : Each_Game_Result(650) = "1-0"

FilePGNs(650) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Be7 5. g3 O-O 6. Bg2 Nbd7 7. Qd3 Nb6 8. c5 Nbd7 9. O-O c6 10. b4 b6 11. Bf4 a5 12. a3 Ba6 13. Qc2 Nh5 14. Bd2 Nhf6 15. Bf4 Nh5 16. Bd2 Nhf6 17. Rfe1  Bc4 18. Bf4 Nh5 19. Be3 Nhf6 20. Bf4 Nh5 21. Be3 Nhf6 22. h3  h6 23. Nd2 Ba6 24. f4 bxc5 25. bxc5 Nxc5 26. dxc5 d4 27. Bf2 dxc3 28. Qxc3 Nd5 29. Qc2 Bf6 30. e4  Bxa1 31. exd5  Qf6 32. d6  Qc3 33. Qd1 Bb2 34. Bxc6 Rad8 35. Nb1  Qf6 36. Qd2  Rb8 37. Be4 e5 38. Nc3  Qe6 39. Nd5 Qxh3 40. Bg2 Qh5 41. d7 exf4 42. Qxf4 Bxa3 43. Qxb8 Rxb8 44. Re8+ Kh7 45. Rxb8 Qd1+ 46. Kh2 Qh5+ 47. Bh3 Qf3 48. d8=Q Qxf2+ 49. Bg2 1-0 "

; sample game 651
EventSites(651) = "Tromsoe ol (Men) 41st  Tromsoe" : GameDates(651) = "20140808" : WhitePlayers(651) = "Negi, Parimarjan   G#651" : WhiteElos(651) = "2645" : BlackPlayers(651) = "Bologan, Viktor   G#651" : BlackElos(651) = "2654" : Each_Game_Result(651) = "1-0"

FilePGNs(651) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. d3 Bc5 5. Bxc6 dxc6 6. Nbd2 O-O 7. O-O Re8 8. Nc4 Nd7 9. Kh1  Bd6 10. Bg5  f6 11. Be3 Nf8 12. Nh4 Be6 13. Nf5 Qd7 14. Qf3 Ng6 15. g3  Bf8 16. Nd2  c5 17. Rg1  Nh8  18. g4 g6 19. Rg3  Nf7 20. Rag1 Kh8 21. Qg2  Bd6 22. Nf3 Rg8 23. Qh3  g5 24. Qg2  Qa4 25. h4 gxh4 26. N5xh4 Be7 27. Nf5 Qd7 28. Qh2 Bxf5 29. gxf5 1-0 "

; sample game 652
EventSites(652) = "Tromsoe ol (Men) 41st  Tromsoe" : GameDates(652) = "20140809" : WhitePlayers(652) = "Svidler, Peter   G#652" : WhiteElos(652) = "2751" : BlackPlayers(652) = "Laznicka, Viktor   G#652" : BlackElos(652) = "2676" : Each_Game_Result(652) = "0-1"

FilePGNs(652) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Nf3 e6 5. Be2 Ne7 6. Nbd2 c5 7. dxc5 Nec6 8. Nb3 Nd7 9. O-O Bg4 10. Nfd4 Bxe2 11. Qxe2 Nxd4 12. Nxd4 Bxc5 13. Be3 O-O 14. f4 Qc7 15. Rac1 Rac8 16. b3 a6 17. c3 Rfe8 18. Bf2 b5 19. Kh1 g6 20. h4 Bf8 21. Nf3 Nc5 22. Bd4  Ne4 23. Kh2 Qa5 24. c4 bxc4 25. bxc4 Ba3 26. Rc2 Qa4 27. Qd3 Rc7  28. Rb1 Rec8 29. Qb3 Qxb3 30. axb3 dxc4 31. Ra1 Bb4 32. bxc4 Rxc4 33. Rxc4 Rxc4 34. Rxa6  Nd2 35. Ra8+ Kg7 36. Bf2 Rxf4  37. Kg3 Rf5 38. Be3  Nxf3 39. gxf3 Be1+ 40. Kg2 Bxh4 41. Bc5 h5 0-1 "

; sample game 653
EventSites(653) = "Tromsoe ol (Men) 41st  Tromsoe" : GameDates(653) = "20140811" : WhitePlayers(653) = "Meier, Georg   G#653" : WhiteElos(653) = "2646" : BlackPlayers(653) = "Kamsky, Gata   G#653" : BlackElos(653) = "2706" : Each_Game_Result(653) = "1-0"

FilePGNs(653) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. e3 g6 5. Nc3 Bg7 6. Be2 O-O 7. O-O Qb6 8. Ne5 Be6 9. Na4  Qc7 10. Nc5 Bf5 11. cxd5 cxd5 12. Bd2 Ne4 13. Nxe4 Bxe4 14. Rc1 Qb6 15. Bc3 Bf5 16. Qa4 a5 17. Bb5 Rd8 18. Rfd1 f6 19. Nd3 Bd7 20. Bxd7 Nxd7 21. Be1  e5 22. dxe5 fxe5 23. b4  axb4 24. Qb3 Qb5 25. Bxb4 Kh8 26. Rc7  Rac8 27. Rdc1 Nb6  28. Bf8 1-0 "

; sample game 654
EventSites(654) = "Tromsoe ol (Men) 41st  Tromsoe" : GameDates(654) = "20140812" : WhitePlayers(654) = "Eljanov, Pavel   G#654" : WhiteElos(654) = "2723" : BlackPlayers(654) = "Mamedov, Rauf   G#654" : BlackElos(654) = "2659" : Each_Game_Result(654) = "1-0"

FilePGNs(654) = "1. d4 d5  2. c4 c6 3. cxd5  cxd5 4. Bf4 Nc6 5. e3 Nf6 6. Nc3 Bf5 7. Rc1  Qb6 8. Bb5 e6 9. Nf3 Bb4  10. O-O Bxc3 11. Bxc6+ bxc6 12. bxc3 O-O 13. Ne5 Qa6  14. g4 Bg6 15. h4 h6 16. Nxg6 fxg6 17. f3  h5 18. Qc2 Kh7 19. Bd6  Rf7 20. Rf2  Rd7 21. Be5 Rf8 22. Bxf6 Rxf6 23. gxh5 Kh6 24. hxg6 Rxg6+ 25. Rg2 Rxg2+ 26. Kxg2 Rf7 27. Rg1 g6 28. Kh1 Rf6 29. h5  1-0 "

; sample game 655
EventSites(655) = "Tromsoe ol (Men) 41st  Tromsoe" : GameDates(655) = "20140812" : WhitePlayers(655) = "Nisipeanu, Liviu Dieter   G#655" : WhiteElos(655) = "2689" : BlackPlayers(655) = "Sasikiran, Krishnan   G#655" : BlackElos(655) = "2669" : Each_Game_Result(655) = "0-1"

FilePGNs(655) = "1. d4 d5 2. Nf3 Nf6 3. c4 c6 4. e3 g6 5. Nbd2 a5  6. b3 Bg7 7. Bb2 O-O 8. Be2 Bf5 9. O-O Ne4  10. Nxe4 Bxe4 11. Nd2  Bf5 12. a3 Nd7 13. b4  Nf6 14. Bc3 axb4 15. axb4 Qc7  16. c5 Nd7  17. Nb3 h5 18. Qc1 Nf6  19. f3 Bh6  20. Qd2  Qd7  21. Ra5  Qe6 22. Kf2 g5  23. Nc1  g4 24. Nd3 gxf3  25. gxf3 Bxd3 26. Bxd3  Kh8  27. Ke2 Rg8 28. Rxa8 Rxa8 29. Bb1 Rg8  30. Kd1 Qxe3 31. Qxe3 Bxe3 32. Re1 Rg1 33. Bd3 Nd7  34. Ke2 Rxe1+ 35. Kxe1 Nf8  36. Bf5 Ne6 37. Bxe6 fxe6 38. Ke2 Bf4 39. h3 Kg7 40. Kd3 Kg6 41. Be1 Kg5  42. b5 e5 43. bxc6 bxc6 44. Bf2 exd4 45. Kxd4 Kf5 46. Bh4 Be5+ 47. Ke3 Bf6 48. Be1 Bb2 0-1 "

; sample game 656
EventSites(656) = "Tromsoe ol (Men) 41st  Tromsoe" : GameDates(656) = "20140814" : WhitePlayers(656) = "Negi, Parimarjan   G#656" : WhiteElos(656) = "2645" : BlackPlayers(656) = "Kasimdzhanov, Rustam   G#656" : BlackElos(656) = "2700" : Each_Game_Result(656) = "1-0"

FilePGNs(656) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. a4 b4 9. d4 d6 10. dxe5 dxe5 11. Nbd2 Bc5 12. a5 Be6   13. Qe2 Qe7 14. Bxe6 Qxe6 15. Nb3 Nd4  16. Nfxd4 Bxd4 17. h3 c5 18. Nd2 c4  19. Nxc4 Nxe4 20. Be3  Bxe3 21. Nxe3 Nc5 22. Rad1 Rad8 23. b3 f6 24. Qf3  h6 25. Rd5  Rxd5 26. Nxd5 Rb8 27. Rd1 Kh8 28. h4 f5 29. Nb6 Ne4 30. Qd3 Nc3 31. Qd6  Qxd6 32. Rxd6 Ne2+ 33. Kf1 Nd4 34. Nc4  Ra8 35. Nxe5 Nxc2 36. Nd3  Rc8 37. Rxa6 Rc3 38. Ne5  Rxb3 39. Ra8+ Kh7 40. g4  Rb1+ 41. Kg2 Ne1+ 42. Kg3 Rb3+ 43. Kf4 Nd3+  44. Kxf5 Nxe5 45. Kxe5 Rd3  46. a6 Rd1  47. a7 Ra1 48. Kd4 g5 49. hxg5 hxg5 50. Kc4 b3 51. Kxb3 Kg7 52. Kc4 Ra2  53. Kd5 Rd2+ 54. Ke4 Re2+ 55. Kd3 Ra2 56. f3 Ra3+ 57. Kd4 Ra1 58. Ke5 Ra5+ 59. Kd6 Ra6+ 60. Kc7 Ra3 61. Kc6 Rc3+ 62. Kd5 Ra3 63. Kc5  Ra6 64. Kc4 Ra3 65. Kb5  Ra1  66. Kb6 Rb1+ 67. Kc6 Rc1+ 68. Kd6 Rd1+ 69. Ke6 1-0 "

; sample game 657
EventSites(657) = "Tromsoe ol (Men) 41st  Tromsoe" : GameDates(657) = "20140814" : WhitePlayers(657) = "Illingworth, Max   G#657" : WhiteElos(657) = "2439" : BlackPlayers(657) = "Nisipeanu, Liviu Dieter   G#657" : BlackElos(657) = "2689" : Each_Game_Result(657) = "1-0"

FilePGNs(657) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 Qc7 6. Be3 a6 7. Qd2 Nf6 8. f4  b5  9. e5 Ng4 10. Bg1 Bb7 11. O-O-O Nxd4 12. Bxd4 Be7 13. Bd3 f5 14. h3 Nh6 15. Rhg1 O-O 16. g4   Bc6  17. g5 Nf7 18. g6  Nh6 19. Qf2 Rac8 20. Kb1 b4 21. Ne2 Bb5 22. Qg3 Kh8 23. gxh7 Rf7 24. Bxb5 axb5 25. Rd2 Qc6 26. Qd3 Kxh7 27. Be3 Ra8 28. Nd4  Qa6 29. Qb3 Qb7 30. Rf2 Ra6 31. Nf3  Kh8 32. Nd4  Ra4 33. Ne2 Kh7 34. Qd3 Ra6 35. Nc1 Rc6 36. Qe2 Rc4 37. Qh5 Qc8 38. Rg6 Qf8 39. Rfg2 Re4 40. Bd2 Rd4 41. Nd3  Kh8 42. b3 Re4 43. Ne1 d6 44. Nf3 dxe5 45. Ng5 Rf6 46. Nxe4 Rxg6 47. Rxg6 fxe4 48. Qxe5 Bf6 49. Qxe4 1-0 "

; sample game 658
EventSites(658) = "EU-Cup 30th  Bilbao" : GameDates(658) = "20140915" : WhitePlayers(658) = "Dreev, Alexey   G#658" : WhiteElos(658) = "2662" : BlackPlayers(658) = "Adams, Michael   G#658" : BlackElos(658) = "2752" : Each_Game_Result(658) = "0-1"

FilePGNs(658) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 d5 5. cxd5 exd5 6. Bg5 h6 7. Bh4 c5 8. dxc5 O-O  9. e3 Be6 10. Nf3 Nbd7 11. Be2 Rc8 12. Nd4 Nxc5 13. Bxf6 Qxf6 14. O-O Nd7 15. Qa4 Bxc3 16. bxc3 a6 17. Qb4 Rc7 18. a4 Rfc8 19. a5 Ne5 20. Rab1 Bg4 21. Bxg4 Nxg4 22. Ne2 Ne5 23. Rfd1 Rd7 24. h3 Qd8 25. Nd4 g6 26. Ra1 Rc4 27. Qa3 Qc7 28. Rdc1 Nd3 29. Rc2 Nc5 30. Qb4 Qd8 31. Qb1 Na4 32. Nb3 Nxc3 33. Qf1 Rdc7 34. Qd3 Nb5 35. Rxc4 Rxc4 36. Rd1 Rc3 37. Qb1 Qd6 38. Nd4 Nxd4 39. exd4 Ra3 40. Qxb7 Rxa5 41. Re1 Kg7 42. g3 Qf6 43. Qb2 Ra4 44. Kg2 Rxd4 45. Re8 Rf4 46. Qa2 Qc6 47. gxf4 Qxe8 48. Qxd5 Qb5 49. Qd4+ Kh7 50. Qa7 Qd5+ 51. Kg3 a5 52. f3 Kg7 53. h4 h5 54. Qe7 Qd4 55. Qa3 a4 56. Qe7 Qg1+ 57. Kh3 Qh1+ 58. Kg3 Qg1+ 59. Kh3 Qa1 60. Kg3 a3 61. f5 a2 62. fxg6 Qf6 0-1 "

; sample game 659
EventSites(659) = "EU-Cup 30th  Bilbao" : GameDates(659) = "20140916" : WhitePlayers(659) = "Sutovsky, Emil   G#659" : WhiteElos(659) = "2632" : BlackPlayers(659) = "Ragger, Markus   G#659" : BlackElos(659) = "2657" : Each_Game_Result(659) = "1-0"

FilePGNs(659) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. d4 Nd6 6. Bxc6 dxc6 7. dxe5 Nf5 8. Qxd8+ Kxd8 9. Rd1+ Ke8 10. Nc3 Ne7 11. h3 Ng6 12. b3 Be7 13. Bb2 a5 14. Re1 Be6 15. Nd4 Bb4 16. Re4 Bxc3 17. Bxc3 Bd5 18. Rg4 Rg8 19. Rd1  a4 20. Bb4 Rd8 21. e6 b6 22. Nxc6  Bxc6 23. Rxd8+ Kxd8 24. exf7 Rh8 25. bxa4 Bxa4 26. Bc3 Bd7 27. Rxg6 hxg6 28. Bxg7 Ke7 29. Bxh8 Kxf7 30. g4 b5 31. a3 Ke6 32. f4 Kd5 33. Kf2 c5 34. c3 Ke4 35. Kg3 Be6 36. Be5 Bc4 37. Kh4 Bf1 38. Bd6 c4 39. f5 gxf5 40. g5 Kd5 41. g6  Ke6 42. Kg5 Bxh3 43. Kh6 f4 44. g7 1-0 "

; sample game 660
EventSites(660) = "EU-Cup 30th  Bilbao" : GameDates(660) = "20140919" : WhitePlayers(660) = "Postny, Evgeny   G#660" : WhiteElos(660) = "2641" : BlackPlayers(660) = "Movsesian, Sergei   G#660" : BlackElos(660) = "2663" : Each_Game_Result(660) = "0-1"

FilePGNs(660) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 a6 5. c5 Bf5 6. Nh4 Bg6 7. Bf4 Nbd7 8. e3 Bh5  9. Qb3 Qc8  10. h3 e6 11. g4 Bg6 12. Nxg6 hxg6 13. Bg2 Be7 14. Bh2  Bd8 15. e4  g5  16. O-O-O Bc7 17. e5  Ng8 18. Na4 Bd8 19. Qe3 Qc7 20. Kb1 Qa5 21. b3 Rb8 22. Rc1  Ne7  23. f4 gxf4 24. Bxf4 Ng6 25. Bg3 Bh4 26. Bxh4 Nxh4 27. Bf1 Qd8 28. Bd3 Qe7 29. Rhf1 Kf8  30. Rf2 Kg8 31. Rcf1 Rf8 32. Nc3 Rh6 33. Ne2 Ng6 34. Ng3  Qh4  35. Rf3 Qe7 36. Bc2 Nh4 37. R3f2 Rh8 38. Nh5  Ng6 39. Qd2  Qd8 40. Bxg6  fxg6 41. Nf4 Qe8 42. Qd3 Rh6  43. Kb2 Rf7 44. Qg3  Nf8  45. h4 Qe7 46. Ng2 Rxf2+ 47. Qxf2 Rh8 48. g5 Nd7 49. Qc2 Qe8 50. Rf4 Kh7 51. Qd3 Rf8 52. h5 Rxf4 53. Nxf4 Nf8 54. hxg6+  Kg8 55. Qh3 Qe7 56. Qg4 Qd8 57. b4 Qe7 58. Kc2 Qe8 59. Qh3 Qe7 60. Qh5 b5  61. Qg4 Qd8 62. a3 Qe8 63. Kd3 Qd8 64. Ke3 a5 65. Kf3 axb4 66. axb4 Qa8 67. Kg3 Qa1 68. Qf3  Qxd4 69. Nxd5  Nxg6  70. Ne3 Qh4+ 71. Kg2 Nxe5 72. Qg3 Qe4+ 73. Kf2 Nd3+ 74. Ke2 Nf4+ 75. Kf2 Qxb4 76. Qf3 Nd3+ 77. Ke2 Ne5 78. Qh3 Qb2+ 79. Kf1 Qb1+ 80. Kf2 Qa2+ 81. Kg1 b4 82. Qg3 Qb1+ 83. Kh2 Qe4 0-1 "

; sample game 661
EventSites(661) = "EU-Cup 30th  Bilbao" : GameDates(661) = "20140920" : WhitePlayers(661) = "Harikrishna, Penteala   G#661" : WhiteElos(661) = "2725" : BlackPlayers(661) = "Dreev, Alexey   G#661" : BlackElos(661) = "2662" : Each_Game_Result(661) = "1-0"

FilePGNs(661) = "1. e4 c6 2. Nf3 d5 3. exd5 cxd5 4. Ne5  Nc6 5. d4 a6 6. c4 Nf6 7. Nc3 Nxe5 8. dxe5 d4 9. exf6 dxc3 10. Qxd8+ Kxd8 11. bxc3 exf6 12. Be3 Bf5 13. Be2 Kc7 14. O-O Re8  15. Rfd1 Bc5 16. Bxc5 Rxe2 17. Bd6+ Kc6 18. Bf4 Rhe8 19. Kf1 Bc2 20. Rd6+ Kc5 21. Rd7 Kxc4 22. Be3 R8xe3  23. fxe3 Bd3 24. Kg1  Kxc3 25. Rxb7 Rxg2+ 26. Kxg2 Be4+ 27. Kf2 Bxb7 28. Rg1  g6  29. Rd1 Kc4 30. Rd6 a5 31. Rb6 Be4 32. Rxf6 Bd5 33. Rf4+ Kc5 34. a3 f5 35. Rh4 Bg8 36. Kg3 Kb5 37. Rd4 g5 38. e4 fxe4 39. Rxe4 h6 40. Kg4 Bf7 41. Re7 Bb3 42. Re5+ Ka4 43. Kh5 g4 44. Kxh6 Bd1 45. Kg5 Bf3 46. Kf5 Kxa3 47. Rxa5+ Kb4 48. Re5 Kc4 49. Kf4 Kd4 50. Re1 1-0 "

; sample game 662
EventSites(662) = "Baku FIDE GP  Baku" : GameDates(662) = "20141010" : WhitePlayers(662) = "Tomashevsky, Evgeny   G#662" : WhiteElos(662) = "2701" : BlackPlayers(662) = "Radjabov, Teimour   G#662" : BlackElos(662) = "2726" : Each_Game_Result(662) = "1/2-1/2"

FilePGNs(662) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. Bd2 Nb6 6. e3 Bg7 7. f4 c5 8. dxc5 N6d7 9. Ne4 Bxb2 10. Rb1 Bg7 11. Bc4 O-O 12. Nf3 Nf6 13. Neg5 e6 14. O-O h6 15. Nxf7  Rxf7 16. Ne5 Rf8  17. Nxg6 Re8 18. f5 Na6 19. c6  bxc6 20. fxe6 Bxe6 21. Bxa6 Ne4 22. Bb4 Bxa2  23. Ne7+ Kh8 24. Qxd8 Raxd8 25. Nxc6 Bxb1 26. Nxd8 Rxd8 27. Rxb1 Rb8  28. Bd3 Nc3 29. Bxc3 Rxb1+ 30. Bxb1 Bxc3 31. Kf2 1/2-1/2 "

; sample game 663
EventSites(663) = "Hoogeveen Unive op 18th  Hoogeveen" : GameDates(663) = "20141016" : WhitePlayers(663) = "Roiz, Michael   G#663" : WhiteElos(663) = "2585" : BlackPlayers(663) = "Hansen, Eric   G#663" : BlackElos(663) = "2574" : Each_Game_Result(663) = "1-0"

FilePGNs(663) = "1. Nf3 c5 2. c4 Nf6 3. g3 g6 4. b3 b6 5. Bg2 Bb7 6. Bb2 Bg7 7. O-O d6 8. Nc3 O-O 9. d4 cxd4 10. Nxd4 Bxg2 11. Kxg2 d5 12. cxd5 Nxd5 13. e3  Nxc3 14. Bxc3 Qd5+ 15. Qf3 Qxf3+ 16. Kxf3 Rc8 17. Rac1 Nd7  18. Rfd1 a6 19. Ne2  Bxc3 20. Rxd7 Bb4 21. Rb7 Bc5 22. Nf4 Rd8 23. Ke2 Rd6  24. Nd3  Rad8  25. Nxc5 Rd2+ 26. Ke1 bxc5 27. Rb8  Rxb8 28. Kxd2 Rd8+  29. Ke2 Rd5 30. Rc4 1-0 "

; sample game 664
EventSites(664) = "Tashkent FIDE GP  Tashkent" : GameDates(664) = "20141027" : WhitePlayers(664) = "Andreikin, Dmitry   G#664" : WhiteElos(664) = "2722" : BlackPlayers(664) = "Karjakin, Sergey   G#664" : BlackElos(664) = "2767" : Each_Game_Result(664) = "1-0"

FilePGNs(664) = "1. d4 Nf6 2. Nf3 e6 3. Bg5 c5 4. Nc3 cxd4 5. Qxd4 Nc6 6. Qh4 Bb4 7. e4 Bxc3+ 8. bxc3 h6 9. Bd3 d6  10. Rd1 Rg8  11. Be3  e5 12. Bb5 Qc7  13. Nd2 Be6 14. f3 Qa5  15. c4 Ke7 16. O-O g5  17. Qf2 Rgd8 18. h4   Nh7 19. hxg5 hxg5 20. g4  f6 21. Kg2 Nf8 22. Rh1 Bf7  23. Nf1  Bg6 24. Bd2  Qb6 25. Ne3 Kf7 26. Qe1 Ne6 27. Nf5 Qc7 28. c5  dxc5 29. Bc4  b5 30. Bd5 Rac8 31. Rh6 Nd4 32. Ba5 Nxc2 33. Qh1 Qxa5 34. Rh7+ 1-0 "

; sample game 665
EventSites(665) = "World-ch Carlsen-Anand +3-1=7  Sochi" : GameDates(665) = "20141109" : WhitePlayers(665) = "Carlsen, Magnus   G#665" : WhiteElos(665) = "2863" : BlackPlayers(665) = "Anand, Viswanathan   G#665" : BlackElos(665) = "2792" : Each_Game_Result(665) = "1-0"

FilePGNs(665) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. d3 Bc5 5. O-O d6 6. Re1  O-O 7. Bxc6 bxc6 8. h3 Re8 9. Nbd2 Nd7 10. Nc4 Bb6 11. a4 a5 12. Nxb6 cxb6  13. d4 Qc7  14. Ra3  Nf8 15. dxe5 dxe5 16. Nh4 Rd8 17. Qh5 f6 18. Nf5 Be6 19. Rg3 Ng6 20. h4 Bxf5 21. exf5 Nf4 22. Bxf4 exf4 23. Rc3  c5 24. Re6 Rab8  25. Rc4 Qd7 26. Kh2 Rf8 27. Rce4 Rb7 28. Qe2 b5 29. b3  bxa4 30. bxa4 Rb4 31. Re7 Qd6 32. Qf3 Rxe4 33. Qxe4 f3+ 34. g3 h5  35. Qb7  1-0 "

; sample game 666
EventSites(666) = "World-ch Carlsen-Anand +3-1=7  Sochi" : GameDates(666) = "20141114" : WhitePlayers(666) = "Anand, Viswanathan   G#666" : WhiteElos(666) = "2792" : BlackPlayers(666) = "Carlsen, Magnus   G#666" : BlackElos(666) = "2863" : Each_Game_Result(666) = "1/2-1/2"

FilePGNs(666) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Bb4+ 5. Bd2 Be7 6. Nc3 Bb7 7. Bg2 c6 8. e4  d5 9. exd5  cxd5 10. Ne5 O-O 11. O-O Nc6 12. cxd5  Nxe5 13. d6  Nc6 14. dxe7 Qxe7 15. Bg5 h6 16. d5  Na5 17. Bxf6 Qxf6 18. dxe6 Qxe6  19. Re1 Qf6 20. Nd5  Bxd5 21. Bxd5 Rad8 22. Qf3 Qxb2 23. Rad1 Qf6  24. Qxf6 gxf6 25. Re7 Kg7 26. Rxa7  Nc6 27. Rb7  Nb4 28. Bb3 Rxd1+ 29. Bxd1 Nxa2 30. Rxb6 Nc3 31. Bf3 f5 32. Kg2 Rd8 33. Rc6 Ne4 34. Bxe4 fxe4 35. Rc4 f5 36. g4 Rd2 37. gxf5 e3 38. Re4 Rxf2+ 39. Kg3 Rxf5 1/2-1/2 "

; sample game 667
EventSites(667) = "World-ch Carlsen-Anand +3-1=7  Sochi" : GameDates(667) = "20141115" : WhitePlayers(667) = "Carlsen, Magnus   G#667" : WhiteElos(667) = "2863" : BlackPlayers(667) = "Anand, Viswanathan   G#667" : BlackElos(667) = "2792" : Each_Game_Result(667) = "1-0"

FilePGNs(667) = "1. e4 c5 2. Nf3 e6 3. d4  cxd4 4. Nxd4 a6 5. c4 Nf6 6. Nc3 Bb4 7. Qd3 Nc6  8. Nxc6 dxc6 9. Qxd8+ Kxd8 10. e5 Nd7 11. Bf4 Bxc3+ 12. bxc3 Kc7 13. h4 b6 14. h5 h6  15. O-O-O Bb7 16. Rd3 c5 17. Rg3 Rag8 18. Bd3 Nf8 19. Be3 g6 20. hxg6 Nxg6 21. Rh5 Bc6 22. Bc2 Kb7 23. Rg4 a5 24. Bd1 Rd8 25. Bc2 Rdg8 26. Kd2  a4  27. Ke2 a3 28. f3 Rd8 29. Ke1 Rd7 30. Bc1 Ra8 31. Ke2 Ba4 32. Be4+ Bc6  33. Bxg6 fxg6 34. Rxg6 Ba4 35. Rxe6 Rd1 36. Bxa3 Ra1 37. Ke3 Bc2 38. Re7+ Ka6 39. Rxh6 Rxa2 40. Bxc5 1-0 "

; sample game 668
EventSites(668) = "Qatar Masters op  Doha" : GameDates(668) = "20141204" : WhitePlayers(668) = "Yu, Yangyi   G#668" : WhiteElos(668) = "2705" : BlackPlayers(668) = "Kramnik, Vladimir   G#668" : BlackElos(668) = "2760" : Each_Game_Result(668) = "1-0"

FilePGNs(668) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. d3 Bc5 5. Bxc6  dxc6 6. Nbd2 Be6 7. O-O Nd7 8. Nb3 Bb6  9. Ng5 Bxb3 10. axb3 f6 11. Nf3 Nf8 12. Nd2 Ne6 13. Qh5+ g6 14. Qd1 Bc5 15. Nc4 b5  16. Na5 Qd7 17. Be3 Bb6 18. b4 O-O 19. Qd2 f5  20. exf5 gxf5 21. Qc3  f4 22. Bxb6 cxb6 23. Nxc6  Qd6 24. Rxa7 Rxa7 25. Nxa7 f3 26. Qc6 Qe7 27. Nxb5 Kh8  28. g3 Qf7 29. Ra1 Ng5 30. Ra8 Qe7 31. h4 Nh3+ 32. Kf1 e4 33. Qxe4 1-0 "

; sample game 669
EventSites(669) = "London Classic 6th  London" : GameDates(669) = "20141211" : WhitePlayers(669) = "Kramnik, Vladimir   G#669" : WhiteElos(669) = "2769" : BlackPlayers(669) = "Nakamura, Hikaru   G#669" : BlackElos(669) = "2775" : Each_Game_Result(669) = "1-0"

FilePGNs(669) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Be2 O-O 6. Nf3 e5 7. d5 a5 8. Bg5 h6 9. Be3 Ng4 10. Bd2 f5 11. h3 Nf6 12. exf5 gxf5 13. Qc1  f4 14. g3 e4 15. Nh4 e3 16. fxe3 fxg3 17. Ng6 Rf7 18. Qc2 Nfd7  19. O-O-O Ne5 20. Rhf1 Rxf1 21. Rxf1 Bxh3 22. Rg1 Qf6 23. Rxg3 Nxg6 24. Rxg6 Qf7 25. Rg3 Bf5 26. e4 Bg6 27. Bg4 Qf1+ 28. Nd1 Be5 29. Bh3  Qf6 30. Rg1 Kh7 31. Bf5  Bxf5 32. exf5 Nd7 33. Rg6 Qf7 34. Rxh6+ Kg8 35. Rg6+ Kf8 36. Nf2 b5 37. Ng4 bxc4 38. Qxc4 Qxf5 39. Rg8+ Ke7 40. Bg5+ Bf6 41. Qe2+ 1-0 "

; sample game 670
EventSites(670) = "Hampstead op  London" : GameDates(670) = "20141217" : WhitePlayers(670) = "Fier, Alexandr   G#670" : WhiteElos(670) = "2592" : BlackPlayers(670) = "Bai, Jinshi   G#670" : BlackElos(670) = "2444" : Each_Game_Result(670) = "1-0"

FilePGNs(670) = "1. d4 Nf6 2. c4 c6 3. Nc3 d5 4. e3 Bf5 5. cxd5 cxd5 6. Qb3 Bc8  7. Nf3 Nc6 8. Ne5 e6 9. f4 Be7 10. Bd3 O-O 11. O-O Nd7 12. Bd2 Ndxe5 13. fxe5 f5 14. exf6 Bxf6 15. Rf3 Qe7 16. Raf1 Bd7 17. Be1 b6 18. Bg3 Nb4 19. Bb1 Bg5  20. h4  Bh6 21. a3 Rxf3 22. Rxf3 Nc6 23. h5 Rf8 24. Qc2 Rxf3  25. Qxh7+ Kf7 26. Bg6+ Kf6 27. gxf3 Bxe3+ 28. Kg2 Qf8 29. f4 Ke7 30. Bh4+ 1-0 "

; sample game 671
EventSites(671) = "Rilton Cup 44th  Stockholm" : GameDates(671) = "20150101" : WhitePlayers(671) = "Roiz, Michael   G#671" : WhiteElos(671) = "2592" : BlackPlayers(671) = "Ivanov, Sergey   G#671" : BlackElos(671) = "2559" : Each_Game_Result(671) = "1-0"

FilePGNs(671) = "1. Nf3 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 O-O 5. a3 Bxc3 6. Qxc3 b6 7. e3 Bb7 8. Be2 c5 9. b4 d6 10. Bb2 Nbd7 11. O-O Rc8 12. d4 Qe7 13. Rfd1 Ne4 14. Qe1  Ndf6  15. dxc5 bxc5 16. h3 Rfd8 17. b5 d5 18. a4  dxc4  19. Bxc4 Nd5  20. Ne5 f6 21. Nf3 Nd6 22. Be2 Nb4 23. Rac1 Be4 24. a5 Bc2 25. Rd2 Bb3   26. Ba3 Ne4 27. Rxd8+ Qxd8 28. Bxb4 cxb4 29. Rxc8 Qxc8 30. Qxb4 Qc1+ 31. Qe1  Qb2 32. Nd4 Bd5 33. Bf3  e5 34. Nc6 Qxb5 35. Ne7+ Kf7 36. Nxd5 Qxd5 37. Qb4 f5 38. a6 Kf6 39. Qb7 Qc5 40. Bxe4 fxe4 41. Qxe4 g6 42. g4 h5 43. gxh5 gxh5 44. Qh7 Kg5 45. h4+  Kf6 46. Qxh5 Qc1+ 47. Kg2 Qc4 48. e4 Qd4 49. Qg4 Ke7 50. h5 Qd2 51. Qg6 1-0 "

; sample game 672
EventSites(672) = "Tata Steel-A 77th  Wijk aan Zee" : GameDates(672) = "20150112" : WhitePlayers(672) = "So, Wesley   G#672" : WhiteElos(672) = "2762" : BlackPlayers(672) = "Aronian, Levon   G#672" : BlackElos(672) = "2797" : Each_Game_Result(672) = "1-0"

FilePGNs(672) = "1. e4 e5  2. Nf3 Nc6  3. d4 exd4 4. Nxd4 Nf6 5. Nxc6 bxc6 6. e5 Qe7 7. Qe2 Nd5 8. Nd2 Rb8 9. c4 Nf4 10. Qe3 Ng6 11. f4 f6 12. Qxa7 Rb7 13. Qf2 fxe5 14. f5 Nf4 15. Qf3  Qf7 16. g3 Nh5 17. Be2 Nf6 18. g4  d5 19. g5 e4 20. Qh3 Ng8  21. Bh5 g6 22. fxg6 Bxh3 23. gxf7+ Kd7 24. fxg8=Q Rxg8 25. Rg1 Bd6 26. cxd5  cxd5 27. Bf7 Rf8 28. Bxd5 Rb4 29. g6 hxg6 30. Rxg6 Rd4 31. Bxe4 Re8 32. Kf2 Rf8+ 33. Ke1 Re8 34. Kf2 Rf8+ 35. Ke3 c5 36. Rg7+ Kd8 37. Ke2 Bc8 38. Bf3 Ba6+ 39. Kf2 Rh4 40. Nf1 Kc8 41. Be3 Rh3 42. Nd2 Rxh2+ 43. Kg1 Rxd2 44. Bg4+ Kb8 45. Bxd2 Be5 46. Re7 Bd4+ 47. Be3 Rg8 48. Bxd4 Rxg4+ 49. Kf2 Rxd4 50. Rh1 Bb7 51. Rh8+ Ka7 52. Ke3 Rb4 53. b3 c4 54. Rh4 1-0 "

; sample game 673
EventSites(673) = "Tata Steel-A 77th  Wijk aan Zee" : GameDates(673) = "20150113" : WhitePlayers(673) = "Radjabov, Teimour   G#673" : WhiteElos(673) = "2734" : BlackPlayers(673) = "Ding, Liren   G#673" : BlackElos(673) = "2732" : Each_Game_Result(673) = "0-1"

FilePGNs(673) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. h3 e5 7. d5 Nh5 8. g3 f5 9. exf5 gxf5 10. Ng5 Qe8 11. Be2 Nf6 12. Be3 Na6 13. Qd2 Bd7 14. O-O-O h6 15. Nf3 Nc5 16. Nh4 Nce4 17. Nxe4 Nxe4 18. Qc2 Ng5 19. Bd3 e4 20. Be2 Rc8 21. Kb1 c5 22. dxc6 Rxc6 23. Qd2 Be6 24. Bxg5 hxg5 25. Qxg5 Ra6 26. Rd2 b5 27. Rc1 Qf7 28. Ng6 Bf6 29. Qh6 Rb8 30. Nf4 Bxc4 31. Rxc4 bxc4 32. Nd5 Bg7 33. Qg5 c3 34. Bc4 cxd2 35. Nf6+ Kf8 36. Nh7+ Ke8 37. Bxf7+ Kxf7 38. Qxf5+ Kg8 39. Kc2 Rxb2+ 40. Kd1 Rb1+ 0-1 "

; sample game 674
EventSites(674) = "Tata Steel-A 77th  Wijk aan Zee" : GameDates(674) = "20150125" : WhitePlayers(674) = "Caruana, Fabiano   G#674" : WhiteElos(674) = "2820" : BlackPlayers(674) = "Vachier Lagrave, Maxime   G#674" : BlackElos(674) = "2757" : Each_Game_Result(674) = "0-1"

FilePGNs(674) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. h3 e5 7. Nde2 h5 8. g3 Be6 9. Bg2 Nbd7 10. a4 Be7 11. O-O Rc8 12. Be3 Nb6 13. b3 d5  14. Bxb6 Qxb6 15. Nxd5 Nxd5 16. exd5 Bd7  17. c4 Qd6  18. a5  f5 19. Qd3 h4 20. g4 O-O  21. Nc3  e4 22. Qe3 Bd8  23. Bxe4 fxe4 24. Nxe4 Qf4 25. Qxf4 Rxf4 26. f3 Be7 27. Kf2 Rcf8 28. Ke3 Be8  29. c5 Bb5 30. b4  Rxe4+  31. Kxe4 Re8 32. Kf4 g5+ 33. Kf5 Kf7  34. Rfe1 Bd3+ 35. Re4 Bf6 0-1 "

; sample game 675
EventSites(675) = "Tata Steel-B 77th  Wijk aan Zee" : GameDates(675) = "20150125" : WhitePlayers(675) = "Klein, David   G#675" : WhiteElos(675) = "2517" : BlackPlayers(675) = "Navara, David   G#675" : BlackElos(675) = "2729" : Each_Game_Result(675) = "0-1"

FilePGNs(675) = "1. e4 c6 2. d4 d5 3. Nd2 dxe4 4. Nxe4 Bf5 5. Ng3 Bg6 6. h4 h6 7. Nf3 e6 8. Ne5 Bh7 9. Bd3 Bxd3 10. Qxd3 Nd7 11. f4 Bb4+ 12. c3 Bd6 13. Ne4 Ndf6 14. Nxd6+ Qxd6 15. Bd2 Ne7 16. h5 Qd5 17. c4 Qxg2 18. O-O-O O-O 19. Bb4 Nf5  20. Bxf8 Rxf8 21. Qf3  Qxf3 22. Nxf3 Ne3   23. Rde1  Nxc4 24. f5 exf5 25. Nh4 Nd6 26. Rhf1 f4  27. Re5 Nc4 28. Rc5 Nd5  29. Rxc4 Ne3 30. Rxf4 Nxc4 31. Nf5 Rd8 32. Ne7+ Kh7 33. Rxf7 Rd7 0-1 "

; sample game 676
EventSites(676) = "Gibraltar Masters 13th  Caleta" : GameDates(676) = "20150131" : WhitePlayers(676) = "Adhiban, Baskaran   G#676" : WhiteElos(676) = "2630" : BlackPlayers(676) = "Nakamura, Hikaru   G#676" : BlackElos(676) = "2776" : Each_Game_Result(676) = "0-1"

FilePGNs(676) = "1. d4 d5 2. c4 dxc4 3. e4 b5  4. a4 c6 5. Nc3  a6 6. axb5 cxb5 7. Nxb5 axb5 8. Rxa8 Bb7 9. Ra1 e6 10. Ne2  Bxe4 11. b3 Nc6 12. Nc3  Bb4 13. Bd2 Bxc3 14. Bxc3 b4 15. d5  bxc3 16. dxc6 Qxd1+ 17. Kxd1 cxb3 18. c7 Kd7  19. Ra3 b2 20. c8=Q+ Kxc8 21. Rxc3+ Kd7 22. Bd3 b1=Q+ 23. Bxb1 Bxb1 24. Rb3  Be4 25. Rb8 g5  26. Ke2 Ke7 27. h4  gxh4 28. Rxh4 Bc6  29. Rc4 Be8 30. Rc7+ Kd6 31. Ra7 Ne7  32. Rd8+ Ke5 33. Rb7 Kf6 34. Rdb8 Ng6 35. Rb6 h5 36. f3 Ba4  37. Rxh8 Nxh8 38. Ke3 Ng6 39. Ra6 Bb3 40. Ra5 Bd5 41. Ra7 e5 42. Ra5 Be6 43. Rb5 h4 44. Rb1 Kg5 45. Rb5 f6 46. Rb7 Nf4 47. Kf2 Nh5 48. Rb6 Bf5 49. Rb8 Bg6 50. Rb4 Nf4 51. Ra4 Bf7 52. Ra7 Kg6 53. Ra1 Bd5 54. Rd1 Kg5 55. Rd2 f5 0-1 "

; sample game 677
EventSites(677) = "Gibraltar Masters 13th  Caleta" : GameDates(677) = "20150204" : WhitePlayers(677) = "Hou, Yifan   G#677" : WhiteElos(677) = "2673" : BlackPlayers(677) = "Rapport, Richard   G#677" : BlackElos(677) = "2716" : Each_Game_Result(677) = "1-0"

FilePGNs(677) = "1. e4 g6 2. Nc3 Bg7 3. d4 a6 4. f4  d5  5. e5 h5 6. Nf3 Bg4 7. h3 Bxf3 8. Qxf3 e6 9. g3  Ne7 10. Be3 Nbc6 11. g4 Qd7 12. O-O-O O-O-O 13. Bd3 hxg4 14. hxg4 f6 15. exf6 Bxf6 16. Qf2 Qd6 17. a3 Kb8 18. Kb1 Rdf8 19. Ne2 Na5 20. Bd2 Nac6 21. Bc1  Bg7 22. Qe3 Na5 23. Rhe1 Nac6  24. Rh1 Na5 25. Bd2  Nc4  26. Bxc4 dxc4 27. Rxh8 Rxh8 28. Re1 Qc6 29. Bc1 Rh4 30. f5  Rxg4 31. fxe6 Re4  32. Qf3  Rxe6 33. Qf7 Nd5  34. Qxg7  Ka7 35. Qf8  c3 36. Qc5+ Qxc5 37. dxc5 c6 38. Bg5  Re5 39. Bh4 cxb2 40. Kxb2 Re4 1-0 "

; sample game 678
EventSites(678) = "Gibraltar Masters 13th  Caleta" : GameDates(678) = "20150204" : WhitePlayers(678) = "Vitiugov, Nikita   G#678" : WhiteElos(678) = "2735" : BlackPlayers(678) = "Mareco, Sandro   G#678" : BlackElos(678) = "2583" : Each_Game_Result(678) = "1-0"

FilePGNs(678) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Nf3 c5 5. g3 Nc6 6. Bg2 Ne4 7. Bd2 Nxd2 8. Qxd2 cxd4 9. Nxd4 Ne5 10. Nf3  Qc7 11. Nxe5 Qxe5 12. Rc1 Rb8 13. O-O a6  14. a3 Be7 15. Rfd1 f5 16. b4 O-O 17. c5  b6 18. Na4 bxc5 19. Nxc5 d5 20. e3 Qd6 21. Rc2 Rd8 22. h4 Qb6 23. Rdc1 Qa7  24. Nb3 Bd7 25. Na5 Rbc8 26. Nc6 Bxc6 27. Rxc6 Rxc6 28. Rxc6 Kf7 29. Qe2  Rd6 30. Qh5+ Kf8 31. Rc8+ Rd8 32. Qxh7 Rxc8 33. Qh8+ Kf7 34. Qxc8 a5 35. Bxd5 exd5 36. Qxf5+ Ke8 37. Qc8+ Kf7 38. Qf5+ Ke8 39. Qxd5 axb4  40. axb4 Qb6 41. b5 Bc5 42. Qg8+ Bf8 43. Qc4 Bc5 44. Kg2 Qb7+  45. e4 Qb6 46. f3 Ke7 47. e5 Bd4 48. f4 Qb7+ 49. Qc6   Qa7 50. Qd6+ Ke8 51. Qa6 Qd7 52. Qc6 Qxc6+ 53. bxc6 Kd8 54. h5 Kc7 55. g4 Bc5 56. g5 Kxc6 57. h6 gxh6 58. g6 Bf8 59. f5 Kd5 60. f6 Ke6 61. Kh3 1-0 "

; sample game 679
EventSites(679) = "EU-ch 16th  Jerusalem" : GameDates(679) = "20150225" : WhitePlayers(679) = "Timofeev, Artyom   G#679" : WhiteElos(679) = "2564" : BlackPlayers(679) = "Laznicka, Viktor   G#679" : BlackElos(679) = "2670" : Each_Game_Result(679) = "0-1"

FilePGNs(679) = "1. e4 c5 2. Nf3 e6 3. d4 cxd4 4. Nxd4 Nc6 5. Nc3 Qc7 6. g3 a6 7. Bg2 Nge7 8. Nb3 d6 9. O-O g6 10. Be3 Bg7 11. Na4 b5 12. Nb6 Rb8 13. Nxc8 Nxc8 14. c3 Nb6 15. Qe2 Nc4 16. Bf4 O-O 17. Rad1 Rfd8 18. h4 Qa7 19. h5 a5  20. a3  N6e5  21. Nd4 Rdc8 22. Nf3 Nxf3+ 23. Bxf3 Qc5 24. Kg2 Be5 25. Bh6 b4 26. axb4 axb4 27. b3 Na5 28. Be3 Qc6  29. cxb4  Nxb3 30. Qe1 Qc4 31. Rh1 Qxb4 32. Qg1 Rc2 33. hxg6 hxg6  34. Qh2 Qc3 35. Qh7+ Kf8 36. Bh6+ Ke7 37. Bg5+ Bf6 38. Qh4 Nd2 39. Bxf6+ Qxf6 40. Qxf6+ Kxf6 41. Rc1 Rbb2 42. Rxc2 Rxc2 43. Bd1 Rc1 44. f3 Ke5 45. Kf2 Kd4 46. Re1 g5 47. Ke2 Nb1 0-1 "

; sample game 680
EventSites(680) = "EU-ch 16th  Jerusalem" : GameDates(680) = "20150302" : WhitePlayers(680) = "Kovalev, Vladislav   G#680" : WhiteElos(680) = "2531" : BlackPlayers(680) = "Laznicka, Viktor   G#680" : BlackElos(680) = "2670" : Each_Game_Result(680) = "0-1"

FilePGNs(680) = "1. e4 d5 2. exd5 Qxd5 3. Nc3 Qd8 4. d4 Nf6 5. Nf3 Bg4 6. h3 Bxf3 7. Qxf3 c6 8. Be3 e6 9. Bd3 Be7 10. O-O O-O 11. Ne4 Nd5 12. c4 Nxe3 13. fxe3 Nd7 14. c5 Nf6  15. Nxf6+ Bxf6 16. b4 Bg5 17. Bc4 Qe7 18. Rab1 Rad8 19. Kh1 g6  20. b5 Qc7 21. Rb3 Be7  22. a4  Rc8  23. a5  Qxa5 24. bxc6 bxc6 25. Rfb1 Rc7  26. Qf1 Rd7 27. Ra1  Qc7 28. Ba6  Rb8  29. Rxb8+ Qxb8 30. Rb1  Qg3 31. Qf3 Qxf3 32. gxf3 e5 33. dxe5 Bxc5 34. e4 Re7 35. f4 g5 36. fxg5 Rxe5 37. Bb7 Rxe4 38. Bxc6 Rh4 39. Rb3 Rh5 40. Rg3 Be7 41. Re3 Kf8 42. Be4 a5 43. Rf3 Rxg5 44. Bxh7 a4 45. Bc2 a3 46. Bb3 f6 47. Rc3 Bd6 48. Rc6 Ke7 49. Ra6 f5 50. Bc2 f4 51. Ra7+ Kd8 52. Be4 Rg3 53. Bf5 Bc5 54. Ra5 f3 55. Rxc5 f2 56. Bd3 Rxd3 57. Kg2 Rd1 0-1 "

; sample game 681
EventSites(681) = "EU-ch 16th  Jerusalem" : GameDates(681) = "20150304" : WhitePlayers(681) = "Navara, David   G#681" : WhiteElos(681) = "2735" : BlackPlayers(681) = "Kempinski, Robert   G#681" : BlackElos(681) = "2625" : Each_Game_Result(681) = "1-0"

FilePGNs(681) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be2 e6 7. O-O Be7 8. f4 O-O 9. Kh1 Qc7 10. Qe1 Nc6 11. Be3 Na5 12. Qg3 Nc4 13. Bxc4 Qxc4 14. Rad1 Qc7 15. f5 Kh8 16. Bg5 Nh5 17. Qh4 Bxg5 18. Qxg5 Nf6 19. Rd3 h6 20. Rh3 Nh7 21. Qd2 Qe7 22. Rhf3  Nf6 23. g4 exf5 24. exf5 b5  25. g5 Nh7  26. f6  gxf6 27. gxf6 Qe5 28. Nc6 Qc5  29. Qxh6 Rg8 30. Nd8  Qc7  31. Rg1 Bg4 32. Rh3  1-0 "

; sample game 682
EventSites(682) = "USA-ch  Saint Louis" : GameDates(682) = "20150403" : WhitePlayers(682) = "Kamsky, Gata   G#682" : WhiteElos(682) = "2683" : BlackPlayers(682) = "Nakamura, Hikaru   G#682" : BlackElos(682) = "2798" : Each_Game_Result(682) = "1/2-1/2"

FilePGNs(682) = "1. d4 Nf6 2. Nf3 e6 3. Bf4 c5 4. e3 Nc6 5. c3 d5 6. Nbd2 Bd6 7. Bg3 O-O 8. Bd3 b6 9. e4  Be7 10. e5 Nh5 11. O-O Bd7 12. Re1 Rc8 13. a3 Nxg3 14. hxg3 f5 15. dxc5  bxc5 16. b4 g5 17. Nh2 d4 18. b5 dxc3 19. bxc6 cxd2 20. Re2 Bxc6 21. Rxd2 Bd5 22. g4  c4 23. Bc2 f4 24. Qe2 Qa5 25. Nf3 Rcd8 26. Rdd1 Rd7 27. a4 Rfd8 28. Rab1 a6 29. Rdc1 Ba3 30. Rd1 h6 31. Kh2 Bf8 32. Rdc1 Qc5 33. Kg1 Qc6 34. Rd1 Bg7 35. Nd4 Qc7 36. Nf3 Rb8 37. Rxb8+ Qxb8 38. Be4  Qc8 39. Bc2  Qc6 40. Nd4 Qc7 41. Nf3 Rd8 42. Bb1 Rb8 43. Bc2 a5 44. Rc1 Qb7 45. Qd1 Qa8 46. Qe2 Rb4 47. Rd1 Qc6 48. Nd4 Qc7 49. Re1 Qb7 50. Rd1 Bf8 51. Nb5 Bxg2 52. Rd8 Bh1 53. Qf1 Rb2 54. Nd6 Qd5 55. Nf7 Rxc2  56. Rxd5 Bxd5 57. Qb1  Kxf7 58. Qxc2 Kg7 59. Qd2 Bb4 60. Qd4 c3 1/2-1/2 "

; sample game 683
EventSites(683) = "Wch World Cup (Women)  Sochi" : GameDates(683) = "20150403" : WhitePlayers(683) = "Muzychuk, Mariya   G#683" : WhiteElos(683) = "2526" : BlackPlayers(683) = "Pogonina, Natalija   G#683" : BlackElos(683) = "2456" : Each_Game_Result(683) = "1-0"

FilePGNs(683) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O b5 6. Bb3 Be7 7. Re1 d6 8. c3 O-O 9. h3 Nb8  10. d4 Nbd7 11. a4 Bb7 12. Nbd2 c5 13. d5 c4 14. Bc2 Nc5 15. Nf1 Re8 16. Ng3 g6 17. Be3 Qc7 18. Nd2 Bf8 19. Qe2 Nfd7 20. f3  Nb6 21. a5 Nbd7 22. Nh1 Be7  23. g4  Qd8 24. Qf2 Bh4 25. Ng3 Rc8 26. Kg2 Nf8  27. Rf1 Bg5 28. f4  exf4 29. Bxf4 Rc7  30. Bxg5 Qxg5 31. Nf3 Qe7 32. Nd4  Qe5  33. h4  h6 34. Qd2 Bc8 35. Nc6  Qg7 36. Qf4 Rd7  37. Rf2 Bb7 38. Nd4 Re5 39. Nf3 Re8 40. g5  h5 41. Nd4 Qe5 42. Qd2 Rc7 43. Raf1 Ree7  44. Rf6  Red7 45. R6f4  b4  46. Nf3 Qg7 47. cxb4 Nd3 48. Rf6 Nh7 49. Nd4 Nxf6 50. gxf6 Qf8 51. Ba4  Ne5  52. Bxd7 Rxd7 53. Nf3 Ng4 54. Nxh5  gxh5 55. Qg5+ Kh8 56. Qxh5+ Nh6 57. Kh2 Qg8 58. Rg1 1-0 "

; sample game 684
EventSites(684) = "Gashimov Memorial  Shamkir" : GameDates(684) = "20150417" : WhitePlayers(684) = "So, Wesley   G#684" : WhiteElos(684) = "2788" : BlackPlayers(684) = "Giri, Anish   G#684" : BlackElos(684) = "2790" : Each_Game_Result(684) = "1-0"

FilePGNs(684) = "1. c4 g6 2. e4 e5 3. d4 Nf6 4. dxe5 Nxe4 5. Bd3 Bb4+  6. Kf1  Nc5 7. Nf3 Ne6 8. a3  Be7 9. Nc3 d6 10. exd6 Bxd6 11. b4 Bf8 12. Qe2 Bg7 13. Bg5 Bf6 14. Bxf6 Qxf6 15. Qd2 O-O 16. Re1 Qd8 17. Rd1 a5 18. h4 axb4 19. axb4 Nd7 20. h5 Nf6 21. c5 b6 22. hxg6 fxg6 23. Qe3 Qe7 24. Bc4 bxc5 25. b5 Rb8 26. Re1 Rb6 27. Na4 Rd6 28. Nxc5 Ng4 29. Qe4 Nxf2 30. Kxf2 Rd2+ 31. Kg3 Rxf3+ 32. gxf3 Qg5+ 33. Qg4 Qxc5 34. Bxe6+ Kg7 35. Bxc8 h5 36. Qf4 Qf2+ 37. Kh3 Qg2+ 38. Kh4 Qf2+ 39. Qg3 1-0 "

; sample game 685
EventSites(685) = "Gashimov Memorial  Shamkir" : GameDates(685) = "20150421" : WhitePlayers(685) = "Carlsen, Magnus   G#685" : WhiteElos(685) = "2863" : BlackPlayers(685) = "Vachier Lagrave, Maxime   G#685" : BlackElos(685) = "2765" : Each_Game_Result(685) = "1-0"

FilePGNs(685) = "1. Nf3 Nf6 2. g3 b5 3. Bg2 Bb7 4. Na3 a6 5. c4 b4 6. Nc2 e6 7. d4 a5 8. O-O Be7 9. d5  Na6 10. Nfd4 Nc5 11. Re1 O-O 12. e4 e5 13. Nf5  d6 14. Bg5  Nxd5  15. Bh6  gxh6 16. Qg4+ Bg5 17. cxd5 Kh8 18. h4 Bf6 19. Nce3 Bc8 20. Qf3 Bg7 21. Bh3 Rg8 22. Bg4 Qf6 23. Bh5 Bxf5 24. Nxf5 c6 25. dxc6 Rac8 26. Qd1  Rxc6 27. Qd5 Rgc8 28. Rad1 Bf8 29. Qxf7 Qxf7 30. Bxf7 Na4 31. Re2 Rc1 32. Rxc1 Rxc1+ 33. Kg2 Nc5 34. b3 Rc3 35. Kh3 Nd7 36. Be6 Nc5 37. Bd5 Nd7 38. Ne3 Nf6 39. Be6 Rc5 40. Nc4 Kg7 41. f3 Ne8 42. Rd2 Nc7 43. Bg4 a4 44. Nxd6 Bxd6 45. Rxd6 a3 46. Bd7  Rc2 47. Bc6 Rxa2 48. Rd7+ Kf6 49. Rxc7 Rc2 50. Rxh7 Kg6 51. Rc7 Kf6 52. h5 Rc1 53. Rh7 a2 54. Bd5 1-0 "

; sample game 686
EventSites(686) = "Capablanca Memorial Elite 50th  Havana" : GameDates(686) = "20150623" : WhitePlayers(686) = "Yu, Yangyi   G#686" : WhiteElos(686) = "2715" : BlackPlayers(686) = "Dominguez Perez, Leinier   G#686" : BlackElos(686) = "2746" : Each_Game_Result(686) = "1-0"

FilePGNs(686) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be3 Ng4 7. Bc1 Nf6 8. Be3 Ng4 9. Bc1 Nc6 10. h3 Nf6 11. g4 Qb6 12. Nb3 e6 13. g5 Nd7 14. Bf4   Qc7 15. Qd2 b5 16. O-O-O Nce5 17. Bg3 Rb8 18. f4 Nc4 19. Bxc4 bxc4 20. Nd4 Nc5 21. Rhe1  Qb6 22. b3 cxb3 23. axb3 Bb7 24. f5 Rc8 25. Kb1 Be7 26. f6  gxf6 27. gxf6 Bf8 28. Qe3   Nd7 29. Nd5  Qc5 30. Nxe6  Qxe3 31. Ng7+ Bxg7 32. fxg7 Qxb3+ 33. cxb3 Rg8 34. Ne3 Bxe4+ 35. Ka1  Kd8 36. Nc4  d5 37. Nd6 Rxg7 38. Rxd5 Rxg3 39. Nxe4 Rg6  40. Red1 Rc7 41. Nc5  Rxc5 42. Rxc5 Rb6 43. Kb2 Rb7 44. Rc6 Ke7 45. Ka3 f5 46. Rd4 Ne5 47. Rxa6 Ng6 48. h4 Nf8 49. Rd5 1-0 "

; sample game 687
EventSites(687) = "Norway Chess 3rd  Stavanger" : GameDates(687) = "20150625" : WhitePlayers(687) = "Aronian, Levon   G#687" : WhiteElos(687) = "2780" : BlackPlayers(687) = "Nakamura, Hikaru   G#687" : BlackElos(687) = "2802" : Each_Game_Result(687) = "0-1"

FilePGNs(687) = "1. c4 e5  2. Nc3 Nc6 3. g3 Bc5  4. Bg2 d6 5. e3 a6 6. Nge2 Ba7 7. a3 h5  8. d4 h4 9. b4 Nge7 10. c5  Bf5  11. Bb2 Qd7 12. Qb3 h3 13. Bf3 exd4 14. Nxd4 Bg4 15. Bxg4 Qxg4 16. Nxc6 Nxc6 17. Qd1 Qg6 18. cxd6 O-O-O 19. Rc1  Rxd6 20. Qc2 Qh5 21. Qe2 Ne5 22. Qxh5 Nd3+ 23. Ke2  Nxc1+ 24. Rxc1 Rxh5 25. g4 Re5  26. Rg1 Re8 27. Rg3 Bd4 28. Na4 Bxb2 29. Nxb2 Red8 30. Nc4 Rc6 31. Ne5 Rc2+ 32. Ke1 f6 33. Nf3 Rh8 34. g5 Ra2 35. Nd4 Rxa3 36. Ne6 Ra1+ 37. Ke2 Rh1 38. gxf6 gxf6 39. Nf4 b6 40. Nxh3 Rb1 0-1 "

; sample game 688
EventSites(688) = "Biel GM 48th  Biel" : GameDates(688) = "20150723" : WhitePlayers(688) = "Navara, David   G#688" : WhiteElos(688) = "2724" : BlackPlayers(688) = "Wojtaszek, Radoslaw   G#688" : BlackElos(688) = "2733" : Each_Game_Result(688) = "1-0"

FilePGNs(688) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be3 e5 7. Nb3 Be6 8. h3 Be7 9. g4  d5 10. exd5 Nxd5 11. Bg2 Nxe3  12. Qxd8+ Bxd8 13. fxe3 Bh4+ 14. Kf1 Nc6 15. Nc5 Bc4+   16. Kg1 O-O-O 17. b3 Bg5 18. Re1 Bh4 19. Rb1  Bg5 20. Kf2 Bh4+ 21. Kf3  e4+  22. Kf4  g5+ 23. Kf5 Rhe8 24. Rhd1  Re5+  25. Kf6 Rg8  26. bxc4 Rg6+ 27. Kxf7 Re7+ 28. Kf8 Rf6+  29. Kg8 Rg6+ 30. Kh8  Rf6  31. Rf1 Bf2 32. Rxf2  Rxf2 33. Rf1 Rxg2 34. Rf8+ Kc7 35. Nd5+  Kd6 36. Nxe7 Kxc5 37. Rf5+ Kxc4 38. Nxc6 bxc6 39. Rxg5 Rg3 40. h4 h6   41. Rg6  Rxe3 42. Kg7 Rg3 43. Kxh6 e3 44. Kg5  Kd5  45. Kf4  Rh3  46. h5 c5 47. Rg5+ Kd4 48. Re5 1-0 "

; sample game 689
EventSites(689) = "Biel GM 48th  Biel" : GameDates(689) = "20150727" : WhitePlayers(689) = "Wojtaszek, Radoslaw   G#689" : WhiteElos(689) = "2733" : BlackPlayers(689) = "Vachier Lagrave, Maxime   G#689" : BlackElos(689) = "2731" : Each_Game_Result(689) = "1-0"

FilePGNs(689) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. Bf4 Bg7 5. e3 O-O 6. Rc1 Be6 7. c5 c6 8. Bd3 Bg4 9. Nge2 Re8 10. f3 Bc8 11. O-O Nbd7 12. Bg5 e5 13. b4 Nf8 14. Bh4 Bh6  15. f4  e4  16. Bc2 Bg7 17. b5 Bd7 18. Ba4 Qc8 19. h3  Nh5 20. Rb1 f5 21. Qb3 Bf6 22. Bxf6 Nxf6 23. bxc6 bxc6 24. Qb7 Ne6 25. Nc1  Rb8  26. Qxc8 Rexc8 27. Nb3 Nc7  28. Na5 Nb5 29. Ne2  Na3 30. Rxb8 Rxb8 31. Bxc6 Bxc6 32. Nxc6 Rb2 33. Nc3 Rc2 34. Ne7+ Kf7 35. Ncxd5 Nc4  36. Rb1  Nh5 37. Nc6 Nd2 38. Ncb4 Nxb1 39. Nxc2 Ke6 40. Nc7+ Kd7 41. Nd5 Ke6 42. Ndb4 Nf6 43. d5+  Kd7 44. d6 Nc3 45. Nd4 Nfd5 46. Na6 1-0 "

; sample game 690
EventSites(690) = "Biel MTO op 48th  Biel" : GameDates(690) = "20150728" : WhitePlayers(690) = "Sutovsky, Emil   G#690" : WhiteElos(690) = "2619" : BlackPlayers(690) = "Bartel, Mateusz   G#690" : BlackElos(690) = "2631" : Each_Game_Result(690) = "1-0"

FilePGNs(690) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Bc5 6. c3 O-O 7. d4 Ba7 8. Bg5 h6 9. Bh4 exd4 10. cxd4 d6 11. Bxc6 bxc6 12. Nbd2 g5 13. Nxg5 hxg5 14. Bxg5 Bxd4 15. Nf3 Bxb2 16. Rb1 Qd7  17. Rxb2 Nxe4 18. Bh6 Re8 19. Nd4  c5 20. f3  Nf6 21. Ne2 Qf5 22. g4 Qg6  23. Bc1  Bd7 24. Nf4 Qh7 25. Rg2  Bb5 26. g5 Bxf1 27. Kxf1  Nd7 28. g6 fxg6 29. Qd5+ Kg7 30. Qf5  Ne5 31. Bb2 Kh6 32. Qg5+ Kg7 33. Nxg6 Qh6 34. Qf5 1-0 "

; sample game 691
EventSites(691) = "Asian Continental op 14th  Al Ain" : GameDates(691) = "20150807" : WhitePlayers(691) = "Le, Quang Liem   G#691" : WhiteElos(691) = "2699" : BlackPlayers(691) = "Gupta, Abhijeet   G#691" : BlackElos(691) = "2619" : Each_Game_Result(691) = "1/2-1/2"

FilePGNs(691) = "1. Nf3 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. h4 Bg7 6. e4 Nxc3 7. dxc3 Qxd1+ 8. Kxd1 Bg4  9. Kc2 Nd7 10. Be3 Nf6 11. Nd2 Be6 12. f3 Nh5 13. Bb5+  c6 14. Bc4 Bxc4 15. Nxc4 f5 16. exf5 Ng3 17. Rhe1 Nxf5 18. Rad1 Bf6 19. Bg5 Bxg5 20. hxg5 Rd8 21. g4  Rxd1 22. Kxd1 Ng7 23. Re4 Rf8 24. f4 Kd8 25. Ke2 Ne8 26. Rd4+ Kc8 27. Ne5 Nc7 28. Re4 Ne6 29. Ke3 Nc5 30. Rc4 Ne6 31. a4 Rd8  32. a5 Rd1 33. a6  Re1+ 34. Kf2 Rb1 35. b4 c5 36. axb7+ Kxb7 37. bxc5 a5 38. Nf3 Kc6 39. Re4 Nxc5 40. Rxe7 Rb7 41. Ne5+ Kd5 42. Rxb7 Nxb7  43. Ke3 a4 44. c4+ Kc5 45. Kd3 Nd6 46. Kc3 Ne4+ 47. Kb2 Kb4 48. f5 gxf5 49. gxf5 Nxg5 50. f6 h5 51. f7 Nxf7 52. Nxf7 h4 53. Ng5 Kxc4 54. Ka3 Kd3 55. Kxa4 Ke3 56. Kb3 Kf4 57. Nh3+ Kg4 58. Ng1 h3 59. Nxh3 1/2-1/2 "

; sample game 692
EventSites(692) = "Kavala op 24th  Kavala" : GameDates(692) = "20150808" : WhitePlayers(692) = "Postny, Evgeny   G#692" : WhiteElos(692) = "2648" : BlackPlayers(692) = "Borovikov, Vladislav   G#692" : BlackElos(692) = "2568" : Each_Game_Result(692) = "1-0"

FilePGNs(692) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. g3 dxc4 5. Bg2 g6 6. O-O Bg7 7. a4 O-O 8. Na3 Na6 9. Nxc4 Be6 10. b3 c5 11. Ba3 Rc8 12. Rc1 b6  13. e3   Bd5 14. Qe2 Qc7 15. Nfe5  Bxg2 16. Kxg2 Qb7+ 17. Qf3 Qxf3+  18. Kxf3 Rfe8 19. Rfd1 cxd4 20. Rxd4 h5  21. h3 Nc5 22. Bxc5 Rxc5 23. b4 Rcc8 24. b5  Nh7  25. Rdd1  Ng5+ 26. Kg2 Bxe5 27. Nxe5 Rxc1 28. Rxc1 Ne6 29. Nc6 Nc5 30. Rc4 Kf8 31. a5  Nb7  32. a6 Na5 33. Nxa5 bxa5 34. Ra4 Rb8  35. Rxa5 Ke8 36. Kf3 Kd7 37. Kf4 Kc7  38. Kg5  Rd8 39. Ra2 Kb6 40. Kh6 Rd5 41. Kg7 Rf5 42. f4 Kxb5 43. e4 Rf6 44. Kf8 h4 45. Kxe7 Re6+ 46. Kxf7 Rxe4 47. Kxg6 hxg3 48. f5 Rh4 49. f6 Rxh3 50. f7 Rh2 51. Ra3 Rf2 52. Rxg3 Kxa6 53. Rg5 1-0 "

; sample game 693
EventSites(693) = "Dresden ZMDI op  Dresden" : GameDates(693) = "20150823" : WhitePlayers(693) = "Roiz, Michael   G#693" : WhiteElos(693) = "2595" : BlackPlayers(693) = "Wagner, Dennis   G#693" : BlackElos(693) = "2569" : Each_Game_Result(693) = "1-0"

FilePGNs(693) = "1. d4 Nf6 2. c4 g6 3. g3 c6 4. Bg2 d5 5. Qa4 Nfd7 6. cxd5 Nb6 7. Qd1 cxd5 8. Nc3 Bg7 9. e3 O-O 10. Nge2 Nc6 11. O-O e6  12. b3 a5 13. a4 Bd7 14. Ba3 Re8 15. Qd2 Nc8 16. Nf4 Rb8 17. Nd3  b6  18. Rac1 N8a7 19. Rc2 Bc8  20. Rfc1 Ba6 21. Ne2 Qd7  22. Ne5  Bxe5 23. dxe5 Ra8 24. Bd6 Rec8 25. Nf4 Qe8 26. h4 Ne7 27. e4  dxe4 28. Bxe4 Rxc2 29. Rxc2 Rc8 30. Rc7 Nac6 31. Qe3 Rxc7 32. Bxc7 Nc8 33. Bxb6 Nxe5 34. Bxa5 Qd7 35. Bc3 Ng4 36. Qd2 Qc7 37. Bf3 Ne5 38. Bg2 Na7 39. Qd4 f6 40. Nxe6 1-0 "

; sample game 694
EventSites(694) = "Sinquefield Cup 3rd  Saint Louis" : GameDates(694) = "20150830" : WhitePlayers(694) = "Nakamura, Hikaru   G#694" : WhiteElos(694) = "2814" : BlackPlayers(694) = "Aronian, Levon   G#694" : BlackElos(694) = "2765" : Each_Game_Result(694) = "0-1"

FilePGNs(694) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. a4 b4 9. d4 d6 10. dxe5 dxe5 11. Qxd8 Rxd8 12. Nbd2 h6 13. Bc4 Bd6 14. a5 Re8  15. Bd3 Nd7  16. b3  Nc5 17. Bc4 Be6 18. Bb2 f6 19. Bxe6+ Rxe6  20. Nc4 Rb8  21. Nfd2 Rb5 22. Ra2  Nb7 23. Rea1 Bc5 24. Kf1 Re7  25. Ke2 Rd7 26. Nf1 Bd4 27. Nfe3 Bxe3  28. Nxe3 Kf7 29. f3 Ke6 30. g4  Nc5 31. Nc4 Ke7 32. Bc1 Ne6 33. Be3  Ncd4+ 34. Kf2 Ng5 35. Bxg5 fxg5 36. Rd1  Ke6 37. Rd3 Rf7 38. Ra1  Rb8  39. Rad1  Rbf8 40. Nxe5 Kxe5 41. Rxd4 Rxf3+ 42. Ke2 Rf2+ 43. Ke1 Rf1+ 44. Ke2 R8f2+ 45. Ke3 Rf3+ 46. Ke2 R1f2+ 47. Ke1 Rxh2 48. Rd5+ Kf4 49. R1d4 Kxg4 50. Rc5 Rg3 51. Kf1 Rc3 0-1 "

; sample game 695
EventSites(695) = "FIDE World Cup  Baku" : GameDates(695) = "20150915" : WhitePlayers(695) = "Sethuraman, SP.   G#695" : WhiteElos(695) = "2640" : BlackPlayers(695) = "Harikrishna, Penteala   G#695" : BlackElos(695) = "2737" : Each_Game_Result(695) = "1-0"

FilePGNs(695) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. d4 Nd6 6. Bxc6 dxc6 7. dxe5 Nf5 8. Qxd8+ Kxd8 9. h3 b6 10. Rd1+ Ke8 11. Nc3 h6  12. b3 Bb7 13. Bb2 Rd8 14. Rxd8+  Kxd8 15. Rd1+ Kc8 16. g4 Ne7 17. Kh2 Ng6 18. Kg3 Be7 19. Ne4 c5 20. Re1 h5  21. Nfg5 h4+ 22. Kh2 Rf8 23. f3 Bc6 24. Kg1  Nf4  25. Bc1 Nd5 26. a3  f5 27. exf6 Nxf6 28. Ne6 Rg8 29. N4g5 Bd6 30. Bf4 a5 31. Bxd6 cxd6 32. Nf4 a4 33. Nf7 axb3 34. cxb3 Kd7  35. Rd1 d5 36. g5 Nh7 37. Nxd5 Ke6 38. g6 Nf6 39. Nxf6 gxf6 40. Nd8+ Kf5 41. Nxc6 Rxg6+ 42. Kf2 Rg3 43. Ne7+ Kf4 44. Nd5+ Ke5 45. Rd3 b5 46. Nc3 1-0 "

; sample game 696
EventSites(696) = "FIDE World Cup  Baku" : GameDates(696) = "20150920" : WhitePlayers(696) = "Ding, Liren   G#696" : WhiteElos(696) = "2782" : BlackPlayers(696) = "Wei, Yi   G#696" : BlackElos(696) = "2734" : Each_Game_Result(696) = "1-0"

FilePGNs(696) = "1. Nf3 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. h4 Bg7 6. h5 Nc6 7. g3 Bg4 8. h6 Bxc3 9. dxc3 Qd6 10. Bg2 O-O-O 11. Ng5  Ne5 12. Qa4 Nb6 13. Qd4 f6 14. Bf4  Qxd4 15. cxd4 Nc6 16. Nf7 Nxd4 17. Rc1 e5 18. Rh4  exf4  19. Nxd8  f3  20. exf3 Nxf3+ 21. Bxf3 Re8+  22. Kd2 Bxf3 23. Nf7 Bc6  24. b4  a6 25. a4  Nxa4  26. Re1  Nb6 27. Rg4  Rg8  28. Re7 Nd5 29. Nd6+  cxd6 30. Rxh7 g5 31. Re4 Rg6  32. Re6  g4  33. Rxd6 Nxb4  34. Rh8+ Kc7 35. Rd4  Nd5 36. h7 Rh6 37. Rxg4 Ne7 38. Rg7 Kd7 39. Rf8 1-0 "

; sample game 697
EventSites(697) = "FIDE World Cup  Baku" : GameDates(697) = "20150925" : WhitePlayers(697) = "Eljanov, Pavel   G#697" : WhiteElos(697) = "2717" : BlackPlayers(697) = "Nakamura, Hikaru   G#697" : BlackElos(697) = "2814" : Each_Game_Result(697) = "1-0"

FilePGNs(697) = "1. d4 d5 2. Nf3 Nf6 3. c4 e6 4. g3 Be7 5. Bg2 O-O 6. O-O dxc4 7. Qc2 a6 8. a4 Bd7 9. Qxc4 Bc6 10. Bg5 Bd5 11. Qc2 Be4 12. Qc1  h6 13. Bxf6 Bxf6 14. Rd1 a5 15. Nbd2 Bh7  16. Nb3 c6 17. Qc3 Be7 18. Nc5 Qc7 19. Ne5 Na6 20. Nxb7  Qxb7 21. Bxc6 Qc7  22. Bxa8 Qxc3 23. bxc3 Rxa8 24. Nc6  Bd8 25. Nxd8 Rxd8 26. f3  Rc8 27. Ra3 Bg6 28. Kf2 Rb8 29. Rd2 f6 30. Raa2  Rb3 31. Rab2 Rxc3 32. Rb5 Bc2 33. Rxa5 Nc7 34. Ra7 f5 35. a5 Kh7 36. Rb7 Rc4 37. Rb6 Ba4 38. a6 Bc6 39. a7 Bd5 40. Ra2 Rxd4 41. Rc2 Na8 42. Ra6 Rd1 43. h4  h5 44. Ke3 Rg1 45. Kf4 Rg2 46. Rd6 Rg1 47. Rc8 Ra1 48. Kg5 Rxa7 49. Rdd8 g6 50. Rh8+ Kg7 51. Rcg8+ Kf7 52. Rxg6 Ra6 53. Rh7+ Kf8 54. Kxh5 Nb6 55. Kg5 Nc4 56. h5 Nd6 57. Rf6+ Kg8 58. Rd7 1-0 "

; sample game 698
EventSites(698) = "Poikovsky Karpov 16th  Poikovsky" : GameDates(698) = "20150929" : WhitePlayers(698) = "Sutovsky, Emil   G#698" : WhiteElos(698) = "2635" : BlackPlayers(698) = "Shirov, Alexei   G#698" : BlackElos(698) = "2712" : Each_Game_Result(698) = "1-0"

FilePGNs(698) = "1. e4 c5 2. Nf3 d6 3. Nc3 a6 4. d4 cxd4 5. Nxd4 Nf6 6. h3 e5 7. Nb3 Be6 8. f4 Nbd7 9. f5 Bxb3 10. axb3 d5 11. exd5 Bb4 12. Bd2 O-O 13. Qe2 Bxc3 14. bxc3 e4 15. O-O-O a5 16. Be3 a4 17. b4 Nb6 18. Qb5 Nbxd5 19. Bc4 Nxe3 20. Rxd8 Rfxd8 21. Ba2 a3 22. g4  Ned5  23. g5  Nxc3 24. Bxf7+  Kxf7 25. Qxb7+ Nd7 26. Qc6  a2 27. Kb2  Na4+ 28. Ka1 Kg8 29. f6 Ne5 30. Qxe4 Re8 31. Re1  Nc3 32. Qd4 Rac8 33. h4 g6 34. b5 1-0 "

; sample game 699
EventSites(699) = "EU-Cup 31st  Skopje" : GameDates(699) = "20151019" : WhitePlayers(699) = "Swiercz, Dariusz   G#699" : WhiteElos(699) = "2620" : BlackPlayers(699) = "Howell, David   G#699" : BlackElos(699) = "2705" : Each_Game_Result(699) = "1-0"

FilePGNs(699) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. e4 Nxc3 6. bxc3 Bg7 7. Qa4+ Qd7 8. Bb5 c6 9. Be2 O-O 10. Qa3 b6 11. Nf3 c5 12. O-O Bb7 13. d5  e6 14. Be3 exd5 15. Rad1  Nc6 16. exd5 Ne5 17. c4 Rfe8 18. Rfe1 Nxf3+ 19. Bxf3 Be5 20. Re2 Bd6  21. Rde1 Qf5 22. Bc1  Rxe2 23. Rxe2 b5 24. g4  Qb1  25. cxb5 Qxb5 26. Qc3   Qb4 27. Qf6 Qd4 28. Qxd6 Qd1+ 29. Kg2 Qxc1 30. Re7 Qb2 31. Qc7 Ba6 32. Qc6 1-0 "

; sample game 700
EventSites(700) = "USA tt  ICC INT" : GameDates(700) = "20151020" : WhitePlayers(700) = "So, Wesley   G#700" : WhiteElos(700) = "2767" : BlackPlayers(700) = "Sadorra, Julio Catalino   G#700" : BlackElos(700) = "2501" : Each_Game_Result(700) = "0-1"

FilePGNs(700) = "1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. e5 Nfd7 5. f4 c5 6. Nf3 Nc6 7. Be3 Be7 8. Qd2 O-O 9. dxc5 Bxc5 10. O-O-O Qa5 11. a3 Be7  12. Kb1 Rd8 13. Nd4 Nxd4 14. Bxd4 Nb8  15. Bf2 Nc6 16. Qe1 Rb8 17. Nb5 Qxe1 18. Rxe1 a6 19. Nd4 Nxd4 20. Bxd4 Bd7 21. c3 Bb5 22. Bxb5 axb5 23. Rhf1 Rdc8 24. Rd1 Ra8 25. f5 Bc5 26. Bxc5 Rxc5 27. Rd4 exf5  28. Rxf5 Re8 29. Kc2 g6 30. Rf6 Rxe5 31. Rb6 Re7 32. b4 Rc6 33. Rxb5 Rec7 34. Kb2 Rxc3 35. Rd2 Re3 36. Rbxd5 Rcc3 37. Ra5 h5  38. Ra7 h4  39. Rf2 Rb3+ 40. Ka2 Kg7 41. h3 g5 42. Rxb7 Rxa3+ 43. Kb2 Reb3+ 44. Kc2 Ra2+ 45. Kxb3 Rxf2 46. b5 Rxg2 47. b6 Rg1 48. Kc2 Re1 49. Rd7 Re6 50. b7 Rb6 51. Kd3  g4  52. hxg4 h3 53. Rd5  Rxb7 54. Rh5  Rb6 55. g5 Rb8 0-1 "

; sample game 701
EventSites(701) = "EU-Cup 31st  Skopje" : GameDates(701) = "20151022" : WhitePlayers(701) = "Kramnik, Vladimir   G#701" : WhiteElos(701) = "2777" : BlackPlayers(701) = "Topalov, Veselin   G#701" : BlackElos(701) = "2813" : Each_Game_Result(701) = "1-0"

FilePGNs(701) = "1. d4 Nf6 2. Nf3 e6 3. e3 c5 4. Bd3 b6 5. O-O Bb7 6. c4 cxd4 7. exd4 Be7 8. Nc3 d5 9. cxd5 Nxd5 10. Ne5 O-O 11. Qg4 f5 12. Qe2 Bf6 13. Bc4 Re8 14. Rd1 Nd7 15. Bb5 Bxe5 16. dxe5 Qe7 17. Nxd5 Bxd5 18. Qh5  g6 19. Qh6 Rec8 20. Bg5 Qf7 21. Bxd7 Qxd7 22. Bf6 Qf7 23. b3 Qf8 24. Qf4 Rc2  25. h4 Rac8 26. h5 Qe8 27. Rd3 R2c3 28. Rad1 gxh5 29. Rxd5  exd5 30. e6 R3c7 31. Rxd5 Qxe6 32. Qg5+ Kf8 33. Rxf5 Rf7 34. Qh6+ Ke8 35. Re5 Rc6 36. Qxh5 1-0 "

; sample game 702
EventSites(702) = "EU-Cup 31st  Skopje" : GameDates(702) = "20151024" : WhitePlayers(702) = "Roiz, Michael   G#702" : WhiteElos(702) = "2600" : BlackPlayers(702) = "Ivanchuk, Vassily   G#702" : BlackElos(702) = "2726" : Each_Game_Result(702) = "0-1"

FilePGNs(702) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. e3 Bf5 5. Nc3 e6 6. Nh4 Be4 7. f3 Bg6 8. Qb3 Qc7 9. Bd2 Be7 10. g3 O-O 11. Rc1 Rd8  12. Nxg6 hxg6 13. cxd5 exd5 14. Bg2 Qb6 15. Qc2 Nbd7 16. O-O Rac8 17. Rfd1 c5 18. Be1 Qe6  19. Bf2 a6  20. Qe2 b5 21. dxc5  Bxc5 22. Rc2  b4  23. Na4 Bxe3  24. Rxc8 Bxf2+ 25. Qxf2 Rxc8 26. Bf1 Ne5 27. Kg2  Qf5  28. Rd2 Ne4  0-1 "

; sample game 703
EventSites(703) = "EU-chT (Men) 20th  Reykjavik" : GameDates(703) = "20151114" : WhitePlayers(703) = "Bologan, Viktor   G#703" : WhiteElos(703) = "2630" : BlackPlayers(703) = "Wojtaszek, Radoslaw   G#703" : BlackElos(703) = "2748" : Each_Game_Result(703) = "1-0"

FilePGNs(703) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be3 e5 7. Nb3 Be6 8. f3 h5 9. Qd2 Nbd7 10. Nd5 Bxd5 11. exd5 g6 12. Be2 Bg7 13. O-O b6 14. c4 O-O 15. Rac1 Nh7 16. Bd3 f5 17. Bb1 Rc8 18. Kh1 a5 19. a4 Nc5 20. Nxc5 bxc5 21. g4  hxg4 22. fxg4 e4  23. gxf5 gxf5 24. Rg1 Kh8 25. Rxg7  Kxg7 26. Qg2+ Kh8 27. Bd2  Qh4 28. Bc3+ Nf6 29. Rf1 Rce8 30. Rxf5 e3 31. Qf3 Re5 32. Bxe5 dxe5 33. Qxe3 Ng4  34. Rxf8+ Kg7 35. Qe2 Kxf8 36. Bf5  Nxh2  37. Qxh2 Qe1+ 38. Kg2  Qd2+ 39. Kh1 Qe1+ 40. Qg1 Qh4+ 41. Kg2 Qg5+ 42. Kf1   Qc1+ 43. Kf2 Qd2+ 44. Kf3 Qf4+ 45. Ke2 Qxc4+ 46. Bd3 Qxd5 47. Qg4 1-0 "

; sample game 704
EventSites(704) = "EU-chT (Men) 20th  Reykjavik" : GameDates(704) = "20151116" : WhitePlayers(704) = "Perunovic, Milos   G#704" : WhiteElos(704) = "2624" : BlackPlayers(704) = "Edouard, Romain   G#704" : BlackElos(704) = "2632" : Each_Game_Result(704) = "1-0"

FilePGNs(704) = "1. e4 e6 2. d4 d5 3. Nc3 Bb4 4. e5 c5 5. a3 Bxc3+ 6. bxc3 Ne7 7. Qg4 cxd4 8. Qxg7 Rg8 9. Qxh7 Qc7 10. Kd1 Nbc6 11. Nf3 Nxe5  12. Bf4 Qxc3 13. Nxe5 Qxa1+ 14. Bc1 d3  15. Qxf7+ Kd8 16. Qf6 dxc2+ 17. Kd2  Qd4+ 18. Bd3 Qc5 19. Ke2 Bd7 20. Be3 d4 21. Bxd4 Qd5 22. Rc1 Bb5  23. Rxc2 Bxd3+ 24. Kxd3 Qb3+  25. Kd2 Qd5 26. Ke3 Re8 27. Nf7+ Kd7 28. Ne5+ Kd8 29. Bc5 Qb3+ 30. Kd2 Qd5+ 31. Kc1 Rc8 32. Bxe7+ Rxe7 33. Qf8+ 1-0 "

; sample game 705
EventSites(705) = "EU-chT (Men) 20th  Reykjavik" : GameDates(705) = "20151120" : WhitePlayers(705) = "Vazquez Igarza, Renier   G#705" : WhiteElos(705) = "2565" : BlackPlayers(705) = "Almasi, Zoltan   G#705" : BlackElos(705) = "2689" : Each_Game_Result(705) = "0-1"

FilePGNs(705) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 O-O 5. a3 Bxc3+ 6. Qxc3 d6 7. Nf3 b6 8. g3 Bb7 9. Bg2 a5 10. b3 c5 11. O-O Nbd7 12. Bb2 Qe7 13. Rfd1 Be4  14. b4 Rfc8 15. dxc5 bxc5 16. b5 Nb6 17. a4 d5 18. cxd5 exd5 19. e3  Qb7 20. Nh4  d4 21. exd4 c4  22. d5  Bxg2 23. Nf5  Nbxd5 24. Rxd5 Bxd5 25. Nxg7 Ne4 26. Qd4 Ng5  27. Qf6 Nh3+  28. Kf1 Bg2+ 29. Ke1 Qe4+ 0-1 "

; sample game 706
EventSites(706) = "London Classic 7th  London" : GameDates(706) = "20151211" : WhitePlayers(706) = "Anand, Viswanathan   G#706" : WhiteElos(706) = "2803" : BlackPlayers(706) = "Vachier Lagrave, Maxime   G#706" : BlackElos(706) = "2773" : Each_Game_Result(706) = "0-1"

FilePGNs(706) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Be2 e5 7. Nb3 Be7 8. Be3 Be6 9. Nd5 Nbd7 10. Qd3 O-O 11. c4 b5 12. Nd2 Nc5 13. Bxc5 dxc5 14. b3 Bxd5 15. cxd5 Ne8 16. O-O Nd6 17. a4 Bg5 18. Nf3 Bf4  19. axb5 f5 20. Nd2 Qg5  21. Rad1  axb5 22. exf5 Ra3  23. Ne4 c4 24. Qc2  Qxf5 25. Qb2 Rxb3 26. Qxb3 cxb3 27. Nxd6 Qg6 28. Nxb5 e4 29. d6 b2 30. Nd4 Qxd6  31. Bc4+ Kh8 32. Ne6 Bxh2+ 33. Kh1 Rxf2  34. Ng5  Bg3  0-1 "

; sample game 707
EventSites(707) = "Bundesliga 1516  Germany" : GameDates(707) = "20151212" : WhitePlayers(707) = "Navara, David   G#707" : WhiteElos(707) = "2728" : BlackPlayers(707) = "Tomashevsky, Evgeny   G#707" : BlackElos(707) = "2758" : Each_Game_Result(707) = "1-0"

FilePGNs(707) = "1. d4 d5 2. c4 c6 3. cxd5 cxd5 4. Nc3 Nf6 5. Bf4 Nc6 6. e3 Bg4 7. Qb3 Na5 8. Qa4+ Bd7 9. Qc2 e6 10. Bd3 Be7 11. Nf3 Nc6  12. a3 Nh5 13. Be5 f6 14. Bf4 Rc8 15. O-O a6  16. Rac1 Nxf4 17. exf4 f5  18. Qe2  O-O 19. Na4   Rc7 20. Qe3 Bf6 21. Nc5 Qe7 22. b4 Rfc8 23. Ne5  Be8 24. Nxb7 Nxb4  25. Rxc7 Rxc7 26. Nc5 Nxd3 27. Nexd3 Bb5 28. Re1  Bxd3 29. Qxd3 Rc6 30. Nxa6 Qa7   31. Nb4 Rc4 32. g3 Qd7 33. Qe2 Bxd4 34. Qxe6+ Qxe6 35. Rxe6 Bb2 36. Nxd5 Bxa3 37. Kg2 Rd4 38. Ne3 g6 39. Rc6 Bf8 40. Nc4 Rd5 41. Ne5 Rc5 42. Rb6 Rc2 43. Rb8 Kg7 44. Rb7+ Kg8 45. Nd7  Bg7 46. Ne5 Bf6 47. h4 Re2 48. h5 gxh5 49. Nf3 Re4  50. Rb5 Kg7 51. Rxf5 Kg6 52. Rb5 h4  53. Nxh4+ Bxh4 54. Kf3  Re1 55. gxh4 Rh1 56. f5+ Kf6 57. Kg4 Rg1+  58. Kf4 Rh1  59. Rb6+ Kf7 60. Rb7+ 1-0 "

; sample game 708
EventSites(708) = "Qatar Masters op  Doha" : GameDates(708) = "20151224" : WhitePlayers(708) = "Carlsen, Magnus   G#708" : WhiteElos(708) = "2834" : BlackPlayers(708) = "Li, Chao B   G#708" : BlackElos(708) = "2750" : Each_Game_Result(708) = "1-0"

FilePGNs(708) = "1. d4 Nf6 2. c4 g6 3. f3  d5 4. cxd5 Nxd5 5. e4 Nb6 6. Nc3 Bg7 7. Be3 O-O 8. Qd2 Nc6 9. O-O-O f5 10. e5 Nb4 11. Nh3 Qe8  12. Kb1 a5 13. Be2 c6 14. Rc1 Kh8  15. Ka1  Be6 16. Nf4 Qf7 17. h4  Bxa2  18. h5 Kg8 19. hxg6 hxg6 20. g4 Bb3  21. Bd1  a4 22. Qh2 Rfd8 23. Qh7+ Kf8 24. d5 Nc4  25. Nxg6+  Ke8 26. e6 a3  27. exf7+ Kd7 28. Ne5+  Bxe5 29. Qxf5+ Kc7 30. Qxe5+  Nxe5 31. Bxb3 axb2+ 32. Kxb2 Nbd3+ 33. Kb1 Nxc1 34. Rxc1 Kc8 35. dxc6 bxc6 36. f4 1-0 "

; sample game 709
EventSites(709) = "Qatar Masters op  Doha" : GameDates(709) = "20151224" : WhitePlayers(709) = "Korobov, Anton   G#709" : WhiteElos(709) = "2713" : BlackPlayers(709) = "Swiercz, Dariusz   G#709" : BlackElos(709) = "2646" : Each_Game_Result(709) = "0-1"

FilePGNs(709) = "1. d4 Nf6 2. c4 g6 3. f3 d5 4. cxd5 Nxd5 5. e4 Nb6 6. Nc3 Bg7 7. Be3 O-O 8. Qd2 Nc6 9. O-O-O Qd6 10. Nb5 Qd7 11. f4  Qe6 12. Nc3 Nc4 13. Qe2 N6a5  14. Bf2  c5 15. Nf3 b5  16. e5 Qa6  17. Ne4  Bf5  18. g4 Bxg4 19. Nxc5 Nb3+  20. Kb1 Nxc5 21. dxc5 f6 22. Rg1 Bh5 23. Qe4 fxe5 24. Bxc4+ bxc4 25. Rd7 Bxf3 26. Qxf3 Qe6  27. Rgd1 e4  28. Qe2 Rfb8 29. R1d4 c3 30. b4 Bxd4 31. Rxd4 a5 32. b5 c2+ 33. Qxc2 Rxb5+ 34. Kc1 e3 35. Re4 exf2 0-1 "

; sample game 710
EventSites(710) = "Qatar Masters op  Doha" : GameDates(710) = "20151227" : WhitePlayers(710) = "Mamedyarov, Shakhriyar   G#710" : WhiteElos(710) = "2748" : BlackPlayers(710) = "Ganguly, Surya Shekhar   G#710" : BlackElos(710) = "2648" : Each_Game_Result(710) = "1-0"

FilePGNs(710) = "1. c4 e5 2. Nc3 Nf6 3. g3 d5 4. cxd5 Nxd5 5. Bg2 Nb6 6. e3 Nc6 7. Nge2 Qd3  8. f4 f6 9. Be4 Qa6 10. fxe5 fxe5 11. Ng1 Nd7  12. Nd5 Bd6 13. Qh5+ Kd8 14. Nf3  Nc5  15. Qg5+ Ne7 16. Nxe7 Bxe7 17. Qxe5 Rf8 18. Rf1 Qc4  19. Bxh7   Bh3 20. Rf2 Bf6 21. Qf4 Nd3+ 22. Bxd3 Qxd3 23. g4 Qd7 24. Ne5 Qd5 25. Ng6 Qh1+  26. Ke2 Qg1  27. Nxf8 Bxg4+ 28. Kd3 Ke8  29. Rf1 Rd8+  30. Kc2 Qg2 31. Nh7  Be2  32. Nxf6+ gxf6 33. b3  Bd3+ 34. Kb2  Bxf1 35. Qxc7 Bd3 36. Ka3  Bf5 37. Bb2 Qxd2 38. Bxf6 Qd6+ 39. Qxd6 Rxd6 40. Bd4 Ra6+ 41. Kb4 Be4 42. a4 Rh6 43. Ra2 a6 44. Rf2 Bd5 45. a5  Kd7 46. Kc3 Rc6+ 47. Kb2 Rh6 48. b4 Rh5 49. Kc3 Rh4 50. Kd3 Ke6 51. Rb2  Rh3 52. Ba7 Rh8 53. Bb6 Rh7 54. Kc3 Rh4 55. Bd8 Rc4+ 56. Kd3 Rc8 57. Bg5  Bc4+ 58. Ke4 Bd5+ 59. Kd4 Rc4+ 60. Kd3 Rg4 61. Bf4  Rg1 62. b5 Rd1+ 63. Kc2 Rg1 64. Rb4 axb5 65. Rxb5 Rg4 66. Kc3 Rh4 67. Rb6+ Kf5 68. Kd4 Bf3 69. Rb2 Rh7  70. Rb5+ Ke6 71. e4  Rd7+ 72. Ke3 Bg2 73. Rb6+ Kf7 74. h4 Re7 75. e5 Re6 76. Rb2 Bd5 77. Rd2 Bc6 78. h5 Re8 79. h6 Ra8 80. Rh2 Kg6 81. h7  Rh8 82. Rh6+ Kg7 83. a6  Bg2 84. a7 b5 85. e6 1-0 "

; sample game 711
EventSites(711) = "Qatar Masters op  Doha" : GameDates(711) = "20151229" : WhitePlayers(711) = "Yu, Yangyi   G#711" : WhiteElos(711) = "2736" : BlackPlayers(711) = "So, Wesley   G#711" : BlackElos(711) = "2775" : Each_Game_Result(711) = "1-0"

FilePGNs(711) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Nf3 c5 5. g3 cxd4 6. Nxd4 O-O 7. Bg2 d5 8. Nc2  Bxc3+ 9. bxc3 Qc7 10. cxd5 Nxd5 11. Nb4 Nxb4 12. cxb4 Rd8 13. Qb3 Nc6 14. O-O Nd4 15. Qb2 e5 16. Be3 Bg4 17. Rac1 Qd7 18. f3 Bh3 19. Rfd1 Bxg2 20. Kxg2 Qe6 21. Rc7 b6 22. a4  Nf5 23. Rxd8+ Rxd8 24. Bf2 e4 25. Qc2 e3 26. Be1 h5  27. Rxa7  Nd4 28. Qe4 Qc4 29. Qxe3  Nc2 30. Qe7 Nxe1+ 31. Kf2 Qd4+  32. Kf1 Nc2  33. Qxf7+ Kh8 34. Qxh5+ Kg8 35. Qf7+ Kh8 36. Qh5+ Kg8 37. Qf7+ Kh8 38. Kg2  Ne3+ 39. Kh3 Kh7 40. Qh5+ Kg8 41. Re7 Rf8 42. a5 bxa5 43. bxa5 Nd5 44. Qe5 Qxe5 45. Rxe5 Nb4 46. Re4 Nd5 47. Rc4 Rf6 48. Rc5 Rf5 49. Rc8+ Kf7 50. a6 Ne3 51. g4 Ra5 52. Rc7+ Kf6 53. Rc6+  Kf7 54. Kg3 g5 55. h4 gxh4+ 56. Kxh4 Nd5 57. e4  Ne7 58. Rb6 Ng6+ 59. Kg3 Ra3 60. g5 Ne5 61. Rf6+ Ke7 62. Kg2 Nd3 63. Rh6  Ra5 64. a7 Rxg5+ 65. Kf1 Rg8 66. Ke2 Ne5  67. f4 Nd7 68. Ra6 Ra8 69. Ke3 Nc5 70. Ra1  Nb7 71. e5 Nd8 72. Ra6 Kd7 73. f5 Nc6 74. e6+ Kc7 75. f6  Nb4 76. f7 Kb7 77. Rd6 1-0 "

; sample game 712
EventSites(712) = "Tata Steel-A 78th  Wijk aan Zee" : GameDates(712) = "20160118" : WhitePlayers(712) = "Navara, David   G#712" : WhiteElos(712) = "2730" : BlackPlayers(712) = "Giri, Anish   G#712" : BlackElos(712) = "2798" : Each_Game_Result(712) = "1/2-1/2"

FilePGNs(712) = "1. d4 Nf6 2. c4 g6 3. Nc3 d5 4. Nf3 Bg7 5. Qb3 dxc4 6. Qxc4 O-O 7. e4 a6 8. Be2 b5 9. Qb3 c5 10. dxc5 Bb7 11. e5 Nfd7 12. Be3 e6 13. O-O Qc7 14. Rad1 Nxc5 15. Qa3 Ne4  16. Nxe4 Bxe4 17. Ng5 Bc6  18. f4 Qb7 19. Bc5 Re8  20. f5  exf5 21. Rxf5  gxf5 22. Bh5 Bd5  23. Rxd5 Qxd5 24. Bxf7+ Qxf7 25. Nxf7 Kxf7 26. Qb3+ Kg6 27. Qg3+ Kf7 28. Qb3+ Kg6 29. Qg3+ Kf7 30. Qf3  Nd7  31. Qd5+ Kg6 32. Qc6+ Nf6  33. exf6 Rac8 34. Qxa6 Ra8 35. f7+ Kxf7 36. Qxb5 Rad8 37. Qb3+ Kg6 38. Qg3+ Kf7 39. Qb3+ Kg6 40. Bd6  Bxb2  41. Qxb2 Rxd6 42. h3 Ra6 1/2-1/2 "

; sample game 713
EventSites(713) = "Tata Steel-A 78th  Wijk aan Zee" : GameDates(713) = "20160122" : WhitePlayers(713) = "Carlsen, Magnus   G#713" : WhiteElos(713) = "2844" : BlackPlayers(713) = "Tomashevsky, Evgeny   G#713" : BlackElos(713) = "2728" : Each_Game_Result(713) = "1-0"

FilePGNs(713) = "1. d4 Nf6 2. Nf3 e6 3. Bf4  b6 4. e3 Bb7 5. h3 Be7 6. Bd3 O-O 7. O-O c5 8. c3 Nc6 9. Nbd2 d5 10. Qe2  Bd6 11. Rfe1  Ne7 12. Rad1 Ng6 13. Bxg6  hxg6 14. Bxd6 Qxd6 15. Ne5  g5 16. f4  gxf4 17. Rf1  Nd7 18. Qh5  Nf6 19. Qh4 Qd8  20. Rxf4 Ne4  21. Nxe4 Qxh4 22. Rxh4 dxe4 23. dxc5  bxc5 24. Rd7 Rab8 25. b3  a5 26. Rc7 a4 27. bxa4 Ba8 28. a5 Rb7 29. Rxc5 Ra7 30. Nc4 1-0 "

; sample game 714
EventSites(714) = "Tata Steel-A 78th  Wijk aan Zee" : GameDates(714) = "20160126" : WhitePlayers(714) = "Carlsen, Magnus   G#714" : WhiteElos(714) = "2844" : BlackPlayers(714) = "Adams, Michael   G#714" : BlackElos(714) = "2744" : Each_Game_Result(714) = "1-0"

FilePGNs(714) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. O-O d6 5. c3 Nf6 6. d3 h6 7. a4 a5 8. Na3 O-O 9. Nc2 Re8 10. Re1 Ba7 11. Be3 Be6 12. Bb5 Bd7 13. Bxa7 Nxa7 14. Bc4 Be6 15. Bxe6 Rxe6 16. Ne3 Nc8 17. Nf5 Ne7 18. d4 exd4 19. N3xd4 Re5  20. Ng3 Ng6 21. Qc2 c6 22. Rad1 Qc7 23. Ndf5 Rd8 24. Qd2 Kh7 25. f4 Qb6+ 26. Kh1 Ree8 27. h3 Rd7 28. Nxd6 Rxd6 29. Qxd6 Qf2 30. Qd3 Nxf4 31. Qf3 Nxh3 32. Re2 Qxf3 33. gxf3 Ng5 34. Kg2 Ne6 35. Red2 g6 36. Nf1 h5 37. Ne3 h4 38. Nc4 g5 39. Nxa5 g4 40. Nxb7 g3 41. Nd6 Rg8 42. Nf5 Nf4+ 43. Kh1 h3 44. a5 N6h5 45. a6 Ne6 46. a7 Ra8 47. Ra1 Ng5 48. Nh4 Nf4 49. b4  g2+ 50. Nxg2 hxg2+ 51. Rxg2 Nxg2 52. Kxg2 Ne6 53. c4 Nc7 54. Kg3 Kg6 55. Kf4 Kf6 56. e5+ Ke7 57. Ke4 f6 58. f4 fxe5 59. Kxe5 Ne8 60. f5 Nd6 61. f6+ Kd7 62. Rd1 Re8+ 63. Kd4 Kc7 64. Re1 Nf5+ 65. Kc3 Ra8 66. f7 1-0 "

; sample game 715
EventSites(715) = "Tata Steel-A 78th  Wijk aan Zee" : GameDates(715) = "20160130" : WhitePlayers(715) = "Caruana, Fabiano   G#715" : WhiteElos(715) = "2787" : BlackPlayers(715) = "Van Wely, Loek   G#715" : BlackElos(715) = "2640" : Each_Game_Result(715) = "1-0"

FilePGNs(715) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. f3 e6 7. Be3 b5 8. Qd2 Nbd7 9. g4 h6 10. O-O-O Bb7 11. h4 b4 12. Na4 Qa5 13. b3 Be7  14. Rh3  Nc5 15. a3 Rc8 16. axb4 Nxb3+ 17. Nxb3 Qxa4 18. Kb2 d5 19. Bc5 Qd7 20. g5 hxg5 21. hxg5 Rxh3 22. Bxh3 Nh7 23. f4 Qc7 24. Bxe7  Kxe7 25. Nc5 a5 26. g6 Nf6 27. e5 Nd7 28. Nxd7 Qxd7 29. f5 Rc4  30. f6+ gxf6 31. exf6+ Kd6 32. Qh2+  Kc6 33. g7 Qd8 34. Qe5 Bc8 35. b5+ Kb7 36. Rg1 Qb6 37. g8=Q 1-0 "

; sample game 716
EventSites(716) = "Gibraltar Masters 14th  Gibraltar" : GameDates(716) = "20160202" : WhitePlayers(716) = "Edouard, Romain   G#716" : WhiteElos(716) = "2617" : BlackPlayers(716) = "Gunina, Valentina   G#716" : BlackElos(716) = "2496" : Each_Game_Result(716) = "1-0"

FilePGNs(716) = "1. d4 d5 2. c4 c6 3. Nf3 Nf6 4. Nc3 e6 5. Bg5 Nbd7 6. e4 dxe4 7. Nxe4 Be7 8. Nc3 O-O 9. Bd3 c5 10. Bc2   b6 11. Qe2 cxd4 12. Nxd4 Bb7 13. O-O-O Qc7 14. Ndb5 Qe5 15. Be3 a6  16. Nd6  Bc6  17. Rhg1 Qa5  18. g4 Ne5 19. g5 Nfd7  20. Rg3 Rfd8  21. Bxh7+ Kf8 22. f4 Ng6 23. Bxg6 fxg6 24. f5  Qe5 25. fxg6 Bxd6 26. Qf1+  Nf6  27. gxf6  Qxf6 28. Rh3  Ke7  29. Qg1 Be5  30. Rf1 Bxc3 31. Rxf6 Bxf6 32. Bxb6 1-0 "

; sample game 717
EventSites(717) = "Gibraltar Masters 14th  Gibraltar" : GameDates(717) = "20160203" : WhitePlayers(717) = "Sethuraman, SP.   G#717" : WhiteElos(717) = "2639" : BlackPlayers(717) = "Wojtaszek, Radoslaw   G#717" : BlackElos(717) = "2727" : Each_Game_Result(717) = "1-0"

FilePGNs(717) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Bb7 10. d4 Re8 11. Nbd2 Bf8 12. a3 g6 13. Ba2 Bg7 14. Qc2  Qd7 15. b4 exd4 16. cxd4 a5 17. bxa5 Nxa5 18. Rb1 Qc6 19. Qd1  d5 20. Ne5 Qa6 21. a4 Nc4  22. Rxb5 Nxd2 23. Bxd2 Qxa4 24. Qxa4 Rxa4 25. Bb3 Rxd4 26. Nf3  Rxd2 27. Nxd2 Ba8 28. Rc5  c6 29. Ra5 Bh6 30. Nf1  Bf8 31. Rea1 Bb7 32. exd5 cxd5 33. Rd1 Ne4 34. Rc1  Bc5 35. Raxc5 Nxc5 36. Rxc5 Re1 37. Bxd5 1-0 "

; sample game 718
EventSites(718) = "Gibraltar Masters 14th  Gibraltar" : GameDates(718) = "20160204" : WhitePlayers(718) = "Yu, Yangyi   G#718" : WhiteElos(718) = "2744" : BlackPlayers(718) = "Jones, Gawain C   G#718" : BlackElos(718) = "2625" : Each_Game_Result(718) = "0-1"

FilePGNs(718) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 g6 6. Be3 Bg7 7. f3 Nc6 8. Qd2 O-O 9. Bc4 Bd7 10. Bb3 Rc8 11. O-O-O Nxd4 12. Bxd4 b5 13. e5 dxe5 14. Bxe5 Bc6 15. Qxd8 Rfxd8 16. Ne2 Bh6+  17. Kb1 Nd7 18. Bd4 a5 19. a3 b4 20. axb4 axb4 21. Rhe1 e5 22. Bf2 Nf6 23. Bg3  Bd2  24. Rg1 e4 25. Be5 exf3 26. gxf3 Bxf3 27. Bxf6 Bxe2 28. Bxd8 Rxd8 29. c3 Bxd1 30. Rxd1 Rb8  31. Kc2 Bf4 32. Rd7 Rf8 33. h3 bxc3 34. bxc3 Kg7 35. Bd5 g5 36. c4 h5 37. c5 Kg6 38. c6 f5 39. c7  Rc8 40. Kd3 g4 41. hxg4 hxg4 42. Bb7 Rxc7 43. Rxc7 Bxc7 44. Ke3 Kg5 45. Bc8  f4+ 46. Ke4 Kh4 47. Kf5 g3 0-1 "

; sample game 719
EventSites(719) = "Mashhad Ferdowsi op 6th  Mashhad" : GameDates(719) = "20160205" : WhitePlayers(719) = "Mousavi, Seyed Khalil   G#719" : WhiteElos(719) = "2425" : BlackPlayers(719) = "Tiviakov, Sergei   G#719" : BlackElos(719) = "2611" : Each_Game_Result(719) = "0-1"

FilePGNs(719) = "1. Nf3 Nf6 2. c4 b6 3. g3 Bb7 4. Bg2 e6 5. O-O c6 6. d4 d5 7. Nc3 Be7 8. Nd2 O-O 9. e4 Na6 10. e5 Nd7 11. cxd5 cxd5 12. f4 Nc7  13. f5  exf5 14. Rxf5 f6  15. Qb3  Kh8 16. exf6 Bxf6 17. Nf3  g6 18. Rf4  Ne6 19. Rg4 g5 20. h4 gxh4 21. gxh4 Bg7 22. Bg5 Nf6 23. Ne5 Nxg4   24. Bxd8 Nxd4 25. Qd1 Nxe5 26. Bc7 Ndf3+ 27. Kh1 d4 28. Bxe5 Bxe5 29. Ne2 Rg8 30. Nf4 Raf8 0-1 "

; sample game 720
EventSites(720) = "Zuerich Chess Challenge Rapid 5th  Zuerich" : GameDates(720) = "20160213" : WhitePlayers(720) = "Shirov, Alexei   G#720" : WhiteElos(720) = "2684" : BlackPlayers(720) = "Nakamura, Hikaru   G#720" : BlackElos(720) = "2787" : Each_Game_Result(720) = "0-1"

FilePGNs(720) = "1. e4 e6 2. d4 d5 3. e5 c5 4. c3 Nc6 5. Nf3 Qb6 6. a3 Nh6 7. b4 cxd4 8. Bxh6 gxh6 9. cxd4 Bd7 10. Ra2 Rg8 11. h3 h5 12. g3 h4 13. g4 Be7 14. Be2 f6 15. b5  Nd8 16. Qd3 Rg7 17. Nc3 Nf7 18. O-O  h5  19. Na4 Qd8 20. exf6 Bxf6 21. Nc5 hxg4 22. hxg4 b6 23. Nxd7 Qxd7 24. Kh1 Rc8 25. Rc2 Rxc2 26. Qxc2 Nd6 27. Ne5 Bxe5 28. dxe5 Ne4 29. Kg2  Nc5 30. Rh1 Qe7 31. Qc1 Rh7 32. Qe3 Qg7 33. Rc1 Qf8  34. a4 Rf7 35. f3  Rf4 36. Rxc5   bxc5 37. a5 h3+ 38. Kg3 h2 0-1 "

; sample game 721
EventSites(721) = "Southwest Class Championship 7th  Dallas" : GameDates(721) = "20160214" : WhitePlayers(721) = "Sadorra, Julio Catalino   G#721" : WhiteElos(721) = "2514" : BlackPlayers(721) = "Liang, Awonder   G#721" : BlackElos(721) = "2379" : Each_Game_Result(721) = "1/2-1/2"

FilePGNs(721) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Nf3 O-O 5. g3 d5 6. Bg2 dxc4 7. O-O Nc6 8. a3  Be7 9. e4 Na5 10. Be3 Nb3 11. Rb1 c5 12. dxc5 Nxc5 13. Ne5 Bd7 14. Nxc4 Bc6  15. Ne5  Qxd1 16. Rfxd1 Be8 17. Nc4 Ng4  18. Bf4 g5  19. Bc7  Rc8 20. Bd6 Bxd6 21. Nxd6 Rd8 22. b4 Na4 23. Ne2 b5 24. Bh3 Ne5 25. f4 gxf4 26. gxf4 Nc4 27. Nxc4 Rxd1+ 28. Rxd1 bxc4 29. Kf2 Bc6  30. Ke3 f5 31. Ng3 Nc3 32. Rd4 Nxe4 33. Rxc4 Bb5 34. Rc7 Rd8  35. Bf1 Nf6  36. Kf2 Ng4+ 37. Ke1 a6  38. Bxb5 axb5 39. Nh5 Rd3 40. Rg7+ Kf8 41. Ra7 Rh3 42. Ng7 Rh6  43. a4  bxa4 44. b5 e5 45. Nxf5 Rf6 46. h3  Rxf5 47. hxg4 Rf6 48. Rxa4 Rb6 49. Rb4 exf4 50. Kf2 Ke7 51. Kf3 Kd6 52. Kxf4 Kc5 53. Rb1 Kd5 54. g5  h6 55. gxh6 Rxh6 56. b6 Rh8 57. b7 Rb8 1/2-1/2 "

; sample game 722
EventSites(722) = "Moscow Aeroflot op-A 15th  Moscow" : GameDates(722) = "20160304" : WhitePlayers(722) = "Wei, Yi   G#722" : WhiteElos(722) = "2714" : BlackPlayers(722) = "Wagner, Dennis   G#722" : BlackElos(722) = "2583" : Each_Game_Result(722) = "1/2-1/2"

FilePGNs(722) = "1. d4  d5  2. c4 c6 3. Nf3 Nf6 4. Nc3 dxc4 5. a4 e6  6. e3 c5 7. Bxc4 Nc6 8. O-O Be7 9. Qe2 cxd4 10. exd4 O-O 11. Rd1 Nb4 12. Bg5 h6 13. Bxf6 Bxf6 14. Ne4 b6 15. Ne5 Be7  16. Ra3 Bb7 17. Qg4 Nd5  18. Rg3 Bg5 19. Bxd5 Bxd5 20. Nxg5 Qxg5 21. Qh3 Qf4 22. Rg4 Qf5 23. Qg3 g5  24. h4 f6 25. hxg5 fxe5 26. gxh6+ Kh8 27. dxe5  Rac8 28. Rg7 Qc2  29. Re1 Rg8  30. Qg5  Rcf8 31. Rxg8+  Rxg8 32. Qf6+ 1/2-1/2 "

; sample game 723
EventSites(723) = "Reykjavik op  Reykjavik" : GameDates(723) = "20160316" : WhitePlayers(723) = "Grandelius, Nils   G#723" : WhiteElos(723) = "2645" : BlackPlayers(723) = "Gupta, Abhijeet   G#723" : BlackElos(723) = "2634" : Each_Game_Result(723) = "0-1"

FilePGNs(723) = "1. Nf3 Nf6 2. c4 g6 3. Nc3 d5 4. cxd5 Nxd5 5. g3 Bg7 6. Bg2 O-O 7. h4 h6 8. O-O c5 9. Nxd5 Qxd5 10. d4 cxd4 11. Be3 d3  12. Ne1 Qd6 13. Nxd3 Nc6 14. Rc1 Nd4 15. Re1 Rd8 16. Qa4 Bd7 17. Qb4 Qxb4 18. Nxb4 Nf5  19. Bf4  e5 20. Bd2 Bc6 21. Bc3  Bxg2 22. Kxg2 e4 23. Bxg7 Kxg7 24. Red1 Rac8  25. Rxd8 Rxd8 26. Rc4 a5  27. Nc2 Rd2 28. e3 Nd6 29. Rc5 b6 30. Rc6 Nb7 31. b4 axb4 32. Nxb4 Na5 33. Rc2  Rxc2 34. Nxc2 Kf6 35. f3  Ke5 36. Nb4 Nc4 37. Kf2 h5 38. g4 Nd2 39. gxh5 gxh5 40. Nc6+ Kd5  41. Nd4  Nxf3 42. Nxf3 exf3 43. Kxf3 Ke5 44. a4 f5 45. Ke2 Ke4 46. Kd2 Kf3 0-1 "

; sample game 724
EventSites(724) = "FIDE Candidates  Moscow" : GameDates(724) = "20160324" : WhitePlayers(724) = "Anand, Viswanathan   G#724" : WhiteElos(724) = "2762" : BlackPlayers(724) = "Karjakin, Sergey   G#724" : BlackElos(724) = "2760" : Each_Game_Result(724) = "1-0"

FilePGNs(724) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. d3 Bc5 5. c3 O-O 6. O-O d6 7. h3 Ne7 8. d4 Bb6 9. Bd3 d5 10. Nxe5 Nxe4 11. Nd2 Nd6 12. Nb3  c6 13. Nc5 Ng6 14. Qh5 Bxc5 15. dxc5 Ne4 16. Bxe4 dxe4 17. Rd1 Qe7 18. Nxg6 hxg6 19. Qg5 Qxg5 20. Bxg5 f6 21. Be3 g5 22. Rd6 Re8 23. Rad1 Be6 24. b3 Kf7 25. R1d4 Bf5 26. a4 Re7 27. g4 Bh7 28. b4 Bg8 29. b5 Rc8 30. Rd7 Re8 31. b6  a6 32. Rc7 Kf8 33. c4  Be6 34. Rxe4 Kf7 35. f4 Rxc7 36. bxc7 Rc8  37. f5 Bd7 38. h4 g6 39. Rd4  Rxc7 40. hxg5 fxg5 41. Bxg5 Be8 42. f6 Kf8 43. Bf4 Rh7 44. Kg2 Bd7 45. Bg5 Be6 46. Rd8+ Kf7 47. Rb8 Bxc4 48. Rxb7+ Kg8 49. Rb8+ Kf7 50. Kg3 Ke6 51. Re8+ Kf7  52. Rc8 Bd5 53. Kf4 Ke6 54. Re8+ Kd7 55. Ra8 Ke6 56. Re8+ Kd7 57. Re3 a5 58. Kg3 Rf7 59. Kf4 Rh7 60. Re1 Kc8 61. Kg3 Rf7 62. Re8+ Kd7 63. Ra8 Kc7 64. Kf4 Rd7 65. Bh4 Kb7 66. Re8 Bf7 67. Re4 Bd5 68. Re3 Bf7 69. Kg5 Ka6 70. Re7 1-0 "

; sample game 725
EventSites(725) = "FIDE Candidates  Moscow" : GameDates(725) = "20160328" : WhitePlayers(725) = "Karjakin, Sergey   G#725" : WhiteElos(725) = "2760" : BlackPlayers(725) = "Caruana, Fabiano   G#725" : BlackElos(725) = "2794" : Each_Game_Result(725) = "1-0"

FilePGNs(725) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 d6 6. Bg5 e6 7. Qd2 a6 8. O-O-O Bd7 9. f4 h6 10. Bh4 b5 11. Bxf6 gxf6 12. f5 Qb6 13. fxe6 fxe6 14. Nxc6 Qxc6  15. Bd3 h5 16. Kb1 b4 17. Ne2 Qc5 18. Rhf1 Bh6 19. Qe1 a5 20. b3  Rg8 21. g3 Ke7 22. Bc4 Be3 23. Rf3 Rg4 24. Qf1 Rf8 25. Nf4 Bxf4 26. Rxf4 a4 27. bxa4 Bxa4 28. Qd3 Bc6 29. Bb3 Rg5 30. e5  Rxe5 31. Rc4 Rd5 32. Qe2 Qb6 33. Rh4 Re5 34. Qd3 Bg2 35. Rd4  d5 36. Qd2 Re4  37. Rxd5  exd5 38. Qxd5 Qc7 39. Qf5  Rf7 40. Bxf7 Qe5 41. Rd7+ Kf8 42. Rd8+ 1-0 "

; sample game 726
EventSites(726) = "Asia Chess Cup  Abu Dhabi" : GameDates(726) = "20160401" : WhitePlayers(726) = "Wei, Yi   G#726" : WhiteElos(726) = "2714" : BlackPlayers(726) = "Vidit, Santosh Gujrathi   G#726" : BlackElos(726) = "2648" : Each_Game_Result(726) = "0-1"

FilePGNs(726) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. d3 Nf6 5. c3 O-O 6. O-O d5 7. exd5 Nxd5 8. Nbd2 Nb6 9. Bb5 Bd6 10. Re1 Bg4 11. h3 Bh5 12. Ne4 f5 13. Ng3 Bxf3 14. Qxf3 Qd7 15. a4 a6 16. Bxc6 bxc6 17. c4 Rab8  18. a5 Nc8 19. c5 Bxc5 20. Rxe5 Bd4 21. Re1 Nd6 22. Ne2  Rfe8 23. Bf4  Bxb2 24. Rab1 Nb5  25. Ng3 Bc3 26. Rxe8+ Rxe8 27. Be3 g6 28. Qd1 Bxa5 29. Ra1 Bb6  30. Bxb6 cxb6 31. Rxa6 f4 32. Ne2 f3 33. Nf4  Nd4 34. Ra1 Rf8 0-1 "

; sample game 727
EventSites(727) = "Norway Chess 4th  Stavanger" : GameDates(727) = "20160419" : WhitePlayers(727) = "Carlsen, Magnus   G#727" : WhiteElos(727) = "2851" : BlackPlayers(727) = "Harikrishna, Penteala   G#727" : BlackElos(727) = "2763" : Each_Game_Result(727) = "1-0"

FilePGNs(727) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Ba6 5. Nbd2 Bb4 6. Qa4 c5 7. a3 Bxd2+ 8. Bxd2 O-O 9. dxc5 bxc5 10. Bg2 Qb6  11. O-O Nc6 12. Be3  Rfc8 13. Rfd1  d5 14. cxd5 exd5 15. Bxc5 Qa5  16. Qc2 Bxe2 17. Qxe2 Qxc5 18. Rac1 Qb6 19. b4  h6 20. Qe3  Qb7 21. Bh3 Re8 22. Qc3 Ne7 23. Nd4 Ne4 24. Qc7 Qa6 25. f3 Ng5 26. Bd7 Red8 27. h4 Nxf3+  28. Nxf3 Qxa3 29. Kg2 Qb2+ 30. Rd2 Qxb4 31. Re1 a5 32. Rde2 Ng6 33. h5 Nh8 34. Bf5 a4 35. Ne5 Qd6 36. Qc2  Re8 37. Bh7+ Kf8 38. Qf5 Re7 39. Bg6 Kg8 40. Nxf7  Rxf7 41. Bxf7+ 1-0 "

; sample game 728
EventSites(728) = "Dubai op 18th  Dubai" : GameDates(728) = "20160419" : WhitePlayers(728) = "Yilmaz, Mustafa   G#728" : WhiteElos(728) = "2594" : BlackPlayers(728) = "Vidit, Santosh Gujrathi   G#728" : BlackElos(728) = "2648" : Each_Game_Result(728) = "0-1"

FilePGNs(728) = "1. Nf3 Nf6 2. c4 c5 3. d4 cxd4 4. Nxd4 e6 5. Nc3 Nc6 6. a3 Bc5 7. Nb3 Bb6 8. Bf4 d5 9. e3 O-O 10. Be2 h6 11. Bg3 dxc4 12. Bxc4 Bd7 13. O-O Na5 14. Nxa5 Bxa5 15. Rc1  Rc8 16. Qe2 Bxc3 17. Rxc3 Ne4 18. Rcc1 Nxg3 19. hxg3 Qb6 20. b3  Rc7 21. Rfd1 Rfc8 22. Qb2  Ba4 23. Rb1 Rxc4 24. bxa4 Qxb2 25. Rxb2 R8c7 26. Rb4 Rc3 27. Ra1 b6 28. g4 Kf8 29. Kh2 Ke7 30. Kg3 R7c5 31. Kf3 Rd5 32. Rb5 Rc4 33. Rb4 Rc3 34. Ra2 Kd6 35. Rf4 f6 36. Rb4 Kc6 37. Re4 Kd6 38. Rb4 Kc6 39. Re4 e5 40. Rb4 Rd4 41. a5 b5 42. Rab2 a6 43. Ke2 Rd5 44. a4 Ra3 45. axb5+ axb5 46. Kf3 Rxa5 47. R4b3 Ra4 48. Rc3+ Rc5 49. Rcb3 Ra8 50. Rd2 Rc4 51. Rdb2 Rb8 52. Ra3 b4 53. Ra6+ Rb6 54. Ra8 Rb7 55. Rd8 Kb5 56. Ra8 Rc3 57. Ke2 b3 58. Rb1 Kb4 59. Rb2 Rc5 60. Kd3 Rd7+ 61. Ke4 Kc3 62. Re2 Rd2 63. Re1 Rxf2 64. Rd8 b2 65. g5 Rc4+ 0-1 "

; sample game 729
EventSites(729) = "Norway Chess 4th  Stavanger" : GameDates(729) = "20160420" : WhitePlayers(729) = "Giri, Anish   G#729" : WhiteElos(729) = "2790" : BlackPlayers(729) = "Vachier Lagrave, Maxime   G#729" : BlackElos(729) = "2788" : Each_Game_Result(729) = "0-1"

FilePGNs(729) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bg5 e6 7. f4 h6 8. Bh4 Qb6 9. a3 Be7 10. Bf2 Qc7 11. Qf3 Nbd7 12. O-O-O b5 13. g4 g5 14. h4 gxf4 15. Be2  Rg8 16. Rdg1  d5  17. exd5 Ne5 18. Qh3 exd5 19. Re1 Kf8  20. Nf5 Bxf5 21. gxf5 Bc5  22. Qf1 d4 23. Nb1 Ne4 24. Bf3 Nxf2  25. Bxa8 Ned3+ 26. Kd2 Nxe1 27. Qxf2 d3  28. Qxe1 Be3+ 0-1 "

; sample game 730
EventSites(730) = "Norway Chess 4th  Stavanger" : GameDates(730) = "20160421" : WhitePlayers(730) = "Carlsen, Magnus   G#730" : WhiteElos(730) = "2851" : BlackPlayers(730) = "Grandelius, Nils   G#730" : BlackElos(730) = "2649" : Each_Game_Result(730) = "1-0"

FilePGNs(730) = "1. e4 c5 2. Nf3 Nf6  3. e5  Nd5 4. Nc3 Nxc3 5. dxc3 Nc6 6. Bf4 Qb6  7. Qc1  f6  8. Bc4  g5  9. Bg3  g4 10. exf6  gxf3 11. Qf4  fxg2  12. Rg1 Na5  13. f7+ Kd8 14. Bd5 Bh6  15. Qe5 Rf8 16. Bh4  Rxf7 17. Bxf7 Nc6 18. Qg3 Qxb2 19. Rd1 Qxc2 20. Bd5 Qf5 21. Rxg2 Bf4 22. Qf3  Kc7 23. Rg5 Qf8 24. Bg3  e5 25. Rh5  a5 26. Rxh7 Ra6 27. Rf7 Qe8 28. Kf1 Bxg3 29. hxg3 Qh8 30. Kg2 Nd8 31. Rf8 Qg7 32. Rh1 Rh6 33. Rxh6 Qxh6 34. Qf6 Qxf6 35. Rxf6 d6 36. Kf3 b5 37. g4 Kd7 38. Rh6 1-0 "

; sample game 731
EventSites(731) = "USA-ch  Saint Louis" : GameDates(731) = "20160421" : WhitePlayers(731) = "Nakamura, Hikaru   G#731" : WhiteElos(731) = "2787" : BlackPlayers(731) = "Akobian, Varuzhan   G#731" : BlackElos(731) = "2615" : Each_Game_Result(731) = "1-0"

FilePGNs(731) = "1. e4 e5  2. Nf3 Nf6 3. Nxe5 d6 4. Nf3 Nxe4 5. d4 d5 6. Bd3 Be7 7. O-O Nc6 8. c4 Nb4 9. Be2 O-O 10. Nc3 Bf5 11. a3 Nxc3 12. bxc3 Nc6 13. Re1 Re8 14. Ra2  Na5 15. cxd5 Qxd5 16. Rb2 c6 17. Ne5 Bxa3 18. Bf3 Qd6 19. Rbe2 Bxc1 20. Qxc1 Be6 21. Be4   Rad8 22. Qb1 g6 23. f4  c5  24. f5 cxd4  25. fxe6 Rxe6 26. Nxf7 Kxf7 27. Bd5  Qxd5 28. Rxe6 dxc3  29. R6e5 Qd4+ 30. Kh1 b6 31. Qa2+ Kg7 32. Re7+ Kh6 33. Qf7 Nc4 34. Qxh7+ Kg5 35. R7e6 Qd3 36. h4+ Kf4 37. Qh6+ 1-0 "

; sample game 732
EventSites(732) = "Norway Chess 4th  Stavanger" : GameDates(732) = "20160427" : WhitePlayers(732) = "Carlsen, Magnus   G#732" : WhiteElos(732) = "2851" : BlackPlayers(732) = "Kramnik, Vladimir   G#732" : BlackElos(732) = "2801" : Each_Game_Result(732) = "1-0"

FilePGNs(732) = "1. d4 d5 2. c4 e6 3. Nc3 Nf6 4. cxd5 exd5 5. Bg5 c6 6. e3 Bf5 7. Qf3 Bg6 8. Bxf6 Qxf6 9. Qxf6 gxf6 10. Nf3 Nd7 11. Nh4 Be7 12. Ne2   Nb6 13. Ng3  Bb4+ 14. Kd1 Na4 15. Ngf5  Kd7 16. Rb1 Ke6  17. Bd3 Rhc8 18. Ke2 Bf8 19. g4 c5  20. Ng2   cxd4 21. exd4 Bd6 22. h4 h5  23. Ng7+ Ke7 24. gxh5 Bxd3+ 25. Kxd3  Kd7 26. Ne3 Nb6 27. Ng4  Rh8 28. Rhe1 Be7 29. Nf5 Bd8 30. h6 Rc8 31. b3 Rc6 32. Nge3 Bc7 33. Rbc1 Rxc1 34. Rxc1 Bf4 35. Rc5 Ke6 36. Ng7+ Kd6 37. Ng4 Nd7 38. Rc2 f5 39. Nxf5+ Ke6 40. Ng7+ Kd6 41. Re2 Kc6 42. Re8 Rxe8 43. Nxe8 Nf8 44. Ne5+ Bxe5 45. dxe5 Kd7 46. Nf6+ Ke6 47. h5 Kxe5 48. Nd7+ Nxd7 49. h7 Nc5+ 50. Ke2 1-0 "

; sample game 733
EventSites(733) = "EU-ch 17th  Gjakova" : GameDates(733) = "20160513" : WhitePlayers(733) = "Inarkiev, Ernesto   G#733" : WhiteElos(733) = "2686" : BlackPlayers(733) = "Svetushkin, Dmitry   G#733" : BlackElos(733) = "2575" : Each_Game_Result(733) = "1-0"

FilePGNs(733) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. d3 b5 7. Bb3 O-O 8. Nc3 Bb7 9. a3 d6 10. Ba2  Qd7 11. Ng5   Nd4 12. f4 c5 13. Ne2 Rae8 14. Ng3 exf4 15. Bxf4 Bd8 16. Qd2  d5 17. c3 Nc6 18. exd5  Nxd5 19. N5e4 Nxf4  20. Qxf4 Ne5  21. Rad1 g6  22. d4  cxd4 23. Rxd4 Qe7 24. Rxd8  Rxd8 25. Nf6+ Kg7 26. Qg5  Qc5+ 27. Kh1 Nd3 28. Nfh5+  Kg8 29. Qf6 Nf2+ 30. Rxf2 Rd1+ 31. Nf1 gxh5 32. Bxf7+ Rxf7 33. Qxf7+ Kh8 34. Qe8+ Kg7 35. Rf7+ Kh6 36. Qe6+ 1-0 "

; sample game 734
EventSites(734) = "EU-ch 17th  Gjakova" : GameDates(734) = "20160517" : WhitePlayers(734) = "Sanikidze, Tornike   G#734" : WhiteElos(734) = "2537" : BlackPlayers(734) = "Nisipeanu, Liviu Dieter   G#734" : BlackElos(734) = "2669" : Each_Game_Result(734) = "0-1"

FilePGNs(734) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 dxc4 5. e4 Bb4 6. Bxc4 Nxe4 7. O-O Nxc3 8. bxc3 Be7 9. Ne5 O-O 10. Qg4 Nc6 11. Bh6 Bf6 12. Rfe1  Ne7 13. Rad1 c5  14. Rd3  b5  15. Bxb5 cxd4 16. Rh3  Nf5  17. Bd3 dxc3  18. Nc6 Qc7 19. Bf4  Qxc6 20. Be4 Qc4 21. Bxa8 e5 22. Be4 Nh6 23. Qf3 exf4 24. Rxh6 gxh6 25. Qxf4 Re8   26. Re3 Qd4 27. h4 c2 28. Rg3+ Bg7 29. Bxh7+ Kxh7 0-1 "

; sample game 735
EventSites(735) = "EU-ch 17th  Gjakova" : GameDates(735) = "20160519" : WhitePlayers(735) = "Nisipeanu, Liviu Dieter   G#735" : WhiteElos(735) = "2669" : BlackPlayers(735) = "Kozul, Zdenko   G#735" : BlackElos(735) = "2591" : Each_Game_Result(735) = "1-0"

FilePGNs(735) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 Nc6 6. Bg5 e6 7. Qd2 a6 8. O-O-O Bd7 9. f3 b5 10. Kb1 Be7 11. Be3 Rb8 12. g4 h6 13. Nxc6 Bxc6 14. Ne2 Nd7 15. Nd4 Ba8 16. h4 Ne5 17. b3  O-O  18. Rg1  Bxh4 19. g5  hxg5 20. Bxg5 Bxg5 21. Rxg5 Qf6 22. Bh3 Rfe8 23. Rdg1 Ng6 24. Bf5  exf5 25. exf5 Ne7 26. Rxg7+ Kf8 27. Qh2 Nd5 28. Rxf7+  Qxf7 29. Qxd6+ Re7 30. Qxb8+ Qe8 31. Qd6 1-0 "

; sample game 736
EventSites(736) = "EU-ch (Women) 17th  Mamaia" : GameDates(736) = "20160528" : WhitePlayers(736) = "Matnadze, Ana   G#736" : WhiteElos(736) = "2332" : BlackPlayers(736) = "Ushenina, Anna   G#736" : BlackElos(736) = "2450" : Each_Game_Result(736) = "1/2-1/2"

FilePGNs(736) = "1. d4 Nf6 2. Nf3 g6 3. g3 Bg7 4. Bg2 O-O 5. c4 d6 6. O-O Nc6 7. Nc3 e5 8. dxe5 dxe5 9. Bg5 Be6 10. Qa4 Qc8 11. Rfd1 Nd7 12. Nd5 e4 13. Nd2 Nb6 14. Qxc6 Bxd5 15. Qc5 Bc6 16. Nxe4 Na4 17. Qe7 Nxb2 18. Nf6+ Kh8 19. Rd4 Qf5  20. Rh4 h5 21. f4 Qe6  22. Qxe6 fxe6 23. Bxc6 Bxf6 24. Bxf6+ Rxf6 25. Bxb7 Rd8 26. Rc1 c5 27. Bf3 Kg7 28. Rc2 Nd1 29. e4 Ne3  30. Rc3 Nd1 31. Rc1  Nb2 32. Rc2 Nd1 33. Rc1 1/2-1/2 "

; sample game 737
EventSites(737) = "Asian Continental op 15th  Tashkent" : GameDates(737) = "20160603" : WhitePlayers(737) = "Le, Quang Liem   G#737" : WhiteElos(737) = "2718" : BlackPlayers(737) = "Ganguly, Surya Shekhar   G#737" : BlackElos(737) = "2654" : Each_Game_Result(737) = "0-1"

FilePGNs(737) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 c6 5. e3 Nbd7 6. Qc2 Bd6 7. Bd3 O-O 8. O-O dxc4 9. Bxc4 b5 10. Be2 Qe7 11. a3 a6 12. Ng5  Bb7 13. Bf3 Rfc8 14. Bd2 h6 15. Nge4 Nxe4 16. Bxe4 Nf6  17. Rfd1 c5 18. Bxb7 Qxb7 19. Be1 cxd4 20. Rxd4 Be5 21. Rd3 Ne4 22. Rc1 a5 23. Qd1 Nc5 24. Rd2 a4 25. Rcc2 Bf6  26. Qf3 b4 27. axb4  Qxb4 28. Nd1  Nd3  29. Rxc8+ Rxc8 30. Qe2 Nxe1 31. Qxe1 Rc1 32. g3 Qb3 33. Qe2 Bxb2 34. Rxb2 Qxd1+ 35. Qxd1 Rxd1+ 36. Kg2 Rd8  37. Ra2 Ra8 38. Kf3 g5 39. Ke4 g4  40. Kf4 h5 41. Kg5 Ra5+ 42. Kh6 Kf8 43. e4 Ke7 44. e5 f5  45. Kg7 a3 46. Kg6 Kd7 47. Kf6 Ra6 48. Kf7 Ra5 49. Kf6 Ra4  50. Kf7 f4 51. Kf6 f3  52. Kf7 Ra6 53. Kf6 Ra5 54. Kf7 Ra8 55. Kf6 Kc6 56. Kxe6 Kc5 57. Kf7 Kb4 58. Ra1 a2 59. Kg6 Kb3 60. Kxh5 Rg8  61. Rd1 Kc2 62. Re1 Kb2 63. e6 a1=Q 64. Rxa1 Kxa1 65. e7 Kb2 66. e8=Q Rxe8 67. Kxg4 Kc3 68. Kxf3 Kd4 69. Kf4 Rf8+ 70. Kg5 Rxf2 71. h4 Ke5 72. h5 Ke6 73. g4 Kf7 74. Kh6 Rg2 75. g5 Rg1 76. g6+ Kg8 77. g7 Ra1 0-1 "

; sample game 738
EventSites(738) = "Edmonton 11th  Edmonton" : GameDates(738) = "20160619" : WhitePlayers(738) = "Ganguly, Surya Shekhar   G#738" : WhiteElos(738) = "2654" : BlackPlayers(738) = "Sethuraman, SP.   G#738" : BlackElos(738) = "2653" : Each_Game_Result(738) = "1-0"

FilePGNs(738) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Nf3 e6 5. Be2 Ne7 6. O-O h6 7. Nbd2 Nd7 8. Nb3 g5 9. a4 Bg7 10. a5 O-O 11. Re1 Ng6 12. Bd3 Bxd3 13. Qxd3 g4  14. Nfd2 Rc8 15. Qe2  c5  16. Qxg4  c4 17. Nc5 Nxc5 18. dxc5 Rxc5 19. Nf3  d4  20. Qh5 Rxa5 21. Bxh6 Rxa1 22. Rxa1 Qd5 23. Qg5 Qd8 24. Qh5 Qd5 25. h4  Nxe5 26. Nxe5 Bxh6 27. Qxh6 Qxe5 28. Ra3  c3 29. bxc3 dxc3 30. Ra4  Qg7 31. Qh5  f5 32. Rxa7 Rd8 33. Qf3  Qg4 34. Qxg4+ fxg4 35. Rxb7 Rd2 36. Rb4  g3 37. Rg4+  Kf7 38. Rxg3 Rxc2 39. Rf3+  Kg6 40. g4 Rc1+ 41. Kg2 e5 42. Rd3  e4 43. Rd6+ Kg7 44. Rc6 c2 45. h5 Kh7 46. Kh2 Kh8 47. Rc7 Kg8 48. g5 Kh8 49. Rc8+ Kg7 50. h6+ Kg6 51. Rc6+ Kh7 52. Rc7+ 1-0 "

; sample game 739
EventSites(739) = "Edmonton 11th  Edmonton" : GameDates(739) = "20160626" : WhitePlayers(739) = "Ganguly, Surya Shekhar   G#739" : WhiteElos(739) = "2654" : BlackPlayers(739) = "Shirov, Alexei   G#739" : BlackElos(739) = "2682" : Each_Game_Result(739) = "1-0"

FilePGNs(739) = "1. e4 c5 2. Nf3 Nc6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 e5 6. Ndb5 d6 7. Bg5 a6 8. Na3 b5 9. Nd5 Be7 10. Bxf6 Bxf6 11. c3 Bg5 12. Nc2 Rb8 13. a4 bxa4 14. Ncb4 Nxb4 15. cxb4 O-O 16. Rxa4 a5 17. h4 Bh6 18. b5 Bd7 19. Nc3 d5 20. exd5 e4  21. Be2 f5 22. d6  Kh8 23. g3  f4  24. Rxe4 Bf5 25. Re5 Qf6 26. Qd5 fxg3 27. fxg3 Qg6 28. g4  Bc8 29. Ne4 Bb7 30. h5  Qxe4 31. Qxe4 Bxe4 32. Rxe4 Rfd8 33. Rd4 Bc1 34. d7 Bxb2 35. Rd5 Rb7 36. O-O  g6 37. h6 Ba3 38. Rf7 a4 39. Re5  Rbb8 40. Bc4 Bf8 41. Kg2 a3 42. Ba2 Bd6 43. Re6 Bf8 44. b6 1-0 "

; sample game 740
EventSites(740) = "Bilbao Masters 9th  Bilbao" : GameDates(740) = "20160716" : WhitePlayers(740) = "Carlsen, Magnus   G#740" : WhiteElos(740) = "2855" : BlackPlayers(740) = "So, Wesley   G#740" : BlackElos(740) = "2770" : Each_Game_Result(740) = "1-0"

FilePGNs(740) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. d3 Bc5 5. Bxc6 dxc6 6. Qe2 Qe7 7. Nbd2 Bg4 8. h3 Bh5 9. a3 Nd7 10. b4 Bd6 11. Nc4 f6 12. Ne3 a5  13. Nf5 Qf8 14. bxa5 Rxa5 15. O-O Qf7 16. a4 Nc5 17. Qe1 b6 18. Nd2 Rxa4 19. Nc4 Bf8  20. Be3 Kd7 21. Qc3 Nxe4 22. Nxb6+ cxb6 23. dxe4 Qc4 24. Qd2+ Kc7 25. g4 Bg6 26. Rfd1 1-0 "

; sample game 741
EventSites(741) = "Dortmund 44th  Dortmund" : GameDates(741) = "20160716" : WhitePlayers(741) = "Caruana, Fabiano   G#741" : WhiteElos(741) = "2810" : BlackPlayers(741) = "Buhmann, Rainer   G#741" : BlackElos(741) = "2653" : Each_Game_Result(741) = "1-0"

FilePGNs(741) = "1. Nf3 d5 2. g3 c5 3. Bg2 Nc6 4. O-O e5 5. c4 d4 6. d3 Nf6 7. e3 Bd6 8. exd4 cxd4 9. Bg5 h6 10. Bxf6 Qxf6 11. Nbd2 Bc7 12. Qa4  O-O 13. b4 Bf5 14. Qb3 Rab8  15. Rfe1 a6 16. Rac1 Rfd8 17. a3 Qe7  18. b5 Na5 19. Qb4  Qf6 20. Ne4 Bxe4  21. Rxe4 axb5 22. cxb5 Qb6 23. Nxe5  Bd6 24. Qb2 Rbc8 25. a4 Rxc1+ 26. Qxc1 Qc5 27. Qxc5 Bxc5 28. h4 h5  29. Bf3 g6 30. Rf4 1-0 "

; sample game 742
EventSites(742) = "Magas m  Magas" : GameDates(742) = "20160720" : WhitePlayers(742) = "Gelfand, Boris   G#742" : WhiteElos(742) = "2734" : BlackPlayers(742) = "Inarkiev, Ernesto   G#742" : BlackElos(742) = "2730" : Each_Game_Result(742) = "1-0"

FilePGNs(742) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Ba6 5. b3 d5 6. Bg2 Bb4+ 7. Bd2 Be7 8. cxd5 exd5 9. O-O O-O 10. Nc3 Re8 11. Ne5 Bb7 12. Bc1 Nbd7 13. Bb2 Bd6 14. f4 c5 15. e3 cxd4 16. exd4 Bb4 17. Rc1 Bxc3 18. Rxc3 Ne4 19. Rc2 Nf8  20. Qh5 g6 21. Qh6 f6 22. Bxe4 fxe5 23. f5  Re7 24. Bg2 e4 25. Ba3 Rf7 26. fxg6 Rxf1+ 27. Bxf1 Nxg6 28. Rf2 Qd7 29. Bh3 Qc6 30. Be7  e3 31. Rf6 Qc1+ 32. Rf1 Qc6 33. Bf6 1-0 "

; sample game 743
EventSites(743) = "Lake Sevan  Martuni" : GameDates(743) = "20160723" : WhitePlayers(743) = "Vidit, Santosh Gujrathi   G#743" : WhiteElos(743) = "2658" : BlackPlayers(743) = "Onischuk, Vladimir   G#743" : BlackElos(743) = "2612" : Each_Game_Result(743) = "1-0"

FilePGNs(743) = "1. d4 d6 2. Nf3 g6 3. g3 Bg7 4. Bg2 Nf6 5. O-O O-O 6. c4 Nc6 7. Nc3 e5 8. dxe5 dxe5 9. Bg5 Be6 10. Nd2 h6 11. Bxf6 Bxf6 12. Nde4 Be7 13. Qc1 Kg7 14. Rd1 Qe8 15. Nd5 Rc8 16. Nxe7  Qxe7 17. Nc3 Bxc4 18. b3  Ba6 19. Bxc6 bxc6 20. Qe3 Ra8 21. Rac1  Rfe8 22. Rc2 Bc8 23. Ne4 Bf5 24. Rxc6 Rad8 25. Rdc1 Qb4 26. R6c4 Qb6 27. Nc5 Rd5 28. Qc3  Qd6 29. e4  Rd1+ 30. Kg2 Bg4 31. Rxd1 Qxd1 32. Qd3  Rd8 33. Qxd1 Bxd1  34. Ra4  g5 35. h3 h5 36. g4 h4  37. Rxa7 Be2 38. Rxc7 Rd1 39. Nd7  Bf1+ 40. Kh2 Rd2 41. Nxe5 Kf6 42. Nxf7 Rxa2 43. e5+ Kg6 44. Nh8+ Kh6 45. Nf7+ Kg6 46. Nd6 Re2 47. Rc1 1-0 "

; sample game 744
EventSites(744) = "Biel Masters m 49th  Biel" : GameDates(744) = "20160728" : WhitePlayers(744) = "Svidler, Peter   G#744" : WhiteElos(744) = "2759" : BlackPlayers(744) = "Vachier Lagrave, Maxime   G#744" : BlackElos(744) = "2798" : Each_Game_Result(744) = "0-1"

FilePGNs(744) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. h3 e6 7. g4 h6 8. Bg2 Be7 9. h4 Nc6 10. g5 hxg5 11. hxg5 Rxh1+ 12. Bxh1 Nh7 13. Nxc6 bxc6 14. g6 fxg6 15. Qd3 e5 16. Qc4 Bd7 17. Bd2  Bg5  18. O-O-O Qf6 19. Na4 Rb8 20. Bxg5 Qxg5+ 21. Kb1 Nf6 22. a3  Qh4 23. Qd3 d5 24. Nc5 d4 25. Qxa6 Qxf2 26. Rf1  Qg3 27. Bf3 Qh3  28. Rh1  Qxf3 29. Rh8+ Ke7 30. Rxb8 Nxe4  31. Nxd7  Nd2+  32. Ka2 Qd5+  33. b3 Qh1 34. a4 Qb1+ 35. Ka3 Qa1+ 36. Kb4 Qc3+ 37. Ka3 Nb1+ 0-1 "

; sample game 745
EventSites(745) = "Sinquefield Cup 4th  Saint Louis" : GameDates(745) = "20160811" : WhitePlayers(745) = "So, Wesley   G#745" : WhiteElos(745) = "2771" : BlackPlayers(745) = "Topalov, Veselin   G#745" : BlackElos(745) = "2761" : Each_Game_Result(745) = "1-0"

FilePGNs(745) = "1. c4 e5 2. g3 Nf6 3. Bg2 d5 4. cxd5 Nxd5 5. Nc3 Nb6 6. Nf3 Nc6 7. O-O Be7 8. d3 O-O 9. a3 Be6 10. Be3 Nd5 11. Nxd5 Bxd5 12. Qa4 Re8 13. Rac1 a6 14. Nd2 Bxg2 15. Kxg2 Nd4  16. Bxd4 exd4 17. Qb3 Rb8 18. e4  dxe3 19. fxe3 Rf8 20. Ne4 Qd7 21. Rf3 Rbd8  22. d4 c6 23. Rcf1 Qd5 24. Qc2  g6 25. g4 Rde8  26. h3 Bd8 27. Nc3 Qe6 28. Na4 b6 29. Rc1 c5 30. dxc5 b5 31. Nc3 Qc6 32. Qd2 Re5  33. b4 Bg5 34. Rd1  Bxe3  35. Qd7  Qa8  36. Nd5 Bg5 37. c6 Bh4 38. Rd2 Re1 39. Rc2  Kg7 40. Nb6 Qb8 41. Qd4+ 1-0 "

; sample game 746
EventSites(746) = "Abu Dhabi op 23rd  Abu Dhabi" : GameDates(746) = "20160825" : WhitePlayers(746) = "Mekhitarian, Krikor Sevag   G#746" : WhiteElos(746) = "2550" : BlackPlayers(746) = "Eggleston, David   G#746" : BlackElos(746) = "2384" : Each_Game_Result(746) = "1-0"

FilePGNs(746) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. a3 Bb7 5. Nc3 d5 6. cxd5 exd5 7. Qc2  Be7 8. Bf4 a6 9. e3 O-O 10. Bd3 Nbd7 11. O-O Re8  12. Rad1 Nf8 13. Rfe1 Ng6 14. Be5 Bd6 15. e4  dxe4 16. Nxe4 Nd5  17. Nxd6  cxd6 18. Bg3 Rxe1+  19. Rxe1 Qf6 20. Be4  Re8 21. Bxd5  Rxe1+ 22. Nxe1 Bxd5 23. Qc8+ Nf8 24. Qb8 Qe7  25. Nf3 Qb7  26. Qd8 Qd7 27. Qxb6 Qf5 28. h4 h6 29. Qd8  Qb1+ 30. Kh2 Qf1 31. Qxd6  Bxf3 32. gxf3 Ne6 33. Qb8+  Kh7 34. Qe5 Qd1 35. Qe4+  Kg8 36. d5 Nd4 37. Kg2 Nc2 38. d6 Ne1+ 39. Kh3 Nxf3 40. Qe8+ Kh7 41. Qxf7 Qf1+ 42. Kg4 Ng1 43. d7 Qd1+ 44. f3 Qd4+ 45. Bf4 Qd1 46. Be5  h5+ 47. Qxh5+ Kg8 48. Qe8+ Kh7 49. Qf7 Qa4+ 50. b4 1-0 "

; sample game 747
EventSites(747) = "Baku ol (Men) 42nd  Baku" : GameDates(747) = "20160905" : WhitePlayers(747) = "Kasimdzhanov, Rustam   G#747" : WhiteElos(747) = "2696" : BlackPlayers(747) = "Peralta, Fernando   G#747" : BlackElos(747) = "2590" : Each_Game_Result(747) = "1-0"

FilePGNs(747) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Nf3 e6 5. Be2 Ne7 6. O-O h6 7. Nc3 Nd7 8. Nh4 Bh7 9. f4 Nf5 10. Nxf5 Bxf5 11. g4 Bh7 12. f5 Qh4 13. Bf4 O-O-O 14. Bg3 Qg5  15. h4 Qe7 16. Bd3 h5 17. gxh5  Bxf5 18. Bxf5 exf5 19. Rxf5 g6 20. hxg6 fxg6 21. Rg5 Bh6 22. Rxg6 Rdg8 23. Qg4 Be3+ 24. Kg2 Rxg6 25. Qxg6 Bxd4 26. Re1  Nc5  27. Qg4+  Ne6 28. Rf1 Rh6 29. Rf5 Qd7 30. h5 Be3 31. Ne2 d4 32. Rf6 Rxf6 33. exf6 Nf4+ 34. Kf3 Nxe2 35. Qg8+ Qd8 36. f7 Bh6 37. Bh4 1-0 "

; sample game 748
EventSites(748) = "Baku ol (Men) 42nd  Baku" : GameDates(748) = "20160906" : WhitePlayers(748) = "Nguyen, Anh Khoi   G#748" : WhiteElos(748) = "2448" : BlackPlayers(748) = "Jones, Gawain C   G#748" : BlackElos(748) = "2635" : Each_Game_Result(748) = "0-1"

FilePGNs(748) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. h3 e5 7. d5 Na6 8. Be3 Nc5 9. Nd2 Nh5  10. b4 Na6 11. a3 Qe8 12. c5 f5 13. cxd6 cxd6 14. Nb5 f4 15. Nxd6  fxe3  16. Nxe8 exf2+ 17. Ke2 Ng3+ 18. Kd3 Rxe8 19. Kc2 Bd7 20. Bc4 Ba4+  21. Bb3 Bb5 22. Kb2 Be2 23. Qb1  Bh6 24. Nf3 Kh8  25. Ka2  Rac8  26. Qb2  Nxe4  27. Raf1 Bxf1 28. Rxf1 Nc3+ 29. Ka1 e4 30. Qxf2 exf3 31. Qxf3 Bg7 32. d6 Re2 0-1 "

; sample game 749
EventSites(749) = "Baku ol (Men) 42nd  Baku" : GameDates(749) = "20160908" : WhitePlayers(749) = "L'Ami, Erwin   G#749" : WhiteElos(749) = "2611" : BlackPlayers(749) = "Adhiban, Baskaran   G#749" : BlackElos(749) = "2671" : Each_Game_Result(749) = "0-1"

FilePGNs(749) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Qc2 Nc6  5. Nf3 d6 6. Bd2 Qe7 7. a3 Bxc3 8. Bxc3 a5 9. e3 O-O 10. Bd3 h6 11. O-O e5 12. d5 Nb8 13. Nd2 a4  14. f4 Nbd7 15. Rae1 Re8 16. Bf5 c6  17. dxc6 bxc6 18. Ne4 Nxe4 19. Bxe4 Ra6  20. Rd1  Nf6 21. Bf3 c5 22. Rxd6 Rxd6 23. fxe5 Rd7  24. exf6 Qxe3+ 25. Kh1 Qd3 26. Qxd3 Rxd3 27. fxg7 Ba6  28. Bc6 Re2 29. Bd5 Re7 30. Bf6 Re8 31. Rc1  Re2 32. Kg1 Red2  33. Bf3 Re3 34. Bc3 Rd6 35. Bd5 Re7 36. Rd1  Bxc4  37. Bf3 Rxd1+ 38. Bxd1 Bb5 39. Kf2 Re6 40. Bf3 Bc6 41. Bg4 Rd6 42. Be5 Rd2+ 43. Ke3 Rxg2 44. h3 h5  45. Bd1 h4 46. Kf4 Bd7 47. Bf3 Rg1 48. Bf6 Rf1 49. Ke3 Bxh3 50. Bxh4 Kxg7 51. Bc6 Rb1 52. Bxa4 Rxb2 53. Be7 c4 54. Bb4 Kg6 55. Kd4 Be6 56. Kc3 Ra2 57. Bc6 f5 58. a4 f4 59. a5 Kf5 60. a6 Ke5 61. Bb7 Bd5 62. Bc5 f3 63. Bd4+ Kd6 64. Bxd5 Kxd5 65. a7 Kc6 66. Kxc4 Kb7 0-1 "

; sample game 750
EventSites(750) = "Baku ol (Men) 42nd  Baku" : GameDates(750) = "20160908" : WhitePlayers(750) = "Carlsen, Magnus   G#750" : WhiteElos(750) = "2857" : BlackPlayers(750) = "Sadorra, Julio Catalino   G#750" : BlackElos(750) = "2560" : Each_Game_Result(750) = "1/2-1/2"

FilePGNs(750) = "1. e4 e6 2. Nf3 d5 3. exd5  exd5 4. d4 Bd6 5. c4 Nf6 6. c5  Be7 7. Nc3 O-O 8. Be3  b6 9. b4 a5 10. a3 Ng4  11. Bf4 Re8  12. Be2 axb4 13. axb4 Rxa1 14. Qxa1 bxc5 15. bxc5 Bxc5  16. dxc5 d4 17. O-O dxc3 18. Bc4  c2  19. Qa4 Bf5 20. Nd4 Bg6 21. Nxc2 Re4 22. Bg3 Ne5 23. Bxe5 Rxe5 24. Ne3  Rxc5 25. f4 h6 26. Qb4 Nd7  27. f5 Bh5 28. Qd2 Qg5 29. Qd4 Re5 30. Qxd7 Qxe3+ 31. Kh1 Qc5 32. Qd3 Re3 33. Qc2 Qe5 34. Qd2  Kh7 35. h3 Qe4 36. Kg1 c6  37. Rc1  Qe5 38. Bf1 Rg3 39. Qf2 Qd6 40. Rc4 f6 41. Rxc6 Qxc6 1/2-1/2 "

; sample game 751
EventSites(751) = "Baku ol (Men) 42nd  Baku" : GameDates(751) = "20160909" : WhitePlayers(751) = "Jobava, Baadur   G#751" : WhiteElos(751) = "2665" : BlackPlayers(751) = "Lupulescu, Constantin   G#751" : BlackElos(751) = "2618" : Each_Game_Result(751) = "1-0"

FilePGNs(751) = "1. d4 d5 2. Nc3 c5  3. dxc5 Nf6 4. e4  d4 5. Bc4 Nc6 6. Nd5  Nxe4 7. Bf4 e5 8. Qe2 Bf5 9. f3 exf4 10. fxe4 Be6 11. O-O-O Bxc5 12. Nxf4 Qg5 13. g3 Bxc4 14. Qxc4 Bd6 15. Kb1  Bxf4 16. Nh3 Qg4 17. Nxf4 O-O 18. Qb5 Rab8 19. Rde1 Rfe8  20. a3 Re5 21. Qb3 Na5 22. Qd3 Nc6 23. Re2 Rbe8 24. Rhe1 Qd7 25. Nd5 Qg4 26. Ka2 h6 27. Kb1 Kh8 28. Nc7 R8e7 29. Nd5 Re8 30. Nf4 Qd7 31. Qd2 Qg4 32. Qd3 Qd7 33. h3 Rc5 34. Nd5 Qxh3 35. Qd2 Qg4 36. Rh2 Kg8  37. b4  Rc4  38. Rxh6   Ne5 39. Reh1 Ng6 40. Rh7  Qxe4  41. Rxg7+  Kf8 42. Rg8+  Kxg8 43. Nf6+ Kg7 44. Nxe4 Rxe4 45. Qd3 1-0 "

; sample game 752
EventSites(752) = "Baku ol (Men) 42nd  Baku" : GameDates(752) = "20160910" : WhitePlayers(752) = "Vallejo Pons, Francisco   G#752" : WhiteElos(752) = "2716" : BlackPlayers(752) = "Sadorra, Julio Catalino   G#752" : BlackElos(752) = "2560" : Each_Game_Result(752) = "1-0"

FilePGNs(752) = "1. e4 e6 2. d4 d5 3. Nd2 Be7 4. c3 c5 5. dxc5 Bxc5 6. Bd3 Nc6  7. Ngf3 Nf6 8. O-O O-O 9. e5 Nd7 10. Nb3 Bb6 11. Re1 f6 12. exf6 Nxf6 13. Nbd4 Qd6 14. Be3 Ng4  15. Bxh7+ Kh8 16. Bc2 e5 17. Nxc6 Nxe3 18. Rxe3 Bxe3 19. Ncxe5 Bxf2+ 20. Kh1 Bf5 21. Bxf5 Rxf5 22. Qc2 Raf8 23. Qxf2 Qxe5 24. Nxe5 Rxf2 25. Ng6+ Kg8 26. Nxf8 Kxf8 27. Rb1 g5  28. h3 Ke7 29. Kh2 b5 30. Kg3 Rd2 31. Kf3 Kf6 32. a3 a5  33. g3 b4  34. cxb4 axb4 35. a4  Ke5 36. a5 Kd6 37. Kg4 Rd3 38. Rc1   Re3 39. a6 Re8 40. Kxg5 d4 41. h4 Kd5 42. h5 d3 43. h6 Kd4 44. h7 d2 45. Rd1 Kd3 46. g4 Kc2 47. Rxd2+ Kxd2 48. Kf6 Ra8 49. a7 1-0 "

; sample game 753
EventSites(753) = "Baku ol (Men) 42nd  Baku" : GameDates(753) = "20160911" : WhitePlayers(753) = "Ipatov, Alexander   G#753" : WhiteElos(753) = "2652" : BlackPlayers(753) = "Banikas, Hristos   G#753" : BlackElos(753) = "2571" : Each_Game_Result(753) = "1/2-1/2"

FilePGNs(753) = "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7 4. e4 d6 5. Nf3 O-O 6. Be2 e5 7. O-O Na6 8. Be3 Qe7 9. c5  exd4 10. cxd6 cxd6 11. Bxd4 Nc5 12. Re1 Ncxe4 13. Bc4 Nxc3 14. Rxe7 Nxd1 15. Rxd1  d5 16. Bb3 a5  17. Ba4  Bg4  18. Rxb7 Rfb8 19. Rc7 Rc8 20. Rxc8+ Rxc8 21. Kf1 Ne4 22. Bxg7 Kxg7 23. Rxd5 Nc5  24. Rd4 Bf5 25. Bd1 Bb1  26. a3 Rb8 27. Rd5 Ne4 28. b4 axb4 29. axb4 Rxb4 30. Be2 Ba2 31. Rb5 Rxb5 32. Bxb5 Bd5 1/2-1/2 "

; sample game 754
EventSites(754) = "Baku ol (Men) 42nd  Baku" : GameDates(754) = "20160911" : WhitePlayers(754) = "Postny, Evgeny   G#754" : WhiteElos(754) = "2619" : BlackPlayers(754) = "Cori Tello, Jorge Moise   G#754" : BlackElos(754) = "2609" : Each_Game_Result(754) = "0-1"

FilePGNs(754) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Bb7 5. Bg2 Bb4+ 6. Bd2 Bxd2+ 7. Qxd2 O-O 8. Nc3 d6 9. O-O Nbd7 10. Qc2  a6 11. Rfe1 Qb8   12. e4 e5 13. Nd5 Re8 14. Rad1 Bc6 15. Qc3 Qb7 16. Nh4  b5 17. dxe5 Rxe5 18. Nf3  Ree8 19. Nd4 b4  20. Qc2 Bxd5 21. cxd5 Qb6 22. Qc6 Qa7 23. Qc4  a5 24. Nc6  Qc5  25. Qd4 Qxd4 26. Rxd4 Nc5 27. f3  Nfd7 28. Rc1 f5  29. exf5 Re2 30. Rb1 Rc2  31. Bf1 Re8 32. f4  Nf6 33. Nxa5 Ng4 34. Bg2 h5  35. Rxb4  Ree2 36. Bf1 Rxh2  37. Rb8+ Kf7 38. Nc6  0-1 "

; sample game 755
EventSites(755) = "Baku ol (Men) 42nd  Baku" : GameDates(755) = "20160912" : WhitePlayers(755) = "Swiercz, Dariusz   G#755" : WhiteElos(755) = "2639" : BlackPlayers(755) = "Thorfinnsson, Bragi   G#755" : BlackElos(755) = "2430" : Each_Game_Result(755) = "1-0"

FilePGNs(755) = "1. d4 Nf6 2. c4 b6 3. Nf3 Bb7 4. Nc3 d5 5. Bg5  Ne4 6. Bh4 Nxc3 7. bxc3 g6 8. cxd5 Qxd5 9. e3 Bg7 10. Bd3 Nc6 11. O-O O-O 12. e4 Qd7 13. Qe2  e5  14. d5 Ne7  15. Bb5 Qd6 16. Ba6 Bxa6 17. Qxa6 f5 18. Rfe1 g5  19. Bxg5 Ng6 20. Bc1  fxe4 21. Ba3 Qxd5 22. Bxf8 Rxf8 23. Rad1 Qc6 24. Nd2   Nf4 25. Nxe4 Qg6 26. Qf1 h5 27. Kh1 h4 28. g3 Nh5 29. Qh3 hxg3 30. fxg3 Rf3 31. Qh4 Bf8 32. Rf1 Rf4 33. Qg5 1-0 "

; sample game 756
EventSites(756) = "Baku ol (Men) 42nd  Baku" : GameDates(756) = "20160912" : WhitePlayers(756) = "Kasimdzhanov, Rustam   G#756" : WhiteElos(756) = "2696" : BlackPlayers(756) = "Nisipeanu, Liviu Dieter   G#756" : BlackElos(756) = "2687" : Each_Game_Result(756) = "1/2-1/2"

FilePGNs(756) = "1. e4 c6 2. d4 d5 3. e5 Bf5 4. Nf3 e6 5. Be2 Ne7 6. O-O c5 7. c4 Nbc6 8. dxc5 dxc4 9. Bxc4 Ng6 10. Be3 Be7 11. Nc3 O-O 12. Be2 Qb8 13. Nd2 Rd8 14. f4 Nd4 15. Nce4 Bxe4 16. Nxe4 Nf3+ 17. Bxf3 Rxd1 18. Rfxd1 Nh4  19. Be2 g5  20. Nd6 gxf4 21. Bxf4 Ng6 22. Bg3 Qc7 23. Rac1 Bh4  24. Bxh4 Nxh4 25. Bh5 Rf8 26. b4 Qc6 27. Rd2 Qa4 28. Rc4 Ng6 29. Bd1 Qa3 30. Bb3 Nxe5 31. Re4 Qc1+ 32. Rd1 Qg5 33. Rf1 b6 34. h4  Qg3 35. Nxf7  Nxf7 1/2-1/2 "

; sample game 757
EventSites(757) = "Baku ol (Men) 42nd  Baku" : GameDates(757) = "20160912" : WhitePlayers(757) = "Carlsen, Magnus   G#757" : WhiteElos(757) = "2857" : BlackPlayers(757) = "Ghaem Maghami, Ehsan   G#757" : BlackElos(757) = "2566" : Each_Game_Result(757) = "1-0"

FilePGNs(757) = "1. d4 d5 2. Nf3 Nf6 3. Bf4 e6 4. e3 Bd6 5. Bg3 c5 6. c3 Nc6 7. Nbd2 Bxg3  8. hxg3 Qd6 9. Bb5 Bd7 10. Bxc6 Bxc6 11. Ne5 Qc7 12. Qf3 h6 13. Qf4 Qe7 14. g4 Nh7 15. Qg3 Rg8  16. O-O  Nf6 17. Rac1 Rc8 18. c4  dxc4 19. dxc5 Qxc5 20. Ndxc4 Ke7 21. b4  Qxb4 22. Nd3 Ne4 23. Nxb4 Nxg3 24. fxg3 Bb5  25. Rxf7+  Kxf7 26. Nd6+ Ke7 27. Nxc8+ Kd7 28. Nxa7  Ba4 29. Nd3 1-0 "

; sample game 758
EventSites(758) = "Baku ol (Men) 42nd  Baku" : GameDates(758) = "20160912" : WhitePlayers(758) = "Jones, Gawain C   G#758" : WhiteElos(758) = "2635" : BlackPlayers(758) = "Naiditsch, Arkadij   G#758" : BlackElos(758) = "2693" : Each_Game_Result(758) = "1-0"

FilePGNs(758) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Nf6 4. d4 exd4 5. e5 d5 6. Bb5 Ne4 7. Nxd4 Bd7 8. Bxc6 bxc6 9. O-O Be7 10. f3 Nc5 11. f4 Ne4 12. f5 c5 13. Ne2 Bb5 14. a4 Ba6 15. Nbc3 Nxc3 16. bxc3 Qd7 17. Rf2 O-O-O 18. Nf4  g5  19. Nh5 Rhg8 20. Qg4 Kb8 21. Bd2 Ka8 22. Re1 Bc4 23. a5 Rb8 24. h3  h6 25. Qf3 Qc8 26. Ng3  Re8 27. Qh5 f6 28. Qxh6 Rh8 29. Qg7 Qd8 30. Qf7 fxe5 31. f6 Bd6 32. Bxg5 Qg8 33. Qxg8 Rbxg8 34. h4 e4 35. Nf5 Be5 36. g4 Bxc3 37. Re3 Be5 38. Ne7 Rb8 39. Ng6 d4 40. Nxe5 dxe3 41. Bxe3 Rxh4 42. Nxc4 Rb1+ 43. Kg2 Rxg4+ 44. Kh3 Rg8 45. Kh2 Kb7 46. f7 Rf8 47. Bxc5 Rh8+ 48. Kg2 Rbh1 49. f8=Q 1-0 "

; sample game 759
EventSites(759) = "Baku ol (Men) 42nd  Baku" : GameDates(759) = "20160913" : WhitePlayers(759) = "Kramnik, Vladimir   G#759" : WhiteElos(759) = "2808" : BlackPlayers(759) = "Vocaturo, Daniele   G#759" : BlackElos(759) = "2583" : Each_Game_Result(759) = "1-0"

FilePGNs(759) = "1. d4 Nf6 2. Nf3 g6 3. g3 Bg7 4. Bg2 O-O 5. O-O d6 6. b3 e5 7. dxe5 dxe5 8. Ba3 Qxd1 9. Rxd1 Re8 10. c4 e4 11. Nd4 c6  12. Nc3 Na6 13. e3 Bg4 14. Rd2 Rad8 15. h3 Bc8 16. Rad1 h5 17. Be7  Rxd4  18. Rxd4 Rxe7 19. Rd8+ Ne8  20. Nxe4 Be6 21. Ra8 Be5 22. Rdd8 Kf8 23. Rxa7 Bc7 24. Rda8  Bb6  25. Rxa6 bxa6 26. Nf6  Bd7 27. b4  c5 28. Nd5  Bc6 29. Rxa6 Bxd5 30. Bxd5 Bd8 31. b5 Rd7 32. b6 Ke7 33. b7 Bc7 34. Ra8 Nf6 35. Rc8 Bd6 36. Bc6 Rd8 37. a4 Nd7 38. a5 Bb8 39. a6 Ne5 40. Rxb8 Rxb8 41. Bd5 1-0 "

; sample game 760
EventSites(760) = "Baku ol (Men) 42nd  Baku" : GameDates(760) = "20160913" : WhitePlayers(760) = "Mchedlishvili, Mikheil   G#760" : WhiteElos(760) = "2609" : BlackPlayers(760) = "Ipatov, Alexander   G#760" : BlackElos(760) = "2652" : Each_Game_Result(760) = "0-1"

FilePGNs(760) = "1. d4 d6 2. Nf3 Nf6 3. c4 g6 4. Nc3 Bf5 5. Qb3 b6 6. g3 Bg7 7. Bg2 Nc6 8. Qa4 Bd7 9. Qd1 e5 10. O-O O-O 11. d5 Ne7 12. e4 Qc8  13. Ne1 Nh5 14. Nd3 f5 15. Bg5 Nf6 16. Qd2  fxe4 17. Bxf6 e3 18. Qxe3 Bxf6 19. Ne4 Bg7 20. Qd2 Nf5 21. Rae1 Qa6  22. b3 Rae8 23. h4  Nd4 24. f4 exf4 25. Nxf4 Qa5  26. b4 Qa3  27. Re3 Qa4 28. Rd3  Nc2  29. Nc3  Qxb4 30. Qxc2 Bf5 31. Nd1 Re1 32. Qd2 Qc5+ 33. Kh2 Rxf1 34. Bxf1 Bxd3 35. Qxd3 Qa5 36. Qe2 Be5 37. Nd3 Re8 38. Qc2 Bd4  39. Bh3 Kg7 40. h5   gxh5  41. Be6 Rf8 42. Qe2 Qa4  43. Nf4 Kh8 44. Ne3 h4 45. Nf5  hxg3+ 46. Kh3 g2  47. Kxg2 Be5 48. Nh3 Rf6  49. Nf2 Rg6+ 50. Kf3  b5 51. Ne3  Rg3+  52. Ke4 bxc4 53. Qd1 Qxa2 54. Qf1 Qd2 55. Nfg4 Qd4+ 56. Kf5 Rxe3 0-1 "

; sample game 761
EventSites(761) = "Baku ol (Men) 42nd  Baku" : GameDates(761) = "20160913" : WhitePlayers(761) = "Wojtaszek, Radoslaw   G#761" : WhiteElos(761) = "2736" : BlackPlayers(761) = "Vallejo Pons, Francisco   G#761" : BlackElos(761) = "2716" : Each_Game_Result(761) = "1-0"

FilePGNs(761) = "1. d4 e6 2. c4 Nf6 3. Nf3 b6 4. g3 Bb4+ 5. Bd2 Bxd2+ 6. Qxd2 Bb7 7. Bg2 O-O 8. Nc3 Ne4 9. Qd3 f5  10. Ne5  Nc5 11. dxc5 Bxg2 12. Rg1 Bc6 13. O-O-O Qe7 14. Qd4  Na6  15. cxb6 axb6 16. g4  Nc5 17. gxf5  Rxa2  18. Kc2  Ba4+ 19. Nxa4 Nxa4  20. Nd3  c5  21. f6  Rxf6 22. Qe4  b5 23. Kb3  d5  24. Qe5 Rf5 25. Qb8+ Rf8 26. Qe5 Rf5 27. Qb8+ Rf8 28. Qe5 Qa7  29. Kxa2 Nc3+ 30. Kb3 Nxd1 31. Nxc5  dxc4+  32. Kc2 Nxf2 33. Nxe6  Rf7 34. Nxg7 Ng4 35. Ne6  h5 36. Qg5+ Kh7 37. Qxh5+ 1-0 "

; sample game 762
EventSites(762) = "Moscow Tal Memorial 10th  Moscow" : GameDates(762) = "20160927" : WhitePlayers(762) = "Gelfand, Boris   G#762" : WhiteElos(762) = "2743" : BlackPlayers(762) = "Giri, Anish   G#762" : BlackElos(762) = "2755" : Each_Game_Result(762) = "0-1"

FilePGNs(762) = "1. d4 Nf6 2. c4 g6 3. g3 Bg7 4. Bg2 O-O 5. Nc3 Nc6 6. e3 d6 7. Nge2 e5 8. O-O exd4 9. exd4 Ne7 10. Bf4 Nf5 11. Qc1 Re8 12. h3 c6 13. g4 Ne7 14. Bh6 d5 15. c5 b6 16. cxb6  axb6 17. Re1 Bh8 18. Qf4 Nd7 19. Qd2 Nf8 20. Nf4 Ne6 21. Nce2 c5  22. dxc5 bxc5 23. Nxd5  Bb7 24. Nec3 Nxd5 25. Nxd5 Bd4 26. Nc3  Bxg2 27. Kxg2 g5  28. h4 gxh4 29. Ne4 Qd5 30. f3 Rad8 31. Rad1 Kh8 32. Bg5 f5 33. Bxd8 Rxd8 34. gxf5 Qxf5 35. Kh1 Rg8 36. Rf1 Be5 0-1 "

; sample game 763
EventSites(763) = "Douglas IoM op  Douglas" : GameDates(763) = "20161003" : WhitePlayers(763) = "Marin, Mihail   G#763" : WhiteElos(763) = "2569" : BlackPlayers(763) = "Sachdev, Tania   G#763" : BlackElos(763) = "2414" : Each_Game_Result(763) = "1/2-1/2"

FilePGNs(763) = "1. d4 Nf6 2. c4 e6 3. g3 d5 4. Bg2 Be7 5. Nf3 O-O 6. O-O dxc4 7. Ne5 c5  8. dxc5 Bxc5 9. Nxc4 Nc6 10. Nc3 Qe7 11. Bg5 h6  12. Bxf6 Qxf6 13. Ne4 Qe7 14. e3 Rd8 15. Qe2 Bd7 16. Rac1 Be8 17. a3  Bb6  18. Nxb6 axb6 19. Rfd1 Na7  20. Rxd8 Rxd8 21. Rd1 Bc6 22. Rxd8+ Qxd8 23. Qd2 Qxd2 24. Nxd2 Bxg2  25. Kxg2 Kf8 26. Kf3 Ke7 27. Ke4 f5+  28. Kd3 Kd6 29. f4 Nc6 30. Kc4 e5 31. Nf3  e4 32. Nd4 Nxd4  33. Kxd4 b5 34. h3  h5 35. h4 g6 36. Kc3 Kc5 37. Kb3 Kc6 38. Kb4 Kb6 39. Kc3 Kc5 40. Kb3 Kc6 41. Kb4 Kb6 42. b3 Kc6 43. Kc3 Kc5 44. Kc2 b6 45. Kd2 b4 46. a4 Kd5 1/2-1/2 "

; sample game 764
EventSites(764) = "Bundesliga 1617  Germany" : GameDates(764) = "20161016" : WhitePlayers(764) = "Navara, David   G#764" : WhiteElos(764) = "2737" : BlackPlayers(764) = "Piorun, Kacper   G#764" : BlackElos(764) = "2665" : Each_Game_Result(764) = "1-0"

FilePGNs(764) = "1. c4 e5 2. g3 g6 3. d4 d6 4. Nc3 Bg7 5. Nf3 exd4 6. Nxd4 Ne7 7. Bg2 Nbc6 8. Nxc6 Nxc6 9. Bf4 Be6 10. Rc1 Bxc4  11. Qa4 Be6 12. Bxc6+ bxc6 13. Qxc6+ Bd7 14. Qe4+ Kf8 15. O-O h6 16. Nd5 Bf5 17. Qa4 g5  18. Be3 c5 19. Rxc5  Bd7  20. Qe4  f5 21. Qc4 dxc5 22. Bxc5+ Ke8 23. Rd1  Rc8 24. Rd3 Rc6  25. b4  Re6  26. Bxa7  Be5 27. Bc5 Qb8 28. Ra3 Qb5 29. Qc2  Bb8 30. Qxf5 Qxe2  31. Nf6+  Rxf6  32. Qxf6  Qe1+ 33. Kg2 Qe4+ 34. f3 Qe2+ 35. Bf2 Bh3+ 36. Kxh3 Qf1+ 37. Kg4 h5+ 38. Kxg5 Rg8+ 39. Kh6 Qxf2 40. Kh7 1-0 "

; sample game 765
EventSites(765) = "EU-Cup 32nd  Novi Sad" : GameDates(765) = "20161107" : WhitePlayers(765) = "Van Wely, Loek   G#765" : WhiteElos(765) = "2685" : BlackPlayers(765) = "Klein, David   G#765" : BlackElos(765) = "2513" : Each_Game_Result(765) = "1-0"

FilePGNs(765) = "1. d4 Nf6 2. c4 e6 3. Nc3 Bb4 4. Nf3 c5 5. g3 Bxc3+ 6. bxc3 Qa5 7. Qd3 b6 8. Bg2 Bb7 9. d5  O-O  10. O-O  exd5 11. cxd5 Bxd5 12. Bg5 c4 13. Qf5 Ne4 14. Be7 g6 15. Qf4 Re8  16. Bb4 Nxc3  17. Bxc3 Qxc3 18. Ng5 Qe5 19. Bxd5 Qxd5 20. e4 1-0 "

; sample game 766
EventSites(766) = "EU-Cup 32nd  Novi Sad" : GameDates(766) = "20161107" : WhitePlayers(766) = "Bluebaum, Matthias   G#766" : WhiteElos(766) = "2641" : BlackPlayers(766) = "Edouard, Romain   G#766" : BlackElos(766) = "2628" : Each_Game_Result(766) = "1-0"

FilePGNs(766) = "1. d4 d5 2. c4 dxc4 3. e4 Nf6 4. e5 Nd5 5. Bxc4 Nb6 6. Bd3 Nc6 7. Be3 Nb4 8. Be4 f5 9. a3 N4d5 10. Bxd5  Nxd5 11. Nc3  Nxc3   12. bxc3 Qd5 13. Nf3 Qc4 14. Qc2  e6 15. Nd2 Qc6 16. O-O b6 17. f3 Rg8  18. c4 g5 19. Nb3  Rg6 20. Rfc1 Qd7  21. d5 exd5 22. e6  Rxe6  23. Re1 Bg7  24. Rad1  Qe7  25. Qd2 f4  26. Bf2 Kf7  27. Qxd5 c6 28. Qd3 h6  29. c5 Rxe1+ 30. Rxe1 Be6  31. Nd4 Rd8 32. Qh7 Rh8 33. Qb1 Bxd4 34. Bxd4 Rd8  35. Qh7+ Ke8 36. Qxh6 Kd7 37. cxb6 axb6 38. Bxb6 Rf8 39. Kh1 Rf5 40. h3 c5 41. Qh8 Rd5 42. Qa8 Qd6 43. Ba5 Ke7 44. Bc7 Qd7 45. Qg8 c4 46. Qg7+ Ke8 47. Qg8+ Ke7 48. Qg7+ Ke8 49. Qg6+ Ke7 50. Be5 Rd1 51. Bf6+ Kf8 52. Qh6+ 1-0 "

; sample game 767
EventSites(767) = "EU-Cup 32nd  Novi Sad" : GameDates(767) = "20161110" : WhitePlayers(767) = "Dominguez Perez, Leinier   G#767" : WhiteElos(767) = "2752" : BlackPlayers(767) = "Andreikin, Dmitry   G#767" : BlackElos(767) = "2736" : Each_Game_Result(767) = "0-1"

FilePGNs(767) = "1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Bc5 5. Nb3 Bb6 6. Nc3 Nf6 7. Bg5 h6 8. Bh4 d6 9. f3   g5 10. Bg3 a6  11. Qd2 Qe7  12. O-O-O  Be6 13. h4  O-O-O 14. Kb1 Nd7 15. Bf2  Qf6 16. Bxb6 Nxb6 17. Qf2 Kb8 18. Be2 Rhg8 19. hxg5 hxg5 20. Nd4 Nxd4 21. Rxd4 Qe5 22. Rhd1 Rh8 23. R4d2  Rh2  24. Bf1 Rh1 25. Qe3 Rdh8 26. Be2  Qg3 27. b3 Nd7 28. Bf1 Qe5 29. Ne2 Nf6 30. Nd4  Nd5 31. Qd3 Nf4 32. Qe3 Nd5 33. Qd3 Nf4 34. Qe3 R8h2 35. g3  Nd5 36. Qd3 Nb4 37. Qe3 Nd5 38. Qd3 Nb4 39. Qe3 Qa5  40. a4 Nd5   41. exd5 Rxd2 42. Rxd2 Rxf1+ 43. Ka2  Bxd5 44. Kb2 Bxf3  45. Qd3 Be4  0-1 "

; sample game 768
EventSites(768) = "World-ch Carlsen-Karjakin +2-2=10  New York" : GameDates(768) = "20161111" : WhitePlayers(768) = "Carlsen, Magnus   G#768" : WhiteElos(768) = "2857" : BlackPlayers(768) = "Karjakin, Sergey   G#768" : BlackElos(768) = "2769" : Each_Game_Result(768) = "1/2-1/2"

FilePGNs(768) = "1. d4 Nf6 2. Bg5 d5 3. e3 c5 4. Bxf6 gxf6 5. dxc5 Nc6 6. Bb5 e6 7. c4 dxc4 8. Nd2 Bxc5 9. Ngf3 O-O 10. O-O Na5 11. Rc1 Be7 12. Qc2 Bd7 13. Bxd7 Qxd7 14. Qc3 Qd5 15. Nxc4 Nxc4 16. Qxc4 Qxc4 17. Rxc4 Rfc8 18. Rfc1 Rxc4 19. Rxc4 Rd8 20. g3 Rd7 21. Kf1 f5 22. Ke2 Bf6 23. b3 Kf8 24. h3 h6 25. Ne1 Ke7 26. Nd3 Kd8 27. f4 h5 28. a4 Rd5 29. Nc5 b6 30. Na6 Be7 31. Nb8 a5 32. Nc6+ Ke8 33. Ne5 Bc5 34. Rc3 Ke7 35. Rd3 Rxd3 36. Kxd3 f6 37. Nc6+ Kd6 38. Nd4 Kd5 39. Nb5 Kc6 40. Nd4+ Kd6 41. Nb5+ Kd7 42. Nd4 Kd6 1/2-1/2 "

; sample game 769
EventSites(769) = "World-ch Carlsen-Karjakin +2-2=10  New York" : GameDates(769) = "20161112" : WhitePlayers(769) = "Karjakin, Sergey   G#769" : WhiteElos(769) = "2769" : BlackPlayers(769) = "Carlsen, Magnus   G#769" : BlackElos(769) = "2857" : Each_Game_Result(769) = "1/2-1/2"

FilePGNs(769) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6  4. Ba4 Nf6 5. O-O Be7 6. d3 b5 7. Bb3 d6 8. a3 O-O 9. Nc3 Na5 10. Ba2 Be6 11. d4 Bxa2 12. Rxa2 Re8 13. Ra1 Nc4 14. Re1 Rc8 15. h3 h6 16. b3 Nb6 17. Bb2 Bf8 18. dxe5 dxe5 19. a4 c6 20. Qxd8 Rcxd8 21. axb5 axb5 22. Ne2 Bb4 23. Bc3 Bxc3 24. Nxc3 Nbd7 25. Ra6 Rc8 26. b4 Re6 27. Rb1 c5 28. Rxe6 fxe6 29. Nxb5 cxb4 30. Rxb4 Rxc2 31. Nd6 Rc1+ 32. Kh2 Rc2 33. Kg1 1/2-1/2 "

; sample game 770
EventSites(770) = "EU-Cup 32nd  Novi Sad" : GameDates(770) = "20161112" : WhitePlayers(770) = "Perunovic, Milos   G#770" : WhiteElos(770) = "2616" : BlackPlayers(770) = "Sasikiran, Krishnan   G#770" : BlackElos(770) = "2654" : Each_Game_Result(770) = "0-1"

FilePGNs(770) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. d3 d6 9. c3 Na5 10. Bc2 c5 11. Nbd2 Nc6 12. Nf1 Re8 13. h3 h6  14. Ne3 Be6 15. a4 Rc8  16. axb5 axb5 17. Bb3  Qd7  18. Bxe6  Qxe6  19. Ra6  Qd7  20. Nf5  Qb7 21. Ra1 Bf8 22. Nh2 Re6  23. Ng4 Ne7  24. Nxf6+ Rxf6 25. Ne3  Rd8  26. Bd2  Re6  27. Ra5  d5  28. exd5 Nxd5 29. Qf3 Qb6  30. c4  Nxe3  31. Rxb5 Nxg2  32. Rxb6 Nxe1 33. Qb7 Nf3+  34. Kf1 Nxd2+ 35. Ke2 Re7  36. Qc6 Nb1  37. f3 Red7  38. Rb3 Be7  39. Rb7  Rxb7  40. Qxb7 Bg5  41. Qb6  Rc8  42. Qb7 Rf8  43. h4 Bf4  44. Qb5 Nd2  45. h5  Rc8  46. Qb7  Re8  47. b4 e4  48. fxe4 Rb8 0-1 "

; sample game 771
EventSites(771) = "World-ch Carlsen-Karjakin +2-2=10  New York" : GameDates(771) = "20161114" : WhitePlayers(771) = "Carlsen, Magnus   G#771" : WhiteElos(771) = "2857" : BlackPlayers(771) = "Karjakin, Sergey   G#771" : BlackElos(771) = "2769" : Each_Game_Result(771) = "1/2-1/2"

FilePGNs(771) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. Re1 Nd6 6. Nxe5 Be7 7. Bf1 Nxe5 8. Rxe5 O-O 9. d4 Bf6 10. Re2 b6 11. Re1 Re8 12. Bf4  Rxe1 13. Qxe1 Qe7 14. Nc3 Bb7 15. Qxe7 Bxe7 16. a4 a6 17. g3 g5 18. Bxd6  Bxd6 19. Bg2  Bxg2 20. Kxg2 f5  21. Nd5 Kf7 22. Ne3 Kf6 23. Nc4 Bf8 24. Re1 Rd8  25. f4 gxf4 26. gxf4 b5 27. axb5 axb5 28. Ne3 c6 29. Kf3 Ra8 30. Rg1 Ra2  31. b3 c5  32. Rg8  Kf7 33. Rg2 cxd4 34. Nxf5 d3 35. cxd3 Ra1  36. Nd4 b4 37. Rg5 Rb1 38. Rf5+ Ke8 39. Rb5 Rf1+ 40. Ke4 Re1+ 41. Kf5 Rd1 42. Re5+ Kf7 43. Rd5 Rxd3 44. Rxd7+ Ke8 45. Rd5 Rh3 46. Re5+ Kf7 47. Re2 Bg7 48. Nc6  Rh5+ 49. Kg4 Rc5 50. Nd8+  Kg6 51. Ne6 h5+ 52. Kf3 Rc3+ 53. Ke4 Bf6 54. Re3 h4 55. h3  Rc1 56. Nf8+ Kf7 57. Nd7 Ke6  58. Nb6 Rd1 59. f5+ Kf7 60. Nc4 Rd4+ 61. Kf3 Bg5  62. Re4 Rd3+ 63. Kg4 Rg3+ 64. Kh5 Be7 65. Ne5+ Kf6 66. Ng4+  Kf7 67. Re6 Rxh3 68. Ne5+ Kg7 69. Rxe7+ Kf6 70. Nc6 Kxf5  71. Na5  Rh1 72. Rb7  Ra1  73. Rb5+ Kf4  74. Rxb4+ Kg3  75. Rg4+ Kf2 76. Nc4 h3 77. Rh4 Kg3 78. Rg4+ Kf2 1/2-1/2 "

; sample game 772
EventSites(772) = "World-ch Carlsen-Karjakin +2-2=10  New York" : GameDates(772) = "20161115" : WhitePlayers(772) = "Karjakin, Sergey   G#772" : WhiteElos(772) = "2769" : BlackPlayers(772) = "Carlsen, Magnus   G#772" : BlackElos(772) = "2857" : Each_Game_Result(772) = "1/2-1/2"

FilePGNs(772) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 O-O 8. h3 Bb7 9. d3 d6 10. a3 Qd7 11. Nbd2 Rfe8 12. c3 Bf8 13. Nf1 h6 14. N3h2 d5 15. Qf3 Na5 16. Ba2 dxe4 17. dxe4 Nc4 18. Bxh6 Qc6  19. Bxc4  bxc4 20. Be3 Nxe4 21. Ng3 Nd6 22. Rad1 Rab8 23. Bc1 f6 24. Qxc6 Bxc6 25. Ng4 Rb5 26. f3 f5 27. Nf2 Be7 28. f4  Bh4 29. fxe5 Bxg3 30. exd6 Rxe1+ 31. Rxe1 cxd6 32. Rd1 Kf7 33. Rd4 Re5 34. Kf1 Rd5 35. Rxd5 Bxd5 36. Bg5 Kg6 37. h4 Kh5 38. Nh3 Bf7 39. Be7 Bxh4 40. Bxd6 Bd8 41. Ke2 g5 42. Nf2 Kg6 43. g4 Bb6 44. Be5 a5 45. Nd1 f4  46. Bd4 Bc7 47. Nf2 Be6 48. Kf3 Bd5+ 49. Ke2 Bg2 50. Kd2 Kf7 51. Kc2 Bd5 52. Kd2 Bd8 53. Kc2 Ke6 54. Kd2 Kd7 55. Kc2 Kc6 56. Kd2 Kb5 57. Kc1 Ka4 58. Kc2 Bf7 59. Kc1 Bg6 60. Kd2 Kb3 61. Kc1 Bd3 62. Nh3 Ka2 63. Bc5 Be2 64. Nf2 Bf3 65. Kc2 Bc6 66. Bd4 Bd7 67. Bc5 Bc7 68. Bd4 Be6 69. Bc5 f3 70. Be3 Bd7 71. Kc1 Bc8 72. Kc2 Bd7 73. Kc1 Bf4 74. Bxf4 gxf4 75. Kc2 Be6 76. Kc1 Bc8 77. Kc2 Be6 78. Kc1 Kb3 79. Kb1 Ka4 80. Kc2 Kb5 81. Kd2 Kc6 82. Ke1 Kd5 83. Kf1 Ke5 84. Kg1 Kf6 85. Ne4+ Kg6 86. Kf2 Bxg4 87. Nd2 Be6 88. Kxf3 Kf5 89. a4 Bd5+ 90. Kf2 Kg4 91. Nf1 Kg5 92. Nd2 Kf5 93. Ke2 Kg4 94. Kf2 1/2-1/2 "

; sample game 773
EventSites(773) = "World-ch Carlsen-Karjakin +2-2=10  New York" : GameDates(773) = "20161117" : WhitePlayers(773) = "Carlsen, Magnus   G#773" : WhiteElos(773) = "2853" : BlackPlayers(773) = "Karjakin, Sergey   G#773" : BlackElos(773) = "2769" : Each_Game_Result(773) = "1/2-1/2"

FilePGNs(773) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. O-O Nf6 5. d3 O-O 6. a4 d6 7. c3 a6 8. b4 Ba7 9. Re1 Ne7 10. Nbd2 Ng6 11. d4 c6 12. h3 exd4  13. cxd4 Nxe4 14. Bxf7+  Rxf7 15. Nxe4 d5 16. Nc5 h6 17. Ra3 Bf5 18. Ne5 Nxe5 19. dxe5 Qh4 20. Rf3 Bxc5  21. bxc5 Re8 22. Rf4 Qe7 23. Qd4 Ref8 24. Rf3 Be4 25. Rxf7 Qxf7 26. f3 Bf5 27. Kh2 Be6 28. Re2 Qg6 29. Be3 Rf7 30. Rf2 Qb1 31. Rb2 Qf5 32. a5 Kf8 33. Qc3 Ke8 34. Rb4 g5  35. Rb2 Kd8 36. Rf2 Kc8 37. Qd4 Qg6 38. g4 h5 39. Qd2 Rg7 40. Kg3 Rg8 41. Kg2  hxg4 42. hxg4 d4  43. Qxd4 Bd5  44. e6 Qxe6 45. Kg3 Qe7 46. Rh2 Qf7 47. f4 gxf4+ 48. Qxf4 Qe7 49. Rh5 Rf8 50. Rh7 Rxf4 51. Rxe7 Re4 1/2-1/2 "

; sample game 774
EventSites(774) = "ROM-chT  Calimanesti Caciulata" : GameDates(774) = "20161123" : WhitePlayers(774) = "Zhigalko, Andrey   G#774" : WhiteElos(774) = "2584" : BlackPlayers(774) = "Marin, Mihail   G#774" : BlackElos(774) = "2549" : Each_Game_Result(774) = "1/2-1/2"

FilePGNs(774) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Nb8 10. d4 Nbd7 11. Nbd2 Bb7 12. Bc2 Re8 13. a4 Bf8 14. Bd3 c6 15. Qc2 Rc8 16. axb5 axb5 17. b3 g6 18. Bb2 Nh5 19. Bf1 Nf4 20. b4 Bg7 21. Qb3 Ne6 22. Rad1 Qb6  23. dxe5 Nxe5 24. c4 Rcd8 25. Nxe5 dxe5 26. Nf3 bxc4 27. Bxc4 Rxd1 28. Rxd1  Qc7 29. Qc2 h6 30. Rd2 Kh7 31. Qd1 Bc8 32. Qa1 Ng5  33. Nxg5+ hxg5 34. Qa5 Qe7 35. Qc5  Be6 36. Bxe6 Qxe6 37. Rc2 Bf8 38. Qc4 Qxc4 39. Rxc4 Re6  40. Kf1 Kg7 41. Ke2 f6 42. Bc1 Kf7 43. Be3 Ke8 44. Bc5 Bxc5 45. bxc5 Re7  46. Ra4 Rb7 47. Ra8+ Kd7 48. Rf8 Ke7 49. Rc8 Kd7 50. Rf8 1/2-1/2 "

; sample game 775
EventSites(775) = "London Classic 8th  London" : GameDates(775) = "20161209" : WhitePlayers(775) = "Kramnik, Vladimir   G#775" : WhiteElos(775) = "2809" : BlackPlayers(775) = "Topalov, Veselin   G#775" : BlackElos(775) = "2760" : Each_Game_Result(775) = "1-0"

FilePGNs(775) = "1. Nf3 d5 2. g3 g6 3. Bg2 Bg7 4. d4 Nf6 5. O-O O-O 6. c4 c5 7. dxc5 dxc4 8. Na3 c3 9. Nb5  cxb2 10. Bxb2  Bd7 11. Qb3 Bc6 12. Rfd1 Qc8  13. Rac1 Nbd7 14. Nbd4 Bd5 15. Qa3 Re8 16. c6  Nb6  17. c7 Nc4 18. Qb4 Nxb2 19. Qxb2 b6 20. Qa3  e6  21. Nb5 Bf8 22. Qb2 Bg7 23. Qd2 Qd7 24. a4 Ne4 25. Qf4 a6 26. Qxe4 axb5 27. Qd3 f5 28. Ng5 1-0 "

; sample game 776
EventSites(776) = "London Classic 8th  London" : GameDates(776) = "20161210" : WhitePlayers(776) = "So, Wesley   G#776" : WhiteElos(776) = "2794" : BlackPlayers(776) = "Adams, Michael   G#776" : BlackElos(776) = "2748" : Each_Game_Result(776) = "1-0"

FilePGNs(776) = "1. d4 Nf6 2. c4 e6 3. g3 d5 4. Bg2 Be7 5. Nf3 O-O 6. O-O dxc4 7. Qc2 a6 8. a4 Bd7 9. Qxc4 Bc6 10. Bg5 a5 11. Nc3 Ra6  12. Qd3  Rb6 13. Qc2 h6  14. Bd2 Bb4 15. Rfe1 Bxf3 16. Bxf3 Nc6 17. e3  e5 18. Bxc6  exd4 19. Bf3 dxc3 20. bxc3 Bc5  21. Rab1 Rd6 22. Red1 b6 23. c4 Qe7 24. Bc3 Rfd8 25. Bb2 Qe6 26. Rxd6 Rxd6 27. Rd1 Rxd1+ 28. Qxd1 Bd6 29. Qd4 Qe8 30. Bd1 Qc6  31. Bc2  Kf8 32. e4 Bc5 33. Qd8+ Ne8 34. Qd5 Qg6 35. Kg2 Ke7 36. f4 c6 37. Qd3 Nc7  38. f5   Qg5 39. Be5 Ne6 40. fxe6 1-0 "

; sample game 777
EventSites(777) = "London Classic 8th  London" : GameDates(777) = "20161212" : WhitePlayers(777) = "Giri, Anish   G#777" : WhiteElos(777) = "2771" : BlackPlayers(777) = "So, Wesley   G#777" : BlackElos(777) = "2794" : Each_Game_Result(777) = "1/2-1/2"

FilePGNs(777) = "1. d4 Nf6 2. Nf3 d5 3. Bf4 c5 4. e3 Nc6 5. Nbd2 e6 6. c3 cxd4  7. exd4 Nh5 8. Bg5 f6 9. Be3 Bd6 10. g3 O-O 11. Bg2 f5 12. Ne5  f4  13. Qxh5 fxe3 14. fxe3 Nxe5 15. dxe5 Bc5 16. Rf1  Bxe3 17. Rxf8+ Qxf8 18. Qf3 Qxf3 19. Nxf3 Bd7 20. Rd1 Rf8 21. c4  Bc6 22. Nd4  Bxd4 23. Rxd4 Rf5 24. g4 Rxe5+ 25. Kf2 Kf7  26. b4 Ke7 27. b5 Bd7 28. b6 dxc4 29. Rxc4 axb6 30. Rc7 Rb5 31. Rxb7 Kd6 32. Kg3 h6 33. Rb8 Rb2 34. Bf3 b5  35. a4  b4 36. a5 Rb3 37. Kg2  Bc6  38. Bxc6 Kxc6 39. a6 Ra3 40. Rxb4 Rxa6 41. h4 e5 42. Kf3 Kd5 43. Rb5+ Ke6 44. Rb7 Kf6 45. g5+ hxg5 46. hxg5+ Kg6 47. Re7 Ra5 48. Ke3 Rb5 49. Kf3 Rb3+ 50. Kf2 Rb5 51. Kf3 Rd5 52. Ke3 e4 53. Kxe4 Rxg5 54. Kf3 Kh5 55. Re1 Rg4 56. Rh1+ Kg5 1/2-1/2 "

; sample game 778
EventSites(778) = "London Classic 8th  London" : GameDates(778) = "20161213" : WhitePlayers(778) = "Adams, Michael   G#778" : WhiteElos(778) = "2748" : BlackPlayers(778) = "Topalov, Veselin   G#778" : BlackElos(778) = "2760" : Each_Game_Result(778) = "1-0"

FilePGNs(778) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. d3 Bc5 5. Bxc6 dxc6 6. Nbd2 Be6 7. O-O Bd6 8. d4 Nd7 9. Nxe5 Nxe5 10. dxe5 Bxe5 11. f4 Bd4+ 12. Kh1 f6 13. c3 Bb6 14. f5 Bf7 15. e5  fxe5 16. Qg4 Qd3 17. Qxg7 Rg8 18. Qxe5+ Kd7 19. Qe4 Qa6  20. f6 Rae8  21. Qf5+  Kd8 22. c4  Qa5 23. Qh3  Qb4 24. Qxh7  Qf8  25. b3 Bd4 26. Qd3 Qd6 27. Ne4 Qd7 28. Rd1 Kc8 29. Qxd4 Qg4 30. Bg5  Rxe4 31. Qxa7 Bd5 32. Qa8+ Kd7 33. Rxd5+ 1-0 "

; sample game 779
EventSites(779) = "London Classic 8th  London" : GameDates(779) = "20161215" : WhitePlayers(779) = "Caruana, Fabiano   G#779" : WhiteElos(779) = "2823" : BlackPlayers(779) = "Nakamura, Hikaru   G#779" : BlackElos(779) = "2779" : Each_Game_Result(779) = "1-0"

FilePGNs(779) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bg5 e6 7. f4 h6 8. Bh4 Qb6 9. a3 Be7 10. Bf2 Qc7 11. Qf3 Nbd7 12. O-O-O b5 13. g4 g5 14. h4  gxf4 15. Be2 b4  16. axb4 Ne5 17. Qxf4 Nexg4 18. Bxg4 e5 19. Qxf6  Bxf6 20. Nd5 Qd8 21. Nf5  Rb8  22. Nxf6+ Qxf6 23. Rxd6  Be6 24. Rhd1 O-O 25. h5  Qg5+ 26. Be3 Qf6 27. Nxh6+ Kh8 28. Bf5 Qe7  29. b5  Qe8  30. Nxf7+ Rxf7 31. Rxe6 Qxb5 32. Rh6+ 1-0 "

; sample game 780
EventSites(780) = "London Classic 8th  London" : GameDates(780) = "20161216" : WhitePlayers(780) = "Nakamura, Hikaru   G#780" : WhiteElos(780) = "2779" : BlackPlayers(780) = "Vachier Lagrave, Maxime   G#780" : BlackElos(780) = "2804" : Each_Game_Result(780) = "1-0"

FilePGNs(780) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bg5 e6 7. f4 h6 8. Bh4 Qb6 9. a3 Be7 10. Bf2 Qc7 11. Qf3 Nbd7 12. O-O-O b5 13. g4 Bb7 14. Bg2 Rc8 15. Kb1 g5 16. Qh3 Nc5  17. Rhe1 h5 18. Nf5  Ncxe4 19. Bxe4 Nxe4 20. Bd4  Rg8 21. Nxe7 Kxe7 22. gxh5 gxf4 23. Qh4+ Kf8 24. Ka1 b4 25. Nxe4 Bxe4 26. Rxe4 Qxc2 27. Ree1 bxa3 28. Qxf4 axb2+ 29. Bxb2 Rg5 30. Qxd6+ Kg8 31. Rg1  Qa4+ 32. Ba3 Rxg1 33. Rxg1+ Kh7 34. Qd3+ Kh6 35. Rg6+ Kxh5 36. Rg1 f5 37. Qf3+ 1-0 "

; sample game 781
EventSites(781) = "London Classic 8th  London" : GameDates(781) = "20161217" : WhitePlayers(781) = "Topalov, Veselin   G#781" : WhiteElos(781) = "2760" : BlackPlayers(781) = "Anand, Viswanathan   G#781" : BlackElos(781) = "2779" : Each_Game_Result(781) = "0-1"

FilePGNs(781) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Be7 5. Bf4 O-O 6. e3 c5 7. dxc5 Bxc5 8. a3 Nc6 9. Qc2 Re8  10. O-O-O e5 11. Bg5 d4 12. Nd5 b5   13. Bxf6  gxf6 14. cxb5 Na5 15. exd4 exd4 16. Nb4  Bxb4 17. axb4 Be6 18. Nxd4  Rc8 19. Nc6 Nxc6 20. bxc6 Qb6 21. Qa4 Rxc6+  22. Kb1 Rd8 23. Rxd8+ Qxd8 24. Be2 Bf5+ 25. Ka2 Rc2 26. Rd1 Qb6 27. Bg4 Qe6+ 28. Ka3 Qe5 29. Qb3 Bg6 30. Bf3 Rxf2 31. h4  Bc2 32. Rd8+ Kg7 33. Qc3  Qb5 34. Qc6 Rxf3+  0-1 "

; sample game 782
EventSites(782) = "London Classic 8th  London" : GameDates(782) = "20161218" : WhitePlayers(782) = "Aronian, Levon   G#782" : WhiteElos(782) = "2785" : BlackPlayers(782) = "Topalov, Veselin   G#782" : BlackElos(782) = "2760" : Each_Game_Result(782) = "0-1"

FilePGNs(782) = "1. c4  g6 2. Nc3 c5 3. g3 Bg7 4. Bg2 Nc6 5. Nf3 d6 6. O-O e6 7. e3 Nge7 8. d4 O-O 9. Re1  a6 10. Bd2  Rb8 11. Rc1 b6 12. Ne2 e5  13. Bc3 h6 14. d5 Nb4 15. Ra1  b5  16. a3 bxc4 17. axb4 cxb4 18. Bd2 Nxd5 19. Qc1  c3 20. bxc3 b3 21. Qb1 Nf6  22. Qb2 Qc7 23. c4  Qxc4 24. Nc3 Be6 25. Rec1 Nd7  26. e4 Nc5 27. Bf1 Qb4 28. Be3 Rfc8 29. Nd2 a5  30. Bxc5 Rxc5 31. Ra4 Qb7 32. Bc4 Qc6  33. Bd5 Bxd5 34. exd5 Qd7 35. Ra3 a4  36. Nxa4 Rxd5 37. Nxb3 e4 38. Qa2 Qf5  39. Re1 Rdb5 40. Rc1 d5 41. Nac5 d4 42. Ra7 d3 43. Rc7  h5  44. Qa4 h4 45. Qxe4  Qxe4 46. Nxe4 Rxb3 47. gxh4  Bh6  48. Rf1 R3b4 49. f3 Rb2 50. Nf6+ Kg7 51. Ng4 d2 52. Rd7 Re8 53. Nf2 Re1 0-1 "

; sample game 783
EventSites(783) = "Groningen op-A 54th  Groningen" : GameDates(783) = "20161227" : WhitePlayers(783) = "Tiviakov, Sergei   G#783" : WhiteElos(783) = "2609" : BlackPlayers(783) = "Chigaev, Maksim   G#783" : BlackElos(783) = "2531" : Each_Game_Result(783) = "1-0"

FilePGNs(783) = "1. e4 c6 2. d4 d5 3. Nd2 dxe4 4. Nxe4 Bf5 5. Ng3 Bg6 6. Nh3 e6 7. Nf4 Bd6 8. Ngh5  Bxh5 9. Nxh5 g6 10. Ng3 Qh4 11. c3  Nd7 12. Qf3 Ngf6  13. Ne2 e5 14. g3 Qg4 15. Qxg4 Nxg4 16. h3  Ngf6 17. Bg2 O-O-O 18. O-O Rde8 19. dxe5 Nxe5 20. Rd1 Kc7 21. Kf1  Ned7 22. Be3 Nb6 23. b3 Nbd5 24. Bd2 Ne4 25. Be1  f5 26. c4 Nb6 27. Rac1 Nd7 28. b4  Rhf8 29. c5 Be7  30. f3 Ng5  31. Nd4 Bf6 32. b5  Bxd4 33. Rxd4 f4  34. bxc6 bxc6 35. h4   Ne6 36. Ba5+ Kc8 37. Rd6 Ndxc5  38. Bh3 Kb7 39. Bb4 Kc7 40. Rd2 1-0 "

; sample game 784
EventSites(784) = "Tata Steel-B 79th  Wijk aan Zee" : GameDates(784) = "20170114" : WhitePlayers(784) = "Ragger, Markus   G#784" : WhiteElos(784) = "2697" : BlackPlayers(784) = "Xiong, Jeffery   G#784" : BlackElos(784) = "2667" : Each_Game_Result(784) = "1-0"

FilePGNs(784) = "1. e4 c5 2. Nf3 d6 3. d4 Nf6 4. Nc3 cxd4 5. Nxd4 a6 6. h3 e5 7. Nde2 b5 8. Ng3 Qc7 9. Bd3 Be6 10. O-O Nbd7 11. f4 Be7 12. Qf3 O-O 13. Kh1 Qc6 14. f5  Bc4 15. Bg5 Rac8 16. Nh5  b4 17. Bxf6 Nxf6 18. Nxf6+ Bxf6 19. Bxc4 Qxc4 20. Nd5 Qxc2 21. b3 a5 22. Qe3 Kh8  23. Rac1  Qxa2 24. Nxf6 Rxc1 25. Rxc1 gxf6 26. Qh6 Kg8 27. Qxf6  Qd2 28. Rf1 Re8  29. Rf3 a4 30. Rg3+ Kf8 31. Qg7+ Ke7 32. f6+ Kd8 33. Qxf7 a3 34. Qa7 Qc1+ 35. Kh2 Qf4 36. Qb8+ Kd7 37. Qb5+ Kd8 38. Qxb4 h5 39. Qxd6+ Kc8 40. Qc6+ Kd8 41. f7  1-0 "

; sample game 785
EventSites(785) = "Tata Steel-A 79th  Wijk aan Zee" : GameDates(785) = "20170117" : WhitePlayers(785) = "Giri, Anish   G#785" : WhiteElos(785) = "2773" : BlackPlayers(785) = "Andreikin, Dmitry   G#785" : BlackElos(785) = "2736" : Each_Game_Result(785) = "1/2-1/2"

FilePGNs(785) = "1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Nxd4 Qf6  5. Nf3  Bb4+  6. c3 Bc5 7. Be2 d6 8. O-O Nge7 9. b4 Bb6 10. Bg5  Qg6 11. Bh4  Qh6  12. Nbd2 Ng6 13. Bg3  O-O 14. a4 a5 15. Nc4 axb4 16. cxb4 Nf4 17. Nxb6 cxb6 18. Bb5 Bg4 19. Qc1 Bxf3 20. gxf3 g5 21. Bxf4 gxf4 22. Bxc6 Rfc8 23. b5  bxc6 24. bxc6 Ra5  25. Kh1 Rc5 26. Qb2 R8xc6 27. Rg1+ Kf8 28. a5  Qh3 29. axb6 Qxf3+ 30. Rg2 Ra5  31. b7 Rxa1+ 32. Qxa1 Rb6 33. h4  Qb3 34. Kh2 Rxb7  35. Qf6 Qb6  36. f3  Rb8  37. Rd2  Re8 38. Qh6+  Ke7 39. e5 Rg8  40. Qxd6+ Qxd6 41. exd6+ 1/2-1/2 "

; sample game 786
EventSites(786) = "Tata Steel-A 79th  Wijk aan Zee" : GameDates(786) = "20170117" : WhitePlayers(786) = "Carlsen, Magnus   G#786" : WhiteElos(786) = "2840" : BlackPlayers(786) = "Wei, Yi   G#786" : BlackElos(786) = "2706" : Each_Game_Result(786) = "1-0"

FilePGNs(786) = "1. e4 e5 2. Bc4 Nf6 3. d3 c6 4. Nf3 d6 5. O-O Be7 6. Bb3 O-O 7. c3 Nbd7 8. Re1 Nc5 9. Bc2 Bg4 10. Nbd2 Ne6 11. h3 Bh5 12. Nf1 Nd7  13. g4  Bg6 14. Ng3 Ng5 15. Bxg5 Bxg5 16. d4 Bf4 17. Ne2 Qf6 18. Kg2 exd4  19. Nfxd4 Rfe8 20. Nxf4 Qxf4 21. f3 Nb6  22. Qc1 Qxc1 23. Raxc1 d5 24. e5 Nd7 25. f4 Bxc2 26. Rxc2 Nc5 27. Re3 Rad8 28. Kf3 Ne4 29. b4  g5  30. c4 c5 31. Nb5 gxf4 32. Kxf4 cxb4 33. cxd5 1-0 "

; sample game 787
EventSites(787) = "Tata Steel-A 79th  Wijk aan Zee" : GameDates(787) = "20170119" : WhitePlayers(787) = "Karjakin, Sergey   G#787" : WhiteElos(787) = "2785" : BlackPlayers(787) = "Adhiban, Baskaran   G#787" : BlackElos(787) = "2653" : Each_Game_Result(787) = "0-1"

FilePGNs(787) = "1. e4 e6 2. d4 d5 3. Nc3 Nf6 4. e5 Nfd7 5. f4 c5 6. Nf3 Nc6 7. Be3 Be7 8. Qd2 a6  9. a3 O-O 10. dxc5 Nxc5 11. Qf2 Nd7   12. Nd4 Nxd4 13. Bxd4 f6 14. exf6 Bxf6  15. Bxf6 Qxf6 16. g3 g5  17. O-O-O gxf4 18. Kb1 f3 19. g4  Ne5 20. g5 Qg7 21. g6  hxg6 22. Bd3 Bd7  23. Rdg1 Nxd3 24. cxd3 Rf5 25. Rg4 Raf8 26. Rhg1 Be8 27. Nd1 Rh5 28. h4 Re5 29. Ne3 Bb5  30. Rd4 Re4  31. Rxg6  Bxd3+ 0-1 "

; sample game 788
EventSites(788) = "Tata Steel-A 79th  Wijk aan Zee" : GameDates(788) = "20170121" : WhitePlayers(788) = "Wei, Yi   G#788" : WhiteElos(788) = "2706" : BlackPlayers(788) = "Van Wely, Loek   G#788" : BlackElos(788) = "2695" : Each_Game_Result(788) = "1-0"

FilePGNs(788) = "1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4 Nf6 5. Nc3 a6 6. Bg5 Nbd7  7. Bc4  Qb6 8. O-O Qc5 9. Bd5 e6 10. Re1 Be7 11. Be3 Qa5 12. Bxe6 fxe6 13. Nxe6 Nc5 14. b4 Qxb4 15. Nc7+ Kd8 16. N3d5 Nxd5 17. Nxd5 Qa3 18. Nb6 Rb8 19. Nc4 Qb4 20. Nxd6 Nd3  21. Qxd3 Qxd6 22. Qxd6+ Bxd6 23. Rad1 Kc7 24. Rxd6 Kxd6 25. Bf4+ Ke6 26. Bxb8 Bd7 27. Ba7 Rc8 28. Rc1 Rc4 29. f3 Ra4 30. Ra1 Rc4 31. c3 b5 32. a3 a5 33. Bb6 Ra4 34. Bd4 g6 35. Kf2 g5 36. Ke3 Bc6 37. Kd2 h5 38. Kc2 b4  39. cxb4 axb4 40. axb4 Rxb4 41. Kc3 Ra4 42. Rxa4 Bxa4 43. g3  h4 44. f4 gxf4 45. gxf4 h3 46. Kd2 Kd6 47. Ke3 Bc2 48. f5 Kc6 49. Kf4 Bd3 50. Bb2 Bc2 51. e5 Kd5 52. Kg5 Bd3 53. e6 1-0 "

; sample game 789
EventSites(789) = "Tata Steel-A 79th  Wijk aan Zee" : GameDates(789) = "20170122" : WhitePlayers(789) = "Aronian, Levon   G#789" : WhiteElos(789) = "2780" : BlackPlayers(789) = "Giri, Anish   G#789" : BlackElos(789) = "2773" : Each_Game_Result(789) = "1-0"

FilePGNs(789) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. g3 Bb4+ 5. Bd2 Be7 6. Bg2 O-O 7. O-O c6 8. Na3 Nbd7 9. Rc1 Ne4 10. Be3 Bxa3 11. bxa3 Nd6 12. c5 Nc4 13. Rxc4 dxc4 14. Qc2 h6 15. Qxc4 b6 16. Bf4 Re8 17. Bd6 Bb7 18. Ne5 bxc5 19. dxc5 Nxe5 20. Bxe5 a5 21. Rb1 Ra7 22. Qc3 f6 23. Bd6 Ba8 24. Be4 f5 25. Bc2 Rb7 26. Rd1 Rd7 27. e4 Qf6 28. Qc4 Kh8 29. Re1 Qf7 30. Qd3 f4 31. gxf4 e5 32. Qh3 Rxd6 33. cxd6 Qg6+ 34. Qg3 Qxd6 35. Rd1 Qc5 36. Rd7 Rg8 37. Bb3 exf4 38. Qg6 f3 39. h4 Qc3 40. Bxg8 Qe1+ 41. Kh2 Qxf2+ 42. Kh3 Qf1+ 43. Kg4 1-0 "

; sample game 790
EventSites(790) = "Tata Steel-A 79th  Wijk aan Zee" : GameDates(790) = "20170122" : WhitePlayers(790) = "Adhiban, Baskaran   G#790" : WhiteElos(790) = "2653" : BlackPlayers(790) = "Andreikin, Dmitry   G#790" : BlackElos(790) = "2736" : Each_Game_Result(790) = "1-0"

FilePGNs(790) = "1. e4 e5 2. Nc3  Nc6 3. g3 g6 4. Bg2 Bg7 5. d3 d6 6. f4 Nge7 7. Nf3 Nd4 8. O-O Bg4 9. Be3 c5 10. Qd2 O-O 11. Nh4 exf4 12. Bxf4 Qd7 13. Rf2 Rae8  14. Bh6  Bxh6 15. Qxh6 b5 16. h3 Be6 17. Raf1 Qd8  18. Nb1  d5  19. Nd2  dxe4 20. Nxe4 Nef5 21. Rxf5  Nxf5 22. Rxf5  Qd4+ 23. Rf2 f5 24. Ng5 Qg7 25. Qxg7+ Kxg7 26. Bc6  h6 27. Nxe6+ Rxe6 28. Bxb5 Rb8 29. a4 a6 30. Bc4 Re1+ 31. Kg2 Rxb2 32. Bxa6 Rc1 33. Bc4 Rcxc2 34. Rxc2 Rxc2+ 35. Kf3 Kf6 36. a5 g5 37. a6  Rc1 38. Ng2 Ke5 39. Ne3 h5  40. Nc2  g4+ 41. Ke3  gxh3 42. a7 h2 43. a8=Q h1=Q 44. Qb8+  Kf6 45. Qf8+ Kg6 46. Bf7+ 1-0 "

; sample game 791
EventSites(791) = "Tata Steel-A 79th  Wijk aan Zee" : GameDates(791) = "20170122" : WhitePlayers(791) = "Rapport, Richard   G#791" : WhiteElos(791) = "2702" : BlackPlayers(791) = "Carlsen, Magnus   G#791" : BlackElos(791) = "2840" : Each_Game_Result(791) = "1-0"

FilePGNs(791) = "1. Nf3  d5 2. b3  Bf5 3. Bb2 e6 4. d3 h6 5. Nbd2 Nf6 6. c4 c6 7. g3 Be7 8. Bg2 O-O 9. O-O Nbd7 10. a3 a5 11. Qb1  Bh7 12. b4 axb4 13. axb4 Qb6 14. Bc3 Rxa1 15. Qxa1 Bxb4 16. Bxb4 Qxb4 17. Rb1 Qd6 18. Rxb7 e5 19. d4 exd4 20. Nxd4 c5 21. N4b3 d4  22. Bh3 d3  23. e3  Ne5  24. Bg2  Rc8 25. f4 Neg4 26. e4 Re8  27. e5 Nxe5 28. fxe5 Rxe5 29. Rb6  Qe7 30. Rb8+ Ne8 31. Bc6 Re1+ 32. Qxe1 Qxe1+ 33. Nf1 1-0 "

; sample game 792
EventSites(792) = "Tata Steel-A 79th  Wijk aan Zee" : GameDates(792) = "20170125" : WhitePlayers(792) = "So, Wesley   G#792" : WhiteElos(792) = "2808" : BlackPlayers(792) = "Wojtaszek, Radoslaw   G#792" : BlackElos(792) = "2750" : Each_Game_Result(792) = "1-0"

FilePGNs(792) = "1. c4 Nf6 2. Nf3 e6 3. g3 d5 4. d4 Be7 5. Bg2 O-O 6. Qc2  c5 7. O-O Nc6 8. dxc5 d4 9. a3 a5 10. Rd1 e5 11. Nc3 Bxc5 12. Nd5 h6 13. Bd2 a4 14. Bb4 Nxb4 15. axb4 Nxd5 16. bxc5 Nb4 17. Qd2 Nc6 18. b4  Qe7 19. Qb2  Bg4 20. Re1 Rfd8 21. Nd2 Be6  22. b5  Nb8 23. Qb4 f5 24. Nb3  Nd7 25. Bxb7 Rab8 26. Rxa4 Rxb7 27. c6 Qxb4 28. Rxb4 Rc7 29. cxd7 Rxc4 30. Rxc4 Bxc4 31. Rc1 Be6 32. Rc8 Rxc8 33. dxc8=Q+ Bxc8 34. b6 1-0 "

; sample game 793
EventSites(793) = "Gibraltar Masters 15th  Caleta" : GameDates(793) = "20170126" : WhitePlayers(793) = "Cheparinov, Ivan   G#793" : WhiteElos(793) = "2689" : BlackPlayers(793) = "Schroeder, Jan Christian   G#793" : BlackElos(793) = "2550" : Each_Game_Result(793) = "1/2-1/2"

FilePGNs(793) = "1. d4 d5 2. c4 e6 3. Nf3 Nf6 4. g3 Be7 5. Bg2 O-O 6. O-O dxc4 7. Qc2 a6 8. a4 c5  9. dxc5 Bxc5 10. Nbd2  b5  11. axb5 Bb7 12. Nh4 Nd5 13. bxa6 Bxa6  14. Nxc4 Nc6 15. Ne3 Nd4 16. Qxc5 Nxe2+ 17. Kh1 Nxg3+ 18. hxg3 Bxf1 19. Rxa8 Bxg2+ 20. Nhxg2 Qxa8 21. Nxd5 exd5 22. Be3 Qa1+ 23. Kh2 Qxb2 24. Nf4 Qb7 25. Nxd5 Rd8 26. Ne7+ Kh8 27. Nf5 f6 28. Bd4 Qd7 29. Qb6 Rf8 30. Bc5 Rg8 31. Nd6 Qe6 32. Qb7 h6 33. Qb1 Rd8 34. Qb6 Rd7 35. Qb8+ Kh7 36. Qb1+ Kh8 37. Qb8+ Kh7 38. Qb1+ Kh8 39. Qb8+ 1/2-1/2 "

; sample game 794
EventSites(794) = "Tata Steel-A 79th  Wijk aan Zee" : GameDates(794) = "20170129" : WhitePlayers(794) = "Rapport, Richard   G#794" : WhiteElos(794) = "2702" : BlackPlayers(794) = "Adhiban, Baskaran   G#794" : BlackElos(794) = "2653" : Each_Game_Result(794) = "0-1"

FilePGNs(794) = "1. d4 Nf6 2. Bg5 c5 3. Nc3 cxd4 4. Qxd4 Nc6 5. Qh4 e6 6. O-O-O Be7 7. e4 a6 8. Nf3 Qc7 9. Bd3 d6 10. Rhe1 Bd7 11. e5 dxe5 12. Ne4 Nd5  13. Bxe7 Ncxe7 14. Ng3 f6  15. Nh5 O-O-O 16. Nxg7 Ng6 17. Qc4 Ngf4 18. Qxc7+ Nxc7 19. g4 Bc6 20. Be4 Rxd1+ 21. Kxd1 Ng2 22. Re2 Nf4 23. Re1 Ng2 24. Re2 Rd8+ 25. Nd2 Nf4 26. Bxc6  Nxe2 27. Bxb7+ Kxb7 28. Kxe2 Rg8 29. Nh5 Rg6  30. Kf3 f5 31. gxf5 exf5 32. Ng3 e4+  33. Kf4 Nd5+ 34. Kxf5 e3 35. fxe3 Nxe3+ 36. Ke5 Nxc2 37. Nde4 Rh6  38. Nf1 Nb4 39. Nf6 Nxa2 0-1 "

; sample game 795
EventSites(795) = "Tata Steel-A 79th  Wijk aan Zee" : GameDates(795) = "20170129" : WhitePlayers(795) = "Carlsen, Magnus   G#795" : WhiteElos(795) = "2840" : BlackPlayers(795) = "Karjakin, Sergey   G#795" : BlackElos(795) = "2785" : Each_Game_Result(795) = "1/2-1/2"

FilePGNs(795) = "1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. c3 Nf6 5. d3 O-O 6. Bg5 d6 7. Nbd2 h6 8. Bh4 g5  9. Nxg5 hxg5 10. Bxg5 Kg7 11. Qf3 Be6 12. b4  Bb6 13. Bd5 a5  14. b5 Nb8 15. Bxb7 Ra7 16. Bd5  Nbd7 17. Nc4 Bxd5 18. exd5 Qe8 19. Ne3 Rg8 20. O-O Nh7 21. Nf5+ Kh8 22. Bh4 Ra8 23. Rae1 f6 24. Re4 Nc5 25. Re3 Nd7 26. d4  Qg6  27. Ne7 Qg4 28. Nxg8 Rxg8 29. Qxg4 Rxg4 30. g3 exd4  31. cxd4 Bxd4 32. Re8+ Rg8 33. Re7 Rg7 34. Re4 Ne5 35. Kg2 Bb6 36. f4 Ng6 37. Kh3  Kg8 38. Rfe1 Kf7 39. Re6 Rg8 40. R1e4 f5 41. Re2 Rh8 42. a4 Kg7 43. Rxg6+  Kxg6 44. Re6+ Kf7 45. Re7+ Kg8 46. Kg2 Nf8 47. Bg5 Rh7 48. Re8 Kf7 49. Rd8 Kg8 50. Re8 Rf7 51. Bh6 Rf6 52. Bg5 Rf7 53. Bh6 1/2-1/2 "

; sample game 796
EventSites(796) = "Gibraltar Masters 15th  Caleta" : GameDates(796) = "20170130" : WhitePlayers(796) = "Vachier Lagrave, Maxime   G#796" : WhiteElos(796) = "2796" : BlackPlayers(796) = "Adams, Michael   G#796" : BlackElos(796) = "2751" : Each_Game_Result(796) = "1-0"

FilePGNs(796) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 4. O-O Nxe4 5. d4 Nd6 6. Bxc6 dxc6 7. dxe5 Nf5 8. Qxd8+ Kxd8 9. h3 Be7  10. Nc3 Nh4 11. Nxh4 Bxh4 12. Be3 h5 13. Rad1+ Ke8 14. Ne2 b6 15. a4   c5 16. Nc3 Bf5 17. Nb5 Bd8 18. Rd2 a6 19. Nc3 h4 20. a5  Rh5 21. Rfd1 Bh7  22. Nd5  Be4  23. c4 Rb8 24. f4 Rf5 25. Nc3  Bb7 26. axb6 cxb6 27. Rd6 Bc7 28. Rd7 Bd8  29. Ne2  Rh5 30. e6  Be7  31. Rc7 Bc8 32. exf7+ Kf8 33. f5  Bxf5  34. g4 hxg3 35. Nxg3 Bc2 36. Rdd7 Re5 37. Bf4 Bf6 38. Nh5 Re1+ 39. Kf2 Bh4+ 40. Ng3 Re6 41. Bd6+  Rxd6 42. Rxd6 Bf6 43. Rxf6  gxf6 44. Nh5 Rd8 45. Nxf6 Bf5  46. Kg3  Rd6 47. Ng4 Rd4 48. b3 b5 49. Ne5  Re4 50. Rxc5 bxc4 51. Rd5 Rxe5 52. Rxe5 Bd3 53. b4  c3 54. Rc5 c2 55. Rc7 1-0 "

; sample game 797
EventSites(797) = "Gibraltar Masters 15th  Caleta" : GameDates(797) = "20170201" : WhitePlayers(797) = "Topalov, Veselin   G#797" : WhiteElos(797) = "2739" : BlackPlayers(797) = "Anton Guijarro, David   G#797" : BlackElos(797) = "2650" : Each_Game_Result(797) = "0-1"

FilePGNs(797) = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Na5 10. Bc2 c5 11. d4 Nd7  12. Nbd2 exd4  13. cxd4 Nc6 14. d5 Nce5 15. a4 Bb7 16. Qe2 Rb8 17. Nxe5 Nxe5 18. axb5 axb5 19. Nf1 Re8 20. Ne3 Bf6 21. Bd2 Bc8  22. Ba5 Qe7 23. Bc3  Ng6  24. Qf3 Bxc3 25. bxc3 Qg5 26. Kh2 h5  27. Ra7 Re7 28. Rxe7 Nxe7 29. Ra1 Ng6 30. Qg3 Qf6  31. Nf5  Bxf5 32. exf5 Ne5 33. Rb1 h4 34. Qf4 g5  35. Qe3 Nc4 36. Qc1 Kg7 37. Bd3 Ne5 38. Be4 g4  39. hxg4 Nxg4+ 40. Kg1 Qh6  41. Qxh6+ Kxh6 42. Kf1 Kg5 0-1 "

; sample game 798
EventSites(798) = "Sharjah FIDE GP  Sharjah" : GameDates(798) = "20170218" : WhitePlayers(798) = "Ding, Liren   G#798" : WhiteElos(798) = "2760" : BlackPlayers(798) = "Rapport, Richard   G#798" : BlackElos(798) = "2692" : Each_Game_Result(798) = "0-1"

FilePGNs(798) = "1. d4 Nf6 2. c4 e6 3. Nf3 b6 4. g3 Bb7 5. Bg2 Bb4+ 6. Bd2 a5  7. O-O O-O 8. Bf4 Be7  9. Nc3 Ne4 10. Qd3 Nxc3 11. bxc3  Qc8 12. e4 d6 13. Rfe1 Nd7 14. Rad1 a4  15. h4 Ra5 16. Bc1  Re8 17. Nh2 Qa8 18. Nf1 Nf6 19. d5 Bf8 20. Ne3 a3 21. f4 Ra4  22. e5 Nd7 23. h5 Nc5 24. Qf1 h6  25. Rd4 Qa5  26. Bd2 exd5 27. Nxd5 c6 28. Nb4 Qa8 29. exd6 Rd8  30. f5 Nd7  31. Rd3  Nf6 32. Bf4 Ra5 33. Qf3 Rxf5 34. Nxc6  Rxd6  35. Rxd6 Bxd6 36. Ne7+ Bxe7 37. Qxb7 Bc5+ 38. Kf1 Qxb7 39. Bxb7 Nxh5 40. Re8+ Bf8 0-1 "

; sample game 799
EventSites(799) = "Sharjah FIDE GP  Sharjah" : GameDates(799) = "20170220" : WhitePlayers(799) = "Nakamura, Hikaru   G#799" : WhiteElos(799) = "2785" : BlackPlayers(799) = "Rapport, Richard   G#799" : BlackElos(799) = "2692" : Each_Game_Result(799) = "1-0"

FilePGNs(799) = "1. d4 d5 2. c4 Nc6 3. Nf3 Bg4 4. cxd5 Bxf3 5. gxf3 Qxd5 6. e3 e5 7. Nc3 Bb4 8. Bd2 Bxc3 9. bxc3 Qd7 10. Rb1 O-O-O  11. Bg2 Nge7 12. Qb3 b6 13. Qxf7 Rhf8 14. Qc4 Kb8 15. O-O g5 16. Rb5 Rf6 17. e4  h6 18. dxe5  Na5 19. Qe2 Rc6 20. Be3 Ng6 21. Rd5 Qe7 22. Rfd1 Rf8 23. Qb5 Qe6 24. Rd8+ Rxd8 25. Rxd8+ Kb7 26. Qd5 Nc4 27. Qxe6 Rxe6 28. Bh3 Rxe5 29. Bc8+ Kc6 30. Bd7+ Kb7 31. Bc8+ Kc6 32. Bd7+ Kb7 33. Bd4 Ra5 34. Bc8+ Kc6 35. Bd7+ Kb7 36. Bc8+ Kc6 37. Be6 Kb5 38. Bd7+  c6  39. Be8 Nf4 40. h4 Nd2  41. Kh2 gxh4  42. Be3 Nxf3+ 43. Kh1 Nh3 44. Bh5 Nxf2+  45. Bxf2 Rxa2 46. Bxf3 Rxf2 47. Rd3 Kc4 48. Re3 Rd2 49. e5 Rd7 50. e6 Re7 51. Bxc6 a5 52. Re4+ Kxc3 53. Bb5 a4 54. Bxa4 Kd3 55. Re1 1-0 "

; sample game 800
EventSites(800) = "Sharjah FIDE GP  Sharjah" : GameDates(800) = "20170222" : WhitePlayers(800) = "Grischuk, Alexander   G#800" : WhiteElos(800) = "2742" : BlackPlayers(800) = "Eljanov, Pavel   G#800" : BlackElos(800) = "2759" : Each_Game_Result(800) = "1-0"

FilePGNs(800) = "1. d4 Nf6 2. c4 e6 3. Nf3 d5 4. Nc3 Bb4 5. cxd5 exd5 6. Bg5 h6 7. Bh4 O-O 8. e3 Bf5 9. Qb3 Bxc3+ 10. bxc3 Nbd7 11. Be2 c5 12. dxc5 Nxc5 13. Qb4 Nce4 14. Nd4 Bh7 15. O-O g5 16. Bg3 Qb6 17. Qxb6 axb6 18. Rfc1 Rfc8 19. c4 Nxg3 20. hxg3 Rc5 21. Nb3  Rc7 22. cxd5 Rxc1+ 23. Rxc1 Nxd5 24. Nd4  Bg6 25. Bb5 Nb4 26. a4 Na6 27. f3 Nc5 28. e4 Rd8 29. Rc4 h5 30. Kf2 f6 31. Ke3 Bf7 32. Rb4 Ra8 33. Ne2 Rc8  34. Rd4 Be8 35. Rd6 Bxb5 36. axb5 Kf7 37. Nc3 Re8 38. Rxb6 f5 39. Rd6 fxe4 40. Nxe4  Nxe4 41. fxe4 Ra8 42. Rd7+ Kf6  43. Rxb7 Ra3+ 44. Kd4 Rxg3 45. b6 Rxg2 46. Rb8 Rb2 47. b7  Kg7 48. e5 g4 49. Kc3 1-0 "


  
  
  For i = 1 To #sample_games : Display_Flag(i) = 1 : FEN_setup_str(i) = "" : FEN_setup_flag(1) = 0 : Next
  GameCount = #sample_games + 1

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
      If ycoordm >= #canvas_gadgetY + SquareSize + (60*i) And ycoordm <= #canvas_gadgetY + SquareSize + (i+1)*60
        mailbox_row = (i+2)*10
      EndIf
      If xcoordm >= 135 + (60*i) And xcoordm <= 135 + (i+1)*60
        mailbox_file = i + 1
      EndIf
    Else
      If ycoordm >= #canvas_gadgetY + SquareSize + (40*i) And ycoordm <= #canvas_gadgetY + SquareSize + (i+1)*40
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
  
  
  Procedure OutputSampleGameCode()
    
    Protected j.i, x.i, dash1_pos.i, rb_pos.i, lb_pos.i, nowdate1.s, DefaultFileName.s, Pattern.s, CodeFilename.s, GameInfoLine.s, PGNScore.s
    Protected Sample_Games_Output_Count_str.s, PGNNoNagGameScore.s
    Protected Sample_Range_End.i, Sample_Range_Start.i, FileID.i
    
    nowdate1 = FormatDate("%yyyy%mm%dd%hh%ii%ss", Date())

    DefaultFileName = GetCurrentDirectory() + "Sample_games_code_" + nowdate1 + ".txt"
    Pattern.s = ""
    
    Sample_Games_Output_Count_str = InputRequester("Sample game(s) export", "Output Range of games ", "[" + Str(#sample_games+1) + "-" + Str(#sample_games+100) + "]")
    dash1_pos = FindString(Sample_Games_Output_Count_str,"-")
    lb_pos = FindString(Sample_Games_Output_Count_str,"[")
    rb_pos = FindString(Sample_Games_Output_Count_str,"]")
    Sample_Range_Start = Val(Mid(Sample_Games_Output_Count_str,lb_pos+1,dash1_pos-lb_pos-1))
    Sample_Range_End = Val(Mid(Sample_Games_Output_Count_str,dash1_pos+1,rb_pos-dash1_pos-1))
    
    CodeFilename = SaveFileRequester("Save the currently selected default samplegames code file?", DefaultFileName, Pattern, 0)
    FileID = OpenFile(#PB_Any, CodeFileName)
    
    For x = #sample_games + 1 To Sample_Range_End
      
      GameInfoLine = "EventSites(" + Str(x) + ") = " + #DQUOTE$ + EventSites(x) + #DQUOTE$ + " : " + "GameDates(" + Str(x) + ") = " + #DQUOTE$ + GameDates(x) + #DQUOTE$ + " : "
      GameInfoLine = GameInfoLine + "WhitePlayers(" + Str(x) + ") = " + #DQUOTE$ + WhitePlayers(x) + #DQUOTE$ + " : "
      GameInfoLine = GameInfoLine + "WhiteElos(" + Str(x) + ") = " + #DQUOTE$ + WhiteElos(x) + #DQUOTE$ + " : "
      GameInfoLine = GameInfoLine + "BlackPlayers(" + Str(x) + ") = " + #DQUOTE$ + BlackPlayers(x) + #DQUOTE$ + " : "
      GameInfoLine = GameInfoLine + "BlackElos(" + Str(x) + ") = " + #DQUOTE$ + BlackElos(x) + #DQUOTE$ + " : "
      GameInfoLine = GameInfoLine + "Each_Game_Result(" + Str(x) + ") = " + #DQUOTE$ + Each_Game_Result(x) + #DQUOTE$ + #CRLF$
      
      PGNNoNagGameScore = FilePGNs(x)
      For j = 150 To 1 Step -1
        PGNNoNagGameScore = ReplaceString(PGNNoNagGameScore,"$"+Str(j),"")   ; remove mal-formed NAGs (with no space after the $)
      Next
      
      PGNScore = "FilePGNs(" + Str(x) + ") = " + #DQUOTE$ + PGNNoNagGameScore + #DQUOTE$
      WriteStringN(FileID, "; sample game " + Str(x))
      WriteStringN(FileID, GameInfoLine)
      WriteStringN(FileID, PGNScore + #CRLF$)
      
    Next
    
    CloseFile(FileID)
    SetGadgetText(#Info_Field, "Text file: " + CodeFilename + " created successfully.")
    
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
            ;PrintN("ResultPGN = " + ResultPGN)
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
  ; code splice for game export
  ConstructFENfromPosition()
  Game_FEN_Positions(HalfMoveCount) = FENpositionstr
  ; code splice end
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

  Protected i.i, j.i, player_result1.i, player_result2.i, whitepl.s, blackpl.s
  Protected gpfx_pos.i, rowitem.s, chr10_pos.i, lb_pos.i, GameNo.i
  ReDim Gadget_List_Display.s(GameCount-1)
  ReDim Gadget_List_Display2.s(GameCount-1)
  
  player_result1 = 0 : player_result2 = 0
  Search_player = InputRequester("Search for player name", "Please enter full or partial player name to search, asterisk (*) for all, *sort to sort: ", "Carlsen")
  ClearGadgetItems(#Players_ListIcon_Gadget)
  If Search_player = "*"
    For i = 1 To GameCount-1
      SetupGameLinkForSearchSort(i)
      AddGadgetItem(#Players_ListIcon_Gadget, -1, GameLink + Chr(10) + Trim(Left(WhitePlayers(i), G1_pos-1), " ") + " [" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + " [" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i))
    Next
  ElseIf  Search_player = "*sort"
    For i = 1 To GameCount-1
      SetupGameLinkForSearchSort(i)
      Gadget_List_Display(i) = GameLink + Chr(10) + Trim(Left(WhitePlayers(i), G1_pos-1), " ") + " [" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + " [" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i)
      Gadget_List_Display2(i) = Trim(WhitePlayers(i), " ") + " [" + WhiteElos(i) + "]" + Chr(10) + Trim(BlackPlayers(i), " ") + " [" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i)
      PrintN("List row = " + Gadget_List_Display2(i))
    Next
    SortArray(Gadget_List_Display2(),#PB_Sort_Ascending)
    PrintN("")
    For i = 1 To GameCount-1
      PrintN("List row = " + Gadget_List_Display2(i))
      Gpfx_pos = FindString(Gadget_List_Display2(i), Game_Prefix, 1)
      lb_pos = FindString(Gadget_List_Display2(i), "[", 1)
      GameLink = Game_Prefix + Trim(Mid(Gadget_List_Display2(i), Gpfx_pos+2, lb_pos-(gpfx_pos+2)),Space(1))
      GameNo = Val(Mid(GameLink,3,6))
      PrintN("GameLink = " + "xxx" + GameLink + "xxx")
      whitepl = Trim(ReplaceString(WhitePlayers(GameNo),GameLink,""),Space(1)) + " [" + WhiteElos(GameNo) + "]"
      blackpl = Trim(ReplaceString(BlackPlayers(GameNo),GameLink,""),Space(1)) + " [" + BlackElos(GameNo) + "]"
      rowitem = GameLink + Chr(10) + whitepl + Chr(10) + blackpl + Chr(10) + GameDates(GameNo) + Chr(10) + EventSites(GameNo) + Chr(10) + Each_Game_Result(GameNo)
      AddGadgetItem(#Players_ListIcon_Gadget, -1, rowitem)
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
        AddGadgetItem(#Players_ListIcon_Gadget, -1, GameLink + Chr(10) + Trim(Left(WhitePlayers(i), G1_pos-1), " ") + " [" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + " [" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i))
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



Procedure PrintAsciiBoard(OutputID.i, FILEID.i)

  Protected BoardLetters.s = "..bRbNbBbQbKbpwRwNwBwQwKwp"
  Protected rank.b, file.b
  
  If OutputID = 2 
    WriteStringN(FileID,"   ________________________" + #CRLF$) 
  Else
    Print("   ________________________") 
  EndIf
  For rank = 20 To 90 Step 10
    If OutputID = 1 : PrintN("") : Else : WriteString(FILEID,"") : EndIf
    For file = 1 To 8
      If OutputID = 1 
        If file = 1 : Print(Str(10-rank/10)+" |") : EndIf
        Print(Mid(BoardLetters,MbxBrd(rank+file)*2+1,2) + Space(1))
        If file = 8 : Print("|") : EndIf
      Else
        If file = 1 : WriteString(FileID,Str(10-rank/10)+" |") : EndIf
        WriteString(FileID, Mid(BoardLetters,MbxBrd(rank+file)*2+1,2) + Space(1))
        If file = 8 : WriteString(FileID,"|") : EndIf
      EndIf
    Next
    If OutputID = 2 : WriteStringN(FileID,"") : EndIf
  Next
  If OutputID = 2 
    WriteStringN(FileID,"   ________________________" + #CRLF$)
    WriteStringN(FileID,Space(4) + "a  b  c  d  e  f  g  h")
  Else
    PrintN(#CRLF$ + "   ________________________" + #CRLF$)
    PrintN(Space(4) + "a  b  c  d  e  f  g  h")
  EndIf
  
  If OutputID = 1 : PrintN("") : PrintN("") : Else : WriteStringN(FileID,"") : WriteStringN(FileID,"") : EndIf

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
  
  GameScore_MoveList = XGameScore_Movelist ; work-around for global string bug I do not understand??
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("") : PrintN("XGameScore_Movelist reduced = " + XGameScore_MoveList) : PrintN("")       
    PrintN("") : PrintN("GameScore_Movelist reduced = " + GameScore_MoveList) : PrintN("")
  CompilerEndIf
    
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
      EmptySq_Button_Click_Count = EmptySq_Button_Click_Count + 1
      If EmptySq_Button_Click_Count >= 10
        PrintN("You clicked on the empty-square-button at least 10 times, unhiding magic S sample data creator button!")
        HideGadget(#Btn_SampleData, 0)                            ; show the Sample games data creator magic button
      EndIf
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
        ResizeGadget(#Btn_ExportPDF, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#Single_MoveDefaultY), #PB_Ignore, #PB_Ignore)
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
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("") : PrintN("GameScore_Movelist spacified = " + GameScore_MoveList) : PrintN("")
  CompilerEndIf
  
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
  If QuickEngine_Flag = #False
    Debug "Error: Could not start Stockfish. Please ensure the path is correct."
  EndIf
EndIf
  


  ProgramID = RunProgram(Stockfish_Input_Path, "", GetCurrentDirectory(), #PB_Program_Open | #PB_Program_Read | #PB_Program_Write)

  If ProgramID
    PrintN("Stockfish started successfully.")
    Engine_Running_Flag = #True
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
  Engine_Running_Flag = #False
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
                    "Choose a PGN (.pgn, [SAN] or [UCI]) or SQLite (.db3, .sqlite) file only, Cancel for Sample games",
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
  If DB_InputFile = ""
    LoadSampleGames()
    SampleGames_Flag = #True
  Else
    SQL_flag = 1
    ;MessageRequester("File PGN read...", "File error!")
  ;LoadSQLiteChessDatabase("/users/testuser/desktop/kppb_pgn_etc/"+DB_InputFile)
    LoadSQLiteChessDatabase(DB_InputFile)
  EndIf
EndIf

DisplayGames()
; IDE Options = PureBasic 6.21 - C Backend (MacOS X - x64)
; CursorPosition = 1924
; FirstLine = 1900
; Folding = -----------------------
; EnableThread
; EnableXP
; DPIAware
; Executable = PGNdbkp_20250903.app