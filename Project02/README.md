# Project 02

## Part 1

Part 1 involves creating a professional resume that can be displayed on a web page. 
The resume can be accessed by opening `webpagecv.html`.

This resume uses a modified version of the template found  [here](https://startbootstrap.com/themes/resume/).

## Part 2 - Chess

Part 2 involves creating a simple web app using Elm or JavaScript.
I chose to implement a two-player chess game in Elm.

## Features

- Turn-based simulation between two players built in Elm
- Turns alternate between white and black, and allow the player to drag the piece to the desired location
- Automatic detection of valid moves, displayed by highlighting squares when player starts to drag a piece. A player will only be able to move a piece if it is a legal move and if it is his turn.
- Complete implementation of rules for several different pieces**
- - A rook can move horizontally or vertically
- - A bishop can move diagonally
- - A queen has the combined moveset of the rook and bishop
- - A pawn can move two tiles if it is its first move, and one otherwise. It can also capture a piece diagonally and cannot capture a piece by moving forward.
- - A knight can hop over pieces in an L-shape.
- - The king can move one square in any direction
- - All pieces can only move if not blocked, except for the knight
- - All pieces cannot capture friendly pieces
- - **See Limitations

## Limitations
- No support for en passant captures
- No support for castling
- No support for pawn promotions
- No checkmate detection (ie a player can illegally walk himself into a check)