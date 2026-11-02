# Ravager 3 — C11 UCI chess engine with an embedded network.
#
#   make                 native build for this machine (./ravager)
#   make release         portable Linux build, x86-64-v3 (AVX2/BMI2/FMA)
#   make windows         portable Windows build (MinGW-w64 cross compiler)
#   make EVALFILE=...    embed a different network (run make clean first)

CC       ?= gcc
CFLAGS   ?= -O3 -std=c11
override CFLAGS += -Wall -Wextra -Wno-unused-parameter -Wno-missing-braces -pthread
CPPFLAGS += -Isrc -Innue
LDLIBS   += -lm

ARCH_FLAGS     ?= -march=native
PORTABLE_FLAGS := -march=x86-64-v3 -mtune=generic
override CFLAGS += $(ARCH_FLAGS)

EVALFILE ?= nets/Ravager_NET.nnue
override CPPFLAGS += -DEVALFILE='"$(EVALFILE)"'

SRC := src/bench.c src/bitboard.c src/board.c src/evaluate.c src/movegen.c src/params.c \
       src/search.c src/see.c src/tb_syzygy.c src/tt.c src/uci.c src/tb/tbprobe.c \
       nnue/inference.c nnue/nnue.c
OBJ := $(SRC:.c=.o)
DEP := $(OBJ:.o=.d)

TARGET  := ravager
RELEASE := ravager-linux-x64-avx2
WINDOWS := ravager-windows-x64-avx2.exe
ANDROID := ravager-android-arm64-neon

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $(OBJ) $(LDFLAGS) $(LDLIBS)

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -MMD -MP -c -o $@ $<

nnue/nnue.o: $(EVALFILE)

release:
	$(MAKE) clean
	$(MAKE) ARCH_FLAGS="$(PORTABLE_FLAGS)" $(TARGET)
	cp $(TARGET) $(RELEASE)
	strip $(RELEASE)

windows: $(SRC) $(wildcard src/*.h src/tb/*.h nnue/*.h) $(EVALFILE)
	x86_64-w64-mingw32-gcc $(CPPFLAGS) -O3 -std=c11 -pthread $(PORTABLE_FLAGS) \
		-o $(WINDOWS) $(SRC) $(LDLIBS) -static -s

# Android ARM64 (ARMv8.2-A + dotprod / NEON). Set CC to the Android NDK
# API-level clang wrapper, e.g. aarch64-linux-android24-clang.
android-arm64: $(SRC) $(wildcard src/*.h src/tb/*.h nnue/*.h) $(EVALFILE)
	$(CC) $(CPPFLAGS) -O3 -std=c11 -Wall -Wextra -Wno-unused-parameter -Wno-missing-braces -pthread -march=armv8.2-a+dotprod -mtune=cortex-a76 -o $(ANDROID) $(SRC) $(LDLIBS)

bench: $(TARGET)
	./$(TARGET) bench

clean:
	rm -f $(OBJ) $(DEP) $(TARGET) $(RELEASE) $(WINDOWS) $(ANDROID)

-include $(DEP)
.PHONY: all release windows android-arm64 bench clean
