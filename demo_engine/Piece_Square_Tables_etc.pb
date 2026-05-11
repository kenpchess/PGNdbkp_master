
Global Dim Midgame_Pawn_table.w(119)
DataSection
  Midgame_Pawn_table:
   Data.w 0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,  -35,  -1, -20, -23, -15,  24, 38, -22,  0,  0,  -26,  -4,  -4, -10,   3,   3, 33, -12,  0,  0,  -27,  -2,  -5,  12,  17,   6, 10, -25,  0,  0,  -14,  13,   6,  21,  23,  12, 17, -23,  0,  0,  -6,   7,  26,  31,  65,  56, 25, -20,   0,  0,  98, 134,  61,  95,  68, 126, 34, -11,   0,  0,   0,   0,   0,   0,   0,   0,  0,   0,   0,  0,   0,   0,   0,   0,   0,   0,  0,   0,   0,  0,   0,   0,   0,   0,   0,   0,  0,   0,   0
EndDataSection
Restore Midgame_Pawn_table
For Datax = 0 To 119 : Read.w Midgame_Pawn_table(Datax) : Next


Global Dim Endgame_Pawn_table.w(119)
DataSection
  Endgame_Pawn_table:
   Data.w 0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,   13,   8,   8,  10,  13,   0,  2,  -7,  0,  0,    4,   7,  -6,   1,   0,  -5, -1,  -8,  0,  0,   13,   9,  -3,  -7,  -7,  -8,  3,  -1,  0,  0,   32,  24,  13,   5,  -2,   4, 17,  17,  0,  0,   94, 100,  85,  67,  56,  53, 82,  84,  0, 0,  178, 173, 158, 134, 147, 132,165, 187,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0
EndDataSection
Restore Endgame_Pawn_table
For Datax = 0 To 119 : Read.w Endgame_Pawn_table(Datax) : Next


Global Dim Midgame_Knight_table.w(119)
DataSection
  Midgame_Knight_table:
   Data.w 0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0, -105, -21, -58, -33, -17, -28, -19, -23, 0,  0,  -29, -53, -12,  -3,  -1,  18, -14, -19, 0,  0,  -23,  -9,  12,  10,  19,  17,  25, -16, 0,  0,  -13,   4,  16,  13,  28,  19,  21,  -8, 0,  0,   -9,  17,  19,  53,  37,  69,  18,  22, 0,  0,  -47,  60,  37,  65,  84, 129,  73,  44, 0,  -73, -41,  72,  36,  23,  62,   7, -17, 0,  0, -167, -89, -34, -49,  61, -97, -15, -107, 0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0
EndDataSection
Restore Midgame_Knight_table
For Datax = 0 To 119 : Read.w Midgame_Knight_table(Datax) : Next


Global Dim Endgame_Knight_table.w(119)
DataSection
  Endgame_Knight_table:
   Data.w 0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,  -29, -51, -23, -15, -22, -18, -50, -64, 0,  0,  -42, -20, -10,  -5,  -2, -20, -23, -44, 0,  0,  -23,  -3,  -1,  15,  10,  -3, -20, -22, 0,  0,  -18,  -6,  16,  25,  16,  17,   4, -18, 0,  0,  -17,   3,  22,  22,  22,  11,   8, -18, 0,  0,  -24, -20,  10,   9,  -1,  -9, -19, -41, 0, 0,  -25,  -8, -25,  -2,  -9, -25, -24, -52, 0,  0,  -58, -38, -13, -28, -31, -27, -63, -99, 0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,   0,   0,   0,   0,   0,   0,  0,   0,  0
EndDataSection
Restore Endgame_Knight_table
For Datax = 0 To 119 : Read.w Endgame_Knight_table(Datax) : Next


Global Dim Midgame_Bishop_table.w(119)
DataSection
  Midgame_Bishop_table:
   Data.w 0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,  -33,  -3, -14, -21, -13, -12, -39, -21, 0,  0,    4,  15,  16,   0,   7,  21,  33,   1, 0,  0,    0,  15,  15,  15,  14,  27,  18,  10, 0,  0,   -6,  13,  13,  26,  34,  12,  10,   4, 0,  0,   -4,   5,  19,  50,  37,  37,   7,  -2, 0,  0,  -16,  37,  43,  40,  35,  50,  37,  -2, 0, 0,  -26,  16, -18, -13,  30,  59,  18, -47, 0,  0,  -29,   4, -82, -37, -25, -42,   7,  -8, 0,  0,   0,   0,   0,   0,   0,   0,   0,   0,  0,  0,    0,   0,   0,   0,   0,   0,   0,   0, 0
EndDataSection
Restore Midgame_Bishop_table
For Datax = 0 To 119 : Read.w Midgame_Bishop_table(Datax) : Next


Global Dim Endgame_Bishop_table.w(119)
DataSection
  Endgame_Bishop_table:
   Data.w 0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,  -23,  -9, -23,  -5, -9, -16,  -5, -17,  0,  0,  -14, -18,  -7,  -1,  4,  -9, -15, -27,  0,  0,  -12,  -3,   8,  10, 13,   3,  -7, -15,  0,  0,   -6,   3,  13,  19,  7,  10,  -3,  -9,  0,  0,   -3,   9,  12,   9, 14,  10,   3,   2,  0,  0,   2,  -8,   0,  -1, -2,   6,   0,   4,  0,  0,   -8,  -4,   7, -12, -3, -13,  -4, -14,  0,  0,  -14, -21, -11,  -8, -7,  -9, -17, -24,  0,  0,    0,   0,   0,   0,   0,   0,   0,   0,  0,  0,   0,   0,   0,   0,   0,   0,   0,   0, 0
EndDataSection
Restore Endgame_Bishop_table
For Datax = 0 To 119 : Read.w Endgame_Bishop_table(Datax) : Next


Global Dim Midgame_Rook_table.w(119)
DataSection
  Midgame_Rook_table:
   Data.w 0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,  -19, -13,   1,  17,  16,   7, -37, -26, 0,  0,  -44, -16, -20,  -9,  -1,  11,  -6, -71, 0,  0,  -45, -25, -16, -17,   3,   0,  -5, -33, 0,  0,  -36, -26, -12,  -1,   9,  -7,   6, -23, 0,  0,  -24, -11,   7,  26,  24,  35,  -8, -20, 0,  0,   -5,  19,  26,  36,  17,  45,  61,  16, 0, 0,   27,  32,  58,  62,  80,  67,  26,  44,  0,  0,  32,  42,  32,  51,  63,   9,  31,  43, 0,  0,    0,   0,   0,   0,   0,   0,   0,   0,  0,  0,    0,   0,   0,   0,   0,   0,   0,   0, 0
EndDataSection
Restore Midgame_Rook_table
For Datax = 0 To 119 : Read.w Midgame_Rook_table(Datax) : Next


Global Dim Endgame_Rook_table.w(119)
DataSection
  Endgame_Rook_table:
   Data.w 0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,   -9,   2,   3,  -1,  -5, -13,  4, -20,  0,  0,   -6,  -6,   0,   2,  -9,  -9, -11, -3,  0,  0,   -4,   0,  -5,  -1,  -7, -12,  -8, -16,  0,  0,   3,   5,   8,   4,  -5,  -6,  -8, -11,  0,  0,   4,   3,  13,   1,   2,   1,  -1,   2,  0,  0,    7,   7,   7,   5,   4,  -3,  -5,  -3,  0, 0,   11,  13,  13,  11,  -3,   3,   8,   3, 0,  0,   13,  10,  18,  15,  12,  12,   8,   5,  0,  0,    0,   0,   0,   0,   0,   0,   0,   0,  0,  0,   0,   0,   0,   0,   0,   0,   0,   0,  0
EndDataSection
   Restore Endgame_Rook_table
   For Datax = 0 To 119 : Read.w Endgame_Rook_table(Datax) : Next


Global Dim Midgame_Queen_table.w(119)
DataSection
  Midgame_Queen_table:
   Data.w 0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,   -1, -18,  -9,  10, -15, -25, -31, -50, 0,  0,  -35,  -8,  11,   2,   8,  15,  -3,   1, 0,  0,  -14,   2, -11,  -2,  -5,   2,  14,   5, 0,  0,   -9, -26,  -9, -10,  -2,  -4,   3,  -3, 0,  0,  -27, -27, -16, -16,  -1,  17,  -2,   1, 0,  0,  -13, -17,   7,   8,  29,  56,  47,  57, 0,  0,  -30, -49,  -5,   1, -16,  57,  28,  54, 0,  0,  -28,   0,  29,  12,  59,  44,  43,  45, 0,  0,   0,   0,   0,   0,   0,   0,   0,   0,  0,  0,   0,   0,   0,   0,   0,   0,   0,   0, 0
EndDataSection
    Restore Midgame_Queen_table
    For Datax = 0 To 119 : Read.w Midgame_Queen_table(Datax) : Next


Global Dim Endgame_Queen_table.w(119)
DataSection
  Endgame_Queen_table:
   Data.w 0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,   0,   0,   0,   0,   0,   0,  0,   0,  0,  0,  -33, -28, -22, -43,  -5, -32, -20, -41, 0,  0,  -22, -23, -30, -16, -16, -23, -36, -32, 0,  0,  -16, -27,  15,   6,   9,  17,  10,   5, 0,  0,  -18,  28,  19,  47,  31,  34,  39,  23, 0,  0,   3,  22,  24,  45,  57,  40,  57,  36, 0,  0,  -20,   6,   9,  49,  47,  35,  19,   9,  0,  0,  -17,  20,  32,  41,  58,  25,  30,   0, 0,  0,   -9,  22,  22,  27,  27,  19,  10,  20, 0,  0,   0,   0,   0,   0,   0,   0,   0,   0,  0,  0,   0,   0,   0,   0,   0,   0,   0,   0, 0
EndDataSection
   Restore Endgame_Queen_table
   For Datax = 0 To 119 : Read.w Endgame_Queen_table(Datax) : Next


Global Dim Midgame_King_table.w(119) 
DataSection
  Midgame_King_table:
   Data.w 0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,  -15,  36,  1, -54,   8, -28,  30,  14, 0,  0,    1,   7,  -8, -64, -43, -16,   9,   8, 0,  0,  -14, -14, -22, -46, -44, -30, -15, -27, 0,  0,  -49,  -1, -27, -39, -46, -44, -33, -51, 0,  0,  -17, -20, -12, -27, -30, -25, -14, -36, 0,  0,   -9,  24,   2, -16, -20,   6,  22, -22,  0,  0,   29,  -1, -20,  -7,  -8,  -4, -38, -29,  0,  0,  -65,  23,  16, -15, -56, -34,   2,  13, 0,  0,    0,   0,   0,   0,   0,   0,   0,   0,  0,  0,   0,   0,   0,   0,   0,   0,   0,   0, 0
EndDataSection
    Restore Midgame_King_table
    For Datax = 0 To 119 : Read.w Midgame_King_table(Datax) : Next


Global Dim Endgame_King_table.w(119)
DataSection
  Endgame_King_table:
   Data.w 0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,    0,   0,   0,   0,   0,   0,  0,   0,  0,  0,  -53, -34, -21, -11, -28, -14, -24, -43, 0,  0,  -27, -11,   4,  13,  14,   4,  -5, -17, 0,  0,  -19,  -3,  11,  21,  23,  16,   7,  -9, 0,  0,  -18,  -4,  21,  24,  27,  23,   9, -11, 0,  0,   -8,  22,  24,  27,  26,  33,  26,   3,  0,  0,   10,  17,  23,  15,  20,  45,  44,  13, 0,  0,  -12,  17,  14,  17,  17,  38,  23,  11, 0,  0,  -74, -35, -18, -18, -11,  15,   4, -17, 0,  0,    0,   0,   0,   0,   0,   0,   0,   0,  0,  0,    0,   0,   0,   0,   0,   0,   0,   0,  0
EndDataSection
   Restore Endgame_King_table
   For Datax = 0 To 119 : Read.w Endgame_King_table(Datax) : Next


Global Dim WPassPawnBlockSqrs.w(78, 6)                   ; for White table used squares starts at MbxBrd square 61
DataSection
  WPassPawnBlockSqr61:
    Data.w 71,81,72,82,0,0
  EndDataSection
Restore WPassPawnBlockSqr61
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(61,Datax) : Next

DataSection
  WPassPawnBlockSqr62:
    Data.w 72,82,71,73,81,83
  EndDataSection
Restore WPassPawnBlockSqr62
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(62,Datax) : Next

DataSection
  WPassPawnBlockSqr63:
    Data.w 73,83,72,74,82,84
  EndDataSection
Restore WPassPawnBlockSqr63
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(63,Datax) : Next

DataSection
  WPassPawnBlockSqr64:
    Data.w 74,84,73,75,83,85
  EndDataSection
Restore WPassPawnBlockSqr64
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(64,Datax) : Next

DataSection
  WPassPawnBlockSqr65:
    Data.w 75,85,74,76,84,86
  EndDataSection
Restore WPassPawnBlockSqr65
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(65,Datax) : Next

DataSection
  WPassPawnBlockSqr66:
    Data.w 76,86,75,77,85,87
  EndDataSection
Restore WPassPawnBlockSqr66
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(66,Datax) : Next

DataSection
  WPassPawnBlockSqr67:
    Data.w 77,87,76,78,86,88
  EndDataSection
Restore WPassPawnBlockSqr67
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(67,Datax) : Next

DataSection
  WPassPawnBlockSqr68:
    Data.w 78,88,77,87,0,0
  EndDataSection
Restore WPassPawnBlockSqr68
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(68,Datax) : Next

DataSection
  WPassPawnBlockSqr69:
    Data.w 0,0,0,0,0,0
  EndDataSection
Restore WPassPawnBlockSqr69
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(69,Datax) : Next

DataSection
  WPassPawnBlockSqr70:
    Data.w 0,0,0,0,0,0
  EndDataSection
Restore WPassPawnBlockSqr70
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(70,Datax) : Next

DataSection
  WPassPawnBlockSqr71:
    Data.w 81,82,0,0,0,0
  EndDataSection
Restore WPassPawnBlockSqr71
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(71,Datax) : Next

DataSection
  WPassPawnBlockSqr72:
    Data.w 82,81,83,0,0,0
  EndDataSection
Restore WPassPawnBlockSqr72
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(72,Datax) : Next

DataSection
  WPassPawnBlockSqr73:
    Data.w 83,82,84,0,0,0
  EndDataSection
Restore WPassPawnBlockSqr73
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(73,Datax) : Next

DataSection
  WPassPawnBlockSqr74:
    Data.w 84,83,85,0,0,0
  EndDataSection
Restore WPassPawnBlockSqr74
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(74,Datax) : Next

DataSection
  WPassPawnBlockSqr75:
    Data.w 85,84,86,0,0,0
  EndDataSection
Restore WPassPawnBlockSqr75
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(75,Datax) : Next

DataSection
  WPassPawnBlockSqr76:
    Data.w 86,85,87,0,0,0
  EndDataSection
Restore WPassPawnBlockSqr76
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(76,Datax) : Next

DataSection
  WPassPawnBlockSqr77:
    Data.w 87,86,88,0,0,0
  EndDataSection
Restore WPassPawnBlockSqr77
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(77,Datax) : Next

DataSection
  WPassPawnBlockSqr78:
    Data.w 88,87,0,0,0,0
  EndDataSection
Restore WPassPawnBlockSqr78
For Datax = 1 To 6 : Read.w WPassPawnBlockSqrs(78,Datax) : Next

Global Dim WPassRankFactor.w(98) 
DataSection
  WPassRankFactor:
    Data.w 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,2,2,2,2,2,2,2,2,0,0,3,3,3,3,3,3,3,3,0,0,0,0,0,0,0,0,0,0
EndDataSection
Restore WPassRankFactor
For Datax = 0 To 98 : Read.w WPassRankFactor(Datax) : Next

Global Dim BPassRankFactor.w(98)
DataSection
  BPassRankFactor:
    Data.w 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,3,3,3,3,3,3,3,0,0,2,2,2,2,2,2,2,2,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
EndDataSection
Restore BPassRankFactor
For Datax = 0 To 98 : Read.w BPassRankFactor(Datax) : Next

Global Dim BPassPawnBlockSqrs.w(58, 6)
DataSection
  BPassPawnBlockSqr41:
    Data.w 31,32,0,0,0,0
  EndDataSection
Restore BPassPawnBlockSqr41
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(41,Datax) : Next

DataSection
  BPassPawnBlockSqr42:
    Data.w 32,31,33,0,0,0
  EndDataSection
Restore BPassPawnBlockSqr42
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(42,Datax) : Next

DataSection
  BPassPawnBlockSqr43:
    Data.w 33,32,34,0,0,0
  EndDataSection
Restore BPassPawnBlockSqr43
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(43,Datax) : Next

DataSection
  BPassPawnBlockSqr44:
    Data.w 34,33,35,0,0,0
  EndDataSection
Restore BPassPawnBlockSqr44
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(44,Datax) : Next

DataSection
  BPassPawnBlockSqr45:
    Data.w 35,34,36,0,0,0
  EndDataSection
Restore BPassPawnBlockSqr45
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(45,Datax) : Next

DataSection
  BPassPawnBlockSqr46:
    Data.w 36,35,37,0,0,0
  EndDataSection
Restore BPassPawnBlockSqr46
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(46,Datax) : Next

DataSection
  BPassPawnBlockSqr47:
    Data.w 37,36,38,0,0,0
  EndDataSection
Restore BPassPawnBlockSqr47
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(47,Datax) : Next

DataSection
  BPassPawnBlockSqr48:
    Data.w 38,37,0,0,0,0
  EndDataSection
Restore BPassPawnBlockSqr48
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(48,Datax) : Next

DataSection
  BPassPawnBlockSqr49:
    Data.w 0,0,0,0,0,0
  EndDataSection
Restore BPassPawnBlockSqr49
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(49,Datax) : Next

DataSection
  BPassPawnBlockSqr50:
    Data.w 0,0,0,0,0,0
  EndDataSection
Restore BPassPawnBlockSqr50
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(50,Datax) : Next

DataSection
  BPassPawnBlockSqr51:
    Data.w 41,31,42,32,0,0
  EndDataSection
Restore BPassPawnBlockSqr51
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(51,Datax) : Next

DataSection
  BPassPawnBlockSqr52:
    Data.w 42,32,41,31,43,33
  EndDataSection
Restore BPassPawnBlockSqr52
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(52,Datax) : Next

DataSection
  BPassPawnBlockSqr53:
    Data.w 43,33,42,32,44,34
  EndDataSection
Restore BPassPawnBlockSqr53
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(53,Datax) : Next

DataSection
  BPassPawnBlockSqr54:
    Data.w 44,34,43,33,45,35
  EndDataSection
Restore BPassPawnBlockSqr54
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(54,Datax) : Next

DataSection
  BPassPawnBlockSqr55:
    Data.w 45,35,44,34,46,36
  EndDataSection
Restore BPassPawnBlockSqr55
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(55,Datax) : Next

DataSection
  BPassPawnBlockSqr56:
    Data.w 46,36,45,35,47,37
  EndDataSection
Restore BPassPawnBlockSqr56
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(56,Datax) : Next

DataSection
  BPassPawnBlockSqr57:
    Data.w 47,37,46,36,48,38
  EndDataSection
Restore BPassPawnBlockSqr57
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(57,Datax) : Next

DataSection
  BPassPawnBlockSqr58:
    Data.w 48,38,47,37,0,0
  EndDataSection
Restore BPassPawnBlockSqr58
For Datax = 1 To 6 : Read.w BPassPawnBlockSqrs(58,Datax) : Next
