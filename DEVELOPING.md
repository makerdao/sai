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
and reference implementation, is strongly encouraged but not required.

[white paper]: https://github.com/makerdao/docs/blob/master/Dai.md
[purple paper]: https://makerdao.com/purple


## Overview

Sai uses the following tokens:

- `gem`: underlying collateral (wrapped ether, in practice)
- `skr`: abstracted collateral claim
- `sai`: stablecoin
- `sin`: anticoin, created when the system takes on debt

Sai has the following core components:

- `vox`: target price feed
- `tub`: CDP record store
- `tap`: liquidation mechanism
- `top`: global settlement facilitator

Sai is configured by the following 'risk parameters':

- `way`: Sai reference price drift
- `cap`: Debt ceiling
- `mat`: Liquidation ratio
- `tax`: Stability fee
- `axe`: Liquidation penalty
- `gap`: Join/Exit and Boom/Bust spread



### `skr`: A Token Wrapper

`skr` is a token wrapper.

- `join`: deposit `gem` in return for `skr`
- `exit`: claim `gem` with their `skr`.

![Join-Exit](https://user-images.githubusercontent.com/5028/30517891-928dd4d8-9bc1-11e7-9398-639233d851ae.png)

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


### `vox`: Target Price Feed

The `vox` provides the Sai *target price*, given in terms of the
reference unit, by `par`. For example, `par == 2` with USD as the
reference unit implies a target price of 2 USD per Sai.

The target price can vary in time, at a rate given by `way`, which is
the multiplicative rate of change per second.

The `vox` is the same as that in Dai, but with the sensitivity, `how`,
set to zero. Adjustments to the target price are made by adjusting the
rate of change, `way`, directly with `coax`. In future Sai iterations,
`how` may be non-zero and `way` adjustments will then follow
automatically via the feedback mechanism. The `vox` component is subject
to ongoing economic modelling research.


### `tub`: CDP Record Engine

The `tub` is the CDP record system.  An individual CDP is called a `cup`
(i.e. a small container), and has:

- `lad`: an owner
- `ink`: locked SKR collateral
- `art`: debt

It is crucial to know whether a CDP is well collateralised or not:
`safe(cup)` returns a boolean indicating this.

`safe` aggregates price information from the `vox` and the `tub` and
compares the reference value of a CDPs debt and collateral.

The following `tub` acts are not possible if they would transition a CDP
to unsafe:

---

![Open | Give](https://user-images.githubusercontent.com/5028/30352570-b4c0f6a2-9874-11e7-8ca3-336531da4c0d.png)

- `open`: create a new CDP
- `give`: transfer ownership (changes `lad`)
---

![Lock-Free](https://user-images.githubusercontent.com/5028/30517892-928e06ec-9bc1-11e7-91e8-6ae6caae8585.png)


- `lock`: deposit SKR collateral (increases `ink`)
- `free`: withdraw SKR collateral (decreases `ink`)

---

![Draw | Wipe](https://user-images.githubusercontent.com/5028/30463893-97a6aef4-9a22-11e7-9a65-3055ad05b8d6.png)

- `draw`: create Sai (increases `art`, `rum`)
- `wipe`: return Sai (decreases `art`, `rum`)

---

- `shut`: clear all CDP debt, unlock all collateral, and delete the record

---

<img src="https://user-images.githubusercontent.com/5028/30519068-6c871ed2-9be1-11e7-83df-3cbda6a49e3b.png" width="600" />

- `bite`: liquidate CDP (zeros `art`, decreases `ink`, mints `sin` to `tap`)

Unsafe CDPs need to be liquidated. When a `cup` is not `safe`, anyone
can perform `bite(cup)`, which takes on all CDP debt and confiscates
sufficient collateral to cover this, plus a buffer.

This returns the CDP to a safe state (possibly with zero collateral).
There are other possible implementations of `bite`, e.g. only taking
sufficient collateral to just transition the CDP to safe, but the
described implementation is chosen for simplicity.

`bite` mints the `sin` associated with the CDP to the `tap` - the
liquidator.

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

<img src="https://user-images.githubusercontent.com/5028/30517887-924bec1c-9bc1-11e7-8c25-6d73a1c48340.png" width="500" />

`bust` is really two functions in one: collateral sell off (aka `flip`),
and inflate and sell (aka `flop`). When `fog` is non zero it is sold in
return for Sai, which is used to cancel out the bad debt, `woe`. If
`fog` is zero but the `tap` has a net Sin balance, then SKR is minted
and sold in return for Sai, up to the point that the net Sin balance is
zero.

![Bust](https://user-images.githubusercontent.com/5028/30517888-9287dd76-9bc1-11e7-8726-6b21843e27a5.png)

Through `boom` and `bust` we close the feedback loop on the price of
SKR. When there is surplus Sai, SKR is burned, decreasing the SKR supply
and increasing `per`, giving SKR holders more GEM per SKR. When there is
surplus Woe, SKR is inflated, increasing the SKR supply and decreasing
`per`, giving SKR holders less GEM per SKR.

The reason for wrapping GEM in SKR is now apparent: *it provides a way
to socialise losses and gains incurred in the operation of the system.*

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

A key feature of Sai is the possibility of `cage`: shutting down the
system and reimbursing Sai holders. This is provided for easy upgrades
between Sai iterations, and for security in case of implementation flaws
- both in the code and in the design.

An admin can use the `top` to `cage` the system at a specific price (sai
per gem), or by reading the last price from the price feed.

<img src="https://user-images.githubusercontent.com/5028/30519069-6c9ae656-9be1-11e7-9e3f-e75f585024f7.png" width="600" />

First, sufficient real `gem` collateral is taken such that Sai holders
can redeem their Sai at face value. The `gem` is moved from the `tub` to
the `tap` and the `tap.cash` function is unlocked for Sai holders to
call.

![Cash](https://user-images.githubusercontent.com/5028/30519070-6cc4fd6a-9be1-11e7-92d8-5d965721d8ef.png)

Any remaining `gem` remains in the `tub`. SKR holders can now `exit`.
CDP holders must first `bite` their CDPs (although anyone can do this)
and then `free` their SKR.

Some important features of `cage`:

- Sai holders are not guaranteed their face value, only preferential payout.
- *the full real collateral pool is tapped* to make Sai whole. SKR is a
  *risk-bearing* token.
- SKR holders will receive a poor rate if they try to `exit` before all
  CDPs are processed by `bite`. To prevent accidental early `exit`,
  `top.flow` is provided, which will only enable `exit` after all CDPs
  are processed, or a timeout has expired.

The `top` also serves as a useful frontend entrypoint to the system, as it
links to all other components.

### `drip`, `rum`, `art` and `chi`: Dynamic Fee Accumulation

In a simpler system with no interest rates, we could denominate CDP debt,
the `tab`, directly in `sin`. However with non zero interest, `tab` is a
dynamic quantity, computed from `art`, a rate-normalised per-CDP debt unit,
and `chi`, the product of accumulated rates that converts `art` into a real
debt amount. `rum` is the total `art` across all CDPs, and can be used
to determine the total debt backed by CDPs, `din`.

```
tab(cdp) = cdp.art * chi
```

The internal debt price, `chi`, is dynamic and is updated by the `drip`
act, which also collects unprocessed revenue.

The `chi` abstraction allows us to compute the per CDP debt, and the
total unprocessed revenue, with varying `tax`, in constant time.

<img src="https://user-images.githubusercontent.com/5028/30517890-928d0094-9bc1-11e7-936c-544f5bc4d197.png" width="600" />

## Governance Fee

This version of Sai (aka Dai v1) is collectively governed by the holders of
a token, `gov`. The specifics of the governance mechanism are
out of scope for this document. The `gov` token is also used to pay usage
fees: the `fee` is similar to the `tax`, and causes the `rhi` accumulator to
increase relative to `chi`. The difference between `rhi` and `chi` can be
used to determine the total outstanding fee, the `rap`. Fees are paid on
`wipe`, and the amount payable is scaled with the amount wiped.

Fees are paid in `gov`, but the outstanding fee is denominated in Sai.
Therefore we need a price feed for `gov`: this is the `pep`. The mechanism
in `wipe` is meant to be robust against failure of the `pep` feed.

Importantly, unpaid fees _are not_ used to determine a CDPs safety (this may
change in a future release).


## Auth setup

Sai is designed with two authorities, `dad` and `chief`.

- `dad` is a DSGuard, and is used for internal contract-contract
  permissions, allowing e.g. the `tub` to `mint` and `burn` Sai. `dad`
  is the authority of the `tub` and `tap`, and also `sai`, `sin` and
  `skr`.

- `chief` restricts access to `top` and `mom`, which are the admin
  interfaces to the system. `chief` is intended to be a DSRoles
  instance, but any authority implementation could be used.


## Deployment

Sai is a complex multi-contract system and has a slightly involved
deployment process. The prerequisities to the deployment are:

1. `pip`, a collateral price feed
2. `pep`, a governance price feed
3. `gem`, a collateral token
4. `pit`, a token burner
5. `chief`, the external authority

For testing purposes, `bin/deploy` will create the prerequisites for you
if you don't supply them.

In addition, Sai utilises on-chain deployers, called fabs, for creating
fresh basic components on chain. These are defined in `fab.sol`.

The main contract deployment is defined in `DaiFab`, and requires
multiple calls because of the size of the contracts.

The full contracts can be deployed to e.g.  ethlive with the following,
after which the contract addresses will be saved in `load-env-ethlive`.

```
bin/deploy-fab
. load-fab-ethlive
bin/deploy
```


## Glossary

### Prices

- `per`: gem per skr
- `par`: ref per sai
- `tag`: ref per skr
- `pip`: ref per gem
- `fix`: gem per sai after `cage`
- `fit`: ref per skr after `cage`

### Meme Mnemonics

- `pip`: trading pips
- `cup`: small container for CDP info
- `tub`: larger container for cups
- `tap`: liquidity provider
- `top`: top-level system manager

- `way`: which way the target price is heading
- `cap`: upper limit of Sai issuance
- `mat`: lower limit of collateralisation
- `tax`: continually paid by CDP holders
- `axe`: penalty applied to bad CDP holders
- `gap`: gap between buy and sell

- `pie`: Real collateral that SKR holders share
- `air`: Abstracted Collateral backing CDPs
- `ice`: Debt that is locked up with CDPs
- `fog`: Murky liquidated `air`that we want to get rid of
- `joy`: SKR holders are happy about this Sai surplus
- `woe`: SKR holders are sad about this Sin debt
