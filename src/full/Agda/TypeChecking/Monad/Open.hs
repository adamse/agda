-- {-# LANGUAGE CPP #-}
{-# LANGUAGE FlexibleContexts #-}

module Agda.TypeChecking.Monad.Open
        ( makeOpen
        , makeClosed
        , getOpen
        , tryOpen
        ) where

import Control.Applicative
import Control.Monad
import Control.Monad.Reader
import Data.List

import Agda.TypeChecking.Substitute
import Agda.TypeChecking.Monad.Base

import {-# SOURCE #-} Agda.TypeChecking.Monad.Context

import Agda.Utils.Except ( MonadError(catchError) )

-- | Create an open term in the current context.
makeOpen :: a -> TCM (Open a)
makeOpen x = do
    ctx <- getContextId
    return $ OpenThing ctx x

-- | Create an open term which is closed.
makeClosed :: a -> Open a
makeClosed = OpenThing []

-- | Extract the value from an open term. Must be done in an extension of the
--   context in which the term was created.
getOpen :: (Subst t a, MonadReader TCEnv m, MonadError TCErr m) => Open a -> m a
getOpen (OpenThing []  x) = return x
getOpen (OpenThing ctx x) = do
  ctx' <- getContextId
  unless (ctx `isSuffixOf` ctx') $ fail $ "thing out of context (" ++ show ctx ++ " is not a sub context of " ++ show ctx' ++ ")"
  return $ raise (genericLength ctx' - genericLength ctx) x

-- | Try to use an 'Open' the current context.
--   Returns 'Nothing' if current context is not an extension of the
--   context in which the 'Open' was created.
tryOpen :: (Subst t a, MonadReader TCEnv m) => Open a -> m (Maybe a)
tryOpen (OpenThing []  x) = return $ Just x
tryOpen (OpenThing ctx x) = do
  ctx' <- getContextId
  if (ctx `isSuffixOf` ctx')
    then return $ Just $ raise (genericLength ctx' - genericLength ctx) x
    else return Nothing
