{-# LANGUAGE OverloadedStrings #-}

module XComp (toXCompose) where

import Data.Char (isAlphaNum, isAscii, ord)
import Data.Text (Text)
import qualified Data.Text as T
import Text.Printf (printf)
import Types (CompMap (..), quote)

-- string-only results (no keysym fallback, e.g. `"ä" adiaeresis`).
-- XCompose accepts both; add the keysym form if pre-UTF-8-era clients matter.
toXCompose :: CompMap -> Text
toXCompose (CompMap ps) = T.unlines (map line ps)
  where
    line (k, v) = T.unwords (map (\c -> T.singleton '<' <> keysymFor c <> T.singleton '>') (T.unpack k)) <> " : " <> quote v

-- basic Latin (ASCII) alphanumerics are their own keysym; everything else
-- (symbols and non-ASCII letters/digits) is looked up or rendered as a
-- zero-padded <Uhex> keysym
keysymFor :: Char -> Text
keysymFor ' ' = "space"
keysymFor '!' = "exclam"
keysymFor '"' = "quotedbl"
keysymFor '#' = "numbersign"
keysymFor '$' = "dollar"
keysymFor '%' = "percent"
keysymFor '&' = "ampersand"
keysymFor '\'' = "apostrophe"
keysymFor '(' = "parenleft"
keysymFor ')' = "parenright"
keysymFor '*' = "asterisk"
keysymFor '+' = "plus"
keysymFor ',' = "comma"
keysymFor '-' = "minus"
keysymFor '.' = "period"
keysymFor '/' = "slash"
keysymFor ':' = "colon"
keysymFor ';' = "semicolon"
keysymFor '<' = "less"
keysymFor '=' = "equal"
keysymFor '>' = "greater"
keysymFor '?' = "question"
keysymFor '@' = "at"
keysymFor '[' = "bracketleft"
keysymFor '\\' = "backslash"
keysymFor ']' = "bracketright"
keysymFor '^' = "asciicircum"
keysymFor '_' = "underscore"
keysymFor '`' = "grave"
keysymFor '{' = "braceleft"
keysymFor '|' = "bar"
keysymFor '}' = "braceright"
keysymFor '~' = "asciitilde"
keysymFor c
  | isAscii c && isAlphaNum c = T.singleton c
  | otherwise = T.pack (printf "U%04X" (ord c))
