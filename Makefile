SOURCE_VERSION = 1.8
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

# COTS for tests
TEST_COTS = junit hamcrest hamcrest.generator qdox
junit::              hamcrest
# Hamcrest depends on qdox 1.12
hamcrest::           qdox hamcrest.generator
hamcrest.generator:: qdox
# QDox depends on byaccj and jflex binaries
qdox::

clean:
	$(RM) -rf $(BUILD_DIR) $(DIST_DIR) $(GENERATED_DIR) $(TOUCH_DIR)

# TODO
define RUN_TEST
	@echo Run test $@
endef

define pre.qdox
	$(eval impl_path = $(GENERATED_PATH)/com/thoughtworks/qdox/parser/impl)
	-mkdir --parent $(impl_path)
	$(eval GRAMMAR = $(abspath cots/qdox/src/grammar))
	cd $(impl_path);\
	byaccj -v -Jnorun -Jnoconstruct -Jclass=Parser -Jsemantic=Value -Jpackage=com.thoughtworks.qdox.parser.impl $(GRAMMAR)/parser.y;\
	jflex -d . --skel $(GRAMMAR)/skeleton.inner $(GRAMMAR)/lexer.flex;\
	cd -
	$(eval CLASSES += $(impl_path)/*.java)
	$(eval COMPILE_FILTER = -path '*/junit/*' -prune -or -path '*/ant/*' -prune -or)
endef

define post.hamcrest
	$(eval classpath = $(CLASS_PATH_OPT))
	$(JAVA) $(CLASS_PATH_OPT):$(BUILD_PATH) org.hamcrest.generator.config.XmlConfigurator cots/JavaHamcrest/core-matchers.xml src/org.hamcrest org.hamcrest.CoreMatchers $(GENERATED_DIR)/$(MODULE)
	$(JAVAC) $(CLASS_PATH_OPT) $(JFLAGS) -d $(BUILD_DIR)/$(MODULE) -source $(SOURCE_VERSION) -target $(TARGET_VERSION) -sourcepath $(SOURCE_PATH) $(GENERATED_DIR)/$(MODULE)/org/hamcrest/CoreMatchers.java
endef

SRC_DIRS = src/ test/
MODULES = $(SRC) $(COTS) $(TEST) $(TEST_COTS)
include java.mk

