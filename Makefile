SOURCE_VERSION = 1.7
JFLAGS ?= -g:source,lines,vars -encoding utf8
CFLAGS ?= -g
PROCESSOR_FACTORIES_MODULES ?= net.aeten.core
TOUCH_DIR = .touch


all: compile jar eclipse src test

# Sources
SRC = core ipc messenger messenger.stream stream parsing.properties parsing.xml parsing.yaml ui.alert ui.graphical ui.swing
src: $(SRC)
core::               jcip.annotations slf4j
ipc::                ipc.jni core
messenger::          core slf4j
messenger.stream::   messenger stream slf4j
parsing.properties:: core slf4j
parsing.xml::        core
parsing.yaml::       core
stream::             core slf4j
ui.alert::           core
ui.graphical::
ui.swing::           ui.graphical

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

include Java-make/java.mk

IPC_HEADERS = -I$(JAVA_HOME)/include/ -I$(JAVA_HOME)/include/linux -Isrc/net.aeten.core
ipc.jni:
	-mkdir --parent src/net.aeten.core.ipc/net/aeten/core/ipc/linux-x86_64/
	gcc -nocpp -std=gnu99 -fPIC -shared $(CFLAGS) $(IPC_HEADERS) src/net.aeten.core.ipc/net/aeten/core/ipc/jni_socket.c -o src/net.aeten.core.ipc/net/aeten/core/ipc/linux-x86_64/libjnisocket.so
	gcc -nocpp -std=gnu99 -fPIC -shared $(CFLAGS) $(IPC_HEADERS) src/net.aeten.core.ipc/net/aeten/core/ipc/jni_ioctl.c -o src/net.aeten.core.ipc/net/aeten/core/ipc/linux-x86_64/libjniioctl.so

