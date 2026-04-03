COMPILER ?= $(GCC_PATH)gcc

FLAGS ?= -fopenmp -O2 -Wall -Wno-variadic-macros -pedantic -g \
         $(GCC_SUPPFLAGS) -DDEBUG_MNGR -DDEBUG_LOADER \
         -Icore/inc

LDFLAGS ?= -g -fopenmp
LDLIBS ?= -lm

EXECUTABLE = schedule_processes

SRCS = $(wildcard core/src/*.c)
OBJS = $(patsubst core/src/%.c,obj/%.o,$(SRCS))

all: release

release: $(OBJS)
	$(COMPILER) $(LDFLAGS) -o $(EXECUTABLE) $(OBJS) $(LDLIBS)

obj/%.o: core/src/%.c | obj
	$(COMPILER) $(FLAGS) -c $< -o $@

obj:
	mkdir -p obj

clean:
	rm -f obj/*.o
	rm -f *.log *.out
	rm -f $(EXECUTABLE)
