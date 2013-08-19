# Makefile for nsfbios

TARGET = hello.bin
NESROM = hello.nes
SOURCE = hello.s
OBJECT = $(patsubst %.s,%.o,$(SOURCE))

AS = wla-6502
LD = wlalink

ASFLAGS =
LDFLAGS = -d linkfile

NESEMU2 = nesemu2

$(TARGET): $(OBJECT)
	$(LD) $(LDFLAGS) $@

$(NESROM): $(TARGET)
	cat header.bin $(TARGET) > $(NESROM)

rom: $(NESROM)

clean:
	rm -f $(OBJECT) $(TARGET) $(NESROM)

test: $(NESROM)
	$(NESEMU2) $(NESROM)

.SUFFIXES: .s

.s.o:
	$(AS) -$(ASFLAGS)o $< $@

.PHONY: rom clean test
