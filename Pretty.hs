{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE TypeFamilies #-}

module Pretty where

import Text.PrettyPrint.HughesPJ hiding ((<>))
import Data.Monoid
import LL
import Control.Lens
import Symheap
import qualified Data.Map as M
import Data.List (intercalate)

------------------------------------
-- Pretty printing of sequents

instance Show (Deriv) where
  show (Deriv ts vs s) = render $ (pCtx ts vs  <> " ⊢") $$ pSeq ts vs s

prn p k = if p > k then parens else id

pType :: Int -> [String] -> Type -> Doc
pType p vs (Forall v t) = prn p 0 $ "∀" <> text v <> ". "  <> pType 0 (v:vs) t
pType p vs (Exists v t) = prn p 0 $ "∃" <> text v <> ". "  <> pType 0 (v:vs) t
pType p vs (x :|: y) = prn p 0 $ pType 1 vs x <> " | " <> pType 0 vs y
pType p vs (x :⊕: y) = prn p 1 $ pType 2 vs x <> " ⊕ " <> pType 1 vs y
pType p vs (x :⊗: y) = prn p 2 $ pType 2 vs x <> " ⊗ " <> pType 2 vs y
pType p vs (x :&: y) = prn p 3 $ pType 3 vs x <> " & " <> pType 3 vs y
pType p vs Zero = "0"
pType p vs One = "1"
pType p vs Top = "⊤"
pType p vs Bot = "⊥"
pType p vs (TVar True x) = text $ vs!!x 
pType p vs (TVar False x) = "~" <> text (vs!!x)
pType p vs (Bang t) = prn p 4 $ "!" <> pType 4 vs t
pType p vs (Quest t) = prn p 4 $ "?" <> pType 4 vs t
pType p vs (Meta b s xs) = if_ b ("~" <>) $ text s <> args
  where args = if null xs then mempty else brackets (cat $ punctuate "," $ map (pType 0 vs) xs)

instance Show Type where
  show x = render $ pType 0 ["v" <> show i | i <- [0..]] x

pSeq :: [Name] -> [(Name,Type)] -> Seq -> Doc
pSeq = foldSeq sf where
 sf (Deriv ts vs _) = SeqFinal {..} where
  sty = pType 0
  sax v v' _ = text v <> " ↔ " <> text v'
  scut v _ s t = "connect new " <> text v <> " in {" <> vcat [s<>";",t] <>"}"
  scross _ w v vt v' vt' t = "let " <> text v <> "," <> text v' <> " = " <> text w <> " in " $$ t
  spar _ w vt vt' s t = "connect {"<> vcat [text w <> " : " <> vt <> " in " <> s <> ";",
                                            text w <> " : " <> vt' <> " in " <> t] <>"}"
  splus _ w vt vt' s t = "case " <> text w <> " of {" <> 
                          vcat ["inl " <> text w <> " ↦ " <> s<> ";", 
                                "inr " <> text w <> " ↦ " <> t]<> "}"
  swith b _ w _ t = "let " <> text w <> " = " <> c <> " " <> text w <> " in " $$ t
     where c = if b then "fst" else "snd"
  sbot v = text v 
  szero w vs = "dump " <> pCtx' vs <> " in " <> text w
  sone w t = "let ◇ = " <> text w <> " in " $$ t
  sxchg _ t = t
  stapp w tyB s = "let " <> text w <> " = " <> text w <> "∙" <> tyB <> " in " $$ s
  stunpack tw w s = "let ⟨" <> text tw <> "," <> text w <> "⟩ = " <> text w <> " in " $$ s
  soffer w ty s = "offer " <> text w <> " : " <> ty $$ s
  sdemand w ty s = "demand " <> text w <> " : " <> ty $$ s
  signore w ty s = "ignore " <> text w $$ s
  salias w w' ty s = "let " <> text w' <> " = alias " <> text w <> " : " <> ty $$ s
  swhat a = braces $ pCtx ts vs
       
instance Show Seq where
  show = render . pSeq [] []

pCtx ts vs = pCtx' (over (mapped._2) (pType 0 ts) vs)

pCtx' :: [(Name,Doc)] ->  Doc
pCtx' vs = sep $ punctuate comma $ [text v <> " : " <> t | (v,t) <- vs]

-----------

pClosedType = pType 0 (repeat "<VAR>")

pRef (Named x) = text x
pRef (Shift t x) = pRef x <> "+ |" <> pClosedType t <> "|"
pRef (Next x) = pRef x <> "+1"

pHeapPart :: SymHeap -> SymRef -> Doc
pHeapPart h r = case v of
    Nothing -> "..."
    Just c -> pCell c <> pHeapPart h (Next r) <> pHeapPart h (Shift (error "yada") r)
  where v = M.lookup r h
        
pCell :: Cell SymRef -> Doc
pCell c = case c of
      New -> "[ ]"
      Freed -> "Freed"
      Tag True -> "1"
      Tag False -> "0"
      _ -> "?"

pHeap :: SymHeap -> Doc
pHeap h = cat $ punctuate ", " [text r <> "↦" <> pHeapPart h (Named r) | Named r <- M.keys h]


pSystem (cls,h) = hang "Heap:" 2 (pHeap h) $$
                  hang "Closures:" 2 (vcat $ map pClosure cls)

pClosure (seq,env,typeEnv) = 
         hang "Closure:" 2 (vcat [
           "Code: TODO",
            hang "Env: " 2 (cat $ punctuate ", " [pRef r | r <- env]),
            hang "TypeEnv:" 2 (cat $ punctuate ", " $ map pClosedType typeEnv)])

sshow = putStrLn . render . pSystem  

