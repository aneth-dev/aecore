JFLAGS ?= -g:source,lines,vars -encoding utf8
BUILD_DIR ?= build
GENERATED_DIR ?= generated
DIST_DIR ?= dist
SOURCE_VERSION ?= 1.7
TARGET_VERSION ?= $(SOURCE_VERSION)
JAVAC ?= javac
JAR ?= $(shell dirname `which $(JAVAC)`)/jar
PROCESSOR_PATH ?= $(BUILD_DIR)/net.aeten.core
TOUCH_DIR ?= .touch
DIST ?= CLASS
SRC_DIRS := src/ test/

all: src test

# Sources
SRC = jcip.annotations core alert stream messenger messenger.stream parsing.properties parsing.xml parsing.yaml
src:: $(SRC)
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
test:: $(TEST)
messenger.test:: messenger.stream parsing.yaml;               $(RUN_TEST)
parsing.test::   parsing.properties parsing.xml parsing.yaml; $(RUN_TEST)
stream.test::    stream;                                      $(RUN_TEST)
spi.test::       core;                                        $(RUN_TEST)

clean:
	$(RM) -rf $(BUILD_DIR) $(DIST_DIR) $(GENERATED_DIR) $(TOUCH_DIR)


# TODO
define RUN_TEST
@echo Run test $(TARGET)
endef

MODULES = $(SRC) $(TEST)

$(shell mkdir --parent $(TOUCH_DIR))

# Do not touch the following
define COMPILE
@echo Compile module $(TARGET) $(shell [ ! -z "$(DEPENDENCIES)" ] && echo wich depends on $(shell echo $(DEPENDENCIES)|sed -r 's/\s+/, /g'))

$(eval SOURCE_PATH = $(shell find $(SRC_DIRS) -maxdepth 1 -type d -name \*.$(TARGET) | awk 'BEGIN {source=""} {if (length(source) == 0 || length($$0) < length(source)) {source=$$0}} END {print source}'))
$(eval MODULE = $(shell basename $(SOURCE_PATH)))
$(eval CLASS_PATH =)
$(foreach dependence, $(DEPENDENCIES),
	$(eval DEPENDENCE = $(shell basename $$(find $(SRC_DIRS) -maxdepth 1 -type d -name \*.$(dependence) | awk 'BEGIN {source=""} {if (length(source) == 0 || length($$0) < length(source)) {source=$$0}} END {print source}')))
	$(eval DEPENDENCIES_$(TARGET) += $(BUILD_DIR)/$(DEPENDENCE) $(DEPENDENCIES_$(dependence)))
)
$(eval CLASS_PATH_OPT = $(shell if [ ! -z "$(DEPENDENCIES_$(TARGET))" ]; then echo -classpath $(shell echo $(DEPENDENCIES_$(TARGET))|sed -r 's/\s+/:/g'); fi))
$(eval BUILD_PATH = $(BUILD_DIR)/$(MODULE))
$(eval GENERATED_PATH = $(GENERATED_DIR)/$(MODULE))
-rm -rf $(GENERATED_PATH)
-mkdir --parent $(GENERATED_PATH) $(BUILD_PATH) dist
$(eval CLASSES = $(shell find $(SOURCE_PATH) -type f -name *.java))
$(foreach class, $(CLASSES),
	@echo find class $(class)>/dev/null
)
$(eval PROCESSOR_OPT = $(shell ([ $(MODULE) = "net.aeten.core" ] || [ $(MODULE) = "net.jcip.annotations" ]) && echo -proc:none || echo -processorpath $(PROCESSOR_PATH)))
$(JAVAC) $(JFLAGS) $(CLASS_PATH_OPT) -d $(BUILD_PATH) -s $(GENERATED_PATH) -source $(SOURCE_VERSION) -target $(TARGET_VERSION) $(PROCESSOR_OPT) -sourcepath $(SOURCE_PATH) $(CLASSES)
$(foreach resource, $(shell find $(SOURCE_PATH) -type f ! -name \*.java|sed "s@$(SOURCE_PATH)/@@"),
	@-mkdir --parent $(BUILD_PATH)/`dirname $(resource)`
	cp $(SOURCE_PATH)/$(resource) $(BUILD_PATH)/`dirname $(resource)`
)
[ $(DIST) = JAR ] && $(JAR) cf $(DIST_DIR)/$(MODULE).jar -C $(BUILD_PATH) . &
endef # COMPILE



ifeq (,$(findstring n,$(MAKEFLAGS)))
$(MODULES):: %: $(TOUCH_DIR)/%

.SECONDEXPANSION:
$(addprefix $(TOUCH_DIR)/,$(MODULES)): %:  $$(addprefix $(TOUCH_DIR)/,$$(shell make -prn|awk '/^$$(subst $(TOUCH_DIR)/,,$$@)::/ && NF > 1 && sub($$$$1,"",$$$$0) { print $$$$0 }'))
	$(eval TARGET = $(patsubst $(TOUCH_DIR)/%,%,$@))
	$(eval DEPENDENCIES = $(subst $(TOUCH_DIR)/,,$^))
	@echo Compile module $(TARGET) $(shell [ ! -z "$(DEPENDENCIES)" ] && echo wich depends on $(shell echo $(DEPENDENCIES)|sed -r 's/\s+/, /g'))
	$(COMPILE)
	@touch $@
endif

