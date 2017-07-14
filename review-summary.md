# Code Review

Completed July 14, 2017

Written of commit 7f1cef39a4d2454bee3ebcd476bc0b56304cbf7d


## Assumptions

All outside contracts which integrate with the sai system, particularly the
ERC20 contracts, are vetted manually by incentive-aligned actors before
inclusion. Failure to satisfy this assumption could result in the system
behaving in unintended ways.


## Findings

From a UI perspective it may make sense to provide a function on `Tub` which
combines the `open`, `lock`, and `draw` functions, assuming the gas costs permit
it. This recommendation is made under the assumption that `Tub` is meant to be
interacted with by transaction issuers.

The variable and function names chosen are unintuitive and don't aid
understanding. If the goal of this system is to be widely understood, then it
ought to provide better cues for the reader's memory and better cues regarding
the author's intent. The use of the compound interest mechanism, `Tip`,
everywhere was somewhat confusing as well. The relevance of compounded interest
to a price feed is not immediately obvious.
