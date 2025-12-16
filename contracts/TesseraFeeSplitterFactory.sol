// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TesseraFeeSplitter.sol";

contract TesseraFeeSplitterFactory {
    event SplitterCreated(address indexed creator, address splitter);

    /**
     * @notice Deploys a new FeeSplitter contract.
     * @param token Address of the ERC20 token (e.g., USDC).
     * @param publisher Recipient of 89% (or custom) of the funds.
     * @param devs Recipient of 11% (or custom) of the funds.
     * @param publisherBps Percentage (basis points) for publisher.
     * @param devsBps Percentage (basis points) for devs.
     *
     * @return splitter Address of deployed FeeSplitter contract.
     */
    function createSplitter(
        address token,
        address publisher,
        address devs,
        uint16 publisherBps,
        uint16 devsBps
    ) external returns (address splitter) {
        splitter = address(
            new TesseraFeeSplitter(
                token,
                publisher,
                devs,
                publisherBps,
                devsBps,
                msg.sender      // caller becomes the admin of the splitter
            )
        );

        emit SplitterCreated(msg.sender, splitter);
    }
}
