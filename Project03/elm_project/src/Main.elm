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
        
update : Msg -> Model -> Model
update msg model =
  case msg of  
    ChangePage page -> { model | currentPage = page}

view : Model -> Html Msg
view model =
  div []
    [ bootstrapCSS
    , nav [ class "navbar navbar-expand-lg navbar-light bg-light" ]
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
        ]
      ]        
    ]
