{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Data.Char
         (isSpace)
import System.Console.Haskeline
import System.Console.Haskeline.History
         (addHistoryUnlessConsecutiveDupe)
import System.IO

import Syntax
import Parser
import Eval
import Type
import Typing

initEnv = []
initTenv = []

isInputFinished :: String -> Bool
isInputFinished str =
  isInputFinished' $ reverse str

isInputFinished' str =
  case str of
    ';' : ';' : str' -> True
    c : str'
      | isSpace c -> isInputFinished' str'
      | otherwise -> False
    _             -> False

repl :: String -> Int -> TyEnv -> Env -> InputT IO ()
repl input' n tenv env = do
  minput <- getInputLine prompt
  case minput of
    Nothing -> return ()
    Just "quit" -> return ()
    Just "exit" -> return ()
    Just input ->
      if not $ isInputFinished input
        then repl (input' ++ input ++ " ") n tenv env
        else do
          history <- getHistory
          putHistory $ addHistoryUnlessConsecutiveDupe (input' ++ input) history
          case parseExpr (input' ++ input) of
            Left msg -> do
              outputStrLn ("Parse error: " ++ msg)
              repl "" n tenv env
            Right parsedProg -> do
              -- outputStrLn $ show parsedProg
              case typeCheck n tenv parsedProg of
                Left msg -> do
                  outputStrLn ("Type error: " ++ msg)
                  repl "" n tenv env
                Right (t, tenv', c, n) -> do
                  -- outputStrLn $ show c -- for debug
                  -- outputStrLn $ show tenv'
                  -- outputStrLn $ show t
                  case parsedProg of
                    CExpr e -> do
                      outputStrLn $ "- : " ++ show t ++ " = " ++ show (eval env e)
                      repl "" n tenv' env
                    CDecl e -> do
                      let (env', v) = evalDecl env e
                      outputStrLn $ "val " ++ nameOfDecl e ++ " : " ++ show t ++ " = " ++ show v
                      repl "" n tenv' env'
          `catch`
          (\((EvalErr msg) :: EvalErr) -> do
            outputStrLn msg
            repl "" n tenv env)
    where
      prompt = if null input' then "# " else "  "

haskelineSettings :: Settings IO
haskelineSettings = Settings {
  complete = completeFilename,
  historyFile = Nothing,
  autoAddHistory = False
}

main :: IO ()
main =
  runInputT haskelineSettings $ repl "" 0 initTenv initEnv