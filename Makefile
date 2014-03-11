SOURCE_VERSION = 1.7
JFLAGS ?= -g:source,lines,vars -encoding utf8
PROCESSOR_PATH = $(BUILD_DIR)/net.aeten.core
TOUCH_DIR = .touch
DIST ?= JAR

all: src test

# Sources
SRC = jcip.annotations core alert stream messenger messenger.stream parsing.properties parsing.xml parsing.yaml
src: $(SRC)
jcip.annotations::
core::               jcip.annotations
alert::              core
stream::             core
messenger::          core
messenger.stream::   messenger stream
parsing.properties:: core
parsing.xml::        core
parsing.yaml::       core

# Tests
TEST = messenger.test parsing.test stream.test spi.test
test: $(TEST)
messenger.test:: messenger.stream parsing.yaml;               $(RUN_TEST)
parsing.test::   parsing.properties parsing.xml parsing.yaml; $(RUN_TEST)
stream.test::    stream;                                      $(RUN_TEST)
spi.test::       core;                                        $(RUN_TEST)

clean:
	$(RM) -rf $(BUILD_DIR) $(DIST_DIR) $(GENERATED_DIR) $(TOUCH_DIR)

# TODO
define RUN_TEST
@echo Run test $@
endef


SRC_DIRS = src/ test/
MODULES = $(SRC) $(TEST)
-include java.mk

