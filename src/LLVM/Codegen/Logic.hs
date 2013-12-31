{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE Rank2Types #-}

{-# OPTIONS_GHC -fno-warn-unused-do-bind#-}

module LLVM.Codegen.Logic (
  def,
  var,
  constant,
  ife,
  for,
  while,
  range,
  proj,
  caseof,

  true,
  false,

  one,
  zero
) where

import Control.Monad (forM )

import LLVM.Codegen.Builder
import LLVM.Codegen.Module
import LLVM.Codegen.Types
import LLVM.Codegen.Constant
import LLVM.Codegen.Instructions

import qualified LLVM.General.AST.IntegerPredicate as IP

import LLVM.General.AST (Name(..), Type, Operand)

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

false :: Codegen Operand
false = return $ constant i1 0

true :: Codegen Operand
true = return $ constant i1 1

zero :: Operand
zero = constant i32 0

one :: Operand
one = constant i32 1

-------------------------------------------------------------------------------
-- Function
-------------------------------------------------------------------------------

-- | Construct a toplevel function.
def :: String -> Type -> [(Type, String)] -> Codegen Operand -> LLVM ()
def name retty argtys m = do
  define retty name argtys blocks
  where
    blocks = createBlocks $ execCodegen [] $ do
      entry <- addBlock entryBlockName
      setBlock entry
      forM argtys $ \(ty, a) -> do
        avar <- alloca ty
        store avar (local (Name a))
        setvar a avar
      m >>= ret

-- | Construct a variable
var :: Type -> Operand -> String -> Codegen Operand
var ty val name = do
  ref <- alloca ty
  store ref val
  setvar name ref
  return ref

{-constant :: Type -> (forall a. Num a => a) -> Operand-}
constant ty val
  | ty == i1  = cons $ ci1  $ fromIntegral val
  | ty == i8  = cons $ ci8  $ fromIntegral val
  | ty == i16 = cons $ ci16 $ fromIntegral val
  | ty == i32 = cons $ ci32 $ fromIntegral val
  | ty == i64 = cons $ ci64 $ fromIntegral val
  | ty == f32 = cons $ cf32 $ fromIntegral val
  | ty == f64 = cons $ cf32 $ fromIntegral val

-- | Construction a if/then/else statement
ife :: Operand -> Codegen Operand -> Codegen Operand -> Codegen Operand
ife cond tr fl = do
  ifthen <- addBlock "if.then"
  ifelse <- addBlock "if.else"
  ifexit <- addBlock "if.exit"

  cbr cond ifthen ifelse

  setBlock ifthen
  trval <- tr
  br ifexit
  ifthen <- getBlock

  setBlock ifelse
  flval <- fl
  br ifexit
  ifelse <- getBlock

  setBlock ifexit
  phi double [(trval, ifthen), (flval, ifelse)]

-- | Construction a for statement
for :: Codegen Operand -> Codegen Operand -> Codegen Operand -> Codegen a -> Codegen ()
for ivar inc cond body = do
  forcond <- addBlock "for.cond"
  forloop <- addBlock "for.loop"
  forexit <- addBlock "for.exit"

  i <- ivar
  n <- inc
  br forcond

  setBlock forcond
  test <- cond
  cbr test forloop forexit

  setBlock forloop
  body
  ival <- load i
  iinc <- add ival n
  store i iinc
  br forcond

  setBlock forexit
  return ()

-- | Construction for range statement
range :: String -> Codegen Operand -> Codegen Operand -> Codegen a -> Codegen ()
range ivar start stop body = do
  forcond <- addBlock "for.cond"
  forloop <- addBlock "for.loop"
  forexit <- addBlock "for.exit"

  lower <- start
  upper <- stop
  i <- var i32 lower ivar
  br forcond

  setBlock forcond
  test <- icmp IP.SLT i upper
  cbr test forloop forexit

  setBlock forloop
  body
  ival <- load i
  iinc <- add ival one
  store i iinc
  br forcond

  setBlock forexit
  return ()

while :: Codegen Operand -> Codegen a -> Codegen ()
while cond body = do
  forcond <- addBlock "while.cond"
  forloop <- addBlock "while.loop"
  forexit <- addBlock "while.exit"

  br forcond

  setBlock forcond
  test <- cond
  cbr test forloop forexit

  setBlock forloop
  body
  br forcond

  setBlock forexit
  return ()

-- | Construction a record projection statement
proj struct field = undefined

-- | Construction a case statement
caseof val brs = undefined

-- | Construction of a sequence statement
seq a b = a >> b
