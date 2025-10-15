Here’s a **GitHub-ready `README.md`** — clean markdown, with emojis, code blocks, headings, and section formatting designed for a repository page:

---

# 🕵️‍♂️ Scavenger Hunt NFT

### A fully on-chain scavenger hunt game built in Solidity

Players solve clues, submit answers, and earn **NFT rewards** for correct submissions.
This contract is **self-contained**, has **no imports**, and uses **no constructor** — designed for simplicity and transparency.

---

## 🌐 Overview

**ScavengerHuntNFT** is a lightweight smart contract that allows a game master (owner) to:

* Create scavenger hunt challenges with clues and hashed answers.
* Let players submit answers on-chain.
* Automatically mint **unique NFTs** to winners.

All logic — from clue management to NFT minting — happens inside a single Solidity file.

---

## ✨ Features

| Feature                      | Description                                                    |
| ---------------------------- | -------------------------------------------------------------- |
| 🧩 **Create Hunts**          | Owner can create multiple hunts with clues and hashed answers. |
| 🔒 **Hash-Based Validation** | Answers are verified using keccak256 hashes.                   |
| 🏆 **NFT Rewards**           | Correct solvers automatically receive minted NFTs.             |
| 👑 **Owner Controls**        | Owner can open/close hunts, and manage token URIs.             |
| ⚡ **Lightweight Design**     | No external libraries or imports (no OpenZeppelin).            |
| 🧱 **Initialize Function**   | Uses `initialize()` instead of a constructor.                  |

---

## 🧠 Contract Details

**File:** `ScavengerHuntNFT.sol`
**Language:** Solidity `^0.8.20`
**License:** MIT

---

### 📜 Core Functions

#### 🔹 Initialize (One-Time Setup)

```solidity
function initialize() external;
```

Sets the deployer as the contract owner. Must be called once after deployment.

---

#### 🔹 Create Hunt

```solidity
function createHunt(string memory clue, bytes32 answerHash, uint256 maxRewards) external onlyOwner;
```

* `clue`: The question or hint for participants.
* `answerHash`: `keccak256(abi.encodePacked(correctAnswer))`
* `maxRewards`: Limit on how many NFTs can be minted (0 = unlimited).

---

#### 🔹 Submit Answer

```solidity
function submitAnswer(uint256 huntId, string memory answer) external returns (uint256);
```

Players call this with their guessed answer.
If the hash matches, the player is rewarded with an NFT.

---

#### 🔹 Close Hunt

```solidity
function closeHunt(uint256 huntId) external onlyOwner;
```

Disables a hunt so no more answers can be accepted.

---

#### 🔹 Set Token Metadata

```solidity
function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner;
```

Allows the owner to assign custom metadata for each NFT.

---

## 🧩 Example Workflow

### 1️⃣ Deploy Contract

Deploy `ScavengerHuntNFT.sol` using **Remix**, **Hardhat**, or any EVM environment.

### 2️⃣ Initialize Owner

Call:

```solidity
initialize()
```

This makes the deployer the owner.

### 3️⃣ Create a Hunt

First, hash the correct answer:

```js
keccak256(abi.encodePacked("piano"))
```

Then call:

```solidity
createHunt("I have keys but no locks. What am I?", 0xHASHVALUE, 10)
```

### 4️⃣ Player Submits Answer

```solidity
submitAnswer(0, "piano")
```

If correct → NFT minted automatically.

### 5️⃣ Check Ownership

```solidity
balanceOf(playerAddress)
ownerOf(tokenId)
tokenURI(tokenId)
```

---

## 🧮 Generate Answer Hash

### JavaScript

```js
import { keccak256, toUtf8Bytes } from "ethers";
console.log(keccak256(toUtf8Bytes("piano")));
```

### Python

```python
import hashlib
print(hashlib.sha3_256("piano".encode()).hexdigest())
```

---

## 🧪 Testing Scenarios

| Scenario               | Expected Outcome                    |
| ---------------------- | ----------------------------------- |
| ✅ Correct Answer       | Player receives NFT reward          |
| ❌ Wrong Answer         | Transaction reverts: "wrong answer" |
| 🔁 Already Claimed     | Reverts: "already claimed"          |
| 📴 Hunt Closed         | Reverts: "hunt inactive"            |
| 🚫 Max Rewards Reached | Reverts: "max rewards reached"      |

---

## 🧰 Development & Deployment

**Requirements**

* Solidity ^0.8.20
* Remix, Hardhat, or Foundry
* Any EVM-compatible network (Ethereum, Polygon, BSC, etc.)

**Recommended Steps**

1. Copy contract into Remix.
2. Compile with Solidity 0.8.20 or higher.
3. Deploy.
4. Call `initialize()` once.
5. Start creating hunts and rewarding players!

---

## ⚠️ Notes

* This contract uses a **minimal ERC-721-like implementation** (no OpenZeppelin).
* For production, consider:

  * Verified ERC-721 standards (OpenZeppelin).
  * Rate limits and attempt counters.
  * Off-chain metadata (IPFS, Arweave).

---

## 🪙 License

**MIT License**
Free to use, modify, and experiment with.

---

## 💬 Author

Created with ❤️ by [Your Name]
Feel free to fork, improve, and extend the contract.

---

Would you like me to include a **GitHub-style badge section** (for Solidity version, license, and network compatibility) at the top? It makes the README look more professional on the repo page.
# ScavengerHuntNFT-
