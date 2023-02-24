pragma solidity ^0.5.0;

import "./SFC.sol";
import "../erc20/base/ERC20Burnable.sol";
import "../erc20/base/ERC20Mintable.sol";
import "../common/Initializable.sol";

contract Spacer {
    address private _owner;
}

contract StakeTokenizer is Spacer, Initializable {
    SFC internal sfc;

    mapping(address => mapping(uint256 => uint256)) public outstandingSTREE;

    address public sTREETokenAddress;

    function initialize(address _sfc, address _sTREETokenAddress) public initializer {
        sfc = SFC(_sfc);
        sTREETokenAddress = _sTREETokenAddress;
    }

    function mintSTREE(uint256 toValidatorID) external {
        address delegator = msg.sender;
        uint256 lockedStake = sfc.getLockedStake(delegator, toValidatorID);
        require(lockedStake > 0, "delegation isn't locked up");
        require(lockedStake > outstandingSTREE[delegator][toValidatorID], "sTREE is already minted");

        uint256 diff = lockedStake - outstandingSTREE[delegator][toValidatorID];
        outstandingSTREE[delegator][toValidatorID] = lockedStake;

        // It's important that we mint after updating outstandingSTREE (protection against Re-Entrancy)
        require(ERC20Mintable(sTREETokenAddress).mint(delegator, diff), "failed to mint sTREE");
    }

    function redeemSTREE(uint256 validatorID, uint256 amount) external {
        require(outstandingSTREE[msg.sender][validatorID] >= amount, "low outstanding sTREE balance");
        require(IERC20(sTREETokenAddress).allowance(msg.sender, address(this)) >= amount, "insufficient allowance");
        outstandingSTREE[msg.sender][validatorID] -= amount;

        // It's important that we burn after updating outstandingSTREE (protection against Re-Entrancy)
        ERC20Burnable(sTREETokenAddress).burnFrom(msg.sender, amount);
    }

    function allowedToWithdrawStake(address sender, uint256 validatorID) public view returns(bool) {
        return outstandingSTREE[sender][validatorID] == 0;
    }
}
