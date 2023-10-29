## README

### 執行說明

```bash
git clone https://github.com/tannerang/USDCRugPullTest.git
```

```bash
cd USDCRugPullTest
```

```bash
forge test 
```

```bash
# foundry.toml config changes as follow
auto_detect_solc = true
```

### 測試個案說明

```
testUpgradeToV3
    說明：
        測試 UpgradeTo 是否成功升級

testAddWhitelist
    說明：
        測試 whitelistOwner 可以將任意 user 加入 whitelist，其他角色則無法

testCanTransferIfInWhitelist
    說明：
        測試被加入 whitelist 的 user 可以成功執行 transfer 

testCannotTransferIfNotInWhitelist
    說明：
        測試沒有被加入 whitelist 的 user 不能執行 transfer 

testCanMintInfinitelyIfInWhitelist
    說明：
        測試被加入 whitelist 的 user 可以無限制的 mint USDC token

(自行增加)testRugBlacklistedAccountIfIsBlacklister
    說明：
        測試 Blacklister 角色可以對指定 BlacklistedAccount 執行 rugBlacklist，將其全部的 USDC 轉到 Blacklister 手上

(自行增加)testCannotRugBlacklistedAccountIfNotBlacklister
    說明：
        測試非 Blacklister 角色無法對指定 BlacklistedAccount 執行 rugBlacklist
```