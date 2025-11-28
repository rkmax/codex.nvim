.PHONY: test

test:
	@echo "Running tests with plenary.busted..."
	@nvim --headless -c "lua require('plenary.busted').runner({path='tests', seed=123, sequential=true, minimal_init = 'tests/minimal_init.lua'})" +qa
