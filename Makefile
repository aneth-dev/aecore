MODE := module
DIST := CLASS
JFLAGS := -g:none -encoding utf8
BUILD_DIR := build
GENERATED_DIR := generated
DIST_DIR := dist
SOURCE_VERSION := 1.7
TARGET_VERSION := $(SOURCE_VERSION)
ifeq "$(JAVAC)" ""
JAVAC := javac
endif # JAVAC

ifdef SOURCE_PATH

JAR := $(shell dirname `which $(JAVAC)`)/jar
MODULE = $(shell echo $(SOURCE_PATH)|sed -r 's@^.*/([^/]+)/?@\1@')
BUILD_PATH := $(BUILD_DIR)/$(MODULE)
GENERATED_PATH := $(GENERATED_DIR)/$(MODULE)
CLASSES := $(shell find $(SOURCE_PATH) -type f -name *.java)
JAVA_FILES := $(CLASSES)
CLASS_PATH := $(shell find build -maxdepth 1 -mindepth 1 -type d ! -name `basename $(BUILD_PATH)` | paste -sd :)
$(warning $(BUILD_PATH))
ifneq "$(MODULE)" "net.aeten.core"
	PROCESSOR = -processorpath $(BUILD_DIR)/net.aeten.core
else
	PROCESSOR = 
endif
ifeq "$(CLASS_PATH)" ""
	CLASS_PATH_OPT =
else
	CLASS_PATH_OPT = -classpath $(CLASS_PATH)
endif

JAVAC_CMD := $(JAVAC) $(JFLAGS) $(CLASS_PATH_OPT) -d $(BUILD_PATH) -s $(GENERATED_PATH) -source $(SOURCE_VERSION) -target $(TARGET_VERSION) $(PROCESSOR) -sourcepath $(SOURCE_PATH)

.SUFFIXES: .java .class
$(BUILD_PATH)/%.class: $(SOURCE_PATH)/%.java
	-mkdir --parent $(BUILD_PATH) dist 
	$(JAVAC_CMD) $(SOURCE_PATH)/$*.java
	$(if $(DIST)="JAR", $(JAR) uf $(DIST_DIR)/$(MODULE).jar -C $(BUILD_PATH) $**.class)

file: $(CLASSES:$(SOURCE_PATH)/%.java=$(BUILD_PATH)/%.class)

module: init
	-rm -rf $(GENERATED_PATH)
	-mkdir --parent $(GENERATED_PATH) $(BUILD_PATH) dist
	$(JAVAC_CMD) $(CLASSES)
	for resource in `find $(SOURCE_PATH) -type f ! -name \*.java|sed 's@$(SOURCE_PATH)/@@'`; do cp $(SOURCE_PATH)/$$resource $(BUILD_PATH)/`dirname $$resource`; done
	$(if $(DIST)="JAR", $(JAR) cf $(DIST_DIR)/$(MODULE).jar -C $(BUILD_PATH) .)

endif # SOURCE_PATH



init:
	-mkdir build $(GENERATED_PATH)

core.init:
	-mkdir --parent build/net.aeten.core
	@cp -fr src/net.aeten.core/META-INF build/net.aeten.core/

%__compile:
	$(MAKE) SOURCE_PATH=$(@:__compile=) MODE=$(MODE) $(MODE) 

jcip: init | src/net.jcip.annotations__compile
core: jcip core.init | src/net.aeten.core__compile
alert: core | src/net.aeten.core.alert__compile
stream: core | src/net.aeten.core.stream__compile
messenger: core | src/net.aeten.core.messenger__compile
messenger.stream: messenger stream | src/net.aeten.core.messenger.stream__compile
parsing.properties: core | src/net.aeten.core.parsing.properties__compile
parsing.xml: core | src/net.aeten.core.parsing.xml__compile
parsing.yaml: core | src/net.aeten.core.parsing.yaml__compile

messenger.test: messenger.stream parsing.yaml | test/net.aeten.core.messenger.test__compile
parsing.test: parsing.properties parsing.xml parsing.yaml | test/net.aeten.core.parsing.test__compile
stream.test: stream | test/net.aeten.core.stream.test__compile
spi.test: core | test/net.aeten.core.spi.test__compile

test: messenger.test parsing.test stream.test spi.test
all: jcip core alert stream messenger messenger.stream parsing.properties parsing.xml parsing.yaml

default: all

clean:
	$(RM) -rf $(BUILD_DIR) $(DIST_DIR) $(GENERATED_DIR)

