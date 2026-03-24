.PHONY: test lint format

PLENARY_DIR := $(shell find ~/.local/share/nvim/lazy -maxdepth 1 -name "plenary.nvim" 2>/dev/null | head -1)

test:
ifeq ($(PLENARY_DIR),)
	$(error plenary.nvim not found. Install it first.)
endif
	nvim --headless \
		--noplugin \
		-u tests/minimal_init.lua \
		--cmd "set rtp+=$(PLENARY_DIR)" \
		-c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

lint:
	luacheck lua/ tests/ --globals vim describe it before_each after_each assert

format:
	stylua lua/ tests/ plugin/
