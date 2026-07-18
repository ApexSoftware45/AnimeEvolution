-- ReplicatedStorage/Shared/CashBundleProducts.luau
-- Shared definitions for Robux cash bundles (Developer Products).
-- Update the developerProductId values after creating products in the Creator Dashboard.

export type CashBundleDefinition = {
	developerProductId: number?,
	alias: string?,
	displayName: string,
	priceInRobux: number,
	cashAmount: number,
	description: string?,
}

local bundles: { CashBundleDefinition } = {
	{
		developerProductId = 3450930462,
		alias = "5m",
		displayName = "Cash Bundle (5M)",
		priceInRobux = 499,
		cashAmount = 5_000_000,
		description = "Instantly grants 5,000,000 cash.",
	},
	{
		developerProductId = 3450931708,
		alias = "12m",
		displayName = "Cash Bundle (12M)",
		priceInRobux = 999,
		cashAmount = 12_000_000,
		description = "Instantly grants 12,000,000 cash.",
	},
	{
		developerProductId = 3450934131,
		alias = "28m",
		displayName = "Cash Bundle (28M)",
		priceInRobux = 1_999,
		cashAmount = 28_000_000,
		description = "Instantly grants 28,000,000 cash.",
	},
}

return bundles
