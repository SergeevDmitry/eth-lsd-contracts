// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

interface IUpgrade {
    function reinit() external;

    function version() external returns (uint8);
}
