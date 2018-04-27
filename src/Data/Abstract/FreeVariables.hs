{-# LANGUAGE DefaultSignatures, UndecidableInstances #-}
module Data.Abstract.FreeVariables where

import qualified Data.ByteString.Char8 as BC
import           Data.String
import           Data.Term
import           Prologue

-- | The type of variable names.
newtype Name = Name { unName :: ByteString }
  deriving (Eq, Ord, Show)

name :: ByteString -> Name
name = Name

instance IsString Name where
  fromString = Name . BC.pack

-- | The type of labels.
--   TODO: This should be rolled into 'Name' and tracked in the environment, both so that we can abstract over labels like any other location, and so that we can garbage collect unreachable labels.
type Label = Int


-- | Types which can contain unbound variables.
class FreeVariables term where
  -- | The set of free variables in the given value.
  freeVariables :: term -> [Name]


-- | A lifting of 'FreeVariables' to type constructors of kind @* -> *@.
--
--   'Foldable' types requiring no additional semantics to the set of free variables (e.g. types which do not bind any variables) can use (and even derive, with @-XDeriveAnyClass@) the default implementation.
class FreeVariables1 syntax where
  -- | Lift a function mapping each element to its set of free variables through a containing structure, collecting the results into a single set.
  liftFreeVariables :: (a -> [Name]) -> syntax a -> [Name]
  default liftFreeVariables :: (Foldable syntax) => (a -> [Name]) -> syntax a -> [Name]
  liftFreeVariables = foldMap

-- | Lift the 'freeVariables' method through a containing structure.
freeVariables1 :: (FreeVariables1 t, FreeVariables a) => t a -> [Name]
freeVariables1 = liftFreeVariables freeVariables

freeVariable :: FreeVariables term => term -> Either [Name] Name
freeVariable term = case freeVariables term of
  [n] -> Right n
  xs -> Left xs

instance (FreeVariables t) => FreeVariables (Subterm t a) where
  freeVariables = freeVariables . subterm

instance (FreeVariables1 syntax, Functor syntax) => FreeVariables (Term syntax ann) where
  freeVariables = cata (liftFreeVariables id)

instance (FreeVariables1 syntax) => FreeVariables1 (TermF syntax ann) where
  liftFreeVariables f (In _ s) = liftFreeVariables f s

instance (Apply FreeVariables1 fs) => FreeVariables1 (Union fs) where
  liftFreeVariables f = apply (Proxy :: Proxy FreeVariables1) (liftFreeVariables f)

instance FreeVariables1 []