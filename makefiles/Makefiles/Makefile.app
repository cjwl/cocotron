TYPE := app

include $(dir $(lastword $(MAKEFILE_LIST)))/Makefile.common

TARGET := $(TARGET_DIR)/Contents/Linux/$(NAME).bin
TARGET_WRAPPER := $(basename $(TARGET))

CFLAGS += $(addprefix -I../,$(addsuffix /$(INCLUDE_DIR),$(FRAMEWORKS)))
LDFLAGS += $(foreach framework,$(FRAMEWORKS),\
    -L../$(framework)/$(BUILD_DIR)/$(framework).framework/Versions/Current\
    -l$(framework)\
)
SPACE = $(EMPTY) $(EMPTY)
LD_PATH = $(subst $(SPACE),:,$(strip $(foreach framework,$(FRAMEWORKS),\
    $(CURDIR)/../$(framework)/$(BUILD_DIR)/$(framework).framework/Versions/Current)))


$(TARGET): $(O_FILES)
	@echo "$(GREEN)[LD]$(NORMAL)" $@
	@mkdir -p $(dir $@)
	@$(OCC) -o $@ $< $(LDFLAGS)

$(TARGET_WRAPPER): $(TARGET)
	@echo "$(YELLOW)[GN]$(NORMAL)" $@
	@echo '#/bin/sh' > $@
	@echo 'export LD_LIBRARY_PATH=$${LD_LIBRARY_PATH}:$(LD_PATH)' >> $@
	@echo '`dirname $$0`/$(notdir $<) $$@' >> $@
	@chmod +x $@

$(TARGET_DIR): $(TARGET_WRAPPER)

