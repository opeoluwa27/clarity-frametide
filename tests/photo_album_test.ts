// [Previous test imports and basic tests remain unchanged]

Clarinet.test({
    name: "Cannot like same photo twice",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get("wallet_1")!;
        
        let block = chain.mineBlock([
            Tx.contractCall("photo_album", "create-album", [
                types.ascii("My Vacation"),
                types.ascii("Summer 2023 photos"),
                types.bool(true)
            ], wallet_1.address),
            Tx.contractCall("photo_album", "add-photo", [
                types.uint(1),
                types.ascii("QmHash123"),
                types.ascii("Beach sunset")
            ], wallet_1.address),
            Tx.contractCall("photo_album", "like-photo", [
                types.uint(1),
                types.uint(1)
            ], wallet_1.address),
            Tx.contractCall("photo_album", "like-photo", [
                types.uint(1),
                types.uint(1)
            ], wallet_1.address)
        ]);
        
        block.receipts[2].result.expectOk();
        block.receipts[3].result.expectErr(106); // ERR_ALREADY_LIKED
    }
});

// [Additional tests for new functionality]
