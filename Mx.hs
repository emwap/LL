{-# OPTIONS_GHC -XTypeSynonymInstances -XOverloadedStrings -XRecursiveDo -pgmF marxup -F #-}

import MarXup.Latex
import MarXup.Tex
import MarXup.DerivationTrees
import Control.Applicative
import MarXup.MultiRef
import Reductions
import Data.Monoid

import TexPretty
import LL

preamble :: Tex ()
preamble = do
  usepackage ["utf8"] "inputenc"
  usepackage [] "graphicx"
  cmd "input" (tex "unicodedefs")
  usepackage [] "amsmath"
  usepackage [] "cmll" -- for the operator "par"
  title "Linear Logic: I see what it means!"
  authorinfo Plain [("Jean-Philippe Bernardy","bernardy@chalmers.se",ch),("Josef Svenningsson","",ch)]
 where ch = "Chalmers University of Technology and University of Gothenburg"

deriv :: Deriv -> Tex Label
deriv (Deriv tvs vs s) = derivationTree [] $ texSeq False tvs vs s

program :: Deriv -> Tex ()
program (Deriv tvs vs s) = math (block (texProg tvs vs s))

allReductions displayer = mapM_ redRule 
   [(amp<>"⊕",cutWithPlus True),
    (math par<>"⊗",cutParCross),
    ("!?", cutBang),
    ("1⊥",cutUnit),
    ("∀∃",cutQuant),
    ("Contract",cutContract),
    ("Weaken",cutIgnore)]

  where redRule (name,input) = do
          name
          displayMath $ do 
            displayer input
            cmd0 "Longrightarrow"
            displayer (eval input)
          newline

todo = cmd "marginpar"

main = render $ latexDocument "article" ["11pt"] preamble $ @"

@maketitle

@section{Introduction}

@todo{Linear logic as a low-level logic}

@todo{propositions as types, proofs as programs}

We won't dwell on the general benefits of the parallel: this has been done countless times before, 
remarkably by Girard in a paragraph which starts with the following provocative sentence.

@env("quote"){
There are still people saying that, in order to make computer
science, one essentially needs a soldering iron; this opinion is
shared by logicians who despise computer science and by engineers
who despise theoreticians.
}
Very much in the spirit of this conference, this paper aims to build
another bridge between logicians and engineers. 


We provide an interpretation
of linear logic as an programming language with ISWIM syntax, together with an
abstract machine able to run programs written for it.

@todo{π-calculus as a low-level programming language: not quite. We fill the niche}

@section{Cut-elimination rules}
@allReductions(deriv)

@section{Reduction rules}
@allReductions(program)

@section{Discussion}

Many presentations of LL for programming needlessly polarize (dualize)
the presentation. We remain faithful to the spirit of Girard's LL ---
LL is already intuitionistic: there is no need to restrict the system
to give it computational content.


On Intuitionistic Linear Logic, G.M. Bierman 93 
Full Intuitionistic Linear Logic, Hyland & de Paiva 93
A Term Calculus for Intuitionistic Linear Logic; Benton, Bierman, de Paiva, Hyland, 03
Dual Intuitionistic Linear Logic, Andrew Barber 96


A correspondance has recently been identified between linear logic
propositions and session types. A proof of a proposition A can be
identified with process obeying protocol A. This correspondance
departs from the usual linear logic in that the type @math{A ⊗ B} is
interpreted as @math{A} then @math{B}, whereas the usual interpretation of the
linear formula is symmetric with respect to time. Our interpretation
keeps the symmetry intact. The associated calculus is close to the
π-calculus, which we observe is unintuitive to functional programmers
in two respect. On a superficial level, they much prefer ISWIM-like
syntaxes. On a semantic level, the ability to transmit channel names,
departs fundamentally from the tradition of functional programming.



@"



