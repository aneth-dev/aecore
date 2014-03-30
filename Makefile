SOURCE_VERSION = 1.7
JFLAGS ?= -g:source,lines,vars -encoding utf8
PROCESSOR_FACTORIES_MODULES ?= net.aeten.core
TOUCH_DIR = .touch


all: compile jar eclipse src test

# Sources
SRC = core alert stream messenger messenger.stream parsing.properties parsing.xml parsing.yaml gui gui.swing
src: $(SRC)
core::               jcip.annotations slf4j
alert::              core
stream::             core slf4j
messenger::          core slf4j
messenger.stream::   messenger stream slf4j
parsing.properties:: core slf4j
parsing.xml::        core
parsing.yaml::       core
gui::
gui.swing::          gui

# COTS
COTS = jcip.annotations slf4j slf4j.nop slf4j.simple slf4j.jdk14
cots: $(COTS)
jcip.annotations::
slf4j::
slf4j.nop::        slf4j
slf4j.simple::     slf4j
slf4j.jdk14::      slf4j

# Tests
TEST = messenger.test parsing.test stream.test spi.test
test: $(TEST)
messenger.test:: messenger.stream parsing.yaml slf4j slf4j.simple; $(RUN_TEST)
parsing.test::   parsing.properties parsing.xml parsing.yaml;      $(RUN_TEST)
stream.test::    stream;                                           $(RUN_TEST)
spi.test::       core parsing.yaml;                                $(RUN_TEST)

clean:
	$(RM) -rf $(BUILD_DIR) $(DIST_DIR) $(GENERATED_DIR) $(TOUCH_DIR)

# TODO
define RUN_TEST
	@echo Run test $@
endef

SRC_DIRS = src/ test/
MODULES = $(SRC) $(COTS) $(TEST) $(TEST_COTS)
include cots/Java-make/java.mk

