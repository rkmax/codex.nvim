.PHONY: test

test:
	@echo "Running tests with plenary.busted..."
	@nvim --headless -u tests/minimal_init.lua "+PlenaryBustedDirectory tests" +qa
