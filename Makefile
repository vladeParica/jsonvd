EXTENSION   = jsonvd
EXTVERSION  = $(shell grep default_version $(EXTENSION).control | sed -e "s/default_version[[:space:]]*=[[:space:]]*'\([^']*\)'/\1/")

DATA        = sql/$(EXTENSION)--$(EXTVERSION).sql

REGRESS      = parse build mutate merge paths diff schema legacy compat
REGRESS_OPTS = --inputdir=test

PG_CONFIG ?= pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
