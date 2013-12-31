module LLVM.Codegen.Types (
  i1, i8, i16, i32, i64, i128,
  f32, f64,
  void,
  pointer,
  array,
  vector,
  struct,
  fun,
  sizeOf,

  -- aliases
  float,
  double,
) where


import Data.Word
import LLVM.Codegen.Utils
import LLVM.General.AST hiding (vector)

import LLVM.General.AST.AddrSpace
import qualified LLVM.General.AST.Constant as C

-- | Integer types
i1, i8, i16, i32, i64, i128 :: Type
i1   = IntegerType 1
i8   = IntegerType 8
i16  = IntegerType 16
i32  = IntegerType 32
i64  = IntegerType 64
i128 = IntegerType 128

-- | Floating point types
f32, f64 :: Type
f32  = FloatingPointType 32 IEEE
f64  = FloatingPointType 64 IEEE

float, double :: Type
float = f32
double = f64

-- | Void type
void :: Type
void = VoidType

-- | Pointer type constructor
pointer :: Type -> Type
pointer ty = PointerType ty (AddrSpace 0)

-- | Array type constructor
array :: Word64 -> Type -> Type
array elements ty = ArrayType elements ty

-- | Vector type constructor
vector :: Word32 -> Type -> Type
vector width ty = VectorType width ty

-- | Struct type constructor
struct :: [Type] -> Type
struct fields = StructureType True fields

-- | Function type constructor
fun :: Type -> [Type] -> Type
fun argtys retty = FunctionType argtys retty True

-- | sizeOf instruction
sizeOf ::  Type -> Operand
sizeOf ty = ConstantOperand $ C.PtrToInt
            (C.GetElementPtr True ty' [C.Int 32 1]) ptr'
  where
    ty'  = C.Null $ PointerType ty (AddrSpace 0)
    ptr' = IntegerType $ fromIntegral bitsize

class Typed a where
  signed :: a -> Bool
