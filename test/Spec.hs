{-# LANGUAGE OverloadedStrings #-}
-- TODO: replace this vibecoded mess with quickcheck or whatever

module Main (main) where

import Cocoa (Mark (..), toPlist, toTrie)
import Data.Char (isSpace)
import Data.Tree (Tree (..))
import qualified Data.Text.IO as TIO
import qualified Data.Text as T
import qualified Data.Yaml as Y
import Types (CompMap (..))
import XComp (toXCompose)

cm :: CompMap
cm = CompMap [("aa", "foo"), ("ab", "bar"), ("cb", "baz")]

main :: IO ()
main = do
  mapM_ (\input -> case Y.decodeEither' input :: Either Y.ParseException CompMap of
    Left err -> assertEq "prefix conflict reports both sequences" True
      (T.pack "\"a\" is a prefix of \"ab\"" `T.isInfixOf` T.pack (Y.prettyPrintParseException err))
    Right result -> error ("accepted prefix conflict: " ++ show result))
    ["a: foo\nab: bar\n", "ab: bar\na: foo\n"]
  case Y.decodeEither' "abc: foo\nabd: bar\n" :: Either Y.ParseException CompMap of
    Left err -> error (Y.prettyPrintParseException err)
    Right (CompMap ps) -> assertEq "shared prefix accepted" 2 (length ps)

  let trie = toTrie cm
  assertEq "root label" Root (rootLabel trie)
  assertEq "root has 2 branches" 2 (length (subForest trie))

  let aSub = head (subForest trie)
  assertEq "'a' node" (Edge 'a') (rootLabel aSub)
  assertEq "'a' has 2 children" 2 (length (subForest aSub))

  let aa = head (subForest aSub)
      ab = head (drop 1 (subForest aSub))
  assertEq "'a'->'a' node" (Edge 'a') (rootLabel aa)
  assertEq "'a'->'a' value" [Value "foo"] (map rootLabel (subForest aa))
  assertEq "'a'->'b' node" (Edge 'b') (rootLabel ab)
  assertEq "'a'->'b' value" [Value "bar"] (map rootLabel (subForest ab))

  -- second branch: 'c'
  let cSub = head (drop 1 (subForest trie))
  assertEq "'c' node" (Edge 'c') (rootLabel cSub)
  assertEq "'c' has 1 child" 1 (length (subForest cSub))
  let cb = head (subForest cSub)
  assertEq "'c'->'b' node" (Edge 'b') (rootLabel cb)
  assertEq "'c'->'b' value" [Value "baz"] (map rootLabel (subForest cb))

  -- empty mapping: bare root
  let emptyTrie = toTrie (CompMap [])
  assertEq "empty root label" Root (rootLabel emptyTrie)
  assertEq "empty has no children" [] (subForest emptyTrie)

  -- keys sharing a prefix branch at the first differing character
  let deep = toTrie (CompMap [("abc", "x"), ("abd", "y")])
  let a2 = head (subForest deep)        -- Edge 'a'
      b2 = head (subForest a2)          -- Edge 'b'
  assertEq "deep 'ab' has 2 children" 2 (length (subForest b2))
  assertEq "['a','b'] children labels" [Edge 'c', Edge 'd']
    (map rootLabel (subForest b2))

  -- serialization: canonical example becomes the expected plist
  assertEq "plist output"
    (T.unlines
      [ "{\"\" = {"
      , "  \"a\" = {"
      , "    \"a\" = (\"insertText:\", \"foo\");"
      , "    \"b\" = (\"insertText:\", \"bar\");"
      , "  };"
      , "  \"c\" = {"
      , "    \"b\" = (\"insertText:\", \"baz\");"
      , "  };"
      , "};}" ])
    (toPlist "" (toTrie cm))

  let allKeys = [ ("hug", "🫂"), ("pnt", "👉👈"), ("pls", "🥺"), ("cdot", "⋅")
        , ("chk", "☑"), ("xx", "×"), ("eu", "€"), ("SS", "ẞ"), ("ss", "ß")
        , ("Ue", "Ü"), ("Oe", "Ö"), ("Ae", "Ä"), ("ue", "ü"), ("oe", "ö")
        , ("ae", "ä"), ("a`", "ᴀ"), ("dgc", "℃"), ("degc", "℃")
        , ("degC", "℃"), ("b`", "ʙ"), ("[x]", "☒"), ("[ ]", "☐")
        , ("_2", "₂"), ("_1", "₁"), ("2.", "‥"), ("..", "…") ]
  example <- TIO.readFile "example.dict"
  assertEq "example.dict tokens" (tokens example)
    (tokens (toPlist "§" (toTrie (CompMap allKeys))))

  -- XCompose: small mapping, one line per binding, no nesting
  assertEq "xcompose output"
    (T.unlines
      [ "<a> <a> : \"foo\""
      , "<a> <b> : \"bar\""
      , "<c> <b> : \"baz\"" ])
    (toXCompose cm)

  -- XCompose: symbol triggers map to keysym names, space in the middle works,
  -- non-ASCII triggers become zero-padded Unicode keysyms
  assertEq "xcompose symbols"
    (T.unlines
      [ "<a> <grave> : \"ᴀ\""
      , "<exclam> <exclam> : \"‼\""
      , "<bracketleft> <space> <bracketright> : \"☐\""
      , "<underscore> <1> : \"₁\""
      , "<period> <period> : \"…\""
      , "<2> <period> : \"‥\""
       , "<U2026> <a> : \"x\""
       , "<U00D7> <b> : \"z\""
       , "<h> <u> <g> : \"🫂\"" ])
    (toXCompose (CompMap [("a`", "ᴀ"), ("!!", "‼"), ("[ ]", "☐"), ("_1", "₁"),
                          ("..", "…"), ("2.", "‥"), ("…a", "x"), ("×b", "z"), ("hug", "🫂")]))

  -- full example.yaml, compared against example.compose line by line
  ex <- Y.decodeFileThrow "example.yaml" :: IO CompMap
  exampleX <- TIO.readFile "example.compose"
  assertEq "example.compose lines" (T.lines exampleX) (T.lines (toXCompose ex))

assertEq :: (Show a, Eq a) => String -> a -> a -> IO ()
assertEq name expected actual
  | actual == expected = return ()
  | otherwise = error (name ++ "\nexpected:\n" ++ show expected
                    ++ "\ngot:\n" ++ show actual)

tokens :: T.Text -> T.Text
tokens = T.filter (not . isSpace)
