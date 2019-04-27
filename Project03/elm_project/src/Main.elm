import Browser
import Html exposing (..)
import Html.Events exposing (onClick, onInput, onFocus, onMouseEnter)
import Html.Attributes exposing (attribute, class, href, placeholder, type_, id, for, readonly)
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
                   , newSubName : String
                   , newSubDescription : String
                   , error : String
                   , isLoggedIn : Bool
                   , threads : List Thread
                   , subs : List Sub
                   , currentThreadID : Int
                   }

type Msg = ChangePage Page
         | ChangeUsername String
         | ChangePassword String
         | ChangeNewPostTitle String
         | ChangeNewPostContent String
         | ChangeNewSubName String
         | ChangeNewSubDescription String
         | ChangeMainThread Int
         | GotLoginResponse (Result Http.Error String) -- Http Post Response Received
         | GotSignupResponse (Result Http.Error String)
         | GotLogoutResponse (Result Http.Error String)
         | GotNewThreadResponse (Result Http.Error String)
         | GotNewSubResponse (Result Http.Error String)
         | GotThreadsJSON (Result Http.Error (List Thread))
         | GotSubsJSON (Result Http.Error (List Sub))
         | PressLogin
         | PressSignup
         | PressLogout
         | PressNewPost
         | PressNewReply
         | PressNewSub

type Page = HomePage
          | LoginPage
          | SignupPage
          | NewPostPage
          | NewReplyPage
          | NewSubPage
          | ThreadPage
          | SubsPage

type alias Thread = { title: String
                    , date: String
                    , content: String
                    , username: String
                    , isMaster: Bool
                    , parentID: Maybe Int
                    , id: Int
                    , subID: Int
                    }

type alias Sub = { name: String
                 , description: String
                 , id: Int
                 }

init : () -> (Model, Cmd Msg)
init _ = ({ currentPage = HomePage
          , username = ""
          , password = ""
          , newPostTitle = ""
          , newPostContent = ""
          , newSubName = ""
          , newSubDescription = ""
          , error = ""
          , isLoggedIn = False
          , threads = []
          , subs = []
          , currentThreadID = 0
          }
        , Cmd.batch [threadsGet, subsGet]
        )
        
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of  
    ChangePage page              -> ({ model | currentPage = page, error = "" }, Cmd.none)
    ChangeUsername uname         -> ({ model | username = uname }, Cmd.none)
    ChangePassword pword         -> ({ model | password = pword }, Cmd.none)
    ChangeNewPostTitle title     -> ({ model | newPostTitle = title }, Cmd.none)
    ChangeNewPostContent content -> ({ model | newPostContent = content }, Cmd.none)
    ChangeNewSubName name        -> ({ model | newSubName = name}, Cmd.none)
    ChangeNewSubDescription desc -> ({ model | newSubDescription = desc}, Cmd.none)
    ChangeMainThread newThreadID -> ({ model | currentThreadID = newThreadID}, Cmd.none)

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
    GotSubsJSON result ->
            case result of
                Ok newSubs -> ({model | subs = newSubs}, Cmd.none)
                Err error  -> (( handleError model error), Cmd.none)            
    GotNewThreadResponse result ->
            case result of
                Ok "Success" -> ({model | currentPage = HomePage, newPostTitle = "", newPostContent = ""}, threadsGet)
                Ok _         -> ({model | error = "Failed to make new post"}, Cmd.none)    
                Err error    -> (( handleError model error), Cmd.none)
    GotNewSubResponse result ->
            case result of
                Ok "Success" -> ({model | currentPage = HomePage, newSubName = "", newSubDescription = ""}, subsGet)
                Ok _         -> ({model | error = "Failed to create new subreddit"}, Cmd.none)
                Err error    -> (( handleError model error), Cmd.none)                              

    PressLogin    -> (model, loginPost model)
    PressSignup   -> (model, signupPost model)
    PressLogout   -> (model, logoutPost model)
    PressNewPost  -> (model, newThreadPost model)
    PressNewReply -> (model, newReplyPost model)
    PressNewSub   -> (model, newSubPost model)

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
    HomePage     -> homePage model.isLoggedIn model.threads model.subs
    LoginPage    -> loginForm model.error
    SignupPage   -> signUpForm model.error
    NewPostPage  -> newPostForm model.error
    NewReplyPage -> newReplyForm model.error (getThreadContent model.currentThreadID model.threads)
    ThreadPage   -> threadPage model.currentThreadID model.threads model.subs
    SubsPage     -> subsPage model.subs
    NewSubPage   -> newSubForm model.error

getThreadContent : Int -> List Thread -> String
getThreadContent targetID threads = 
        let maybeThread = getThread targetID threads 
            in case maybeThread of
                  Just thread -> thread.title ++ "\n" ++ thread.content
                  Nothing     -> ""

getSubName : Int -> List Sub -> String
getSubName targetID subs =
        let maybeSub = getSub targetID subs
          in case maybeSub of
              Just sub -> sub.name   
              Nothing -> ""
                  
getThread : Int -> List Thread -> Maybe Thread
getThread targetID threads = List.head (List.filter (\thread -> thread.id == targetID) threads)

getReplies : Int -> List Thread -> List Thread
getReplies targetID threads = List.filter (\thread -> (doesIDMatch thread.parentID targetID)) threads

getSub : Int -> List Sub -> Maybe Sub
getSub targetID subs = List.head (List.filter (\sub -> sub.id == targetID) subs)

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

newReplyPost : Model -> Cmd Msg
newReplyPost model =
    Http.post
        { url = rootUrl ++ "threads/addthread/"
        , body = Http.jsonBody <| newReplyEncoder model
        , expect = Http.expectString GotNewThreadResponse
        }

newSubPost : Model -> Cmd Msg
newSubPost model =
    Http.post
        { url = rootUrl ++ "threads/addsub/"
        , body = Http.jsonBody <| newSubEncoder model
        , expect = Http.expectString GotNewSubResponse
        }

threadsGet : Cmd Msg
threadsGet =
    Http.get 
        {
          url = rootUrl ++ "threads/getthreads/"
        , expect = Http.expectJson GotThreadsJSON threadsDecoder 
        }

subsGet : Cmd Msg
subsGet =
    Http.get
        {
          url = rootUrl ++ "threads/getsubs/"
        , expect = Http.expectJson GotSubsJSON subsDecoder
        }

newReplyEncoder : Model -> JEncode.Value
newReplyEncoder model =
    JEncode.object
        [ ( "title"
          , JEncode.string ""
          )
        , ( "is_master"
          , JEncode.bool False
          )
        , ( "content"
          , JEncode.string model.newPostContent
          )
        , ( "user"
          , JEncode.string model.username
          )
        , (
            "parent"
          ,  JEncode.int model.currentThreadID
          )
        ]

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

newSubEncoder : Model -> JEncode.Value
newSubEncoder model =
    JEncode.object
      [
        ( "name"
        , JEncode.string model.newSubName
        )
      , ( "description"
        , JEncode.string model.newSubDescription
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
threadDecoder = JDecode.map8 Thread
        (JDecode.field "title" JDecode.string)
        (JDecode.field "date" JDecode.string)
        (JDecode.field "content" JDecode.string)
        (JDecode.field "user" JDecode.string)
        (JDecode.field "is_master" JDecode.bool)
        (JDecode.maybe(JDecode.field "parent" JDecode.int))
        (JDecode.field "pkid" JDecode.int)
        (JDecode.field "sub" JDecode.int)

subsDecoder : JDecode.Decoder (List Sub)
subsDecoder = JDecode.at["subs"] (JDecode.list subDecoder)

subDecoder : JDecode.Decoder Sub
subDecoder = JDecode.map3 Sub
        (JDecode.field "name" JDecode.string)
        (JDecode.field "description" JDecode.string)
        (JDecode.field "pkid" JDecode.int)

view : Model -> Html Msg
view model =
  div []
    [ bootstrapCSS
    , faCSS
    , formCSS
    , navbar model    
    , pageToHTML model
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
            div[class "d-inline"][
            li [ class "nav-item d-inline" ]
            [ a [ class "nav-link d-inline"
                , href "#"
                , onClick (ChangePage HomePage) ]
              [ i [ class "fas fa-home mr-2" ] [], text "Home" ]
            ]
          , li [ class "nav-item d-inline" ]
            [ a [ class "nav-link d-inline"
                , href "#"
                , onClick (ChangePage SubsPage) ]
              [ i [ class "fab fa-reddit-alien mr-2" ] [], text "Choose Subreddit" ]
            ]]
          , if model.isLoggedIn then div[ class "d-inline"][
              li [ class "nav-item d-inline" ]
              [
                a [ class "nav-link d-inline"
                  , href "#"
                  , onClick (ChangePage NewPostPage) 
                  ]
                [ i [ class "fas fa-clone mr-2" ] [], text "New Post" ]
              ]
            , li [ class "nav-item d-inline"]
              [
                 a [ class "nav-link d-inline"
                , href "#"
                , onClick (ChangePage NewSubPage) 
                ]
              [ i [ class "fas fa-plus-circle mr-2" ] [], text "New Subreddit" ]
              ]]
             else div[][] 
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

homePage : Bool -> List Thread -> List Sub -> Html Msg
homePage isLoggedIn threads subs = threadsView (List.filter(\thread -> thread.isMaster) threads) threads subs

getThreadHTMLByID : Int -> List Thread -> List Sub -> Html Msg
getThreadHTMLByID threadID threads subs = 
      let maybeThread = getThread threadID threads
        in case maybeThread of
            Just thread -> threadView thread threads subs True
            Nothing     -> div[][]
                
threadPage : Int -> List Thread -> List Sub -> Html Msg
threadPage threadID threads subs = div[] [(getThreadHTMLByID threadID threads subs), (repliesView (getReplies threadID threads))]

repliesView : List Thread -> Html Msg 
repliesView threads = div [] (List.map replyView threads)

replyView : Thread -> Html Msg
replyView thread = div [ class "container"]
  [ div [ class "card my-3"]
    [
      div [class "card-header"] [text ("Posted by " ++ thread.username ++ " at " ++ thread.date)]
    , div [ class "thread-body" ] 
      [
        h6 [] [text thread.content]
      , div [class "pr-6"] 
        [ button [class "btn thread-button"] [i [ class "fas fa-star mr-2" ] [], text "Give Award"]
        ]    
      ]
    ]
  ]

threadsView : List Thread -> List Thread -> List Sub -> Html Msg 
threadsView threadsToDisplay allThreads subs = div [] (List.reverse (List.map (\thread -> threadView thread allThreads subs False) threadsToDisplay))

threadView : Thread -> List Thread -> List Sub -> Bool -> Html Msg
threadView thread threads subs showContent = div [ class "container", onMouseEnter (ChangeMainThread thread.id) ]
  [ div [ class "card my-5"]
    [
      div [class "card-header"] [text ("Posted by " ++ thread.username ++ " on " ++ thread.date ++ " in " ++ getSubName thread.subID subs)]
    , div [ class "thread-body" ] 
      [
        h4 [] [text thread.title]
      , if showContent then h6 [] [text thread.content] else div [] []
      , div [] 
        [ button [class "btn thread-button", onClick (ChangePage ThreadPage)] [i [ class "fas fa-comment mr-2" ] [], text (String.fromInt (List.length(getReplies thread.id threads)) ++ " comments")]
        , button [class "btn thread-button"] [i [ class "fas fa-star mr-2" ] [], text "Give Award"]
        , button [class "btn thread-button", onClick (ChangePage NewReplyPage)] [i [ class "fas fa-share mr-2" ] [], text "Reply"]
        ]    
      ]
    ]
  ]

subsPage : List Sub -> Html Msg
subsPage subs = div [] (List.map subView subs)

subView : Sub -> Html Msg
subView sub = div[ class "container" ] 
  [ button [class "btn btn-danger my-3"] 
    [i [ class "fab fa-reddit-alien mr-2" ] []
    , text sub.name
    ]
  ]

newSubForm : String -> Html Msg
newSubForm error = div [ class "container" ]
  [ div [ class "row" ]
    [ div [ class "col-sm-9 col-md-7 col-lg-9 mx-auto" ]
      [ div [ class "card card-signin my-5" ]
        [ div [ class "card-body" ]
          [ h5 [ class "card-title text-center" ]
            [ text "Create a Subreddit" ]
          , form [ class "form-signin" ]
            [ div [ class "form-label-group" ]
              [ input [ id "inputName", class "form-control", placeholder "Name", onInput ChangeNewSubName ] []
              , label [ for "inputName"] [i [ class "fas fa-blog mr-2" ] [], text "Name" ]
              , textarea [ for "inputDescription", class "form-control my-3", placeholder "Description", onInput ChangeNewSubDescription ] []
              , h6 [ class "error-msg" ] [text error]
              , button [ class "btn btn-lg btn-primary btn-block text-uppercase", type_ "submit", onClick PressNewSub ]
                [ text "Create Subreddit" ]
              ]
            ]
          ]
        ]
      ]
    ]
  ]

newReplyForm : String -> String -> Html Msg
newReplyForm error threadContent = div [ class "container" ]
  [ div [ class "row" ]
    [ div [ class "col-sm-9 col-md-7 col-lg-9 mx-auto" ]
      [ div [ class "card card-signin my-5" ]
        [ div [ class "card-body" ]
          [ h5 [ class "card-title text-center" ]
            [ text "Reply to Post" ]
          , form [ class "form-signin" ]
            [ div [ class "form-label-group" ]
            [ textarea [ for "inputContent", class "form-control", readonly True] [text threadContent] ]
            ,  textarea [ for "inputContent", class "form-control", placeholder "Content", onInput ChangeNewPostContent ] [] 
            , h6 [ class "error-msg" ] [text error]
            , button [ class "btn btn-lg btn-primary btn-block text-uppercase", type_ "submit", onClick PressNewReply ]
              [ text "Make Reply" ]
            ]
          ]
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
