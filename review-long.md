# Code Review

Completed July 14, 2017

Written of commit 7f1cef39a4d2454bee3ebcd476bc0b56304cbf7d


## The Format

I've written this review in a prose-like format which can function as a source
of documentation for those seeking to understand the system. I've written it
this way as an aid to my own understanding while performing this review, as I
find describing a system helps me understand it further.

The system is described file-by-file in a way which builds on itself, assuming
familiarity with terms already defined in previous files. The descriptions may
be referred to in order to check how my understanding of the system underpins
the suggestions I make.

To succinctly define terms, parentheticals are sometimes used. To disambiguate
the term definition from the rest of the prose, *italics* are used.

Example:

> This paper describes the code implementing *a simplified stable token (sai)*.


## Assumptions

All outside contracts which integrate with the sai system, particularly the
ERC20 contracts, are vetted manually by incentive-aligned actors before
inclusion. Failure to satisfy this assumption could result in the system
behaving in unintended ways.


## tip.sol

Contains a contract called `Tip`, which subclasses a `DSWarp` contract for its
`era` function, which returns the current time by default. (`DSWarp` also allows
setting the `era` return value to some point in the future and freezing the
normal time-based progression of its return values, but this functionality is
not used here.) It enables keeping track of a compounded rate over time. In the
compound interest formula, `p(1+r/n)^nt`, it assumes `n` is 1 and keeps track of
`(1+r)^t`, with `t` being the Unix timestamp and `1+r` being the value last set
via `coax`.

`coax` sets the rate at which the amount rises. As mentioned before, the rate is
equivalent to the `1 + r/n` figure in the compound interest formula,
`p(1+r/n)^nt`, where `n` is 1 and `t` is the current Unix timestamp. If a value
is supplied which would result in an per-hour compound interest rate of greater
than 200% or less than -200%, the function throws.

`par` calls `prod` and then returns the current value denoted by the `Tip`
contract.

`prod` updates the current value denoted by the Tip contract based on how much
time has passed, saving it to storage.

The values returned by `par` are static relative to when the contract was
deployed, as there is no way to set the underlying principal in the formula.

**This contract could unintentionally lock if left open long enough and with an
high enough interest rate that a uint128 overflow occurs when `prod` is
called.**


## jar.sol

Contains a contract called `SaiJar`. `SaiJar` takes a reference to a DSToken
contract (called `skr`, whose tokens are henceforth referred to as SKR), some
arbitrary ERC20 token (called `gem`, whose tokens are henceforth referred to as
gems), and the sai target price in terms of the `gem` (called `pip`). It sets a
value called `gap` which scales the costs of tokens in the contract and SKR (the
`bid` and `ask` function return values), effectively setting the spread. (I.e.,
`gap` is a figure which determines the size of the `SaiJar` order spread by
virtue of acting as a multiplier on the SKR-per-gems and gems-per-SKR figures.)

`tag` returns the price of SKR in terms of *the sai target value (`ref`)*.

`per` returns the ratio of `gem` tokens held in the contract to `skr` tokens

`jump` sets `gap`. I dislike this naming, as I feel it's particularly
unintuitive. I've expressed my opinion at length in the DappHub RocketChat.

`bid` and `ask` are self-explanatory for those familiar with exchanges.

`join` takes *the address of a user (`guy`)* and *a number denoting a quantity
of gems (`jam`)*. It determines *the amount of SKR which `jam` gems would get the
user based on the current `ask` (`ink`)*. It mints the user `ink` SKR, then
debits the user `jam` gems.

`exit` does the inverse of `join`, burning `ink` SKR and crediting `jam` gems
based on the current `bid`.

This class is simple and should not cause problems given my assumptions.


## lib.sol

`SaiJug` wraps two DSTokens, one called `gem` and one called `sin`. `sin` is
meant to be a debt token and `gem` is meant to be an asset. In `lend`, `sin` and
`gem` are minted in equal measure. In `mend`, they are burned the same way. A
`DSVault` with the ability to `mint` and `burn` both tokens must be supplied to
both functions. The `DSVault` argument is called `guy`, which is a strange name,
but the functions are short enough that it doesn't really matter.

`SaiJug`'s purpose appears to be to maintain an even balance of sai tokens and
debt tokens.

A function called `heal` calls `mend` with the lesser of the user's `gem` and
`sin` balances.

This class is very simple and should not cause problems given my assumptions.


## lpc.sol

Contains a contract called `SaiLPC`, defined as a "simple two token liquidity
pool that uses an external price feed." Takes two `DSToken`s, one called `ref`
and the other called `alt`. Also takes a `DSValue` (a contract which encompasses
a value and has an "is unset" boolean, disambiguating "null because not set"
from "null because set as such") representing the price of `ref` in terms of
`alt`. Finally, takes *a `DSToken` used to reward people for providing liquidity
to the contract (`lps`)* and *a `Tip` contract representing the `lps` fee
discounted when supplying the `alt` token (`tip`)*.

The `jump` function sets `gap`. In this contract, `gap` is the value that
determines how much of a fee will be exacted (or bonus provided) in `lps` tokens
when `lps` tokens are burned via the `exit` function.

The `tag` function returns the value in `pip`, cast to `uint128`.

The `pie` function returns the value of all tokens in the contract, minus the
`pool` and `exit` fees on `alt` tokens.

The `pool` function takes either an `alt` or a `ref` token as the first
argument, *the amount the user wishes to send the contract (`wad`)* as the
second argument and mints `lps` tokens. A fee is assessed for providing `alt`
tokens based on the `Tip` contract. (I.e., this fee compounds with time.)

The `exit` function does the opposite of the `pool` function, including
refunding the fee for providing `alt` tokens so that you get back the same
amount of `alt` if you `pool` for `lps` and then `exit` to get rid of the `lps`
in the same block. Otherwise some will always be held back due to the
compounding of `Tip` over time. Also, a fee or bonus is assessed based on the
contract's `gap` value. (Either some extra `lps` will be pulled while you
retrieve your tokens or you will have some left over after trying to provide the
original amount.)

The `take` function accepts the same arguments as `pool` and `take`. It uses
`Tip` to give a bonus or take a fee from the `alt` or `ref` token the user is
offering (the one which the `gem` argument is not) and `gap` to assess a static
fee/spread. The function transfers `wad` `gem` tokens to the user and pulls
enough of the other token (`ref` or `alt`) to pay for the requested number of
`gem` tokens.


## tub.sol

This file contains a contract called `Tub`. The `Tub` contract exists to allow
people to open CDPs (Collateralized Debt Positions). It takes a `SaiJar`
(`jar`), a `SaiJug` (`jug`), a `DSVault` (`pot`), another `DSVault` (`pit`),
and a `Tip` (`tip`). The `gem` and `skr` properties of the `jar` are immediately
pulled out into the `Tub`'s own `gem` and `skr` properties. The `gem` and `sin`
properties are also pulled from `jug` into the `Tub`'s properties of the same
names. The `tip`'s `era` property is saved as `rho`. When the `Tub` is `cage`d,
it saves the `era` return value from `tip` in its `caged` property.

This is the largest contract in the Sai system and might benefit from being
split up a bit.

First, the setter functions:

- `chop` sets `axe`, the penalty for having a CDP margin called as ratio of
  amount originally owed to amount owed upon margin call.
- `cork` sets `hat`, the debt ceiling for the `gem` collateral.
- `cuff` sets `mat`, the ratio of `gem` price to `ref` price, as reported by
  `tip`.
- `crop` sets `tax`, the time-based "stability fee" exacted when the CDP is
  closed. The stability fee is capped at 200% per hour. It also calls `drip`, a
  description of which can be found below.

Then, the getter functions:

- `ice` gets the balance of debt/`sin` tokens in *the vault which issues sai and
  debt tokens, (`pot`)*.
- `pie` gets the balance of collateral/`gem` tokens in *the vault which holds
  `gem` and `skr` tokens, (`jar`)*.
- `air` gets the balance of profit claim/`skr` tokens in *the vault which holds
  `gem` and `skr` tokens, (`jar`)*.

`chi` calls `drip`, which sets `_chi` as a side effect, and returns `_chi`. This
function name breaks the "four letter names for functions that mutate state"
guideline.

`drip` updates *the variable which keeps track of when drip was last called
(`rho`)*, compounds the `_chi` property (which starts at a hard-coded value and
can't be changed any other way), increases the amount of outstanding debt tokens
and `sai` tokens based on some relation between the compounded `_chi` value and
the previous `_chi` value, and leaves the sai in `pot` and the `sin` in `pit`.

`safe` takes *a CDP represented via the `Cup` struct (`cup`)* and returns a
boolean indicating whether `cup` meets the minimum collateralization
requirements for its asset.

`join` and `exit` are provided as pass-through functions on the `jar` `DSVault`
object. Before passing-through the call, they check to make sure the position
can be `join`ed (Is the `Tub` un-`cage`d?) and `exit`ed (Is the `Tub` either
un-`cage`d or is it `cage`d and either all debt/`sin` tokens cleared or 6 hours
passed?).

`open` reserves a CDP slot for the transaction sender, unless the `Tub` is
`cage`d.

`wipe` can only be called on a CDP in an un-`cage`d `Tub` by the CDP holder. It
takes a CDP identifier and a `uint128` value, which in this case represents the
amount of debt the holder wishes to pay off. It calculates the amount of debt to
leave in the CDP based on the interest accrued, debits the requested amount of
`sai` from the holder, and destroys the debited `sai` along with an equal amount
of `sin`/debt tokens.

`free` takes the same arguments as `wipe` and has the same constraints on when
and by whom it may be called. It decreases the balance of `skr` collateral held
in a CDP by the amount passed as an argument and pushes the collateral to the
holder.

`shut` takes a CDP identifier and calls `wipe` and `free` with the identifier as
the first argument, and the total amount of debt held by the CDP and the total
amount of collateral held by the CDP, respectively, as the second. It then
removes the CDP from the collection of open CDPs.

`lock` takes a CDP identifier and a `uint128` representing the amount of
collateral to add to the identified CDP. It has the same calling constraints as
the `wipe` function. It debits the specified amount of `skr` collateral and
increases the balance of collateral held by the CDP by the same amount. As the
`open` function creates a CDP with zero debt and zero collateral, this function
will almost always be called immediately after calling `open`.

`draw` has the same constraints on calling as `wipe` does, and takes the same
argument types. The `uint128` value here represents an amount by which to
increase the debt of the specified CDP. It assesses a penalty for doing so based
on the compounded interest rate/"debt price." As the `open` function creates a
CDP with zero debt and zero collateral, this function will almost always be
called immediately after calling `open` and `lock`. This function issues the
appropriate amount of `sai` to the CDP holder and also creates the appropriate
amount of `sin` via the `SaiJug` `lend` function.

`give` takes a CDP identifier and an address, then transfers ownership of the
CDP to the given address. The address to which ownership is transfered cannot be
the null address, `0x0`. The function may only be called by the owner of the CDP
in question.

`tag` returns the number of `gem` tokens available per `skr` token. The value is
static if the `cage` function has already been called and reflects the value of
`jar.tag()` at the time of the `cage` function call.

`bite` takes a CDP identifier. For this function call to succeed, either the
`Tub` must be `cage`d or the specified CDP must be under-collateralized. First
all the `sin`/debt tokens held in the CDP are sent to the `pit` address, then
the CDP's debt balance is cleared, then the margin call fee is assessed, and
then the lesser of the debt owed plus fee and all the collateral in the CDP are
sent to the pit address. The collateral balance of the CDP is reduced
by the same amount sent to the `pit` address.

`cage` changes the `Tub`'s `reg` value from `Stage.Usual` to `Stage.Caged`,
allowing all the other functions to determine if the `cage` function has been
called or not, and saves the current price of collateral in terms of `skr` under
the `Tub`'s `fit` property.


## tap.sol

This file supplies a `Tap` contract. The `Tap` contract handles liquidation of
contracts. The constructor takes a `Tub` called `tub` and a `DSVault` called
`pit`. It grabs `tub`'s `sai`, `sin`, `skr`, and `jug` properties and saves it
as its own properties under the same names. It also has a `gap` property.

`joy` returns the amount of `sai` in the `pit` `DSVault`.

`woe` returns the amount of `sin`/debt tokens in the `pit` `DSVault`.

`fog` returns the amount of `skr`/collateral tokens in the `pit` `DSVault`.

`s2s` returns the ratio of `skr` to `sai` in `tub`.

`jump` sets `gap`.

`bid` returns the price of `skr` in `sai`, scaled in accordance with `gap`. If
`gap` is `> 1`, then it will be scaled down. If `gap` is `< 1`, it will be
scaled up.

`ask` returns the price of `skr` in `sai`, scaled in accordance with `gap`. If
`gap` is `< 1`, then it will be scaled down. If `gap` is `> 1`, it will be
scaled up.

`boom` takes a `uint128` value representing the amount of `skr` the user wishes
to exchange for `sai` profits. It calls `drip` on `tub`, compounding the amount
of outstanding `sai` and `sin` tokens, then burns `sai` and `sin` tokens in
`pit` (which may not be the `pit` used by `tub`) in equal measure. It then
calculates how much `sai` the amount of `skr` offered is worth based on the
values returned by `tub`'s price feeds and releases that amount of `sai` to the
user after debiting and burning the offered amount of `skr`.

`boom` may only be called if `tub` has not been `cage`d.

`bust` likewise may only be called if `tub` has not been `cage`d. It takes a
`uint128` value representing the amount of `sai` the user wishes to exchange for
`skr`. It calls `drip` on `tub`, compounding the amount of outstanding `sai` and
`sin` tokens, then burns `sai` and `sin` tokens in `pit` (which may not be the
`pit` used by `tub`) in equal measure. If the amount of `skr` held by `pit` is
less than the amount requested, it mints enough to cover the difference, as long
as the value of the difference is less than the value of `sin` tokens held by
`pit` (as reported by the price feed). The value of the `sai` offered is
calculated, based on the `tub` price feeds, and the `sai` offered is debited
from the user and burned, and the requested `skr` is issued to the user. It then
burns the `sai` and `sin` tokens in `pit` in equal measure once more.


## top.sol

This file supplies a `Top` contract, which appears to be the top-level, UI
contract in the system. In the dependency graph of the system, it has all the
other contracts as dependencies and is itself a dependency of none.

Its constructor takes a `Tub` and a `Tap`, called `tub` and `tap` from here on.
It pulls `jar`, `pot`, `jug`, `sai`, `sin`, `skr`, and `gem` from `tub` and
copies them into its own properties by the same name. It does the same with
`pit` from `tap`.

`cage` "forces settlement of the system at a given price." More specifically, it
takes a `uint128` value representing the price of the system's outstanding `sin`
tokens in terms of its collateral, compounds the amount of outstanding `sai` and
`sin` tokens by calling `drip` on `tub`, then calls `cage` on `tub` to freeze
the price of `tub` collateral in terms of `skr`. It calls `heal` on `jug` to
burn the `sai` held by the system and the `sin` held by the system in equal
measure, then burns all `skr` held by `pit` since the system is being liquidated
and `skr` sales no longer serve a purpose. It determines how much collateral is
needed to cover the current outstanding debt (i.e., `sin` tokens) and sends them
to `pit`.

There is also a zero-argument `cage` which just uses the prices from the `tub`
price feeds to figure out the price of the system's `sin` tokens in terms of its
collateral, passing that value along to the `cage` function just described.

`cash` allows `sai` holders to exchange their `sai` for the system's collateral
after `Top` has been `cage`d.

`vent` can only be called after `Top` has been `cage`d. It calls `heal` on
`jug`, passing in `pit`, to destroy the `sin` and `sai` tokens held by `pit` in
equal measure. It then burns all `skr` held by `pit`.


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
