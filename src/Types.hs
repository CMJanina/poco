module Types (CompMap (..), quote) where

import Data.Aeson.Key (toText)
import Data.Aeson.KeyMap (toList)
import Data.Aeson.Types (prependFailure, typeMismatch)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Yaml as Y

newtype CompMap = CompMap [(Text, Text)] deriving (Eq, Show)

instance Y.FromJSON CompMap where
  parseJSON (Y.Object o) = fmap CompMap . mapM toPair $ toList o
    where
      toPair (k, Y.String s) = pure (toText k, s)
      toPair (k, invalid) =
        prependFailure
          ("replacement for trigger \"" <> T.unpack (toText k) <> "\" must be a string ")
          (typeMismatch "String" invalid)
  parseJSON invalid =
    prependFailure
      "input must be a mapping from trigger strings to replacement strings "
      (typeMismatch "Object" invalid)

quote :: Text -> Text
quote s = T.singleton '"' <> T.concatMap esc s <> T.singleton '"'
  where
    esc '"'  = T.pack ['\\', '"']
    esc '\\' = T.pack ['\\', '\\']
    esc c    = T.singleton c
