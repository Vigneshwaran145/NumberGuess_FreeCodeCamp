#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo -e "Enter your username:"
read USERNAME

USER_ID=$($PSQL "select user_id from users where username='$USERNAME';")
if [[ -z $USER_ID ]]
then 
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
  USER_INSERT_RESULT=$($PSQL "insert into users(username) values('$USERNAME');")
  USER_ID=$($PSQL "select user_id from users where username='$USERNAME';")

else
  GAMES_PLAYED=$($PSQL "select games_played from games right join users using(user_id) where user_id=$USER_ID;")
  BEST_GAME=$($PSQL "Select best_game from games right join users using(user_id) where user_id=$USER_ID;")
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
echo -e "\nGuess the secret number between 1 and 1000:"
read INPUT_NUMBER

GUESSED_CORRECTLY=true
NUMBER_OF_GUESSES=1

until [[ $SECRET_NUMBER == $INPUT_NUMBER ]]
do 
  if [[ ! $INPUT_NUMBER =~ ^-?[0-9]+$ ]] 
  then 
    echo -e "\nThat is not an integer, guess again:"
  fi

  if [[ $SECRET_NUMBER > $INPUT_NUMBER ]]
  then
    echo -e "\nIt's lower than that, guess again:"
  elif [[ $SECRET_NUMBER < $INPUT_NUMBER ]]
  then
    echo -e "\nIt's higher than that, guess again:"
  fi
  NUMBER_OF_GUESSES=$(( NUMBER_OF_GUESSES + 1 ))
  read INPUT_NUMBER
done

echo -e "\nYou guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
GAME_ID=$($PSQL "select game_id from games right join users using(user_id) where user_id=$USER_ID;")
if [[ -z $GAME_ID ]]
then
  GAME_INSERT_RESULT=$($PSQL "insert into games(user_id, games_played, best_game) values($USER_ID, 1, $NUMBER_OF_GUESSES);")
else
  BEST_GAME=$($PSQL "Select best_game from games where game_id=$GAME_ID;")
  if [[ $BEST_GAME > $NUMBER_OF_GUESSES ]]
  then
    NUMBER_OF_GAMES=$($PSQL "select games_played from games where game_id=$GAME_ID;")
    UPDATE_BEST_GAME=$($PSQL "update games set best_game=$NUMBER_OF_GUESSES where game_id=$GAME_ID;")
    NUMBER_OF_GAMES=$(( NUMBER_OF_GAMES + 1 ))
    UPDATE_GAMES_PLAYED=$($PSQL "update games set games_played=$NUMBER_OF_GAMES where game_id=$GAME_ID")
  fi
fi
