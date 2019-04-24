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
                   , newPostTitle : String
                   , newPostContent : String
                   , error : String
                   , isLoggedIn : Bool
                   , threads : List Thread
                   }

type Msg = ChangePage Page
         | ChangeUsername String
         | ChangePassword String
         | ChangeNewPostTitle String
         | ChangeNewPostContent String
         | GotLoginResponse (Result Http.Error String) -- Http Post Response Received
         | GotSignupResponse (Result Http.Error String)
         | GotLogoutResponse (Result Http.Error String)
         | GotNewThreadResponse (Result Http.Error String)
         | GotThreadsJSON (Result Http.Error (List Thread))
         | PressLogin
         | PressSignup
         | PressLogout
         | PressNewPost

type Page = HomePage
          | LoginPage
          | SignupPage
          | NewPostPage

type alias Thread = { title: String
                    , date: String
                    , content: String
                    , username: String
                    , isMaster: Bool
                    , parentID: Maybe Int
                    , id: Int
                    }

init : () -> (Model, Cmd Msg)
init _ = ({ currentPage = HomePage
          , username = ""
          , password = ""
          , newPostTitle = ""
          , newPostContent = ""
          , error = ""
          , isLoggedIn = False
          , threads = []
          }
        , threadsGet
        )
        
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of  
    ChangePage page              -> ({ model | currentPage = page, error = "" }, Cmd.none)
    ChangeUsername uname         -> ({ model | username = uname }, Cmd.none)
    ChangePassword pword         -> ({ model | password = pword }, Cmd.none)
    ChangeNewPostTitle title     -> ({ model | newPostTitle = title }, Cmd.none)
    ChangeNewPostContent content -> ({ model | newPostContent = content }, Cmd.none)

    GotLoginResponse result ->
            case result of
                Ok "LoginFailed" -> ({ model | error = "Failed to login." }, Cmd.none)
                Ok _             -> ({ model | currentPage = HomePage, error = "", isLoggedIn = True }, Cmd.none)
                Err error        -> ((handleError model error), Cmd.none)
    GotSignupResponse result ->
            case result of
                Ok "EmptyUsername" -> ({ model | error = "Spaces in usernames are not allowed." }, Cmd.none)
                Ok _               -> ({ model | currentPage = HomePage, error = "", isLoggedIn = True }, Cmd.none)
                Err error          -> ({ model | error = "Failed to register. Try using a different username." }, Cmd.none)
    GotLogoutResponse result ->
            case result of
                Ok "LoggedOut" -> ({ model | currentPage = LoginPage, error = "", username = "", password = "", isLoggedIn = False }, Cmd.none)
                Ok _           -> ({model | currentPage = LoginPage}, Cmd.none)
                Err error      -> (( handleError model error), Cmd.none)
    GotThreadsJSON result ->
            case result of
                Ok newThreads  -> ({model | threads = newThreads}, Cmd.none)
                Err error      -> (( handleError model error), Cmd.none)
    GotNewThreadResponse result ->
            case result of
                Ok "Success" -> ({model | currentPage = HomePage, newPostTitle = "", newPostContent = ""}, threadsGet)
                Ok _         -> ({model | error = "Failed to make new post"}, Cmd.none)    
                Err error    -> (( handleError model error), Cmd.none)
                    

    PressLogin   -> (model, loginPost model)
    PressSignup  -> (model, signupPost model)
    PressLogout  -> (model, logoutPost model)
    PressNewPost -> (model, newThreadPost model)

handleError : Model -> Http.Error -> Model
handleError model error =
    case error of
        Http.BadUrl url   -> { model | error = "Bad URL: " ++ url }
        Http.Timeout      -> { model | error = "Server Timout" }
        Http.NetworkError -> { model | error = "Network Error" }
        Http.BadStatus i  -> { model | error = "Bad Status: " ++ String.fromInt i }
        Http.BadBody body -> { model | error = "Bad Body: " ++ body }

pageToHTML : Model -> Html Msg
pageToHTML model = case model.currentPage of
    HomePage    -> homePage model.isLoggedIn model.threads
    LoginPage   -> loginForm model.error
    SignupPage  -> signUpForm model.error
    NewPostPage -> newPostForm model.error

getReplies : Int -> List Thread -> List Thread
getReplies targetID threads = List.filter (\thread -> (doesIDMatch thread.parentID targetID)) threads

doesIDMatch : Maybe Int -> Int -> Bool
doesIDMatch id targetID = case id of
    Just i  -> i == targetID
    Nothing -> False
        
    
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
        , expect = Http.expectString GotSignupResponse
        }

logoutPost : Model -> Cmd Msg
logoutPost model =
    Http.post
        { url = rootUrl ++ "userauth/logout/"
        , body = Http.jsonBody <| userEncoder model
        , expect = Http.expectString GotLogoutResponse
        }

newThreadPost : Model -> Cmd Msg
newThreadPost model =
    Http.post
        { url = rootUrl ++ "threads/addthread/"
        , body = Http.jsonBody <| newThreadEncoder model
        , expect = Http.expectString GotNewThreadResponse
        }

threadsGet : Cmd Msg
threadsGet =
    Http.get 
        {
          url = rootUrl ++ "threads/getthreads/"
        , expect = Http.expectJson GotThreadsJSON threadsDecoder 
        }

newThreadEncoder : Model -> JEncode.Value
newThreadEncoder model =
    JEncode.object
        [ ( "title"
          , JEncode.string model.newPostTitle
          )
        , ( "is_master"
          , JEncode.bool True
          )
        , ( "content"
          , JEncode.string model.newPostContent
          )
        , ( "user"
          , JEncode.string model.username
          )
        ]

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

threadsDecoder : JDecode.Decoder (List Thread)
threadsDecoder =  JDecode.at["threads"] (JDecode.list threadDecoder)

threadDecoder : JDecode.Decoder Thread
threadDecoder = JDecode.map7 Thread
        (JDecode.field "title" JDecode.string)
        (JDecode.field "date" JDecode.string)
        (JDecode.field "content" JDecode.string)
        (JDecode.field "user" JDecode.string)
        (JDecode.field "is_master" JDecode.bool)
        (JDecode.maybe(JDecode.field "parent" JDecode.int))
        (JDecode.field "pkid" JDecode.int)

view : Model -> Html Msg
view model =
  div []
    [ bootstrapCSS
    , faCSS
    , formCSS
    , navbar model    
    , pageToHTML model
    , text model.error
    ]

navbar : Model -> Html Msg
navbar model = nav [ class "navbar navbar-expand-lg navbar-light bg-light" ]
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
              [ i [ class "fab fa-reddit-alien mr-2" ] [], text "Subreddit" ]
            , div [ attribute "aria-labelledby" "navbarDropdownMenuLink", class "dropdown-menu" ]
              [ a [ class "dropdown-item", href "#" ]
                [ text "Action" ]
              , a [ class "dropdown-item", href "#" ]
                [ text "Another action" ]
              , a [ class "dropdown-item", href "#" ]
                [ text "Something else here" ]
              ]
            ]
          , if model.isLoggedIn then li [ class "nav-item" ]
            [
              a [ class "nav-link"
                , href "#"
                , onClick (ChangePage NewPostPage) 
                ]
              [ i [ class "fas fa-clone mr-2" ] [], text "New Post" ]
            ] else div[][] 
          ]
          , navBarButtonsRight model
        ]
      ]

navBarButtonsRight : Model -> Html Msg
navBarButtonsRight model = if model.isLoggedIn then div[][
                                  text ("Hello, " ++ model.username)
                                , button [ class "btn btn-primary ml-3", onClick PressLogout] [ text "LOG OUT" ]]
                           else div[][
                                  button [ class "btn btn-outline-primary ml-3", onClick (ChangePage LoginPage)] [ text "LOG IN" ]
                                , button [ class "btn btn-primary ml-3 mr-3", onClick (ChangePage SignupPage)] [ text "SIGN UP" ]]

homePage : Bool -> List Thread -> Html Msg
homePage isLoggedIn threads = if isLoggedIn then div[][text "Logged in!", threadsView threads] else div[][threadsView threads]

threadsView : List Thread -> Html Msg 
threadsView threads = div [] (List.map (\thread -> threadView thread threads) threads)

threadView : Thread -> List Thread -> Html Msg
threadView thread threads = div [ class "container"]
  [ div [ class "card my-5"]
    [
      div [class "card-header"] [text ("Posted by " ++ thread.username ++ " at " ++ thread.date)]
    , div [ class "thread-body" ] 
      [
        h4 [] [text thread.title]
      , div [] 
        [ button [class "btn thread-button"] [i [ class "fas fa-comment mr-2" ] [], text (String.fromInt (List.length(getReplies thread.id threads)) ++ " comments")]
        , button [class "btn thread-button"] [i [ class "fas fa-star mr-2" ] [], text "Give Award"]
        , button [class "btn thread-button"] [i [ class "fas fa-share mr-2" ] [], text "Share"]
        ]    
      ]
    ]
  ]

newPostForm : String -> Html Msg
newPostForm error = div [ class "container" ]
  [ div [ class "row" ]
    [ div [ class "col-sm-9 col-md-7 col-lg-9 mx-auto" ]
      [ div [ class "card card-signin my-5" ]
        [ div [ class "card-body" ]
          [ h5 [ class "card-title text-center" ]
            [ text "Create a New Post" ]
          , form [ class "form-signin" ]
            [ div [ class "form-label-group" ]
              [ input [ attribute "autofocus" "", class "form-control", id "inputTitle", placeholder "Title", attribute "required" "", type_ "text", onInput ChangeNewPostTitle ]
                []
              , label [ for "inputTitle"]
                [i [ class "fas fa-blog mr-2" ] [], text "Title" ]
              ]
            , div [ class "form-label-group" ]
              [ textarea [ for "inputContent", class "form-control", placeholder "Content", onInput ChangeNewPostContent ] [] ]
            , h6 [ class "error-msg" ] [text error]
            , button [ class "btn btn-lg btn-primary btn-block text-uppercase", type_ "submit", onClick PressNewPost ]
              [ text "Make Post" ]
            ]
          ]
        ]
      ]
    ]
  ]

loginForm : String -> Html Msg
loginForm error = div [ class "container" ]
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
            , h6 [ class "error-msg" ] [text error]
            , button [ class "btn btn-lg btn-primary btn-block text-uppercase", type_ "submit", onClick PressLogin ]
              [ text "Log In" ]
            ]
          ]
        ]
      ]
    ]
  ]

signUpForm : String -> Html Msg
signUpForm error = div [ class "container" ]
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
            , h6 [ class "error-msg" ] [text error]
            , button [ class "btn btn-lg btn-primary btn-block text-uppercase", type_ "submit", onClick PressSignup ]
              [ text "Sign Up" ]
            ]
          ]
        ]
      ]
    ]
  ]
