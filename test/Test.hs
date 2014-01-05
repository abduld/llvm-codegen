{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Applicative

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.Golden

import LLVM.Codegen
import LLVM.Codegen.Types
import LLVM.Codegen.Instructions
import LLVM.Codegen.Pipeline
import LLVM.Codegen.Structure
import LLVM.Codegen.Array
import LLVM.Codegen.Execution
import qualified LLVM.Codegen.Intrinsics as I

import LLVM.General.AST (Operand)

-------------------------------------------------------------------------------
-- Cases
-------------------------------------------------------------------------------

test_simple :: LLVM ()
test_simple = do
  def "foo" i32 [(i32, "x")] $ do
    let a = constant i32 1
    let b = constant i64 1000
    add a b

test_multiple :: LLVM ()
test_multiple = do
  def "foo" i32 [(i32, "x")] $ do
    x <- getvar "x"
    res <- load x
    return $ res

  def "bar" i32 [(i32, "x")] $ do
    return $ cons $ ci32 1000

test_for :: LLVM ()
test_for = do
  foo <- external i32 "foo" []

  def "forloop" i32 [] $ do
    for i inc (const true) $ \_ -> do
      for j inc (const true) $ \_ -> do
        call (fn foo) []
    return zero

  where
    i = var i32 zero "i"
    j = var i32 zero "j"
    inc = add one

test_record :: LLVM ()
test_record = do
  rec <- record "myrecord" [("kirk", i32), ("spock", f32)]
  def "main" i32 [] $ do
    x <- alloca (recType rec)
    xp <- proj rec x "kirk"
    load xp

test_comparison :: LLVM ()
test_comparison = do
  def "main" i1 [(i32, "x")] $ do
    x <- getvar "x"
    xv <- load x
    xv `ilt` one

test_intrinsic :: LLVM ()
test_intrinsic = do
  llsqrt <- llintrinsic I.sqrt
  tixx <- llintrinsic I.tixx

  def "main" f64 [] $ do
    let x = constant f64 2
    call (fn llsqrt) [x]

test_debug :: LLVM ()
test_debug = do
  def "main" i32 [] $ do
    debug "%i" x
  where
    x = constant i32 42

test_full :: LLVM ()
test_full = do
  def "main" i32 [] $ do
    let i = var i32 zero "i"
    let j = var i32 zero "j"

    for i inc cond $ \ix -> do
      for j inc cond $ \jx -> do
        sum <- add ix jx
        debug "%i" sum
    return zero

  where
    inc = add one
    cond x = x `ilt` (constant i32 15)

test_loopnest :: LLVM ()
test_loopnest = do
  foo <- external i32 "foo" [(i32, "i"), (i32, "j")]

  def "main" i32 [] $ do
    loopnest [0,0] [10,20] [1,1] $ \ivars -> do
      call (fn foo) ivars
    return zero

-------------------------------------------------------------------------------
-- Test Runner
-------------------------------------------------------------------------------

myPipeline :: Pipeline
myPipeline = [
    ifVerbose showPass
  , verifyPass
  , ifVerbose (optimizePass 3)
  , ifVerbose showPass
  ]

compile :: LLVM a -> IO ()
compile m = do
  let ast = runLLVM (emptyModule "test module") m
  result <- runPipeline myPipeline settings ast
  case result of
    Left a -> print a
    Right b -> return ()
  where
    settings = defaultSettings { verbose = False }

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "Tests" [unitTests]

unitTests = testGroup "Pipeline tests"
  [
    testCase "test_simple" $ compile test_simple
  , testCase "test_multiple" $ compile test_multiple
  , testCase "test_for" $ compile test_for
  , testCase "test_record" $ compile test_record
  , testCase "test_comparison" $ compile test_comparison
  , testCase "test_intrinsic" $ compile test_intrinsic
  , testCase "test_debug" $ compile test_debug
  , testCase "test_full" $ compile test_full
  , testCase "test_loopnest" $ compile test_loopnest
  ]
