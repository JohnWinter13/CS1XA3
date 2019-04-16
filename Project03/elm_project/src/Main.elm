import Browser
import Html exposing (..)
import Html.Events exposing (onClick)
import Html.Attributes exposing (attribute, class, href, placeholder, type_, id, for)

main =
  Browser.sandbox { init = init, update = update, view = view }

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

type alias Model = { currentPage : Page
                   , task : String
                   }

type Msg = ChangePage Page

type Page = HomePage
          | LoginPage
          | SignupPage

init : Model
init  = { currentPage = HomePage
        , task = ""
        }

pageToHTML : Page -> Html Msg
pageToHTML page = case page of
    HomePage   -> div[][]
    LoginPage  -> loginForm
    SignupPage -> signUpForm
        
update : Msg -> Model -> Model
update msg model =
  case msg of  
    ChangePage page -> { model | currentPage = page}

view : Model -> Html Msg
view model =
  div []
    [ bootstrapCSS
    , faCSS
    , formCSS
    , navBar        
    , pageToHTML model.currentPage
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
          li [ class "nav-item dropdown" ]
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
              [ input [ attribute "autofocus" "", class "form-control", id "inputEmail", placeholder "Email", attribute "required" "", type_ "email" ]
                []
              , label [ for "inputEmail" ]
                [i [ class "fas fa-envelope mr-2" ] [], text "Email" ]
              ]
            , div [ class "form-label-group" ]
              [ input [ class "form-control", id "inputPassword", placeholder "Password", attribute "required" "", type_ "password" ]
                []
              , label [ for "inputPassword" ]
                [i [ class "fas fa-key mr-2" ] [], text "Password" ]
              ]
            , button [ class "btn btn-lg btn-primary btn-block text-uppercase", type_ "submit" ]
              [ text "Log in" ]
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
              [ input [ attribute "autofocus" "", class "form-control", id "inputEmail", placeholder "Email", attribute "required" "", type_ "email" ]
                []
              , label [ for "inputEmail"]
                [i [ class "fas fa-envelope mr-2" ] [], text "Email" ]
              ]
            , div [ class "form-label-group" ]
              [ input [ class "form-control", id "inputPassword", placeholder "Password", attribute "required" "", type_ "password" ]
                []
              , label [ for "inputPassword" ]
                [i [ class "fas fa-key mr-2" ] [], text "Password" ]
              ]
            , button [ class "btn btn-lg btn-primary btn-block text-uppercase", type_ "submit" ]
              [ text "Sign Up" ]
            ]
          ]
        ]
      ]
    ]
  ]
