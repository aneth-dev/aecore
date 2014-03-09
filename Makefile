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

FIND_SOURCE_PATH = \
	find src/ test/ -maxdepth 1 -type d -name \*.$@|awk 'BEGIN {source=""} {if (length(source) == 0 || length($$0) < length(source)) {source=$$0}} END {print source}'
	

COMPILE = \
	@echo $@ deps $^ ;\
	SOURCE_PATH=`$(FIND_SOURCE_PATH)` ;\
	echo $$SOURCE_PATH;\
	MODULE=`basename $$SOURCE_PATH` ;\
	BUILD_PATH=$(BUILD_DIR)/$$MODULE ;\
	GENERATED_PATH=$(GENERATED_DIR)/$$MODULE ;\
	rm -rf $$GENERATED_PATH ;\
	mkdir --parent $$GENERATED_PATH $$BUILD_PATH dist ;\
	CLASSES=$$(find $$SOURCE_PATH -type f -name *.java) ;\
	JAVA_FILES=$$CLASSES ;\
	if [ $$MODULE = "net.aeten.core" ] || [ $$MODULE = "net.jcip.annotations" ]; then\
		PROCESSOR="-proc:none";\
	else\
		PROCESSOR="-processorpath $(BUILD_DIR)/net.aeten.core";\
	fi;\
	CLASS_PATH=`find build -maxdepth 1 -mindepth 1 -type d ! -name $$MODULE | paste -sd :`;\
	CLASS_PATH_OPT=`if [ ! -z $$CLASS_PATH ]; then echo -classpath $$CLASS_PATH; fi` ;\
	JAVAC_CMD="$(JAVAC) $(JFLAGS) $$CLASS_PATH_OPT -d $$BUILD_PATH -s $$GENERATED_PATH -source $(SOURCE_VERSION) -target $(TARGET_VERSION) $$PROCESSOR -sourcepath $$SOURCE_PATH" ;\
	echo $$JAVAC_CMD $$CLASSES;\
	$$JAVAC_CMD $$CLASSES;\
	for resource in `find $$SOURCE_PATH -type f ! -name \*.java|sed "s@$$SOURCE_PATH/@@"`; do\
		mkdir --parent $$BUILD_PATH/`dirname $$resource`;\
		CP="cp $$SOURCE_PATH/$$resource $$BUILD_PATH/`dirname $$resource`";\
		echo $$CP;\
		`$$CP`;\
	done ;\
	if [ $(DIST) = "JAR" ]; then $(JAR) cf $(DIST_DIR)/$$MODULE.jar -C $$BUILD_PATH . & fi

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

