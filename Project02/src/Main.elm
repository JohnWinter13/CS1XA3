import Browser
import Html exposing (..)
import Html.Events exposing (on, onClick, onMouseDown, onMouseUp, preventDefaultOn)
import Html.Attributes exposing (class, src, attribute, draggable)
import Json.Decode exposing (succeed)

main =
 Browser.sandbox { init = init, update = update, view = view }

stylesheet = 
  let
    tag =  "link"
    attrs = 
      [ attribute "Rel" "stylesheet"
      , attribute "property" "stylesheet"
      , attribute "href" "https://unpkg.com/tachyons@4.10.0/css/tachyons.min.css"
      ]
    children = []
  in
    node tag attrs children

stylesheet2 = 
  let
    tag =  "link"
    attrs = 
      [ attribute "Rel" "stylesheet"
      , attribute "property" "stylesheet"
      , attribute "href" "css/main.css"
      ]
    children = []
  in
    node tag attrs children

type alias Board     = List (List Square)
type alias Position  = (Int, Int)
type alias Highlight = Bool
type Square          = Occupied Piece Highlight | Empty Highlight
type Piece           = Piece Color Role
type Color           = White | Black
type Role            = Pawn  | Bishop | Knight | Rook | Queen | King   

initialBoard : Board
initialBoard = [ [Occupied (Piece Black Rook) False, Occupied (Piece Black Knight) False, Occupied (Piece Black Bishop) False, Occupied (Piece Black Queen) False, Occupied (Piece Black King) False, Occupied (Piece Black Bishop) False, Occupied (Piece Black Knight) False, Occupied (Piece Black Rook) False],
                 [Occupied (Piece Black Pawn) False, Occupied (Piece Black Pawn) False, Occupied (Piece Black Pawn) False, Occupied (Piece Black Pawn) False, Occupied (Piece Black Pawn) False, Occupied (Piece Black Pawn) False, Occupied (Piece Black Pawn) False, Occupied (Piece Black Pawn) False],
                 [Empty False, Empty False, Empty False, Empty False, Empty False, Empty False, Empty False, Empty False],
                 [Empty False, Empty False, Empty False, Empty False, Empty False, Empty False, Empty False, Empty False],
                 [Empty False, Empty False, Empty False, Empty False, Empty False, Empty False, Empty False, Empty False],
                 [Empty False, Empty False, Empty False, Empty False, Empty False, Empty False, Empty False, Empty False],
                 [Occupied (Piece White Pawn) False, Occupied (Piece White Pawn) False, Occupied (Piece White Pawn) False, Occupied (Piece White Pawn) False, Occupied (Piece White Pawn) False, Occupied (Piece White Pawn) False, Occupied (Piece White Pawn) False, Occupied (Piece White Pawn) False],
                 [Occupied (Piece White Rook) False, Occupied (Piece White Knight) False, Occupied (Piece White Bishop) False, Occupied (Piece White Queen) False, Occupied (Piece White King) False, Occupied (Piece White Bishop) False, Occupied (Piece White Knight) False, Occupied (Piece White Rook) False]
               ]   

--Renders a square on the gameboard
--Also attaches the drop events detectors if the square should be highlighted (ie it can be moved to)
renderSquare : Square -> Position -> Html Msg
renderSquare square (x, y) = case square of
    Occupied piece highlight -> if highlight then div [ class ("h3 w3 " ++ squareColor (x + y) highlight), onDragOver DragOver, onDrop <| Drop (x, y) ] [ pieceImg piece (x, y) ]
                                else div [ class ("h3 w3 " ++ squareColor (x + y) highlight)] [ pieceImg piece (x, y) ]
    Empty highlight          -> if highlight then div [ class ("h3 w3 " ++ squareColor (x + y) highlight), onDragOver DragOver, onDrop <| Drop (x, y) ] []
                                else div [ class ("h3 w3 " ++ squareColor (x + y) highlight)] []

--Renders a row on the gameboard
renderRow : List Square -> Int -> Html Msg
renderRow row n = List.indexedMap (\i square -> renderSquare square (i, n)) row |> div [ class "flex" ]

--Renders the entire gameboard 
renderBoard : Board -> Html Msg
renderBoard board = List.indexedMap (\i row -> renderRow row i) board |> div []

squareColor : Int -> Highlight -> String
squareColor n highlight = if highlight then "c-bg-highlight" else
                            if modBy 2 n == 0 then "c-bg-light" else "c-bg-dark"

--Attach events found in our Msg type, will be triggered on those events and pass in necessary info
dragEventListeners : Piece -> Position -> List (Html.Attribute Msg)
dragEventListeners piece pos =
    [ onMouseDown (CheckPossibleMoves piece pos)
    , onMouseUp RemovePossilbeMoves
    , draggable "true"
    , onDragStart <| Drag piece pos
    , onDragEnd DragEnd
    ]

--Helper functions to allow us to handle drag events
onDragStart : Msg -> Html.Attribute Msg
onDragStart msg = on "dragstart" <| succeed msg

onDragEnd : Msg -> Html.Attribute Msg
onDragEnd msg = on "dragend" <| succeed msg

onDragOver : Msg -> Html.Attribute Msg
onDragOver msg = preventDefaultOn "dragover" <| succeed ( msg, True )

onDrop : Msg -> Html.Attribute Msg
onDrop msg = preventDefaultOn "drop" <| succeed ( msg, True )

--Attach the piece's image and the drag event listeners
pieceImg : Piece -> Position -> Html Msg
pieceImg piece pos = img ([ src <| pieceImgStr piece ] ++ dragEventListeners piece pos) []

--Choose the correct image for our piece
pieceImgStr : Piece -> String
pieceImgStr piece = case piece of
    Piece Black Rook   -> "img/br.png"
    Piece Black Knight -> "img/bn.png"
    Piece Black Bishop -> "img/bb.png"
    Piece Black Queen  -> "img/bq.png"
    Piece Black King   -> "img/bk.png"
    Piece Black Pawn   -> "img/bp.png"
    Piece White Rook   -> "img/wr.png"
    Piece White Knight -> "img/wn.png"
    Piece White Bishop -> "img/wb.png"
    Piece White Queen  -> "img/wq.png"
    Piece White King   -> "img/wk.png"
    Piece White Pawn   -> "img/wp.png"

--Generates all possible (legal) moves for the piece at the current position, given the current board state and the color of the player (to detect whoose turn it is)
--If the piece's color is not the same as the given color, then there are no legal moves (it is not the player's turn).
--NOTE that this currently does not detect checks, in which case the player will be able to make a move that puts or keeps them in check. 
legalMoves : Piece -> Position -> Board -> Color -> List Position
legalMoves piece pos board color = let possMoves = if getPieceColor piece == color then possibleMoves piece pos board color else []
                                     in List.filter (isNotTeamKill piece board) possMoves

--Generates all possible moves for a given piece
possibleMoves : Piece -> Position -> Board -> Color -> List Position
possibleMoves piece pos board color = case piece of
    Piece _ Rook     -> rookMoves pos board color
    Piece _ Knight   -> knightMoves pos
    Piece _ Bishop   -> bishopMoves pos board color
    Piece _ Queen    -> queenMoves pos board color
    Piece _ King     -> kingMoves pos
    Piece Black Pawn -> pawnBlackMoves pos board
    Piece White Pawn -> pawnWhiteMoves pos board

--The upper bound on our map's dimensions
posHi : Int 
posHi = 7

--The lower bound on our map's dimensions
posLo : Int 
posLo = 0

--Returns true if the given position lies within the map's dimensions
inRange : Position -> Bool
inRange (x, y) = x <= posHi && x >= posLo && y <= posHi && y >= posLo

--Returns true if the piece given does NOT have the same color as the piece at the given position
isNotTeamKill : Piece -> Board -> Position -> Bool
isNotTeamKill piece board pos = let sqColor = getColorAtPosition pos board in
                              case sqColor of
                                  Just c -> c /= getPieceColor piece                                                       
                                  Nothing -> True

--Returns the color of the piece at the given position, and Nothing if the position is empty                                      
getColorAtPosition : Position -> Board -> Maybe Color
getColorAtPosition pos board = let square = getSquareAt pos board
                                in case square of
                                  Occupied piece highlight -> Just (getPieceColor piece)
                                  Empty highlight -> Nothing

--Returns True if the given position is empty
isPositionEmpty : Board -> Position -> Bool
isPositionEmpty board pos = let square = getSquareAt pos board
                              in case square of
                                Occupied piece highlight -> False
                                Empty highlight -> True

--Returns the color of the given piece                                  
getPieceColor : Piece -> Color
getPieceColor piece = case piece of
    Piece Black _ -> Black
    Piece White _ -> White

--Returns true if the color given does NOT equal the color of the piece at the given position
isPawnEnemy : Color -> Board -> Position -> Bool
isPawnEnemy color board pos = let enemyColor = getColorAtPosition pos board 
                                in case enemyColor of
                                    Just c -> c /= color                                                                     
                                    Nothing -> False

--Returns a list of possible diagonal captures for a black pawn at the given position (does NOT support en passant)                                 
blackPawnCapture : Position -> Board -> List Position
blackPawnCapture (x, y) board = List.filter (isPawnEnemy Black board) [(y + 1, x + 1), (y + 1, x - 1)]

--Returns a list of possible black pawn moves            
pawnBlackMoves : Position -> Board -> List Position 
pawnBlackMoves (x, y) board = List.filter (isPositionEmpty board) [(y + 1, x)] ++ (if y == posLo + 1 then [(y + 2, x)] else []) ++ blackPawnCapture (x, y) board

--Returns a list of possible diagonal captures for a white pawn at the given position (does NOT support en passant)   
whitePawnCapture : Position -> Board -> List Position
whitePawnCapture (x, y) board = List.filter (isPawnEnemy White board) [(y - 1, x + 1), (y - 1, x - 1)]

--Returns a list of possible white pawn moves
pawnWhiteMoves : Position -> Board -> List Position 
pawnWhiteMoves (x, y) board = List.filter (isPositionEmpty board) [(y - 1, x)] ++ (if y == posHi - 1 then [(y - 2, x)] else []) ++ whitePawnCapture (x, y) board

--Returns a list of possible consecutive moves (moves that are unblocked by a piece)
--If the first piece we encounter is the same color that we have, then immediatly stop
--otherwise include that piece (can be captured by us) and stop
sweepKillFilter : List Position -> List Position -> Board -> Color -> List Position
sweepKillFilter moves newMoves board color = case moves of
    (x::xs) -> let maybeColor    = getColorAtPosition x board 
                   continue      = sweepKillFilter xs  (x :: newMoves) board color
                in case maybeColor of
                    Just c -> if c == color then newMoves else (x :: newMoves)                      
                    Nothing -> continue
                        
    [] -> newMoves

--Returns a list of all possible rook moves
rookMoves : Position -> Board -> Color -> List Position
rookMoves (x, y) board color = List.filter inRange(
    sweepKillFilter [ (y, x + 1), (y, x + 2), (y, x + 3), (y, x + 4), (y, x + 5), (y, x + 6), (y, x + 7)] [] board color ++
    sweepKillFilter [ (y, x - 1), (y, x - 2), (y, x - 3), (y, x - 4), (y, x - 5), (y, x - 6), (y, x - 7)] [] board color ++
    sweepKillFilter [ (y + 1, x), (y + 2, x), (y + 3, x), (y + 4, x), (y + 5, x), (y + 6, x), (y + 7, x)] [] board color ++
    sweepKillFilter [ (y - 1, x), (y - 2, x), (y - 3, x), (y - 4, x), (y - 5, x), (y - 6, x), (y - 7, x)] [] board color)

--Returns a list of all possible bishop moves
bishopMoves : Position -> Board -> Color -> List Position
bishopMoves (x, y) board color = List.filter inRange(
    sweepKillFilter [ (y + 1, x + 1), (y + 2, x + 2), (y + 3, x + 3), (y + 4, x + 4), (y + 5, x + 5), (y + 6, x + 6),(y + 7, x + 7) ] [] board color ++
    sweepKillFilter [ (y - 1, x - 1), (y - 2, x - 2), (y - 3, x - 3), (y - 4, x - 4), (y - 5, x - 5), (y - 6, x - 6),(y - 7, x - 7) ] [] board color ++
    sweepKillFilter [ (y + 1, x - 1), (y + 2, x - 2), (y + 3, x - 3), (y + 4, x - 4), (y + 5, x - 5), (y + 6, x - 6),(y + 7, x - 7) ] [] board color ++
    sweepKillFilter [ (y - 1, x + 1), (y - 2, x + 2), (y - 3, x + 3), (y - 4, x + 4), (y - 5, x + 5), (y - 6, x + 6),(y - 7, x + 7) ] [] board color)
    
--Returns a list of all possible queen moves
queenMoves : Position -> Board -> Color -> List Position
queenMoves pos board color = rookMoves pos board color ++ bishopMoves pos board color

--Returns a list of all possible king moves
kingMoves : Position -> List Position
kingMoves (x, y) = List.filter inRange
    [ (y - 1, x - 1)
    , (y - 1, x)
    , (y - 1, x + 1)
    , (y, x - 1)
    , (y, x + 1)
    , (y + 1, x - 1)
    , (y + 1, x)
    , (y + 1, x + 1)
    ]

--Returns a list of all possible knight moves
knightMoves : Position -> List Position
knightMoves (x, y) = List.filter inRange
    [ (y - 2, x + 1)
    , (y - 2, x - 1)
    , (y + 2, x + 1)
    , (y + 2, x - 1)
    , (y + 1, x + 2)
    , (y - 1, x + 2)
    , (y + 1, x - 2)
    , (y - 1, x - 2)
    ]

--Updates a square at the given position and returns the resulting board
updateSquare : Position -> Board -> Square -> Board
updateSquare (x, y) board square = List.reverse (updateSquareAux 0 (x, y) board square [])

--A helper function for the updateSquare function 
--Keep appending the same row unless it is the row of interest (has the same index as our x co-ordinate)
--Remember to reverse the list since we are appending to the beginning of the list, so if we do not reverse it
--then the resulting Board will be flipped
updateSquareAux : Int -> Position -> Board -> Square -> Board -> Board
updateSquareAux index (x, y) board square newBoard = case board of
    (row::rows) -> if index == x then updateSquareAux (index + 1) (x, y) rows square (List.reverse(updateR 0 y row square []) :: newBoard)
                    else updateSquareAux (index + 1) (x, y) rows square (row :: newBoard)
    [] -> newBoard

--Update a row at the given index
updateR : Int -> Int -> List Square -> Square -> List Square -> List Square
updateR index goalIndex row square newRow = case row of
    (x::xs) -> if index == goalIndex then updateR (index + 1) goalIndex xs square (square :: newRow) 
                else updateR (index + 1) goalIndex xs square (x :: newRow)
    []      -> newRow
        
--Similar to the (!!) operator in haskell
atIndex : List a -> Int ->  Maybe a
atIndex xs n  = List.head (List.drop n xs)

--Returns the square at the given position
getSquareAt : Position -> Board -> Square 
getSquareAt pos board = getSquareAtAux pos board 0

--Helper function for getSquareAt
getSquareAtAux : Position -> Board -> Int -> Square 
getSquareAtAux (x, y) board index = case board of
    (b::bs) -> if index == x then let row = atIndex b y 
                  in case row of
                    Just r  -> r
                    Nothing -> Empty False
               else getSquareAtAux (x, y) bs (index + 1)
    []      -> Empty False
        
--Returns the same square, but highlighted
highlightSquare : Square -> Square
highlightSquare square = case square of
    Occupied piece highlight -> Occupied piece True
    Empty highlight -> Empty True

--Given a list of positions, returns a list of squares corressponding to the pieces at those positions  
posToSquares : List Position -> Board -> List Square         
posToSquares xs board = List.map(\move -> getSquareAt move board) xs

--Given a list of squares, returns a list of the same squares, but highlighted
highlightSquares : List Square -> List Square
highlightSquares xs = List.map highlightSquare xs

--Given a list of positions, updates the board with those positions
updateMovesBoard : List Position -> Board -> Board
updateMovesBoard moves board = case moves of
    (m::ms) -> let newBoard = updateSquare m board (highlightSquare (getSquareAt m board))
                in updateMovesBoard ms newBoard
    []      -> board

--Returns the opposite color
swapColor : Color -> Color
swapColor color = case color of
    Black -> White
    White -> Black

--Moves a piece to a new position on the given board, and returns a new board        
movePiece : Piece -> Position -> Board -> Board
movePiece piece (x, y) board = updateSquare (y, x) board (Occupied piece False)

--Sets the board to an Empty and unhighlighted square at the given position, and returns a new board
removePiece : Piece -> Position -> Board -> Board
removePiece piece (x, y) board = updateSquare (y, x) board (Empty False)

type Msg
    = CheckPossibleMoves Piece Position
    | RemovePossilbeMoves
    | Drag Piece Position
    | DragEnd
    | DragOver
    | Drop Position

type alias Model =
    { board : Board
    , boardNoHighlights : Board
    , pieceDragging : Maybe ( Piece, Position )
    , color : Color
    }

init : Model
init =
    { board = initialBoard
    , boardNoHighlights = initialBoard
    , pieceDragging = Nothing
    , color = White
    }

view : Model -> Html Msg
view model =
  div []
  [ stylesheet
  , stylesheet2
  , div 
    [ class "mt4 flex justify-center" ] 
    [
      renderBoard model.board   
    ] 
  ]

update : Msg -> Model -> Model
update msg model = case msg of

      CheckPossibleMoves piece pos ->        
            let moves = legalMoves piece pos model.board model.color
            in { model | board = updateMovesBoard moves model.board }
      
      RemovePossilbeMoves -> { model | board = model.boardNoHighlights }

      Drag piece pos -> { model | pieceDragging = Just (piece, pos) } 

      DragEnd -> { model | pieceDragging = Nothing, board = model.boardNoHighlights }

      DragOver -> model

      Drop targetPos -> case model.pieceDragging of
          Just (piece, pos) -> { model | color = swapColor model.color
                                       , pieceDragging = Nothing
                                       , board = model.boardNoHighlights |> removePiece piece pos |> movePiece piece targetPos
                                       , boardNoHighlights = model.boardNoHighlights |> removePiece piece pos |> movePiece piece targetPos }
          Nothing -> model
 