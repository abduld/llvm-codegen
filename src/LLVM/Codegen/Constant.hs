module LLVM.Codegen.Constant (
  ci1, ci8, ci16, ci32, ci64,
  cf32, cf64,
  cfloat,
  cdouble,
  cnull,
  cundef,
  cstruct,
  carray,

  Constant(..)
) where

import LLVM.General.AST
import qualified LLVM.General.AST.Float as F
import qualified LLVM.General.AST.Constant as C

ci1, ci8, ci16, ci32, ci64 :: (Integral a) => a -> C.Constant
ci1  = C.Int 1 . fromIntegral
ci8  = C.Int 8 . fromIntegral
ci16 = C.Int 16 . fromIntegral
ci32 = C.Int 32 . fromIntegral
ci64 = C.Int 64 . fromIntegral

cf32, cfloat :: Float -> C.Constant
cf32  = C.Float . F.Single
cfloat = cf32

cf64, cdouble :: Double -> C.Constant
cf64  = C.Float . F.Double
cdouble = cf64

cnull :: Type -> C.Constant
cnull ty = C.Null ty

cundef :: Type -> C.Constant
cundef = C.Undef

cstruct :: [C.Constant] -> C.Constant
cstruct values = C.Struct True values

carray :: Type -> [C.Constant] -> C.Constant
carray ty values = C.Array ty values

-- | Conversion between Haskell numeric values and LLVM constants
class Constant a where
  toConstant :: a -> C.Constant

instance Constant Bool where
  toConstant False = ci1 (0 :: Int)
  toConstant True  = ci1 (1 :: Int)

instance Constant Int where
  toConstant = ci64

instance Constant Float where
  toConstant = cf32

instance Constant Double where
  toConstant = cf64
