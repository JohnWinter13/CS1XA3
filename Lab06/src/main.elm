module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Attribute, Html, div, input, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


main =
    Browser.sandbox { init = init, update = update, view = view }


type alias Model =
    { left : String
    , right : String
    }


init : Model
init =
    { left = "", right = "" }


type Msg
    = Left String
    | Right String


update : Msg -> Model -> Model
update msg model =
    case msg of
        Left newContent ->
            { model | left = newContent }

        Right newContent ->
            { model | right = newContent }


view : Model -> Html Msg
view model =
    div []
        [ input [ placeholder "String 1", value model.left, onInput Left ] []
        , input [ placeholder "String 2", value model.right, onInput Right ] []
        , div [] [ text model.left, text " : ", text model.right ]
        ]
