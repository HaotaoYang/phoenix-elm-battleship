module Game.View exposing (..)

import Html exposing (..)
import Json.Decode as JD
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Game.Model exposing (..)
import Msg exposing (..)
import Game.MyBoard.View as MyBoardView
import Game.OpponentBoard.View as OpponentBoardView
import Game.Helpers exposing (..)
import Logo.View as Logo


view : String -> String -> Model -> Html Msg
view playerId messageText model =
    div
        [ id "game_show"
        , class "view-container"
        ]
        [ gameContent playerId model
        , chatView playerId messageText model
        ]


gameContent : String -> Model -> Html Msg
gameContent playerId model =
    if model.gameOver then
        resultView playerId model
    else
        gameView playerId model


gameView : String -> Model -> Html Msg
gameView playerId model =
    section
        [ id "main_section" ]
        [ headerView playerId model
        , section
            [ id "boards_container" ]
            [ MyBoardView.view model
            , opponentBoard playerId model
            ]
        ]


headerView : String -> Model -> Html Msg
headerView playerId model =
    let
        ( title, message ) =
            if isBoardReady model.game.my_board == False then
                ( "Place your ships", "Use the instructions below" )
            else if isBoardReady model.game.opponents_board == False then
                ( "Waiting for opponent", "Battle will start as soon as your opponent is ready" )
            else if isItPlayersTurn model.currentTurn playerId then
                ( "Your turn!", "Click on your shooting grid to open fire!" )
            else if not (isItPlayersTurn model.currentTurn playerId) then
                ( "Your opponent's turn!", "Wait for your opponent to shoot..." )
            else
                ( "Let the battle begin", "Let the battle begin" )
    in
        header
            [ id "game_header" ]
            [ h1 [] [ text title ]
            , p [] [ text message ]
            ]


resultView : String -> Model -> Html Msg
resultView playerId model =
    let
        message =
            if playerId == Maybe.withDefault "" model.winnerId then
                "Yo Ho Ho, victory is yours!"
            else
                "You got wrecked, landlubber!"

        twitterMessage =
            if playerId == Maybe.withDefault "" model.winnerId then
                "Yo Ho Ho, I won a battle at Phoenix Battleship"
            else
                "I got wrecked at Phoenix Battleship"
    in
        div [ id "game_result" ]
            [ header
                []
                [ Logo.view
                , h1
                    []
                    [ text "Game over" ]
                , p
                    []
                    [ text message ]
                , a
                    [ class "twitter-hashtag-button"
                    , href ("https://twitter.com/intent/tweet?url=https://phoenix-battleship.herokuapp.com&button_hashtag=myelixirstatus&text=" ++ twitterMessage)
                    ]
                    [ i
                        [ class "fa fa-twitter" ]
                        []
                    , text " Share result"
                    ]
                ]
            , a
                [ onClick NavigateToHome ]
                [ text "Back to home" ]
            ]


opponentBoard : String -> Model -> Html Msg
opponentBoard playerId model =
    if model.readyForBattle == False then
        instructionsView playerId model
    else
        OpponentBoardView.view playerId model


instructionsView : String -> Model -> Html Msg
instructionsView playerId model =
    let
        firstStep =
            if Maybe.withDefault "" model.game.attacker == playerId then
                li []
                    [ text "Copy this link by clicking on it and share it with your opponent. "
                    , br []
                        []
                    , text " "
                    ]
            else
                span [] []
    in
        div [ id "opponents_board_container" ]
            [ header
                []
                [ h2 [] [ text "Instructions" ]
                ]
            , ol [ class "instructions" ]
                [ firstStep
                , li []
                    [ text "To place a ship in your board select one by clicking on the gray boxes." ]
                , li []
                    [ text "The selected ship will turn green." ]
                , li []
                    [ text "Switch the orientation of the ship by clicking again on it." ]
                , li []
                    [ text "To place the selected ship click on the cell where you want it to start." ]
                , li []
                    [ text "Repeat the process until you place all your ships." ]
                , li []
                    [ text "Tha battle will start as soon as both players have placed all their ships." ]
                , li []
                    [ text "Good luck!" ]
                ]
            ]


chatView : String -> String -> Model -> Html Msg
chatView playerId messageText model =
    let
        opponentIsConnected =
            case ( model.game.attacker, model.game.defender ) of
                ( Just attackerId, Just defenderId ) ->
                    True

                _ ->
                    False

        statusText =
            if opponentIsConnected == True then
                "Opponent is connected"
            else
                "No opponnent yet connected"

        classes =
            classList [ ( "status", True ), ( "connected", opponentIsConnected ) ]
    in
        aside
            [ id "chat_container" ]
            [ header
                []
                [ p
                    []
                    [ i [ classes ] []
                    , text statusText
                    ]
                ]
            , div
                [ class "messages-container" ]
                [ model.messages
                    |> List.map (messageView playerId)
                    |> ul []
                ]
            , div
                [ class "form-container" ]
                [ div [ class "form-container" ]
                    [ input
                        [ disabled (not opponentIsConnected)
                        , autofocus True
                        , onInput SetMessageText
                        , on "keypress" handleKeyPress
                        , placeholder "Type message and hit intro..."
                        , value messageText
                        ]
                        []
                    ]
                ]
            ]


messageView : String -> ChatMessage -> Html Msg
messageView playerId message =
    let
        classes =
            classList [ ( "mine", message.player_id == playerId ) ]
    in
        li
            [ classes ]
            [ span [] [ text message.text ] ]


handleKeyPress : JD.Decoder Msg
handleKeyPress =
    JD.map (always (SendChatMessage)) (JD.customDecoder keyCode is13)
