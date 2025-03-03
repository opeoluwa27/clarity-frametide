// [Previous test imports and basic tests remain unchanged]

Clarinet.test({
    name: "Rate limiting prevents rapid actions",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get("wallet_1")!;
        
        let block = chain.mineBlock([
            Tx.contractCall("photo_album", "add-photo", [
                types.uint(1),
                types.ascii("QmHash123"),
                types.ascii("Beach sunset")
            ], wallet_1.address),
            Tx.contractCall("photo_album", "add-photo", [
                types.uint(1),
                types.ascii("QmHash124"),
                types.ascii("Mountain view")
            ], wallet_1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectErr(108); // ERR_RATE_LIMIT_EXCEEDED
    }
});

// [Additional tests for new functionality]
