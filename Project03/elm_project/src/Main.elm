import Browser
import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (attribute, class, href, placeholder, type_, id, for)
import Http
import Json.Decode as JDecode
import Json.Encode as JEncode

main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }

bootstrapCSS = 
  let
    tag =  "link"
    attrs = 
      [ attribute "Rel" "stylesheet"
      , attribute "property" "stylesheet"
      , attribute "href" "https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css"
      ]
    children = []
  in
    node tag attrs children

faCSS = 
  let
    tag =  "link"
    attrs = 
      [ attribute "Rel" "stylesheet"
      , attribute "property" "stylesheet"
      , attribute "href" "https://use.fontawesome.com/releases/v5.8.1/css/all.css"
      ]
    children = []
  in
    node tag attrs children

formCSS = 
  let
    tag =  "link"
    attrs = 
      [ attribute "Rel" "stylesheet"
      , attribute "property" "stylesheet"
      , attribute "href" "form.css"
      ]
    children = []
  in
    node tag attrs children

rootUrl : String 
rootUrl = "http://127.0.0.1:80/"

type alias Model = { currentPage : Page
                   , username : String
                   , password : String
                   , error : String
                   }

type Msg = ChangePage Page
         | ChangeUsername String
         | ChangePassword String
         | GotLoginResponse (Result Http.Error String) -- Http Post Response Received
         | GotSignupResponse (Result Http.Error String)
         | PressLogin
         | PressSignup

type Page = HomePage
          | LoginPage
          | SignupPage

init : () -> (Model, Cmd Msg)
init _ = ({ currentPage = HomePage
          , username = ""
          , password = ""
          , error = ""
          }
        , Cmd.none
        )
        
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of  
    ChangePage page      -> ({ model | currentPage = page, error = "" }, Cmd.none)
    ChangeUsername uname -> ({ model | username = uname }, Cmd.none)
    ChangePassword pword -> ({ model | password = pword }, Cmd.none)
    GotLoginResponse result ->
            case result of
                Ok "LoginFailed" -> ({ model | error = "Failed to login." }, Cmd.none)
                Ok _             -> ({ model | currentPage = HomePage, error = "" }, Cmd.none)
                Err error        -> ((handleError model error), Cmd.none)
    GotSignupResponse result ->
            case result of
                Ok "LoggedOut" -> ({ model | error = "Failed to register. Use a different username." }, Cmd.none)
                Ok _           -> ({ model | currentPage = HomePage, error = "" }, Cmd.none)
                Err error      -> (( handleError model error), Cmd.none)
    PressLogin  -> (model, loginPost model)
    PressSignup -> (model, signupPost model)

handleError : Model -> Http.Error -> Model
handleError model error =
    case error of
        Http.BadUrl url   -> { model | error = "Bad URL: " ++ url }
        Http.Timeout      -> { model | error = "Server Timout" }
        Http.NetworkError -> { model | error = "Network Error" }
        Http.BadStatus i  -> { model | error = "Bad Status: " ++ String.fromInt i }
        Http.BadBody body -> { model | error = "Bad Body: " ++ body }

view : Model -> Html Msg
view model =
  div []
    [ bootstrapCSS
    , faCSS
    , formCSS
    , navBar        
    , pageToHTML model.currentPage
    , text model.error
    ]

pageToHTML : Page -> Html Msg
pageToHTML page = case page of
    HomePage   -> div[][]
    LoginPage  -> loginForm
    SignupPage -> signUpForm

loginPost : Model -> Cmd Msg
loginPost model =
    Http.post
        { url = rootUrl ++ "userauth/login/"
        , body = Http.jsonBody <| userEncoder model
        , expect = Http.expectString GotLoginResponse
        }

signupPost : Model -> Cmd Msg
signupPost model =
    Http.post
        { url = rootUrl ++ "userauth/signup/"
        , body = Http.jsonBody <| userEncoder model
        , expect = Http.expectString GotLoginResponse
        }

userEncoder : Model -> JEncode.Value
userEncoder model =
    JEncode.object
        [ ( "username"
          , JEncode.string model.username
          )
        , ( "password"
          , JEncode.string model.password
          )
        ]

navBar = nav [ class "navbar navbar-expand-lg navbar-light bg-light" ]
      [ a [ class "navbar-brand ml-3" ]
        [ text "Reddit" ]
      , button [ attribute "aria-controls" "navbarToggler", attribute "aria-expanded" "false", attribute "aria-label" "Toggle navigation", class "navbar-toggler", attribute "data-target" "#navbarToggler", attribute "data-toggle" "collapse", type_ "button" ]
        [ span [ class "navbar-toggler-icon" ]
          []
        ]
      , div [ class "collapse navbar-collapse", id "navbarToggler" ]
        [ ul [ class "navbar-nav mr-auto mt-2 mt-lg-0" ]
          [ 
            li [ class "nav-item" ]
            [ a [ class "nav-link"
                , href "#"
                , onClick (ChangePage HomePage) ]
              [ i [ class "fas fa-home mr-2" ] [], text "Home" ]
            ]
          , li [ class "nav-item dropdown" ]
            [ a [ attribute "aria-expanded" "false", attribute "aria-haspopup" "true", class "nav-link dropdown-toggle", attribute "data-toggle" "dropdown", href "#", id "navbarDropdownMenuLink" ]
              [ text "Subreddit" ]
            , div [ attribute "aria-labelledby" "navbarDropdownMenuLink", class "dropdown-menu" ]
              [ a [ class "dropdown-item", href "#" ]
                [ text "Action" ]
              , a [ class "dropdown-item", href "#" ]
                [ text "Another action" ]
              , a [ class "dropdown-item", href "#" ]
                [ text "Something else here" ]
              ]
            ]
          ]
          , button [ class "btn btn-outline-primary btn-header ml-3", onClick (ChangePage LoginPage)] [ text "LOG IN" ]
          , button [ class "btn btn-primary ml-3 mr-3", onClick (ChangePage SignupPage)] [ text "SIGN UP" ]
        ]
      ]

loginForm = div [ class "container" ]
  [ div [ class "row" ]
    [ div [ class "col-sm-9 col-md-7 col-lg-5 mx-auto" ]
      [ div [ class "card card-signin my-5" ]
        [ div [ class "card-body" ]
          [ h5 [ class "card-title text-center" ]
            [ text "Log In" ]
          , form [ class "form-signin" ]
            [ div [ class "form-label-group" ]
              [ input [ attribute "autofocus" "", class "form-control", id "inputUsername", placeholder "Username", attribute "required" "", type_ "text", onInput ChangeUsername ]
                []
              , label [ for "inputUsername"]
                [i [ class "fas fa-user mr-2" ] [], text "Username" ]
              ]
            , div [ class "form-label-group" ]
              [ input [ class "form-control", id "inputPassword", placeholder "Password", attribute "required" "", type_ "password", onInput ChangePassword ]
                []
              , label [ for "inputPassword" ]
                [i [ class "fas fa-key mr-2" ] [], text "Password" ]
              ]
            , button [ class "btn btn-lg btn-primary btn-block text-uppercase", type_ "submit", onClick PressLogin ]
              [ text "Log In" ]
            ]
          ]
        ]
      ]
    ]
  ]

signUpForm = div [ class "container" ]
  [ div [ class "row" ]
    [ div [ class "col-sm-9 col-md-7 col-lg-5 mx-auto" ]
      [ div [ class "card card-signin my-5" ]
        [ div [ class "card-body" ]
          [ h5 [ class "card-title text-center" ]
            [ text "Sign Up" ]
          , form [ class "form-signin" ]
            [ div [ class "form-label-group" ]
              [ input [ attribute "autofocus" "", class "form-control", id "inputUsername", placeholder "Username", attribute "required" "", type_ "text", onInput ChangeUsername ]
                []
              , label [ for "inputUsername"]
                [i [ class "fas fa-user mr-2" ] [], text "Username" ]
              ]
            , div [ class "form-label-group" ]
              [ input [ class "form-control", id "inputPassword", placeholder "Password", attribute "required" "", type_ "password", onInput ChangePassword ]
                []
              , label [ for "inputPassword" ]
                [i [ class "fas fa-key mr-2" ] [], text "Password" ]
              ]
            , button [ class "btn btn-lg btn-primary btn-block text-uppercase", type_ "submit", onClick PressSignup ]
              [ text "Sign Up" ]
            ]
          ]
        ]
      ]
    ]
  ]
