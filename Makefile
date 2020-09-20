.SUFFIXES:

-include .config

ALL_CONFIGS:=$(filter CONFIG_%, $(.VARIABLES))
ALL_CONFIG_DEF:=$(subst __,_, $(subst ___,_, $(subst -,_, $(ALL_CONFIGS))))

extract_yvar=$(patsubst CONFIG_$(strip $(1))%, %, $(filter CONFIG_$(strip $(1))%, $(ALL_CONFIGS)))

if_xexist=$(shell which $(1))
if_xexist_or=$(if $(shell which $(1)), $(1), $(2))

define yes-var
FLAG-$(strip $(2))-y:=$(strip $(3))
$(strip $(1))$$(FLAG-$(strip $(2))-$$(CONFIG_$(strip $(2))))
endef

.PHONY: .info
.info:
	@echo CFLAGS=$(CFLAGS)
	@echo LDFLAGS=$(LDFLAGS)
	@echo ALL_CONFIG_DEF=$(ALL_CONFIG_DEF)

TARGET:=$(patsubst "%", %, $(CONFIG_TARGET_NAME))
OUT:=out

CSRC:=$(wildcard src/*.c)

INCPATH:=inc

LIBPATH:=lib

LIBS:=

LDSCRIPTS:=link.ld

TARGET_ELF:=$(addprefix $(OUT)/, $(addsuffix .elf, $(TARGET)))
TARGET_BIN:=$(patsubst %.elf, %.bin, $(TARGET_ELF))
TARGET_HEX:=$(patsubst %.elf, %.hex, $(TARGET_ELF))
TARGET_MAP:=$(patsubst %.elf, %.map, $(TARGET_ELF))
TARGET_LST:=$(patsubst %.elf, %.lst, $(TARGET_ELF))

COMMA:=,

ifeq ($(CONFIG_VERBOSE),y)
Q:=
else
Q:=@
endif

MENUCONFIG_CMD?=$(call if_xexist, kconfig-mconf)
ifneq ($(OS),Windows_NT)
ifeq ($(XDG_SESSION_TYPE),x11)
MENUCONFIG_CMD:=$(call if_xexist_or, kconfig-gconf, kconfig-mconf)
endif
ifeq ($(MENUCONFIG_CMD),)
MENUCONFIG_CMD:=$(call if_xexist_or, kconfig-qconf, kconfig-mconf)
endif
endif

ifeq ($(MENUCONFIG_CMD),)
$(error $(MENUCONFIG_CMD) is not in path)
endif

OBJECTS:=$(addprefix $(OUT)/, $(notdir $(patsubst %.c, %.o, $(CSRC))))
DEPS:=$(addsuffix .o.dep.mk, $(OBJECTS))

CROSS:=$(patsubst "%", %, $(CONFIG_CROSS_PREFIX))
CC:=$(CROSS)gcc
LD:=$(CROSS)gcc
OCP:=$(CROSS)objcopy
OD:=$(CROSS)objdump
RM:=rm -fr

OPT_FLAGS:=$(addprefix -O, $(call extract_yvar, OPT_))
OPT_FLAGS+=$(addprefix -g, $(call extract_yvar, DBG_))

ARCH_FLAGS:=$(addprefix -mcpu=, $(call extract_yvar, CPU_))
$(eval $(call yes-var, ARCH_FLAGS+=, USE_THUMB, -mthumb))
$(eval $(call yes-var, ARCH_FLAGS+=, USE_FPU, -mfloat-abi=hard))
$(eval $(call yes-var, ARCH_FLAGS+=, USE_FPUDP, -mfpu=fpv5-sp-d16))

SPECS:=$(call extract_yvar, SPECS_)

SPEC_FLAGS:=$(addprefix -specs=, $(addsuffix .specs, $(SPECS)))

CFLAGS:=$(ARCH_FLAGS)
CFLAGS+=$(OPT_FLAGS)
CFLAGS+=$(SPEC_FLAGS)
CFLAGS+=$(addprefix -, $(call extract_yvar, CFLAGS_))

LINKER_FLAGS:=$(call extract_yvar, LDFLAGSWL_)
LINKER_FLAGS+=-Map=$(strip $(TARGET_MAP))

LDFLAGS:=$(ARCH_FLAGS) $(SPEC_FLAGS)
LDFLAGS+=$(addprefix -Wl$(COMMA), $(LINKER_FLAGS))
LDFLAGS+=$(addprefix -L, $(LIBPATH))
LDFLAGS+=$(addprefix -l, $(LIBS))
LDFLAGS+=$(addprefix -T, $(LDSCRIPTS))
LDFLAGS+=$(call extract_yvar, LDFLAGS_)

LSTSECTIONS:=$(foreach l, $(LDSCRIPT_FILES), $(strip $(shell cat $l | grep -E '\s\.\S+\s+\:' | cut -f 1 -d ':') ))
LSTFLAGS:=-z -x -w -t -S $(addprefix -j, $(LSTSECTIONS))

all: $(TARGET_ELF) $(TARGET_BIN) $(TARGET_HEX) $(TARGET_LST)

$(OUT):
	@mkdir -p $(OUT)

$(OUT)/genhdr/autoconf.h: .config | $(OUT)
	@echo GEN $@
	@mkdir -p $(dir $@)
	@sh gen-hdr.sh $< > $@

define cc_rule
$(OUT)/$(notdir $(patsubst %.c, %.o, $1)): $1 $(OUT)/genhdr/autoconf.h | $(OUT)
	@echo CC $$<
	$(Q)$(CC) -MMD -MP -MF $$@.dep.mk -c $(CFLAGS) -o $$@ $$<
endef

define cc_rules
	$(foreach f, $(CSRC), $(eval $(call cc_rule, $f)))
endef

$(eval $(cc_rules))

$(TARGET_ELF): $(OBJECTS)
	@echo LD $@
	$(Q)$(LD) $(LDFLAGS) -o $@ $(OBJECTS)

$(TARGET_BIN): $(TARGET_ELF)
	@echo BIN $@
	$(Q)$(OCP) -O binary $< $@

$(TARGET_HEX): $(TARGET_ELF)
	@echo HEX $@
	$(Q)$(OCP) -O ihex $< $@

$(TARGET_LST): $(TARGET_ELF)
	@echo LIST $@
	$(Q)$(OD) $(LSTFLAGS) $< > $@

menuconfig:
	$(Q)$(MENUCONFIG_CMD) Kconfig

clean:
	$(Q)$(RM) $(OUT)

.PHONY: clean all menuconfig
