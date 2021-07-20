// spell.sol - An un-owned object that performs one action one time only

// Copyright (C) 2017, 2018 DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import "../ds-exec/exec.sol";
import "../ds-note/note.sol";

contract DSSpell is DSExec, DSNote {
    address public whom;
    uint256 public mana;
    bytes   public data;
    bool    public done;

    constructor(address whom_, uint256 mana_, bytes memory data_) public {
        whom = whom_;
        mana = mana_;
        data = data_;
    }
    // Only marked 'done' if CALL succeeds (not exceptional condition).
    function cast() public note {
        require(!done, "ds-spell-already-cast");
        exec(whom, data, mana);
        done = true;
    }
}

contract DSSpellBook {
    function make(address whom, uint256 mana, bytes memory data) public returns (DSSpell) {
        return new DSSpell(whom, mana, data);
    }
}