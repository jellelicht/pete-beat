# SPDX-FileCopyrightText: 2021 bbbbbr
# SPDX-FileCopyrightText: 2021 Jelle Licht <jlicht@fsfe.org>
#
# SPDX-License-Identifier: MIT

.POSIX:
.SUFFIXES: 
CC     = lcc
CFLAGS = -debug 
PNG2GBM = png2gbtiles
PNG2GBMFLAGS = -gbm
GBM2C = gbm2c
GBR2C = gbr2c
EMULATOR = sameboy

PROJECTNAME    = PeteBeat

SRCDIR      = src
OBJDIR      = obj
RESDIR      = res
BINS	    = $(OBJDIR)/$(PROJECTNAME).gb
RESOURCES = cave_tiles.h cave_map.h

all:	prepare $(RESOURCES) $(BINS)

cave.gbm cave.gbm.tiles.gbr: cave.png
	$(PNG2GBM) cave.png $(PNG2GBMFLAGS)

cave.gbm.tiles.gbr.c cave_tiles.h: cave.gbm.tiles.gbr
	$(GBR2C) cave.gbm.tiles.gbr .

cave.gbm.c cave_map.h: cave.gbm
	$(GBM2C) cave.gbm .
	sed -i 's/cave.h/cave_tiles.h/' cave.gbm.c
	sed -i 's/cave,/cave_tiles,/' cave.gbm.c

CSOURCES   = main.c cave.gbm.c cave.gbm.tiles.gbr.c
OBJS       = $(CSOURCES:%.c=$(OBJDIR)/%.o)


# Compile .c files in "src/" to .o object files
$(OBJDIR)/%.o:	%.c $(RESOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<

# Link the compiled object files into a .gb ROM file
$(BINS):	$(OBJS)
	$(CC) $(CFLAGS) -o $(BINS) $(OBJS)

prepare:
	mkdir -p $(OBJDIR)

clean:
	rm -f  $(OBJDIR)/*.*
	rm -f  $(RESOURCES)

run:
	$(EMULATOR) $(BINS)

