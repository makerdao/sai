// exec.sol - base contract used by anything that wants to do "untyped" calls

// Copyright (C) 2017  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

contract DSExec {
    function tryExec( address target, bytes memory data, uint value)
             internal
             returns (bool ok)
    {
        assembly {
            ok := call(gas(), target, value, add(data, 0x20), mload(data), 0, 0)
        }
    }
    function exec( address target, bytes memory data, uint value)
             internal
    {
        if(!tryExec(target, data, value)) {
            revert("ds-exec-call-failed");
        }
    }

    // Convenience aliases
    function exec( address t, bytes memory c )
        internal
    {
        exec(t, c, 0);
    }
    function exec( address t, uint256 v )
        internal
    {
        bytes memory c; exec(t, c, v);
    }
    function tryExec( address t, bytes memory c )
        internal
        returns (bool)
    {
        return tryExec(t, c, 0);
    }
    function tryExec( address t, uint256 v )
        internal
        returns (bool)
    {
        bytes memory c; return tryExec(t, c, v);
    }
}