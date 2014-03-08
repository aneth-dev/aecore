MODE := module
DIST := CLASS
JFLAGS := -g:source,lines,vars -encoding utf8
BUILD_DIR := build
GENERATED_DIR := generated
DIST_DIR := dist
SOURCE_VERSION := 1.7
TARGET_VERSION := $(SOURCE_VERSION)
ifeq "$(JAVAC)" ""
JAVAC := javac
endif # JAVAC

JAR := $(shell dirname `which $(JAVAC)`)/jar

%__: 
	$(eval SOURCE_PATH = $(@:__=))
	$(eval MODULE = `basename $(SOURCE_PATH)`)
	$(eval BUILD_PATH := $(BUILD_DIR)/$(MODULE))
	$(eval GENERATED_PATH := $(GENERATED_DIR)/$(MODULE))
	$(eval CLASSES := $(shell find $(SOURCE_PATH) -type f -name *.java))
	$(eval JAVA_FILES := $(CLASSES))
	@if [ $(MODULE) = "net.aeten.core" ] || [ $(MODULE) = "net.jcip.annotations" ]; then \
		PROCESSOR="-proc:none"; \
	else \
		PROCESSOR="-processorpath $(BUILD_DIR)/net.aeten.core"; \
	fi
	$(eval CLASS_PATH = \`find build -maxdepth 1 -mindepth 1 -type d ! -name \\\$(MODULE:`=)\\\` | paste -sd :\`)
	$(eval CLASS_PATH_OPT = `if [ ! -z $(CLASS_PATH) ]; then echo -classpath $(CLASS_PATH); fi`)
	$(eval JAVAC_CMD := $(JAVAC) $(JFLAGS) $(CLASS_PATH_OPT) -d $(BUILD_PATH) -s $(GENERATED_PATH) -source $(SOURCE_VERSION) -target $(TARGET_VERSION) $(PROCESSOR) -sourcepath $(SOURCE_PATH))

	-rm -rf $(GENERATED_PATH)
	-mkdir --parent $(GENERATED_PATH) $(BUILD_PATH) dist
	$(JAVAC_CMD) $(CLASSES)
	@for resource in `find $(SOURCE_PATH) -type f ! -name \*.java|sed 's@$(SOURCE_PATH)/@@'`; do \
		mkdir --parent $(BUILD_PATH)/`dirname $$resource`; \
		cp $(SOURCE_PATH)/$$resource $(BUILD_PATH)/`dirname $$resource`; \
	done
	$(if $(DIST)="JAR", $(JAR) cf $(DIST_DIR)/$(MODULE).jar -C $(BUILD_PATH) .)


all: jcip core alert stream messenger messenger.stream parsing.properties parsing.xml parsing.yaml
test: messenger.test parsing.test stream.test spi.test

src/net.aeten.core__: jcip
src/net.aeten.core.alert__: core
src/net.aeten.core.stream__: core
src/net.aeten.core.messenger__: core
src/net.aeten.core.messenger.stream__: messenger stream
src/net.aeten.core.parsing.properties__: core
src/net.aeten.core.parsing.xml__: core
src/net.aeten.core.parsing.yaml__: core

jcip: src/net.jcip.annotations__
core: src/net.aeten.core__
alert: src/net.aeten.core.alert__
stream: src/net.aeten.core.stream__
messenger: src/net.aeten.core.messenger__
messenger.stream: src/net.aeten.core.messenger.stream__
parsing.properties: src/net.aeten.core.parsing.properties__
parsing.xml: src/net.aeten.core.parsing.xml__
parsing.yaml: src/net.aeten.core.parsing.yaml__

test/net.aeten.core.messenger.test__: | messenger.stream parsing.yaml
test/net.aeten.core.parsing.test__: | parsing.properties parsing.xml parsing.yaml
test/net.aeten.core.stream.test__: | stream
test/net.aeten.core.spi.test__: | core

messenger.test: test/net.aeten.core.messenger.test__
parsing.test: test/net.aeten.core.parsing.test__
stream.test: test/net.aeten.core.stream.test__
spi.test: test/net.aeten.core.spi.test__


clean:
	$(RM) -rf $(BUILD_DIR) $(DIST_DIR) $(GENERATED_DIR)

