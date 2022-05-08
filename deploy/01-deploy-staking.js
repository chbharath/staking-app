module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const  rewardToken  = await ethers.getContract("RewardToken")
    
    const stakingDeployment = await deploy("Staking", {
        from: deployer,
        args: [rewardToken.address, rewardToken.address],
        log: true,
    })

}

module.exports.tags = ["all", "stakingToken"]
