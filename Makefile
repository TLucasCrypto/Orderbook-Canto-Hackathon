-include .env

.PHONY: forge script test anvil snapshot

# deploy-test-engine:
# 	forge script script/DeployForTest.s.sol:DeployForTest --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --fork-url localhost -vvvv --optimize --broadcast

deploy-orderbook:
	forge script script/Deploy.s.sol:Deploy --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --fork-url localhost -vvvv --optimize --broadcast