module Eval where

import Syntax

eval :: Env -> Expr -> Value
eval env e =
    case e of
      EConstInt n -> VInt n
      EConstBool b -> VBool b
      EVar x ->
          case lookup x env of
            Just v -> v
      ETuple es ->
          VTuple $ map (eval env) es
      ENot e' ->
          case eval env e' of
            VBool b -> VBool $ not b
      ENeg e' ->
          case eval env e' of
            VInt n -> VInt $ -1 * n
      EBinop op e1 e2 ->
          evalBinOp op (eval env e1) (eval env e2)
      EIf e1 e2 e3 ->
          case eval env e1 of
            VBool b -> if b then eval env e2 else eval env e3
      EFun x e ->
          VFun x e env
      ELet x e1 e2 ->
          eval ((x, eval env e1) : env) e2
      EApp f e ->
          let z = eval env e in
          case eval env f of
            VFun x body env' -> eval ((x, z) : env') body

evalBinOp :: Binop -> Value -> Value -> Value
evalBinOp op =
    case op of
      BAnd -> \ (VBool b1) (VBool b2) -> VBool $ b1 && b2
      BOr  -> \ (VBool b1) (VBool b2) -> VBool $ b1 || b2
      BAdd -> \ (VInt n1) (VInt n2)   -> VInt  $ n1 + n2
      BSub -> \ (VInt n1) (VInt n2)   -> VInt  $ n1 - n2
      BMul -> \ (VInt n1) (VInt n2)   -> VInt  $ n1 * n2
      BDiv -> \ (VInt n1) (VInt n2)   -> VInt  $ n1 `div` n2
      -- we don't need pattern-match for the arguments after type matching
      BEq  -> \ e1 e2 -> case (e1, e2) of (VInt a, VInt b)   -> VBool $ a == b
                                          (VBool a, VBool b) -> VBool $ a == b
      BGT  -> \ e1 e2 -> case (e1, e2) of (VInt a, VInt b)   -> VBool $ a > b
                                          (VBool a, VBool b) -> VBool $ a > b
      BLT  -> \ e1 e2 -> case (e1, e2) of (VInt a, VInt b)   -> VBool $ a < b
                                          (VBool a, VBool b) -> VBool $ a < b
      BGE  -> \ e1 e2 -> case (e1, e2) of (VInt a, VInt b)   -> VBool $ a >= b
                                          (VBool a, VBool b) -> VBool $ a >= b
      BLE  -> \ e1 e2 -> case (e1, e2) of (VInt a, VInt b)   -> VBool $ a <= b
                                          (VBool a, VBool b) -> VBool $ a <= b

evalDecl :: Env -> Decl -> (Env, Value)
evalDecl env e =
    case e of
      DLet x e ->
          ((x, val) : env, val)
              where val = eval env e
      DLetRec f e ->
          case e of
            EFun x e' ->
                let env' = (f, VFun x e' env') : env
                    val = VFun x e' env'
                 in ((f, val) : env, val)
