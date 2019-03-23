import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Http

main = Browser.element { init = init, update = update, 
                  subscriptions = subscriptions, view = view }

-- Model 
type alias Model = { request: String, username: String, password: String }
type Msg = GotText (Result Http.Error String) 
         | Username String
         | Password String
         | Submit

baseUrl = "https://mac1xa3.ca/e/rizkally/lab7/"

testPost : Model -> Cmd Msg
testPost model  =
  Http.post
    { url = baseUrl
    , body = Http.stringBody "application/x-www-form-urlencoded" ("username=" ++ model.username ++ "&password=" ++ model.password)
    , expect = Http.expectString GotText
    }

init : () -> (Model, Cmd Msg)
init _ = ( Model "" "" "" , Cmd.none )

-- View

viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
  input [ type_ t, placeholder p, value v, onInput toMsg ] []

view : Model -> Html Msg
view model = div [] [
      text model.request
    , viewInput "text" "Name" model.username Username
    , viewInput "password" "Password" model.password Password
    , button [onClick Submit] [text "Submit"]
    ]

-- Update
update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    GotText (Ok val)    -> ({model | request = val }, Cmd.none)
    GotText (Err error) -> case error of
        Http.BadUrl url   -> ({model | request = "Bad Url:" ++ url}, Cmd.none)
        Http.Timeout      -> ({model | request = "Timeout"}, Cmd.none)
        Http.NetworkError -> ({model | request = "Network Error"}, Cmd.none)
        Http.BadStatus i  -> ({model | request = "Bad Status: " ++ String.fromInt i}, Cmd.none)
        Http.BadBody body -> ({model | request = "Bad Body: " ++ body}, Cmd.none)
    Username username ->
      ({ model | username = username }, Cmd.none)
    Password password ->
      ({model | password = password}, Cmd.none)
    Submit -> (model, testPost model)


-- Subscriptions
subscriptions : Model -> Sub Msg
subscriptions model = Sub.none
