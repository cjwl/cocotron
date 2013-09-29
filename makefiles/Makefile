PROJECTS = test Foundation


.PHONY: all
all: $(PROJECTS)


.PHONY: $(PROJECTS)
$(PROJECTS):
	@$(MAKE) -C $@

test: Foundation

.PHONY: clean
clean:
	@$(foreach project,$(PROJECTS),$(MAKE) -C $(project) clean;)
