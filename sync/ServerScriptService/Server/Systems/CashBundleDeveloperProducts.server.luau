-- ServerScriptService/Systems/CashBundleDeveloperProducts.server.luau
-- Handles Robux developer product purchases that grant cash bundles.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local cashBundles = require(SharedFolder:WaitForChild("CashBundleProducts"))
type CashBundleDefinition = typeof(cashBundles[1])

type ReceiptInfo = {
	PlayerId: number,
	ProductId: number,
	PurchaseId: string,
	PlaceIdWherePurchased: number,
	CurrencySpent: number,
}

local bundlesByProductId: {[number]: CashBundleDefinition} = {}
local bundlesByAlias: {[string]: CashBundleDefinition} = {}

for _, def in ipairs(cashBundles) do
	if typeof(def.alias) == "string" then
		bundlesByAlias[string.lower(def.alias)] = def
	end

	if typeof(def.developerProductId) == "number" and def.developerProductId > 0 then
		if bundlesByProductId[def.developerProductId] then
			warn(string.format("[CashBundleProducts] Duplicate product id %d detected; only the first definition will be used.", def.developerProductId))
		else
			bundlesByProductId[def.developerProductId] = def
		end
	else
		warn(string.format("[CashBundleProducts] DeveloperProductId missing for %s. Update Shared/CashBundleProducts with the published product ids.", def.displayName))
	end
end

local function resolveDefinition(identifier: number | string | CashBundleDefinition?)
	if typeof(identifier) == "table" then
		return identifier
	end

	if typeof(identifier) == "number" then
		return bundlesByProductId[identifier]
	end

	if typeof(identifier) == "string" then
		return bundlesByAlias[string.lower(identifier)]
	end

	return nil
end

local function awardCash(player: Player, def: CashBundleDefinition, source: string?)
	if not player or not def then
		return false
	end

	local amount = tonumber(def.cashAmount) or 0
	if amount <= 0 then
		warn(string.format("[CashBundleProducts] %s has no cash amount configured.", def.displayName))
		return false
	end

	local addMoney = _G.addMoney or _G.addPlayerCash
	if typeof(addMoney) ~= "function" then
		warn("[CashBundleProducts] _G.addMoney helper is missing; ensure CashSystem loads before this script.")
		return false
	end

	local reason = source or string.format("RobuxCashBundle:%s", def.displayName)
	addMoney(player, amount, reason, false)
	print(string.format("[CashBundleProducts] Granted %d cash to %s (%s)", amount, player.Name, def.displayName))
	return true
end

local function processReceipt(receiptInfo: ReceiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local def = bundlesByProductId[receiptInfo.ProductId]
	if not def then
		warn(string.format("[CashBundleProducts] No handler configured for product %d. Purchase was completed with no reward.", receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local ok = awardCash(player, def, "DeveloperProductPurchase")
	if not ok then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.ProcessReceipt = processReceipt

print(string.format("[CashBundleProducts] Ready (bundles configured: %d)", #cashBundles))
