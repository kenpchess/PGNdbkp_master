; ======================================================================
;
; File:      a PureBasic complete rewrite of Minimax by kenpchess
; Authors:   originally from D. Steinwender, Ch. Donninger, May 1, 1995
; and a FreeBASIC adaptation from S. Budinov
; and a CECP protocol implementation from R. Chastain
;
; ======================================================================
;
; Authors:   modified by kenpchess (new movegen, new PST-based eval, zobrist history, parse FEN positions, some king safety, minimal time management, tt data structures, more misc.
; also converted to PureBasic 2026.)
; Date:      Sept 10, 2021
; Version    1.18tt_pb
;
EnableExplicit

Global Program_Name.s = "Minimaxkp_20260515"
Declare AlphaBetaX(AAlpha.w, ABeta.w, Distance.w)
Declare AssessPosition(AAlpha.w, ABeta.w, Side.w)
Declare Board_Print_Routine()

Declare CommandLoop()
Declare ComputerMove()
Declare CopyMainVariant(CurrMove.w)
Declare ConstructNonZobristBoardStrings(Z.w)
Declare ConstructZobristPositionKey(ZobristSideToMove.w)
Declare CountKingEscapeSquares()
Declare ConstructFENfromPosition(ColorOnMove.w)
Declare ConstructPositionfromFEN()

Declare DisplayBoard()
Declare DisplayMove(CurrMove.w)

Declare Evaluate_Position_With_PSTs()
Declare EvaluateKingSafety(KingLocSqr.w)

Declare FieldNotation(AField.w)
Declare FieldNumber(AField.s)

Declare Initialize()
Declare InitGameTree()
Declare InputMove(Move.s)

Declare GeneratePawnMoves(AllMoves.w)
Declare GeneratePseudoLegalMovesFromTables(AllMoves.w)
Declare GeneratePieceMoves(AllMoves.w)

Declare LookupPositionInTT(ZobristPositionKey.q)
Declare NextBestMove()

Declare PseudoLegalMove_IsLegal(AFrom.w, ATo.w, Side.w)
Declare PerformMove(CurrMove.w)

Declare ResetBoardToInitialPosition()
Declare SaveQuietMove(AFrom.w, ATo.w)
Declare SaveQuietCastleMove(AFrom.w, ATo.w)
Declare SaveCaptureMove(AFrom.w, ATo.w)
Declare SaveEnPassantMove(AFrom.w, ATo.w, AEP.w)
Declare SavePromotionMove(AFrom.w, ATo.w)
Declare SendLog(Amessage.s)
Declare SquareIsAttacked(TargetSq.w, Side.w, FullCountFlag.w)
Declare StoreZobristTTEntry(ZobristPositionKey.q, TpFromSq.b, TpToSq.b, ZEval.w, ZDepth.b, EvalTypeFlag.b, ZAlpha.w, ZBeta.w )
Declare TimerCheck()
Declare UndoMove(CurrMove.w)


#CBoardDim = 119
#CMoveDirections = 15
#PieceTypes = 6
#CMoveStackDim = 2000
#EarlyGameMoveNumberCutoff1 = 12

#nil = 0 : #Edge = 100 


Enumeration B_Pieces
  #BK = -6 : #BQ = -5 : #BN = -4 : #BB = -3 : #BR = -2 : #BP = -1
EndEnumeration

Enumeration W_Pieces
  #WK = 6 : #WQ = 5 : #WN = 4 : #WB = 3 : #WR = 2 : #WP = 1
EndEnumeration

Enumeration Material_Values
  #MatP = 100 : #MatR = 500 : #MatB = 375 : #MatN = 350 : #MatQ = 900 : #MatK = 0
EndEnumeration


#MateValue = 32000
#MaxPos = #MatB
#MainVariantBonus = 500
#Killer1Bonus = 250
#Killer2Bonus = 150
#MaterialSum = 4 * (#MatR + #MatB + #MatN) + (2 * #MatQ)
#EndgameMaterial = 4 * #MatR + 2 * #MatB
#SparseEndgameMaterial = 2 * #MatR + 2 * #MatB + 5 * #MatP
#MiddleGameMaterial1 = 2 * #MatR + 3 * #MatB + 3*#MatN + 8 * #MatP
#KingRingSqrAttackedPenalty = 30
#QueenIsKingRingAttackerPenalty = 50
#KingRingSqrDefendedBonus = 25
#KingRingSqrPawnBonus = 15
#DoubledPawnPenalty = 25
#BackRankWeakPenalty = 60
#PassedPawnBonus = 52
#CastlingBonus = 25
#EarlyKingMovePenalty = 100
#PlyExtensionLarge = 3
#PlyExtensionMinimal = 1


; MailBox Board squares layout looks like -

;110 111 112 113 114 115 116 117 118 119
;100 101 102 103 104 105 106 107 108 109
; 90  A8  B8  C8  D8  E8  F8  G8  H8  99
; 80  A7  B7  C7  D7  E7  F7  G7  H7  89
; 70  A6  B6  C6  D6  E6  F6  G6  H6  79
; 60  A5  B5  C5  D5  E5  F5  G5  H5  69
; 50  A4  B4  C4  D4  E4  F4  G4  H4  59
; 40  A3  B3  C3  D3  E3  F3  G3  H3  49
; 30  A2  B2  C2  D2  E2  F2  G2  H2  39
; 20  A1  B1  C1  D1  E1  F1  G1  H1  29
; 10  11  12  13  14  15  16  17  18  19
; O0  01  02  03  04  05  06  07  08  09 


Enumeration Board_Squares

      #A8 = 91 :  #B8 = 92 :  #C8 = 93 :  #D8 = 94 :  #E8 = 95 :  #F8 = 96 :  #G8 = 97 :  #H8 = 98
      #A7 = 81 :  #B7 = 82 :  #C7 = 83 :  #D7 = 84 :  #E7 = 85 :  #F7 = 86 :  #G7 = 87 :  #H7 = 88
      #A6 = 71 :  #B6 = 72 :  #C6 = 73 :  #D6 = 74 :  #E6 = 75 :  #F6 = 76 :  #G6 = 77 :  #H6 = 78
      #A5 = 61 :  #B5 = 62 :  #C5 = 63 :  #D5 = 64 :  #E5 = 65 :  #F5 = 66 :  #G5 = 67 :  #H5 = 68
      #A4 = 51 :  #B4 = 52 :  #C4 = 53 :  #D4 = 54 :  #E4 = 55 :  #F4 = 56 :  #G4 = 57 :  #H4 = 58
      #A3 = 41 :  #B3 = 42 :  #C3 = 43 :  #D3 = 44 :  #E3 = 45 :  #F3 = 46 :  #G3 = 47 :  #H3 = 48
      #A2 = 31 :  #B2 = 32 :  #C2 = 33 :  #D2 = 34 :  #E2 = 35 :  #F2 = 36 :  #G2 = 37 :  #H2 = 38
      #a1 = 21 :  #B1 = 22 :  #C1 = 23 :  #D1 = 24 :  #E1 = 25 :  #F1 = 26 :  #G1 = 27 :  #H1 = 28

EndEnumeration



Enumeration The_Rows
  #Arow = 1 : #BRow = 2 : #CRow = 3 : #DRow = 4 : #ERow = 5 : #FRow = 6 : #GRow = 7 : #HRow = 8
EndEnumeration

Enumeration The_Columns
  #Column1 = 2 : #Column2 = 3 : #Column3 = 4 : #Column4 = 5 : #Column5 = 6 : #Column6 = 7 : #Column7 = 8 : #Column8 = 9
EndEnumeration


Enumeration Movegen_Constants

  #No_of_Rook_Dirs = 4 : #No_of_Bishop_Dirs = 4 : #No_of_King_Dirs = 8 : #No_of_Knight_Dirs = 8 : #No_of_WP_Dirs = 4 : #No_of_BP_Dirs = 4
  #No_of_TravelSqs = 7 : #Max_Travel_Sqs = 7 : #EdgeSq = 100
  #King = 6 : #Queen = 5 : #Knight = 4 : #Bishop = 3 : #Rook = 2 : #Pawn = 1
  #Max_Move_Dirs = 8 : #QuietPromoFlag = 1 : #CapturePromoFlag = 2 : #EmptySq = 0 : #JustMovedEPFlag = 1
  #NoCastlingMove = 0 : #ShortCastlingMove = 1 : #LongCastlingMove = 2
  #CMaxDepth = 21

EndEnumeration

Enumeration Rook_Directions
  #Rook_North = 10
  #Rook_South = -10
  #Rook_East = 1
  #Rook_West = -1
EndEnumeration

Enumeration Bishop_Directions
  #Bishop_NW = 9
  #Bishop_NE = 11
  #Bishop_SW = -11
  #Bishop_SE = -9
EndEnumeration

Enumeration King_Directions
  #King_North = #Rook_North
  #King_South = #Rook_South
  #King_East = #Rook_East
  #King_West = #Rook_West

  #King_NW = #Bishop_NW
  #King_NE = #Bishop_NE
  #King_SW = #Bishop_SW
  #King_SE = #Bishop_SE
EndEnumeration

Enumeration Knight_Directions
  #Knight_Up1Left2 = 8
  #Knight_Up1Right2 = 12
  #Knight_Up2Left1 = 19
  #Knight_Up2Right1 = 21

  #Knight_Down1Left2 = -12
  #Knight_Down1Right2 = -8
  #Knight_Down2Left1 = -21
  #Knight_Down2Right1 = -19
EndEnumeration

Enumeration WhitePawn_Directions
  #WP_North1 = #Rook_North
  #WP_North2 = #Rook_North * 2
  #WPcapture_NW = #Bishop_NW
  #WPcapture_NE = #Bishop_NE
EndEnumeration

Enumeration BlackPawn_Directions
  #BP_South1 = #Rook_South
  #BP_South2 = #Rook_South * 2
  #BPcapture_SW = #Bishop_SW
  #BPcapture_SE = #Bishop_SE
EndEnumeration

Enumeration TT_Score_Flags
  #Alpha_Cutoff_TT_Flag = 1
  #Beta_Cutoff_TT_Flag = 2
  #Exact_Score_TT_Flag = 3
  #Unknown_Score_TT_Flag = 4
  #Other_Info_TT_Flag = 5
EndEnumeration

#NoCastlingMove = 0
#ShortCastlingMove = 1
#LongCastlingMove = 2
#WhiteX = 1
#BlackX = -1
#Min_Time_Value = 1000
#Fixed_Clock_Time = 1000          ; in centi-seconds according to xboard protocol

#Legal = 1
#Illegal = 0

;some constants for Zobrist hashing - kenpchess

;#HashModuloValue as UInteger = 1000000                            ; this modulo will yield six-digit indexes

#HashModuloValue = 4194304
#HashTableSize = 4194304                              ; size is somewhat arbitrary, this is 4,096,000 entries
#PawnHashTableSize = 65536                            ; pawn table size is quite a bit smaller, this is 65536 entries, not implemented fully yet
#RepTableSize = 500                                   ; repetition table only holds key positions after an actual game move
#WhiteZbIdx = 1
#BlackZbIdx = 2


Structure MoveType
  FromField.w
  ToField.w
  CapturedPiece.w
  PromotedPiece.w
  CastlingNr.w
  EpField.w
  Value.w
EndStructure


Structure BothColourTypes
  WhiteX.w
  BlackX.w
EndStructure

Structure FromToType
  FromField.w
  ToField.w
  Eval.w
EndStructure

Structure KillerType
  Killer1.FromToType
  Killer2.FromToType
EndStructure


;************* start of Zobrist transpostion table code definitions - kenpchess


Structure ttMove
       ttFromSq.b
       ttToSq.b
EndStructure

Structure TpTableEntry                                                      ; obviously the structure for a transposition table entry
       TpZobkey.q                                            ; using the 8 byte Zobrist key
       TpMove.ttMove
       TpEval.w
       TpDepth.b
       TpEvalTypeFlag.b                                         ; all-node (upper bound=1), cut-node (lower bound=2), pv-node (exact=3), unknown=4
       TpAge.b                                                  ; 16-byte TT entry (Did I count correctly?)
       TpExtra1.b
EndStructure


Structure rptMove
       rptFromSq.b
       rptToSq.b
EndStructure

Structure RepTableEntry                                          ; similar type of structure for a much smaller 3-fold repetition table
       RepZobkey.q                                               ; still using the 8 byte Zobrist key
       RepMove.rptMove
       RepEval.w
       RepDepth.b                                                ; probably do not need the Depth, will leave it for now, we will see
       RepExtra1Flag.b
       RepExtra2Flag.b
       RepExtra3Flag.b
EndStructure


Structure PawnTMove                     
       pawnFromSq.b
       pawnToSq.b
       pawnEPSq.b
       pawnPromoSq.b
EndStructure


Structure PawnTableEntry                                          ; similar type of structure for Pawn hash table, probably changes upon implementation
       PawnZobkey.q                                               ; still using the 8 byte Zobrist key
       PawnMove.PawnTMove
       PawnEval.w
       PawnDepth.b                                                ; maybe do not need the Depth, will leave it for now, we will see
       PawnExtra1Flag.b
EndStructure


;random 64 bit numbers for Zobrist hashing function, 1440 + 20 in this table, see below. For Transpotion table and 3-fold Repetition table.
;for freebasic by kenpchess


Global Dim Rand64s_for_Zobrist.q(6,2,119)     ; for Zobrist keys, 6 piecetypes * 2 colors * 64 sq is 768, and with 120 mailbox sq is 1440
Global Dim Extra_Rand64s.q(30)                          ; maybe used for castling, ep, color, etc.

Global Dim WCastleZobristFlags.q(4)                     ; Bothwings, long, short, none
Global Dim BCastleZobristFlags.q(4)                     ; Bothwings, long, short, none
Global SwitchColorZobristKey.q                          ; used to change White or Black to move (positions are considered different depending on whose turn to move
Global ExtraZobristFlag1.q
Global Dim WhiteEPSqsZobristKey.q(78)                   ; White EP captures can only occur on sqs a6 thru h6
Global Dim BlackEPSqsZobristKey.q(48)                   ; Black EP captures can only occur on sqs a3 thru h3
Global Dim FourExtraZobristKeys.q(4)                    ; use up four extra randoms

Global StartingPositionZobristKey.q                     ; all pieces XORed of classic chess starting position
Global CurrentPositionZobristKey.q
Global IncrementalZobristPositionKey.q
Global RepeatPositionZobristKey.q
Global TestPositionZobristKey1.q 
Global TestPositionZobristKey2.q

Global StartingPawnsZobristKey.q                        ; for a yet un-implemented pawn hash table
Global CurrentPawnsZobristKey.q
Global TTZobristKeyIndex1.q
Global TTEntryCount.i
Global TTLookupHitCount.i

Global z1.i
Global z2.i
Global z3.i
Global z4.i
Global z5.i
Global zsq.i

Global Dim TpTable.TpTableEntry(#HashTableSize-1)
;Global Dim TpTable.TpTableEntry(#HashTableSize - 1)                 ; size of transposition table is currently 2 ^ 17 entries * 16 bytes per entry
Global Dim RepTable.RepTableEntry(2,#RepTableSize - 1)              ; size of repetition table is small, approx 500 entries * 16 bytes per entry * both White and Black separately indexed
Global Dim PawnTpTable.PawnTableEntry(#PawnHashTableSize -1)        ; size of pawn transposition table is much smaller than general transposition table
Global Dim ColorZbIdx.w(3)                                         ; hack to translate SideToMove to WhiteZbIdx or BlackZbIdx (see below)

Global StartPositionTpTableIndex.q
Global TpTableIndex1.q


;************* end of Zobrist transpostion table code definitions - kenpchess



Global Dim Board.w(#CBoardDim)
Global Dim EpField.w(#CMaxDepth)
Global Dim MoveStack.MoveType(#CMoveStackDim)
Global Dim MoveStackQuiet.MoveType(#CMoveStackDim)
Global Dim MoveStackCapture.MoveType(#CMoveStackDim)
Global Dim PositionHistory_Table.s(#RepTableSize,2)
Global SecondBestMove.MoveType

Global Dim MoveControl.w(#H8)
Global Dim Castling.w(2)
Global CurrentEval.w
Global CurrentMovingPiece.w
Global CurrentMaterialBalance.w
Global Dim StackLimit(#CMaxDepth)
Global CaptureMoveFlag.w
Global MaterialOKFlag.w
Global NonZobristRepeatFlag.w
Global ZobristRepeatFlag.w
Global SecondBestMovePiece.w
Global SecondBestMoveIsLegalFlag.w
Global PreviousMove.FromToType
Global Dim MVar.FromToType(#CMaxDepth, #CMaxDepth)
Global Dim PV.FromToType(#CMaxDepth)
Global Dim KillerTab.KillerType(#CMaxDepth)
Global Dim ToField.w(#CMaxDepth)
Global WKing.w
Global BKing.w
Global Dim MaterialBalance.w(#CMaxDepth)
Global Dim MaterialTotal.w(#CMaxDepth)
Global SideToMove.w
Global ComputerSide.w
Global MinDepth.w
Global MaxExtension.w
Global Depth.w
Global NodeCount.l
Global LastMove.w
Global InCheck.w
Global ZobristInCheckFlag.w
Global KingOnBackRankFlag.w
Global MoveCount.w
Global GameMoveNumber.w
Global AvgGameLengthMoves.w
Global KingEscapeSqrCount.w
Global KingDefendersBonus.w
Global KingRingPawnShieldBonus.w
Global KingAttackersPenalty.w
Global IsWhiteLast.w
Global Time_Balance.q, Original_ClockTime.q
Global Time_Balance_Quad.q
Global StartTime.q, EndTime.q, Elapsed_Time.q
Global mg_starttime.q
Global mg_endtime.q
Global mg_elapsedtime.q

Global Dim AlgBrd.s(99)
Global Dim NonZobristBoardStr.s(400)
Global FENPositionstr.s
Global infoMsg.s
Global SquareAttackCount.w
Global QueenIsSquareAttackerFlag.w
Global QueenIsKingRingAttackerFlag.w
Global Datax.w, jjj.w
Global PartMove.s, previous_depth.w, TimerCheck_Count.i, movegen_flag.b, movegen_count.i
Global alphabeta_count.i, log_count.i


; PIECE SQUARE TABLES only (PESTO) evaluation
; values from Rofchade: http://www.talkchess.com/forum3/viewtopic.php?f=2$amp;t=68311$amp;start=19


Global Dim Midgame_Piece_value.w(6)
DataSection
  Midgame_Piece_values:
    Data.w 82, 477, 365, 337, 1025, 0
  EndDataSection
Restore Midgame_Piece_values
For Datax = 1 To 6 : Read.w Midgame_Piece_value(Datax) : Next

Global Dim Endgame_Piece_value.w(6)
DataSection
  Endgame_Piece_values:
    Data.w 94, 512, 297, 281, 936, 0
  EndDataSection
Restore Endgame_Piece_values
For Datax = 1 To 6 : Read.w Endgame_Piece_value(Datax) : Next

Global Dim MidGame_PST.w(6, 119, 2)
Global Dim EndGame_PST.w(6, 119, 2)

Global Dim GamePhaseInc.w(6)
GamePhaseInc(1) = 0 : GamePhaseInc(2) = 2 : GamePhaseInc(3) = 1 : GamePhaseInc(4) = 1 : GamePhaseInc(5) = 4 : GamePhaseInc(6) = 0

Global SideColor.w, TheSq.w, MG_Eval_White.w, MG_Eval_Black.w, EG_Eval_White.w, EG_Eval_Black.w, Total_PST_Eval.w

#WhiteColor = 1
#BlackColor = 2

; Below array is used to invert PST arrays from White side to Black side when they are loaded to main arrays above
 
Global Dim FlipMatrix.w(119)
DataSection
  FlipMatrix: 
    Data.w 0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,   91,  92,  93,  94,  95,  96, 97,  98,  0, 0,   81,  82,  83,  84,  85,  86, 87,  88,  0,  0,   71,  72,  73,  74,  75,  76, 77,  78,  0,  0,   61,  62,  63,  64,  65,  66, 67,  68,  0,  0,   51,  52,  53,  54,  55,  56, 57,  58,  0,  0,   41,  42,  43,  44,  45,  46, 47,  48,  0, 0,   31,  32,  33,  34,  35,  36, 37,  38,  0,  0,   21,  22,  23,  24,  25,  26, 27,  28,  0,  0,   0,   0,   0,   0,   0,   0,  0,   0,   0,  0,   0,   0,   0,   0,   0,   0,  0,   0,   0
EndDataSection
Restore FlipMatrix
For Datax = 0 To 119 : Read.w FlipMatrix(Datax) : Next

; Below arrays are mailbox conceptualized with edge squares and viewed as a1-h1 at bottom (after two bottom edge rows.
; It obviously loads from left to right and wraps up and back around to next row in DIM statement.
;
;110=edge, 111=edge, 112=edge, 113=edge, 114=edge, 115=edge , 116=edge, 117=edge, 118=edge, 119=edge.  ( last 2 rows are off the board )
;100=edge, 101=edge, 102=edge, 103=edge, 104=edge, 105=edge , 106=edge, 107=edge, 108=edge, 109=edge,
; 90=edge, 91=a8,   92=b8,   93=c8,   94=d8,   95=e8,   96=f8,   97=g8,   98=h8,  99=edge,             ( note - this is the eighth  rank )
; 80=edge, 81=a7,   82=b7,   83=c7,   84=d7,   85=e7,   86=f7,   87=g7,   88=h7,  89=edge,             ( note - this is the seventh rank )
; 70=edge, 71=a6,   72=b6,   73=c6,   74=d6,   75=e6,   76=f6,   77=g6,   78=h6,  79=edge,
; 60=edge, 61=a5,   62=b5,   63=c5,   64=d5,   65=e5,   66=f5,   67=g5,   68=h5,  69=edge,
; 50=edge, 51=a4,   52=b4,   53=c4,   54=d4,   55=e4,   56=f4,   57=g4,   58=h4,  59=edge,
; 40=edge, 41=a3,   42=b3,   43=c3,   44=d3,   45=e3,   46=f3,   47=g3,   48=h3,  49=edge,
; 30=edge, 31=a2,   32=b2,   33=c2,   34=d2,   35=e2,   36=f2,   37=g2,   38=h2,  39=edge,
; 20=edge, 21=a1,   22=b1,   23=c1,   24=d1,   25=e1,   26=f1,   27=g1,   28=h1,  29=edge,
; 10=edge, 11=edge, 12=edge, 13=edge, 14=edge, 15=edge, 16=edge, 17=edge, 18edge, 19=edge,             ( 1st 2 rows are off the board )
;  0=edge,  1=edge,  2=edge,  3=edge,  4=edge,  5=edge,  6=edge,  7=edge,  8=edge, 9=edge,           

CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  IncludeFile "/Users/kenpchess/Public/Piece_Square_Tables_etc.pb"
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  IncludeFile "C:\PureBasic\Piece_Square_Tables_etc.pb"
CompilerEndIf


Global Dim Piece_Moves_Table.w(6, #H8, #Max_Move_Dirs, #Max_Travel_Sqs)    ; all piece sqs in one table, Black pawn in element 0
Global Dim Max_Piece_Dirs.w(6)
Max_Piece_Dirs(0) = 4 : Max_Piece_Dirs(1) = 4 : Max_Piece_Dirs(2) = 4 : Max_Piece_Dirs(3) = 4 : Max_Piece_Dirs(4) = 8 : Max_Piece_Dirs(5) = 8 : Max_Piece_Dirs(6) = 8

Global Dim Piece_Dirs_Table.w(6, #Max_Move_Dirs)
Piece_Dirs_Table(0,1) = #BP_South1 : Piece_Dirs_Table(0,2) = #BP_South2 : Piece_Dirs_Table(0,3) = #BPcapture_SW : Piece_Dirs_Table(0,4) = #BPcapture_SE
Piece_Dirs_Table(0,5) = 0 : Piece_Dirs_Table(0,6) = 0 : Piece_Dirs_Table(0,7) = 0 : Piece_Dirs_Table(0,8) = 0

Piece_Dirs_Table(1,1) = #WP_North1 : Piece_Dirs_Table(1,2) = #WP_North2 : Piece_Dirs_Table(1,3) = #WPcapture_NW : Piece_Dirs_Table(1,4) = #WPcapture_NE
Piece_Dirs_Table(1,5) = 0 : Piece_Dirs_Table(1,6) = 0 : Piece_Dirs_Table(1,7) = 0 : Piece_Dirs_Table(1,8) = 0

Piece_Dirs_Table(2,1) = #Rook_North : Piece_Dirs_Table(2,2) = #Rook_South : Piece_Dirs_Table(2,3) = #Rook_East : Piece_Dirs_Table(2,4) = #Rook_West 
Piece_Dirs_Table(2,5) = 0 : Piece_Dirs_Table(2,6) = 0 : Piece_Dirs_Table(2,7) = 0 : Piece_Dirs_Table(2,8) = 0

Piece_Dirs_Table(3,1) = #Bishop_NW : Piece_Dirs_Table(3,2) = #Bishop_NE : Piece_Dirs_Table(3,3) = #Bishop_SW : Piece_Dirs_Table(3,4) = #Bishop_SE
Piece_Dirs_Table(3,5) = 0 : Piece_Dirs_Table(3,6) = 0 : Piece_Dirs_Table(3,7) = 0 : Piece_Dirs_Table(3,8) = 0 : 

Piece_Dirs_Table(4,1) = #Knight_Up1Left2 : Piece_Dirs_Table(4,2) = #Knight_Up1Right2 : Piece_Dirs_Table(4,3) = #Knight_Up2Left1 : Piece_Dirs_Table(4,4) = #Knight_Up2Right1
Piece_Dirs_Table(4,5) = #Knight_Down1Left2 : Piece_Dirs_Table(4,6) = #Knight_Down1Right2 : Piece_Dirs_Table(4,7) = #Knight_Down2Left1 : Piece_Dirs_Table(4,8) = #Knight_Down2Right1
 
Piece_Dirs_Table(5,1) = #Bishop_NW : Piece_Dirs_Table(5,2) = #Bishop_NE : Piece_Dirs_Table(5,3) = #Bishop_SW : Piece_Dirs_Table(5,4) = #Bishop_SE
Piece_Dirs_Table(5,5) = #Rook_North : Piece_Dirs_Table(5,6) = #Rook_South : Piece_Dirs_Table(5,7) = #Rook_East : Piece_Dirs_Table(5,8) = #Rook_West

Piece_Dirs_Table(6,1) = #King_North : Piece_Dirs_Table(6,2) = #King_South : Piece_Dirs_Table(6,3) = #King_East : Piece_Dirs_Table(6,4) = #King_West
Piece_Dirs_Table(6,5) = #King_NW : Piece_Dirs_Table(6,6) = #King_NE : Piece_Dirs_Table(6,7) = #King_SW : Piece_Dirs_Table(6,8) = #King_SE

Global Dim KingQuandrant.w(98) 
For Datax = 0 To 98 : KingQuandrant(Datax) = 0 : Next
For DataX = 20 To 90 Step 10
  For jjj = 1 To 4
    KingQuandrant(Datax+jjj) = #d1
  Next
  For jjj = 5 To 8
    KingQuandrant(Datax+jjj) = #e1
  Next
Next

Global Dim InitialPosition.w(119)
For Datax = 0 To 119 : InitialPosition(Datax) = #EdgeSq : Next
For Datax = 20 To 90 Step 10
  For jjj = 1 To 8
    InitialPosition(Datax+jjj) = #EmptySq
  Next
Next
InitialPosition(21) = #rook : InitialPosition(22) = #knight : InitialPosition(23) = #bishop : InitialPosition(24) = #queen
InitialPosition(25) = #king : InitialPosition(26) = #bishop : InitialPosition(27) = #knight : InitialPosition(28) = #rook
For DataX = 31 To 38 : InitialPosition(Datax) = #pawn : Next
InitialPosition(91) = #rook * -1 : InitialPosition(92) = #knight * -1 : InitialPosition(93) = #bishop * -1 : InitialPosition(94) = #queen * -1
InitialPosition(95) = #king * -1 : InitialPosition(96) = #bishop * -1 : InitialPosition(97) = #knight * -1 : InitialPosition(98) = #rook * -1
For DataX = 81 To 88 : InitialPosition(Datax) = #pawn * -1 : Next


Global Dim MbxBrd.w(119)
For Datax = 0 To 119 : MbxBrd(Datax) = #EdgeSq : Next
For Datax = 20 To 90 Step 10
  For jjj = 1 To 8
    MbxBrd(Datax+jjj) = #EmptySq
  Next
Next

Global Dim KingRingSqrsTable.w(5)
Global Dim KingRingSqrAttackedFlag.w(5)
Global Dim KingRingSqrDefendedFlag.w(5)

Global Dim WhiteEPSquares.w(78)
Global Dim BlackEPSquares.w(48)

Global.w BoardSq, The_Dir, NextDir, SqList, NextSq, No_of_Piece_Dirs
Global.w RawPiece, ThePiece, SqContents, TableSq, MoveIndex, QuietIndex, CaptureIndex, Proper_Piece_Color, SqCount, Total_Travel_Sqs


AlgBrd(99)="OB"

AlgBrd(91)="a8" : AlgBrd(92)="b8" : AlgBrd(93)="c8" : AlgBrd(94)="d8" : AlgBrd(95)="e8" : AlgBrd(96)="f8" : AlgBrd(97)="g8" : AlgBrd(98)="h8"
AlgBrd(81)="a7" : AlgBrd(82)="b7" : AlgBrd(83)="c7" : AlgBrd(84)="d7" : AlgBrd(85)="e7" : AlgBrd(86)="f7" : AlgBrd(87)="g7" : AlgBrd(88)="h7"
AlgBrd(71)="a6" : AlgBrd(72)="b6" : AlgBrd(73)="c6" : AlgBrd(74)="d6" : AlgBrd(75)="e6" : AlgBrd(76)="f6" : AlgBrd(77)="g6" : AlgBrd(78)="h6"
AlgBrd(61)="a5" : AlgBrd(62)="b5" : AlgBrd(63)="c5" : AlgBrd(64)="d5" : AlgBrd(65)="e5" : AlgBrd(66)="f5" : AlgBrd(67)="g5" : AlgBrd(68)="h5"
AlgBrd(51)="a4" : AlgBrd(52)="b4" : AlgBrd(53)="c4" : AlgBrd(54)="d4" : AlgBrd(55)="e4" : AlgBrd(56)="f4" : AlgBrd(57)="g4" : AlgBrd(58)="h4"
AlgBrd(41)="a3" : AlgBrd(42)="b3" : AlgBrd(43)="c3" : AlgBrd(44)="d3" : AlgBrd(45)="e3" : AlgBrd(46)="f3" : AlgBrd(47)="g3" : AlgBrd(48)="h3"
AlgBrd(31)="a2" : AlgBrd(32)="b2" : AlgBrd(33)="c2" : AlgBrd(34)="d2" : AlgBrd(35)="e2" : AlgBrd(36)="f2" : AlgBrd(37)="g2" : AlgBrd(38)="h2"
AlgBrd(21)="a1" : AlgBrd(22)="b1" : AlgBrd(23)="c1" : AlgBrd(24)="d1" : AlgBrd(25)="e1" : AlgBrd(26)="f1" : AlgBrd(27)="g1" : AlgBrd(28)="h1"

AlgBrd(20)="OB"

Global iii.w
For iii = 0 To 400
  NonZobristBoardStr(iii) = ""
Next

; Initialize the master Piece Square Tables

For TheSq = #a1 To #h8
  For ThePiece = 1 To 6
    Select ThePiece
      Case #WP
          ; fill tables for White
          MidGame_PST(ThePiece,TheSq,#WhiteColor) = MidGame_Piece_value(ThePiece) + MidGame_Pawn_table(TheSq)
          EndGame_PST(ThePiece,TheSq,#WhiteColor) = EndGame_Piece_value(ThePiece) + EndGame_Pawn_table(TheSq)
          ; fill tables for Black
          MidGame_PST(ThePiece,TheSq,#BlackColor) = MidGame_Piece_value(ThePiece) + MidGame_Pawn_table(FlipMatrix(TheSq))
          EndGame_PST(ThePiece,TheSq,#BlackColor) = EndGame_Piece_value(ThePiece) + EndGame_Pawn_table(FlipMatrix(TheSq))
      Case #WR
          ; fill tables for White
          MidGame_PST(ThePiece,TheSq,#WhiteColor) = MidGame_Piece_value(ThePiece) + MidGame_Rook_table(TheSq)
          EndGame_PST(ThePiece,TheSq,#WhiteColor) = EndGame_Piece_value(ThePiece) + EndGame_Rook_table(TheSq)
          ; fill tables for Black
          MidGame_PST(ThePiece,TheSq,#BlackColor) = MidGame_Piece_value(ThePiece) + MidGame_Rook_table(FlipMatrix(TheSq))
          EndGame_PST(ThePiece,TheSq,#BlackColor) = EndGame_Piece_value(ThePiece) + EndGame_Rook_table(FlipMatrix(TheSq))
      Case #WB
          ; fill tables for White
          MidGame_PST(ThePiece,TheSq,#WhiteColor) = MidGame_Piece_value(ThePiece) + MidGame_Bishop_table(TheSq)
          EndGame_PST(ThePiece,TheSq,#WhiteColor) = EndGame_Piece_value(ThePiece) + EndGame_Bishop_table(TheSq)
          ; fill tables for Black
          MidGame_PST(ThePiece,TheSq,#BlackColor) = MidGame_Piece_value(ThePiece) + MidGame_Bishop_table(FlipMatrix(TheSq))
          EndGame_PST(ThePiece,TheSq,#BlackColor) = EndGame_Piece_value(ThePiece) + EndGame_Bishop_table(FlipMatrix(TheSq))
      Case #WN
          ; fill tables for White
          MidGame_PST(ThePiece,TheSq,#WhiteColor) = MidGame_Piece_value(ThePiece) + MidGame_Knight_table(TheSq)
          EndGame_PST(ThePiece,TheSq,#WhiteColor) = EndGame_Piece_value(ThePiece) + EndGame_Knight_table(TheSq)
          ; fill tables for Black
          MidGame_PST(ThePiece,TheSq,#BlackColor) = MidGame_Piece_value(ThePiece) + MidGame_Knight_table(FlipMatrix(TheSq))
          EndGame_PST(ThePiece,TheSq,#BlackColor) = EndGame_Piece_value(ThePiece) + EndGame_Knight_table(FlipMatrix(TheSq))
      Case #WQ
          ; fill tables for White
          MidGame_PST(ThePiece,TheSq,#WhiteColor) = MidGame_Piece_value(ThePiece) + MidGame_Queen_table(TheSq)
          EndGame_PST(ThePiece,TheSq,#WhiteColor) = EndGame_Piece_value(ThePiece) + EndGame_Queen_table(TheSq)
          ; fill tables for Black
          MidGame_PST(ThePiece,TheSq,#BlackColor) = MidGame_Piece_value(ThePiece) + MidGame_Queen_table(FlipMatrix(TheSq))
          EndGame_PST(ThePiece,TheSq,#BlackColor) = EndGame_Piece_value(ThePiece) + EndGame_Queen_table(FlipMatrix(TheSq))
      Case #WK
          ; fill tables for White
          MidGame_PST(ThePiece,TheSq,#WhiteColor) = MidGame_Piece_value(ThePiece) + MidGame_King_table(TheSq)
          EndGame_PST(ThePiece,TheSq,#WhiteColor) = EndGame_Piece_value(ThePiece) + EndGame_King_table(TheSq)
          ; fill tables for Black
          MidGame_PST(ThePiece,TheSq,#BlackColor) = MidGame_Piece_value(ThePiece) + MidGame_King_table(FlipMatrix(TheSq))
          EndGame_PST(ThePiece,TheSq,#BlackColor) = EndGame_Piece_value(ThePiece) + EndGame_King_table(FlipMatrix(TheSq))
    EndSelect
  Next ThePiece
Next TheSq


Global Dim PieceMaterial.w(#PieceTypes)

PieceMaterial(#nil) = 0 : PieceMaterial(#WP) = #MatP : PieceMaterial(#WR) = #MatR : PieceMaterial(#WB) = #MatB
PieceMaterial(#WN) = #MatN : PieceMaterial(#WQ) = #MatQ : PieceMaterial(#WK) = #MatK

Global Dim FigSymbol.s(#PieceTypes)

FigSymbol(#nil) = "." : FigSymbol(#WP) = "P" : FigSymbol(#WR) = "R" : FigSymbol(#WB) = "B" : FigSymbol(#WN) = "N" : FigSymbol(#WQ) = "Q" : FigSymbol(#WK) = "K"

Global Dim WhitePieces.s(#PieceTypes)
WhitePieces(0) = "0" : WhitePieces(1) = "P" : WhitePieces(2) = "R" : WhitePieces(3) = "B" : WhitePieces(4) = "N" : WhitePieces(5) = "Q" : WhitePieces(6) = "K"

Global Dim BlackPieces.s(#PieceTypes)
BlackPieces(0) = "0" : BlackPieces(1) = "p" : BlackPieces(2) = "r" : BlackPieces(3) = "b" : BlackPieces(4) = "n" : BlackPieces(5) = "q" : BlackPieces(6) = "k"

Global Dim PieceStr.s(6)

PieceStr(1) = "P" : PieceStr(2) = "R" : PieceStr(3) = "N" : PieceStr(4) = "B" : PieceStr(5) = "Q" : PieceStr(6) = "K"

ColorZbIdx(1) = 2 : ColorZbIdx(2) = 0 : ColorZbIdx(3) = 1


; open debugging logfile

Global FileHandleLog.i, Mnowdate1.s, MiniMaxPBkp_Logfile.s

OpenConsole()
Mnowdate1 = FormatDate("%yyyy%mm%dd%hh%ii%ss", Date())
; note: some kind of GetCurrentDirectory() bug, logfile cannot always be created on /Desktop
;MiniMaxPBkp_Logfile = GetCurrentDirectory() + "minimax_pbkp_" + MnowDate1 + ".log"
;MiniMaxPBkp_Logfile = "/users/kenpresley/Desktop/" + "minimax_pbkp_" + MnowDate1 + ".log"
MiniMaxPBkp_Logfile = GetUserDirectory(#PB_Directory_Desktop) + "minimax_pbkp_" + MnowDate1 + ".log"

FileHandleLog = OpenFile(#PB_Any,MiniMaxPBkp_Logfile, #PB_File_Append)

PrintN("info - MiniMaxPBkp_Logfile = " + MiniMaxPBkp_Logfile)


Procedure SendLog(AMessage.s)
  
  If Depth <= 3 Or (movegen_flag = #True And movegen_count % 500 = 0)
    ;PrintN(AMessage)
  EndIf
  If FindString(Amessage,"checkmate") > 0
    PrintN(AMessage)
  EndIf
  log_count = log_count + 1
  ;If FileHandleLog And Depth <= 11 And log_count % 5 = 0
  If FileHandleLog And (log_count % 5 = 0 Or FindString(Amessage,"checkmate") > 0 Or FindString(Amessage,"MiniMaxkp ") > 0 )
    WriteStringN(FileHandleLog, AMessage)
  EndIf
  previous_depth = depth
EndProcedure


Procedure ConstructZobristPositionKey(ZobristSideToMove.w)
  CurrentPositionZobristKey = 0
  CurrentPawnsZobristKey = 0
  CurrentMaterialBalance = 0                                                                                             ; recompute material balance while we are here
  For zsq = 0 To 119
    If Board(zsq) <> 0  ;skip empty squares
      If Board(zsq) < 0
        CurrentPositionZobristKey = CurrentPositionZobristKey ! Rand64s_for_Zobrist(Board(zsq) * -1,#BlackZbIdx,zsq)    ; black piece
        If Board(zsq) = #BP                                                                                          ; for pawn hash table
            CurrentPawnsZobristKey = CurrentPawnsZobristKey ! Rand64s_for_Zobrist(#BP*-1,#BlackZbIdx,zsq)
        EndIf
        CurrentMaterialBalance = CurrentMaterialBalance - PieceMaterial(Board(zsq)*-1)                                 ; Black pieces
      Else
        If Board(zsq) <> #EdgeSq  ;skip edge (off-board) squares
          CurrentPositionZobristKey = CurrentPositionZobristKey ! Rand64s_for_Zobrist(Board(zsq),#WhiteZbIdx,zsq)  ; white piece
          If Board(zsq) = #WP                                                                                        ; for pawn hash table
              CurrentPawnsZobristKey = CurrentPawnsZobristKey ! Rand64s_for_Zobrist(#WP,#WhiteZbIdx,zsq)
          EndIf
          CurrentMaterialBalance = CurrentMaterialBalance + PieceMaterial(Board(zsq))                                    ; White pieces
        EndIf 
      EndIf
    EndIf
  Next zsq
  If ZobristSideToMove = #BlackX
    CurrentPositionZobristKey = CurrentPositionZobristKey ! SwitchColorZobristKey
  EndIf
EndProcedure 


Procedure StoreZobristTTEntry(ZobristPositionKey.q, TpFromSq.b, TpToSq.b, ZEval.w, ZDepth.b, EvalTypeFlag.b, ZAlpha.w, ZBeta.w )
  
  ;Global Dim TpTable.TpTableEntry(#HashTableSize - 1)
  ;PureBasic select statements do not have conditionals!, so ...
  If ZEval < Zalpha
    EvalTypeFlag = #Alpha_Cutoff_TT_Flag
  Else
    If ZEval >= ZBeta
      EvalTypeFlag = #Beta_Cutoff_TT_Flag
    Else
      If ZEval >= Zalpha
        EvalTypeFlag = #Exact_Score_TT_Flag
      Else
        EvalTypeFlag = #Unknown_Score_TT_Flag
      EndIf
    EndIf
  EndIf

; Currently during debugging we are greatly limiting or even disabling the transposition table

  ;EvalTypeFlag = Unknown_Score_TT_Flag

;  If Depth > 0 AND EvalTypeFlag <> Alpha_Cutoff_TT_Flag 
  If Depth > 0 

    TTZobristKeyIndex1 = ZobristPositionKey % #HashModuloValue
    ;TpTable(TTZobristKeyIndex1)\TpZobkey = ZobristPositionKey
    ;TpTable(TTZobristKeyIndex1)\TpMove\ttFromSq = TpFromSq
    ;TpTable(TTZobristKeyIndex1)\TpMove\ttToSq = TpToSq
    ;TpTable(TTZobristKeyIndex1)\TPEval = ZEval
    ;TpTable(TTZobristKeyIndex1)\TpDepth = ZDepth
    ;TpTable(TTZobristKeyIndex1)\TpEvalTypeFlag = EvalTypeFlag
    ;TpTable(TTZobristKeyIndex1)\TpAge = GameMoveNumber
    ;TpTable(TTZobristKeyIndex1)\TpExtra1 = 0
    TTEntryCount = TTEntryCount + 1

    infoMsg = "info: Zobrist STORE - Zobrist key = " + Str(IncrementalZobristPositionKey) + " move = " + AlgBrd(TpFromSq) + AlgBrd(TpToSq)
    infoMsg = infoMsg + " Eval = " + Str(ZEval) + " Depth = " + Str(Depth) + " hash type = " + Str(EvalTypeFlag) + " TT Index = " + Str(TTZobristKeyIndex1)
    infoMsg = infoMsg + " TT Hits = " + Str(TTLookupHitCount)
    ;SendLog(infoMsg)

  EndIf

EndProcedure 


Procedure ResetBoardToInitialPosition()
  For BoardSq = 0 To 119
    Board(BoardSq) = InitialPosition(BoardSq)
  Next BoardSq
EndProcedure 


;Fill the initial Zobrist randoms table
CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
  IncludeFile "/Users/kenpchess/Public/Zobrist_Table_values.pb"
CompilerEndIf

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  IncludeFile "C:\PureBasic\Zobrist_Table_values.pb"
CompilerEndIf


Restore ZobristValues

For z1 = 1 To 6
  For z2 = 1 To 2
   For z3 = 0 To 119
     Read.i Rand64s_for_Zobrist(z1,z2,z3)
     If z2 = 1 
       ;print "piece = ";PieceStr(z1);" Filling Zobrist squares table - color is White: ";
     Else 
       ;print "piece = ";PieceStr(z1);" Filling Zobrist squares table - color is Black: ";
     EndIf
     ;print "sq = ";str(z3);" Zobrist random value = ";Rand64s_for_Zobrist(z1,z2,z3);" in hex = ";hex(Rand64s_for_Zobrist(z1,z2,z3))
   Next z3

   ;print
  Next z2
Next z1

;print "Last random for Zobrist board value in hex is: "; hex(Rand64s_for_Zobrist(6,2,119))
;print

;Read the Zobrist randoms for the castling flags (both, short, long, none) 

For z1 = 1 To 4
  Read.i WCastleZobristFlags(z1)
  ;print "White castle zobrist flag ";z1;" = ";WCastleZobristFlags(z1)
Next z1
;print
For z1 = 1 To 4
  Read.i BCastleZobristFlags(z1)
  ;print "Black castle zobrist flag ";z1;" = ";BCastleZobristFlags(z1)
Next z1

; Zobrist position keys are considered different depending on color to move
Read.i SwitchColorZobristKey
Read.i ExtraZobristFlag1
                                                         ; now have used 8 plus 2 or ten random values
;print "Color to move Zobrist flag = ";SwitchColorZobristKey
;print "Extra1 Zobrist flag = ";ExtraZobristFlag1
;print

For z1 = 41 To 48
  Read.i BlackEPSqsZobristKey(z1)                          ; squares a3 thru h3
  ;print "Black ep square ";z1;" Zobrist value = ";BlackEPSqsZobristKey(z1)
Next z1
;print
For z1 = 71 To 78
  Read.i WhiteEPSqsZobristKey(z1)                          ; squares a6 thru h6
  ;print "White ep square ";z1;" Zobrist value = ";WhiteEPSqsZobristKey(z1)
Next z1

;print
                                                         ; use (and reserve) the last four Zobrist randoms from the big data table
For z1 = 1 To 4
  Read.i FourExtraZobristKeys(z1)
  ;print "The four extra Zobrist keys - key ";z1;" is = ";FourExtraZobristKeys(z1);" in hex = ";hex(FourExtraZobristKeys(z1))
Next z1


;let us make a Zobrist key for the starting position in classical chess with our random number table

For z1 = 0 To #CBoardDim
  Board(z1) = InitialPosition(z1)
Next z1

ConstructZobristPositionKey(#WhiteX)
StartingPositionZobristKey = CurrentPositionZobristKey
StartingPawnsZobristKey = CurrentPawnsZobristKey

;print
SendLog("info - Starting Position Zobrist key = " + Str(StartingPositionZobristKey) + " hex = " + Hex(StartingPositionZobristKey))
;print
;print "Let us make and unmake the moves 1. e2e4 e7e5 and check our Zobrist key values."
;print


;Board(35) = 0
;Board(55) = WP

TestPositionZobristKey1 = StartingPositionZobristKey ! Rand64s_for_Zobrist(#WP,#WhiteZbIdx,35)  ; remove (xor out) white e2 pawn
TestPositionZobristKey1 = TestPositionZobristKey1 ! Rand64s_for_Zobrist(#WP,#WhiteZbIdx,55)     ; add (xor in) white e4 pawn
TestPositionZobristKey1 = TestPositionZobristKey1 ! SwitchColorZobristKey                    ; change side to move (now Black)

;print "test position after whites e2e4 Zobrist key = ";TestPositionZobristKey1;" hex = ";hex(TestPositionZobristKey1)

;Board(85) = 0
;Board(65) = BP

TestPositionZobristKey1 = TestPositionZobristKey1 ! Rand64s_for_Zobrist(#BP * -1,#BlackZbIdx,85)  ; remove (xor out) black e7 pawn
TestPositionZobristKey1 = TestPositionZobristKey1 ! Rand64s_for_Zobrist(#BP * -1,#BlackZbIdx,65)  ; add (xor in) black e5 pawn
TestPositionZobristKey1 = TestPositionZobristKey1 ! SwitchColorZobristKey                      ; change side to move (now White)

;print
;print "test position after blacks e7e5 Zobrist key = ";TestPositionZobristKey1;" hex = ";hex(TestPositionZobristKey1)

;print
;print "Now take back the moves, Zobrist position key should revert to starting position Zobrist key."
;print

;Board(65) = 0
;Board(85) = BP

TestPositionZobristKey1 = TestPositionZobristKey1 ! Rand64s_for_Zobrist(#BP * -1,#BlackZbIdx,65)  ; remove (xor out) black e5 pawn
TestPositionZobristKey1 = TestPositionZobristKey1 ! Rand64s_for_Zobrist(#BP * -1,#BlackZbIdx,85)  ; add back (xor in) black e7 pawn8
TestPositionZobristKey1 = TestPositionZobristKey1 ! SwitchColorZobristKey


;Board(55) = 0
;Board(35) = WP

TestPositionZobristKey1 = TestPositionZobristKey1 ! Rand64s_for_Zobrist(#WP,#WhiteZbIdx,55)  ; remove (xor out) white e4 pawn
TestPositionZobristKey1 = TestPositionZobristKey1 ! Rand64s_for_Zobrist(#WP,#WhiteZbIdx,35)  ; add back (xor in) white e2 pawn
TestPositionZobristKey1 = TestPositionZobristKey1 ! SwitchColorZobristKey


SendLog("info - Starting position should be restored - our test position Zobrist key now = " + Str(TestPositionZobristKey1) + " hex = " + Hex(TestPositionZobristKey1))

;SendLog("info - Index via modulo " + Str(#HashModuloValue) + Str(TestPositionZobristKey1 % #HashModuloValue))



; sample table test code


;StartPositionTpTableIndex = StartingPositionZobristKey mod HashModuloValue

;RepTable(StartPositionTpTableIndex).RepZobkey = StartingPositionZobristKey

;print "Entry in RepTable with Starting position Zobrist key = ";RepTable(StartPositionTpTableIndex).RepZobkey;   " The index = ";StartPositionTpTableIndex


;Test data
;Here are some test keys. They were computed using MiniMax_kp and checked using the algorithm described above.
;starting position
;FEN=rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
;key=D13604BE6960D107

;position after e2e4
;FEN=rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1
;key=4C6F7327A874CD79

;position after e2e4 e7e5
;FEN=rnbqkbnr/ppp1pppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2
;key=4BD423A4EBCC852


;************* end of Zobrist transpostion table data and testing code etc- kenpchess



;******************************************************************** INITIALIZE (to all zeros) MoveGen Tables code *********************************************************************

; Initialize big Piece_Moves_Table to all zeros

For ThePiece = 0 To 6
  For BoardSq = #a1 To #h8
    For The_Dir = 1 To #Max_Move_Dirs
      For SqList = 1 To #Max_Travel_Sqs
        Piece_Moves_Table(ThePiece,BoardSq,The_Dir,SqList) = 0
      Next SqList
    Next The_Dir
  Next BoardSq
Next ThePiece

For z1 = 41 To 48
  BlackEPSquares(z1) = 0
  WhiteEPSquares(z1+30) = 0
Next z1

ResetBoardToInitialPosition()


;******************************************************************** BUILD MoveGen Tables code *********************************************************************

; Build big Piece_Moves_Table                                first pass is R,B,N,Q,K

For ThePiece = 2 To 6
  For BoardSq = #a1 To #h8
    If MbxBrd(BoardSq) <> #EdgeSq
      No_of_Piece_Dirs = Max_Piece_Dirs(ThePiece)

      For The_Dir = 1 To No_of_Piece_Dirs
        NextDir = Piece_Dirs_Table(ThePiece,The_Dir)
        If NextDir <> 0
          If ThePiece = 4 Or ThePiece = 6
            Total_Travel_Sqs = 1
          Else
            Total_Travel_Sqs = #Max_Travel_Sqs
          EndIf
          For SqList = 1 To Total_Travel_Sqs
            NextSq = BoardSq + (NextDir * SqList)
            If MbxBrd(NextSq) = 0
              Piece_Moves_Table(ThePiece,BoardSq,The_Dir,SqList) = NextSq
              ;print "Moves_Table(";WhitePieces(ThePiece);",";str(BoardSq);",";str(The_Dir);",";str(SqList);") = ";Rook_Moves_Table(BoardSq,The_Dir,SqList)
            Else
              Break
            EndIf
        Next SqList

        EndIf
      Next The_Dir
    EndIf
  Next BoardSq
Next ThePiece


; Populate WHITE PAWN Table entries (in big table)

For BoardSq = #A2 To #H7
  If MbxBrd(BoardSq) <> #EdgeSq
    For The_Dir = 1 To 4
      Select The_Dir
        Case 1, 3, 4
          NextDir = Piece_Dirs_Table(#WP,The_Dir)
          NextSq = BoardSq + NextDir
          If MbxBrd(NextSq) = 0 And MbxBrd(NextSq) <> #EdgeSq
            Piece_Moves_Table(#WP,BoardSq,The_Dir,1) = NextSq
            ;print "WPawn_Table(";str(BoardSq);",";str(The_Dir);") = ";Piece_Moves_Table(WP,BoardSq,The_Dir,1)
          EndIf
        Case 2
          If BoardSq >= #A2 And BoardSq <= #H2
            NextDir = Piece_Dirs_Table(#WP,The_Dir)
            NextSq = BoardSq + NextDir
            If MbxBrd(NextSq) = 0
              Piece_Moves_Table(#WP,BoardSq,The_Dir,1) = NextSq
              ;print "WPawn_Table(";str(BoardSq);",";str(The_Dir);") = ";Piece_Moves_Table(WP,BoardSq,The_Dir,1)
            EndIf
          EndIf
      EndSelect
    Next The_Dir
  EndIf
Next BoardSq


; Populate BLACK PAWN Table entries (in big table)

For BoardSq = #A2 To #H7
  If MbxBrd(BoardSq) <> #EdgeSq
    For The_Dir = 1 To 4
      Select The_Dir
        Case 1, 3, 4
          NextDir = Piece_Dirs_Table(0,The_Dir)                             ; storing BP sq moves in element zero of big table
          NextSq = BoardSq + NextDir
          If MbxBrd(NextSq) = 0 And MbxBrd(NextSq) <> #EdgeSq
            Piece_Moves_Table(0,BoardSq,The_Dir,1) = NextSq
            ;print "BPawn_Table(";str(BoardSq);",";str(The_Dir);") = ";Piece_Moves_Table(0,BoardSq,The_Dir,1)
          EndIf
        Case 2
          If  BoardSq >= #A7 And BoardSq <= #H7
            NextDir = Piece_Dirs_Table(0,The_Dir)
            NextSq = BoardSq + NextDir
            If MbxBrd(NextSq) = 0
              Piece_Moves_Table(0,BoardSq,The_Dir,1) = NextSq
              ;print "BPawn_Table(";str(BoardSq);",";str(The_Dir);") = ";Piece_Moves_Table(0,BoardSq,The_Dir,1)
            EndIf
          EndIf
      EndSelect
    Next The_Dir
  EndIf
Next BoardSq

;******************************************************************** PRINT MoveGen Tables code *********************************************************************


;print BIG table

For ThePiece = 0 To 6

  For BoardSq = #a1 To #h8
    If MbxBrd(BoardSq) <> #EdgeSq
      No_of_Piece_Dirs = Max_Piece_Dirs(ThePiece)
      For The_Dir = 1 To No_of_Piece_Dirs
        If ThePiece = 0
;          Print #1,"Piece = ";"BP";" BoardSq = ";str(BoardSq);" ";"MoveDir = ";str(Piece_Dirs_Table(ThePiece,The_Dir));" ";
        Else
;          Print #1,"Piece = ";WhitePieces(ThePiece);" BoardSq = ";str(BoardSq);" ";"MoveDir = ";str(Piece_Dirs_Table(ThePiece,The_Dir));" ";
        EndIf
        For SqList = 1 To 7
;          Print #1,"Sq = ";str(Piece_Moves_Table(ThePiece,BoardSq,The_Dir,SqList));" ";
        Next SqList
;        Print #1," "
      Next The_Dir
    EndIf
;    Print #1, " "
  Next BoardSq
;  Print #1," " : Print #1," "

Next ThePiece


; ----------------------------------------------------------------------

PrintN("info - " + Program_Name + " Ready for a command or long algebraic move (such as e2e4)...")
Initialize()
CommandLoop()

; ----------------------------------------------------------------------

CloseFile(#PB_Any)

Procedure Initialize()
  Protected i.w
  MoveCount = 0
  GameMoveNumber = 0
  AvgGameLengthMoves = 60
  TTEntryCount = 0
  TTLookupHitCount = 0
  For i = 0 To #CBoardDim
    Board(i) = InitialPosition(i)
  Next i
  For z5 = 0 To #HashTableSize-1
    TpTable(z5)\TpZobkey = 0
    TpTable(z5)\TpMove\ttFromSq = 0
    TpTable(z5)\TpMove\ttToSq = 0
    TpTable(z5)\TPEval = 0
    TpTable(z5)\TpDepth = 0
    TpTable(z5)\TpEvalTypeFlag = 0
    TpTable(z5)\TpAge = 0
    TpTable(z5)\TpExtra1 = 0
  Next z5

  CurrentPositionZobristKey = StartingPositionZobristKey
  IncrementalZobristPositionKey = StartingPositionZobristKey
  WKing = #e1
  BKing = #E8
  For i = 0 To 2
    Castling(i) = #False
  Next i
  For i = #a1 To #h8
    MoveControl(i) = 0
  Next i
  EpField(0) = #Illegal
  MaterialTotal(0) = #MaterialSum
  MaterialBalance(0) = 0
  StackLimit(0) = 0
  MinDepth = 5
  Depth = 0
  SideToMove = #WhiteX
  Original_ClockTime = #Fixed_Clock_Time * 10
  Time_Balance = Original_ClockTime
  ComputerSide = #nil
EndProcedure 

Procedure CommandLoop()
  Protected.w Ends, i.i
  Protected FullCommand.s, ShortCommand.s

  Repeat
    
    FullCommand = Input()
    ;PrintN("info: " + FullCommand)
    
    i = FindString(FullCommand, " ")
    If i > 0
      ShortCommand = Mid(FullCommand, 1, i - 1)
    Else
      ShortCommand = FullCommand
    EndIf
    SendLog("info: cmdloop " + FullCommand)

     Select ShortCommand
      Case "accepted"
      Case "board"
        Board_Print_Routine()
      Case "display-assessment"
        InitGameTree()
        Print("info - Assessment = " + AssessPosition(-1 * #MateValue, #MateValue, SideToMove))
      Case "display-board"
        DisplayBoard()
      Case "easy"
      Case "fen"
        FENPositionStr = Mid(FullCommand, i + 1, Len(FullCommand)-4)
        SendLog("info: CL1 FEN = " + FENPositionStr)
        ConstructPositionfromFEN()
      Case "force"
        ComputerSide = #nil
      Case "go"
        ComputerSide = SideToMove
        ;ComputerMove()
        ;ComputerSide = #nil
      Case "hard"
      Case "level"
      Case "new"
        Initialize()
      Case "otim"
      Case "post"
      Case "protover"
        PrintN("feature ping=0 setboard=0 usermove=0 memory=0 sigint=0 sigterm=0 myname=''" + Program_Name + "''")
        PrintN("feature done=1")
      Case "quit"
        Ends = #True
      Case "random"
      Case "rejected"
      Case "result"
      Case "st"
        Original_ClockTime = Val(Mid(FullCommand,i+1,5)) * 1000
        Time_Balance = Original_ClockTime                               ; xboard time is given in centi-seconds, watch out
        Time_Balance_Quad = Time_Balance
        PrintN("info: CL1a " + FullCommand + " Time Balance = " + Time_Balance_Quad)
        SendLog("info: CL1a " + FullCommand + " Time Balance = " + Time_Balance_Quad)
      Case "takeback"
        GameMoveNumber = GameMoveNumber - 1
        FENPositionstr = PositionHistory_Table(GameMoveNumber,ColorZbIdx(-1*SideToMove+2))
        ConstructPositionfromFEN()
        PositionHistory_Table(GameMoveNumber+1,ColorZbIdx(-1*SideToMove+2)) = ""
        PositionHistory_Table(GameMoveNumber+1,ColorZbIdx(SideToMove+2)) = ""
        SideToMove = -1 * SideToMove
        Board_Print_Routine()
      Case "time"
        Original_ClockTime = Val(Mid(FullCommand,i+1,5))
        Time_Balance = Original_ClockTime * 10                               ; xboard time is given in centi-seconds
        Time_Balance_Quad = Time_Balance
        PrintN("info: CL1a " + FullCommand + " Time Balance = " + Time_Balance_Quad)
        SendLog("info: CL1a " + FullCommand + " Time Balance = " + Time_Balance_Quad)
      Case "xboard"
      Default                                                                       ; any other
        If InputMove(FullCommand) = #False
          PrintN("info - ** Illegal move or unknown command: " + FullCommand)
        EndIf
    EndSelect
    
    Select Time_Balance
      Case 20001 To 60000
        MinDepth = 5
      Case 8000 To 20000
        MinDepth = 4
      Case 6000 To 7000
        MinDepth = 3
      Case 1000 To 5000
        MinDepth = 2
      Default
        MinDepth = 3
    EndSelect
    
    ;PrintN("info - ...In CommandLoop...ready to call ComputerMove...")
    
    If ComputerSide = SideToMove
      ;PrintN("info...In CommandLoop...calling ComputerMove...")
      ComputerMove()
      ComputerSide = #nil
    EndIf
    
  Until Ends = #True
EndProcedure 

Procedure  AlphaBetaX(AAlpha.w, ABeta.w, Distance.w)
  
  Protected BestValue.w, i.w, Value.w, Check.w
  Protected Condition1.b, Condition2.b
  
  NodeCount = NodeCount + 1
  MVar(Depth, Depth)\FromField = 0
  CurrentEval = AssessPosition(AAlpha, ABeta, SideToMove)
  Check = InCheck
  
  If (Check = #True) And (Depth + Distance < MaxExtension + 1)
    Condition1 = #True
  EndIf
  
  If (Depth >= 2) And (Depth + Distance < MaxExtension)
    Condition2 = #True
  EndIf
  
  If Condition2 And (ToField(Depth) = ToField(Depth - 1))
    Condition2 = #True
  Else
    Condition2 = #False
  EndIf
  
  If Condition2 And (CurrentEval >= AAlpha - 150) And (CurrentEval <= ABeta + 150)
    Condition2 = #True
  Else
    Condition2 = #False
  EndIf
  
  If Condition1 Or Condition2 
    Distance = Distance + 1
  EndIf
  If (Distance < -5) Or (CurrentEval = #MateValue - Depth) Or (Depth >= #CMaxDepth)
    ProcedureReturn CurrentEval
  EndIf
  If (CurrentEval >= ABeta) And (Distance + Check <= 1)
    ProcedureReturn CurrentEval
  EndIf
  GeneratePseudoLegalMovesFromTables(Distance)
  If Distance > 0
    BestValue = -#MateValue
  Else
    BestValue = CurrentEval
  EndIf
  
  i = NextBestMove()
  While i >= 0
    StartTime = ElapsedMilliseconds()
    PerformMove(i)

;   just testing different TT strategies
    ;If LookupPositionInTT(IncrementalZobristPositionKey) = #True

    ;If LookupPositionInTT(IncrementalZobristPositionKey) = #True And TpTable(TTZobristKeyIndex1)\TpEval >= ABeta
    ;  CurrentEval = TpTable(TTZobristKeyIndex1)\TPEval
      ;infoMsg = "info: AB1 - Transposition table hit - Zobrist key = " + Str(IncrementalZobristPositionKey) + " move = " + AlgBrd(MoveStack(i).FromField) + AlgBrd(MoveStack(i).ToField)
      ;infoMsg = infoMsg + " Eval = " + Str(CurrentEval) + " Depth = " + Str(Depth) + " hash type = " + Str(TpTable(TTZobristKeyIndex1).TPEvalTypeFlag)
      ;infoMsg = infoMsg + " TT Index = " + Str(TTZobristKeyIndex1) + " TT Hits = " + Str(TTLookupHitCount)
      ;If Depth <= 3 SendLog(infoMsg)
    ;Else
    CurrentEval = -1 * AlphaBetaX(-1 * ABeta, -1 * AAlpha, Distance - 1)
    
      ;StoreZobristTTEntry(IncrementalZobristPositionKey, MoveStack(i)\FromField, MoveStack(i)\ToField, CurrentEval, Depth, 4, AAlpha, ABeta)
      ;SendLog("info: AB1 - TT STORE - Zobrist key = " + Str(IncrementalZobristPositionKey) + " Depth = " + Str(Depth))
    ;EndIf
    
    alphabeta_count = alphabeta_count + 1
    infoMsg = "info: ABi - Depth = " + Str(Depth) + " Current move = " + AlgBrd(MoveStack(i)\FromField) + AlgBrd(MoveStack(i)\ToField) + "  Eval = " + Str(CurrentEval)
    If alphabeta_count % 3 = 0
      SendLog(infoMsg)
    EndIf

    UndoMove(i)
    TimerCheck()
    If CurrentEval > BestValue
      ;SendLog("info vz3 AlphaBeta: pruning 1 - Current best eval now = " + str(CurrentEval))
      BestValue = CurrentEval
      If CurrentEval >= ABeta
        ;SendLog("info vz3 AlphaBeta: pruning 2 - Current best eval now = " + str(CurrentEval))
        If Distance > 0 
          CopyMainVariant(i)
          Break
        EndIf
      EndIf
    EndIf
    If CurrentEval > AAlpha
      If Distance > 0 
        CopyMainVariant(i)
        AAlpha = CurrentEval
      EndIf
    EndIf
    i = NextBestMove()
  Wend
  
  If (CurrentEval >= ABeta) And (i >= 0)
    KillerTab(Depth)\Killer2 = KillerTab(Depth)\Killer1
    KillerTab(Depth)\Killer1\FromField = MoveStack(i)\FromField
    KillerTab(Depth)\Killer1\ToField = MoveStack(i)\ToField
    KillerTab(Depth)\Killer1\Eval = MoveStack(i)\Value
  EndIf
  If BestValue = -(#MateValue - (Depth + 1))
    If Check = #False
      ProcedureReturn 0
    EndIf
  EndIf
  ProcedureReturn BestValue
EndProcedure

Procedure  AssessPosition(AAlpha.w, ABeta.w, Side.w )

  If Side = #WhiteX
    If SquareIsAttacked(BKing, #WhiteX, 0) = #True
      ProcedureReturn #MateValue - Depth
    EndIf
    InCheck = SquareIsAttacked(WKing, #BlackX, 0)
  Else
    If SquareIsAttacked(WKing, #BlackX, 0) = #True
      ProcedureReturn #MateValue - Depth 
    EndIf
    InCheck = SquareIsAttacked(BKing, #WhiteX, 0)
  EndIf

  Evaluate_Position_With_PSTs()

  If Side = #WhiteX
    ProcedureReturn Total_PST_Eval
  Else
    ProcedureReturn -1 * Total_PST_Eval
  EndIf

EndProcedure 


Procedure  SquareIsAttacked(TargetSq.w, Side.w, FullCountFlag.w)

  Protected SqCnt, NS, A_Dir
  Global Dim NonSliders.w(3)
  Global Dim Dir_Start.w(3)
  Global Dim Dir_End.w(3)
  
  NonSliders(1) = 1 : NonSliders(2) = 4 : NonSliders(3) = 6
  Dir_Start(1) = 3 : Dir_Start(2) = 1 : Dir_Start(3) = 1
  Dir_End.w(1) = 4 : Dir_End.w(2) = 8 : Dir_End.w(3) = 8

  #WN = 4 : #WK = 6 : #WP = 1 : #WQ = 5
  #Max_Move_Dirs = 8 : #EmptySq = 0

  SquareAttackCount = 0
  ;SquareIsAttacked = #False
  QueenIsSquareAttackerFlag = #False
  For NS = 1 To 3
    For The_Dir = Dir_Start(NS) To Dir_End(NS)                                 ; now pawn or knight or king attacks (non-sliders)
      A_Dir = Piece_Dirs_Table(NonSliders(NS),The_Dir)
      TheSq = TargetSq - Side * A_Dir
      If Board(TheSq) <> #EmptySq And Board(TheSq) <> #EdgeSq
        ThePiece = Board(TheSq)
        If ThePiece = Side * NonSliders(NS)
          ;SquareIsAttacked = #True
          SquareAttackCount = SquareAttackCount + 1
          If FullCountFlag = #True
            If SquareAttackCount >= 2
               ProcedureReturn #True
            EndIf
            ; Print "Non-Sliders:  Piece = ";ThePiece;" Direction = ";A_Dir;"  Attack count incremented to ";SquareAttackCount
          Else
            ProcedureReturn #True
          EndIf
        EndIf
      EndIf
    Next The_Dir
  Next NS

  For The_Dir = 1 To #Max_Move_Dirs                                             ; all other attacks (sliders)
    For SqCnt = 1 To 7
      A_Dir = Piece_Dirs_Table(#WQ,The_Dir) * SqCnt
      TheSq = TargetSq + A_Dir
      If Board(TheSq) = #EdgeSq
        Break
      Else
        ThePiece = Board(TheSq)
        If ThePiece <> #EmptySq
          If Side * ThePiece > 0
            Select The_Dir
              Case 1,2,3,4                                                      ; diagonal directions
                Select Abs(ThePiece)
                  Case 1,2,4,6
                    ; pawn or rook or knight or king do nothing, not diagonal or slider
                    Break
                  Case 3,5
                    ;SquareIsAttacked = #True
                    SquareAttackCount = SquareAttackCount + 1
                    If Abs(ThePiece) = #WQ 
                      QueenIsSquareAttackerFlag = #True
                    EndIf
                    If FullCountFlag = #True
                      If SquareAttackCount >= 2 
                        ProcedureReturn #True
                      EndIf
                      ; Print "Sliders:  Piece = ";ThePiece;" Direction = ";A_Dir;" Attack count incremented to ";SquareAttackCount
                      Break
                    Else
                      ProcedureReturn #True
                    EndIf
                EndSelect
              Case 5,6,7,8                                                      ; rank and file directions
                Select Abs(ThePiece)
                  Case 1,3,4,6
                    ; pawn or bishop or knight or king do nothing, not rank and file or slider
                    Break
                  Case 2,5
                    ;SquareIsAttacked = #True
                    SquareAttackCount = SquareAttackCount + 1
                    If Abs(ThePiece) = #WQ 
                      QueenIsSquareAttackerFlag = #True
                    EndIf
                    If FullCountFlag = #True
                      If SquareAttackCount >= 2 
                        ProcedureReturn #True
                      EndIf
                      ; Print "Sliders:  Piece = ";ThePiece;" Direction = ";A_Dir;" Attack count incremented to ";SquareAttackCount
                      Break
                    Else
                      ProcedureReturn #True
                    EndIf
                EndSelect
            EndSelect
          Else
            Break
          EndIf
        EndIf
      EndIf
    Next SqCnt
  Next The_Dir
  
  ProcedureReturn #False
EndProcedure


Procedure  LookupPositionInTT(ZobristPositionKey.q)

  TTZobristKeyIndex1 = IncrementalZobristPositionKey % #HashModuloValue
  ;If TpTable(TTZobristKeyIndex1)\TpZobKey = IncrementalZobristPositionKey And TpTable(TTZobristKeyIndex1)\TpDepth >= Depth
    ; TTLookupHitCount = TTLookupHitCount + 1
    ; ProcedureReturn #True
 
  ;Else
    ProcedureReturn #False
  ;EndIf

EndProcedure


Procedure Board_Print_Routine()

  Protected chessrank.w, chessfile.w

  SendLog("info" + #CRLF$)
  SqCount = 0
  For chessrank = 9 To 2 Step -1
    For chessfile = 1 To 8
    BoardSq = chessrank * 10 + chessfile
    If Board(BoardSq) <> #EdgeSq
      SqCount = SqCount + 1
      ThePiece = Board(BoardSq)
       Select ThePiece
         Case 0
           If chessfile = 1
             Print("info:  -  ")
           Else
             Print(" -  ")
           EndIf
         Case 1,2,3,4,5,6
           If chessfile = 1
             Print("info:  " + WhitePieces(ThePiece) + "  ")
           Else
             Print(" " + WhitePieces(ThePiece) + "  ")
           EndIf
         Case -1,-2,-3,-4,-5,-6
           If chessfile = 1
             Print("info:  " + BlackPieces(-1 * ThePiece) + "  ")
           Else
             Print(" " + BlackPieces(-1 * ThePiece) + "  ")
           EndIf
      EndSelect
      If SqCount = 8
        SqCount = 0
        ;Print("")
      EndIf
    EndIf
    Next ;chessfile
    Print(Space(5)) : For chessfile = 1 To 8 : BoardSq = chessrank * 10 + chessfile : Print(Str(BoardSq) + Space(2)) : Next
    Print(Space(5)) : For chessfile = 1 To 8 : BoardSq = chessrank * 10 + chessfile : Print(AlgBrd(BoardSq) + Space(2)) : Next
    PrintN("info " + #CRLF$)
  Next ;chessrank
  ;Print("")
  PrintN("info ")

EndProcedure 

Procedure ComputerMove()
  Protected tmp.MoveType
  Protected Value.w, Check.w, Distance.w, LAlpha.w, LBeta.w, BestValue.w, i.w, j.w
  Protected LFrom.w, LTo.w, Z.w, zdepth1.w, Avg_Move_Time.q
  Protected LMove.s, L1.s, L2.s
  Protected MoveList.s
  
  InitGameTree()
  TimerCheck_Count = 0 : movegen_count = 0 : alphabeta_count = 0 : log_count = 0
  Time_Balance = Original_ClockTime
  For z1 = 1 To 12
    PV(z1)\FromField = 0
    PV(z1)\ToField = 0
    PV(z1)\Eval = 0
  Next z1
  
  ;PrintN("...in ComputerMove at top...")

  If GameMoveNumber > 50 
    AvgGameLengthMoves = GameMoveNumber + 25
  EndIf
  StartTime = ElapsedMilliseconds()
  CurrentEval = AssessPosition(-1 * #MateValue, #MateValue, SideToMove)
  TimerCheck()
  If CurrentEval = #MateValue
    SendLog("info: Checkmate!")
    ProcedureReturn
  EndIf
  Check = InCheck
  NodeCount = 0
  Z = 0
  
  StartTime = ElapsedMilliseconds()

  GeneratePseudoLegalMovesFromTables(1)
  For Distance = 1 To MinDepth
    If Distance = 1
      LAlpha = -1 * #MateValue
      LBeta = #MateValue
    Else
      LBeta = LAlpha + 100
      LAlpha = LAlpha - 100
    EndIf
    
    TimerCheck()
    If GameMoveNumber <= #EarlyGameMoveNumberCutoff1
      MaxExtension = Distance + #PlyExtensionLarge
    Else
      If Time_Balance > 5000 Or MaterialTotal(1) <= #SparseEndgameMaterial
        MaxExtension = Distance + #PlyExtensionLarge
      Else
        MaxExtension = Distance + #PlyExtensionMinimal
      EndIf
    EndIf

    SendLog("info: CM1 Time Balance = " + Time_Balance + " Distance = " + Str(Distance) + " MaxEntension = " + MaxExtension + " Material = " + MaterialTotal(1))

    For i = 0 To StackLimit(1) - 1
      StartTime = ElapsedMilliseconds()
      CaptureMoveFlag = #False
      MaterialOKFlag = 0
      MVar(Depth, Depth)\FromField = 0
      DisplayMove(i)

      LFrom = MoveStack(i)\FromField
      LTo = MoveStack(i)\ToField
      CurrentMovingPiece = Board(LFrom)
      infoMsg = "info: CMi1 - Depth = " + Str(Depth) + " Current move = " + AlgBrd(LFrom) + AlgBrd(Lto) + "  TT Entries = " + Str(TTEntryCount)
      SendLog(infoMsg)

      PerformMove((i))

;      If LookupPositionInTT(IncrementalZobristPositionKey) = #true AND abs(TpTable(TTZobristKeyIndex1).TpEval) >= LAlpha
       If LookupPositionInTT(IncrementalZobristPositionKey) = #True And Abs(TpTable(TTZobristKeyIndex1)\TpEval) >= LBeta
        CurrentEval = TpTable(TTZobristKeyIndex1)\TPEval
        infoMsg = "info: CM1 - Transposition table hit - Zobrist key = " + Str(IncrementalZobristPositionKey) + " move = " + AlgBrd(LFrom) + AlgBrd(LTo)
        infoMsg = infoMsg + " Eval = " + Str(CurrentEval) + " Depth = " + Str(Depth) + " hash type = " + Str(TpTable(TTZobristKeyIndex1)\TPEvalTypeFlag)
        infoMsg = infoMsg + " TT Index = " + Str(TTZobristKeyIndex1) + " TT Hits = " + Str(TTLookupHitCount)
;       SendLog(infoMsg)
       Else
        CurrentEval = -1 * AlphaBetaX(-1 * LBeta, -1 * LAlpha, Distance - 1)
        TimerCheck()
        If Abs(CurrentMovingPiece) = #WK And (GameMoveNumber <= 30 Or MaterialTotal(Depth) >= #MiddleGameMaterial1)
           Select -1 * SideToMove
            Case #WhiteX
              If LFrom = #e1 And (LTo = #G1 Or Lto = #C1)
                CurrentEval = CurrentEval + #CastlingBonus
              Else
                CurrentEval = CurrentEval - #EarlyKingMovePenalty
              EndIf 
            Case #BlackX
              If LFrom = #E8 And (LTo = #G8 Or Lto = #C8)
                CurrentEval = CurrentEval + #CastlingBonus
              Else
                CurrentEval = CurrentEval - #EarlyKingMovePenalty
              EndIf
          EndSelect
        EndIf
        StoreZobristTTEntry(IncrementalZobristPositionKey, LFrom, LTo, CurrentEval, Depth, 4, LAlpha, LBeta)
        ;SendLog("info: CM1 - TT STORE - Zobrist key = " + str(IncrementalZobristPositionKey) + " Depth = " + str(Depth))
      EndIf

      ;SendLog("info: CM1 - After 1st eval - SideToMove = " + SideToMove + " Depth = " + Depth)
 
      infoMsg = "info: CMi2 - Depth = " + Str(Depth) + " Current move = " + AlgBrd(LFrom) + AlgBrd(Lto) + "  Eval = " + Str(CurrentEval)
      SendLog(infoMsg)

      UndoMove((i))
      If i = 0
        If CurrentEval < LAlpha
          LAlpha = -1 * #MateValue
          LBeta = CurrentEval
          PerformMove(i)
          CurrentEval = -1 * AlphaBetaX(-1 * LBeta, -1 * LAlpha, Distance - 1)
          UndoMove((i))
        ElseIf CurrentEval >= LBeta
          LAlpha = CurrentEval
          LBeta = #MateValue
          PerformMove(i)
          CurrentEval = -1 * AlphaBetaX(-1 * LBeta, -1 * LAlpha, Distance - 1)
          UndoMove(i)
        EndIf
        LAlpha = CurrentEval
        LBeta = LAlpha + 1
        DisplayMove(i)
        CopyMainVariant(i)
      Else
        If CurrentEval > LAlpha
          BestValue = LAlpha
          LAlpha = CurrentEval
          LBeta = #MateValue
          PerformMove(i)

           If LookupPositionInTT(IncrementalZobristPositionKey) = #True
             CurrentEval = TpTable(TTZobristKeyIndex1)\TPEval
             infoMsg = "info: CM2 - Transposition table hit - Zobrist key = " + Str(IncrementalZobristPositionKey) + " move = " + AlgBrd(LFrom) + AlgBrd(LTo)
             infoMsg = infoMsg + " Eval = " + Str(CurrentEval) + " Depth = " + Str(Depth) + " hash type = " + Str(TpTable(TTZobristKeyIndex1)\TPEvalTypeFlag)
             infoMsg = infoMsg + " TT Index = " + Str(TTZobristKeyIndex1)
;            SendLog(infoMsg)
           Else
            CurrentEval = -1 * AlphaBetaX(-1 * LBeta, -1 * LAlpha, Distance - 1)
            StoreZobristTTEntry(IncrementalZobristPositionKey, LFrom, LTo, CurrentEval, Depth, 4, LAlpha, LBeta)
            SendLog("info: CM2 - TT STORE - Zobrist key = " + Str(IncrementalZobristPositionKey) + " Depth = " + Str(Depth))
           EndIf

          UndoMove(i)
          If CurrentEval > BestValue
            LAlpha = CurrentEval
            LBeta = LAlpha + 1
            CopyMainVariant(i)
            tmp = MoveStack(i)
            For j = i To 1 Step -1
              MoveStack(j) = MoveStack(j - 1)
            Next j
            MoveStack(0) = tmp
            PV(Depth)\FromField = MoveStack(0)\FromField
            PV(Depth)\ToField = MoveStack(0)\ToField
            PV(Depth)\Eval = MoveStack(0)\Value
          EndIf
        EndIf
      EndIf
    Next i
    
    
    TimerCheck()
    
    
    If Time_Balance > 0
      If Time_Balance_Quad <= #Min_Time_Value
        SendLog("info: Very Low Time alert - Time left = " + Str(Time_Balance_Quad) + " Distance = " + Str(Distance))
        Break
      Else
        Avg_Move_Time = (Time_Balance_Quad/(AvgGameLengthMoves - GameMoveNumber + 1)) * 1.4
          SendLog("info: Average move time * 1.4 = " + Str(Avg_Move_Time) + " Distance = " + Str(Distance))
          ; Break
        
      EndIf
    EndIf

    PV(Depth)\FromField = MoveStack(0)\FromField
    PV(Depth)\ToField = MoveStack(0)\ToField
    PV(Depth)\Eval = MoveStack(0)\Value

  Next Distance


  If LAlpha > -1 * (#MateValue - 1)
    DisplayMove(0)

    ZobristInCheckFlag = #False
    KingOnBackRankFlag = #False
    If SideToMove = #WhiteX
      If WKing <= #H1 
        KingOnBackRankFlag = #True
      EndIf
      ZobristInCheckFlag = SquareIsAttacked(WKing, #BlackX, 0)
    Else
      If BKing >= #A8 
        KingOnBackRankFlag = #True
      EndIf
      ZobristInCheckFlag = SquareIsAttacked(BKing, #WhiteX, 0)
    EndIf
    CountKingEscapeSquares()

    SecondBestMove = MoveStack(1)
    SecondBestMovePiece = Board(MoveStack(1)\FromField)
    If PseudoLegalMove_IsLegal(SecondBestMove\FromField, SecondBestMove\ToField, SideToMove) = #True
      SecondBestMoveIsLegalFlag = #True
    Else
      SecondBestMoveIsLegalFlag = #False
    EndIf

    PerformMove(0)
    ConstructNonZobristBoardStrings(GameMoveNumber)
    ConstructZobristPositionKey(SideToMove)                                                          ; for now just scanning whole board instead of incremental zobrist key update in PerformMove()

    If Depth = 1                                                                  
      If SideToMove = #BlackX
        GameMoveNumber = GameMoveNumber + 1
      EndIf
        ; now in PerformMove()
      RepTable(ColorZbIdx(-1*SideToMove+2),GameMoveNumber)\RepZobKey = CurrentPositionZobristKey
      RepTable(ColorZbIdx(-1*SideToMove+2),GameMoveNumber)\RepMove\rptFromSq = LFrom
      RepTable(ColorZbIdx(-1*SideToMove+2),GameMoveNumber)\RepMove\rptToSq = LTo
      infoMsg = "info: GameMoveNumber = " + Str(GameMoveNumber) + "  Side to move = " + Str(SideToMove) + "  CurrentPositionZobristKey = " + Str(CurrentPositionZobristKey)
      infoMsg = infoMsg + " TT Hits = " + Str(TTLookupHitCount)
      SendLog(infoMsg)
    EndIf

    ConstructFENfromPosition(SideToMove * -1)
    PositionHistory_Table(GameMoveNumber, ColorZbIdx(-1*SideToMove+2)) = FENpositionstr
    SendLog("info - FEN = " + FENpositionstr + "  Depth = " + Str(Depth) + "  TT Entries = " + Str(TTEntryCount))

    If GameMoveNumber < 13  Or (ZobristInCheckFlag = #True And SecondBestMoveIsLegalFlag = #False) Or (ZobristInCheckFlag = #True And KingOnBackRankFlag = #True)
      LFrom = MoveStack(0)\FromField
      LTo = MoveStack(0)\ToField
      FieldNotation(LFrom)
      L1 = PartMove
      FieldNotation(LTo)
      L2 = PartMove
      LMove =  L1 + L2 
      If MoveStack(0)\PromotedPiece <> #nil
        LMove = LMove + LCase(FigSymbol(MoveStack(0)\PromotedPiece))
      EndIf
    Else
      ;If (Board(MoveStack(0).ToField) > 0 and MaterialBalance(1) >= 0) or (Board(MoveStack(0).ToField) < 0 and MaterialBalance(1) <= -1 * MatP)
      ;EndIf
       MaterialOKFlag = #True                                                                          ; move to inside above If statement to test material conditions

      ZobristRepeatFlag = #False                                                                             ; check the position in Zobrist Rep table
      For z1 = GameMoveNumber - 2 To GameMoveNumber - 12 Step -1
        If CurrentPositionZobristKey = RepTable(ColorZbIdx(-1*SideToMove+2),z1)\RepZobKey
          ZobristRepeatFlag = #True
          RepeatPositionZobristKey = CurrentPositionZobristKey
          z4 = z1
          Break
        EndIf
      Next z1

      ;ZobristRepeatFlag = #False                                 ; temp patch if enabled, Zobrist 2-fold avoidance code below will NOT run
      If (MaterialOKFlag = #True And ZobristRepeatFlag = #True)  ;very kludgy 2-fold avoidance - do second-best move
        UndoMove(0)
        PerformMove(1)
        ;PrintN("***** Making second-best move!*****")
        LFrom = MoveStack(1)\FromField
        LTo = MoveStack(1)\ToField
        FieldNotation(LFrom) : L1 = PartMove
        FieldNotation(LTo) : L2 = PartMove
        LMove = L1 + L2
        If MoveStack(1)\PromotedPiece <> #nil
          LMove = LMove + LCase(FigSymbol(MoveStack(1)\PromotedPiece))
        EndIf
        ConstructZobristPositionKey(SideToMove)
        RepTable(ColorZbIdx(-1*SideToMove+2),GameMoveNumber)\RepZobKey = CurrentPositionZobristKey
        RepTable(ColorZbIdx(-1*SideToMove+2),GameMoveNumber)\RepMove\rptFromSq = LFrom
        RepTable(ColorZbIdx(-1*SideToMove+2),GameMoveNumber)\RepMove\rptToSq = LTo

        infoMsg = "info: TwoFold rep avoidance via NonZobrist board strings - GameMove = " + Str(GameMoveNumber)
        infoMsg = infoMsg + " Material Balance = " + Str(MaterialBalance(1))
        infoMsg = infoMsg + " Board 1 = " +  NonZobristBoardStr(GameMoveNumber) + " Board 2 = " + NonZobristBoardStr(GameMoveNumber-2)
        SendLog(infoMsg)
        If ZobristRepeatFlag = #True
          infoMsg = "info: TwoFold rep avoidance via Zobrist board keys - GameMove = " + Str(GameMoveNumber)
          infoMsg = infoMsg + " Material Balance = " + Str(MaterialBalance(1))
          infoMsg = infoMsg + " RepeatPositionZobristKey = " +  Str(RepeatPositionZobristKey) + "  Matching Zobrst key move number = " + Str(z4)
          infoMsg = infoMsg + "  RepTable value = " + Str(RepTable(ColorZbIdx(-1*SideToMove+2),z4)\RepZobKey)
          SendLog(infoMsg)
        EndIf
      Else
        LFrom = MoveStack(0)\FromField
        LTo = MoveStack(0)\ToField
        FieldNotation(LFrom) : L1 = PartMove
        FieldNotation(LTo) : L2 = PartMove
        LMove = L1 + L2
        If MoveStack(0)\PromotedPiece <> #nil
          LMove = LMove + LCase(FigSymbol(MoveStack(0)\PromotedPiece))
        EndIf
      EndIf
    EndIf
    
    ;PrintN("info")
    Board_Print_Routine()
    
    ; ************************ ENGINE SENDs (PRINTS) ITS MOVE HERE **********************
    SendLog("MiniMaxkp move " + LMove)
    SendLog("info MiniMaxkp : CM3 Node count = " + Str(NodeCount) + "  TT Entries = " + Str(TTEntryCount))
    SendLog("info MiniMaxkp : CM4 Eval = " + MoveStack(0)\Value)
    
    PrintN("move " + LMove)
    PrintN("info: CM3 Node count = " + Str(NodeCount) + "  TT Entries = " + Str(TTEntryCount))
    PrintN("info: CM4 Eval = " + MoveStack(0)\Value)


    If MoveStack(1)\FromField > 0
      SendLog("info: CM5a 2nd best move? = " + AlgBrd(MoveStack(1)\FromField) + AlgBrd(MoveStack(1)\ToField) + " Eval = " + MoveStack(1)\Value)
    EndIf
    
    MoveList = ""
    For Z = 0 To StackLimit(1)-1
      MoveList = MoveList + " " + AlgBrd(MoveStack(Z)\FromField) + AlgBrd(MoveStack(Z)\ToField) + " " + Str(MoveStack(Z)\Value)
    Next Z
    SendLog("info: CM5b " + " legalmove count = " + Str(StackLimit(1)))
    SendLog("info: CM6 legalmoves = " + MoveList)
    SendLog("info: CM7 Zobrist Incremental Key = " + Str(IncrementalZobristPositionKey) + " Zobrist Full Key = " + Str(CurrentPositionZobristKey))

    infoMsg = "info: MVar PVa = "
    For z1 = 1 To 12
      If MVar(z1,z1)\FromField <> 0
        infoMsg = infoMsg + AlgBrd(MVar(z1,z1)\FromField) + AlgBrd(MVar(z1,z1)\ToField) + " "
      Else
        Break
      EndIf
    Next z1
    SendLog(infoMsg)

    infoMsg = "info: Killer1 PVb = "
    For z1 = 1 To 12
      If KillerTab(z1)\Killer1\FromField <> 0
        infoMsg = infoMsg + AlgBrd(KillerTab(z1)\Killer1\FromField) + AlgBrd(KillerTab(z1)\Killer1\ToField) + " "
      Else
        Break
      EndIf
    Next z1
    ;SendLog(infoMsg)
 
    infoMsg = "info: Killer2 PVc = "
    For z1 = 1 To 11
      If KillerTab(z1)\Killer2\FromField <> 0
        infoMsg = infoMsg + AlgBrd(KillerTab(z1)\Killer2\FromField) + AlgBrd(KillerTab(z1)\Killer2\ToField) + " "
      Else
        Break
      EndIf
    Next z1
    ;SendLog(infoMsg)

    If LAlpha >= #MateValue - 10
      SendLog("info - I checkmate in " + Str((#MateValue - 2 - LAlpha) / 2) + " moves.")
    Else
      If LAlpha <= -1 * #MateValue + 10
        SendLog("info - I am checkmated in " + Str((LAlpha + #MateValue - 1) / 2) + " moves.")
      EndIf
    EndIf
  Else
    If Check = #True
      SendLog("info -  Congratulations are due: You have checkmated " + Program_Name + "!")
    Else
      SendLog("info - Stalemate! It is a draw!")
    EndIf
  EndIf
EndProcedure 


Procedure CopyMainVariant(CurrMove.w)
  Protected i.w
  MVar(Depth, Depth)\FromField = MoveStack(CurrMove)\FromField
  MVar(Depth, Depth)\ToField = MoveStack(CurrMove)\ToField
  MVar(Depth, Depth)\Eval = MoveStack(CurrMove)\Value
  PV(Depth)\FromField = MoveStack(CurrMove)\FromField
  PV(Depth)\ToField = MoveStack(CurrMove)\ToField
  PV(Depth)\Eval = MoveStack(CurrMove)\Value
  SendLog("info: CMV Depth = " + Depth + " " + AlgBrd(MoveStack(CurrMove)\FromField) + "-" + AlgBrd(MoveStack(CurrMove)\ToField))
  i = 0
  Repeat
    i = i + 1
    MVar(Depth, Depth + i) = MVar(Depth + 1, Depth + i)
  Until MVar(Depth + 1, Depth + i)\FromField = 0
EndProcedure 


Procedure ConstructNonZobristBoardStrings(Z.w)
  Protected i.w
  
  NonZobristBoardStr(Z) = ""
  For i = 1 To 99
    If Board(i) >= 0
      If Board(i) = #Edge  
        NonZobristBoardStr(Z) = NonZobristBoardStr(Z) + "*"           ;offboard (edge) square
      Else
        NonZobristBoardStr(Z) = NonZobristBoardStr(Z) + WhitePieces(Board(i))
      EndIf
    Else
      NonZobristBoardStr(Z) = NonZobristBoardStr(Z) + BlackPieces(-1 * Board(i))
    EndIf
  Next i
  SendLog("info: NonZobrist board string = " + NonZobristBoardStr(Z))
EndProcedure 


Procedure ConstructFENfromPosition(ColorOnMove.w)
  Protected blanksquarecount.w, BoardSq.w, chessrank.w, chessfile.w, WhitecastleFlag.w, BlackcastleFlag.w

  FENpositionstr = ""
  blanksquarecount = 0

  For chessrank = 9 To 2 Step -1
    For chessfile = 1 To 8
      BoardSq = chessrank * 10 + chessfile
      If Board(BoardSq) <> 0
        If blanksquarecount > 0
          FENpositionstr = FENpositionstr + Str(blanksquarecount)
          blanksquarecount = 0
        EndIf
        If Board(BoardSq) < 0 
          FENpositionstr = FENpositionstr + BlackPieces(-1 * Board(BoardSq))
        Else
          FENpositionstr = FENpositionstr + WhitePieces(Board(BoardSq))
        EndIf
      Else
        blanksquarecount = blanksquarecount + 1
      EndIf
    Next chessfile
    If blanksquarecount > 0
      FENpositionstr = FENpositionstr + Str(blanksquarecount)
      If chessrank <> 2
        FENpositionstr = FENpositionstr + "/"
      EndIf
      blanksquarecount = 0
    Else
      If BoardSq <> 28 
        FENpositionstr = FENpositionstr + "/"
      EndIf
    EndIf
  Next chessrank

  If ColorOnMove = #WhiteX
    FENpositionstr = FENpositionstr + " w "
  Else
    FENpositionstr = FENpositionstr + " b "
  EndIf

  WhitecastleFlag = #False
  If Board(25) = #WK
    If Board(28) = #WR
      FENpositionstr = FENpositionstr + "K"
      WhitecastleFlag = #True
    EndIf
    If Board(21) = #WR
      FENpositionstr = FENpositionstr + "Q"
      WhitecastleFlag = #True
    EndIf
  EndIf

  BlackcastleFlag = #False
  If Board(95) = #BK
    If Board(98) = #BR
      FENpositionstr = FENpositionstr + "k"
      BlackcastleFlag = #True
    EndIf
    If Board(91) = #BR
      FENpositionstr = FENpositionstr + "q"
      BlackcastleFlag = #True
    EndIf
  EndIf

  If WhitecastleFlag = #False And BlackcastleFlag = #False
    FENpositionstr = FENpositionstr + "-"
  EndIf

  ;not checking enpassant conditions

  FENpositionstr = FENpositionstr + " - "

  ;not checking half-moves since last capture or pawn move for fifty move rule, use a random number like 11

  FENpositionstr = FENpositionstr + "11 "
  FENpositionstr = FENpositionstr + Str(GameMoveNumber) ;actual game move number

EndProcedure 


Procedure ConstructPositionfromFEN()
  Protected blanksquarecount.w, BoardSq.w, chessrank.w, chessfile.w, slashposition.w, WhitecastleFlag.w, BlackcastleFlag.w
  Protected BlackPieceNo.w, WhitePieceNo.w, EmptySquaresCount.w
  Protected tempFENstr.s, FEN_ColorToMove.s
  
  Dim FENrankstr.s(9)
  
  tempFENstr = FENPositionStr
  FEN_ColorToMove = Mid(tempFENstr,FindString(tempFENstr," ")+1,1)
  If FEN_ColorToMove = "w"
    SideToMove = #WhiteX
  Else
    SideToMove = #BlackX
  EndIf
  GameMoveNumber = Val(Trim(Mid(tempFENstr,Len(tempFENstr)-1,2)))
  SendLog("info: CPfF - length of FEN string = " + Str(Len(tempFENStr)) + " GameMoveNumber = " + Str(GameMoveNumber))
  ; Not picking up any castling status yet


  For chessrank = 9 To 2 Step -1
    If chessrank <> 2
      slashposition = FindString(tempFENstr,"/")
      FENrankstr(chessrank) = Left(tempFENstr,slashposition - 1)
      tempFENstr = Mid(tempFENstr,slashposition+1,Len(tempFENstr)-slashposition)
    Else
      FENrankstr(chessrank) = tempFENstr
    EndIf
    SendLog("info - Rank " + FENrankstr(chessrank) + "  Remaining FEN part = " + tempFENstr)
  Next chessrank


  For chessrank = 9 To 2 Step -1
  
    chessfile = 1
    While chessfile <= 8
      BoardSq = chessrank * 10 + chessfile
      EmptySquaresCount = FindString("12345678",Left(FENrankstr(chessrank),1))
      BlackPieceNo = FindString("prbnqk",Left(FENrankstr(chessrank),1))
      WhitePieceNo = FindString("PRBNQK",Left(FENrankstr(chessrank),1))
      If EmptySquaresCount > 0                                       ;  number of empty squares
        For z4 = 1 To EmptySquaresCount
         Board(BoardSq) = 0
         chessfile = chessfile + 1
         BoardSq = chessrank * 10 + chessfile
        Next z4
        EmptySquaresCount = 0
      Else
        If BlackPieceNo > 0                                          ; it is a Black Piece
          Board(BoardSq) = -1 * BlackPieceNo
          BlackPieceNo = 0
        Else                                               
          If WhitePieceNo > 0 
            Board(BoardSq) = WhitePieceNo          ; it is a White Piece or a bad FEN
          EndIf
          WhitePieceNo = 0
        EndIf
        chessfile = chessfile + 1
      EndIf
      FENrankstr(chessrank) = Mid(FENrankstr(chessrank),2,Len(FENrankstr(chessrank))-1)
      SendLog("info: CPfF - rank " + Str(chessrank) + " " + FENrankstr(chessrank))
    Wend
    
    infoMsg = "info: rank " + Str(chessrank) + " squares = "
    For z4 = 1 To 8 
      infoMsg = infoMsg + " " + Str(Board(chessrank*10+z4))
    Next z4
    SendLog("info: FEN Row squares = " + infoMsg)
  Next chessrank

EndProcedure 



Procedure CountKingEscapeSquares()
                                    
Protected CurrentKingSqr.w, KingEscapeSqr.w

If SideToMove = #WhiteX
  CurrentKingSqr = WKing
Else
  CurrentKingSqr = BKing
EndIf

KingEscapeSqrCount = 0
For z1 = 1 To #Max_Move_Dirs                                        ; currently only using 1st six directions (really 5)
  KingEscapeSqr = CurrentKingSqr + Piece_Dirs_Table(#WK,z1)
  If Board(KingEscapeSqr) <> #EdgeSq
    If Board(KingEscapeSqr) * -1 * SideToMove >= 0
      If SquareIsAttacked(KingEscapeSqr,-1 * SideToMove, 0) = #False
        KingEscapeSqrCount = KingEscapeSqrCount + 1
      EndIf
    EndIf
  EndIf
Next z1

EndProcedure 



Procedure Evaluate_Position_With_PSTs()

  ; dim GamePhaseInc.w(1 to 6) = {0,2,1,1,4,0}                          note - defined globally at program start (P,R,B,N,Q,K)

  Protected mgPhase.w, egPhase.w, TempKingSqr.w, DoubledPawnFlag.w, BackRankWeakFlag.w, WhitePassedPawnBonusFlag.w, BlackPassedPawnBonusFlag.w
  Protected Eval_PST_White_mg.w, Eval_PST_White_eg.w, Eval_PST_Black_mg.w, Eval_PST_Black_eg.w, Eval_mg.w, Eval_eg.w

  Eval_PST_White_mg = 0  : Eval_PST_Black_mg = 0  : Eval_PST_White_eg = 0  : Eval_PST_Black_eg = 0 : mgPhase = 0  : egPhase = 0  :  Total_PST_Eval = 0

    BackRankWeakFlag = #True                                                                   ; this eval item is temporarily disabled (set to #False) for debugging
    WhitePassedPawnBonusFlag = #False
    BlackPassedPawnBonusFlag = #False
    For TheSq = #a1 To #h8
      If Board(TheSq) <> #EdgeSq And Board(TheSq) <> #EmptySq
        RawPiece = Board(TheSq)
        If RawPiece > 0
          mgPhase = mgPhase + gamePhaseInc(RawPiece)
        Else
          mgPhase = mgPhase + gamePhaseInc(-1 * RawPiece)
        EndIf
        DoubledPawnFlag = #False

         Select -1 * SideToMove
          Case #WhiteX
            If RawPiece = #WK                    ; make sure we know where King is
              TempKingSqr = TheSq
            Else
              TempKingSqr = WKing                
            EndIf
              If TempKingSqr <= #H1                                                         ; kludgy check for no rook back rank weakness, needs improving later
               Select TheSq
                Case #a1 To #g1
                  If Board(TheSq) = #WR And TheSq < TempKingSqr 
                    BackRankWeakFlag = #False
                    If Depth <= 2 
                      ;SendLog("info: PST - SideToMove = " + str(SideToMove) + " Depth = " + str(Depth) + " BackRankWeakFlag = " + str(BackRankWeakFlag))
                    EndIf 
                 EndIf
                Default
                  ; do nothing, not back Rank square
              EndSelect
            Else
              BackRankWeakFlag = #False
            EndIf
          Case #BlackX
            If RawPiece = #BK 
              TempKingSqr = TheSq 
            Else 
              TempKingSqr = BKing
            EndIf
            If TempKingSqr >= #A8
               Select TheSq
                Case #a8 To #g8
                  If Board(TheSq) = #BR And TheSq < TempKingSqr
                    BackRankWeakFlag = #False
                  EndIf
                Default
                  ; do nothing, not back Rank square
              EndSelect
            Else
              BackRankWeakFlag = #False
            EndIf
        EndSelect

         Select Sign(RawPiece)
          Case #WhiteX
            If RawPiece = #WP
              If Board(TheSq+10) = #WP Or Board(TheSq+20) = #WP
                DoubledPawnFlag = #True
              EndIf
              If TheSq >= #A5 And TheSq <= #H7                                                             ; look for possible passed pawns on 5th or 6th or 7th rank
                WhitePassedPawnBonusFlag = #True
                If TheSq <= #H6                                                                           ; if square gt h6 white pawn is already passed on 7th rank, no pawn blockers possible
                  For z1 = 1 To 6
                     If WPassPawnBlockSqrs(TheSq,z1) <> 0
                       If Board(WPassPawnBlockSqrs(TheSq,z1)) = #BP 
                         WhitePassedPawnBonusFlag = #False
                         Break
                       EndIf
                     Else
                       Break
                     EndIf
                  Next z1
                EndIf
              EndIf
            EndIf
            Eval_PST_White_mg = Eval_PST_White_mg + MidGame_PST(RawPiece,TheSq,#WhiteColor) - (DoubledPawnFlag * #DoubledPawnPenalty) + (WhitePassedPawnBonusFlag * #PassedPawnBonus * WPassRankFactor(TheSq))
            Eval_PST_White_eg = Eval_PST_White_eg + EndGame_PST(RawPiece,TheSq,#WhiteColor) - (DoubledPawnFlag * #DoubledPawnPenalty) + (WhitePassedPawnBonusFlag * #PassedPawnBonus * WPassRankFactor(TheSq))
          Case #BlackX
            If RawPiece = #BP
              If Board(TheSq-10) = #BP Or Board(TheSq-20) = #BP
                DoubledPawnFlag = #True
              EndIf
              If TheSq >= #A2 And TheSq <= #H4                                                             ; look for possible passed pawns on 5th or 6th or 7th rank
                BlackPassedPawnBonusFlag = #True
                If TheSq >= #A3                                                                           ; if square ge a3 black pawn is already passed on 7th rank, no pawn blockers possible
                  For z1 = 1 To 6
                    If BPassPawnBlockSqrs(TheSq,z1) <> 0
                      If Board(BPassPawnBlockSqrs(TheSq,z1)) = #WP 
                        BlackPassedPawnBonusFlag = #False
                        Break
                      EndIf
                    Else
                      Break
                    EndIf
                  Next z1
                EndIf
              EndIf
            EndIf
            Eval_PST_Black_mg = Eval_PST_Black_mg + MidGame_PST(-1 * RawPiece,TheSq,#BlackColor) - (DoubledPawnFlag * #DoubledPawnPenalty) + (BlackPassedPawnBonusFlag * #PassedPawnBonus * BPassRankFactor(TheSq))
            Eval_PST_Black_eg = Eval_PST_Black_eg + EndGame_PST(-1 * RawPiece,TheSq,#BlackColor) - (DoubledPawnFlag * #DoubledPawnPenalty) + (BlackPassedPawnBonusFlag * #PassedPawnBonus * BPassRankFactor(TheSq))
          Case 0
            ; do nothing
        EndSelect
      EndIf
    Next TheSq

    If GameMoveNumber >= 10  And GameMoveNumber <= 60 And Depth <= 7                                                           ; some minimal and dubious (lol) king safety
      If (-1*SideToMove = #White And TempKingSqr <= #H2) Or (-1*SideToMove = #BlackX And TempKingSqr >= #A7)        ; do king safety if king still on back two ranks
        EvaluateKingSafety(TempKingSqr)
        If -1*SideToMove = #WhiteX
          Eval_PST_White_mg = Eval_PST_White_mg + KingDefendersBonus + KingRingPawnShieldBonus - KingAttackersPenalty - (QueenIsKingRingAttackerFlag * #QueenIsKingRingAttackerPenalty)
          Eval_PST_White_mg = Eval_PST_White_mg - BackRankWeakFlag * #BackRankWeakPenalty
        Else
          Eval_PST_Black_mg = Eval_PST_Black_mg + KingDefendersBonus + KingRingPawnShieldBonus - KingAttackersPenalty - (QueenIsKingRingAttackerFlag * #QueenIsKingRingAttackerPenalty)
          Eval_PST_Black_mg = Eval_PST_Black_mg - BackRankWeakFlag * #BackRankWeakPenalty
        EndIf
      EndIf
    EndIf

    Eval_mg = Eval_PST_White_mg - Eval_PST_Black_mg
    Eval_eg = Eval_PST_White_eg - Eval_PST_Black_eg
                                                                                ; Now Taper the evals
    If mgPhase > 24                       ; take care of early pawn promotion
      mgPhase = 24
    EndIf
      
    egPhase = 24 - mgPhase
    Total_PST_Eval = (Eval_mg * mgPhase + Eval_eg * egPhase)/24

    If Depth <= 1
      infoMsg = "info - Evals mg - Eval_White_mg = " + Str(Eval_PST_White_mg) + " Eval_Black_mg = " + Str(Eval_PST_Black_mg)
      infoMsg = infoMsg + "  Evals eg - Eval_White_eg = " + Str(Eval_PST_White_eg) + " Eval_Black_eg = " + Str(Eval_PST_Black_eg)
      infoMsg = infoMsg + " Defenders bonus = " + Str(KingDefendersBonus) + " Attackers penalty = " + Str(KingAttackersPenalty)
      infoMsg = infoMsg + " Q atk penalty = " + Str(QueenIsKingRingAttackerFlag * #QueenIsKingRingAttackerPenalty)
      infoMsg = infoMsg + " Back rank penalty = " + Str(BackRankWeakFlag)
      infoMsg = infoMsg + " White passer = " + Str(WhitePassedPawnBonusFlag) + " Black passer = " + Str(BlackPassedPawnBonusFlag)
      SendLog(infoMsg)
      infoMsg = "info - Total tapered PST Eval = " + Str(Total_PST_Eval)
      SendLog(infoMsg) 
    EndIf

EndProcedure 



Procedure EvaluateKingSafety(KingLocSqr.w)
                                                                      ; This King Safety routine is currently very minimal
Protected KingRingSqr.w, RingSqrCount.w, DefenderLocationSqr.w, BlockerPiece.w

;If Depth <= 3 SendLog("info: EKS - SideToMove = " + SideToMove + " Depth = " + Depth + " King square = " + AlgBrd(KingLocSqr))

RingSqrCount = 0
KingDefendersBonus = 0
KingRingPawnShieldBonus = 0
KingAttackersPenalty = 0
QueenIsKingRingAttackerFlag = #False

For z1 = 1 To 5
  KingRingSqrsTable(z1) = 0
  KingRingSqrAttackedFlag(z1) = 0
  KingRingSqrDefendedFlag(z1) = 0
Next z1

For z1 = 1 To #Max_Move_Dirs - 2                                        ; currently only using 1st six directions (really 5)
  If z1 <> 2                                                      ; do not need King_South (yet)
    KingRingSqr = KingLocSqr - SideToMove * -1 * Piece_Dirs_Table(#WK,z1)
    If Board(KingRingSqr) <> #EdgeSq
      RingSqrCount = RingSqrCount + 1
      KingRingSqrsTable(RingSqrCount) = KingRingSqr
      If (-1 * SideToMove = #WhiteX And KingLocSqr <> #e1) Or (-1 * SideToMove = #BlackX And KingLocSqr <> #E8)
         Select z1                                                 ; just pawn shield sqrs in front of king when king NOT in starting position , etc.
          Case 1,5,6
            If Board(KingRingSqr) = -1 * SideToMove * #WP
              KingRingPawnShieldBonus = KingRingPawnShieldBonus + #KingRingSqrPawnBonus
            EndIf
          Case 2,3,4
            ; do nothing - not sqrs in front of king
        EndSelect
      EndIf
    EndIf
  EndIf
Next z1

If Depth <= 2
  infoMsg = "info: EvalKingSafety - Ring Sqrs: "
  For z1 = 1 To RingSqrCount
    infoMsg = infoMsg + AlgBrd(KingRingSqrsTable(z1)) + " "
  Next z1
  ;SendLog(infoMsg)
EndIf

For z1 = 1 To RingSqrCount
  KingRingSqr = KingRingSqrsTable(z1)
  If SquareIsAttacked(KingRingSqr,SideToMove, 1) = #True
    KingRingSqrAttackedFlag(z1) = #True
    If QueenIsSquareAttackerFlag = #True 
      QueenIsKingRingAttackerFlag = #True
    EndIf
    KingAttackersPenalty = KingAttackersPenalty + #KingRingSqrAttackedPenalty
  EndIf
Next z1


For z1 = 1 To RingSqrCount                                                                  ; do we have ring square defenders
  KingRingSqr = KingRingSqrsTable(z1)
  If SquareIsAttacked(KingRingSqr,-1*SideToMove,1) = #True And SquareAttackCount > 1       ; more than just king defending this square?
    KingRingSqrDefendedFlag(z1) = #True
    KingDefendersBonus = KingDefendersBonus + #KingRingSqrDefendedBonus
  EndIf
Next z1

EndProcedure 


Procedure  PseudoLegalMove_IsLegal(AFrom.w, ATo.w, Side.w)

  Protected CurrentKingLocSqr.w, PossibleCapturedPiece.w

  ;Board_Log_Routine()
  If Sign(Board(Afrom)) = Sign(Board(Ato))
    ProcedureReturn #False
  EndIf

  If Abs(Board(AFrom)) = #WK 
    CurrentKingLocSqr = ATo
  Else
    If Side = #WhiteX
      CurrentKingLocSqr = WKing 
    Else 
      CurrentKingLocSqr = BKing
    EndIf
  EndIf

  PossibleCapturedPiece = Board(ATo)
  Board(ATo) = Board(AFrom)
  Board(AFrom) = 0

  If SquareIsAttacked(CurrentKingLocSqr, -1 * Side, 0) = #True
    Board(AFrom) = Board(ATo)
    Board(ATo) = PossibleCapturedPiece
    ProcedureReturn #False
  Else
    Board(AFrom) = Board(ATo)
    Board(ATo) = PossibleCapturedPiece
    ProcedureReturn #True
  EndIf

  

EndProcedure


Procedure  DisplayBoard()
  
  Protected LColumn.w, LRow.w, LPiece.w, LSide.w, xrank.w, xfile.w
  Protected Result.s = ""
  
  For xrank = 9 To 2 Step -1
    For xfile = 1 To 8
      LPiece = Board(xrank * 10 + xfile)
      LSide = Sign(LPiece)
      LPiece = Abs(LPiece)
      If LSide = #BlackX
        result = result + LCase(FigSymbol(LPiece)) + " "
      Else
        result = result + FigSymbol(LPiece) + " "
      EndIf
    Next
    PrintN(result)
    result = ""
  Next
  
  result = ""
  
  If SideToMove = #WhiteX
    result = result + "# White"
  Else
    result = result + "# Black"
  EndIf
  result = result + " to move" + #CRLF$
  result = result + "# Material balance: " + MaterialBalance(Depth) + #CRLF$
  result = result + "# En Passant field: " + FieldNotation(EpField(Depth)) + #CRLF$
  result = result + "# Castling state black: "
  If MoveControl(#E8) + MoveControl(#h8) = 0 
    result = result + "0-0 "
  EndIf
  If MoveControl(#E8) + MoveControl(#A8) = 0 
    result = result + "0-0-0"
  EndIf
  result = result + #CRLF$
  result = result + "# Castling state white: "
  If MoveControl(#e1) + MoveControl(#H1) = 0 
    result = result + "0-0 "
  EndIf
  If MoveControl(#e1) + MoveControl(#a1) = 0 
    result = result + "0-0-0"
  EndIf
  PrintN(result)
EndProcedure

Procedure DisplayMove(CurrMove.w)
  Protected LFrom.w, LTo.w
  
  LFrom = MoveStack(CurrMove)\FromField
  LTo = MoveStack(CurrMove)\ToField
  If MoveStack(CurrMove)\CapturedPiece = #nil
    ; do nothing for now
  EndIf
  If MoveStack(CurrMove)\PromotedPiece <> #nil
    ; do nothing for now
  EndIf
EndProcedure 

Procedure  FieldNotation(AField.w)
  Protected LCol.i, LRow.i, LCol_str.s, LRow_str.s
  
  If (AField < #a1) Or (AField > #h8) Or (Board(AField) = #Edge)
    PartMove = "--"
  Else
    ;LCol = AField % 10
    LRow = AField / 10 - 1
    LCol = Val(Right(Str(Afield),1))

    ;FieldNotation = Chr(Asc("a") + LCol - 1, Asc("1") + LRow - 1)
    PartMove = Mid("abcdefgh",LCol,1) + Str(LRow)
  EndIf
EndProcedure

Procedure  FieldNumber(AField.s)
  Protected LRow.s , LCol.s
  LRow = Left(AField, 1)
  LCol = Mid(AField, 2, 1)
  If (LRow < "a") Or (LRow > "h") Or (LCol < "1") Or (LCol > "8")
    ProcedureReturn #Illegal
  EndIf
  ProcedureReturn 10 * (Asc(LCol) - Asc("1") + 2) + Asc(LRow) - Asc("a") + 1
EndProcedure



Procedure GeneratePseudoLegalMovesFromTables(AllMoves.w)

  #KingSide = 1 : #QueenSide = 2
  Protected LFrom.w, LPiece.w, i.w, Direction.w, LTo.w, ep.w, OK.w
  Protected ValidKSqr.w, ValidRookSqr.w, KurrentKingSqr.w, Castle.w
  
  movegen_flag = #True : movegen_count = movegen_count + 1
  starttime = ElapsedMilliseconds()
  QuietIndex = 0
  CaptureIndex = 0
  MoveIndex = StackLimit(Depth)

  For BoardSq = #a1 To #h8
    RawPiece = Board(BoardSq)
    If RawPiece * SideToMove > 0 And RawPiece <> #EdgeSq
      ThePiece = Abs(Board(BoardSq))
        Select ThePiece
          Case #Pawn
;            SendLog(" ") : SendLog("BoardSq = " + str(BoardSq) + " Pawn moves")
            GeneratePawnMoves(AllMoves)
          Case #Rook
;            SendLog(" ") : SendLog("BoardSq = " + str(BoardSq) + " Rook moves")
            GeneratePieceMoves(AllMoves)
          Case #Bishop
;            SendLog(" ") : SendLog("BoardSq = " + str(BoardSq) + " Bishop moves")
            GeneratePieceMoves(AllMoves)
          Case #Knight
;            SendLog(" ") : SendLog("BoardSq = " + str(BoardSq) + " Knight moves")
            GeneratePieceMoves(AllMoves)
          Case #Queen
;            SendLog(" ") : SendLog("BoardSq = " + str(BoardSq) + " Queen moves")
            GeneratePieceMoves(AllMoves)
          Case #King
;            SendLog(" ") : SendLog("BoardSq = " + str(BoardSq) + " King moves")
            GeneratePieceMoves(AllMoves)
        EndSelect
    EndIf
  Next BoardSq


; Now check en-passant moves

  If EpField(Depth) <> #Illegal
    ep = EpField(Depth)
    If Board(ep - 9*SideToMove) = #WP * SideToMove
      SaveEnPassantMove(ep - 9*SideToMove, ep, ep - 10*SideToMove)
    EndIf
    If Board(ep - 11*SideToMove) = #WP * SideToMove
      SaveEnPassantMove(ep - 11*SideToMove, ep, ep - 10*SideToMove)
    EndIf
  EndIf


 ; Now check non-table castling moves

   Select SideToMove
    Case #WhiteX
      ValidKSqr = #e1 : KurrentKingSqr = Wking
    Case #BlackX
      ValidKSqr = #E8 : KurrentKingSqr = BKing
  EndSelect

  If KurrentKingSqr = ValidKSqr And MoveControl(ValidKSqr) = 0                                    ; make sure King has not moved
    For Castle = #KingSide To #QueenSide
       Select Castle
        Case #KingSide
          ValidRookSqr = ValidKSqr + 3
          If Board(ValidRookSqr) = #WR * SideToMove And MoveControl(ValidRookSqr) = 0              ; make sure Kingside Rook has not moved
            If Board(ValidKSqr+1) = #EmptySq And Board(ValidKSqr+2) = #EmptySq
              If SquareIsAttacked(ValidKSqr, -1 * SideToMove, 0) = #False And SquareIsAttacked(ValidKSqr+1, -1 * SideToMove, 0) = #False And SquareIsAttacked(ValidKSqr+2, -1 * SideToMove, 0) = #False
                SaveQuietCastleMove(ValidKSqr, ValidKSqr+2)
                MoveStack(MoveIndex-1)\CastlingNr = #ShortCastlingMove
              EndIf
            EndIf
           EndIf
        Case #QueenSide
          ValidRookSqr = ValidKSqr - 4
          If Board(ValidRookSqr) = #WR * SideToMove And MoveControl(ValidRookSqr) = 0               ; make sure Queenside Rook has not moved
            If Board(ValidKSqr-1) = #EmptySq And Board(ValidKSqr-2) = #EmptySq And Board(ValidKSqr-3) = #EmptySq
              If SquareIsAttacked(ValidKSqr, -1 * SideToMove, 0) = #False And SquareIsAttacked(ValidKSqr-1, -1 * SideToMove, 0) = #False And SquareIsAttacked(ValidKSqr-2, -1 * SideToMove, 0) = #False
                SaveQuietCastleMove(ValidKSqr, ValidKSqr-2)
                MoveStack(MoveIndex-1)\CastlingNr = #LongCastlingMove
              EndIf
            EndIf
          EndIf
      EndSelect
    Next Castle
  EndIf



; Simple move ordering, save captures first in ordinary movelist, save ALL Quiet moves to MoveStackQuiet and copy back to movelist at end below

;  For Z1 = 0 to CaptureIndex
;    MoveStack(MoveIndex) = MoveStackCapture(z1)
;  MoveIndex = MoveIndex + 1
;  next z1


  For Z1 = 1 To QuietIndex
    MoveStack(MoveIndex) = MoveStackQuiet(z1)
    MoveIndex = MoveIndex + 1
  Next z1  

  StackLimit(Depth + 1) = MoveIndex
  TimerCheck()
  If movegen_count % 100 = 0
    infoMsg = ""
    infoMsg = "info - Depth = " + Str(Depth) + "  Movegen elapsed time = " + Str(elapsed_time) + " Captures = " + Str(CaptureIndex+1) + " Quiets = " + Str(QuietIndex+1) + " Total moves = " 
    infoMsg = infoMsg + Str(MoveIndex) + "  Nodes = " + Str(NodeCount)
    ;PrintN(infoMsg)
    SendLog(infoMsg)
  EndIf
  
  movegen_flag = #False

EndProcedure 



Procedure GeneratePieceMoves(AllMoves.w)

  No_of_Piece_Dirs = Max_Piece_Dirs(ThePiece)
  For The_Dir = 1 To No_of_Piece_Dirs
    If ThePiece <> 4 And ThePiece <> 6
      Total_Travel_Sqs = #Max_Travel_Sqs
    Else
      Total_Travel_Sqs = 1
    EndIf
    For Sqlist = 1 To Total_Travel_Sqs
      TableSq = Piece_Moves_Table(ThePiece,BoardSq,The_Dir,SqList)
      If TableSq <> 0
        SqContents = Board(TableSq)
        Proper_Piece_Color = SqContents * SideToMove
         Select Proper_Piece_Color
          Case 0
            If AllMoves > 0
              SaveQuietMove(BoardSq,TableSq)
            EndIf
          Case 1,2,3,4,5,6
            Break                                                                                ; blocked by own piece, proceed to next direction
          Case -1,-2,-3,-4,-5,-6                                                                      ; it is a valid move capture
            SaveCaptureMove(BoardSq,TableSq)
            Break
          Default
            PrintN("info - Piece what  - why are we here?")
        EndSelect
      Else
        Break
      EndIf
    Next SqList

  Next The_Dir

EndProcedure 



Procedure GeneratePawnMoves(AllMoves.w)

  For The_Dir = 1 To 4
     Select RawPiece
      Case #WP
        TableSq = Piece_Moves_Table(#WP,BoardSq,The_Dir,1)
      Case #BP
        TableSq = Piece_Moves_Table(0,BoardSq,The_Dir,1)
      Default
        PrintN("info - GenetatePawnMoves - something went wrong!")
    EndSelect

    SqContents = Board(TableSq)    
    Proper_Piece_Color = SqContents * SideToMove
    If The_Dir <= 2                                                              ; pawn forward moves only
       Select Proper_Piece_Color
        Case 0
           Select The_Dir
            Case 1
              If (Rawpiece = #WP And BoardSq >= #A7) Or (Rawpiece = #BP And BoardSq <= #H2)
                SavePromotionMove(BoardSq,TableSq)
              Else
                If AllMoves > 0 
                  SaveQuietMove(BoardSq,TableSq)
                EndIf
              EndIf
            Case 2                                                                   ; two-square pawn forward move, interposing square must also be empty
              If Board(TableSq - RawPiece*10) = 0
                If AllMoves > 0
                  SaveQuietMove(BoardSq,TableSq)
                  If SideToMove = #WhiteX
                    MoveStackQuiet(QuietIndex)\EpField = BoardSq + 10
                  Else
                    MoveStackQuiet(QuietIndex)\EpField = BoardSq - 10
                  EndIf
                EndIf
              EndIf
          EndSelect
        Case 1,2,3,4,5,6
          ; do nothing we are blocked by own piece, proceed to next direction
        Case -1,-2,-3,-4,-5,-6        
          ; do nothing we are blocked by forward enemy piece, proceed to next direction
      EndSelect
    Else
       Select Proper_Piece_Color
        Case 0                                                                    ; if NOT an EP move, nothing to capture
          If SideToMove = #WhiteX
            If Depth <= 1
;             SaveEnPassantMove(BoardSq,TableSq,TableSq)
            Else
;             SaveEnPassantMove(BoardSq,TableSq,TableSq)
            EndIf
          EndIf                                                  
        Case 1,2,3,4,5,6        
          ; do nothing we are blocked by own piece, proceed to next direction
        Case -1,-2,-3,-4,-5,-6
              If (Rawpiece = #WP And BoardSq >= #A7) Or (Rawpiece = #BP And BoardSq <= #H2)
                If Board(TableSq) <> #EdgeSq
                  SavePromotionMove(BoardSq,TableSq)
                EndIf
              Else
                If Board(TableSq) <> #EdgeSq
                  SaveCaptureMove(BoardSq,TableSq)
                EndIf
              EndIf
      EndSelect
    EndIf
  Next The_Dir

EndProcedure 



Procedure InitGameTree()
  If Depth = 0  
    ProcedureReturn 
  EndIf
  EpField(0) = EpField(1)
  MaterialBalance(0) = MaterialBalance(1)
  MaterialTotal(0) = MaterialTotal(1)
  Depth = 0
EndProcedure 




Procedure  InputMove(Move.s)
  Protected LFrom.w, LTo.w, i.w, tmp.w
  If Len(Move) < 4 And Move <> "st"
    ProcedureReturn #False
  EndIf
  LFrom = FieldNumber(Move)
  LTo = FieldNumber(Mid(Move, 3, 2))

  If SideToMove = #WhiteX
    GameMoveNumber = GameMoveNumber + 1
    SendLog("info: InputMove routine - GameMoveNumber = " + Str(GameMoveNumber) + "  Side to move = " + Str(SideToMove))
  EndIf

  GeneratePseudoLegalMovesFromTables(1)
  For i = StackLimit(Depth) To StackLimit(Depth + 1) - 1
    If MoveStack(i)\FromField = LFrom And MoveStack(i)\ToField = LTo
      If MoveStack(i)\PromotedPiece <> #nil
        If Mid(Move, 5, 1) = "n"
          i = i + 1
        ElseIf Mid(Move, 5, 1) = "b"
          i = i + 2
        ElseIf Mid(Move, 5, 1) = "r"
          i = i + 3
        EndIf
      EndIf
      InitGameTree()
      DisplayMove(i)
      tmp = LastMove
      PerformMove(i)

      SendLog("info: Input Move function - move was " + Str(LFrom) + Str(LTo)  + "  Depth = " + Str(Depth) + "  Side to move = " + Str(SideToMove))
      If SideToMove = #BlackX
        If SquareIsAttacked(WKing, #BlackX, 0)
          PrintN("info - ** White king on " + FieldNotation(WKing) + " is being checked.")
          UndoMove((i))
          LastMove = tmp
          ProcedureReturn #False
        EndIf
      ElseIf SquareIsAttacked(BKing, #WhiteX, 0)
        PrintN("info - ** Black king on " + FieldNotation(BKing) + " is being checked.")
        UndoMove((i))
        LastMove = tmp
        ProcedureReturn #False
      EndIf
      ProcedureReturn #True
    EndIf
  Next i
  ProcedureReturn #False
EndProcedure


Procedure  NextBestMove()
  
  Protected BestMove.w, BestValue.w, i.w
  
  BestMove = -1
  BestValue = -1 * #MateValue
  For i = StackLimit(Depth) To StackLimit(Depth + 1) - 1
    If MoveStack(i)\Value > BestValue
      BestMove = i
      BestValue = MoveStack(i)\Value
    EndIf
  Next i
  If BestMove >= 0
    MoveStack(BestMove)\Value = -1 * #MateValue
  EndIf
  ProcedureReturn BestMove
EndProcedure


Procedure PerformMove(CurrMove.w)
  Protected LFrom.w, LTo.w, LEnPassant.w, MatChange.w
  MoveCount = MoveCount + 1
  LFrom = MoveStack(CurrMove)\FromField
  LTo = MoveStack(CurrMove)\ToField
  If Depth <= 3
    ;PrintN("PERFORMMOVE1:  Lfrom = " + AlgBrd(Lfrom) + "  Lto = " + AlgBrd(LTo))
    ;SendLog("PERFORMMOVE1:  Lfrom = " + AlgBrd(Lfrom) + "  Lto = " + AlgBrd(LTo))
  EndIf
  
    ;If AlgBrd(Lfrom) = "g8" And AlgBrd(LTo) = "f6"
     ; PrintN("PERFORMMOVE2**********: Here is a g8-f6 knight move!" + " Depth = " + Str(Depth))
     ; SendLog("PERFORMMOVE2**********: Here is a g8-f6 knight move!" + " Depth = " + Str(Depth))
    ;EndIf
  
  LEnPassant = MoveStack(CurrMove)\EpField
  LastMove = CurrMove
  Depth = Depth + 1
  ToField(Depth) = LTo
  EpField(Depth) = #Illegal
  MaterialBalance(Depth) = -1 * MaterialBalance(Depth - 1)
  MaterialTotal(Depth) = MaterialTotal(Depth - 1)
  MoveControl(LFrom) = MoveControl(LFrom) + 1
  MoveControl(LTo) = MoveControl(LTo) + 1
  If LEnPassant <> #Illegal
    If Board(LEnPassant) = #nil
      EpField(Depth) = LEnPassant
    Else
      Board(LEnPassant) = #nil
      IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(#WP,ColorZbIdx(-1*SideToMove+2),LEnPassant)                            ; XOR out enemy pawn
      MaterialBalance(Depth) = MaterialBalance(Depth) - #MatP
    EndIf
  Else
    If MoveStack(CurrMove)\CapturedPiece <> #nil
      If MoveStack(CurrMove)\CapturedPiece >= 0
        IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(MoveStack(CurrMove)\CapturedPiece,ColorZbIdx(-1*SideToMove+2),LTo) ; XOR out captured piece
      Else
        IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(-1 * MoveStack(CurrMove)\CapturedPiece,ColorZbIdx(-1*SideToMove+2),LTo)
      EndIf
      MatChange = PieceMaterial(MoveStack(CurrMove)\CapturedPiece)
      MaterialBalance(Depth) = MaterialBalance(Depth) - MatChange
      If MatChange <> #MatP
        MaterialTotal(Depth) = MaterialTotal(Depth) - MatChange
      EndIf
    EndIf
  EndIf
  Board(LTo) = Board(LFrom)
  Board(LFrom) = #nil

; Update Zobrist Position Key and some special move squares ************************************************************** starting with from move part
  If Board(Lto) >= 0                                               ; XOR out from sq piece
    IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(Board(LTo),ColorZbIdx(SideToMove+2),LFrom)
  Else
    IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(-1 * Board(LTo),ColorZbIdx(SideToMove+2),LFrom)
  EndIf
  If MoveStack(CurrMove)\CastlingNr = #ShortCastlingMove
    Board(LTo + 1) = #nil
    Board(LTo - 1) = SideToMove * #WR
    Castling(SideToMove + 1) = #True
    IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(#WR,ColorZbIdx(SideToMove+2),LTo+1)                                      ; XOR out rook sq piece
    IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(#WR,ColorZbIdx(SideToMove+2),LTo-1)                                      ; XOR in rook sq piece
    EndIf
  If MoveStack(CurrMove)\CastlingNr = #LongCastlingMove
    Board(LTo - 2) = #nil
    Board(LTo + 1) = SideToMove * #WR
    Castling(SideToMove + 1) = #True
    IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(#WR,ColorZbIdx(SideToMove+2),LTo-2)                                      ; XOR out rook sq piece
    IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(#WR,ColorZbIdx(SideToMove+2),LTo+1)                                      ; XOR in rook sq piece
  EndIf

  If MoveStack(CurrMove)\PromotedPiece <> #nil
    Board(LTo) = SideToMove * MoveStack(CurrMove)\PromotedPiece
    If MoveStack(CurrMove)\PromotedPiece >= 0
      IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(MoveStack(CurrMove)\PromotedPiece,ColorZbIdx(SideToMove+2),LTo)    ; XOR in To sq Promotion piece
    Else
      IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(-1 * MoveStack(CurrMove)\PromotedPiece,ColorZbIdx(SideToMove+2),LTo)
    EndIf
    MatChange = PieceMaterial(MoveStack(CurrMove)\PromotedPiece) - #MatP
    MaterialBalance(Depth) = MaterialBalance(Depth) - MatChange
    MaterialTotal(Depth) = MaterialTotal(Depth) + MatChange + #MatP
  Else
    If Board(Lto) > 0                                               ; XOR in regular move To sq piece
      IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(Board(LTo),ColorZbIdx(SideToMove+2),LTo)
    Else
      IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(-1 * Board(LTo),ColorZbIdx(SideToMove+2),LTo)
    EndIf
  EndIf

  If Board(LTo) = #WK
    WKing = LTo
  ElseIf Board(LTo) = #BK
    BKing = LTo
  EndIf
                                                                                   
  SideToMove = -1 * SideToMove
  IncrementalZobristPositionKey = IncrementalZobristPositionKey ! SwitchColorZobristKey                                                                        ; SideToMove has changed
EndProcedure 




Procedure SaveQuietMove(AFrom.w, ATo.w)

  Protected Killer1.w, Killer2.w, MVarMove.w

;  SendLog("pseudo-legal quiet move = " + str(BoardSq) + str(TableSq))

  QuietIndex = QuietIndex + 1

  KillerTab(Depth)\Killer1\FromField = AFrom
  Killer1 = KillerTab(Depth)\Killer1\FromField
  
  KillerTab(Depth)\Killer1\ToField = ATo
  Killer1 = Killer1 * 100 + KillerTab(Depth)\Killer1\ToField
  
  KillerTab(Depth)\Killer2\FromField = AFrom
  Killer2 = KillerTab(Depth)\Killer2\FromField
  
  KillerTab(Depth)\Killer2\ToField = ATo
  Killer2 = Killer2 * 100 + KillerTab(Depth)\Killer2\ToField
  
  MVar(0, Depth)\FromField = AFrom
  MVarMove = MVar(0, Depth)\FromField
  MVar(0, Depth)\ToField = ATo
 
  If MVarMove
    MoveStackQuiet(QuietIndex)\Value = #MainVariantBonus
  ElseIf Killer1
    MoveStackQuiet(QuietIndex)\Value = #Killer1Bonus
  ElseIf Killer2
    MoveStackQuiet(QuietIndex)\Value = #Killer2Bonus
  Else
    MoveStackQuiet(QuietIndex)\Value = 0
  EndIf

  MoveStackQuiet(QuietIndex)\FromField = AFrom
  MoveStackQuiet(QuietIndex)\ToField = ATo
  MoveStackQuiet(QuietIndex)\CapturedPiece = 0
  MoveStackQuiet(QuietIndex)\PromotedPiece = 0
  MoveStackQuiet(QuietIndex)\CastlingNr = #NoCastlingMove
  MoveStackQuiet(QuietIndex)\EpField = #Illegal


EndProcedure 


Procedure SaveQuietCastleMove(AFrom.w, ATo.w)

  Protected Killer1.w, Killer2.w, MVarMove.w

;  SendLog("pseudo-legal quiet move = " + str(BoardSq) + str(TableSq))

  KillerTab(Depth)\Killer1\FromField = AFrom
  Killer1 = KillerTab(Depth)\Killer1\FromField
  
  KillerTab(Depth)\Killer1\ToField = ATo
  Killer1 = Killer1 * 100 + KillerTab(Depth)\Killer1\ToField
  
  KillerTab(Depth)\Killer2\FromField = AFrom
  Killer2 = KillerTab(Depth)\Killer2\FromField
  
  KillerTab(Depth)\Killer2\ToField = ATo
  Killer2 = Killer2 * 100 +  KillerTab(Depth)\Killer2\ToField
  
  MVar(0, Depth)\FromField = AFrom
  MVarMove = MVar(0, Depth)\FromField
  MVar(0, Depth)\ToField = ATo
 
  If MVarMove
    MoveStack(MoveIndex)\Value = #MainVariantBonus
  ElseIf Killer1
    MoveStack(MoveIndex)\Value = #Killer1Bonus
  ElseIf Killer2
    MoveStack(MoveIndex)\Value = #Killer2Bonus
  Else
    MoveStack(MoveIndex)\Value = 0
  EndIf

  MoveStack(MoveIndex)\FromField = AFrom
  MoveStack(MoveIndex)\ToField = ATo
  MoveStack(MoveIndex)\CapturedPiece = 0
  MoveStack(MoveIndex)\PromotedPiece = 0
  MoveStack(MoveIndex)\CastlingNr = #NoCastlingMove
  MoveStack(MoveIndex)\EpField = #Illegal

  MoveIndex = MoveIndex + 1

EndProcedure 



Procedure SaveCaptureMove(AFrom.w, ATo.w)

 Protected FigValue.w, Killer1.w, Killer2.w, MVarMove.w, i.w

 If Board(ATo) = #WK Or Board(ATo) = #BK 
   ProcedureReturn 
 EndIf
  ;SendLog("pseudo-legal capture move = " + str(BoardSq) + str(TableSq))

  CaptureIndex = CaptureIndex + 1
  If Board(ATo) >= 0
    FigValue = PieceMaterial(Board(ATo))
  Else
    FigValue = PieceMaterial(-1 * Board(ATo))
  EndIf

  MoveStack(MoveIndex)\FromField = AFrom
  MoveStack(MoveIndex)\ToField = ATo
  
  If Board(ATo) >= 0
    MoveStack(MoveIndex)\CapturedPiece = Board(ATo)
  Else
    MoveStack(MoveIndex)\CapturedPiece = -1 * Board(ATo)
  EndIf
  
  If Board(AFrom) >= 0
    MoveStack(MoveIndex)\Value = FigValue - PieceMaterial(Board(AFrom)) / 8
  Else
    MoveStack(MoveIndex)\Value = FigValue - PieceMaterial(-1 * Board(AFrom)) / 8
  EndIf
  
  If Depth > 0
    If ATo = ToField(Depth - 1)
      MoveStack(MoveIndex)\Value = MoveStack(MoveIndex)\Value + 300
    EndIf
  EndIf
  
  KillerTab(Depth)\Killer1\FromField = AFrom
  Killer1 = KillerTab(Depth)\Killer1\FromField
  KillerTab(Depth)\Killer1\ToField = ATo
  Killer1 = Killer1 * 100 + KillerTab(Depth)\Killer1\ToField
  
  KillerTab(Depth)\Killer2\FromField = AFrom
  Killer2 = KillerTab(Depth)\Killer2\FromField
  
  KillerTab(Depth)\Killer2\ToField = ATo
  Killer2 = Killer2 * 100 + KillerTab(Depth)\Killer2\ToField
  
  MVar(0, Depth)\FromField = AFrom
  MVarMove = MVar(0, Depth)\FromField
  MVar(0, Depth)\ToField = ATo

  If MVarMove
    MoveStack(MoveIndex)\Value = MoveStack(MoveIndex)\Value + #MainVariantBonus
  ElseIf Killer1
    MoveStack(MoveIndex)\Value = MoveStack(MoveIndex)\Value + #Killer1Bonus
  ElseIf Killer2
    MoveStack(MoveIndex)\Value = MoveStack(MoveIndex)\Value + #Killer2Bonus
  EndIf
  MoveStack(MoveIndex)\PromotedPiece = 0
  MoveStack(MoveIndex)\CastlingNr = #NoCastlingMove
  MoveStack(MoveIndex)\EpField = #Illegal

  MoveIndex = MoveIndex + 1 


EndProcedure 


Procedure SaveEnPassantMove(AFrom.w, ATo.w, AEP.w)

  If Board(ATo) = #WK Or Board(ATo) = #BK
    ProcedureReturn 
  EndIf
  ;SendLog("pseudo-legal ep capture move = " + str(AFrom) + str(ATo))
;  CaptureIndex = CaptureIndex + 1

  MoveStack(MoveIndex)\FromField = AFrom
  MoveStack(MoveIndex)\ToField = ATo
  MoveStack(MoveIndex)\CapturedPiece = #WP
  MoveStack(MoveIndex)\PromotedPiece = #nil
  MoveStack(MoveIndex)\CastlingNr = #NoCastlingMove
  MoveStack(MoveIndex)\EpField = AEP
  MoveStack(MoveIndex)\Value = #MatP

  MoveIndex = MoveIndex + 1

EndProcedure 



Procedure SavePromotionMove(AFrom.w, ATo.w)

  If Board(ATo) = #EmptySq
    For z1 = #WQ To #WR Step -1
      SaveQuietMove(AFrom, ATo)
      MoveStackQuiet(QuietIndex)\PromotedPiece = z1
    Next z1
  Else
    For z1 = #WQ To #WR Step -1
      SaveCaptureMove(AFrom, ATo)
      MoveStack(MoveIndex-1)\PromotedPiece = z1
    Next z1
  EndIf

EndProcedure 


Procedure TimerCheck()
  
  EndTime = ElapsedMilliseconds()
  Elapsed_Time = EndTime - StartTime
  Time_Balance = Time_Balance - Elapsed_Time
  Time_Balance_Quad = Time_Balance
  TimerCheck_Count = TimerCheck_Count + 1
  If TimerCheck_Count % 100 = 0 Or (movegen_flag = #True And movegen_count % 10 = 0)
    SendLog("info: CM - Elapsed time = " + Str(Elapsed_Time) + " Time Left = " + Str(Time_Balance) + "  TT Entries = " + Str(TTEntryCount))
  EndIf
  If Time_Balance < 3000
    MaxExtension = 1
  EndIf
  
EndProcedure


Procedure UndoMove(CurrMove.w)
  Protected LFrom.w, LTo.w, LEnPassant.w, Promopiece.w, PreviousSideToMove.w
  MoveCount = MoveCount - 1
  LFrom = MoveStack(CurrMove)\FromField
  LTo = MoveStack(CurrMove)\ToField
  If Depth <= 3
    ;PrintN("UndoMove1:  Lfrom = " + AlgBrd(Lfrom) + "  Lto = " + AlgBrd(LTo))
    ;SendLog("UndoMove1:  Lfrom = " + AlgBrd(Lfrom) + "  Lto = " + AlgBrd(LTo))
  EndIf
  
    ;If AlgBrd(Lfrom) = "g8" And AlgBrd(LTo) = "f6"
     ; PrintN("UndoMove2**********: Here is a g8-f6 knight move!" + " Depth = " + Str(Depth))
      ;SendLog("UndoMove2**********: Here is a g8-f6 knight move!" + " Depth = " + Str(Depth))
    ;EndIf
 
  LEnPassant = MoveStack(CurrMove)\EpField
  PreviousSideToMove = SideToMove
  SideToMove = -1 * SideToMove
  Depth = Depth - 1

  Board(LFrom) = Board(LTo)
  Board(LTo) = #nil

  If (LEnPassant <> #Illegal) And (MoveStack(CurrMove)\CapturedPiece = #WP)
    Board(LEnPassant) = -1 * SideToMove
    IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(#WP,ColorZbIdx(-1*SideToMove+2),LEnPassant)                                      ; XOR back in enemy pawn
  ElseIf MoveStack(CurrMove)\CapturedPiece <> #nil
    Board(LTo) = -1 * SideToMove * MoveStack(CurrMove)\CapturedPiece
    If MoveStack(CurrMove)\CapturedPiece >= 0
      IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(MoveStack(CurrMove)\CapturedPiece,ColorZbIdx(-1*SideToMove+2),LTo)         ; XOR back in captured piece
    Else
      IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(-1 * MoveStack(CurrMove)\CapturedPiece,ColorZbIdx(-1*SideToMove+2),LTo)
    EndIf
  EndIf
  MoveControl(LFrom) = MoveControl(LFrom) - 1
  MoveControl(LTo) = MoveControl(LTo) - 1
  If Board(LFrom) >= 0
    IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(Board(LFrom),ColorZbIdx(SideToMove+2),LTo)                           ; XOR out orig moveto sq piece
  Else
    IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(-1 * Board(LFrom),ColorZbIdx(SideToMove+2),LTo)
  EndIf
  If MoveStack(CurrMove)\CastlingNr = #ShortCastlingMove
    Board(LTo + 1) = SideToMove * #WR
    Board(LTo - 1) = #nil
    Castling(SideToMove + 1) = #False
    IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(#WR,ColorZbIdx(SideToMove+2),LTo+1)                                      ; XOR back in rook sq piece
    IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(#WR,ColorZbIdx(SideToMove+2),LTo-1)                                      ; XOR back out rook sq piece
  ElseIf MoveStack(CurrMove)\CastlingNr = #LongCastlingMove
    Board(LTo - 2) = SideToMove * #WR
    Board(LTo + 1) = #nil
    Castling(SideToMove + 1) = #False
    IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(#WR,ColorZbIdx(SideToMove+2),LTo-2)                                      ; XOR back in rook sq piece
    IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(#WR,ColorZbIdx(SideToMove+2),LTo+1)                                      ; XOR back out rook sq piece
  EndIf

  If MoveStack(CurrMove)\PromotedPiece <> #nil
    Board(LFrom) = SideToMove
    If MoveStack(CurrMove)\PromotedPiece >= 0
      IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(MoveStack(CurrMove)\PromotedPiece,ColorZbIdx(SideToMove+2),LTo)    ; XOR out promo move To sq piece
    Else
      IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(-1 * MoveStack(CurrMove)\PromotedPiece,ColorZbIdx(SideToMove+2),LTo)
    EndIf
    IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(#WP,ColorZbIdx(SideToMove+2),LFrom)                                      ; XOR pawn back in regular move from sq
  Else
    If Board(LFrom) >= 0
      IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(Board(LFrom),ColorZbIdx(SideToMove+2),LFrom)
    Else
      IncrementalZobristPositionKey = IncrementalZobristPositionKey ! Rand64s_for_Zobrist(-1 * Board(LFrom),ColorZbIdx(SideToMove+2),LFrom)
    EndIf
    ; XOR back in  move From sq piece
  EndIf
  IncrementalZobristPositionKey = IncrementalZobristPositionKey ! SwitchColorZobristKey

  If Board(LFrom) = #WK
    WKing = LFrom
  ElseIf Board(LFrom) = #BK
    BKing = LFrom
  EndIf
EndProcedure 
; IDE Options = PureBasic 6.30 - C Backend (MacOS X - x64)
; ExecutableFormat = Console
; CursorPosition = 16
; Folding = --------
; EnableXP
; DPIAware
; Executable = MiniMaxkp_20260515.app