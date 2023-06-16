
async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("获取部署钱包地址:",await deployer.getAddress());
    console.log("获取部署钱包地址余额:", (await deployer.getBalance()).toString());
    //指定合约工程要部署的名称
    const Token = await ethers.getContractFactory("TreasuryDistribution");
    const token = await Token.deploy();
    await token.deployed();

    console.log("部署后合约地址:", token.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
