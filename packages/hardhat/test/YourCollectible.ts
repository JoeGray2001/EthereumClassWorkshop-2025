import { expect } from "chai";
import { ethers } from "hardhat";
import { YourCollectible } from "../typechain-types/contracts";
import { YourContract } from "../typechain-types";
import { type HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ContractTransactionReceipt, EventLog } from "ethers";

describe("YourCollectible", function () {
  // We define a fixture to reuse the same setup in every test.
  let yourCollectible: YourCollectible, yourCollectibleAddress: string;
  let yourContract: YourContract, yourContractAddress: string;
  let owner: HardhatEthersSigner, user1: HardhatEthersSigner, user2: HardhatEthersSigner, user3: HardhatEthersSigner;
  let tokenId_0: number;
  before(async () => {
    // Get the Signers object from ethers
    [owner, user1, user2, user3] = await ethers.getSigners();

    const yourCollectibleFactory = await ethers.getContractFactory("YourCollectible");
    yourCollectible = (await yourCollectibleFactory.deploy()) as YourCollectible;

    await yourCollectible.waitForDeployment();
    yourCollectibleAddress = await yourCollectible.getAddress();

    const yourContractFactory = await ethers.getContractFactory("YourContract");
    yourContract = (await yourContractFactory.deploy(owner.address)) as YourContract;

    await yourContract.waitForDeployment();
    yourContractAddress = await yourContract.getAddress();
  });

  describe("Deployment", function () {
    it("Should have the right owner on deploy", async function () {
      expect(await yourCollectible.owner()).to.equal(owner.address);
    });
  });

  describe("Mint token", function () {
    it("Should allow minting to an externally owned account EOA", async function () {
      // user1 is minting a token for user2
      const txn = await yourCollectible.connect(user1).mintItem(user2.address, "https://www.example.com/nft1");

      // Unlike view functions, transactions do not return values directly because they need to be mined on the blockchain
      // Instead we'll retrieve the event emitted by the transaction. It is included in the transaction receipts.
      const receipt = await txn.wait();
      const transferEventLog = receipt!.logs.find(l => (l as EventLog).fragment.name === "Transfer") as EventLog;
      const iface = new ethers.Interface([
        "event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)",
      ]);
      const decodedLog = iface.decodeEventLog("Transfer", transferEventLog.data, transferEventLog.topics);

      tokenId_0 = decodedLog.tokenId as number;

      // get the owner of the token
      expect(await yourCollectible.connect(user1).ownerOf(tokenId_0)).to.equal(user2.address);
      expect(await yourCollectible.connect(user1).balanceOf(user2.address)).to.equal(1);
    });

    it("Should not allow minting to contract address without implementing IERC721Receiver", async function () {
      await expect(yourCollectible.connect(user1).mintItem(yourContractAddress, "https://www.example.com/nft1")).to.be
        .reverted;
    });
  });

  describe("Transfer", function () {
    it("Should not allow transfer from non-owner user1", async function () {
      // TODO: write a test to check that user 1 cannot transfer the token they created for user 2
      
      await expect(yourCollectible.connect(user1).transferFrom(user2.address, user3.address, tokenID_0)).to.be.reverted;
    });

    it("Should allow transfer from non-owner user1 after approving them", async function () {
      // TODO: call yourCollectible SM and have user 2 to approve/authorize user 1 to transfer the token on their behalf
      await yourCollectible.connect(user2).approve(user1.address, tokenId_0);

      // TODO: call yourCollectibe and have user 1 transfer user 2 token to user 3
      await yourCollectible.connect(user1).transferFrom(user2.address, user3.address, tokenId_0);

      // TODO: write a test to check that the owner of the token is currently user 3
      expect(yourCollectible.connect(user1).ownerOf(tokenId_0)).to.equal(user3.address);

      // TODO: write a test to check that user 2 has no token that they own
      expect(await yourCollectible.connect(user1).balanceOf(user2.address)).to.equal(0);
    });
  });
});
