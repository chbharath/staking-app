// stake: Lock tokens into our smart contract ✅
// withdraw: unlock tokens and pull out of the contract ✅
// clainRewards: users get their reward tokens
//  What's a good reward mechanism?
//  What's some good reward math?

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();
error Staking__NeedsMoreThanZero();

contract Staking {

    IERC20 public s_stakingToken;
    IERC20 public s_rewardToken;


    // someones address -> how much they staked
    mapping(address => uint256) public s_balances;

    // a mapping of how much each address has to claim
    mapping(address => uint256) public s_userRewardPerTokenPaid;

    // a mapping of how much rewards each address has been paid
    mapping(address => uint256) public s_rewards;

    uint256 public constant REWARD_RATE = 100;
    uint256 public s_totalSupply;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdateTime;

    modifier updateReward(address account){
        // how much the reward per token?
        // last timestamp
        // 12 - 1, user earned X tokens
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        _;
    }

    modifier moreThanZero(uint256 amount){
        if(amount == 0) {
            revert Staking__NeedsMoreThanZero();
        }
        _;
    }

    constructor(address stakingToken, address rewardToken){
        s_stakingToken = IERC20(stakingToken);
        s_rewardToken = IERC20(rewardToken);
    }

    function earned(address account) public view returns (uint256){
        uint256 currentBalance = s_balances[account];
        // how much they have been paid already
        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];

        uint256 _earned = ((currentBalance * (currentRewardPerToken - amountPaid)) / 1e18) + pastRewards;

        return _earned;

    }
    // Based on how long it's been during this most recent snapshot
    function rewardPerToken() public view returns(uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        }
        return s_rewardPerTokenStored + (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18)/ s_totalSupply);

    }

    //do we allow any token? - not allow any token.
    //            Chainlink stuff to convert prices between tokens.*****
    //or just a specific token? Yes✅
    function stake(uint256 amount) external updateReward(msg.sender) moreThanZero(amount) {
        // keep track of  how much this user has staked
        // keep track of how much token we have total
        // transfer the tokens to this contract
        s_balances[msg.sender] = s_balances[msg.sender] + amount;
        s_totalSupply = s_totalSupply + amount;
        // emit event
        bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
        // require(success, "Failed");
        if(!success) {
            revert Staking__TransferFailed();
        }
    }

    function withdraw(uint256 amount) external updateReward(msg.sender) moreThanZero(amount) {
        s_balances[msg.sender] = s_balances[msg.sender] - amount;
        s_totalSupply = s_totalSupply - amount;
        bool success = s_stakingToken.transfer(msg.sender, amount);
        if (!success)  {
            revert Staking__TransferFailed();
        }
    }

    function claimReward() external updateReward(msg.sender) {
        uint256 reward = s_rewards[msg.sender];
        bool success = s_rewardToken.transfer(msg.sender, reward);
        if(!success) {
            revert Staking__TransferFailed();
        }
        // How much reward do they get?

        // The contract is going to emit X tokens per second
        // And disperse them to all tokens stakers

        // 100 tokens / second 
        // staked  :  50 staked tokens, 20 staked tokens, 30 staked tokens
        // rewards :  50 reward tokens, 20 reward tokens, 30 reward tokens

        // staked: 100, 50, 20 , 30  (total: 200)
        // rewards: 50, 25, 10 15

        // why not 1 to 1? - bankrupt your protocol

        // 5 seconds, 1 person had 100 token staked = reward 500 tokens
        // 6 seconds, 2 person have 100 tokens staked each:
        //    Person 1: 550
        //    Person 2: 50
        // ok between seconds 1 and 5, person 1 got 500 tokens
        // ok at second 6 on, person 1 gets 50 tokens now

        // 100 tokens /second
        // 1 token / staked token

        // Time = 0
        // Person A: 80 staked,
        // Person B: 20 staked,

        // Time = 1
        // PA : 80 staked, Earned: 80, Withdrawn: 0
        // PB : 20 staked, earned:20, withdrawn: 0

        // Time = 2
        // PA : 80 staked, Earned: 160, Withdrawn: 0
        // PB : 20 staked, earned: 40, withdrawn: 0

        // Time = 3
        // PA : 80 staked, Earned: 240, Withdrawn: 0
        // PB : 20 staked, earned: 60, withdrawn: 0

        // New person enters
        // Stake 100
        // total tokens staked = 200 
        // 0.5 tokens / staked token

        // Time = 3
        // PA: 80 staked, earned : 240 + 40, withdrawn : 0
        // PB: 20 staked, earned : 60 + 10, withdrawn : 0
        // PC: 100 staked, earned : 50, withdrawn : 0 

        // PA withdrew & claimed rewards on everything
        //
        // Time = 4
        // PA: 0 staked, earned : 0, withdrawn : 280
        


    }


}

