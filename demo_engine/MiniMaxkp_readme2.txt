This chess engine is a conversion/fairly-complete-rewrite of Minimax in PureBasic by kenpchess in 2026.
Most of the conversion/rewrite by kenpchess was done during the covid pandemic around 2020-2021 and was just re-converted to PureBasic by kenpchess in 2026.
 
The original authors were D. Steinwender, Ch. Donninger, May 1, 1995, in QBasic (?)
and a FreeBASIC adaptation from S. Budinov and the CECP protocol implementation from a nice gentleman
and good programmer, Roland Chastain.

======================================================================

Mostly rewritten by kenpchess (complete new movegen, complete new PST-based eval, new zobrist history and transposition tables, (not fully turned on yet), parsing of FEN positions, some king safety, minimal time management, tt data structures, more misc., etc.

This is a rather weak console engine and is meant to be a didactic (educational) example of a chess engine written in PureBasic for those chess engine enthusiasts (like myself) that do not program in C or C++ but want to see what the structure of a beginning chess engine looks like. 

======================================================================

Mini-Instructions:

The binary files named MiniMaxkp_20260425 (MacOS and Windows) are really console-only (terminal) executables and thus should be run from a terminal window. It is possible that it might run under a chess GUI since it supports a subset of the CECP (xboard) protocol but I believe this is buggy in the current incarnation of the program.

The source files are MiniMaxkp_20260425.pb, Piece_Square_Tables_etc.pb, and Zobrist_table_values.pb, which are the complete PureBasic sources, and this readme file, Minimaxkp_readme.txt. I am sure there are some bugs in this code if nothing else because of the multiple conversion/rewrites. But it runs and plays "passable" chess and demonstrates in simple (but powerful) Basic how many chess coding features work.

When running this engine you can give some limited xboard commands like "st 10", which means 10 seconds per move (the engine does not fully adhere to the time command, but is fairly close). Mostly you simply type a long algebraic move in the format "e2e4" (notice no hyphen), hit <return> and then type "go" (another xboard command) and another <return>. You should receive a return move and an ascii-printed chessboard of the current position. (You can always type "board" at the engine prompt to print the board).

I am not sure it matters but since this is a conversion/rewrite of a previously public domain program I am licensing it under the Creative-Commons license that just basically prohibits commercial use.



File Locations:

The above mentioned source and binary files should be in an "engine_demo" subdirectory at my github repository site for my chess pgn viewer/db utility which is:


https://github.com/kenpchess/PGNdbkp_master


Have fun and feel free to modify/improve the sources for your own chess engine/programming enjoyment and education!

-kenpchess
