// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Farm distributes the ERC20 rewards based on staked LP to each user.
//
// Cloned from https://github.com/SashimiProject/sashimiswap/blob/master/contracts/MasterChef.sol
// Modified by DEOR to work for non-mintable ERC20.
contract Farm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ERC20s
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accERC20PerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accERC20PerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.

        //uint256 금액; // 사용자가 제공한 LP 토큰 수.
        //uint256 보상 부채; // 부채를 보상합니다. 아래 설명을 참조하십시오.
        //
        // 우리는 여기서 멋진 수학을 합니다. 기본적으로 어느 시점에서든 ERC20의 양은
        // 사용자에게 권한이 있지만 배포 대기 중인 경우:
        //
        // 보류 중인 보상 = (user.amount * pool.accERC20PerShare) - user.rewardDebt
        //
        // 사용자가 풀에 LP 토큰을 입금하거나 출금할 때마다. 다음은 발생합니다.
        // 1. 풀의 `accERC20PerShare`(및 `lastRewardBlock`)가 업데이트됩니다.
        // 2. 사용자는 자신의 주소로 전송된 보류 보상을 받습니다.
        // 3. 사용자의 '금액'이 업데이트됩니다.
        // 4. 사용자의 `rewardDebt`가 업데이트됩니다.

    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. ERC20s to distribute per block.
        uint256 lastRewardBlock;    // Last block number that ERC20s distribution occurs.
        uint256 accERC20PerShare;   // Accumulated ERC20s per share, times 1e36.
        // IERC20 lpToken; // LP 토큰 계약의 주소입니다.
        // uint256 할당점; // 이 풀에 할당된 할당 포인트 수. 블록당 배포할 ERC20.
        // uint256 lastRewardBlock; // ERC20s 배포가 발생한 마지막 블록 번호입니다.
        // uint256 accERC20PerShare; // 주당 누적 ERC20, 곱하기 1e36.
    }

    // Address of the ERC20 Token contract.
    IERC20 public erc20;
    // The total amount of ERC20 that's paid out as reward.
    uint256 public paidOut = 0;
    // ERC20 tokens rewarded per block.
    uint256 public rewardPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The block number when farming starts.
    uint256 public startBlock;
    // The block number when farming ends.
    uint256 public endBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(IERC20 _erc20, uint256 _rewardPerBlock, uint256 _startBlock) public {
        erc20 = _erc20;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _startBlock;
    }

    // Number of LP pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Fund the farm, increase the end block
    function fund(uint256 _amount) public {
        require(block.number < endBlock, "fund: too late, the farm is closed");

        erc20.safeTransferFrom(address(msg.sender), address(this), _amount);
        endBlock += _amount.div(rewardPerBlock);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    //동일한 LP 토큰을 두 번 이상 추가하지 마십시오. 그렇게하면 보상이 엉망이 될 것입니다.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accERC20PerShare: 0
        }));
    }

    // Update the given pool's ERC20 allocation point. Can only be called by the owner.
    //지정된 풀의 ERC20 할당 지점을 업데이트합니다. 소유자만 호출할 수 있습니다.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // View function to see deposited LP for a user. //사용자에게 예치된 LP를 조회하는 기능
    function deposited(uint256 _pid, address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.amount;
    }

    // View function to see pending ERC20s for a user.
    function pending(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accERC20PerShare = pool.accERC20PerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 lastBlock = block.number < endBlock ? block.number : endBlock;
            uint256 nrOfBlocks = lastBlock.sub(pool.lastRewardBlock);
            uint256 erc20Reward = nrOfBlocks.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accERC20PerShare = accERC20PerShare.add(erc20Reward.mul(1e36).div(lpSupply));
        }

        return user.amount.mul(accERC20PerShare).div(1e36).sub(user.rewardDebt);
    }

    // View function for total reward the farm has yet to pay out.//농장에서 아직 지불하지 않은 총 보상 보기 기능입니다.
    function totalPending() external view returns (uint256) {
        if (block.number <= startBlock) {
            return 0;
        }

        uint256 lastBlock = block.number < endBlock ? block.number : endBlock;
        return rewardPerBlock.mul(lastBlock - startBlock).sub(paidOut);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    // 모든 풀에 대한 보상 변수를 업데이트합니다. 가스 소비를 조심하십시오!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    //주어진 풀의 보상 변수를 최신으로 업데이트합니다.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lastBlock = block.number < endBlock ? block.number : endBlock;

        if (lastBlock <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = lastBlock;
            return;
        }

        uint256 nrOfBlocks = lastBlock.sub(pool.lastRewardBlock);
        uint256 erc20Reward = nrOfBlocks.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        pool.accERC20PerShare = pool.accERC20PerShare.add(erc20Reward.mul(1e36).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to Farm for ERC20 allocation. //ERC20 할당을 위해 Farm에 LP 토큰을 예치합니다.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(pool.accERC20PerShare).div(1e36).sub(user.rewardDebt);
            erc20Transfer(msg.sender, pendingAmount);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from Farm.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: can't withdraw more than deposit");
        updatePool(_pid);
        uint256 pendingAmount = user.amount.mul(pool.accERC20PerShare).div(1e36).sub(user.rewardDebt);
        erc20Transfer(msg.sender, pendingAmount);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY. //보상에 신경 쓰지 않고 Withdraw하십시오. 비상시에만.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Transfer ERC20 and update the required ERC20 to payout all rewards
    //ERC20을 전송하고 필요한 ERC20을 업데이트하여 모든 보상을 지급합니다.
    function erc20Transfer(address _to, uint256 _amount) internal {
        erc20.transfer(_to, _amount);
        paidOut += _amount;
    }
}
