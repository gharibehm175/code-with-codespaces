// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NexaVerse (NXV) with minimal 1.5% tax, auto-owner share, manual override, pause
contract NexaVerse is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10**18; // 1 billion NXV
    uint256 public taxRate = 15;    // 1.5% (15 / 1000)
    address public taxWallet;       // where collected fee goes
    bool    public paused = false;  // emergency stop

    event TaxRateUpdated(uint256 oldRate, uint256 newRate);
    event TaxWalletUpdated(address oldWallet, address newWallet);
    event Paused();
    event Unpaused();

    constructor(address _taxWallet) ERC20("NexaVerse", "NXV") {
        require(_taxWallet != address(0), "Tax wallet zero");
        _mint(msg.sender, INITIAL_SUPPLY);
        taxWallet = _taxWallet;
    }

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    function setTaxRate(uint256 _permille) external onlyOwner {
        require(_permille <= 50, "Max 5%");         // ceiling 5%
        emit TaxRateUpdated(taxRate, _permille);
        taxRate = _permille;
    }

    function setTaxWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Zero addr");
        emit TaxWalletUpdated(taxWallet, _wallet);
        taxWallet = _wallet;
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    function _transfer(address from, address to, uint256 amount) internal override whenNotPaused {
        uint256 fee = amount * taxRate / 1000;
        uint256 net = amount - fee;
        super._transfer(from, taxWallet, fee);
        super._transfer(from, to, net);
    }

    /// @notice manual owner withdrawal of any ERC20
    function rescueERC20(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }
}
