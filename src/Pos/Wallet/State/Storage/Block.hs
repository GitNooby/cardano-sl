{-# LANGUAGE RankNTypes      #-}
{-# LANGUAGE TemplateHaskell #-}

-- | Block maintenance in wallet state

module Pos.Wallet.State.Storage.Block
       ( BlockStorage (..)
       , HasBlockStorage (blockStorage)

       , Block'
       , HeaderHash'
       , AltChain

       , getBlock

       , blkSetHead
       ) where

import           Control.Lens        (at, makeClassy, view, (.=))
import           Data.Default        (Default, def)
import qualified Data.HashMap.Strict as HM
import           Data.List.NonEmpty  (NonEmpty (..))
import           Data.SafeCopy       (base, deriveSafeCopySimple)
import           Universum

import           Pos.Crypto          (unsafeHash)
import           Pos.Ssc.GodTossing  (SscGodTossing)
import           Pos.Types           (Block, HeaderHash)

type Block' = Block SscGodTossing
type HeaderHash' = HeaderHash SscGodTossing
type AltChain = NonEmpty Block'

data BlockStorage = BlockStorage
    { -- | All blocks known to the node. Blocks have pointers to other
      -- blocks and can be easily traversed.
      _blkBlocks    :: !(HashMap HeaderHash' Block')
    , -- | Hash of the head in the best chain.
      _blkHead      :: !HeaderHash'
    , -- | Hash of bottom block (of depth `k + 1`, or, if the whole
      -- chain is shorter than `k + 1`, the first block in the chain)
      _blkBottom    :: !HeaderHash'
    , -- | Alternative chains which can be merged into main chain.
      _blkAltChains :: ![AltChain]
    }

makeClassy ''BlockStorage
deriveSafeCopySimple 0 'base ''BlockStorage

instance Default BlockStorage where
    def = BlockStorage HM.empty (unsafeHash (0 :: Int)) (unsafeHash (1 :: Int)) []

type Query a = forall m x. (HasBlockStorage x, MonadReader x m) => m a
type Update a = forall m x. (HasBlockStorage x, MonadState x m) => m a

-- | Get block by hash of its header.
getBlock :: HeaderHash' -> Query (Maybe Block')
getBlock h = view (blkBlocks . at h)

-- | Set head of main blockchain to block which is guaranteed to
-- represent valid chain and be stored in blkBlocks.
blkSetHead :: HeaderHash' -> Update ()
blkSetHead headHash = blkHead .= headHash
