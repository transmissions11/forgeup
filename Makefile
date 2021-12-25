
version  = $(shell awk -F '=' '/^FOUNDRY_VERSION/{print $$2}' $(CURDIR)/bin/forgeup)
prefix   = $(HOME)/.foundry
programs = $(prefix)/programs
home     = $(programs)/foundry-$(version)

TEST_DIR=$(CURDIR)/test

.PHONY: test install uninstall

test:
	@echo "integration tests..."
	( cd $(TEST_DIR); $(TEST_DIR)/integration_tests.sh )
	@echo "unit tests..."
	( cd $(TEST_DIR); $(TEST_DIR)/unit_test_configure_environment.sh )
	( cd $(TEST_DIR); $(TEST_DIR)/unit_test_utilities.sh )
	( cd $(TEST_DIR); $(TEST_DIR)/unit_test_list_plugins.sh )
	( cd $(TEST_DIR); $(TEST_DIR)/unit_test_show_program.sh )
	( cd $(TEST_DIR); $(TEST_DIR)/unit_test_use_program.sh )
	( cd $(TEST_DIR); $(TEST_DIR)/unit_test_install_program.sh )
	( cd $(TEST_DIR); $(TEST_DIR)/unit_test_uninstall_program.sh )

install: uninstall
	install -m 0755 -d $(prefix)
	install -m 0755 -d $(home)/bin
	install -m 0755 -d $(home)/install
	install -m 0755 -d $(home)/plugins

	install -m 0644 $(CURDIR)/bin/libfoundry $(home)/bin
	install -m 0755 $(CURDIR)/bin/foundry $(home)/bin
	install -m 0755 $(CURDIR)/install/profile $(home)/install
	install -m 0644 $(CURDIR)/plugins/* $(home)/plugins
	install -m 0644 $(CURDIR)/README.md $(home)
	install -m 0644 $(CURDIR)/Changelog.md $(home)
	install -m 0644 $(CURDIR)/Roadmap.md $(home)
	install -m 0644 $(CURDIR)/LICENSE $(home)
	ln -s $(home) $(programs)/foundry
	ln -s $(programs)/foundry/install/profile $(prefix)/profile

uninstall:
	rm -f $(prefix)/profile
	rm -rf $(programs)/foundry*