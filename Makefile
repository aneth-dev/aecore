DIST := CLASS
JFLAGS := -g:source,lines,vars -encoding utf8
BUILD_DIR := build
GENERATED_DIR := generated
DIST_DIR := dist
SOURCE_VERSION := 1.7
TARGET_VERSION := $(SOURCE_VERSION)
ifeq "$(JAVAC)" ""
	JAVAC := javac
endif
JAR := $(shell dirname `which $(JAVAC)`)/jar
SRC_DIRS := src/ test/
PROCESSOR_PATH := $(BUILD_DIR)/net.aeten.core

$(info Make command goals\: $(MAKECMDGOALS))

all: src test

# Sources
SRC = jcip.annotations core alert stream messenger messenger.stream parsing.properties parsing.xml parsing.yaml
src: $(SRC)
jcip.annotations:; $(COMPILE)
core: jcip.annotations; $(COMPILE)
alert: core; $(COMPILE)
stream: core; $(COMPILE)
messenger: core; $(COMPILE)
messenger.stream: messenger stream; $(COMPILE)
parsing.properties: core; $(COMPILE)
parsing.xml: core; $(COMPILE)
parsing.yaml: core; $(COMPILE)

# Tests
TEST = messenger.test parsing.test stream.test spi.test
test: $(TEST)
messenger.test: messenger.stream parsing.yaml; $(COMPILE)
parsing.test: parsing.properties parsing.xml parsing.yaml; $(COMPILE)
stream.test: stream; $(COMPILE)
spi.test: core; $(COMPILE)

.PHONY: all src test $(SRC) $(TEST)

clean:
	$(RM) -rf $(BUILD_DIR) $(DIST_DIR) $(GENERATED_DIR)


# Do not touch the following
define COMPILE
@echo Compile module $@ $(shell [ ! -z "$^" ] && echo wich depends on $(shell echo $^|sed -r 's/\s+/, /g'))

$(eval SOURCE_PATH = $(shell find $(SRC_DIRS) -maxdepth 1 -type d -name \*.$(@) | awk 'BEGIN {source=""} {if (length(source) == 0 || length($$0) < length(source)) {source=$$0}} END {print source}'))
$(eval MODULE = $(shell basename $(SOURCE_PATH)))
$(eval CLASS_PATH =)
$(foreach dependence, $^,
	$(eval DEPEPEDENCE = $(shell basename $$(find $(SRC_DIRS) -maxdepth 1 -type d -name \*.$(dependence) | awk 'BEGIN {source=""} {if (length(source) == 0 || length($$0) < length(source)) {source=$$0}} END {print source}')))
	$(eval DEPEPEDENCIES_$@ += $(BUILD_DIR)/$(DEPEPEDENCE) $(DEPEPEDENCIES_$(dependence)))
)
$(eval CLASS_PATH_OPT = $(shell if [ ! -z "$(DEPEPEDENCIES_$@)" ]; then echo -classpath $(shell echo $(DEPEPEDENCIES_$@)|sed -r 's/\s+/:/g'); fi))
$(eval BUILD_PATH = $(BUILD_DIR)/$(MODULE))
$(eval GENERATED_PATH = $(GENERATED_DIR)/$(MODULE))
-rm -rf $(GENERATED_PATH)
-mkdir --parent $(GENERATED_PATH) $(BUILD_PATH) dist
$(eval CLASSES = $(shell find $(SOURCE_PATH) -type f -name *.java))
$(eval PROCESSOR_OPT = $(shell ([ $(MODULE) = "net.aeten.core" ] || [ $(MODULE) = "net.jcip.annotations" ]) && echo -proc:none || echo -processorpath $(PROCESSOR_PATH)))
$(JAVAC) $(JFLAGS) $(CLASS_PATH_OPT) -d $(BUILD_PATH) -s $(GENERATED_PATH) -source $(SOURCE_VERSION) -target $(TARGET_VERSION) $(PROCESSOR_OPT) -sourcepath $(SOURCE_PATH) $(CLASSES)
$(foreach resource, $(shell find $(SOURCE_PATH) -type f ! -name \*.java|sed "s@$(SOURCE_PATH)/@@"),
	@-mkdir --parent $(BUILD_PATH)/`dirname $(resource)`
	cp $(SOURCE_PATH)/$(resource) $(BUILD_PATH)/`dirname $(resource)`
)
$(if ifeq($(DIST)==JAR),
	$(JAR) cf $(DIST_DIR)/$(MODULE).jar -C $(BUILD_PATH) . &
)
endef # COMPILE

