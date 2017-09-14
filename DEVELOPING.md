# Sai Developer Documentation

This is a developer level guide to the Sai source layout and how the
different objects relate to each other.


## Introduction

Sai is Simple-Dai, a simplification of the Dai Stablecoin System
intended for field testing and refining Dai components. Sai has several
features that distinguish it from Dai:

- trusted price feed
- single collateral type
- global settlement
- liquidations at fixed price (rather than auctions)

This document is an introduction to Sai, aimed at those seeking an
understanding of the Solidity implementation.  We assume knowledge of
the [white paper], a high level overview of Dai.  A reading of the
[purple paper], the (in progress) detailed Dai technical specification
and reference implementation is useful but not required.

XXX: include LL link?

There is ongoing work to specify Sai (and Dai) using Linear Logic,
forming the [teal paper]. This is at a very early draft stage and is
provided for interest. Eventually, this work aims to allow formal
reasoning about system properties.

[white paper]: https://github.com/makerdao/docs/blob/master/Dai.md
[purple paper]: https://makerdao.com/purple
[teal paper]: https://dapphub.github.io/LLsai/sai

### Note on memes

Blockchain applications are a constrained environment. This neccesitates
constrained language.  It is no accident that reading the Sai and Dai
source feels like reading assembly at times.

The idiosyncratic terms used within are affectionately referred to as
'memes':

- four letter memes are typically used for functions that effect state
transitions, and are referred to as 'acts'.
- three letter memes are used for variables, constants, and derived
quantities.


## Overview

Sai uses the following tokens:

- `gem`: underlying collateral (wrapped ether, in practice)
- `skr`: abstracted collateral claim
- `sai`: stablecoin
- `sin`: anticoin, created and destroyed 1:1 with `sai`

Sai has the following core components:

- `jar`: A token wrapper
- `tub`: CDP record store
- `tip`: target price feed
- `tap`: liquidation mechanism
- `top`: global settlement facilitator

TODO: jar, `pot` and `pit` vault info

TOOD: risk parameters


### `jar`: A Token Wrapper

The `jar` is a token wrapper. Users `join` to deposit `gem` in return
for `skr`, and `exit` to claim `gem` with their `skr`.

![Join-Exit](https://user-images.githubusercontent.com/5028/30302214-a5e79350-97b3-11e7-924c-adc2edf1c61d.png)

`skr` is a simple proportional claim on a collateral pool, with the
initial `gem`<->`skr` exchange ratio being 1:1.  The essential reason
for this abstraction will be developed later, but for now it is
sufficient to see `skr` as a token with intrinsic value.

The `gem`/`skr` exchange rate is called `per`, and is calculated as the
total number of deposited `gem` divided by the total supply of SKR.

The reference price of `gem` (in practice, ETHUSD) is provided by the
`pip`, an external oracle. The `pip` is completely trusted.

The reference price of `skr` is then given by the dynamic `tag`, e.g.
the price of SKR in USD.


### `tip`: Target Price Oracle

The `tip` is a simple oracle for the Sai *target price*, given in terms
of the reference unit, by `par`. For example, `par == 2` with USD as
the reference unit implies a target price of 2 USD per Sai.

The target price can vary in time, at a rate given by `way`, which is
the multiplicative rate of change per second.


### `tub`: CDP Record Engine

The `tub` is the CDP record system.  An individual CDP is called a `cup`
(i.e. a small container), and has:

- `lad`: an owner
- `ink`: locked SKR collateral
- `art`: debt

It is crucial to know whether a CDP is well collateralised or not:
`safe(cup)` returns a boolean indicating this.

`safe` aggregates price information from the `tip` and the `jar` and
compares the reference value of a CDPs debt and collateral.

The following `tub` acts are not possible if they would transition a CDP
to unsafe:

---

![Open | Give](https://user-images.githubusercontent.com/5028/30352570-b4c0f6a2-9874-11e7-8ca3-336531da4c0d.png)

- `open`: create a new CDP
- `give`: transfer ownership (changes `lad`)
---

![Lock-Free](https://user-images.githubusercontent.com/5028/30302506-9ff08748-97b5-11e7-95bb-f03ae7d92a1b.png)


- `lock`: deposit SKR collateral (increases `ink`)
- `free`: withdraw SKR collateral (decreases `ink`)

---

![Draw | Wipe](https://user-images.githubusercontent.com/5028/30319553-5094c4e4-9804-11e7-9417-c9085a771643.png)

- `draw`: create Sai (increases `art`)
- `wipe`: return Sai (decreases `art`)

---

- `shut`: clear all CDP debt, unlock all collateral, and delete the record

---

<img src="https://user-images.githubusercontent.com/5028/30306754-383f5304-97ce-11e7-9f2e-dcd077b5f1f9.png" width="600" />

- `bite`: liquidate CDP (zeros `art`, decreases `ink`, transfers `sin` to `pit`)

Unsafe CDPs need to be liquidated. When a `cup` is not `safe`, anyone
can perform `bite(cup)`, which takes on all CDP debt and confiscates
sufficient collateral to cover this, plus a buffer.

This returns the CDP to a safe state (possibly with zero collateral).
There are other possible implementations of `bite`, e.g. only taking
sufficient collateral to just transition the CDP to safe, but the
described implementation is chosen for simplicity.

`bite` transfers the `sin` associated with the CDP to the `pit` - the
liquidator vault.

---


### `tap`: The Liquidator

The `tap` is a liquidator. It has three token balances that determine
its allowed behaviour:

- `joy`: Sai balance, surplus transferred from `drip`
- `woe`: Sin balance, bad debt transferred from `bite`
- `fog`: SKR balance, collateral pending liquidation

and one derived price, `s2s`, which is the price of SKR in Sai. The
`tap` seeks to minimise all of its token balances. Recall that Sai can
be canceled out with Sin via `heal`.

The `tap` has two acts:

- `boom`: sell Sai in return for SKR (decreases `joy` and `woe`, decreases SKR supply)
- `bust`: sell SKR in return for Sai (decreases `fog`, increases `joy` and `woe`, can increase SKR supply)

`boom` is the simpler function and can be thought of as buy and burn.
Given a net Sai balance, sell the Sai in return for SKR, which is
burned.

<img src="https://user-images.githubusercontent.com/5028/30313253-d17d6386-97f0-11e7-935d-747521bf9478.png" width="500" />

`bust` is really two functions in one: collateral sell off, and
inflate and sell. When `fog` is non zero it is sold in return for Sai,
which is used to cancel out the bad debt, `woe`. If `fog` is zero but
the `tap` has a net Sin balance, then SKR is minted and sold in return
for Sai, up to the point that the net Sin balance is zero.

![Bust](https://user-images.githubusercontent.com/5028/30313251-cf8596d4-97f0-11e7-9140-ed75c9c335ef.png)

Through `boom` and `bust` we close the feedback loop on the price of
SKR. When there is surplus Sai, SKR is burned, decreasing the SKR supply
and increasing `per`, giving SKR holders more GEM per SKR. When there is
surplus Woe, SKR is inflated, increasing the SKR supply and decreasing
`per`, giving SKR holders less GEM per SKR.

The reason for wrapping GEM in the `jar` is now apparent: *it provides a
way to socialise losses and gains incurred in the operation of the system.*

Two features of this mechanism:

1. Whilst SKR can be inflated significantly, there is a finite limit on
   the amount of bad debt the system can absorb - given by the value of
   the underlying GEM collateral.

2. There is a negative feedback between `bust` and `bite`: as SKR is
   inflated it becomes less valuable, reducing the safety level of CDPs.
   Some CDPs will become unsafe and be vulnerable to liquidation,
   creating more bad debt. In an active market, CDP holders will have to
   be vigilant about the potential for SKR inflation if they are holding
   tightly collateralised CDPs.


### `top`: Global Settlement Manager

Other components need very little awareness of what `top` does.

`top` just needs authority to move balances from vaults.

This also serves as a useful frontend entrypoint to the system, as it
links to all other components.

TODO: finish this


### `drip`, `art` and `chi`: Dynamic Fee Accumulation

In a simpler system with no interest rates, we could denominate CDP debt,
the `tab`, directly in `sin`. However with non zero interest, `tab` is a
dynamic quantity, computed from `art`, a per CDP debt unit, and `chi`,
the price of this debt unit in `sin`.

```
tab(cdp) = cdp.art * chi
```

The internal debt price, `chi`, is dynamic and is updated by the `drip`
act, which also collects unprocessed revenue.

The `chi` abstraction allows us to compute the per CDP debt, and the
total unprocessed revenue, with varying `tax`, in constant time.

<img src="https://user-images.githubusercontent.com/5028/30360338-dd708204-98a4-11e7-9da7-f016840a120c.png" width="600" />

## Auth setup

ds-auth is used, with no owners (XXX: check) and two authorities:

1. `dad`: ds-guard, used for internal authority

2. `mom`: ds-roles, used for external authority

The auth setup looks as follows: sai-auth.jpeg [XXX: do this in graphviz]


### Sai v1 features

- `drip` == 1 (optimisation)
- `auth` on all functions

### Changes in Sai v2

- `auth` only on admin functions
- updated to latest dappsys


## Deployment

Scripts, scripts, scripts.. also see test setup.

Script output gist

## Glossary

### Prices

- `per`: gem per skr
- `par`: ref per sai
- `tag`: ref per skr
- `pip`: ref per gem
- `price`: sai per gem
- `fix`: gem per sai after `cage`
- `fit`: gem per skr after `cage`


### Meme Mnemonics

- `pip`: trading pips
- `jar`: where collateral is kept
- `tip`: target price tip-off
- `cup`: small container for CDP info
- `tub`: larger container for cups
- `tap`: liquidity provider
- `top`: top-level system manager

- `way`: which way the target price is heading
- `mat`:
- `hat`:
- `axe`
- `tax`
- `gap`

- `air`
- `fog`
- `joy`: SKR holders are happy about this
- `woe`: SKR holders are sad about this

- `pot`:
- `pit`: where to put unwanted things
