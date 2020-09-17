TARGET:=armv7m-universal-boot
OUT:=out

CSRC:=$(wildcard src/*.c)

INCPATH:=inc

LIBPATH:=lib

LIBS:=

SPECS:=nosys

LDSCRIPTS:=link.ld

ARCH_FLAGS:=-mcpu=cortex-m3 -mthumb
OPT_FLAGS:=-Og -g3

TARGET_ELF:=$(addprefix $(OUT)/, $(addsuffix .elf, $(TARGET)))
TARGET_BIN:=$(patsubst %.elf, %.bin, $(TARGET_ELF))
TARGET_HEX:=$(patsubst %.elf, %.hex, $(TARGET_ELF))
TARGET_MAP:=$(patsubst %.elf, %.map, $(TARGET_ELF))
TARGET_LST:=$(patsubst %.elf, %.lst, $(TARGET_ELF))

COMMA:=,
Q:=

OBJECTS:=$(addprefix $(OUT)/, $(notdir $(patsubst %.c, %.o, $(CSRC))))
DEPS:=$(addsuffix .o.dep.mk, $(OBJECTS))

CROSS?=arm-none-eabi-
CC:=$(CROSS)gcc
LD:=$(CROSS)gcc
OCP:=$(CROSS)objcopy
OD:=$(CROSS)objdump
RM:=rm -fr

SPEC_FLAGS:=$(addprefix -specs=, $(addsuffix .specs, $(SPECS)))

CFLAGS:=$(ARCH_FLAGS)
CFLAGS+=$(OPT_FLAGS)
CFLAGS+=$(SPEC_FLAGS)
CFLAGS+=-fdata-sections -ffunction-sections -fmove-loop-invariants

LINKER_FLAGS:=--gc-sections -Map=$(strip $(TARGET_MAP)) --print-memory-usage

LDFLAGS:=$(ARCH_FLAGS) $(SPEC_FLAGS)
LDFLAGS+=$(addprefix -Wl$(COMMA), $(LINKER_FLAGS))
LDFLAGS+=$(addprefix -L, $(LIBPATH))
LDFLAGS+=$(addprefix -l, $(LIBS))
LDFLAGS+=$(addprefix -T, $(LDSCRIPTS))
LDFLAGS+=-nostartfiles

LSTSECTIONS:=$(foreach l, $(LDSCRIPT_FILES), $(strip $(shell cat $l | grep -E '\s\.\S+\s+\:' | cut -f 1 -d ':') ))
LSTFLAGS:=-z -x -w -t -S $(addprefix -j, $(LSTSECTIONS))

all: $(TARGET_ELF) $(TARGET_BIN) $(TARGET_HEX) $(TARGET_LST)

$(OUT):
	mkdir -p $(OUT)

define cc_rule
$(OUT)/$(notdir $(patsubst %.c, %.o, $1)): $1 | $(OUT)
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

clean:
	$(Q)$(RM) $(OUT)

.PHONY: clean all
