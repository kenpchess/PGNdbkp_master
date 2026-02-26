; PureBasic PGN SAN-UCI-notation Reader, SQLite chess DB, engine match manager, and display (by kenpchess).
; Many thanks to all of the coding experts at the PureBasic forum. This program
; contains code snippets from "Azjio", "Fred", "idle", "infratec", "mk-soft",	"ti994A", 
; Rashad, and others! Thank you all for your code examples!
; See https://github.com/kenpchess/PGNdbkp_master for github code repository!
; 
;The program's main screen layout is similar to the ascii diagram below, but of course a graphical GUI with a graphical chessboard
;in reality.
;
;                                           PGNdbkp_20260109 - PGN Game And SQLite chessdb Viewer
;
;  ————————————————————————————————————————-————-----------------------------------------------------   ———————————————————----------
; | Game #  White Player           Black Player            GameDate  Event/Site        Result   ECO  | | White Moves     Black Moves |                                                                                               
; |   #1    Karpov, Anatoly        Kasparov, Gary          19840910  WCC31-Moscow        1-0    D30  | |   1. e4            c5       |      
; |   #2          *                      *                     *          *               *      *   | |   2. Nf3           Nc6      |  
; |   #3          *                      *                     *          *               *      *   | |   3. d4            cxd4     |   
; |   #4          *                      *                     *          *               *      *   | |   4. Nxd4          Nf6      |   
; |   #5          *                      *                     *          *               *      *   | |   5. Nc3           e5       |   
; |   #6          *                      *                     *          *               *      *   | |   6. Nbd5          d6       |   
; |   #7          *                      *                     *          *               *      *   | |   7. Bg5           a6       |   
; |   #8          *                      *                     *          *               *      *   | |   8. Na3           b5       |   
; |   #9          *                      *                     *          *               *      *   | |   9. Nd5           Be7      |   
; |  #10    Kasimdzhanov, Rustam   Kortschnoi, Viktor      20020525  Jborowski Mem       1-0    C11  | |  10. Bxf6          Bxf6     |   
; |  #11          *                      *                     *          *               *      *   | |  11. c3            Bg5      |   
; |  #12          *                      *                     *          *               *      *   | |  12. Nc2           O-O      |   
; |  #13          *                      *                     *          *               *      *   | |  13. a4            bxa4     |   
; |  #14          *                      *                     *          *               *      *   | |  14. Rxa4          a5       |   
; |  #15          *                      *                     *          *               *      *   | |  15. Bc4           Rb8      |   
; |  #16          *                      *                     *          *               *      *   | |  16. Ra2           Kh8      |   
; |  #17          *                      *                     *          *               *      *   | |  17. Nce3          Bxe3     |   
; |  #18          *                      *                     *          *               *      *   | |  18. Nxe3          Ne7      |   
; |  #19          *                      *                     *          *               *      *   | |  19. b3            f5       |   
; |x #20    Karjakin, Sergey       Topalov, Veselin        20060124  Corus-WijkanZee     0-1    B33  | |  20. exf5          Nxf5     |   
;  --------------------------------------------------------------------------------------------------   -----------------------------
;
;       | A File was not selected: showing sample games: [1-5000] |
;
;         a        b        c        d        e        f        g        h     
;      -----------------------------------------------------------------------
;     |        |        |        |        |        |        |        |        |   |Show FEN|        |BoardSize|        |ExportGames|
;  8  |   BR   |  ***   |   BB   |   BQ   |   BK   |   BB   |   BN   |   BR   |
;     |        |        |        |        |        |        |        |        |   |no moves yet|    |CleanPGN|         |ExportToPDF|
;      -----------------------------------------------------------------------
;     |        |        |        |        |        |        |        |        |    ---------------------------
;  7  |   bp   |   bp   |  ***   |   bp   |   bp   |   bp   |   bp   |   bp   |   |                           |
;     |        |        |        |        |        |        |        |        |   |        general            |
;      -----------------------------------------------------------------------    |          info             |
;     |        |        |        |        |        |        |        |        |   |          area             |        |HELP INFO|
;  6  |  +++   |  ***   |  +BN   |  ***   |  +++   |  ***   |  +++   |  ***   |   |                           |
;     |        |        |        |        |        |        |        |        |   |                           |
;      -----------------------------------------------------------------------     ---------------------------
;     |        |        |        |        |        |        |        |        |
;  5  |  ***   |  +++   |  ***   |  +++   |  ***   |  +++   |  ***   |  +++   |   | < move |     |automove|
;     |        |        |        |        |        |        |        |        |
;      -----------------------------------------------------------------------    | > move |     |Sac Filter|
;     |        |        |        |        |        |        |        |        |
;  4  |  +++   |  ***   |  +++   |  *bp   |  +wp   |  ***   |  +++   |  ***   |   |GameToDb|     |ECO Codes|
;     |        |        |        |        |        |        |        |        |
;      -----------------------------------------------------------------------    |AllGamesToDb| |Update Engines|
;     |        |        |        |        |        |        |        |        |
;  3  |  ***   |  +++   |  ***   |  +++   |  ***   |  +WN   |  ***   |  +++   |   |SF Analy|  |SF 10sec|  |PlayVsEngine|
;     |        |        |        |        |        |        |        |        |
;      -----------------------------------------------------------------------    |Searching/Sorting|     |Engine Match|
;     |        |        |        |        |        |        |        |        |
;  2  |   wp   |   wp   |   wp   |  ***   |  +++   |   wp   |   wp   |   wp   |   |FEN Editor|
;     |        |        |        |        |        |        |        |        |
;      -----------------------------------------------------------------------
;     |        |        |        |        |        |        |        |        |
;  1  |   WR   |   WN   |   WB   |   WQ   |   WK   |   WB   |  ***   |   WR   |
;     |        |        |        |        |        |        |        |        |
;      -----------------------------------------------------------------------
;
;
CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  EnableExplicit
CompilerEndIf

Global version.s = "_20260111"
#game_max = 200000 : #halfmove_max = 2000 : #max_move_history = 1000 : #PGNSizeSkipProgressStartBtn = 10000000
;
;window and gadget layout info follows
;
#canvas_gadgetX = 75 : #canvas_gadgetY = 470
#cg_width = 575 : #cg_height = 545
#alg_filesY = 17 : #alg_rankX = 20
#alg_baseX = 25 : #alg_baseY = 17
#doc_offset = 30 : #demo_y_offset = 10
#progressBarEvent = #PB_Event_FirstCustomValue
#Image_Board192 = 0
#Image_Whitebkgnd32 = 37
#ImageID_DemoBkgnd = 97
#ImageID_DemoBkgnd2 = 98
#ImageID_DemoBkgnd3 = 99

#ButtonsLeftEdgeDefaultX = 675
#playgadgetwidth = 730 : #playgadgetDefaultHeight = 420
#movesgadgetX = 760 : #movesgadgetwidth = 260 : #movesgadgetDefaultHeight = 425

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
#pgnwidth = 1000
;
; end of window and gadget layout info
;
#progressBytes = 2000
#mainwinDefaultWidth = 1050 : #mainwinDefaultHeight = 1020
#SQLBatchOfGames = 500
#sample_games = 5000
#ECO_Codes_max = 3546
#HelpInfoLines = 89
#numAllowedEngines = 16
#NumGames = 1                                           ; Number of full AB/BA pairs to play per opening line.
#OpeningLines_default = 20000

Global SquareSize = 60, Help_accessed_flag.b = 0, Engine_Count.i = 1

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  #StockfishPath = "/usr/local/bin/stockfish17"                                    ; Adjust this to the actual path of your Stockfish executable
  #Engine1Path = #StockfishPath                           ; <<<< CHANGE THIS PATH
  #Engine2Path = "/usr/local/bin/stockfish15"           ; <<<< CHANGE THIS PATH
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  #StockfishPath = "C:\PureBasic\stockfish17.exe"                                    ; Adjust this to the actual path of your Stockfish executable
  #Engine1Path = #StockfishPath                           ; <<<< CHANGE THIS PATH
  #Engine2Path = "C:\PureBasic\stockfish16.exe"            ; <<<< CHANGE THIS PATH
CompilerEndIf


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
Global Dim Sorted_FilePGNs.s(#game_max)
Global Dim Gadget_List_Display.s(#game_max)
Global Dim Gadget_List_Display2.s(#game_max)
Global Dim Game_FEN_Positions.s(#halfmove_max)
Global Dim GameScore_UCI_HalfMoves.s(#halfmove_max)
Global Dim GameScore_Plain_HalfMoves.s(#halfmove_max)
Global Dim Capture_Flag_Array.b(#halfmove_max)
Global Dim WhitePlayers.s(#game_max)
Global Dim ECO_Game_Codes.s(#game_max)
Global Dim Sorted_ECOs.s(#game_max)
Global Dim ECO_Table_Codes.s(#ECO_Codes_max) : Global Dim ECO_Table_Names.s(#ECO_Codes_max)
Global Dim ECO_Table_Moves.s(#ECO_Codes_max) : Global Dim ECO_Table_FENs.s(#ECO_Codes_max)
Global Dim Position_History.s(#max_move_history,2)
Global Dim Move_History.s(#max_move_history,2)
Global Dim Score_History.s(#max_move_history,2)
Global Dim MbxBrd.b(119)                                   ; the semi-famous mailbox chessboard used by me in 1975 (and others in similar timeframe)
Global Dim ValidQueenMbxSqs.s(119)                         ; this array contains all valid queen move squares from every square on the mailbox board
Global Dim PieceImages(25) ; 12 piece types (6 white, 6 black) + 40 pixel versions + emptysq
Global Dim PieceLetters.s(12)
;Global Dim HelpImages(56)
Global Dim pvstring.s(2) 
Global Dim cpscore_str.s(2)

Global Dim Number_Of_Minor_Pieces.i(2)
Global Dim Number_Of_Major_Pieces_Or_Pawns.i(2)
Global Dim Number_Of_Bishops.i(2)
Global Dim Number_Of_Knights.i(2)
Global Dim Number_Of_Rooks.i(2)
Global Dim Number_Of_Pawns.i(2)
Global Dim Total_Material.i(2)
Global Dim Material_Eval.i(12)

Global PGNFileName.s, All_Games_Read_Flag.b
Global AssignedChessDate.s = FormatDate("%yyyy%mm%dd", Date())                   ; todays chess date (for pgns with missing date)
Global EmptySq_Button_Flag.b, Piece_Button_Flag.b, WhiteKing_Button_Flag.b
Global PlayEngineEditCount.i, PlayEngineFENstr.s, MoveString.s, pdf_halfmove.i
Global QuickEngine_Flag.b = #False, SampleGames_Flag.b = #False, Engine_Running_Flag.b = #False
Global GSAT_Flag.b = #False, PDFWidth.f = 650, PDFHeight.f = 700, EmptySq_Button_Click_Count.i
Global match_noboard_flag,b = #False, matchgame_insufficient_mating_material_flag.b = #False
Global capture_flag.b = #False, Sac_Game_Start_Index_str.s, Sac_Game_Start_Index.i, Eng_Index.i = 1

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

Global UCI_move_str.s, Saved_MoveNumber_Construct.s, GameLink.s
Global GameCount.i, MoveColumn.b, iii.i
Global GameIndex, HalfMoveCount, TotalHalfMoves, SQL_flag, SF_Time_Per_Move
Global FENpositionstr.s, SF_fenposition.s, GameTag.s, Game_Result.s
Global Game_Prefix.s = "G#", Ellipsis_move.s = "1. ...", Dot_Sequence.s = "...", DollarSign.s = "$"
Global Win1.s = "1-0" , Lose1.s = "0-1" , Draw1.s = "1/2-1/2", Other1.s = " *"
Global GameResult_SearchMask.s = "1-0xx0-1xx1/2-1/2xx *"
Global WhiteKingSideCastle.s = "e1-g1" , WhiteQueenSideCastle.s = "e1-c1"
Global BlackKingSideCastle.s = "e8-g8" , BlackQueenSideCastle.s = "e8-c8"
Global FEN_Start_Position.s = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
Global AlgSquares.s = "000102030405060708091011121314151617181920a8b8c8d8e8f8g8h82930a7b7c7d7e7f7g7h73940a6b6c6d6e6f6g6h64950a5b5c5d5e5f5g5h55960a4b4c4d4e4f4g4h46970a3b3c3d3e3f3g3h37980a2b2c2d2e2f2g2h28990a1b1c1d1e1f1g1h1"
Global WhiteTag.s = "[White", BlackTag.s = "[Black", EventTag.s = "[Event", SiteTag.s = "[Site"
Global DateTag.s = "[Date", WhiteEloTag.s = "[WhiteElo", BlackEloTag.s = "[BlackElo", FENTag.s = "[FEN", ECOTag.s = "[ECO"
Global PGN_InputFile, DB_InputFile.s, Search_player.s
Global MultiPV.b, cpscore_normal_pos.i, cpscore_mate_pos.i, pva.i, pvb.i
Global G1_pos, G2_pos, GameScore_MoveList.s, DisplayGamesCounter.i = 0

Global mailbox_editor_squareXY.b, GamesInserted.i, ResultPGN.s, startdate.q
Global Games_Range_str.s, range_start.i, range_end.i, GS_Index.i, FEN_display_str.s

Global text.s, output.s, bestmove.s, uci_info.s, anotherFen.s
Global Stockfish_Input_Path.s

Global Images_Path.s = "/users/kenpchess/public/images/"           ; Adjust this to the actual path of your chesspiece images

Global Dim GameResult_Tags.s(4)
GameResult_Tags(1) = Win1 : GameResult_Tags(2) = Lose1 : GameResult_Tags(3) = Draw1 : GameResult_Tags(4) = Other1

PieceLetters(1) = "BR" : PieceLetters(2) = "BN" : PieceLetters(3) = "BB" : PieceLetters(4) = "BQ" : PieceLetters(5) = "BK" : PieceLetters(6) = "BP"
PieceLetters(7) = "WR" : PieceLetters(8) = "WN" : PieceLetters(9) = "WB" : PieceLetters(10) = "WQ" : PieceLetters(11) = "WK" : PieceLetters(12) = "WP"

Global Wpawn = 12, Wking = 11, Wqueen = 10, Wbishop = 9, Wknight = 8, Wrook = 7
Global Bpawn = 6, Bking = 5, Bqueen = 4, Bbishop = 3, Bknight = 2, Brook = 1

Material_Eval(Brook) = 5 : Material_Eval(Bknight) = 3 : Material_Eval(Bbishop) = 3 : Material_Eval(Bqueen) = 9 : Material_Eval(Bking) = 0 : Material_Eval(Bpawn) = 1
Material_Eval(Wrook) = 5 : Material_Eval(Wknight) = 3 : Material_Eval(Wbishop) = 3 : Material_Eval(Wqueen) = 9 : Material_Eval(Wking) = 0 : Material_Eval(Wpawn) = 1

Global Dim Colorflip(13) : Global Dim ColorSign(13)

Colorflip(1) = 0 : Colorflip(2) = 0 : Colorflip(3) = 0 : Colorflip(4) = 0 : Colorflip(5) = 0 : Colorflip(6) = 0 
Colorflip(7) = 6 : Colorflip(8) = 6 : Colorflip(9) = 6 : Colorflip(10) = 6 : Colorflip(11) = 6 : Colorflip(12) = 6

ColorSign(1) = -1 : ColorSign(2) = -1 : ColorSign(3) = -1 : ColorSign(4) = -1 : ColorSign(5) = -1 : ColorSign(6) = -1
ColorSign(7) = 1 : ColorSign(8) = 1 : ColorSign(9) = 1 : ColorSign(10) = 1 : ColorSign(11) = 1 : ColorSign(12) = 1

Global White_on_Move = 1, Black_on_Move = 0, FEN_SideToMove = 1

; Define chessboard colors
Global WhiteColor = RGB(240, 217, 181)
Global BlackColor = RGB(181, 136, 99)

Global _emptysq = 0

Global FilePattern.s, RequesterTitle.s, Pattern.s

;keycodes and  variables for NSCocoa definitions follows

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  Global sharedApplication = CocoaMessage(0, 0, "NSApplication sharedApplication")
  Global clickCount, location.NSPoint, deltaX.CGFloat, deltaY.CGFloat
CompilerEndIf

;Define currentEvent, type, modifierFlags, keyCode
Global currentEvent, type, modifierFlags, keyCode

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

Global uci.s, gamescore_result.s, pgnfile.s, ucifile.s

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

Global Dim possibleFromSquaresMailbox.b(6) ; Store potential move mailbox indices, this dimension is rather arbitrary
Global piece.s, Counter.l, possibleCount.b, fromsq1.b, fromsq2.b, fromSq_str.s, toSq_str.s
Global fromSquareMailbox.b, toSquareMailbox.b, pgngamecount.i
Global WhiteKingCurrentSq.b, BlackKingCurrentSq.b, WhiteQueenCurrentSq.b, BlackQueenCurrentSq.b
Global AppWindow
Global Mailbox_editor_piece.i, GameInfo.s, wFlags.i, filelen.l, max.i, event.i, appQuit.b, currentRead.l, inc.l


; --- Global Variables for Engines (Engines 1 to 8) ---

Global Engine_Path_Generic.s
Global Dim Engine_Name.s(#numAllowedEngines)
Global Dim Engine_Path.s(#numAllowedEngines)
Global Dim Engine_Handle.i(#numAllowedEngines)
Global Dim Engine_ScoreWin.i(#numAllowedEngines)
Global Dim Engine_ScoreDraw.i(#numAllowedEngines)
Global Dim Engine_ScoreLoss.i(#numAllowedEngines)
Global Dim Engine_ScoreDisconnect.i(#numAllowedEngines)
Global Dim Engine_ScorePoints.f(#numAllowedEngines)
Global Dim Engine_SortList.i(#numAllowedEngines)
Global Dim Disconnect_Flag.b(2)


Global MatchWindowID.i, MatchInfoResult.i
Global Dim OpeningLines.s(#OpeningLines_default)
Global Mnowdate1.s, MDefaultFileName.s, PGNMatchFile.s, EngineMatchLogFile.s
Global SF_Time_Per_Move.i = 500, SF_Time_Per_Move_str.s, tempfilename.s
Global MoveNumber.i, Open_Index1.i, Open_Index2.i, OpeningIndex.i, Open_Ply_Length.i
Global Open_Index1_str.s, Open_Index2_str.s, Open_Ply_Length_str.s
Global GameOne_GameTwo.i
Global maxhalfmoves.i = 400
Global MatchGameCount.i = 0, RoundNumber.s, MatchGameResult.s
Global GamePGN.s, MsgText.s
Global output.s, bestmove.s, uci_info.s, SF_fenPosition.s, filtered_output.s
Global printready_openingline.s, printready_openingline2.s

Global NearZero_Moves_min.i = 10, Draw_MoveNumber_min.i = 45
Global CurrentOpening.s, GamePairs_str.s, GamePairs.i, Editor_LineCount.i = 0
Global CurrentGamePair.i, PairNo.i, FileHandle1.i, FileHandle2.i, FileHandleEng.i, Result.i, ClosebtnResult.i
Global TotalMatchGames.i, playerone.i, playertwo.i, gauntlet_flag.b = #False, Sac_Deficit_filter.i
Global Engii.i, Engjj.i, white_enginename_glbl.s, black_enginename_glbl.s

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
	helpscreen1:
	IncludeBinary "/users/kenpchess/Public/images/FENEditor_screen_33pct.png"
	PGNdbkp_scrollright:
	IncludeBinary "/users/kenpchess/Public/images/PGNdbkp_scrollright_33pct.png"
  
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
  helpscreen1:
  IncludeBinary "C:/PureBasic/images/FENEditor_screen_33pct.png"
  PGNdbkp_scrollright:
  IncludeBinary "C:/PureBasic/images/PGNdbkp_scrollright_33pct.png"
  
EndDataSection
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  IncludeFile "/Users/kenpchess/Public/eco_name_pgn_fen.pb"
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  IncludeFile "C:\PureBasic\eco_name_pgn_fen.pb"
CompilerEndIf

Declare AddInfoTextMsg(MsgText.s)
Declare AddInfoToLogFile(MsgText.s)
Declare AddToResultsGadget(MsgText.s)
Declare AppendPGNToFile(WhiteName.s, BlackName.s, Result.s, GamePGN.s, Opening.s)
Declare BubbleSortEnginePointsDescending()
Declare EngineMatchMain()
Declare GetBestMoveUCIPVMatch(ProgramID, PositionCommand.s, searchTime_ms)
Declare LoadOpeningLines()
Declare Log_Current_Match_Standings()
Declare MatchGame_Insufficient_Mating_Material_Calc()
Declare.s PlayGame(WhiteHandle.i, WhiteName.s, BlackHandle.i, BlackName.s, OpeningPGN.s)
Declare Print_Current_Match_Standings()
Declare Print_Current_Match_Standings2()
Declare.s ReadUCIResponse_EngineMatch(Engine_HandleX.i, timeout_ms = 300)
Declare SendUCICommandMatch(ProgramID, command.s)
Declare Set_MatchGameResult(WhitePlayer1.i,BlackPlayer2.i,MatchGameResult.s)
Declare Set_CurrentPlayingGameInfo(p1ayerone.i,playertwo.i)
Declare StartEngine_Thread(*Value)
Declare Start_or_Restart_GameMatch_Engines(Engine1_Path.s,Engine1_Handle.i,Engine2_Path.s,Engine2_Handle.i)
Declare StopEngine(EngineHandle.i, EngineName.s)
Declare AAA_Dummy_PlaceHolder_EndMatchCode()

Declare Add_Game_To_SQLite_DB()
Declare Add_All_Games_To_SQLite_DB_Thread(*Value)
Declare BoardDisplay()
Declare BoardEditorDisplay()
Declare BoardEmpty()
Declare BoardInitialize()
Declare BoardSqIsEmptyMailbox(square.b)
Declare BuildValidQueenMovesTable()
Declare Calculate_White_Black_Material()
Declare ConstructFENfromPosition()
Declare ConstructPositionfromFEN(FENpositionstr.s)
Declare Convert_UCI_Notation(Passed_UCI_Str.s)
Declare CreateChessboardPDF()
Declare DeepCleanPGNs()
Declare DoEventMacOS()
Declare DisplayGames()
Declare DrawVectorTextDemoData(k.i)
Declare DrawVectorTextDemoDataToImage(k.i)
Declare ECOCodeSearch()
Declare ExportPGNGame()
Declare ExportGameToPDF()
Declare FEN_display_str_Set(index.i)
Declare FreeBoardEditorGadgets()

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  Declare.s FileRequester(RequesterType, Title.s, DefaultFile.s = "", AllowedFileTypes.s = "", Message.s = "", Flags = 0)
CompilerEndIf

Declare GadgetToolTipsSetup()
Declare GameFENEditorPlus()
Declare GameScoreAutomatedTesting_Thread(null)

Declare GetMouseX(gadget)
Declare GetMouseY(gadget)
Declare ReportCursor(msg1.s)

Declare GetBestMoveUCIPV(ProgramID, fen.s, searchTime_ms, MultiPV.b)
Declare KeystrokesMacOs()
Declare KeystrokeShiftKeyCheckOnlyMacOs()
Declare KeystrokesWindowsOs()
Declare LoadPGN_Thread(null)
Declare LoadSQLiteChessDatabase(FileName.s)
Declare Load_ECO_Table()
Declare LoadHelpData()
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
Declare OutputSampleGameCode2()
Declare.s ParseAndCleanPGN(PGNDirtyGameScore.s)
Declare Parse_Save_GameScore_Bare_Halfmoves(GameScore.s)
Declare PDFMove_Thread(null)
Declare PDFAnalysis_Thread(null)
Declare PlayEngine()
Declare PreviousMove()
Declare PrintAsciiBoard(OutputID.i,FileID.i)
Declare PieceIsWhite(Xpiece.b)
Declare PieceIsBlack(Xpiece.b)
Declare PopulateMovesGadget()
Declare Refresh_PlayersListIconGadget(Clean_Flag.b)
Declare ReadUCIResponse(ProgramID, timeout_ms = 100)
Declare RemovePGNCommentsAndVariations2(line.s)
Declare RemoveNumberDotSequenceSpecialNotations(XGameScore_Movelist.s)
Declare SacGamesFilter()
Declare SavePossibleMoveMailBoxSquare(XMailBoxSquare.b)
Declare SANtoUCI_SingleMove(san.s, isWhite.b)
Declare Searching_Sorting()
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

Enumeration main
  #mainwin
  #CanvasGadgetChessBoard
  #Help_window
  #Help_EditorGadget
  #HelpImageGadget1
  #HelpImageGadget2
  #Btn_CloseHelp
  #Engmatchwin
  #InfoMatch_Field
  #GamePlaying_GadgetW
  #GamePlaying_GadgetB
  #TourneyInfo_Gadget
  #TourneyResults_Gadget
  #Btn_CloseMatch
  #Players_ListIcon_Gadget
  #Move_ListIcon_Gadget
  #DbFile_Gadget
  #Btn_SampleData
  #Btn_GSTest
  #Single_Move_Gadget
  #Btn_HelpInfo
  #Btn_Fen
  #Btn_BoardSize
  #Btn_ExportGame
  #Info_Field
  #Btn_CleanPGN
  #Btn_ExportPDF
  #Btn_Prev
  #Btn_Automove
  #Btn_Next
  #Btn_SacFilter
  #Btn_Db1
  #Btn_Db2
  #Btn_ECOCodes
  #Btn_SFAnaly
  #Btn_SF10sec
  #Btn_PlayvsSF
  #Btn_UpdSF
  #Btn_PSearch
  #Btn_EngineMatch
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
  #PGN_Help
  
EndEnumeration

UsePNGImageDecoder()
UsePNGImageEncoder()

;******* from matchmanager code

Procedure AddInfoTextMsg(MsgText.s)
  
  Protected Result.i
  Editor_LineCount = Editor_LineCount + 1
  ;If Left(MsgText,4) = "Info"
   ; SetGadgetItemAttribute(#InfoMatch_Field,  #PB_Ignore, #PB_ListIcon_ColumnWidth, 400, 0)
  ;Else
   ; SetGadgetItemAttribute(#InfoMatch_Field, #PB_Ignore, #PB_ListIcon_ColumnWidth, 345, 0)
   ;EndIf
  If Left(MsgText,4) = "Info" And Len(MsgText) > 50
    Result = AddGadgetItem(#InfoMatch_Field, -1, Left(MsgText,50))
    If Len(MsgText) <= 100
      Result = AddGadgetItem(#InfoMatch_Field, -1, Mid(MsgText,51,50) + #CRLF$)
    Else
      Result = AddGadgetItem(#InfoMatch_Field, -1, Mid(MsgText,51,50))
      Result = AddGadgetItem(#InfoMatch_Field, -1, Mid(MsgText,101,50) + #CRLF$)
    EndIf
   Else
     Result = AddGadgetItem(#InfoMatch_Field, -1, MsgText + #CRLF$)
  EndIf
  Delay(10)
  SetGadgetState(#InfoMatch_Field,CountGadgetItems(#InfoMatch_Field)-1)
  While WindowEvent() : Wend
  

EndProcedure


Procedure AddToResultsGadget(MsgText.s)
  
  Protected Result.i
  
  Result = AddGadgetItem(#TourneyResults_Gadget, -1, MsgText + #CRLF$)
  SetGadgetState(#TourneyResults_Gadget,CountGadgetItems(#TourneyResults_Gadget)-1)
  While WindowEvent() : Wend
  
  
EndProcedure



Procedure AddInfoToLogFile(MsgText.s)
  
  If FileHandle2
    WriteStringN(FileHandle2, MsgText)
  EndIf
  
EndProcedure



Procedure AppendPGNToFile(WhiteName.s, BlackName.s, Result.s, GamePGN.s, Opening.s)
  Protected FileHandle.i
  
  FileHandle = OpenFile(#PB_Any, PGNMatchFile, #PB_File_Append)
  If FileHandle
    ; PGN Tags
    WhiteName = ReplaceString(WhiteName,"(Player 1)","") : WhiteName = ReplaceString(WhiteName,"(Player 2)","")
    BlackName = ReplaceString(BlackName,"(Player 2)","") : BlackName = ReplaceString(BlackName,"(Player 1)","")
    WriteStringN(FileHandle, "[Event 'PGNdbkp UCI Engine Match: " + " TC = " + SF_Time_Per_Move_str + "ms" + "']")
    WriteStringN(FileHandle, "[Site 'PGNdbkp Test Rig']")
    WriteStringN(FileHandle, "[Date " + FormatDate("%YYYY.%MM.%DD", Date()) + "]")
    Select GameOne_GameTwo
      Case 1
        WriteStringN(FileHandle, "[Round " + "'" + RoundNumber + Str(Engii) + "w-" + Str(Engjj) + "b" + " G" + Str(MatchGameCount) + "'" + "]")
      Case 2
        WriteStringN(FileHandle, "[Round " + "'" + RoundNumber + Str(Engii) + "b-" + Str(Engjj) + "w" + " G" + Str(MatchGameCount) + "'" + "]")
    EndSelect
    WriteStringN(FileHandle, "[White " + "'" + WhiteName + "'" + "]")
    WriteStringN(FileHandle, "[Black " + "'" + BlackName + "'" + "]")
    WriteStringN(FileHandle, "[Result " + "'" + Result + "'" + "]")
    WriteStringN(FileHandle, "[Opening " + "'" + Opening + "'"  + "]")
    
    ; Moves and Result
    WriteStringN(FileHandle, "")
    WriteStringN(FileHandle, RTrim(GamePGN) + " " + Result)
    WriteStringN(FileHandle, "")
    WriteStringN(FileHandle, #CRLF$)
    CloseFile(FileHandle)
  Else
    Debug "Error: Could not open PGN file for writing."
  EndIf
EndProcedure


Procedure BubbleSortEnginePointsDescending()
  Protected ii.i, jj.i, temp.f, temp2.i
  Protected Dim Engine_ScorePoints_Sorted.f(Engine_Count)
  
  For ii = 1 To Engine_Count : Engine_SortList(ii) = ii : Next
  For ii = 1 To Engine_Count : Engine_ScorePoints_Sorted(ii) = Engine_ScorePoints(ii) : Next
  
  For ii = 1 To Engine_Count
    For jj = 1 To Engine_Count - ii
      If Engine_ScorePoints_Sorted(jj) < Engine_ScorePoints_Sorted(jj + 1)
        ; Swap elements
        temp = Engine_ScorePoints_Sorted(jj) : temp2 = Engine_SortList(jj)
        Engine_ScorePoints_Sorted(jj) = Engine_ScorePoints_Sorted(jj + 1) : Engine_SortList(jj) = Engine_SortList(jj+1)
        Engine_ScorePoints_Sorted(jj + 1) = temp : Engine_SortList(jj+1) = temp2
      EndIf
    Next jj
  Next ii
EndProcedure



Procedure MatchGame_Insufficient_Mating_Material_Calc()
  
  ; this routine is not yet fully coded, there are other (very rare) chess material boundary conditions not yet checked
  
  Protected i.i, White.b = 1, Black.b = 2
  Protected Dim Number_Of_Minor_Pieces.i(2)
  Protected Dim Number_Of_Major_Pieces_Or_Pawns.i(2)
  Protected Dim Number_Of_Bishops.i(2)
  Protected Dim Number_Of_Knights.i(2)
  Protected Dim Number_Of_Rooks.i(2)
  
  Number_Of_Minor_Pieces(White) = 0 : Number_Of_Minor_Pieces(Black) = 0
  Number_Of_Bishops(White) = 0 : Number_Of_Bishops(Black) = 0
  Number_Of_Knights(White) = 0 : Number_Of_Knights(Black) = 0
  Number_Of_Rooks(White) = 0 : Number_Of_Rooks(Black) = 0
  Number_Of_Major_Pieces_Or_Pawns(White) = 0 : Number_Of_Major_Pieces_Or_Pawns(Black) = 0
  matchgame_insufficient_mating_material_flag = #False
  
  For i = 1 To 119
    If MbxBrd(i) <> #OffTheBoard And MbxBrd(i) <> _emptysq
      Select MbxBrd(i)
        Case Wrook
          Number_Of_Major_Pieces_Or_Pawns(White) = Number_Of_Major_Pieces_Or_Pawns(White) + 1
          Number_Of_Rooks(White) = Number_Of_Rooks(White) + 1
        Case Wpawn, Wqueen
          Number_Of_Major_Pieces_Or_Pawns(White) = Number_Of_Major_Pieces_Or_Pawns(White) + 1
          Break
        Case Wbishop
          Number_Of_Minor_Pieces(White) = Number_Of_Minor_Pieces(White) + 1
          Number_Of_Bishops(White) = Number_Of_Bishops(White) + 1
        Case Wknight
          Number_Of_Minor_Pieces(White) = Number_Of_Minor_Pieces(White) + 1
          Number_Of_Knights(White) = Number_Of_Knights(White) + 1
        Case Brook
          Number_Of_Major_Pieces_Or_Pawns(Black) = Number_Of_Major_Pieces_Or_Pawns(Black) + 1
          Number_Of_Rooks(Black) = Number_Of_Rooks(Black) + 1
        Case Bpawn, Bqueen
          Number_Of_Major_Pieces_Or_Pawns(Black) = Number_Of_Major_Pieces_Or_Pawns(Black) + 1
          Break
        Case Bbishop
          Number_Of_Minor_Pieces(Black) = Number_Of_Minor_Pieces(Black) + 1
          Number_Of_Bishops(Black) = Number_Of_Bishops(Black) + 1
        Case Bknight
          Number_Of_Minor_Pieces(Black) = Number_Of_Minor_Pieces(Black) + 1
          Number_Of_Knights(Black) = Number_Of_Knights(Black) + 1
        Case Wking, Bking
          ; we just ignore the kings because they are always on the board (never captured!)
      EndSelect
    EndIf
  Next
  
  If Number_Of_Major_Pieces_Or_Pawns(White) = 1 And Number_Of_Rooks(White) = 1 And Number_Of_Minor_Pieces(White) = 0
    If Number_Of_Major_Pieces_Or_Pawns(Black) = 0 And Number_Of_Minor_Pieces(Black) = 1 And Number_Of_Bishops(Black) = 1
      ; white rook vs black bishop
      matchgame_insufficient_mating_material_flag = #True         ; not completely chess correct, but good for computer matches!
    EndIf
  EndIf
  
  If Number_Of_Major_Pieces_Or_Pawns(Black) = 1 And Number_Of_Rooks(Black) = 1 And Number_Of_Minor_Pieces(Black) = 0
    If Number_Of_Major_Pieces_Or_Pawns(White) = 0 And Number_Of_Minor_Pieces(White) = 1 And Number_Of_Bishops(White) = 1
      ; black rook vs white bishop
      matchgame_insufficient_mating_material_flag = #True         ; not completely chess correct, but good for computer matches!
    EndIf
  EndIf
  
  If Number_Of_Major_Pieces_Or_Pawns(White) = 0 And Number_Of_Minor_Pieces(White) = 2 And Number_Of_Knights(White) = 2
    If Number_Of_Major_Pieces_Or_Pawns(Black) = 0 And Number_Of_Minor_Pieces(Black) = 0
      ; two knights cannot checkmate a lone king!
      matchgame_insufficient_mating_material_flag = #True
    EndIf
  EndIf
  
  If Number_Of_Major_Pieces_Or_Pawns(Black) = 0 And Number_Of_Minor_Pieces(Black) = 2 And Number_Of_Knights(Black) = 2
    ; two knights cannot checkmate a lone king!
    If Number_Of_Major_Pieces_Or_Pawns(White) = 0 And Number_Of_Minor_Pieces(White) = 0
      matchgame_insufficient_mating_material_flag = #True
    EndIf
  EndIf
  
  If Number_Of_Major_Pieces_Or_Pawns(White) = 0 And Number_Of_Major_Pieces_Or_Pawns(Black) = 0
    If Number_Of_Minor_Pieces(White) <= 1 And Number_Of_Minor_Pieces(Black)  <= 1
      matchgame_insufficient_mating_material_flag = #True
    EndIf
  Else
    matchgame_insufficient_mating_material_flag = #False                   ; pawns or rooks or queens CAN obviously be mating material
  EndIf
  
EndProcedure



Procedure.s PlayGame(WhiteHandle.i, WhiteName.s, BlackHandle.i, BlackName.s, OpeningPGN.s)
  ; This procedure manages all game state locally and returns the final result string.
  
  Protected WhiteEngineHandle.i, BlackEngineHandle.i
  Protected WhiteEngineName.s, BlackEngineName.s
  
  ; Local game state variables
  Protected ToMove.s, MoveList.s, Any_Promotion.s, MoveMsg.s
  Protected Result.s = "*",  MoveCount.i = 0, position_count = 0
  Protected CurrentHandle.i, CurrentName.s, tempscore.s, turnColor.i, move_hist_loop.i
  Protected zero_counter.b, zero_score_flag.b, j.i, space_pos.i
  Protected BestMove_UCI.s, OpeningMove_UCI.s, Opening_Move.s, z.i
  Protected fen_zero_space1.i, fen_zero_space2.i, wdl_pos.i
  Protected previous_whitemove.s, previous_blackmove.s, match_or_tourney.s
  Protected Eng_short1.s, bookmovepair.s
  
  ; Assign local and global variables from arguments
  WhiteEngineHandle = WhiteHandle
  BlackEngineHandle = BlackHandle
  WhiteEngineName = WhiteName
  BlackEngineName = BlackName
  white_enginename_glbl = WhiteName
  black_enginename_glbl = BlackName
  
  ; Set up initial position with opening moves i.e. e2e4 e7e5 g1f3 b8c6 f1c4 g8f6 f3g5 d7d5 ...
  
  MoveList = OpeningPGN
  Disconnect_Flag(1) = #False : Disconnect_Flag(2) = #False
  space_pos = 0 : printready_openingline = "" : printready_openingline2 = ""
  For j = 1 To 200
    Space_pos = FindString(MoveList,Space(1),space_pos+1)
    If space_pos = 0
      ;printready_openingline = printready_openingline + Str(j/2) + ". " + Right(MoveList,10) + Space(1)
      Break
    Else
      If j % 2 = 0
        printready_openingline = printready_openingline + Str(j/2) + ". " + Mid(MoveList,space_pos-9,9) + Space(1)
        printready_openingline2 = printready_openingline2 + Str(j/2) + ". " + Mid(MoveList,space_pos-9,2) + "-" + Mid(MoveList,space_pos-7,3) + Mid(MoveList,space_pos-4,2) + "-" + Mid(MoveList,space_pos-2,2) + Space(1)
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN("opening UCI reaady = " + printready_openingline2)
        CompilerEndIf
      EndIf
    EndIf
  Next
  ;PrintN("PrintReady_OpeningLine = " + printready_openingline)
  
  ; Determine whose turn it is after the opening, (actually always White with my current opening file)
  If CountString(MoveList, " ") % 2 = 0 ; White to move
    ToMove = "w"
  Else ; Black to move (odd number of half-moves)
    ToMove = "b"
  EndIf
  
  ; Initialize PGN with opening moves (as placeholder)
  GamePGN = printready_openingline2
  ;AddInfoTextMsg("Info...Opening #" + Str(CurrentGamePair) + "..." + printready_openingline2)
  
  AddInfoTextMsg("Info...Opening #" + Str(CurrentGamePair))
  z = 0
  For j = 1 To Len(MoveList) Step 10
    z = z + 1
    bookmovepair = Mid(MoveList,j,10)
    AddInfoTextMsg("Tourney game " + Str(MatchGameCount) + " of " + Str(TotalMatchGames) + "...opening book moves..." +  Chr(10) + Str(z) + "." + Space(1) + Left(bookmovepair,4) + Chr(10) + "book" + Chr(10) + Mid(bookmovepair,6,4) + Chr(10) + "book")
  Next
    
  While WindowEvent() : Wend
  
  Global PositionCommand.s = "position startpos moves " + MoveList
  
  BoardInitialize()
  
  For z = 1 To Len(OpeningPGN) - 4 Step 5        ; a bit tricky, parses halfmoves at character 1,6,11,16,21,26,31,36,41,46,51,56,61,66,71,76
    Opening_Move = Mid(OpeningPGN,z,4)
    OpeningMove_UCI = Left(Opening_Move,2) + "-" + Mid(Opening_Move,3,2)
    MoveNumber = (z-1)/10 + 1
    HalfMoveCount = (z-1)/5 + 1
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      PrintN("...PlayGame routine - MoveNumber = " + Str(MoveNumber) + " HalfMoveCount = " + Str(HalfMoveCount) + " Openingmove_UCI = " + OpeningMove_UCI)
    CompilerEndIf
    
    Convert_UCI_Notation(OpeningMove_UCI)
    If HalfMoveCount % 2 > 0 : turnColor = 1 : Else : turnColor = 2 : EndIf
    ConstructFENfromPosition()
    position_history(MoveNumber,turnColor) = FENpositionstr
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      PrintN("...PlayGame routine - FENposition_str = " + position_history(MoveNumber,turnColor))
    CompilerEndIf
  
    If match_noboard_flag = #False                ; if you don't show the moves on the board, a match runs a bit quicker and more smoothly
      BoardDisplay()
      While WindowEvent() : Wend
      Delay(300)
    EndIf
  Next
  
  ; Game loop
  
  MoveNumber = Len(OpeningPGN)/10
  
  Repeat
    
    If ToMove = "w"
      CurrentHandle = WhiteEngineHandle
      CurrentName = WhiteEngineName
      turnColor = 1
      MoveNumber = MoveNumber + 1
    Else
      CurrentHandle = BlackEngineHandle
      CurrentName = BlackEngineName
      turnColor = 2
    EndIf
    
    ; a. Request move
    PositionCommand = "position startpos moves " + MoveList
    GetBestMoveUCIPVMatch(CurrentHandle, PositionCommand,SF_Time_Per_Move)
    BestMove = Trim(BestMove,Space(1)) : BestMove = Trim(BestMove,Chr(10)) : BestMove = Trim(BestMove,Chr(13))
    Move_History(MoveNumber,turnColor) = BestMove
    BestMove_UCI = Left(bestmove,2) + "-" + Trim(Mid(bestmove,3,3),Space(1))
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      PrintN("Bestmove_UCI = " + BestMove_UCI)
    CompilerEndIf
    
    If FindString(BestMove,"mate") <= 0
     Convert_UCI_Notation(BestMove_UCI)
    EndIf
    
    If match_noboard_flag = #False
      BoardDisplay()
      While WindowEvent() : Wend
      Delay(25)
    EndIf
    
    HalfMoveCount = HalfMoveCount + 1
    ConstructFENfromPosition()
    position_history(MoveNumber,turnColor) = FENpositionstr
    
    If MoveNumber % 5 = 0
      PrintAsciiBoard(2,FileHandle2)
    EndIf
    
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      PrintN("...PlayGame routine - FENposition_str = " + position_history(MoveNumber,turnColor))
      PrintN("...PlayGame routine - Move number = " + Str(MoveNumber) + "  BESTMOVE = " + bestmove)
    CompilerEndIf
    AddInfoToLogFile("...PGR - FENposition_str = " + position_history(MoveNumber,turnColor))
    AddInfoToLogFile("...PGR - Move number =  " + Str(MoveNumber) + "  BESTMOVE = " + bestmove)
    
    
    tempscore = cpscore_str(1)
    tempscore = ReplaceString(tempscore,"upperbound","") : tempscore = ReplaceString(tempscore,"lowerbound","")
    tempscore = ReplaceString(tempscore," multipv 1","")
    wdl_pos = FindString(tempscore,"wdl ")
    If wdl_pos > 0
      tempscore = Left(tempscore,wdl_pos-2)
    EndIf
    Score_History(MoveNumber,turnColor) = Trim(tempscore,Space(1))
    If ToMove = "w"
      MoveMsg = Str(MoveNumber) + "." + Space(1) + bestmove + Chr(10) + tempscore + Chr(10)
    Else
      MoveMsg = MoveMsg + bestmove + Chr(10) + tempscore
      If Engine_Count > 2
        match_or_tourney = "Tourney Game "
      Else
        match_or_tourney = "Match Game "  
      EndIf
      AddInfoTextMsg(match_or_tourney + Str(MatchGameCount) + " of " + Str(TotalMatchGames) + Chr(10) + MoveMsg)             ; print the entire full move to the window
      AddInfoToLogFile(match_or_tourney + Str(MatchGameCount) + " of " + Str(TotalMatchGames) + Space(5) + ReplaceString(MoveMsg,Chr(10),""))
      MoveMsg = ""
      While WindowEvent() : Wend
    EndIf
    
    ; patch below for iffy engine behaviors (a)
    If (BestMove="mate" Or BestMove="mate 1") And FindString(Score_History(MoveNumber-1,turnColor),"mate") > 0 And FindString(Score_History(MoveNumber-2,turnColor),"mate") > 0
      Select turnColor
        Case 1                 ; white has probably mated, black did not make meaningful reply
          Result = "1-0"       ; 
          ;ProcedureReturn Result
        Case 2                 ; black has probably mated, white did not make meaningful reply
          Result = "0-1"       ;
          ;ProcedureReturn Result
      EndSelect
      
      AddInfoToLogFile(CurrentName + " Engine has likely mated, engine opponent possibly made no move or illegal move (disconnect).")
      AddInfoToLogFile(#CRLF$)
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN(CurrentName + " Engine has likely mated, engine opponent possibly made no move or illegal move (disconnect).")
      CompilerEndIf
      ;Break
      AppendPGNToFile(WhiteEngineName, BlackEngineName, Result, GamePGN, OpeningPGN)
      ProcedureReturn Result
    EndIf
    
    ; patch below for more bad engine behaviors (b)
    If BestMove = "a1a1" Or BestMove = "0000" Or BestMove = "mate 0" Or FindString(BestMove,"(none)") > 0 Or BestMove = Move_History(MoveNumber-1,turnColor)
      ; Engine failed to move, usually indicates a terminal state (stalemate), or some engines 'misbehave' when about to be mated!
      Select turnColor
        Case 1                 ; white would ordinarily lose on Disconnect, probably a loss anyway
          Result = "0-1" 
          ;Disconnect_Flag(1) = #True
          ;Result = "1/2-1/2" : Disconnect_Flag(1) = #True
          ;Break
        Case 2                 ; black would ordinarily lose on Disconnect, probably a loss anyway
          Result = "1-0"
          ;Disconnect_Flag(2) = #True
          ;Result = "1/2-1/2" : Disconnect_Flag(2) = #True
          ;Break
      EndSelect
      
      AddInfoToLogFile(CurrentName + " engine returned no move or illegal move (disconnect). Discon flag is set." + "Bestmove = " + Bestmove)
      AddInfoToLogFile(#CRLF$)
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN(CurrentName + " engine returned no move (disconnect). Disconnect flag is set.")
      CompilerEndIf
      ;Break
      AppendPGNToFile(WhiteEngineName, BlackEngineName, Result, GamePGN, OpeningPGN)
      ProcedureReturn Result
    EndIf
    
    ; patch below for more bad engine behaviors (c)
    If BestMove = ""     ; some strange no-moves, gonna set these to drawn or loss and set the disconnect flag, temporarily
      Result = "1/2-1/2"
      If Val(Score_History(MoveNumber-2,turnColor)) < -100 Or FindString(Score_History(MoveNumber-1,turnColor),"mate -") > 0
        If turnColor = 1
          Result = "0-1"
        Else
          Result = "1-0"
        EndIf
      Else
        If MoveNumber = Len(OpeningPGN)/10 Or MoveNumber = (Len(OpeningPGN)/10) + 1 
          Disconnect_Flag(turnColor) = #True                    ; maybe ignore the engine opening glitches for now
        EndIf
      EndIf
      
      AddInfoToLogFile(CurrentName + " engine returned no move or (disconnect). Might be an opening glitch. Game result is temporarily drawn." + "Bestmove = " + Bestmove)
      AddInfoToLogFile(#CRLF$)
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN(CurrentName + " engine returned no move (disconnect). Might be an opening glitch. Game result is temporarily drawn.")
      CompilerEndIf
      AppendPGNToFile(WhiteEngineName, BlackEngineName, Result, GamePGN, OpeningPGN)
      ProcedureReturn Result
    EndIf
    
    position_count = 0
    fen_zero_space1 = FindString(FENpositionstr,"0 ")
    For move_hist_loop = 1 To MoveNumber
      fen_zero_space2 = FindString(position_history(move_hist_loop,turnColor),"0 ")
      If Left(FENpositionstr,fen_zero_space1-1) = Left(position_history(move_hist_loop,turnColor),fen_zero_space2-1)
        position_count = position_count + 1
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN("FEN position draw count match found: " + FENpositionstr)
        CompilerEndIf
      EndIf
    Next
    If position_count >= 3
      If (Move_History(MoveNumber-1,turnColor)="mate" Or Move_History(MoveNumber-1,turnColor)="mate 1" Or bestmove="mate" Or bestmove="mate 1")  And FindString(bestmove,"-") <= 0
        Select turnColor
          Case 1                 ; white
            Result = "1-0"
            Break
          Case 2                 ; black
            Result = "0-1"
            Break
        EndSelect
      Else
        Result = "1/2-1/2"
      EndIf
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN("PGNdbkp match manager - Draw by three-fold repetition. Game result set to Draw.")
      CompilerEndIf
      AddInfoTextMsg(#CRLF$) : AddInfoTextMsg("Info...PGNdbkp match manager - Draw by three-fold repetition. Game result set to Draw.") : AddInfoTextMsg(#CRLF$)
      AddInfoToLogFile(#CRLF$) : AddInfoToLogFile("PGNdbkp match manager - Draw by three-fold repetition. Game result set to Draw.") : AddInfoToLogFile(#CRLF$)
      Break  
    EndIf
    
    If ToMove = "w"
      previous_whitemove = bestmove
      If (Trim(BestMove,Space(1)) = "mate 1" Or Trim(BestMove,Space(1)) = "mate 2" Or Trim(tempscore," ") = "mate 2") And FindString(Bestmove,"mate -") <= 0
        ; Engine (checkmate)
        Result = "1-0" 
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN(CurrentName + " engine returned mate. Game result is 1-0")
        CompilerEndIf
        AddInfoToLogFile(CurrentName + " engine returned mate. Game result is 1-0.")
        AddInfoToLogFile(#CRLF$)
        Break
      EndIf
      If Trim(BestMove,Space(1)) = "mate -1" Or Trim(BestMove,Space(1)) = "mate -2" Or Trim(tempscore," ") = "mate -2"
        ; Engine (checkmate by opponent)
        Result = "0-1" 
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN(CurrentName + " engine returned mate by opponent. Game result is 0-1")
        CompilerEndIf
        AddInfoToLogFile(CurrentName + " engine returned mate by opponent. Game result is 0-1.")
        AddInfoToLogFile(#CRLF$)
        Break
      EndIf
    EndIf
    
    If ToMove = "b"
      previous_blackmove = bestmove
      If (Trim(BestMove,Space(1)) = "mate 2" Or Trim(BestMove,Space(1)) = "mate 1" Or Trim(tempscore," ") = "mate 2") And FindString(Bestmove,"mate -") <= 0
        ; Engine (checkmate)
        Result = "0-1" 
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN(CurrentName + " engine returned mate. Game result is 0-1")
        CompilerEndIf
        AddInfoToLogFile(CurrentName + " engine returned mate. Game result is 0-1.")
        AddInfoToLogFile(#CRLF$)
        Break
      EndIf
      If Trim(BestMove," ") = "mate -2" Or Trim(BestMove," ") = "mate -1" Or Trim(tempscore," ") = "mate -2"
        ; Engine (checkmate by opponent)
        Result = "1-0" 
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN(CurrentName + " engine returned mate by opponent. Game result is 1-0")
        CompilerEndIf
        AddInfoToLogFile(CurrentName + " engine returned mate by opponent. Game result is 1-0.")
        AddInfoToLogFile(#CRLF$)
        Break
      EndIf
    EndIf
    
    Select tempscore
        Case "0","-1","-2","-3","-4","-5","-6","-7","-8","-9","-10","1","2","3","4","5","6","7","8","9","10"
          zero_score_flag = #True
          zero_counter = zero_counter + 1
        Default
          zero_score_flag = #False
          zero_counter = 0
    EndSelect
        
    If zero_score_flag = #True And zero_counter >= NearZero_Moves_min And MoveNumber >= Draw_MoveNumber_min
      Result = "1/2-1/2" 
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN(CurrentName + " multi-fold consecutive near-zero score with " + Str(Draw_MoveNumber_min)  + " or more moves. Game result set To Draw.")
      CompilerEndIf
      AddInfoTextMsg(#CRLF$)
      Eng_short1 = ReplaceString(CurrentName,"Match","") : Eng_short1 = ReplaceString(Eng_short1,"ine","")
      AddInfoTextMsg("Info..." + Eng_short1 + " multi-fold consecutive near-zero score With " + Str(Draw_MoveNumber_min)  + " Or more moves. Game result set To Draw.")
      AddInfoTextMsg(#CRLF$)
      AddInfoToLogFile(#CRLF$)
      AddInfoToLogFile(CurrentName + " multi-fold consecutive near-zero score with " + Str(Draw_MoveNumber_min)  + " or more moves. Game result set To Draw.")
      AddInfoToLogFile(#CRLF$)
      Break
    EndIf
    
    ; Append the UCI move to the move list
    If MoveList <> "" And MoveList <> OpeningPGN
      MoveList = MoveList + Space(1)
    EndIf

    MoveList = MoveList + BestMove
    ; PGN tracking
    MoveNumber = (CountString(MoveList, " ")/2) + 1
    
    If Len(bestmove) >= 5
      Any_Promotion = Mid(bestmove,5,1)
    Else
      Any_Promotion = ""
    EndIf
    
    If ToMove = "w"
      GamePGN = GamePGN + Str(MoveNumber) + ". " + Left(BestMove,2) + "-" + Mid(BestMove,3,2) + Any_Promotion + Space(1)
      ToMove = "b" ; Flip turn
    Else
      GamePGN = GamePGN + Left(BestMove,2) + "-" + Mid(BestMove,3,2) + Any_Promotion + Space(1)
      ToMove = "w" ; Flip turn
    EndIf
    
    MoveCount = MoveCount + 1
    
    MatchGame_Insufficient_Mating_Material_Calc()
    If matchgame_insufficient_mating_material_flag = #True
      Result = "1/2-1/2"
      AddInfoTextMsg(#CRLF$)
      AddInfoTextMsg("Info...Insufficient mating material! Game result set to Draw.")
      AddInfoToLogFile(#CRLF$)
      AddInfoToLogFile("...Insufficient mating material! Game result set to Draw.")
      AddInfoToLogFile(#CRLF$)
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN("...Insufficient mating material! Game result set to Draw.")
      CompilerEndIf
      Break
    EndIf
    
    If MoveCount >= maxhalfmoves
      Result = "1/2-1/2" ; Draw by move limit
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN("Draw by move limit reached.")
      CompilerEndIf
      AddInfoToLogFile("Draw by move limit reached.")
      Break
    EndIf
 
  Until MoveCount >= maxhalfmoves
  
  ; Final Result Parsing (Placeholder logic)
  If Result = "*"
    Result = "1/2-1/2" ; Draw
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      PrintN("WARNING: Result not determined. Full result detection probably requires engine analysis of the final position.")
    CompilerEndIf
  EndIf
  
  ; 4. Log the game
  AppendPGNToFile(WhiteEngineName, BlackEngineName, Result, GamePGN, OpeningPGN)
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("Game Result: " + Result)
  CompilerEndIf
  
  ; Return the result string to the main loop for score update
  ProcedureReturn Result
EndProcedure


Procedure EngineMatchMain()
  
  Protected Somefile.s, slash_pos.i, Draw_Eval_str.s, move_hist_loop.i, GamePlayResultW.i, GamePlayResultB.i
  Protected p1.i, p2.i, ii.i, jj.i, kk.i, zz.i, TourneyInfoResult.i, TourneyResultsResult.i
  Protected Eng_short1.s, Eng_short2.s
  ; Set initial global engine values
  
  For jj = 1 To Engine_Count
    Engine_Name(jj) = "MatchEngine" + Chr(64+jj) + " (Player " + Str(jj) + ")"
  Next

DeleteFile(PGNMatchFile)
PrintN("Log file " + PGNMatchFile + " cleared. Prepare to start match...")

; Load opening lines
LoadOpeningLines()

Mnowdate1 = FormatDate("%yyyy%mm%dd%hh%ii%ss", Date())
MDefaultFileName = "/Users/kenpchess/Desktop/PGNdbkp_engmatch_" + Mnowdate1 + ".pgn"

PGNMatchFile = SaveFileRequester("Save the currently selected PGN match game (change location, etc.)?", MDefaultFileName, Pattern, 0)
tempfilename = PGNMatchFile : tempfilename = ReplaceString(PGNMatchFile,".pgn",".log")
EngineMatchLogFile = tempfilename
FileHandle2 = OpenFile(#PB_Any, EngineMatchLogFile, #PB_File_Append)

;wflags = #PB_Window_SizeGadget | #PB_Window_SystemMenu | #PB_Window_ScreenCentered
wflags = #PB_Window_SizeGadget | #PB_Window_SystemMenu
MatchWindowID = OpenWindow(#engmatchwin, 1100, 50, 750, 990, "PGNdbkp" + version + " Engine Match Manager & Viewer", wflags)
MatchInfoResult = ListIconGadget(#InfoMatch_Field, 50, 85, 650, 425, "Engine Match Information",345, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
AddGadgetColumn(#InfoMatch_Field, 1, "White", 80)
AddGadgetColumn(#InfoMatch_Field, 2, "wScore", 75)
AddGadgetColumn(#InfoMatch_Field, 3, "Black", 75)
AddGadgetColumn(#InfoMatch_Field, 4, "bScore", 75)
GamePlayResultW = StringGadget(#GamePlaying_GadgetW, 50, 20, 650, 25, "Current game: ")
GamePlayResultB = StringGadget(#GamePlaying_GadgetB, 50, 50, 650, 25, "Current game: ")
TourneyInfoResult = StringGadget(#TourneyInfo_Gadget,50, 520, 650, 25, "Tourney Info: ")
TourneyResultsResult = ListIconGadget(#TourneyResults_Gadget, 50, 560, 650, 380,"Scoring Results Sorted: Engine Name and Path",375, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
AddGadgetColumn(#TourneyResults_Gadget, 1, "Wins", 50)
AddGadgetColumn(#TourneyResults_Gadget, 2, "Draws", 50)
AddGadgetColumn(#TourneyResults_Gadget, 3, "Losses", 50)
AddGadgetColumn(#TourneyResults_Gadget, 4, "Discon", 50)
AddGadgetColumn(#TourneyResults_Gadget, 5, "Points", 50)
ClosebtnResult = ButtonGadget(#Btn_CloseMatch, 320, 955, 120, 25, "Close Match")

Delay(10)
While WindowEvent() : Wend

Repeat
  Open_Index1_str = InputRequester("Openings index Start [always White and Black]","There are 20000 built-in openings. Choose openings starting index [1-20000]","500")
  Open_Index1 = Val(Open_Index1_str)
  Open_Index2_str = InputRequester("Openings index End [always White and Black]","Choose openings ending index [" + Str(Open_Index1+1) + "-" + "20000" + "]", Str(Open_Index1+100))
  Open_Index2 = Val(Open_Index2_str)
Until Open_Index2 > Open_Index1

GamePairs = Open_Index2 - Open_Index1 + 1

Repeat
  Open_Ply_Length_str = InputRequester("Openings Ply Length","Enter the openings ply length. Choose openings ply (ply=half-move) length (always even) [6-16]","16")
  Open_Ply_Length = Val(Open_Ply_Length_str)
Until Open_Ply_Length >=6 And Open_Ply_Length <= 16 And Open_Ply_Length % 2 = 0
Open_Ply_Length = Val(Open_Ply_Length_str)

Repeat
  Draw_Eval_str = InputRequester("Engine match manager draw eval parameters]","Number of consecutive near-zero-score moves[min=5] and minimum moves draw number[min=40]: [i.e. 10/50]","10/50")
  slash_pos = FindString(Draw_Eval_str,"/")
  NearZero_Moves_min = Val(Left(Draw_Eval_str,slash_pos-1))
  Draw_MoveNumber_min = Val(Mid(Draw_Eval_str,slash_pos+1,3))
Until NearZero_Moves_min >= 5 And Draw_MoveNumber_min >= 40

Repeat
  SF_Time_Per_Move_str = InputRequester("Engine move time [and board/noboard display, and /gauntlet]","Number of milliseconds for engines move time [100-30000]/noboard/gauntlet","1000")
  If FindString(SF_Time_Per_Move_str,"/noboard") > 0
    match_noboard_flag = #True
    SF_Time_Per_Move_str = ReplaceString(SF_Time_Per_Move_str,"/noboard","")
  Else
    match_noboard_flag = #False
  EndIf
  If FindString(SF_Time_Per_Move_str,"/gauntlet") > 0
    gauntlet_flag = #True
    SF_Time_Per_Move_str = ReplaceString(SF_Time_Per_Move_str,"/gauntlet","")
  Else
    gauntlet_flag = #False
  EndIf
  SF_Time_Per_Move = Val(SF_Time_Per_Move_str)
Until SF_Time_Per_Move >= 100 And SF_Time_Per_Move <= 30000
SF_Time_Per_Move = Val(SF_Time_Per_Move_str)

If gauntlet_flag = #True
  TotalMatchGames = GamePairs * 2 * (Engine_Count-1)
  SetGadgetText(#TourneyInfo_Gadget,"Tourney Info: " + "Engines: " + Str(Engine_Count) + "  Games/Round: " + Str((Engine_Count-1)*2) + "  Total Games: " + Str(TotalMatchGames) + " GA "+ Space(10) + "Openings Index: " + Open_Index1_str + "-" + Open_Index2_str)
Else
  TotalMatchGames = GamePairs * Engine_Count * (Engine_Count-1)
  SetGadgetText(#TourneyInfo_Gadget,"Tourney Info: " + "Engines: " + Str(Engine_Count) + "  Games/Round: " + Str(Engine_Count*(Engine_Count-1)) + "  Total Games: " + Str(TotalMatchGames) + " RR " + Space(10) + "Openings Index: " + Open_Index1_str + "-" + Open_Index2_str)
EndIf

AddInfoTextMsg("Info - PGNdbkp" + version + " - Book opening lines (" + Str(Open_Ply_Length) + "-ply) Index: " + Open_Index1_str + " To " + Open_Index2_str + ".") : AddInfoTextMsg(#CRLF$)
AddInfoToLogFile("PGNdbkp" + version + " - This match using Book opening lines (" + Str(Open_Ply_Length) + "-ply) Index: " + Open_Index1_str + " To " + Open_Index2_str + ".") : AddInfoToLogFile(#CRLF$)
For OpeningIndex = Open_Index1 To Open_Index2
  AddInfoTextMsg("Info - Book Index " + Str(OpeningIndex) + " Opening Line: " + Left(OpeningLines(OpeningIndex),Open_Ply_Length*5)) 
  AddInfoToLogFile("Book Index " + Str(OpeningIndex) + " Opening Line: " + Left(OpeningLines(OpeningIndex),Open_Ply_Length*5))
Next
AddInfoTextMsg(#CRLF$) : AddInfoToLogFile(#CRLF$)

;AddInfoTextMsg("MatchEngineA = " + Engine_Path(1)) : AddInfoToLogFile("MatchEngineA = " + Engine_Path(1)) 
For zz = 1 To Engine_Count
  AddInfoTextMsg("Info - Eng" + Chr(64+zz) + " = " + Engine_Path(zz))
  AddInfoToLogFile("MatchEngine" + Chr(64+zz) + " = " + Engine_Path(zz))
Next
AddInfoTextMsg(#CRLF$) : AddInfoToLogFile(#CRLF$)

AddInfoTextMsg("Info - Consecutive near-zero-score moves parameter = " + Str(NearZero_Moves_min)) : AddInfoToLogFile("Consecutive near-zero-score moves parameter = " + Str(NearZero_Moves_min))
AddInfoTextMsg("Info - Game minimum movenumber draw parameter = " + Str(Draw_MoveNumber_min)) : AddInfoToLogFile("Game minimum movenumber draw parameter = " + Str(Draw_MoveNumber_min))
AddInfoTextMsg(#CRLF$) : AddInfoToLogFile(#CRLF$)

If match_noboard_flag = #True
  AddInfoTextMsg("NoBoard display flag = True") : AddInfoTextMsg(#CRLF$)
  AddInfoToLogFile("NoBoard display flag = True") : AddInfoToLogFile(#CRLF$)
Else
  AddInfoTextMsg("NoBoard display flag = False") : AddInfoTextMsg(#CRLF$)
  AddInfoToLogFile("NoBoard display flag = False") : AddInfoToLogFile(#CRLF$)
EndIf

If gauntlet_flag = #True
  AddInfoTextMsg("gauntlet flag = True") : AddInfoTextMsg(#CRLF$)
  AddInfoToLogFile("gauntlet flag = True") : AddInfoToLogFile(#CRLF$)
Else
  AddInfoTextMsg("gauntlet flag = False") : AddInfoTextMsg(#CRLF$)
  AddInfoToLogFile("gauntlet flag = False") : AddInfoToLogFile(#CRLF$)  
EndIf

AddInfoTextMsg("Info...STARTING MATCH of " + Str(TotalMatchGames) + " games...to file " + PGNMatchFile + " TC = " + SF_Time_Per_Move_str + "ms")
AddInfoTextMsg(#CRLF$)
AddInfoToLogFile("...STARTING MATCH of " + Str(TotalMatchGames) + " games...to file " + PGNMatchFile + " TC = " + SF_Time_Per_Move_str + "ms")

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  PrintN(#CRLF$)
  PrintN("*************STARTING MATCH of " + Str(TotalMatchGames *#NumGames) + " games...")
CompilerEndIf

; Match loop

For CurrentGamePair = Open_Index1 To Open_Index2
  
  RoundNumber = Str(CurrentGamePair)
  CurrentOpening = Left(OpeningLines(CurrentGamePair),Open_Ply_Length*5) ; Current PGN string
  
  For PairNo = 1 To #NumGames
    
    For ii = 1 To Engine_Count - 1
      For jj = ii + 1 To Engine_Count
        Engii = ii : Engjj = jj
        ; --- Pairing 1ab: Engine ii (White) vs. Engine jj (Black) --- (AB)
        MatchGameCount = MatchGameCount + 1
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN(#CRLF$)
          PrintN("--- Game " + Str(MatchGameCount) + " / White: " + Engine_Name(ii) + " vs Black: " + Engine_Name(jj) + " / Opening: " + CurrentOpening + " ---")
        CompilerEndIf
        Eng_short1 = ReplaceString(Engine_Name(ii),"Match","") : Eng_short1 = ReplaceString(Eng_short1,"ine","")
        Eng_short2 = ReplaceString(Engine_Name(jj),"Match","") : Eng_short2 = ReplaceString(Eng_short2,"ine","")
        AddInfoTextMsg("Info... Game " + Str(MatchGameCount) + " / W: " + Eng_short1 + " vs B: " + Eng_short2 + " / Open: " + CurrentOpening)
        AddInfoTextMsg(#CRLF$)
        AddInfoToLogFile("... Game " + Str(MatchGameCount) + " / White: " + Engine_Name(ii) + " vs Black: " + Engine_Name(jj) + " / Opening: " + CurrentOpening)
    
        For move_hist_loop = 1 To #max_move_history 
          position_history(move_hist_loop,1) = "" : position_history(move_hist_loop,2) = ""
          Score_History(move_hist_loop,1) = "" : Score_History(move_hist_loop,2) = "" 
          Move_History(move_hist_loop,1) = "" : Move_History(move_hist_loop,2) = "" 
        Next
        GameOne_GameTwo = 1
        SetGadgetText(#GamePlaying_GadgetW, "Current Game #" + Str(MatchGameCount) + " - " + Str(ii) + "w-" + Str(jj) + "b:" + " White: " + Engine_Path(ii))
        SetGadgetText(#GamePlaying_GadgetB, "Current Game #" + Str(MatchGameCount) + " - " + Str(ii) + "w-" + Str(jj) + "b:" + " Black: " + Engine_Path(jj))
        While WindowEvent() : Wend
        
        ; start up the two engines for this match game pair, if necessary (I sometimes leave engines running, probably shouldn't)
        Start_or_Restart_GameMatch_Engines(Engine_Path(ii),Engine_Handle(ii),Engine_Path(jj),Engine_Handle(jj))
        
        MatchGameResult = PlayGame(Engine_Handle(ii), Engine_Name(ii), Engine_Handle(jj), Engine_Name(jj), CurrentOpening)
   
        AddInfoTextMsg("... Game " + Str(MatchGameCount) + " Result: " + MatchGameResult) : AddInfoTextMsg(#CRLF$)
        AddInfoToLogFile("... Game " + Str(MatchGameCount) + " Result: " + MatchGameResult) : AddInfoTextMsg(#CRLF$)
        PrintAsciiBoard(2,FileHandle2)
        Set_MatchGameResult(ii,jj,MatchGameResult)
        Print_Current_Match_Standings2()
    
        ; --- Pairing 1ba: Engine jj (White) vs. Engine ii (Black) --- (BA)
        MatchGameCount = MatchGameCount + 1
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN(#CRLF$)
          PrintN("--- Game " + Str(MatchGameCount) + " / White: " + Engine_Name(jj) + " vs Black: " + Engine_Name(ii) + " / Opening: " + CurrentOpening + " ---")
        CompilerEndIf
        Eng_short1 = ReplaceString(Engine_Name(jj),"Match","") : Eng_short1 = ReplaceString(Eng_short1,"ine","")
        Eng_short2 = ReplaceString(Engine_Name(ii),"Match","") : Eng_short2 = ReplaceString(Eng_short2,"ine","")
        AddInfoTextMsg("Info... Game " + Str(MatchGameCount) + " / W: " + Eng_short1 + " vs B: " + Eng_short2 + " / Open: " + CurrentOpening)
        AddInfoTextMsg(#CRLF$)
        AddInfoToLogFile("... Game " + Str(MatchGameCount) + " / White: " + Engine_Name(jj) + " vs Black: " + Engine_Name(ii) + " / Opening: " + CurrentOpening)
    
        For move_hist_loop = 1 To #max_move_history 
          position_history(move_hist_loop,1) = "" : position_history(move_hist_loop,2) = ""
          Score_History(move_hist_loop,1) = "" : Score_History(move_hist_loop,2) = "" 
          Move_History(move_hist_loop,1) = "" : Move_History(move_hist_loop,2) = ""
        Next
        GameOne_GameTwo = 2
        SetGadgetText(#GamePlaying_GadgetW, "Current Game #" + Str(MatchGameCount) + " - " + Str(jj) + "w-" + Str(ii) + "b:" + " White: " + Engine_Path(jj))
        SetGadgetText(#GamePlaying_GadgetB, "Current Game #" + Str(MatchGameCount) + " - " + Str(jj) + "w-" + Str(ii) + "b:" + " Black: " + Engine_Path(ii))
        While WindowEvent() : Wend
        
        Start_or_Restart_GameMatch_Engines(Engine_Path(jj),Engine_Handle(jj),Engine_Path(ii),Engine_Handle(ii))
        
        MatchGameResult = PlayGame(Engine_Handle(jj), Engine_Name(jj), Engine_Handle(ii), Engine_Name(ii), CurrentOpening)
        AddInfoTextMsg("... Game " + Str(MatchGameCount) + " Result: " + MatchGameResult) : AddInfoTextMsg(#CRLF$)
        AddInfoToLogFile("... Game " + Str(MatchGameCount) + " Result: " + MatchGameResult) : AddInfoTextMsg(#CRLF$)
        PrintAsciiBoard(2,FileHandle2)
        Set_MatchGameResult(jj,ii,MatchGameResult)
        Print_Current_Match_Standings2()
        
        StopEngine(Engine_Handle(jj), Engine_Name(jj)) : Engine_Handle(jj) = 0
        StopEngine(Engine_Handle(ii), Engine_Name(ii)) : Engine_Handle(ii) = 0
      Next ; jj
      If gauntlet_flag = #True
        Break  
      EndIf
    Next   ; ii
    
    SetGadgetText(#GamePlaying_GadgetW, "Current game: ")
    SetGadgetText(#GamePlaying_GadgetB, "Current game: ")
    While WindowEvent() : Wend
  Next
  
  Print_Current_Match_Standings()
  Log_Current_Match_Standings()
Next


; Output Final Score
CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  Print_Current_Match_Standings()
CompilerEndIf

FileHandle1 = OpenFile(#PB_Any, PGNMatchFile, #PB_File_Append)
If FileHandle1
  WriteString(FileHandle1,"==================================================")
  WriteStringN(FileHandle1,"--- Match Finished ---==================================================")
  WriteStringN(FileHandle1,"Total Games Played: " + Str(MatchGameCount))
  
  ; WriteStringN(FileHandle1,"Engine A (" + Engine_Name(1) + ") Final Score:")
  ; WriteStringN(FileHandle1,"  Wins: " + Str(Engine_ScoreWin(1)) + " | Draws: " + Str(Engine_ScoreDraw(1)) + " | Losses: " + Str(Engine_ScoreLoss(1)) + " | Disconnects: " + Str(Engine_ScoreDisconnect(1)))
  For zz = 1 To Engine_Count
    WriteStringN(FileHandle1,"Engine " + Chr(64+zz) + " (" + Engine_Name(zz) + ") Final Score:")
    WriteStringN(FileHandle1,"  Wins: " + Str(Engine_ScoreWin(zz)) + " | Draws: " + Str(Engine_ScoreDraw(zz)) + " | Losses: " + Str(Engine_ScoreLoss(zz)) + " | Disconnects: " + Str(Engine_ScoreDisconnect(zz)))
  Next
  WriteStringN(FileHandle1, #CRLF$)
  CloseFile(FileHandle1)
EndIf

AddInfoTextMsg("--- MATCH FINISHED ---")
Print_Current_Match_Standings()
Log_Current_Match_Standings()
SetGadgetState(#InfoMatch_Field,CountGadgetItems(#InfoMatch_Field)-1)
While WindowEvent() : Wend
MessageRequester("Match Complete", "The chess engine match has finished. Results are in the PGN file: " + PGNMatchFile + ", and the match LOG file: " + EngineMatchLogFile)

  Repeat
    Select WaitWindowEvent()
      Case #PB_Event_Gadget
        Select EventType()
          Case #PB_EventType_LeftClick
            Select EventGadget()
              Case #Btn_CloseMatch
                FreeGadget(#Btn_CloseMatch)
                CloseWindow(#engmatchwin)
            EndSelect
        EndSelect
    EndSelect
  Until IsWindow(#engmatchwin) = 0
  
  DisplayGames()
  
EndProcedure


Procedure Print_Current_Match_Standings()
  
  Protected zz.i
  
  AddInfoTextMsg(#CRLF$)
  AddInfoTextMsg("=========================================================================================================")
  For zz = 1 To Engine_Count
    AddInfoTextMsg("Info - MatchEngine" + Chr(64+zz) + " = " + Engine_Path(zz))
  Next
  AddInfoTextMsg(#CRLF$)
  
  AddInfoTextMsg("_____________________ Current/Final Match Standings _____________________" + "Games Played: " + Str(MatchGameCount))
  ;AddInfoTextMsg("----------------------------------------------------------------")
  For zz = 1 To Engine_Count
    AddInfoTextMsg("Engine " + Chr(64+zz) + " (" + Engine_Name(zz) + ")")
    AddInfoTextMsg("Score:  Wins: " + Str(Engine_ScoreWin(zz)) + " | Draws: " + Str(Engine_ScoreDraw(zz)) + " | Losses: " + Str(Engine_ScoreLoss(zz)) + " | Disconnects: " + Str(Engine_ScoreDisconnect(zz)))
  Next
  ;AddInfoTextMsg("=========================================================================================================")
  AddInfoTextMsg(#CRLF$)
  
EndProcedure


Procedure Print_Current_Match_Standings2()
  
  Protected zz.i, drawsf.f, winsf.f, Engine_Index.i
  
  AddToResultsGadget(#CRLF$)
  ;AddToResultsGadget("=========================================================================================================")
  ;For zz = 1 To Engine_Count
   ; AddToResultsGadget("MatchEngine" + Chr(64+zz) + " = " + Engine_Path(zz))
  ;Next
  ;AddToResultsGadget(#CRLF$)
  
  ;AddToResultsGadget("_____________________ Current/Final Match Standings _____________________" + "Games Played: " + Str(MatchGameCount))
  BubbleSortEnginePointsDescending()
  
  For zz = 1 To Engine_Count
    Engine_Index = Engine_SortList(zz)
    ;AddToResultsGadget(Engine_Name(Engine_Index) + " [" + Engine_Path(Engine_Index) + "]")
    AddToResultsGadget("Eng"+ Chr(64+Engine_Index) + " ["+ Engine_Path(Engine_Index) + "]" + Chr(10) + Str(Engine_ScoreWin(Engine_Index)) + Chr(10) + Str(Engine_ScoreDraw(Engine_Index)) + Chr(10) + Str(Engine_ScoreLoss(Engine_Index)) + Chr(10) + Str(Engine_ScoreDisconnect(Engine_Index)) + Chr(10) + StrD(Engine_ScorePoints(Engine_Index)))
  Next zz
  
  ;For zz = 1 To Engine_Count
  ;  drawsf = Engine_ScoreDraw(zz)
  ;  winsf = Engine_ScoreWin(zz)
  ;  AddToResultsGadget("Engine " + Chr(64+zz) + " (" + Engine_Path(zz) + ")")
  ;  AddToResultsGadget("Current/Final Score:  Wins: " + Str(Engine_ScoreWin(zz)) + " | Draws: " + Str(Engine_ScoreDraw(zz)) + " | Losses: " + Str(Engine_ScoreLoss(zz)) + " | Disconnects: " + Str(Engine_ScoreDisconnect(zz)) + " | Points: " + StrD(winsf+drawsf/2.0))
  ;Next zz
  ;AddToResultsGadget("=========================================================================================================")
  AddToResultsGadget(#CRLF$)
  
EndProcedure


Procedure Log_Current_Match_Standings()
  
  Protected zz.i, drawsf.f, winsf.f, Engine_Index.i
  
  AddInfoToLogFile(#CRLF$)
  AddInfoToLogFile("=========================================================================================================")
  For zz = 1 To Engine_Count
    AddInfoToLogFile("MatchEngine" + Chr(64+zz) + " = " + Engine_Path(zz))
  Next
  AddInfoToLogFile(#CRLF$)
  BubbleSortEnginePointsDescending()
  
  AddInfoToLogFile(#CRLF$ + "This EngineMatch logfile = " + EngineMatchLogFile + #CRLF$)
  AddInfoToLogFile("_____________________________ Current/Final Match Standings _____________________________" + "Games Played: " + Str(MatchGameCount))
  ;AddInfoToLogFile("_______________________________________________________________")
  AddInfoToLogFile(#CRLF$)
  
  For zz = 1 To Engine_Count
    Engine_Index = Engine_SortList(zz)
    ;drawsf = Engine_ScoreDraw(zz)
    ;winsf = Engine_ScoreWin(zz)
    AddInfoToLogFile(Engine_Name(Engine_Index) + " [" + Engine_Path(Engine_Index) + "]")
    AddInfoToLogFile("Current/Final Score:  Wins: " + Str(Engine_ScoreWin(Engine_Index)) + " | Draws: " + Str(Engine_ScoreDraw(Engine_Index)) + " | Losses: " + Str(Engine_ScoreLoss(Engine_Index)) + " | Disconnects: " + Str(Engine_ScoreDisconnect(Engine_Index)) + " | Points: " + StrD(Engine_ScorePoints(Engine_Index)))
  Next
  
  AddInfoToLogFile("=========================================================================================================")
  AddInfoToLogFile(#CRLF$)
  
EndProcedure


Procedure.s ReadUCIResponse_EngineMatch(Engine_HandleX.i, timeout_ms = 300)
  Protected Filtered_output.s, ii.i
  output = ""
  Protected startTime = ElapsedMilliseconds()
  
  Delay(timeout_ms/2) ; Give Stockfish a little time to respond more fully
  While AvailableProgramOutput(Engine_HandleX)
    output = output + ReadProgramString(Engine_HandleX) + #CRLF$
    ;output = ReadProgramString(ProgramID)
  Wend
  ;Delay(timeout_ms/2)
  
  Filtered_output = ReplaceString(output,Space(1),"")
  Filtered_output = ReplaceString(Filtered_output,#LF$,"")
  
  If filtered_output <> ""
    For ii = 1 To Engine_Count
      If Engine_HandleX = Engine_Handle(ii)
        PrintN("Engine" + Chr(64+ii) + "_Output = " + output)
        AddInfoToLogFile("Engine" + Chr(64+ii) + "_Output = " + output)
        Break
      EndIf
    Next
  EndIf
  
  ProcedureReturn output
EndProcedure


Procedure SendUCICommandMatch(ProgramID, command.s)
  
  Protected ii.i, NewProgramID.i
  
  If IsProgram(ProgramID) And ProgramRunning(ProgramID)
    WriteProgramStringN(ProgramID, command)
    Debug ">> UCI Sent: " + command
  Else                   ; some error handling for engines that dropout ot quit
    For ii = 1 To Engine_Count
      If Engine_Handle(ii) = ProgramID          ; finding the engine that croaked
        Eng_Index = ii
        Engine_Path_Generic = Engine_Path(Eng_Index)
        PrintN("SendUCIComMatch: Engine croaked, Engine Path = " + Engine_Path(Eng_Index))
        ;Break
      EndIf
    Next
    CreateThread(@StartEngine_Thread(),1)
    PrintN("SendUCIComMatch: Engine restarted. Engine Path = " + Engine_Path(Eng_Index))
    Delay(400)
    NewProgramID = Engine_Handle(Eng_Index)
    WriteProgramStringN(NewProgramID, command)
    Debug ">> UCI Sent NewProgramID: " + command    
  EndIf
  
EndProcedure



Procedure WaitForUCIResponseMatch(ProgramID, expectedResponse.s, timeout_ms = 3000)
  Protected startTime = ElapsedMilliseconds(), response$, ii.i
  
  While ElapsedMilliseconds() - startTime < timeout_ms
    For ii = 1 To Engine_Count
      If ProgramID = Engine_Handle(ii)
        ReadUCIResponse_EngineMatch(Engine_Handle(ii),300)
        Break
      EndIf
    Next
    
    ;Select ProgramID
    ;  Case Engine_Handle(1)
    ;    ReadUCIResponse_EngineMatch(Engine_Handle(1),300)
    ;  Case Engine_Handle(2)
    ;    ReadUCIResponse_EngineMatch(Engine_Handle(2),300)
    ; ...
    ;EndSelect
    
    response$ = output
    If FindString(response$, expectedResponse, 1)
      ProcedureReturn #True
    EndIf
    Delay(10)
  Wend
  ProcedureReturn #False
EndProcedure



Procedure Set_MatchGameResult(WhitePlayer1.i,BlackPlayer2.i,MatchGameResult.s)
  
  Protected wins_f.f, draws_f.f
  
  Select MatchGameResult
    Case "1-0"
      Engine_ScoreWin(WhitePlayer1) = Engine_ScoreWin(WhitePlayer1) + 1
      Engine_ScorePoints(WhitePlayer1) = Engine_ScorePoints(WhitePlayer1) + 1
      Engine_ScoreLoss(BlackPlayer2) = Engine_ScoreLoss(BlackPlayer2) + 1
      If Disconnect_Flag(2) = #True
        Engine_ScoreDisconnect(BlackPlayer2) = Engine_ScoreDisconnect(BlackPlayer2) + 1
      EndIf
    Case "0-1"
      Engine_ScoreWin(BlackPlayer2) = Engine_ScoreWin(BlackPlayer2) + 1
      Engine_ScorePoints(BlackPlayer2) = Engine_ScorePoints(BlackPlayer2) + 1
      Engine_ScoreLoss(WhitePlayer1) = Engine_ScoreLoss(WhitePlayer1) + 1
      If Disconnect_Flag(1) = #True
        Engine_ScoreDisconnect(WhitePlayer1) = Engine_ScoreDisconnect(WhitePlayer1) + 1
      EndIf
    Case "1/2-1/2"
      Engine_ScoreDraw(WhitePlayer1) = Engine_ScoreDraw(WhitePlayer1) + 1
      Engine_ScorePoints(WhitePlayer1) = Engine_ScorePoints(WhitePlayer1) + 0.5
      Engine_ScoreDraw(BlackPlayer2) = Engine_ScoreDraw(BlackPlayer2) + 1
      Engine_ScorePoints(BlackPlayer2) = Engine_ScorePoints(BlackPlayer2) + 0.5
    Default
      Engine_ScoreDraw(WhitePlayer1) = Engine_ScoreDraw(WhitePlayer1) + 1
      Engine_ScoreDraw(BlackPlayer2) = Engine_ScoreDraw(BlackPlayer2) + 1
      Engine_ScorePoints(WhitePlayer1) = Engine_ScorePoints(WhitePlayer1) + 0.5
      Engine_ScorePoints(BlackPlayer2) = Engine_ScorePoints(BlackPlayer2) + 0.5
  EndSelect

EndProcedure


Procedure Set_CurrentPlayingGameInfo(p1ayerone.i, playertwo.i)
  
  ;Protected playerone.i
  ;Protected playertwo.i
  
  SetGadgetText(#GamePlaying_GadgetW, "Current game: White:" + Engine_Path(playerone))
  SetGadgetText(#GamePlaying_GadgetB, "Current game: Black:" + Engine_Path(playertwo))
  While WindowEvent() : Wend
  
EndProcedure

; ==============================================================================
; UCI Communication and Process Management
; ==============================================================================

Procedure StartEngine_Thread(*Value)
  ; Initializes a single engine process.
  
  Protected ii.i
  
  If FileSize(Engine_Path_Generic) > 0
    For ii = 1 To Engine_Count
      If Trim(Engine_Path(ii),Space(1)) = Trim(Engine_Path_Generic,Space(1))
        Eng_Index = ii
        ;PrintN("StartEngThread: Engine Path = " + Engine_Path(Eng_Index))
        Break
      EndIf
    Next
      
    Engine_Handle(Eng_Index) = RunProgram(Engine_Path(Eng_Index), "", "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Write)
    PrintN("...trying to start..." + Str(Engine_Handle(Eng_Index)) + Space(2) + Engine_Name(Eng_Index))
    If Engine_Handle(Eng_Index)
      SendUCICommandMatch(Engine_Handle(Eng_Index), "uci")
      Delay(20)
      ReadUCIResponse_EngineMatch(Engine_Handle(Eng_Index), 1000)
      uci_info = output
      PrintN("<< UCI Received:\n" + uci_info)
      If FindString(uci_info, "uciok", 1)
        PrintN("Engine UCI handshake successful.")
      Else
        PrintN("Error: Engine UCI handshake failed.")
      EndIf
      SendUCICommandMatch(Engine_Handle(Eng_Index), "isready")
      Delay(20)
      ReadUCIResponse_EngineMatch(Engine_Handle(Eng_Index), 1000)
      uci_info = output
      PrintN("<< UCI Received:\n" + uci_info)
      If FindString(uci_info, "readyok", 1)
        PrintN(Engine_Name(Eng_Index) + " UCI handshake successful.")
      Else
        PrintN(Engine_Name(Eng_Index) + " - Error: UCI handshake failed.")
      EndIf
      SendUCICommandMatch(Engine_Handle(Eng_Index), "ucinewgame")
      PrintN(Engine_Name(Eng_Index) + " started successfully at starting position.")
    Else
      MessageRequester("Error", "Could not start engine: " + Engine_Name(Eng_Index) + ". Check the path and permissions.")
      ProcedureReturn 0
    EndIf
  Else
    MessageRequester("Error", "Engine file not found: " + Engine_Path_Generic)
    ProcedureReturn 0
  EndIf
  
EndProcedure


Procedure Start_or_Restart_GameMatch_Engines(Engine1_Path.s,Engine1_Handle.i,Engine2_Path.s,Engine2_Handle.i)
  
  
      If Engine1_Path <> "" And Engine1_Handle <= 0
          AddInfoTextMsg("Info...starting or restarting " + Engine1_Path + "...")
          AddInfoToLogFile("...starting or restarting " + Engine1_Path + "...")
          Engine_Path_Generic = Engine1_Path
          CreateThread(@StartEngine_Thread(),1)
          Delay(350)
        EndIf
        If Engine2_Path <> "" And Engine2_Handle <= 0
          AddInfoTextMsg("Info...starting or restarting " + Engine2_Path + "...")
          AddInfoToLogFile("...starting or restarting " + Engine2_Path + "...")
          Engine_Path_Generic = Engine2_Path
          CreateThread(@StartEngine_Thread(),1)
          Delay(350)
        EndIf
  
EndProcedure



Procedure StopEngine(EngineHandle.i, EngineName.s)
  ; Shuts down a single engine process.
  If ProgramRunning(EngineHandle)
    ; Send quit command and then forcibly close the process
    ;SendUCICommandMatch(EngineHandle, "quit")
    ;Delay(20)
    KillProgram(EngineHandle)
    CloseProgram(EngineHandle)
    Delay(20)
  EndIf
EndProcedure


Procedure GetBestMoveUCIPVMatch(ProgramID, PositionCommand.s, searchTime_ms)
  Protected pv1a.w, pv1b.w, pv2a.w, pv2b.w, response2.s, pva.i, sp1.i, sp2.i
  Protected cpscore_normal_pos.i, cpscore_mate_pos.i, wdl_pos.i, ii.i

  SendUCICommandMatch(ProgramID, PositionCommand)
  SendUCICommandMatch(ProgramID, "go movetime " + Str(searchTime_ms))
  
  Protected startTime = ElapsedMilliseconds(), response.s, pos, endPos, pv, cpscore, nodes
  bestmove = ""
  output = ""
  While ElapsedMilliseconds() - startTime < searchTime_ms + 100 ; Add extra time for the response
    
    For ii = 1 To Engine_Count
      If ProgramID = Engine_Handle(ii)
        ReadUCIResponse_EngineMatch(Engine_Handle(ii),100)
        Break
      EndIf
    Next
      
    response2 = output
    ;PrintN("SF analy = " + response2)

    pva = FindString(response2, "multipv 1", 1)
    ;pvb = FindString(response2, "pv ", pva+9) ; skip over multipv string

    pos = FindString(response2, "bestmove", 1)
    
    cpscore_normal_pos = 0
    cpscore_mate_pos = 0
    cpscore_normal_pos = FindString(response2, "score cp", 1)
    cpscore_mate_pos = FindString(response2, "score mate", 1)   ; allow score string to show mate scores
    
    nodes = FindString(response2, "nodes", 1)
    
    If cpscore_normal_pos > 0
      sp1 = FindString(response2,Space(1),cpscore_normal_pos+8)
      sp2 = FindString(response2,Space(1),sp1+1)
      cpscore_str(1) = Trim(Mid(response2, sp1+1, sp2-sp1-1), Space(1))
    ; wdl_pos = FindString(cpscore_str(1),"wdl")
    ; If wdl_pos > 0                                                   ; grungy patch for some engines with extra info
    ;   cpscore_str(1) = Left(cpscore_str(1),wdl_pos-2)
    ; EndIf
      
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN("")
        PrintN("...GameNumber = " + Str(MatchGameCount) + "  Movenumber = " + Str(MoveNumber) +  "  score(1) = " + cpscore_str(1))
        PrintN("")
      CompilerEndIf
      AddInfoToLogFile("...GameNumber = " + Str(MatchGameCount) + "  Movenumber = " + Str(MoveNumber) +  "  score(1) = " + cpscore_str(1))
    EndIf
    
    
    If cpscore_mate_pos > 0
      cpscore_str(1) = "mate " + Trim(Mid(response2, cpscore_mate_pos+11, nodes-cpscore_mate_pos-11), Space(1))
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
        PrintN("")
        PrintN("score(" + Str(1) + ") = " + cpscore_str(1))
        PrintN("")
      CompilerEndIf
      AddInfoToLogFile("score(" + Str(1) + ") = " + cpscore_str(1))
    EndIf

    If pos
      ; Find the start of the bestmove value (after "bestmove ")
      pos = pos + Len("bestmove ")
      ; Find the end of the bestmove value (usually the next space or end of line)
      endPos = FindString(response2, " ", pos)
      If endPos
        bestmove = Mid(response2, pos, endPos - pos)
      Else
        bestmove = Mid(response2, pos) ; Bestmove is the last word on the line
      EndIf
      XTrim(bestmove)
    EndIf
    Delay(10)
  Wend
  ;ProcedureReturn "" ; Return empty string if best move not found within timeout
EndProcedure



Procedure LoadOpeningLines()
  ; Hardcoded UCI move lines for now for simplicity
  Protected i.i
  
  Restore Opening_Lines
  
  For i = 1 To #OpeningLines_default
    Read.s OpeningLines(i)
  Next
  
EndProcedure





Procedure AAA_Dummy_PlaceHolder_EndMatchCode()
  
  
EndProcedure

; ********** end of matchmanager code



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
  ; 10. ECO - text data
  ; 11. ucimoves - text data


  query.s =  "CREATE TABLE IF NOT EXISTS pgngames (gameid INTEGER PRIMARY KEY, event TEXT, gamedate TEXT, player1 TEXT, ELO1 TEXT, player2 TEXT, ELO2 TEXT, startingFEN TEXT, gameresult TEXT, ECO TXT, ucimoves TEXT)"
 
  
  ; update the database with the prepared query

  If DatabaseUpdate(#sqlite, query.s)
    
    Debug "database table created successfully."
    
  Else
    
    Debug "error creating database table! " + DatabaseError()
    
  EndIf
  
  ;query.s = "INSERT INTO pgngames (event, gamedate, player1, elo1, player2, elo2, startingFEN, gameresult, ECO, ucimoves) " + "VALUES ('kptourney1', '20250331', 'Chess, Kenp', '2000', 'Fischer, Bobby', '2800', '', '1/2-1/2','A00','e2-e4 e7-e5 g1-f3 b8-c6 f1-c4 g8-f6')"
  
  ; FYI Retrieval 1

  ; retrieve ALL (*) data and records from the pgngames table
  ;query.s = "SELECT * FROM pgngames"
  
  ; GAME insertion with binding

  UCI_Gamescore = ""
  For i = 1 To TotalHalfMoves : UCI_Gamescore = UCI_Gamescore + GameScore_UCI_HalfMoves(i) + Space(1) : Next

  PrintN("UCI_Gamescore = " + UCI_Gamescore)
   
  query.s = "INSERT INTO pgngames (event, gamedate, player1, elo1, player2, elo2, startingFEN, gameresult, ECO, ucimoves) " + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"   ; binding order = 0, 1, 2, 3, 4, 5, 6
  
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
  
  ; column 8 = ECO (text)
  SetDatabaseString(#sqlite,8, ECO_Game_Codes(GameIndex+1))
  
  ; column 9 = ucimoves (text)
  SetDatabaseString(#sqlite, 9, UCI_Gamescore)
  
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

    query.s =  "CREATE TABLE IF NOT EXISTS pgngames (gameid INTEGER PRIMARY KEY, event TEXT, gamedate TEXT, player1 TEXT, ELO1 TEXT, player2 TEXT, ELO2 TEXT, startingFEN TEXT, gameresult TEXT, ECO TEXT, ucimoves TEXT)"
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
      Gamescore = gamescore_result
      ; single game insertion with binding
      UCI_Gamescore = ""
      For j = 1 To TotalHalfMoves : UCI_Gamescore = UCI_Gamescore + GameScore_UCI_HalfMoves(j) + Space(1) : Next

      PrintN("UCI_Gamescore = " + UCI_Gamescore)
      query.s = "INSERT INTO pgngames (event, gamedate, player1, elo1, player2, elo2, startingFEN, gameresult, ECO, ucimoves) " + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"   ; binding order = 0, 1, 2, 3, 4, 5, 6
    
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
      
      ; column 8
      SetDatabaseString(#sqlite, 8, ECO_Game_Codes(i))
      
      
      ; column 9 = ucimoves (text)
      SetDatabaseString(#sqlite, 9, UCI_Gamescore)
  
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
  ;PieceImages(6) = LoadImage(6, Images_Path + "bp.png")
  ;PieceImages(7) = LoadImage(7, Images_Path + "wr.png")
  ;            ...
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
  
  If IsGadget(#CanvasGadgetChessBoard) = 0
    If SquareSize = 60
      CanvasGadget(#CanvasGadgetChessBoard, #Canvas_GadgetX, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#canvas_gadgetY), #cg_width, #cg_height, #PB_Canvas_Keyboard)  
    Else
      CanvasGadget(#CanvasGadgetChessBoard, #Canvas_GadgetX, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#canvas_gadgetY), #cg_width-50, #cg_height-100, #PB_Canvas_Keyboard)
    EndIf
  EndIf
  
  StartDrawing(CanvasOutput(#CanvasGadgetChessBoard))        ; see the DisplayGames routine just after the other gadgets are created
  
; Draw chessboard
For row = 1 To 8
  For col = 1 To 8
    If (row + col) % 2 = 0
      Box(col * SquareSize, row * SquareSize -5, SquareSize, SquareSize, WhiteColor)
    Else
      Box(col * SquareSize, row * SquareSize -5, SquareSize, SquareSize, BlackColor)
    EndIf
  Next
Next

; Draw pieces (new)
For row = 20 To 90 Step 10
  For col = 1 To 8
    If MbxBrd(row+col) <> _emptysq
      DrawAlphaImage(ImageID(MbxBrd(row+col)), col * SquareSize, (row/10-1) * SquareSize -5)
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


Procedure Calculate_White_Black_Material()
  
  Protected i.i, White.b = 1, Black.b = 2
  
  Number_Of_Minor_Pieces(White) = 0 : Number_Of_Minor_Pieces(Black) = 0
  Number_Of_Bishops(White) = 0 : Number_Of_Bishops(Black) = 0
  Number_Of_Knights(White) = 0 : Number_Of_Knights(Black) = 0
  Number_Of_Rooks(White) = 0 : Number_Of_Rooks(Black) = 0
  Number_Of_Pawns(White) = 0 : Number_Of_Pawns(Black) = 0
  Number_Of_Major_Pieces_Or_Pawns(White) = 0 : Number_Of_Major_Pieces_Or_Pawns(Black) = 0
  Total_Material(White) = 0 : Total_Material(Black) = 0
  matchgame_insufficient_mating_material_flag = #False
  
  For i = 1 To 119
    If MbxBrd(i) <> #OffTheBoard And MbxBrd(i) <> _emptysq
      Select MbxBrd(i)
        Case Wrook
          Number_Of_Major_Pieces_Or_Pawns(White) = Number_Of_Major_Pieces_Or_Pawns(White) + 1
          Number_Of_Rooks(White) = Number_Of_Rooks(White) + 1
          Total_Material(White) = Total_Material(White) + Material_Eval(Wrook)
        Case Wpawn
          Number_Of_Major_Pieces_Or_Pawns(White) = Number_Of_Major_Pieces_Or_Pawns(White) + 1
          Number_Of_Pawns(White) = Number_Of_Pawns(White) + 1
          Total_Material(White) = Total_Material(White) + Material_Eval(Wpawn)
        Case Wqueen
          Number_Of_Major_Pieces_Or_Pawns(White) = Number_Of_Major_Pieces_Or_Pawns(White) + 1
          Total_Material(White) = Total_Material(White) + Material_Eval(Wqueen)
        Case Wbishop
          Number_Of_Minor_Pieces(White) = Number_Of_Minor_Pieces(White) + 1
          Number_Of_Bishops(White) = Number_Of_Bishops(White) + 1
          Total_Material(White) = Total_Material(White) + Material_Eval(Wbishop)
        Case Wknight
          Number_Of_Minor_Pieces(White) = Number_Of_Minor_Pieces(White) + 1
          Number_Of_Knights(White) = Number_Of_Knights(White) + 1
          Total_Material(White) = Total_Material(White) + Material_Eval(Wknight)
        Case Brook
          Number_Of_Major_Pieces_Or_Pawns(Black) = Number_Of_Major_Pieces_Or_Pawns(Black) + 1
          Number_Of_Rooks(Black) = Number_Of_Rooks(Black) + 1
          Total_Material(Black) = Total_Material(Black) + Material_Eval(Brook)
        Case Bpawn
          Number_Of_Major_Pieces_Or_Pawns(Black) = Number_Of_Major_Pieces_Or_Pawns(Black) + 1
          Number_Of_Pawns(Black) = Number_Of_Pawns(Black) + 1
          Total_Material(Black) = Total_Material(Black) + Material_Eval(Bpawn)
        Case Bqueen
          Number_Of_Major_Pieces_Or_Pawns(Black) = Number_Of_Major_Pieces_Or_Pawns(Black) + 1
          Total_Material(Black) = Total_Material(Black) + Material_Eval(Bqueen)
        Case Bbishop
          Number_Of_Minor_Pieces(Black) = Number_Of_Minor_Pieces(Black) + 1
          Number_Of_Bishops(Black) = Number_Of_Bishops(Black) + 1
          Total_Material(Black) = Total_Material(Black) + Material_Eval(Bbishop)
        Case Bknight
          Number_Of_Minor_Pieces(Black) = Number_Of_Minor_Pieces(Black) + 1
          Number_Of_Knights(Black) = Number_Of_Knights(Black) + 1
          Total_Material(Black) = Total_Material(Black) + Material_Eval(Bknight)
        Case Wking, Bking
          ; we just ignore the kings because they are always on the board (never captured, infinite value!)
      EndSelect
    EndIf
  Next
  
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


Procedure DeepCleanPGNs()
  
  Protected i.i
  
  MessageRequester("CleanPGN Info button","This Btn assists in deep cleaning of all PGN gamescores (NOT required, but for human readability when horizontally scrolling the PGNs movelists). It can take awhile on large files!")
  ClearGadgetItems(#Players_ListIcon_Gadget)
  For i = 1 To GameCount-1
    SetupGameLinkForSearchSort(i)
    FilePGNs(i) = ParseAndCleanPGN(FilePGNs(i))
    RemovePGNCommentsAndVariations2(FilePGNs(i))
    FilePGNs(i) = gamescore_result
    FEN_display_str_Set(i)
    AddGadgetItem(#Players_ListIcon_Gadget, -1, GameLink + Chr(10) + Trim(Left(WhitePlayers(i), G1_pos-1), " ") + " [" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + " [" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i) + Chr(10) + ECO_Game_Codes(i) + Chr(10) + FEN_display_str + Chr(10) + Left(FilePGNs(i),#pgnwidth))
    If i % 250 = 0
      SetGadgetText(#Info_Field, "...working...DEEPLY cleaning GAME = #" + Str(i))
      While WindowEvent() : Wend
    EndIf
  Next
  SetGadgetText(#Info_Field, "All games now cleaned...Select a game above left...")
  While WindowEvent() : Wend
  
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
  DrawVectorText("[ECO " + #DQUOTE$ + ECO_Game_Codes(k) + #DQUOTE$ + "]")
  
  MovePathCursor(PDFSquareSize*8 + #doc_offset*2, #demo_y_offset + PDFSquareSize*5.2)
  DrawVectorText("[Result " + #DQUOTE$ + Each_Game_Result(k) + #DQUOTE$ + "]")
  
  MovePathCursor(PDFSquareSize*8 + #doc_offset*2, #demo_y_offset + PDFSquareSize*6)
  

  DrawVectorParagraph(MoveString, 300, 600)
  
  ;MovePathCursor(#doc_offset*3, #demo_y_offset + PDFSquareSize*9)
  ;DrawVectorText(sample_move)
  
  
  
EndProcedure


Procedure DrawVectorTextDemoDataToImage(k.i)
  
  ; This procedure exists because DrawVectorText doesn't work with PDF under Windows, (works fine under macos)! It therefore draws GAME INFO for the game
  ; PDF onto a temporary image, and then that image is written to the PDF file in the main ExportGameToPDF procedure.
  
  Protected sample_gamescore_moves.s
  Protected PDFSquareSize.i = 24
  Protected sample_move.s = "46. b4 gxh4"
  Protected pvstring_sample.s = "pv = g3h4 b1g6 e3g2 g6f7 g2f4 d6c6 f4d3 f7e6 f2g3 c6d6 d3f4 e6f7 g3h2 d6c7 f4d3 f7e6 h2g2 c7c6   eval = 137"
  
  #ImageWidth = 400
  #ImageHeight = 800
  
UsePNGImageDecoder()
UsePNGImageEncoder()

; Create a new image in memory
If CreateImage(#ImageID_DemoBkgnd, #ImageWidth, #ImageHeight,32,#White)

  ; Start vector drawing on the image
  If StartVectorDrawing(ImageVectorOutput(#ImageID_DemoBkgnd))

    ; Load a TrueType font (vector fonts only)
    LoadFont(0, "Helvetica", 12)
    VectorFont(FontID(0)) ; Set the font for vector drawing, with size in points

    ; Set the text color
    VectorSourceColor(RGBA(0, 0, 0, 255)) ;  black color
    
    MovePathCursor(#doc_offset, #demo_y_offset + PDFSquareSize)
    DrawVectorText("[Site " + #DQUOTE$ + EventSites(k) + #DQUOTE$ + "]")
  
    MovePathCursor(#doc_offset, #demo_y_offset + PDFSquareSize*1.6)
    DrawVectorText("[Date " + #DQUOTE$ + GameDates(k) + #DQUOTE$ + "]")
  
    MovePathCursor(#doc_offset, #demo_y_offset + PDFSquareSize*2.2)
    DrawVectorText("[White " + #DQUOTE$ + Trim(WhitePlayers(k),Space(1))  + #DQUOTE$ + "]")
  
    MovePathCursor(#doc_offset, #demo_y_offset + PDFSquareSize*2.8)
    DrawVectorText("[WhiteElo " + #DQUOTE$ + WhiteElos(k) + #DQUOTE$ + "]")
  
    MovePathCursor(#doc_offset, #demo_y_offset + PDFSquareSize*3.4)
    DrawVectorText("[Black " + #DQUOTE$ + Trim(BlackPlayers(k),Space(1)) + #DQUOTE$ + "]")
  
    MovePathCursor(#doc_offset, #demo_y_offset + PDFSquareSize*4)
    DrawVectorText("[BlackElo " + #DQUOTE$ + BlackElos(k) + #DQUOTE$ + "]")
    
    MovePathCursor(#doc_offset, #demo_y_offset + PDFSquareSize*4.6)
    DrawVectorText("[ECO " + #DQUOTE$ + ECO_Game_Codes(k) + #DQUOTE$ + "]")
  
    MovePathCursor(#doc_offset, #demo_y_offset + PDFSquareSize*5.2)
    DrawVectorText("[Result " + #DQUOTE$ + Each_Game_Result(k) + #DQUOTE$ + "]")
  
    MovePathCursor(#doc_offset, #demo_y_offset + PDFSquareSize*6.6)
  
    DrawVectorParagraph(MoveString, 350, 700)
    
    ; End the vector drawing block
    StopVectorDrawing()

    ; Save the image to a file
    ;If SaveImage(#ImageID_DemoBkgnd, "/users/kenpresley/desktop/VectorText.png", #PB_ImagePlugin_PNG)
      ;MessageRequester("Success", "Image 'VectorText.png' created successfully!")
    ;Else
      ;MessageRequester("Error", "Could not save image.")
    ;EndIf

  Else
    MessageRequester("Error", "Could not start vector drawing on the image.")
  EndIf

Else
  MessageRequester("Error", "Could not create image.")
EndIf
  

  
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

   If HalfMoveCount % 2 > 0                            ; a bit confusing, odd halfmove number but FEN reflects who is NEXT to move, so Black
    FENpositionstr = FENpositionstr + " b "
  Else
    FENpositionstr = FENpositionstr + " w "            ; a bit confusing, even halfmove number but FEN reflects who is NEXT to move, so White
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



Procedure Convert_UCI_Notation(Passed_UCI_Str.s)
  
  ; This procedure takes a UCI notation halfmove (such as e2-e4 or g1-f3) and simply converts the departure and arrival alebraic squares
  ; to their corresponding mailbox square numbers (i.e. 21 to 98) for updating the chessboard state. Of course it does have to handle 
  ; special moves like castling and pawn promotion.
  
  ; This procedure calls: ConstructFENfromPosition()
  
  Protected fromsq.i, tosq.i, movingPiece.b
  Protected promopiece.s
  
  capture_flag = #False
  If Passed_UCI_Str = ""
    UCI_move_str = Trim(GameScore_UCI_HalfMoves(HalfMoveCount),Space(1))
  Else
    UCI_move_str = Passed_UCI_Str
  EndIf


  Select UCI_move_str

    Case Win1, Lose1, Draw1, Trim(Other1, Space(1)), "mate"
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
      If fromsq <> 0 And tosq <> 0
        If MbxBrd(tosq) = _emptysq
          Capture_Flag_Array(HalfMoveCount) = #False
        Else
          Capture_Flag_Array(HalfMoveCount) = #True
        EndIf
      EndIf

      If fromsq = 0 Or tosq = 0
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN(" CnvUCINotation proc ERROR: fromsq = " + Str(fromsq) + "  tosq = " + Str(tosq))
        CompilerEndIf
        SetGadgetText(#Info_Field, "...possible ERROR...fromsq or tosq is invalid...recheck gamescore above...setting both squares to: a1")
        If FindString(UCI_move_str,"ma") <= 0                  ; possible mate in match game
          ;MessageRequester("Possible Move format ERROR!", "...ERROR...fromsq or tosq is possibly invalid...recheck gamescore above...setting both squares to: a1")
        EndIf
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
            CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
                PrintN(" ep move...")
              CompilerEndIf
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
      
      If Passed_UCI_Str = ""
        ConstructFENfromPosition()
        Game_FEN_Positions(HalfMoveCount) = FENpositionstr
  
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN("")
          PrintN("Game_FEN_Positions(" + Str(HalfMoveCount) + ") = " + FENpositionstr)
          PrintN("")
  
          PrintN("...from square = " + fromSq_str + "  ...to square = " + toSq_str)
          PrintN("...moving Piece = " + Str(movingPiece))
        CompilerEndIf
      EndIf
      
  EndSelect

EndProcedure


CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  Procedure DoEventMacOS()
    Select EventMenu()
      Case #PB_Menu_Quit
        PostEvent(#PB_Event_CloseWindow, #mainwin, 0)
      Case #PB_Menu_About
        ;MessageRequester("About", "PGNdb"+version, #PB_MessageRequester_Info)
        LoadHelpData()
        CloseWindow(#mainwin)
        DisplayGames()
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
  ; GameFENEditorPlus(), NextMove(), PreviousMove(), ParseAndCleanPGN(), Parse_Save_GameScore_Bare_Halfmoves(), Searching_Sorting(), PopulateMovesGadget(),
  ; RemovePGNCommentsAndVariations2(), SetTextColorABGR(), SizeHandler(), SizeHandlerFENEditorButtons(), KeystrokesMacOs(), LoadHelpData(),
  ; ECOCodeSearch, ExportPGNGame(), ExportToPDF, GadgetToolTipsSetup()

  Protected WindowID.b, HelpWindowID.b, PlayerListGadget.b, MovesGadget.b
  Protected SingleMoveResult.b, FENBtnResult.b, InfoResult.b, ExportPDFBtnResult.b, FileInfoResult.b, HelpImageResult1.b
  Protected PrevBtnResult.b, NextBtnResult.b, DbBtn1Result.b, DbBtn2Result.b, SFBtnResult.b, HelpbtnResult.b, ClosebtnResult.b
  Protected SFBtn10secResult.b, PSBtnResult.b, EdBtnResult.b, UpdSFBtnResult.b, AutoBtnResult.b, CleanPGNBtnResult.b, BtnEngMatchResult.b
  Protected BrdSizeBtnResult.b, PlayvsSFBtnResult, ExportGameBtnResult.b, SampleDataBtnResult.b, GSTestBtnResult.b, ECOCodeBtnResult.b
  Protected shiftKeyState.i, GameIndexFromPost.i, automove.i, Automove_Delay.s, CurrentGameindex.i, SacFilterBtnResult.b
  Protected GameLink_pos.i, G1_pos.i, G2_pos.i, i.i
  Protected ColorToMove.b, WhiteOnMove.b, x.b, y.i, yy.i, z.i
  Protected currentEvent.i, type.i, modifierFlags.i, keycode.i, wflags.i, key_halfmove.i
  Protected dash_pos.i, left_bracket_pos.i, right_bracket_pos.i, Invalid_Engine_Count.i
  Protected Sac_Deficit_filter_str.s, Engine_File.s, EngineOrListFile.s
  
  DisplayGamesCounter = DisplayGamesCounter + 1
  wflags = #PB_Window_SizeGadget | #PB_Window_SystemMenu | #PB_Window_ScreenCentered
  WindowID = OpenWindow(#mainwin, 100, 100, #mainwinDefaultWidth, #mainwinDefaultHeight, "PGNdbkp" + version + " - PGN Game And SQLite chessdb Viewer ", wflags)

  
  PlayerListGadget = ListIconGadget(#Players_ListIcon_Gadget, 20, 10, #playgadgetwidth, #playgadgetDefaultHeight, "Game #", 80, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  
  AddGadgetColumn(#Players_ListIcon_Gadget, 1, "White Player", 175)
  AddGadgetColumn(#Players_ListIcon_Gadget, 2, "Black Player", 175)
  AddGadgetColumn(#Players_ListIcon_Gadget, 3, "GameDate", 80)
  AddGadgetColumn(#Players_ListIcon_Gadget, 4, "Event/Site", 95)
  AddGadgetColumn(#Players_ListIcon_Gadget, 5, "Result", 65)
  AddGadgetColumn(#Players_ListIcon_Gadget, 6, "ECO", 50)
  AddGadgetColumn(#Players_ListIcon_Gadget, 7, "FEN setup (or classic start position)", 475)
  AddGadgetColumn(#Players_ListIcon_Gadget, 8, "PGN GameScore", 5000)
  
  MovesGadget = ListIconGadget(#Move_ListIcon_Gadget, #movesgadgetX , 10, #movesgadgetwidth, #movesgadgetDefaultHeight, "White Player Moves", #movesgadgetwidth/2, #PB_ListIcon_GridLines)
  AddGadgetColumn(#Move_ListIcon_Gadget, 1, "Black Player Moves", #movesgadgetwidth/2)
  ;CocoaMessage(0, 0, "makeFirstResponder:", GadgetID(0))
  AppWindow = WindowID
  CreateMenu(0, WindowID(#mainwin))
      CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      MenuItem(#PB_Menu_About, "Help")
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
  GSTestBtnResult = ButtonGadget(#Btn_GSTest, #fileinfogadgetDefaultX+520, #fileinfogadgetDefaultY, 50, 25, "GS")
  HideGadget(#Btn_GSTest, 1)
  
  HelpbtnResult = ButtonGadget(#Btn_HelpInfo, #ButtonsLeftEdgeDefaultX+205, #InfoFieldDefaultY+50, 100, 25, "HELP INFO")  ; Use About menu item instead?
  FENBtnResult = ButtonGadget(#Btn_Fen, #FENBtnDefaultX, #FENBtnDefaultY, 90, 25, "Show FEN")
  BrdSizeBtnResult = ButtonGadget(#Btn_BoardSize, #ButtonsLeftEdgeDefaultX+100, #FENBtnDefaultY, 100, 25, "BoardSize")
  ExportGameBtnResult = ButtonGadget(#Btn_ExportGame, #ButtonsLeftEdgeDefaultX+205, #FENBtnDefaultY, 120, 25, "ExportGame[s]")
  ExportPDFBtnResult = ButtonGadget(#Btn_ExportPDF, #ButtonsLeftEdgeDefaultX+205, #Single_MoveDefaultY, 120, 25, "ExportToPDF")
  SingleMoveResult = StringGadget(#Single_Move_Gadget, #ButtonsLeftEdgeDefaultX, #Single_MoveDefaultY, 95, 25, " no moves yet")
  CleanPGNBtnResult = ButtonGadget(#Btn_CleanPGN, #ButtonsLeftEdgeDefaultX+100, #Single_MoveDefaultY, 100, 25, "CleanPGN")
  InfoResult = EditorGadget(#Info_Field, #ButtonsLeftEdgeDefaultX, #InfoFieldDefaultY, 200, #InfoFieldDefaultHeight, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
  
  PrevBtnResult = ButtonGadget(#Btn_Prev, #ButtonsLeftEdgeDefaultX, #prevbtnDefaultY, 100, 25, " < move")
  AutoBtnResult = ButtonGadget(#Btn_Automove, #ButtonsLeftEdgeDefaultX+105, #prevbtnDefaultY, 100, 25, "automove")
  NextBtnResult = ButtonGadget(#Btn_Next, #ButtonsLeftEdgeDefaultX, #nextbtnDefaultY, 100, 25, " > move")
  SacFilterBtnResult = ButtonGadget(#Btn_SacFilter, #ButtonsLeftEdgeDefaultX+105, #nextbtnDefaultY, 100, 25, "Sac Filter")
  DbBtn1Result = ButtonGadget(#Btn_Db1, #ButtonsLeftEdgeDefaultX, #dbbtn1DefaultY, 100, 25, "Game to Db")
  ECOCodeBtnResult = ButtonGadget(#Btn_ECOCodes, #ButtonsLeftEdgeDefaultX+105, #dbbtn1DefaultY, 100, 25, "ECO Codes")
  DbBtn2Result = ButtonGadget(#Btn_Db2, #ButtonsLeftEdgeDefaultX, #dbbtn2DefaultY, 125, 25, "All Games to Db")
  SFBtnResult = ButtonGadget(#Btn_SFAnaly, #sfbtnDefaultX, #sfbtnDefaultY, 80, 25, "SF Analy")
  SFBtn10secResult = ButtonGadget(#Btn_SF10sec, #sfbtn10secDefaultX, #sfbtn10secDefaultY, 80, 25, "SF 10sec")
  PlayvsSFBtnResult = ButtonGadget(#Btn_PlayvsSF, #sfbtn10secDefaultX+80, #sfbtn10secDefaultY, 110, 25, "PlayVsEngine")
  UpdSFBtnResult = ButtonGadget(#Btn_UpdSF, #sfbtn10secDefaultX+40, #dbbtn2DefaultY, 120, 25, "Update Engines")
  PSBtnResult = ButtonGadget(#Btn_PSearch, #PSearchbtnDefaultX, #PSearchbtnDefaultY, 140, 25, "Searching/Sorting")
  BtnEngMatchResult = ButtonGadget(#Btn_EngineMatch, #sfbtn10secDefaultX+80, #PSearchbtnDefaultY, 140, 25, "Engine Match")
  EdBtnResult = ButtonGadget(#Btn_FENEditor, #FENEditbtnDefaultX, #FENEditbtnDefaultY, 100, 25, "FEN Editor")
  
  ; create a canvasgadget for the chessboard
  CanvasGadget(#CanvasGadgetChessBoard, #Canvas_GadgetX, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#canvas_gadgetY), #cg_width, #cg_height, #PB_Canvas_Keyboard)
  
  BindEvent(#PB_Event_SizeWindow, @SizeHandler())
  
  BoardDisplay()
  
  GadgetToolTipsSetup()
  
  For i = 1 To GameCount-1
    If Display_Flag(i) = 1
      G1_pos = FindString(WhitePlayers(i), Game_Prefix, 1)
      G2_pos = FindString(BlackPlayers(i), Game_Prefix, 1)
      GameLink = Game_Prefix + Mid(BlackPlayers(i), G2_pos+2, 6)
      FEN_display_str_Set(i)
      AddGadgetItem(#Players_ListIcon_Gadget, -1, GameLink + Chr(10) + Trim(Left(WhitePlayers(i), G1_pos-1), " ") + " [" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + " [" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i) + Chr(10) + ECO_Game_Codes(i) + Chr(10) + FEN_display_str + Chr(10) + Left(FilePGNs(i),#pgnwidth)) 
    EndIf
  Next
  
  If DisplayGamesCounter > 1 And HalfMoveCount > 1                              ; help fix addition, returning to DisplayGames after HELP was called - kp
    If GameIndex <> -1
      SetGadgetState(#Players_ListIcon_Gadget, Gameindex)
    EndIf
    PopulateMovesGadget()
  Else
    SetGadgetText(#Info_Field, "...Select a game above left...")
  EndIf
  
  
  Repeat
    
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      ; ********* start of macintosh macos keyscan code *********
      KeystrokesMacOs()
    ; ********* end of macintosh macos keyscan code *********
    CompilerEndIf
    
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      
      ; ********* start of Windows OS keyscan code ************
      KeystrokesWindowsOs()
      
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
        Select EventWindow()
          Case #Help_window
            CloseWindow(#Help_window)
          Case #Engmatchwin
            CloseWindow(#Engmatchwin)
          Case #mainwin
            Break
        EndSelect
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    Case #PB_Menu_Quit
      If IsWindow(#Help_window) = 0
        PostEvent(#PB_Event_CloseWindow, #mainwin, #Null)
      EndIf
    CompilerEndIf
      Case #PB_Event_Gadget
        Select EventType()
          Case #PB_EventType_LeftClick
            Select EventGadget()
              Case #Btn_SampleData
                MessageRequester("Magic S button","This is the sample Data creator magic S button. ...Information To follow!")
                OutputSampleGameCode2()
              Case #Btn_GSTest
                MessageRequester("Magic GS button","This Btn assists in gamescore validation testing. ...Information To follow!")
                Games_Range_str = InputRequester("GameScore Validation Automated Testing", "GameScore validation number range, i.e.[1-100]", "[1-100]")
                dash_pos = FindString(Games_Range_str,"-",1)
                left_bracket_pos = FindString(Games_Range_str,"[",1)                      ; normally 1 unless I add more flags
                right_bracket_pos = FindString(Games_Range_str,"]",1)
                range_start = Val(Mid(Games_Range_str,left_bracket_pos+1,dash_pos-left_bracket_pos-1))
                range_end = Val(Mid(Games_Range_str,dash_pos+1,right_bracket_pos-dash_pos-1))
                CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
                  PrintN("GSAT:...Range start = " + Str(range_start) + " Range end = " + Str(range_end))
                CompilerEndIf
                SetGadgetState(#Players_ListIcon_Gadget,1)
                SetGadgetItemState(#Players_ListIcon_Gadget,GS_Index,#PB_ListIcon_Selected)
                SetActiveGadget(#Players_ListIcon_Gadget)
                CreateThread(@GameScoreAutomatedTesting_Thread(),1)
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
                ;CompilerIf #PB_Compiler_OS = #PB_OS_MacOS                        ; temp SHIFT-help debugging code
                  ;KeystrokeShiftKeyCheckOnlyMacOs()
                ;CompilerEndIf
                Help_accessed_flag = 0                                            ; temp bypass CanvasChessBoardGadget disappears bugfix
                If Help_accessed_flag = 1
                  MessageRequester("Memory Access Problem.","This Btn option is temporarily disabled. Restarting PGNdbkp will likely solve the memory problem!")
                Else
                  If IsGadget(#CanvasGadgetChessBoard) > 0
                    FreeGadget(#CanvasGadgetChessBoard)
                  EndIf
                  If SquareSize = 60
                    SquareSize = 40
                    CanvasGadget(#CanvasGadgetChessBoard, #Canvas_GadgetX, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#canvas_gadgetY), #cg_width-50, #cg_height-100, #PB_Canvas_Keyboard)
                  Else
                    SquareSize = 60
                    CanvasGadget(#CanvasGadgetChessBoard, #Canvas_GadgetX, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#canvas_gadgetY), #cg_width, #cg_height, #PB_Canvas_Keyboard)
                  EndIf
                  BoardDisplay()
                EndIf
              Case #Btn_ExportGame
                ExportPGNGame()
              Case #Btn_CleanPGN
                DeepCleanPGNs()
              Case #Btn_ExportPDF
                ExportGameToPDF()
              Case #Btn_HelpInfo
                ;MessageRequester("HELP INFO","This Btn is for general HELP information. ...Not Yet Implemented!")
                LoadHelpData()
                CloseWindow(#mainwin)
                DisplayGames()                                                  ; this seeems strange, but canvaschessboardgadget dissapears otherwise 
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
              Case #Btn_Automove
                If GameInfo <> ""
                  Automove_Delay = InputRequester("Automove Time Delay", "Time delay between moves (in seconds)?", "1")
                  For Automove = HalfMoveCount To TotalHalfMoves-1
                    
                    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
                      currentEvent = CocoaMessage(0, sharedApplication, "currentEvent")               ; crude hack to STOP automove
                      If currentEvent
                        type = CocoaMessage(0, currentEvent, "type")
                        modifierFlags = CocoaMessage(0, currentEvent, "modifierFlags")
                          If type = #NSKeyDown
                            keyCode = CocoaMessage(0, currentEvent, "keyCode")
                            If Keycode = 119 Or Keycode = 53                                          ; And (modifierFlags & #NSShiftKeyMask)
                              PrintN("End or Escape key down with code : " + Str(keyCode))
                              Break
                            EndIf
                          EndIf
                      EndIf
                    CompilerEndIf
                    
                    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
                      If (GetAsyncKeyState_(#VK_ESCAPE) & $8000) Or (GetAsyncKeyState_(#VK_NEXT) & $8000)
                        Break
                      EndIf
                    CompilerEndIf
                    
                    NextMove()
                    While WindowEvent() : Wend
                    Delay(Val(Automove_Delay)*1000)
                    SetGadgetText(#Info_Field, "")
                  Next
                EndIf
              Case #Btn_SacFilter
                Sac_Deficit_filter = 1
                Repeat
                  Sac_Deficit_filter_str = InputRequester("Sac Filter (pawn units) Amount", "This option finds games with sacrifices from the gamelist. Please enter the amount (in pawn units) for the sacrifice filter[1-9]:", "2")
                  Sac_Deficit_filter = Val(Sac_Deficit_filter_str)
                Until Sac_Deficit_filter >= 1 And Sac_Deficit_filter <= 9
                Sac_Game_Start_Index_str = InputRequester("Sac Filter starting game index", "Enter the gamelist starting game number[1]","1")
                Sac_Game_Start_Index = Val(Sac_Game_Start_Index_str)
                SacGamesFilter()
              Case #Btn_Db1
                DB_InputFile = InputRequester("DB Input File", "Please enter the PB Sqlite chess db filename: ", "/users/kenpchess/desktop/kppb_pgn_etc/chesspgn_db.sqlite")
                Add_Game_To_SQLite_DB()
              Case #Btn_Db2
                DB_InputFile = InputRequester("DB Input File", "Please enter the full path of the PB Sqlite chess database filename: ", "/users/kenpchess/desktop/kppb_pgn_etc/chesspgn_db.sqlite")
                CreateThread(@Add_All_Games_To_SQLite_DB_Thread(),1)
              Case #Btn_ECOCodes
                MessageRequester("ECO Codes Generation", "This option will generate an ECO code for all games with no ECO code! It may take some time with large PGN files.")
                ECOCodeSearch()
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
                ;EngineOrListFile = "/Users/kenpchess/public/Engine_list.txt"
                EngineOrListFile = InputRequester("Match Engine List or Stockfish Path (path must exist)", "Enter the complete file path of your Engine_List.txt file or Stockfish executable: ", "/users/kenpchess/public/engine_list.txt")
                ;PrintN("EngineOrListFile = " + EngineOrListFile)
                Engine_Count = 0 : Invalid_Engine_Count = 0
                If FindString(EngineOrListFile,"engine_list.txt") > 0 And FileSize(EngineOrListFile) > 0
                  FileHandleEng = ReadFile(0, EngineOrListFile)
                  If FileHandleEng
                    While Not Eof(0) And Engine_Count < #numAllowedEngines
                      Engine_File = ReadString(0)
                      If Engine_File <> "" And Left(Engine_File,1) <> ";"
                        If FileSize(Engine_File) > 0
                          Engine_Count = Engine_Count + 1
                          Engine_Path(Engine_Count) = Engine_file
                          ;PrintN("Engine file = " + Engine_Path(Engine_Count))
                        Else
                          Invalid_Engine_Count = Invalid_Engine_Count + 1
                        EndIf
                      EndIf
                    Wend
                    CloseFile(0)
                    If Invalid_Engine_Count > 0
                      MessageRequester("Some Engines Invalid", "Some of the engine names or paths (" + Str(Invalid_Engine_Count) + ") are invalid! Check Engine_List.txt")
                    Else
                      MessageRequester("All Engines valid!", "Number of valid engines is  [" + Str(Engine_Count) + "]. Proceed with games or an engine match.")
                    EndIf
                    For i = 1 To Engine_Count
                      Engine_Name(i) = "MatchEngine" + Chr(64+i) + " (Player " + Str(i) + ")"
                    Next
                  EndIf
                Else
                  If FileSize(EngineOrListFile) > 0
                    Engine_Count = Engine_Count + 1
                    Engine_Path(1) = EngineOrListFile
                    For i = 2 To #numAllowedEngines
                      Repeat
                        Engine_Path(i) = InputRequester("Match Engine Path (path must exist)", "Please enter the complete file path of your Engine" + Chr(64+i) + " executable (or blank): ", "/Applications/ChessEnginesOSX/someEngine")
                      Until FileSize(Engine_Path(i)) > 0 Or Engine_Path(i) = ""
                      If Engine_Path(i) = ""
                        Break
                      Else
                        Engine_Count = Engine_Count + 1
                      EndIf
                    Next
                  Else
                    For i = 1 To #numAllowedEngines
                      Repeat
                        Engine_Path(i) = InputRequester("Match Engine Path (path must exist)", "Please enter the complete file path of your Engine" + Chr(64+i) + " executable (or blank): ", "/Applications/ChessEnginesOSX/someEngine")
                      Until FileSize(Engine_Path(i)) > 0 Or Engine_Path(i) = ""
                      If Engine_Path(i) = ""
                        Break
                      Else
                        Engine_Count = Engine_Count + 1
                      EndIf
                    Next
                  EndIf
                EndIf
              Case #Btn_PSearch
                Searching_Sorting()
              Case #Btn_EngineMatch
                ;MessageRequester("Engine vs Engine match.","This Btn option is not yet available!")
                If Engine_Count < 2
                  MessageRequester("You need at least 2 engines for an Engine(s) vs Engine(s) match.","Use the 'Update Engines' button to set your engines!")
                Else
                  EngineMatchMain()
                EndIf
              Case #Btn_FENEditor
                Help_accessed_flag = 0                             ; temp bypass CanvasChessBoardGadget disappears bugfix
                If Help_accessed_flag = 1
                  MessageRequester("Memory Access Problem.","This Btn option is temporarily disabled. Restarting PGNdbkp will likely solve the memory problem!")
                Else
                  GameFENEditorPlus()
                EndIf
              Case #Players_ListIcon_Gadget
                GameIndex = GetGadgetState(#Players_ListIcon_Gadget)
                If GSAT_Flag = #True
                  GameIndex = EventData()
                  SetActiveGadget(#Players_ListIcon_Gadget)
                  SetGadgetItemState(#Players_ListIcon_Gadget,GS_Index,#PB_ListIcon_Selected)
                  SetGadgetText(#Info_Field, "GSAT:...Checking game #" + Str(GameIndex+1))
                  While WindowEvent() : Wend
                  Delay(100)
                EndIf
                CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
                  PrintN("***************GameIndex = " + Str(GameIndex))
                CompilerEndIf
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
                  FilePGNs(Val(GameLink)) = gamescore_result
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





Procedure ECOCodeSearch()
  
  Protected i.i, j.i, GameMoves.s, ECOMoveSequence.s, ECOCodeMatch.s, ECOMoveLength.i, ECO_Start_Index.i, ECO_End_Index.i
  Protected FirstMove.s
  
  DisableGadget(#Players_ListIcon_Gadget, #True)
  For i = 1 To GameCount - 1
    If ECO_Game_Codes(i) = "" Or ECO_Game_Codes(i) = "n/a"
      If i % 100 = 0
        SetGadgetText(#Info_Field, "...searching ECO codes for game #" + Str(i))
        While WindowEvent() : Wend
      EndIf
      GameMoves = ReplaceString(FilePGNs(i),Space(1),"")
      FirstMove = Left(GameMoves,4)
      ECOMoveLength = 0
      ECOCodeMatch = "n/a"
      Select FirstMove
        Case "1.e4"
          ECO_Start_Index = 746 : ECO_End_Index = 2689
        Case "1.c4"
          ECO_Start_Index = 265 : ECO_End_Index = 436
        Case "1.d4"
          ECO_Start_Index = 425 : ECO_End_Index = #ECO_Codes_max
        Default
          ECO_Start_Index = 1 : ECO_End_Index = #ECO_Codes_max
      EndSelect

      For j = ECO_Start_Index To ECO_End_Index
        ECOMoveSequence = ReplaceString(ECO_Table_Moves(j),Space(1),"")
        If FindString(GameMoves,ECOMoveSequence) > 0 And Len(ECOMoveSequence) > ECOMoveLength
          ECOCodeMatch = ECO_Table_Codes(j)
          ECOMoveLength = Len(ECOCodeMatch)
          ;PrintN("...ECO match found = " + ECOCodeMatch + "  Length = " + Str(ECOMoveLength))
          ECO_Game_Codes(i) = ECOCodeMatch
        EndIf
      Next
      ;SetGadgetItemText(#Players_ListIcon_Gadget,i-1,ECOCodeMatch,6)
    EndIf
  Next
  DisableGadget(#Players_ListIcon_Gadget, #False)
  Refresh_PlayersListIconGadget(#False)
  SetGadgetText(#Info_Field, "...All ECO codes were generated.")
  
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
    HalfMove_Diagram_Counter = 400
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
  SetGadgetText(#Info_Field, "...Analyzing Game: #" + Str(k) + "...")
  While WindowEvent() : Wend
   If Engine_analy_flag
    Delay(100)
  Else
    Delay(10)
  EndIf
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    PrintN("****************...working on game # " + Str(k) + "...******************")
  CompilerEndIf
If FileID
  ;PrintN("FILEID="+Str(FILEID))
  If GameIndex >= 0
    ;PrintN("GameIndex = "+ Str(GameIndex))
    FilePGNs(k) = ParseAndCleanPGN(FilePGNs(k))
    RemovePGNCommentsAndVariations2(FilePGNs(k))
    FilePGNs(k) = gamescore_result
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      PrintN("************************FilePGN(" + Str(k) + ") = " + FilePGNs(k))
    CompilerEndIf
    For j = 1 To #halfmove_max : GameScore_Plain_HalfMoves(j) = "" : Game_FEN_Positions(j) = "" : Next
    Parse_Save_GameScore_Bare_Halfmoves(FilePGNs(k))
    G1_pos = FindString(WhitePlayers(k), Game_Prefix, 1)
    G2_pos = FindString(BlackPlayers(k), Game_Prefix, 1)
    MoveString = ""
    WriteStringN(FileID, "[Game " + #DQUOTE$ + Str(k) + #DQUOTE$ + "]")
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
    If ECO_Game_Codes(k) <> "" And ECO_Game_Codes(k) <> "n/a"
      WriteStringN(FileID, "[ECO " + #DQUOTE$ + ECO_Game_Codes(k) + #DQUOTE$ + "]")
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
  
  MoveString = ""
  For j = 1 To TotalHalfMoves
    If j % 2 > 0 And J <> TotalHalfMoves
      MoveString = MoveString + Str(j/2 + 1) + ". " + ReplaceString(GameScore_Plain_HalfMoves(j),Space(1),"") + Space(1)
    Else
      MoveString = MoveString + ReplaceString(GameScore_Plain_HalfMoves(j),Space(1),"") + Space(1)
    EndIf
  Next
  MoveString = Trim(Movestring,Space(1))
  If GameIndex < 0
    MoveString = MoveString + Space(1) + "*"
  EndIf
  WriteString(FileID, MoveString)
  
  For z = 1 To TotalHalfMoves
    If ((z-1) % 2 > 0 And z % HalfMove_Diagram_Counter = 0) Or (z >= TotalHalfMoves-6 And (z-1) % 2 > 0 And HalfMove_Diagram_Counter <> 400)
      If FindString(GameResult_SearchMask, Trim(GameScore_Plain_HalfMoves(z),Space(1))) <= 0
        ConstructPositionfromFEN(Game_FEN_Positions(z))
        BoardDisplay()
        While WindowEvent() : Wend
      Else
        ConstructPositionfromFEN(Game_FEN_Positions(z-1))
        BoardDisplay()
        While WindowEvent() : Wend
      EndIf
      WriteString(FileID, "") : WriteString(FileID, #CRLF$) : WriteString(FileID, #CRLF$)
      PrintAsciiBoard(1, FILEID)
      PrintAsciiBoard(2, FILEID)
      WriteString(FileID, Str(z/2) + ". " + Trim(GameScore_Plain_HalfMoves(z-1),Space(1)) + Space(1) + GameScore_Plain_HalfMoves(z))
      WriteString(FileID, #CRLF$)
      pvstring(1) = "" : pvstring(2) = "" : cpscore_str(1) = "" : cpscore_str(2) = ""
      If Game_FEN_Positions(z) <> "" And Engine_analy_flag > 0
        SF_Time_Per_Move = 500
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
        ;Delay(1250)                                                         ; empirical value via testing to help engine thread syncing
        While Engine_Running_Flag = #True                                    ; newer somewhat better synching method
          Delay(5)
        Wend
        WriteString(FileID, "pv = " + pvstring(1) + Space(2) + "eval = " + cpscore_str(1))
        WriteString(FileID, #CRLF$)
      EndIf
    EndIf
  Next
  WriteString(FileID, #CRLF$) : WriteString(FileID, #CRLF$)
  EndIf
Next

SetGadgetText(#Info_Field, "...All games analyzed and exported...")
While WindowEvent() : Wend
Delay(1000)

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
  ; ConstructPositionfromFEN(), and CreateThread(@Stockfish_FEN_Analysis_Thread(),1), CreateThread(@PDFMove_Thread(),1), CreateThread(@PDFAnalysis()_Thread,1)
  ; and DrawVeectorTextDemoDataImage.
  ;
  ; Also see the comments for the above-named last three procedures: CreateThread(@PDFMove_Thread(),1), CreateThread(@PDFAnalysis()_Thread,1)
  ; and DrawVeectorTextDemoDataImage. This entire ExportGameToPDF() procedure is NOT VERY ELEGANT but I had to work around several feature-limits
  ; of the PureBasic language (which overall is a very good development system!). But I really had a strong desire for this ExportGameToPDF() feature and hope
  ; to improve it in the future. It does work quite well on the macintosh version.
  
  
Protected DefaultFileName.s, Pattern.s, PDFFilename.s, PDFFilename0.s, FileID.i, G1_pos.i, G2_pos.i, GameLink0.s, diagram_pos.i
Protected fullversionname.s = "PGNdbkp" + version
Protected nowdate1.s, nowdate2.s, Games_Export_Count_str.s
Protected j.i, k.i, z.i, zz.i, year.i, month.i, day.i, hour.i, minute.i, seconds.i, Games_Export_Count.i, dash_pos.i
Protected HalfMove_Diagram_Counter.i, color_pos.i, Engine_analy_flag.i, right_bracket_pos.i, first_slash_pos.i
Protected PDFSquareSize.i = 24, ext_pos.i


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
    HalfMove_Diagram_Counter = 400
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
PDFFilename0 = PDFFilename

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  PrintN("********** PDFFileName = " + PDFFileName)
CompilerEndIf


For k = Val(GameLink0) To Games_Export_Count
  SetGadgetText(#Info_Field, "...Analyzing Game: #" + Str(k) + "...")
  While WindowEvent() : Wend
  Delay(200)
  If GameIndex >= 1
    FilePGNs(k) = ParseAndCleanPGN(FilePGNs(k))
    ;PrintN("FilePGN(" + Str(k) + ") = " + FilePGNs(k))
    RemovePGNCommentsAndVariations2(FilePGNs(k))
    FilePGNs(k) = gamescore_result
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
  
  DrawVectorTextDemoDataToImage(k)                            ; this procedure draws GAME INFO for the diagram, DrawVectorText doesn't work with PDF under Windows!
  
  Ext_pos = FindString(PDFFilename0,".pdf")
  If Ext_pos > 0
    PDFFilename = Left(PDFFilename0,Ext_pos-1) + "_G" + Str(k) + ".pdf"
  EndIf
  StartVectorDrawing(PdfVectorOutput(PDFFileName, PDFWidth, PDFHeight))
  
  For z = 1 To TotalHalfMoves
    If ((z-1) % 2 > 0 And z % HalfMove_Diagram_Counter = 0) Or (z >= TotalHalfMoves-6 And (z-1) % 2 > 0 And HalfMove_Diagram_Counter <> 400)
      If FindString(GameResult_SearchMask, Trim(GameScore_Plain_HalfMoves(z),Space(1))) <= 0
        ConstructPositionfromFEN(Game_FEN_Positions(z))
        ;BoardDisplay()
        ;While WindowEvent() : Wend
      Else
        ConstructPositionfromFEN(Game_FEN_Positions(z-1))
        ;BoardDisplay()
        ;While WindowEvent() : Wend
      EndIf
      
      CreateChessboardPDF()
      MovePathCursor(PDFSquareSize*8 + #doc_offset, 0)
      DrawVectorImage(ImageID(#ImageID_DemoBkgnd), 255, 400, 800)
      pdf_halfmove = z
      CreateThread(@PDFMove_Thread(),1)                               ; this procedure creates MOVE INFO for the diagram, DrawVectorText doesn't work with PDF under Windows!
      Delay(500)
      
      MovePathCursor(#doc_offset+55, 225)                     
      DrawVectorImage(ImageID(#ImageID_DemoBkgnd2), 255, 100, 100)    ; draw the MOVE INFO image from above thread
      FreeImage(#ImageID_DemoBkgnd2)
         
      pvstring(1) = "" : pvstring(2) = "" : cpscore_str(1) = "" : cpscore_str(2) = ""
      If Game_FEN_Positions(z) <> "" And Engine_analy_flag > 0
        SF_Time_Per_Move = 500
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
        ;Delay(1250)                                                           ; empirical value via testing to help engine thread syncing, kinda junky!
        While Engine_Running_Flag = #True                                    ; newer somewhat better synching method
          Delay(5)
        Wend
        
        CompilerIf #PB_Compiler_OS = #PB_OS_Windows
          CreateThread(@PDFAnalysis_Thread(),1)                               ; this procedure creates ANALYSIS INFO for the diagram, DrawVectorText doesn't work with PDF under Windows!
          Delay(500)
          MovePathCursor(#doc_offset, #demo_y_offset + SquareSize*4)
          DrawVectorImage(ImageID(#ImageID_DemoBkgnd3), 255, 200, 200)        ; draw the ANALYSIS INFO image created above
          FreeImage(#ImageID_DemoBkgnd3)
        CompilerEndIf
        
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          MovePathCursor(#doc_offset*2, #demo_y_offset + PDFSquareSize*10)
          DrawVectorText("[...engine analysis...]")
          MovePathCursor(#doc_offset, #demo_y_offset + PDFSquareSize*11)
          DrawVectorParagraph("pv = " + pvstring(1) + Space(2) + "eval = " + cpscore_str(1), 200, 200)
        CompilerEndIf
        
        NewVectorPage()
      EndIf
    EndIf
  Next
EndIf

If k < Games_Export_Count
  NewVectorPage()
EndIf
SetGadgetText(#Info_Field, "Text file: " + PDFFilename + " created successfully.")
While WindowEvent() : Wend
Delay(1000)
Next

StopVectorDrawing()

;CloseFile(FileID)
  
  
EndProcedure


Procedure FEN_display_str_Set(index.i)
  
  If Trim(FEN_setup_str(index),Space(1)) = ""
    FEN_display_str = FEN_Start_Position
  Else
    FEN_display_str = FEN_setup_str(index)
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


Procedure GadgetToolTipsSetup()
  
  GadgetToolTip(#Btn_Fen, "Displays the Forsythe-Edwards notation for the current position.")
  GadgetToolTip(#Btn_BoardSize, "Toggle between 60-point squaresize and 40-point squaresize chessboard.")
  GadgetToolTip(#Btn_ExportGame, "Exports PGN gamescore plus enginine analysis plus board text diagram.")
  GadgetToolTip(#Btn_CleanPGN, "Deep-cleans (removes) extraneous information from all PGN gamescores.")
  GadgetToolTip(#Btn_ExportPDF, "Exports PGN gamescore plus enginine analysis plus graphic board diagram to PDF file.")
  ;GadgetToolTip(#Btn_HelpInfo, "Thank you, Captain Obvious.")
  
  GadgetToolTip(#Btn_Prev, "You may also use the <left-arrow-key>.")
  GadgetToolTip(#Btn_Next, "You may also use the <right-arrow-key>.")
  GadgetToolTip(#Btn_Automove, "Replays the entire PGN gamescore.")
  GadgetToolTip(#Btn_SacFilter,"Filter games with sacrifices with specified pawn units.")
  GadgetToolTip(#Btn_Db1, "Saves game to PGNdbkp-specific sqlite database.")
  GadgetToolTip(#Btn_Db2, "Saves all games to PGNdbkp-specific sqlite database.")
  GadgetToolTip(#Btn_ECOCodes, "Inserts opening-specific ECO code into each game.")
  
  GadgetToolTip(#Btn_SFAnaly, "Light engine analysis (1-sec) of current position with principal variation.")
  GadgetToolTip(#Btn_SF10sec, "Medium engine analysis (10-sec) of current position with two principal variations.")
  GadgetToolTip(#Btn_PlayvsSF, "Play directly against currently installed chess engine.")
  GadgetToolTip(#Btn_UpdSF, "Update the file location of the currently installed chess engine.")
  GadgetToolTip(#Btn_PSearch, "Player, move sequence, and ECO code searching and sorting options.")
  GadgetToolTip(#Btn_EngineMatch,"Run tournaments between engines with up to four engines.")
  GadgetToolTip(#Btn_FENEditor, "The point-and-click FEN position editor.")
  
EndProcedure


Procedure GameFENEditorPlus()
  
  Protected i.i, Demographic_Info.s, Position_Info.s, Save_Text.s, WhitePlayer.s, BlackPlayer.s, Info_Result.s, Info_Description.s, GameLink.s
  Protected Space1_pos.b, Space2_pos.b, Move_Sequence.s, Start_Info.s, ECOCode.s
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
    Save_Text = InputRequester("Save FEN Position in GameList", "Save this FEN position in the gamelist?", "No")
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
    ECOCode = "n/a"
    
    GameLink = Game_Prefix + Str(GameCount)
    
    WhitePlayers(GameCount) = WhitePlayer + Space(3) + Game_Prefix + Str(GameCount)
    BlackPlayers(GameCount) = BlackPlayer + Space(3) + Game_Prefix + Str(GameCount)
    EventSites(GameCount) = Info_Description
    Each_Game_Result(GameCount) = Info_Result
    ECO_Game_Codes(GameCount) = "n/a"
    FilePGNs(GameCount) = Move_Sequence + Info_Result
    PrintN("New game position addition = " + GameLink + Space(2) + WhitePlayer + Space(2) + BlackPlayer + Space(2) + Info_Result)
    AddGadgetItem(#Players_ListIcon_Gadget, -1, GameLink + Chr(10) + WhitePlayer + Chr(10) + BlackPlayer + Chr(10) + "20990101" + Chr(10) + Info_Description + Chr(10) + Info_Result + Chr(10) + ECOCode + Chr(10) + Position_Info + Chr(10) + Left(FilePGNs(GameCount),#pgnwidth))
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


Procedure GameScoreAutomatedTesting_Thread(null)
  
  Protected DefaultFileName.s, nowdate2.s, FileID.i
  
  nowdate2 = FormatDate("%yyyy%mm%dd", Date())
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    DefaultFileName = "/Users/kenpchess/Desktop/" + "GSAT_" + nowdate2 + ".log"
  CompilerEndIf

  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    DefaultFileName = GetTemporaryDirectory() + "GSAT_" + nowdate2 + ".log"
  CompilerEndIf
  
  FileID = OpenFile(#PB_Any, DefaultFileName)
  WriteStringN(FileID, "PGNFile = " + DB_InputFile + #CRLF$)
  
  For GS_Index = range_start-1 To range_end-1
    GSAT_Flag = #True
    
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      PrintN("GSAT:...Checking gamescore #" + Str(GS_Index+1))
    CompilerEndIf

    PostEvent(#PB_Event_Gadget, #mainwin, #Players_ListIcon_Gadget, #PB_EventType_LeftClick, GS_Index)
    
    WriteStringN(FileID, "...Gamescore # = " + Str(GS_Index))
    
    Delay(250)
    
    ;SetGadgetItemState(#Players_ListIcon_Gadget, GS, #PB_ListIcon_Selected)
    ;While WindowEvent() : Wend
  Next
  ;PostEvent(#PB_Event_Gadget, #mainwin, #Players_ListIcon_Gadget, #PB_EventType_LeftClick, range_end)
  ;Delay(500)
  CloseFile(FileID)
  GSAT_Flag = #False
  
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


CompilerIf #PB_Compiler_OS = #PB_OS_MacOS

  Procedure KeystrokesMacOs()
    
    Protected key_halfmove.i
  
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
              If modifierFlags & #NSShiftKeyMask
                For key_halfmove = 1 To 10
                  PreviousMove()
                Next
              Else
                PreviousMove()
              EndIf
              SetGadgetText(#Info_Field, "")
            EndIf
          Case 124                                              ; same code as NextButton
            PrintN("Right-Arrow Key down with code : " + Str(keyCode))
            If GameInfo <> ""
              If modifierFlags & #NSShiftKeyMask
                For key_halfmove = 1 To 10
                  If HalfMoveCount <= TotalHalfMoves -10
                    NextMove()
                  EndIf
                Next
              Else
                NextMove()
              EndIf
              BoardDisplay()
              SetGadgetText(#Info_Field, "")
            EndIf
        EndSelect
      EndIf
    EndIf
  
EndProcedure

CompilerEndIf


CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  
Procedure KeystrokeShiftKeyCheckOnlyMacOs()
  
   currentEvent = CocoaMessage(0, sharedApplication, "currentEvent")
    If currentEvent
      type = CocoaMessage(0, currentEvent, "type")
      modifierFlags = CocoaMessage(0, currentEvent, "modifierFlags")
      If modifierFlags & #NSShiftKeyMask
        PrintN("...Shift-key and BoardSize button pressed. Toggling Help_accessed_flag off for debugging purposes.")
        Help_accessed_flag = 0
      EndIf
    EndIf
    
EndProcedure

CompilerEndIf



CompilerIf #PB_Compiler_OS = #PB_OS_Windows

Procedure KeystrokesWindowsOs()
  
  shiftKeyState = GetAsyncKeyState_(#VK_SHIFT) & $8000;

    If GetAsyncKeyState_(#VK_RIGHT) & $8000 ; Check if the right-arrow is down
      ;PrintN("Right-Arrow is down!")
      If GameInfo <> ""
        If shiftKeyState
          Delay(150)
          For key_halfmove = 1 To 10
            If HalfMoveCount <= TotalHalfMoves - 10
              NextMove()
            EndIf
          Next
        Else
          Delay(150)                          ; yeah i know, kinda kludgy, right-arrow key is very touchy otherwise on Windows
          NextMove()
        EndIf
        BoardDisplay()
        SetGadgetText(#Info_Field, "")
      EndIf
    EndIf
    If GetAsyncKeyState_(#VK_LEFT) & $8000 ; Check if the left-arrow is down
      ;PrintN("Left-Arrow key is down!")
      If HalfMoveCount > 0
        If shiftKeyState
          Delay(150)
          For key_halfmove = 1 To 10
            PreviousMove()
          Next
        Else
          Delay(150)
          PreviousMove()
        EndIf
      EndIf
      SetGadgetText(#Info_Field, "")
    EndIf
  
EndProcedure

CompilerEndIf




Procedure LoadPGN_Thread(null)
  Protected FileHandle, GameLine.s, WhitePlayer.s, BlackPlayer.s, GamePGN.s, ChessEvent.s, WhiteElo.s, BlackElo.s, ECOGameCode.s
  Protected ChessSite.s, ChessDate.s, InGame.b, MovesStarted.b, Quote1.i, Quote2.i, x.i, j.i, filelen.i
  Protected readBytes.l
  
  All_Games_Read_Flag = 0
  ;PrintN("filename = " + PGNFileName)
  FileHandle = ReadFile(0, PGNFileName)
  If FileHandle
    GamePGN = "" : GameLine = "" : WhitePlayer = "" : BlackPlayer = "" : ChessEvent = "" : ECOGameCode = "n/a"
    ChessSite = "" : ChessDate = "" : WhiteElo = "n/a" : BlackElo = "n/a" : GameCount = 1 : MovesStarted = 0
    For x = 1 To #halfmove_max : FEN_setup_flag(x) = 0 : FEN_setup_str(x) = ""
      Each_Game_Result(x) = "" : WhiteElos(x) = "n/a" : BlackElos(x) = "n/a" : ECO_Game_Codes(x) = "n/a"
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
          Case ECOTag
            ECOGameCode = Mid(GameLine, 7, Len(GameLine) - 8)
            If ECOGameCode = ""
              ECOGameCode = "n/a"
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
            ECO_Game_Codes(GameCount) = ECOGameCode
            GamePGN = ReplaceString(GamePGN, Space(2), Space(1)) ; convert any double-spaces to a single space
            ;RemovePGNCommentsAndVariations2(GamePGN.s)
            ;FilePGNs(GameCount) = gamescore_result
            ;FilePGNs(GameCount) = ParseAndCleanPGN(GamePGN)      ; parseandcleanpgn() is latest best attemt at cleaning grungy PGNs
            FilePGNs(GameCount) = GamePGN
            CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
              PrintN("FilePGNs(GameCount) = " + FilePGNs(GameCount))
            CompilerEndIf
            Display_Flag(GameCount) = 1
            CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
              PrintN("GameDate = " + GameDates(GameCount)) : PrintN("WhiteElo = " + WhiteElos(GameCount))
              PrintN("BlackElo = " + BlackElos(GameCount)) : PrintN("ECOTag = " + ECO_Game_Codes(GameCount))
              PrintN("GameCount = " + Str(GameCount)) : PrintN("FilePGN = " + FilePGNs(GameCount))
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
  Protected HalfMove_Pair.s, AnyFEN_str.s, GameLink_pos.i, WhitePlayer.s, Blackplayer.s, query.s, ECO.s, ucimoves_str.s, TheGameDate.s
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
       ECO_Game_Codes(GameCount) = GetDatabaseString(#sqlite, 9)
       PrintN("ECOCode = " + ECO_Game_Codes(GameCount))
       Display_Flag(GameCount) = 1
       
       If AnyFEN_str <> ""
         FEN_setup_str(GameCount) = AnyFEN_str
         FEN_setup_flag(GameCount) = 1
       EndIf
         
       ucimoves_str = Trim(GetDatabaseString(#sqlite, 10))
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


Procedure Load_ECO_Table()
  
  Protected i.i
  
  Restore ECOData
  For i = 1 To #ECO_Codes_max
    Read.s ECO_Table_Codes(i)
    Read.s ECO_Table_Names(i)
    Read.s ECO_Table_Moves(i)
    Read.s ECO_Table_FENs(i) 
    ;PrintN("ECO("+Str(i)+") = " + ECO_Table_Codes(i) + Space(2) + ECO_Table_Names(i) + Space(2) + ECO_Table_Moves(i))
  Next
  
EndProcedure


  Procedure LoadHelpData()
    
    Protected HelpLine.s, HelpMsg.s, a.i, HelpWindowID.b
    Protected ClosebtnResult.b, HelpImageResult1.b, HelpImageResult2.b
    Protected DisplayGames_help_debug_flag.b = 0
    
    DisableWindow(#mainwin, #True)
    CatchImage(55, ?helpscreen1)
    CatchImage(56, ?PGNdbkp_scrollright)
    HelpWindowID = OpenWindow(#Help_window, 0, 0, 950, 975, "PGNdbkp HELP and INFO", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    If HelpWindowID
      SetActiveWindow(#Help_window)
      Help_accessed_flag = 1
      EditorGadget(#Help_EditorGadget, 25, 30, 900, 550, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
      ClosebtnResult = ButtonGadget(#Btn_CloseHelp, 850, 5, 75, 25, "Close")
      HelpImageResult1 = ImageGadget(#HelpImageGadget1, 50, 600, 375, 375, ImageID(55))
      HelpImageResult2 = ImageGadget(#HelpImageGadget2, 550, 600, 375, 375, ImageID(56))
    EndIf
    
    Restore HelpData
    HelpMsg = ""
    For a = 1 To #HelpInfoLines
      Read.s HelpLine
      HelpMsg = HelpMsg + HelpLine + Space(1) + #CRLF$
    Next
    
    SetGadgetText(#Help_EditorGadget, HelpMsg)
    
    Repeat
    Select WaitWindowEvent()
      Case #PB_Event_Gadget
        Select EventType()
          Case #PB_EventType_LeftClick
            Select EventGadget()
              Case #Btn_CloseHelp
                FreeGadget(#Help_EditorGadget)
                FreeGadget(#Btn_CloseHelp)
                FreeGadget(#HelpImageGadget1)
                FreeGadget(#HelpImageGadget2)
                ;HideWindow(#Help_window, #True)      ; a bugfix try
                ;DisableWindow(#Help_window,#True)    ; a bugfix try
                CloseWindow(#Help_window)
                CompilerIf #PB_Compiler_OS = #PB_OS_MacOS                        ; temp SHIFT-help debugging code
                currentEvent = CocoaMessage(0, sharedApplication, "currentEvent")
                If currentEvent
                  type = CocoaMessage(0, currentEvent, "type")
                  modifierFlags = CocoaMessage(0, currentEvent, "modifierFlags")
                  If modifierFlags & #NSShiftKeyMask
                    PrintN("...Shift-key pressed. Toggling DisplayGames_help_debug_flag.")
                    DisplayGames_help_debug_flag = 1
                  EndIf
                EndIf
                CompilerEndIf
            EndSelect
        EndSelect
    EndSelect
    Until IsWindow(#Help_window) = 0
    ;Until WaitWindowEvent() = #PB_Event_CloseWindow Or IsWindow(#Help_window) = 0
    
    DisableWindow(#mainwin, #False)
    SetActiveWindow(#mainwin)
    
    
  EndProcedure



Procedure LoadSampleGames()

  Protected i.i
  ;#sample_games = 20

For i = 1 To #sample_games : Display_Flag(i) = 1 : FEN_setup_str(i) = "" : FEN_setup_flag(1) = 0 : Next

Restore SampleGames
For i = 1 To #sample_games
  Read.s EventSites(i)
  Read.s GameDates(i)  
  Read.s WhitePlayers(i) 
  Read.s WhiteElos(i) 
  Read.s BlackPlayers(i) 
  Read.s BlackElos(i) 
  Read.s Each_Game_Result(i)
  Read.s ECO_Game_Codes(i)
  Read.s FilePGNs(i)
Next
  
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
      Convert_UCI_Notation("")
      SetGadgetItemColor(#Move_ListIcon_Gadget, (HalfMoveCount-1)/2, #PB_Gadget_FrontColor, #Red,  MoveColumn)
    Else
      PrintN("NM: FEN_SideToMove = " + Str(FEN_SideToMove))
      PrintN("NM: HalfMoveCount = " + Str(HalfMoveCount))
      PrintN("NM: GameScore_UCI_HalfMoves(HalfMoveCount) = " + GameScore_UCI_HalfMoves(HalfMoveCount))
      Select FEN_SideToMove
        Case White_On_Move
          Convert_UCI_Notation("")
          SetMoveColumn()
          SetGadgetItemColor(#Move_ListIcon_Gadget, (HalfMoveCount-1)/2, #PB_Gadget_FrontColor, #Red,  MoveColumn)
        Case Black_on_Move
          If FindString(Left(UCI_move_str,3),Dot_Sequence) <= 0
            Convert_UCI_Notation("")
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
  
  
    Procedure OutputSampleGameCode2()
    
    Protected j.i, x.i, dash1_pos.i, rb_pos.i, lb_pos.i, nowdate1.s, DefaultFileName.s, Pattern.s, CodeFilename.s, GameInfoLine.s, PGNScore.s
    Protected Sample_Games_Output_Count_str.s, PGNNoNagGameScore.s
    Protected Sample_Range_End.i, Sample_Range_Start.i, FileID.i
    Protected cs.s = "," + Space(1)
    
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
    
    ;For x = #sample_games + 1 To Sample_Range_End
    For x = Sample_Range_Start To Sample_Range_End
      
      ;Data.s "WCC31-Moscow", "19840910", "Karpov, Anatoly   G#1101", "2705", "Kasparov, Garry   G#1101", "2715", "1-0"
      ;Data.s "1. d4 d5 2. c4 e6 3. Nf3 c5 4. cxd5 exd5 5. g3 Nf6 6. Bg2 Be7 7. O-O O-O 8. Nc3 Nc6 9. Bg5 cxd4 10. Nxd4 h6 11. Be3 Re8 12. Qb3 Na5 13. Qc2 Bg4 14. Nf5 Rc8 15. Bd4 Bc5 16. Bxc5 Rxc5 17. Ne3 Be6 18. Rad1 Qc8 19. Qa4 Rd8 20. Rd3 a6 21. Rfd1 Nc4 22. Nxc4 Rxc4 23. Qa5 Rc5 24. Qb6 Rd7 25. Rd4 Qc7 26. Qxc7 Rdxc7 27. h3 h5 28. a3 g6 29. e3 Kg7 30. Kh2 Rc4 31. Bf3 b5 32. Kg2 R7c5 33. Rxc4 Rxc4 34. Rd4 Kf8 35. Be2 Rxd4 36. exd4 Ke7 37. Na2 Bc8 38. Nb4 Kd6 39. f3 Ng8 40. h4 Nh6 41. Kf2 Nf5 42. Nc2 f6 43. Bd3 g5 44. Bxf5 Bxf5 45. Ne3 Bb1 46. b4 gxh4 47. Ng2 $1 hxg3+ 48. Kxg3 Ke6 49. Nf4+ Kf5 50. Nxh5 Ke6 51. Nf4+ Kd6 52. Kg4 Bc2 53. Kh5 Bd1 54. Kg6 Ke7 55. Nxd5+ Ke6 56. Nc7+ Kd7 57. Nxa6 Bxf3 58. Kxf6 Kd6 59. Kf5 Kd5 60. Kf4 Bh1 61. Ke3 Kc4 62. Nc5 Bc6 63. Nd3 Bg2 64. Ne5+ Kc3 65. Ng6 Kc4 66. Ne7 Bb7 67. Nf5 Bg2 68. Nd6+ Kb3 69. Nxb5 Ka4 70. Nd6 1-0"
      
      GameInfoLine = #DQUOTE$ + EventSites(x) + #DQUOTE$ + cs + #DQUOTE$ + GameDates(x) + #DQUOTE$ + cs + #DQUOTE$ + WhitePlayers(x) + #DQUOTE$ + cs
      GameInfoLine = GameInfoLine + #DQUOTE$ + WhiteElos(x) + #DQUOTE$ + cs + #DQUOTE$ + BlackPlayers(x) + #DQUOTE$ + cs
      GameInfoLine = GameInfoLine + #DQUOTE$ + BlackElos(x) + #DQUOTE$ + cs + #DQUOTE$ + Each_Game_Result(x) + #DQUOTE$ + cs
      GameInfoLine = GameInfoLine + #DQUOTE$ + ECO_Game_Codes(x) + #DQUOTE$
      
      PGNNoNagGameScore = FilePGNs(x)
      For j = 150 To 1 Step -1
        PGNNoNagGameScore = ReplaceString(PGNNoNagGameScore,"$"+Str(j),"")   ; remove mal-formed NAGs (with no space after the $)
      Next
      
      PGNScore = PGNNoNagGameScore
      WriteStringN(FileID, "; sample game " + Str(x))
      WriteStringN(FileID, "Data.s " + GameInfoLine)
      WriteStringN(FileID, "Data.s " + #DQUOTE$ + PGNScore + #DQUOTE$)
      
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
    
    ;PrintN("ParseAndClean proc: PGNDirtyGameScore = " + PGNDirtyGameScore)
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


Procedure PDFMove_Thread(null)
  
  ; This procedure exists because DrawVectorText doesn't work with PDF under Windows, (works fine under macos)! It therefore draws MOVE INFO for the game
  ; diagram onto a temporary image, and then that image is written to the PDF file in the main ExportGameToPDF procedure.
  ;
  ; It is also worth noting I used the thread mechanism for this procedure so I could "nest" StartVectorDrawing calls which ordinarily is also not allowed.
  
  If CreateImage(#ImageID_DemoBkgnd2, 100, 100,32,#White)    ; this code block "pre-draws" the move for its place under the diagram, DrawVectorText doesn't work with PDF under Windows!
      ; Start vector drawing on the image
      If StartVectorDrawing(ImageVectorOutput(#ImageID_DemoBkgnd2))
        ; Load a TrueType font (vector fonts only)
        LoadFont(0, "Helvetica", 12)
        VectorFont(FontID(0)) ; Set the font for vector drawing, with size in points
        ; Set the text color
        VectorSourceColor(RGBA(0, 0, 0, 255)) ;  black color
        MovePathCursor(5, 5)
        DrawVectorText( Str(pdf_halfmove/2) + ". " + Trim(GameScore_Plain_HalfMoves(pdf_halfmove-1),Space(1)) + Space(1) + GameScore_Plain_HalfMoves(pdf_halfmove))
        StopVectorDrawing()
      EndIf
    EndIf
  
  
EndProcedure


Procedure PDFAnalysis_Thread(null)
  
  ; This procedure exists because DrawVectorText doesn't work with PDF under Windows, (works fine under macos)! It therefore draws ANALYSIS INFO for the game
  ; diagram onto a temporary image, and then that image is written to the PDF file in the main ExportGameToPDF procedure.
  ;
  ; It is also worth noting I used the thread mechanism for this procedure so I could "nest" StartVectorDrawing calls which ordinarily is also not allowed.
  
  If CreateImage(#ImageID_DemoBkgnd3, 200, 300,32,#White)    ; this code block "pre-draws" the position ANALYSIS for its place under the diagram, DrawVectorText doesn't work with PDF under Windows!
    ; Start vector drawing on the image
    If StartVectorDrawing(ImageVectorOutput(#ImageID_DemoBkgnd3))
      ; Load a TrueType font (vector fonts only)
      LoadFont(0, "Helvetica", 12)
      VectorFont(FontID(0)) ; Set the font for vector drawing, with size in points
      ; Set the text color
      VectorSourceColor(RGBA(0, 0, 0, 255)) ;  black color
      MovePathCursor(#doc_offset, 0)
      DrawVectorText("[...engine analysis...]")
      MovePathCursor(0, #demo_y_offset*2)
      DrawVectorParagraph("pv = " + pvstring(1) + Space(2) + "eval = " + cpscore_str(1), 200, 200)
      
    EndIf
  EndIf
  
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
  Convert_UCI_Notation("")
  BoardDisPlay()
  ConstructFENfromPosition()
  Game_FEN_Positions(HalfMoveCount) = FENpositionstr
  PopulateMovesGadget()
  GameInfo = "Casual player versus engine game"

  UnbindEvent(#PB_Event_SizeWindow, @SizeHandlerFENEditorButtons()) ; Unbind it immediatel
  QuickEngine_Flag = #False
  
  
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
    
    CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
      PrintN("PM - HalfMoveCount = " + Str(HalfMoveCount))
    CompilerEndIf
    
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

  Protected BoardLetters1.s = "..bRbNbBbQbKbpwRwNwBwQwKwp"
  Protected BoardLetters2.s = "++bRbNbBbQbKbpwRwNwBwQwKwp"
  Protected rank.b, file.b
  Protected sumsqdigits.i
  
  If OutputID = 2 
    WriteStringN(FileID,"   ________________________" + Space(5) + black_enginename_glbl + #CRLF$) 
  Else
    Print("   ________________________") 
  EndIf
  For rank = 20 To 90 Step 10
    If OutputID = 1 : PrintN("") : Else : WriteString(FILEID,"") : EndIf
    For file = 1 To 8
      sumsqdigits = rank/10 + file
      If OutputID = 1 
        If file = 1 : Print(Str(10-rank/10)+" |") : EndIf
        If sumsqdigits % 2 > 0
          Print(Mid(BoardLetters1,MbxBrd(rank+file)*2+1,2) + Space(1))
        Else
          Print(Mid(BoardLetters2,MbxBrd(rank+file)*2+1,2) + Space(1))
        EndIf
        If file = 8 : Print("|") : EndIf
      Else
        If file = 1 : WriteString(FileID,Str(10-rank/10)+" |") : EndIf
        If sumsqdigits % 2 > 0
          WriteString(FileID, Mid(BoardLetters1,MbxBrd(rank+file)*2+1,2) + Space(1))
        Else
          WriteString(FileID, Mid(BoardLetters2,MbxBrd(rank+file)*2+1,2) + Space(1))
        EndIf
        If file = 8 : WriteString(FileID,"|") : EndIf
      EndIf
    Next
    If OutputID = 2 : WriteStringN(FileID,"") : EndIf
  Next
  If OutputID = 2 
    WriteStringN(FileID,"   ________________________" + Space(5) + white_enginename_glbl + #CRLF$)
    WriteStringN(FileID,Space(4) + "a  b  c  d  e  f  g  h")
  Else
    PrintN(#CRLF$ + "   ________________________" + #CRLF$)
    PrintN(Space(4) + "a  b  c  d  e  f  g  h")
  EndIf
  
  If OutputID = 1 : PrintN("") : PrintN("") : Else : WriteStringN(FileID,"") : WriteStringN(FileID,"") : EndIf

EndProcedure


Procedure Refresh_PlayersListIconGadget(Clean_Flag.b)
  
  Protected i.i
  
  ClearGadgetItems(#Players_ListIcon_Gadget)
  For i = 1 To GameCount-1
    SetupGameLinkForSearchSort(i)
    If Clean_flag = #True
      RemovePGNCommentsAndVariations2(FilePGNs(i))
      FilePGNs(i) = gamescore_result
    EndIf
    FEN_display_str_Set(i)
    AddGadgetItem(#Players_ListIcon_Gadget, -1, GameLink + Chr(10) + Trim(Left(WhitePlayers(i), G1_pos-1), " ") + " [" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + " [" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i) + Chr(10) + ECO_Game_Codes(i) + Chr(10) + FEN_display_str + Chr(10) + Left(FilePGNs(i),#pgnwidth))
    If i % 500 = 0
      SetGadgetText(#Info_Field, "...working...reloading GAME = #" + Str(i))
      While WindowEvent() : Wend
    EndIf
  Next
  SetGadgetText(#Info_Field, "All games with ECO codes now visible...Select a game above left...")
  While WindowEvent() : Wend
  
  
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
  
  gamescore_result = ""
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
  
  
  gamescore_result = Line
  While FindString(gamescore_result,Space(2)) > 0
   gamescore_result = ReplaceString(gamescore_result,Space(2),Space(1))
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


Procedure SendUCICommand(ProgramID, command.s)
  WriteProgramStringN(ProgramID, command)
  Debug ">> UCI Sent: " + command
EndProcedure


Procedure SacGamesFilter()

  Protected x.i, White.i = 1, Black.i = 2, sac_count.i = 0
  Protected GamescoreX.s, Index.i, GamePrefix_pos.i, GameLinkNo.i
  
  For Index = Sac_Game_Start_Index To GameCount-1
    
    ;PrintN("*********************************BlackPlayers(" + Str(Index) + ") = " + BlackPlayers(Index))
    GamePrefix_pos = FindString(BlackPlayers(Index), Game_Prefix, 1)
    GameLink = Mid(BlackPlayers(Index), GamePrefix_pos+2, 6)
    GameLinkNo = Val(GameLink)
    
    If Index >= 1 And Index <= GameCount-2
      GamescoreX = FilePGNs(GameLinkNo)
      GameScoreX = ParseAndCleanPGN(GamescoreX)
      ;PrintN("*********************************GameScore = " + GameScoreX)
      RemovePGNCommentsAndVariations2(GameScoreX)
      FilePGNs(GameLinkNo) = gamescore_result
      Parse_Save_GameScore_Bare_Halfmoves(FilePGNs(GameLinkNo))
      If FEN_setup_flag(GameLinkNo) = 0 
        BoardInitialize()
      Else
        ConstructPositionfromFEN(FEN_setup_str(GameLinkNo))
      EndIf
      HalfMoveCount = 1
      For x = 1 To #halfmove_max
        Capture_Flag_Array(x) = #False : Game_FEN_Positions(x) = ""
      Next
    EndIf
    
    ;PrintN("...Scanning game GameLink = " + GameLink)
    For x = 1 To TotalHalfMoves-1
      Convert_UCI_Notation(GameScore_UCI_HalfMoves(x))
      Total_Material(White) = 0 : Total_Material(Black) = 0
      Calculate_White_Black_Material()
      Display_Flag(GameLinkNo) = 0
      Select Each_Game_Result(GameLinkNo)
        Case Win1
          If x % 4 = 0 And Capture_Flag_Array(HalfMoveCount) = #False And Capture_Flag_Array(HalfMoveCount-1) = #False      ; Not a capture
            If Total_Material(Black) - Total_Material(White) >= Sac_Deficit_filter
              sac_count = sac_count + 1
              Display_Flag(GameLinkNo) = 1
              CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
                SetTextColorABGR(#Info_Field, $ff0000ff, 1, 100)
                PrintN("...SacFilter match GameLink = " + GameLink)
                PrintN("...White material = " + Str(Total_Material(White)) + "  Black material = " + Str(Total_Material(Black)))
              CompilerEndIf
              SetGadgetText(#Info_Field, "...SacFilter match GameLink = " + GameLink)
              While WindowEvent() : Wend
              Break
            EndIf
          EndIf
        Case Lose1
          If x % 6 = 0 And capture_flag = #False                       ; check only after both Black and White have moved, not a capture
            If Total_Material(White) - Total_Material(Black) >= Sac_Deficit_filter
              sac_count = sac_count + 1
              Display_Flag(GameLinkNo) = 1
              CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
                SetTextColorABGR(#Info_Field, $ff0000ff, 1, 100)
                PrintN("...SacFilter match GameLink = " + GameLink)
                PrintN("...White material = " + Str(Total_Material(White)) + "  Black material = " + Str(Total_Material(Black)))
              CompilerEndIf
              SetGadgetText(#Info_Field, "...SacFilter match GameLink = " + GameLink)
              While WindowEvent() : Wend
              Break
            EndIf
          EndIf
        Case Draw1
          Break
      EndSelect
    Next
  Next
  
  ClearGadgetItems(#Players_ListIcon_Gadget)
  For Index = Sac_Game_Start_Index To GameCount-1
    If Display_Flag(Index) = 1
      SetupGameLinkForSearchSort(Index)
      FEN_display_str_Set(Index)
      AddGadgetItem(#Players_ListIcon_Gadget, -1, GameLink + Chr(10) + Trim(Left(WhitePlayers(Index), G1_pos-1), " ") + " [" + WhiteElos(Index) + "]" + Chr(10) + Trim(Left(BlackPlayers(Index), G2_pos-1), " ") + " [" + BlackElos(Index) + "]" + Chr(10) + GameDates(Index) + Chr(10) + EventSites(Index) + Chr(10) + Each_Game_Result(Index) + Chr(10) + ECO_Game_Codes(Index) + Chr(10) + FEN_display_str + Chr(10) + Left(FilePGNs(Index),#pgnwidth))
    EndIf
  Next
  
  SetGadgetText(#Info_Field, "...All games have been scanned. Games matching the Sac Filter criteria of " + Str(Sac_Deficit_filter) + " pawn units = " + Str(sac_count) + ". When finished viewing sac games, use the '*' (asterisk) command under search options to reset all games to visible.")

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
      WhiteKing_Button_Flag = 1
    Case #Btn_wp40
      Mailbox_editor_piece = Wpawn : PrintN("You Clicked: " + "White pawn")
    Case #Btn_es32
      Mailbox_editor_piece = _emptysq : PrintN("You Clicked: " + "Empty square")
      EmptySq_Button_Flag = 1
      PrintN("Select Proc: EmptySq_Button_Flag = " + Str(EmptySq_Button_Flag))
      EmptySq_Button_Click_Count = EmptySq_Button_Click_Count + 1
      If EmptySq_Button_Click_Count >= 5 And WhiteKing_Button_Flag = 1
        PrintN("You clicked on the white king once and the empty-square-button at least five times, unhiding magic S sample data creator button!")
        Help_accessed_flag = 0
        HideGadget(#Btn_SampleData, 0)                            ; show the Sample games data creator magic button
        HideGadget(#Btn_GSTest,0)
      EndIf
    Case #Btn_done40
      Counter = 99
    Default
            ; do nothing now
  EndSelect
  
EndProcedure


Procedure Searching_Sorting()

  Protected i.i, j.i, player_result1.i, player_result2.i, whitepl.s, blackpl.s, Move_Sequence.s
  Protected gpfx_pos.i, rowitem.s, chr10_pos.i, lb_pos.i, GameNo.i, matchcount.i, last_match.i
  ReDim Gadget_List_Display.s(GameCount-1)
  ReDim Gadget_List_Display2.s(GameCount-1)
  ReDim Sorted_FilePGNs.s(GameCount-1)
  ReDim Sorted_ECOs.s(GameCount-1)
  
  player_result1 = 0 : player_result2 = 0
  SetGadgetText(#Info_Field,"Enter full/partial player name to search, asterisk (*) for all games visible, *sort to sort all, *movesort for gamescore moves sort, *ecosort for game ECOs sort ,*moves=1. e4 e5 2. Nf3 Nc6 etc. for move sequence search.")
  Search_player = InputRequester("Search for player name", "Enter full or partial player name to search, asterisk (*) to make all games visible, *sort to sort all," + #LF$ + "*movesort For gamescore moves sort, *ecosort For game ECOs sort ,*moves=1. e4 e5 2. Nf3 Nc6 etc. For move sequence search:", "Carlsen")
  ClearGadgetItems(#Players_ListIcon_Gadget)
  If Search_player = "*" Or Search_player = "*all"
    Refresh_PlayersListIconGadget(#True)
    SetGadgetText(#Info_Field, "All games now visible...Select a game above left...")
    While WindowEvent() : Wend
  ElseIf  Search_player = "*sort"
    For i = 1 To GameCount-1
      SetupGameLinkForSearchSort(i)
      FEN_display_str_Set(i)
      Gadget_List_Display(i) = GameLink + Chr(10) + Trim(Left(WhitePlayers(i), G1_pos-1), " ") + " [" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + " [" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i) + Chr(10) + FEN_display_str + Chr(10) + Left(FilePGNs(i),#pgnwidth)
      Gadget_List_Display2(i) = Trim(WhitePlayers(i), " ") + " [" + WhiteElos(i) + "]" + Chr(10) + Trim(BlackPlayers(i), " ") + " [" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i) + Chr(10) + FEN_display_str + Chr(10) + Left(FilePGNs(i),#pgnwidth)
    Next
    SortArray(Gadget_List_Display2(),#PB_Sort_Ascending)
    PrintN("")
    For i = 1 To GameCount-1
      ;PrintN("Sorted List row = " + Gadget_List_Display2(i))
      Gpfx_pos = FindString(Gadget_List_Display2(i), Game_Prefix, 1)
      lb_pos = FindString(Gadget_List_Display2(i), "[", 1)
      GameLink = Game_Prefix + Trim(Mid(Gadget_List_Display2(i), Gpfx_pos+2, lb_pos-(gpfx_pos+2)),Space(1))
      GameNo = Val(Mid(GameLink,3,6))
      ;PrintN("GameLink = " + "xxx" + GameLink + "xxx")
      whitepl = Trim(ReplaceString(WhitePlayers(GameNo),GameLink,""),Space(1)) + " [" + WhiteElos(GameNo) + "]"
      blackpl = Trim(ReplaceString(BlackPlayers(GameNo),GameLink,""),Space(1)) + " [" + BlackElos(GameNo) + "]"
      FEN_display_str = FEN_setup_str(GameNo)
      If Trim(FEN_display_str,Space(1)) = ""
        FEN_display_str = FEN_Start_Position
      EndIf
      rowitem = GameLink + Chr(10) + whitepl + Chr(10) + blackpl + Chr(10) + GameDates(GameNo) + Chr(10) + EventSites(GameNo) + Chr(10) + Each_Game_Result(GameNo) + Chr(10) + ECO_Game_Codes(GameNo) + Chr(10) + FEN_display_str + Chr(10) + Left(FilePGNs(GameNo),#pgnwidth)
      AddGadgetItem(#Players_ListIcon_Gadget, -1, rowitem)
    Next
  ElseIf  Search_player = "*movesort" 
    For i = 1 To GameCount-1
      GameLink = Game_Prefix + Str(i)
      Sorted_FilePGNs(i) = Left(FilePGNs(i),300) + Space(3) + GameLink
      SpacifyNoSpaceGamescoreLine(Sorted_FilePGNs(i))
      ;PrintN("UnSorted PGNs = " + Sorted_FilePGNs(i))
      Gadget_List_Display(i) = GameLink + Chr(10) + Trim(Left(WhitePlayers(i), G1_pos-1), " ") + " [" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + " [" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i) + Chr(10) + FEN_display_str + Chr(10) + Left(FilePGNs(i),#pgnwidth)
    Next
    SortArray(Sorted_FilePGNs(),#PB_Sort_Ascending)
    ;PrintN("") : For i = 1 To GameCount-1 : PrintN("Sorted List row = " + Sorted_FilePGNs(i)) : Next
    For i = 1 To GameCount-1
      ;PrintN("List row = " + Sorted_FilePGNs(i))
      Gpfx_pos = FindString(Sorted_FilePGNs(i), Game_Prefix, 1)
      GameLink = Game_Prefix + Trim(Mid(Sorted_FilePGNs(i), Gpfx_pos+2,6),Space(1))
      GameNo = Val(Mid(GameLink,3,6))
      ;PrintN("GameLink = " + "xxx" + GameLink + "xxx  GameNo = " + Str(GameNo))
      whitepl = Left(WhitePlayers(GameNo),FindString(WhitePlayers(GameNo),Game_Prefix)-1) + " [" + WhiteElos(GameNo) + "]"
      blackpl = Left(BlackPlayers(GameNo),FindString(BlackPlayers(GameNo),Game_Prefix)-1) + " [" + BlackElos(GameNo) + "]"
      FEN_display_str = FEN_setup_str(GameNo)
      If Trim(FEN_display_str,Space(1)) = ""
        FEN_display_str = FEN_Start_Position
      EndIf
      rowitem = GameLink + Chr(10) + whitepl + Chr(10) + blackpl + Chr(10) + GameDates(GameNo) + Chr(10) + EventSites(GameNo) + Chr(10) + Each_Game_Result(GameNo) + Chr(10) + ECO_Game_Codes(GameNo) + Chr(10) + FEN_display_str + Chr(10) + Left(FilePGNs(GameNo),#pgnwidth)
      AddGadgetItem(#Players_ListIcon_Gadget, -1, rowitem)
    Next
    ElseIf  Search_player = "*ecosort" 
    For i = 1 To GameCount-1
      GameLink = Game_Prefix + Str(i)
      Sorted_ECOs(i) = ECO_Game_Codes(i) + Space(4) + GameLink + Space(5) + Left(FilePGNs(i),300)
      ;PrintN("UnSorted PGNs = " + Sorted_FilePGNs(i))
      Gadget_List_Display(i) = GameLink + Chr(10) + Trim(Left(WhitePlayers(i), G1_pos-1), " ") + " [" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + " [" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i) + Chr(10) + ECO_Game_Codes(i) + Chr(10) + FEN_display_str + Chr(10) + Left(FilePGNs(i),#pgnwidth)
    Next
    SortArray(Sorted_ECOs(),#PB_Sort_Ascending)
    ;PrintN("") : For i = 1 To GameCount-1 : PrintN("Sorted List row = " + Sorted_FilePGNs(i)) : Next
    For i = 1 To GameCount-1
      ;PrintN("List row = " + Sorted_FilePGNs(i))
      Gpfx_pos = FindString(Sorted_ECOs(i), Game_Prefix, 1)
      GameLink = Game_Prefix + Trim(Mid(Sorted_ECOs(i), Gpfx_pos+2,6),Space(1))
      GameNo = Val(Mid(GameLink,3,6))
      ;PrintN("GameLink = " + "xxx" + GameLink + "xxx  GameNo = " + Str(GameNo))
      whitepl = Left(WhitePlayers(GameNo),FindString(WhitePlayers(GameNo),Game_Prefix)-1) + " [" + WhiteElos(GameNo) + "]"
      blackpl = Left(BlackPlayers(GameNo),FindString(BlackPlayers(GameNo),Game_Prefix)-1) + " [" + BlackElos(GameNo) + "]"
      FEN_display_str = FEN_setup_str(GameNo)
      If Trim(FEN_display_str,Space(1)) = ""
        FEN_display_str = FEN_Start_Position
      EndIf
      rowitem = GameLink + Chr(10) + whitepl + Chr(10) + blackpl + Chr(10) + GameDates(GameNo) + Chr(10) + EventSites(GameNo) + Chr(10) + Each_Game_Result(GameNo) + Chr(10) + ECO_Game_Codes(GameNo) + Chr(10) + FEN_display_str + Chr(10) + Left(FilePGNs(GameNo),#pgnwidth)
      AddGadgetItem(#Players_ListIcon_Gadget, -1, rowitem)
    Next
  ElseIf Left(Search_player,7) = "*moves="
    Move_Sequence = Mid(Search_player,8,200)
    Move_Sequence = ReplaceString(Move_Sequence,Space(1),"")
    matchcount = 0 : last_match = 0
    For i = 1 To GameCount-1
      If FindString(ReplaceString(FilePGNs(i),Space(1),""), Move_Sequence, 1) > 0
        matchcount = matchcount + 1
        Display_flag(i) = 1
        CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
          PrintN("...found a move sequence match...i = " + Str(i))
        CompilerEndIf
      Else
        Display_flag(i) = 0
      EndIf
      If Display_Flag(i) = 1
        SetupGameLinkForSearchSort(i)
        FEN_display_str_Set(i)
        AddGadgetItem(#Players_ListIcon_Gadget, -1, GameLink + Chr(10) + Trim(Left(WhitePlayers(i), G1_pos-1), " ") + " [" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + " [" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i) + Chr(10) + ECO_Game_Codes(i) + Chr(10) + FEN_display_str + Chr(10) + Left(FilePGNs(i),#pgnwidth))
        SetGadgetText(#Info_Field, "...searching..." + "Found a move sequence match: Game #" + Str(i))
        last_match = i
        Delay(30)
        While WindowEvent() : Wend
      EndIf
    Next
    If last_match > 0
      SetGadgetText(#Info_Field, "Found a move sequence match: Game #" + Str(last_match) + ". Total matched games = " + Str(matchcount))
      While WindowEvent() : Wend
    EndIf
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
        FEN_display_str_Set(i)
        AddGadgetItem(#Players_ListIcon_Gadget, -1, GameLink + Chr(10) + Trim(Left(WhitePlayers(i), G1_pos-1), " ") + " [" + WhiteElos(i) + "]" + Chr(10) + Trim(Left(BlackPlayers(i), G2_pos-1), " ") + " [" + BlackElos(i) + "]" + Chr(10) + GameDates(i) + Chr(10) + EventSites(i) + Chr(10) + Each_Game_Result(i) + Chr(10) + ECO_Game_Codes(i) + Chr(10) + FEN_display_str + Chr(10) + Left(FilePGNs(i),#pgnwidth))
      EndIf
    Next
  EndIf
  BoardInitialize()
  BoardDisplay()
  SetGadgetText(#Single_Move_Gadget, " ")
  ;Delay(2000)
  ;SetGadgetText(#Info_Field, "...Select a game above left...")

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
        
        ResizeGadget(#Btn_HelpInfo, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-(#InfoFieldDefaultY+50)), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#DbFile_Gadget, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#fileinfogadgetDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_Fen, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#FENBtnDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_BoardSize, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#FENBtnDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_ExportGame, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#FENBtnDefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Single_Move_Gadget, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#Single_MoveDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_CleanPGN, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#Single_MoveDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_ExportPDF, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#Single_MoveDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Info_Field, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#InfoFieldDefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Btn_Prev, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#prevbtnDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_Automove, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#prevbtnDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_SacFilter, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#prevbtnDefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Btn_Next, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#nextbtnDefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Btn_Db1, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#dbbtn1DefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_ECOCodes, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#dbbtn1DefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_Db2, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#dbbtn2DefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Btn_SFAnaly, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#sfbtnDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_SF10sec, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#sfbtn10secDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_UpdSF, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#dbbtn2DefaultY), #PB_Ignore, #PB_Ignore)
        
        ResizeGadget(#Btn_PlayvsSF, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#sfbtn10secDefaultY), #PB_Ignore, #PB_Ignore)
        ResizeGadget(#Btn_EngineMatch, #PB_Ignore, WindowHeight(#mainwin)-(#mainwinDefaultHeight-#PSearchbtnDefaultY), #PB_Ignore, #PB_Ignore)
        
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
  ;Delay(10)
  
  If IsProgram(ProgramID) And ProgramRunning(ProgramID)
    PrintN("...killing and closing Engine...progID = " + Str(ProgramID))
    KillProgram(ProgramID)
    CloseProgram(ProgramID)
  EndIf

  
  Engine_Running_Flag = #False
  If QuickEngine_Flag = #False And pvstring(2) <> ""
    SetGadgetText(#Info_Field, "...engine...pv1 = " + pvstring(1) + Space(2) + " score: " + cpscore_str(1) + #CRLF$ + "pv2 = " + pvstring(2) + Space(2) + " score: " + cpscore_str(2))
  Else
    If pvstring(1) <> ""
      SetGadgetText(#Info_Field, "...engine...pv1 = " + pvstring(1) + Space(2) + " score: " + cpscore_str(1) + #CRLF$)
    EndIf
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




; ***************************************************** main program  ***********************************

OpenConsole("PBConsole")

BoardInitialize()
BuildValidQueenMovesTable()
Load_ECO_Table()
;LoadHelpData()
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
  zPattern = 0    ; use the first of the three possible patterns as standard
  DB_InputFile = OpenFileRequester(RequesterTitle, #StandardFile, FilePattern, zPattern, #PB_Requester_MultiSelection)
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

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  IncludeFile "/Users/kenpchess/Public/16ply_openings_20000_spaces.pb"
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  IncludeFile "C:\PureBasic\16ply_openings_20000_spaces.pb"
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  IncludeFile "/Users/kenpchess/Public/PGNdbkp_samplegames.pb"
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  IncludeFile "C:\PureBasic\PGNdbkp_samplegames.pb"
CompilerEndIf


DataSection
  HelpData:
  
  Data.s "										PGNdbkp Help, Features and Information"
  Data.s " "
  Data.s "GENERAL FEATURES INFORMATION:"
  Data.s " "
  Data.s "1. Reads most SAN or UCI PGN gamefiles. It attempts To remove all comments And variations, although Not 100% perfect. See [OPENING FILES] information. Also see the [CLEANPGN] button info. Also see [FILESIZE LIMITS] information."
  Data.s " "
  Data.s "2. Reads And writes an SQLite database file of its' own simple format. Allows game export (all games or current game) to SQLite database file. See [OPENING FILES] information."
  Data.s " "
  Data.s "3. Allows the current game or a range of games To be exported To a PGN gamefile textfile, including ascii diagrams And engine analysis. See [EXPORTGAMESs] information."
  Data.s " "
  Data.s "4. Allows the current game or a range of games To be exported To a PDF file(s) With graphic board diagrams (smaller version of PGNdbkp's on-screen chessboard) and engine analysis. These are essentially make-your-own PDF chessbooks (only partially working under Windows, still a work in progress!). Note that each analyzed game will be output to a separate pdf file. See [EXPORTTOPDF]"
  Data.s " "
  Data.s "5. Stockfish or UCI engine interaction. Allows chess engine to analyze moves or positions. The default engine location is updatable. On MacOs make sure you have your 'Security Preferences' set To allow Stockfish To run. (MacOs blocks most 'outsider' downloads like Stockfish Until you tell it otherwise). See [SF ANALY] button information."
  Data.s " "
  Data.s "6. Allows play directly against Stockfish or another UCI engine. See [PLAY ENGINE] button information."
  Data.s " "
  Data.s "7. Player/moves search/sort options to sort all games, search for the games of a specific player, sort by ECO code, or search for specific move sequences such as '1. e4 e5 2. Nf3 Nc6 3. Bc4' Or even iconic sacrifice moves such As simply Bxh7+. See [SEARCHING/SORTING] button information. Also see [ECO CODES] button information."
  Data.s " "
  Data.s "8. Basic FEN position GUI chessboard editor. Utilizes point-and-click GUI to edit games or setup positions. FEN starting positions (if any) can now also be viewed by right-scrolling in the games window. See [SHOW FEN] and [FEN EDITOR] button information."
  Data.s " "
  Data.s "9. Board size option for small or medium-size chessboard. See [BOARDSIZE] button information."
  Data.s " "
  Data.s "10. GUI allows main window resizing (limited) and allows using arrow-keys and shift-arrow-keys for move traversal. You may also use the 'automove' button To automatically replay the entire game [press the escape-key For about two seconds To halt 'automove' replay]. You may right-scroll in the games window To view all raw movelists And any FENs. See the [<MOVE], [>MOVE], [AUTOMOVE], [ARROW-KEYS], And [WINDOW-RESIZING] buttons And options For more information."
  Data.s " "
  Data.s "11. There are a few 'Easter Egg' features If you look at the source code. One such feature is If you choose 'cancel' at the file-open dialog instead of selecting a PGN file, you will be presented With some nice built-in sample chess games To view (currently about 1800 games). See [SAMPLE-GAMES] option information."
  Data.s " "
  Data.s " "
  Data.s "GUI AND BUTTON-SPECIFIC INFORMATION:"
  Data.s " "
  Data.s " "
  Data.s "[OPENING FILES] - PGNdbkp opens PGN notation chess gamescore files with the '.pgn' file extension. It will attempt to remove variations and comments. If you have a specific PGN file that cannot be read by PGNdbkp, my suggestion is obtain a copy of the excellent PGN-EXTRACT utility (https://github.com/kentdjb/pgn-extract/ or https://www.cs.kent.ac.uk/people/staff/djb/pgn-extract/) and use it to 'clean' the PGN file, such as: pgn-extract -C -V input.pgn --output cleaned.pgn. PGNdbkp also opens it's own-format SQLITE files with the extensions '.sqlite' or '.db3'. Currently the PGN filesize is set to 200,000 games althougth that can be changed in the PureBasic source code with the #game_max constant. When the file-open dialog presents itself upon program open, you may select [CANCEL] and PGNdbkp will simply display built-in sample games (currently about 1800), in the players and games scrolling gadget window."
  Data.s " "
  Data.s "[RESIZING MAIN WINDOW] - You may resize the main window of PGNdbkp (vertically) to a limited degree. Simply drag and stretch or drag and reduce the window as you would with any normal application. In PGNdbkp this will primarily stretch or reduce the players-games scrolling gadget and the moves scrolling gadget to better fit your monitor size."
  Data.s " "
  Data.s "[SHOW FEN] - This button when pressed simply shows the current game position in Forsythe-Edwards Notation."
  Data.s " "
  Data.s "[BOARDSIZE] - This button when pressed toggles between the default medium-sized board with 60-pixel squares and the small board with 40-pixel squares. One advantage of using the small board is to also use the click-and-drag vertical resize option to allow the program window to fit on a smaller screensize."
  Data.s " "
  Data.s "[EXPORTGAMEs] - This button when pressed starts the PGN game output process by asking for input in the following form: 'Export this game [xx] Or Range of games [xx-xx] (With/wo engine analysis) (With/wo diagrams)?'. You might answer for example: '[10-20] /engine/diagram:10'. The preceding response will produce a PGN output file With games 10-20 including engine analysis evaluations And diagrams every 10 halfmoves (every 5 moves)."
  Data.s " "
  Data.s "[EXPORTTOPDF] - This button when pressed is identical to [EXPORTGAMESs] except that the output will be to a PDF file with graphic chessboards identical (but smaller) to the on-screen chessboard. This option essentially creates a mini-PDF chessbook. Note this option works quite well under the MacOs operating system but is a work-in-process under the Microsoft Windows operating system."
  Data.s " "
  Data.s "[CLEANPGN] - This button when pressed will attempt to clean or remove extraneous info/characters from the PGN gamescore. The gamescores are normally only fully cleaned when you select one in the gamelist/players gadget window. This option can be useful to view clean PGN gamescores at any time when you right-scroll in the gamelist/players gadget window. Note that this option can take quite some time on large PGN files. See mini-screenshot below right of scrolling right in PGNdbkp."
  Data.s " "
  Data.s "[<MOVE] and [>MOVE] and [AUTOMOVE] - These buttons when pressed control the game replay for the on-screen chessboard. They make the moves in the forwards and backwards (takeback) directions. AUTOMOVE replays the entire game in the forward direction. Note that PGNdbkp also supports the <left and right arrow-keys> on the keyboard to mimic these buttons. You may also use the <shift-arrow-keys> to move through the game five moves at a time, forward or backward."
  Data.s " "
  Data.s "[SAC FILTER] - This button when pressed filters the games list for games with sacrifices according to a specified amount in pawn units (1-9)."
  Data.s " "
  Data.s "[GAME TO DB] and [ALL GAMES TO DB] - These buttons when pressed export the current game or all games to an sqlite database format specific to PGNdbkp. It is a simple format consisting of one table as follows:"
  Data.s " "
  Data.s "TABLE pgngames ("
  Data.s "gameid INTEGER PRIMARY KEY," 
  Data.s "event TEXT," 
  Data.s "gamedate TEXT,"
  Data.s "player1 TEXT," 
  Data.s "ELO1 TEXT," 
  Data.s "player2 TEXT,"
  Data.s "ELO2 TEXT," 
  Data.s "startingFEN TEXT," 
  Data.s "gameresult TEXT," 
  Data.s "ECO TEXT," 
  Data.s "ucimoves TEXT)"
  Data.s " "
  Data.s "PGNdbkp can of course reopen and use as input this created sqlite database or you can open it with your favorite sqlite database tool. When using PGNdbkp, you may add games to an existing sqlite database or if the database does not exist, PGNdbkp will create a new one with the supplied name according to the table structure above and then add the games to the new database."
  Data.s " "
  Data.s "[ECO CODES] - ECO codes are the widely-used standard opening-classification codes created by the also widely-read Chess Informant publications. This button will compare each game to the ECO codes table and populate the ECO codes column for any games missing an ECO code. Note that PGNdbkp supports the ECO tag in pgn files and will automatically read it if it already exists in each gamescore. See the source file 'eco_name_pgn_fen.pb' in this github repository for the ECO table and more information on ECO codes."
  Data.s " "
  Data.s "[UPDATE ENGINES] - This button will update the internal location for the Stockfish (or any UCI-compliant) analysis engine. It will also allow you to set the location for additional engines for the '[ENGINE MATCH]' feature using a simple 'engines_list.txt' file(see below). For MacOs the stockfish location is often '/usr/local/bin/stockfish' or '/usr/local/bin/engineXX'. For Microsoft Windows you might use 'C:\PureBasic\stockfish.exe' or any suitable location of your choice."
  Data.s " "
  Data.s "[SF ANALY] and [SF 10sec] - These buttons simply call Stockfish (or whatever UCI engine you designated with the [UPDATE ENGINE] option to analyze the current board position. The [SF ANALY] button performs a default 1-second single-PV analysis of the current position. The [SF 10sec] button performs a 10-second double-PV analysis of the current position."
  Data.s " "
  Data.s "[PLAYVSENGINE] - This button allows you to play directly against the designated 'built-in' engine by utilizing some functions of the [FEN EDITOR] option. When pressing this button you will be presented with the [FEN EDITOR] screen so that you can choose your move with the 'point-and-click' style of the [FEN EITOR]. After you make your move the 'built-in' engine (see above) will automatically analyze the position for 1 second and make an engine move. You should then AGAIN press the [PLAYVSENGINE] button to make your next move. The [PLAYVSENGINE] option makes the most 'sense' when you first start PGNdbkp and have NOT chosen a game to view, but you can actually utilize it at any point during a gameview to 'takeover' a viewed game."
  Data.s " "
  Data.s "[SEARCHING/SORTING] - This button is the interface to all of the searching and sorting options. Upon pressing this button you are given the short and to-the-point command responses that you can give to initiate the various searching/sorting options. This button options preview is as follows:"
  Data.s " "
  Data.s "'Enter full or partial player name to search, asterisk (*) to make all games visible, *sort to sort all, *movesort for gamescore moves sort, *ecosort for game ECOs sort ,*moves=1. e4 e5 2. Nf3 Nc6 etc. for move sequence search'."
  Data.s " "
  Data.s "The first option is fairly self-explanatory. You may enter a full or partial name For searching, i.e. 'Carlsen, Magnus', or simply 'Carl', etc."
  Data.s "The second option is a lone '*' or asterisk, which is like a reset. It will retrieve all original games And place them back into the players/games gadget window. This is particularly useful after a previous search or sort, etc. It also has the additional benefit that it will 'lightly clean' all of the pgn gamescores from the current file."
  Data.s "The third option,'*sort', is also fairly self-explanatory. It will sort the ENTIRE file top-To-bottom, alphabetically on the players names."
  Data.s "The fourth option, '*movesort', will also sort the ENTIRE file top-To-bottom, but on the gamescores PGN movelists, once again alphabetically."
  Data.s "The fifth option, '*ecosort', will also sort the ENTIRE file top-To-bottom, but this time on the 'ECO' codes column."
  Data.s "The sixth and last option, '*moves=1. e4 e5 2. Nf3 Nc6', is a search feature that will search And match all games that contain the move sequence specified in your response."
  Data.s " "
  Data.s "[ENGINE MATCH] - This button invokes the engines match feature (currently up to 16 engines per round-robin match, gauntlet also available). There are 20,000 built-in opening lines. Update (or add) the additional UCI engines with the '[UPDATE ENGINES]' button above. The engines match is currently limited to 56 games per round (8 engines round-robin white and black games) * the number of opening lines used. Therefore a 50-openings round-robin tourney with 4 engines would total 600 games. Invoke the match feature for more information."
  Data.s " "
  Data.s "[FEN EDITOR] - This button invokes the point-and-click FEN position editor. When pressed this option displays all piece types (plus an empty square) so that you may setup a board position by simply clicking on a piece and then clicking on a board square to place that piece on the square. You can also click on the 'empty-square' button icon and then click on as many board squares as necessary to empty or 'blank-out' those squares. When done creating the board position, click on the 'Exit Editor' button to finish. At that point, you will be asked to enter any demographic information about the position (players, etc.) and whether you wish to save this FEN setup position to the gamelist. Note that there is an 'Easter Egg' (semi-hidden option) or two in the [FEN EDITOR] options if you read the prompts carefully! Also see mini-screenshot of FEN Editor below left."
  Data.s " "
  Data.s "                                                                                            END-OF-HELP                               "
  
EndDataSection
; IDE Options = PureBasic 6.21 - C Backend (MacOS X - x64)
; CursorPosition = 133
; FirstLine = 130
; Folding = --------------------------------------
; EnableThread
; EnableXP
; DPIAware
; Executable = PGNdbkp_20260111.app
