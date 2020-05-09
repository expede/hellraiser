{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE UndecidableInstances  #-}

{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- | 

module Control.Monad.Reraise where

import Control.Monad.Rescue
 
import           Data.Proxy
import           Data.WorldPeace

import Control.Monad.Foo

-- NOTE TO SELF: this shoudl actaully just be a natual transformation, i.e. n a -> m a, becasue n and m have all the error carrying info
class MonadReraise n m where
  reraise :: n a -> m a
  -- ^ TODO: rename function to `relax` or `relaxErr`? `recontextualize`?
  -- ^ TODO: rename class to `MonadCleanup`?

-- recontextualize :: MonadReraise outer m n => Proxy outer -> m a -> n a
-- recontextualize = reraise

-- rectx :: MonadReraise outer m n => Proxy outer -> m a -> n a
-- rectx = recontextualize

instance MonadReraise m m where
  reraise action = action

-- instance (ToOpenUnion inner outer, MonadRaise (OpenUnion outer) m, MonadRescue inner n) => MonadReraise n m where
--   reraise action = try action >>= \case

instance ToOpenUnion inner outer => MonadReraise (Either inner) (Either (OpenUnion outer)) where
  reraise action =
    case action of
      Left  err -> Left $ consistent err -- FIXME perhaps rename consistent to recontextualize?
      Right val -> Right val

-- -- instance IsMember err errs =>
-- --   MonadReraise errs (Either err) (Either (OpenUnion errs)) where
-- --     reraise _ = \case
-- --       Left  err -> raise @(OpenUnion errs) err
-- --       Right val -> return val

-- instance (MonadRescue innerErrs (Either innerErrs), ToOpenUnion innerErrs outerErrs) =>
--   MonadReraise outerErrs (Either innerErrs) (Either (OpenUnion outerErrs)) where
--     reraise _pxyOuterErrs = \case
--       Left  err -> raise err
--       Right val -> return val

-- reraise :: forall outer inner n m a . (ToOpenUnion (OpenUnion inner) outer, MonadRescue inner n, MonadRaise (OpenUnion outer) m) => n a -> m a
-- reraise action = do
--   let innerResult = try @inner action
--   case innerResult of
--     Left err -> raise $ consistent err


-- cleanup :: forall outer n m resource output ignored1 ignored2 .
--   ( MonadRescue outer m
--   -- , MonadReraise outer n m
--   )
--   => Proxy outer
--   -> n resource                                  -- ^ Acquire resource
--   -> (resource -> OpenUnion outer -> m ignored1) -- ^ Cleanup exception case; The exception will be reraised
--   -> (resource -> output          -> m ignored2) -- ^ Cleanup happy path
--   -> (resource -> m output)                      -- ^ Inner action
--   -> m output
-- cleanup pxyO acquire onErr onOk action = do
--   resource <- reraise acquire
--   try @outer (action resource) >>= \case
--     Left err -> do
--       _ <- onErr resource err
--       raise err

--     Right output -> do
--       _ <- onOk resource output
--       return output

-- cleanup' :: forall outer n m resource output ignored1 ignored2 .
--   ( MonadRescue outer m
--   -- , MonadReraise outer n m
--   )
--   => n resource                                  -- ^ Acquire resource
--   -> (resource -> OpenUnion outer -> m ignored1) -- ^ Cleanup exception case; The exception will be reraised
--   -> (resource -> output          -> m ignored2) -- ^ Cleanup happy path
--   -> (resource -> m output)                      -- ^ Inner action
--   -> m output
-- cleanup' = cleanup (Proxy @outer)
