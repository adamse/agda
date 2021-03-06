{-# LANGUAGE CPP #-}
module Utils where

import qualified Data.Text as T
import System.FilePath
import System.Exit

#if __GLASGOW_HASKELL__ <= 708
import Control.Applicative ((<$>))
#endif

import System.Environment
import Data.Maybe
import Data.Char
import qualified Data.Set as S
import System.Directory

import Data.Array
import Text.Regex.TDFA.Text ()
import qualified Text.Regex.TDFA as R

type ProgramResult = (ExitCode, T.Text, T.Text)

type AgdaArgs = [String]

getEnvAgdaArgs :: IO AgdaArgs
getEnvAgdaArgs = maybe [] words <$> getEnvVar "AGDA_ARGS"


getAgdaBin :: IO FilePath
getAgdaBin = do
  agda <- getEnvVar "AGDA_BIN"
  case agda of
    Just x -> return x
    Nothing -> fail "AGDA_BIN environment variable not set, aborting..."

-- | Gets the program executable. If an environment variable
-- YYY_BIN is defined (with yyy converted to upper case),
-- the value of it is returned. Otherwise, the input value
-- is returned unchanged.
getProg :: String -> IO FilePath
getProg prog = fromMaybe prog <$> getEnvVar (map toUpper prog ++ "_BIN")

getEnvVar :: String -> IO (Maybe String)
getEnvVar v =
  lookup v <$> getEnvironment

agdaExts :: S.Set String
agdaExts = S.fromList [".agda", ".lagda"]

getAgdaFilesInDir :: String -> IO [FilePath]
getAgdaFilesInDir dir = map (dir </>) . filter (flip S.member agdaExts . takeExtension) <$> getDirectoryContents dir

doesEnvContain :: String -> IO Bool
doesEnvContain v = isJust <$> getEnvVar v

-- | Replaces all matches of a regex with the given text.
--
-- (There doesn't seem to be any such function in the regex-tdfa libraries?)
replace :: R.Regex -> T.Text -> T.Text -> T.Text
replace rgx new inp =
  foldr repl inp matches
  where
    -- the matches are in ascending, non-overlapping order. We take advantage
    -- of this by replacing the matches in last-to-first order,
    -- which means we don't have to worry about changing offsets.
    matches = R.matchAll rgx inp
    repl :: R.MatchArray -> T.Text -> T.Text
    repl match t =
      T.take off t `T.append` new `T.append` T.drop (off + len) t
      where
        (off, len) = match ! 0

