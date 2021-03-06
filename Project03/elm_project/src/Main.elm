import Browser
import Html exposing (..)
import Html.Events exposing (onClick, onInput, onFocus, onMouseEnter)
import Html.Attributes exposing (attribute, class, href, placeholder, type_, id, for, readonly)
import Http
import Json.Decode as JDecode
import Json.Encode as JEncode
import Dropdown

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
rootUrl = "https://mac1xa3.ca/e/rizkally/"

type alias Model = { currentPage : Page
                   , username : String
                   , password : String
                   , newPostTitle : String
                   , newPostContent : String
                   , newSubName : String
                   , newSubDescription : String
                   , error : String --Error message from Http responses
                   , isLoggedIn : Bool
                   , threads : List Thread
                   , subs : List Sub
                   , currentThreadID : Int
                   , currentSubID : Int --The subreddit the user is browsing (controlled by the dropdown menu)
                   , replySubID : Int --The subreddit belonging to the post the user is replying to (not related to currentSubID)
                   , dropdownState : Dropdown.State
                   }

type Msg = ChangePage Page
         | ChangeUsername String
         | ChangePassword String
         | ChangeNewPostTitle String
         | ChangeNewPostContent String
         | ChangeNewSubName String
         | ChangeNewSubDescription String
         | ChangeMainThread Int
         | ChangeReplySub Int
         | ResetSub --Activated when user clicks on home button
         | GotLoginResponse (Result Http.Error String) -- Http Post Response Received
         | GotSignupResponse (Result Http.Error String)
         | GotLogoutResponse (Result Http.Error String)
         | GotNewThreadResponse (Result Http.Error String)
         | GotNewSubResponse (Result Http.Error String)
         | GotThreadsJSON (Result Http.Error (List Thread)) --Http JSON recieved
         | GotSubsJSON (Result Http.Error (List Sub))
         | PressLogin --Activated when user presses login button
         | PressSignup
         | PressLogout
         | PressNewPost
         | PressNewReply
         | PressNewSub
         | OnSelect (Maybe Sub) --Activated when user selects an item on the dropdown
         | DropdownMsg (Dropdown.Msg Sub) --Important for maintaining dropdown state (see below)

--The different types of pages a user can view
type Page = HomePage
          | LoginPage
          | SignupPage
          | NewPostPage
          | NewReplyPage
          | NewSubPage
          | ThreadPage

--A record type containing information for a thread
type alias Thread = { title: String
                    , date: String
                    , content: String
                    , username: String
                    , isMaster: Bool
                    , parentID: Maybe Int
                    , id: Int
                    , subID: Int
                    }

--A record type containing information for a sub
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
          , currentSubID = 0
          , replySubID = 0
          , dropdownState = Dropdown.newState "Sub"
          }
        , Cmd.batch [threadsGet, subsGet] --Retrieve all threads and subs from the server on startup
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
    ChangeReplySub newSubID      -> ({ model | replySubID = newSubID}, Cmd.none) --The replySubID tracks the sub that belongs to the post that the user is replying to, and has no correlation to the sub in the dropdown
    ResetSub                     -> ({ model | currentSubID = 0}, Cmd.none) --Event called when we click on the homepage button, set ID to 0 so that the user can see all the posts

    --Http Response Updates
    GotLoginResponse result ->
            case result of
                Ok "LoginFailed" -> ({ model | error = "Failed to login." }, Cmd.none)
                Ok _             -> ({ model | currentPage = HomePage, error = "", isLoggedIn = True }, Cmd.none) --Successfully logged in
                Err error        -> ((handleError model error), Cmd.none)
    GotSignupResponse result ->
            case result of
                Ok "EmptyUsername" -> ({ model | error = "Spaces in usernames are not allowed." }, Cmd.none)
                Ok _               -> ({ model | currentPage = HomePage, error = "", isLoggedIn = True }, Cmd.none) --Successfully signed in
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
                Ok "Success" -> ({model | currentPage = HomePage, newPostTitle = "", newPostContent = ""}, threadsGet) --We created a new thread, so must run threadsGet to retrieve and update new threads
                Ok _         -> ({model | error = "Failed to make new post. Make sure to choose a subreddit!"}, Cmd.none)    
                Err error    -> (( handleError model error), Cmd.none)
    GotNewSubResponse result ->
            case result of
                Ok "Success" -> ({model | currentPage = HomePage, newSubName = "", newSubDescription = ""}, subsGet) --We created a new sub, so must run subsGet to retrieve and update new subs
                Ok _         -> ({model | error = "Failed to create new subreddit"}, Cmd.none)
                Err error    -> (( handleError model error), Cmd.none)                              

    --Press Button Events, all route to an Http Post request
    PressLogin    -> (model, loginPost model)
    PressSignup   -> (model, signupPost model)
    PressLogout   -> (model, logoutPost model)
    PressNewPost  -> (model, newThreadPost model)
    PressNewReply -> (model, newReplyPost model)
    PressNewSub   -> (model, newSubPost model)

    --Update the selected sub id when user selects using dropdown
    OnSelect maybeSub ->
            let id = case maybeSub of
                        Just sub -> sub.id    
                        Nothing  -> 0                  
            in
                ( { model | currentSubID = id }, Cmd.none )

    -- Route message to the Dropdown component.
    -- The returned command is important.
    DropdownMsg subMsg ->
        let
            ( updated, cmd ) =
                Dropdown.update dropdownConfig subMsg model.dropdownState
        in
            ( { model | dropdownState = updated }, cmd )

{-|
Create the configuration for the Dropdown component
`Dropdown.newConfig` takes two args:
- The selection message e.g. `OnSelect`
- A function that extract a label from an item e.g. `.name`
-}
dropdownConfig : Dropdown.Config Msg Sub
dropdownConfig =
    Dropdown.newConfig OnSelect .name
        |> Dropdown.withItemClass "border-bottom border-silver p1 gray"
        |> Dropdown.withMenuClass "border border-gray"
        |> Dropdown.withMenuStyles [ ( "background", "white" ) ]
        |> Dropdown.withPrompt "Select Subreddit"
        |> Dropdown.withPromptClass "silver"
        |> Dropdown.withSelectedClass "bold"
        |> Dropdown.withSelectedStyles [ ( "color", "black" ) ]
        |> Dropdown.withTriggerClass "col-12 border bg-white p1"

--A function to handle Http Errors
handleError : Model -> Http.Error -> Model
handleError model error =
    case error of
        Http.BadUrl url   -> { model | error = "Bad URL: " ++ url }
        Http.Timeout      -> { model | error = "Server Timout" }
        Http.NetworkError -> { model | error = "Network Error" }
        Http.BadStatus i  -> { model | error = "Bad Status: " ++ String.fromInt i }
        Http.BadBody body -> { model | error = "Bad Body: " ++ body }

--Given a model, routes the model's currentPage to the appropriate HTML view
pageToHTML : Model -> Html Msg
pageToHTML model = case model.currentPage of
    HomePage     -> homePage model.isLoggedIn (getThreadsInSub model.currentSubID model.threads) model.subs
    LoginPage    -> loginForm model.error
    SignupPage   -> signUpForm model.error
    NewPostPage  -> newPostForm model.error
    NewReplyPage -> newReplyForm model.error (getThreadContent model.currentThreadID model.threads)
    ThreadPage   -> threadPage model.currentThreadID model.threads model.subs
    NewSubPage   -> newSubForm model.error


--Filters the list of threads given to those with the same subID as the given subID
--If the subID given is 0, it will just return the list of all threads (0 means we are on the homepage)
getThreadsInSub : Int -> List Thread -> List Thread
getThreadsInSub subID threads = if subID /= 0 then List.filter(\thread -> thread.subID == subID) threads else threads

--Returns a string containing the thread's title and content
--If the targetID given does not match any of the threads, will return an empty string.
getThreadContent : Int -> List Thread -> String
getThreadContent targetID threads = 
        let maybeThread = getThread targetID threads 
            in case maybeThread of
                  Just thread -> thread.title ++ "\n" ++ thread.content
                  Nothing     -> ""

--Returns a string containing the sub's name
--If the targetID given does not match any of the subs, will return an empty string.
getSubName : Int -> List Sub -> String
getSubName targetID subs =
        let maybeSub = getSub targetID subs
          in case maybeSub of
              Just sub -> sub.name   
              Nothing -> ""

--Given a targetID and a list of threads, looks for the thread and returns it.
--If there is more than one thread with the same ID, returns the first one (this should NEVER happen unless the database is corrupted).
--Returns Nothing if there are no threads matching the targetID                  
getThread : Int -> List Thread -> Maybe Thread
getThread targetID threads = List.head (List.filter (\thread -> thread.id == targetID) threads)

--Given a targetID and a list of threads, looks through the list of threads and
--returns a list containing all posts with parentID matching targetID 
--(i.e. the replies of the thread with id targetID)
getReplies : Int -> List Thread -> List Thread
getReplies targetID threads = List.filter (\thread -> (doesIDMatch thread.parentID targetID)) threads

--Given a targetID and a list of subs, looks for the sub and returns it.
--If there is more than one sub with the same ID, returns the first one (this should NEVER happen unless the database is corrupted).
--Returns Nothing if there are no subs matching the targetID                 
getSub : Int -> List Sub -> Maybe Sub
getSub targetID subs = List.head (List.filter (\sub -> sub.id == targetID) subs)

--A helper function to determine if a Maybe Int matches an Int
doesIDMatch : Maybe Int -> Int -> Bool
doesIDMatch id targetID = case id of
    Just i  -> i == targetID
    Nothing -> False


--HTTP POST REQUESTS


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


--HTTP GET REQUESTS


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


--JSON ENCODERS

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
        , (
            "sub"
          , JEncode.int model.replySubID
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
        , (
            "sub"
          , JEncode.int model.currentSubID
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


--JSON DECODERS


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
    , Html.map DropdownMsg (Dropdown.view dropdownConfig model.dropdownState model.subs (getSub model.currentSubID model.subs))
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
            div[class "d-inline", onClick (ResetSub)][
            li [ class "nav-item d-inline" ]
              [ a [ class "nav-link d-inline"
                  , href "#"
                  , onClick (ChangePage HomePage) ]
                [ i [ class "fas fa-home mr-2" ] [], text "Home" ]
              ]
            ]
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
              [ i [ class "fab fa-reddit-alien mr-2" ] [], text "New Subreddit" ]
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
  [ div [ class "card my-5", onMouseEnter (ChangeReplySub thread.subID) ]
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
