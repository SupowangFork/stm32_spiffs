

BINARY = spiffs_stm32
DBG_SCRIPT = debug.gdb
GDB_PORT = 4444


CONFIG_MAKE = config.mk


############
#
# STM Device settings
#
############

FLAGS += -DSYSCLK_FREQ_72MHz=72000000
FLAGS += -DSTM32F10X_HD
STARTUP = startup_stm32f10x_hd.s

############
#
# Paths
#
############

sourcedir = src
builddir = build

basetoolsdir = /home/petera/toolchain/arm-none-eabi-toolchain-gcc-5.3.0-softfloat
libdir = ${basetoolsdir}/lib/gcc/arm-none-eabi/5.3.0

hfile = ${sourcedir}/config_header.h

stmlibdir = STM32F10x_StdPeriph_Lib_V3.5.0/Libraries
stmdriverdir = ${stmlibdir}/STM32F10x_StdPeriph_Driver
stmcmsisdir = ${stmlibdir}/CMSIS/CM3/DeviceSupport/ST/STM32F10x
stmcmsisdircore = ${stmlibdir}/CMSIS/CM3/CoreSupport

tools = ${basetoolsdir}/bin

gensysdir = ./generic_embedded
spiffs = ./spiffs

CPATH =
SPATH =
INC =
SFILES =
CFILES =
RFILES =
SPIFFS_FLAGS ?= 

#############
#
# Build tools
#
#############

CROSS_COMPILE=${tools}/arm-none-eabi-
#CROSS_COMPILE=${tools}/arm-elf-
CC = $(CROSS_COMPILE)gcc $(COMPILEROPTIONS)
AS = $(CROSS_COMPILE)gcc $(ASSEMBLEROPTIONS)
LD = $(CROSS_COMPILE)ld
GDB = $(CROSS_COMPILE)gdb
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
SIZE = $(CROSS_COMPILE)size
MKDIR = mkdir -p

###############
#
# Build configs
#
###############

COMPILER_OPTIMIZE_FLAGS = -Os
LD_SCRIPT = arm.ld
INCLUDE_DIRECTIVES =
COMPILEROPTIONS = $(INCLUDE_DIRECTIVES) $(FLAGS) -mcpu=cortex-m3 -mno-thumb-interwork -mthumb -Wall -gdwarf-2 -Wno-packed-bitfield-compat -ffunction-sections -fdata-sections
COMPILEROPTIONS += $(COMPILER_OPTIMIZE_FLAGS) -nostartfiles -nostdlib 
#COMPILEROPTIONS += -mno-unaligned-access
ASSEMBLEROPTION = $(COMPILEROPTIONS)
LINKERSCRIPT = $(LD_SCRIPT)

GC_SECTION ?= 1
ifeq (1, $(strip $(GC_SECTION)))
LINKEROPTIONS = --gc-sections -cref
endif

OBJCOPYOPTIONS_HEX = -O ihex ${builddir}/$(BINARY).elf
OBJCOPYOPTIONS_BIN = -O binary ${builddir}/$(BINARY).elf

BUILD_NUMBER_FILE=build-number.txt

###############
#
# Files and libs
#
###############

# app files

CPATH 		+= ${sourcedir}
SPATH 		+= ${sourcedir}
INC			+= -I./${sourcedir}



# generic system configuration
include ${CONFIG_MAKE}

# spiffs
include ${spiffs}/files.mk

# common  files

CFILES 		+= main.c
CFILES 		+= processor.c
CFILES 		+= timer.c
CFILES		+= precise_clock.c
CFILES		+= app.c

# stm32 lib files
#SPATH	+= ${stmdriverdir}/src ${stmcmsisdir} ${stmcmsisdir}/startup/gcc_ride7
SFILES 	+= $(STARTUP)

CPATH	+= ${stmdriverdir}/src ${stmcmsisdir} ${stmcmsisdircore}
INC		+= -I./${stmdriverdir}/inc
INC		+= -I./${stmcmsisdir}
INC		+= -I./${stmcmsisdircore}

CFILES	+= misc.c
CFILES	+= stm32f10x_adc.c
CFILES	+= stm32f10x_bkp.c
CFILES	+= stm32f10x_can.c
CFILES	+= stm32f10x_cec.c
CFILES	+= stm32f10x_crc.c
CFILES	+= stm32f10x_dac.c
CFILES	+= stm32f10x_dbgmcu.c
CFILES	+= stm32f10x_dma.c
CFILES	+= stm32f10x_exti.c
CFILES	+= stm32f10x_flash.c
CFILES	+= stm32f10x_fsmc.c
CFILES	+= stm32f10x_gpio.c
CFILES	+= stm32f10x_i2c.c
CFILES	+= stm32f10x_iwdg.c
CFILES	+= stm32f10x_pwr.c
CFILES	+= stm32f10x_rcc.c
CFILES	+= stm32f10x_rtc.c
CFILES	+= stm32f10x_sdio.c
CFILES	+= stm32f10x_spi.c
CFILES	+= stm32f10x_tim.c
CFILES	+= stm32f10x_usart.c
CFILES	+= stm32f10x_wwdg.c
		
# cmsis files
CFILES	+= system_stm32f10x.c
CFILES	+= core_cm3.c

# stm32 system
CFILES 	+= stm32f10x_it.c

LIBS = ${libdir}/libgcc.a

BINARYEXT = .hex


############
#
# Tasks
#
############

vpath %.c $(CPATH)
vpath %.s $(SPATH)
INCLUDE_DIRECTIVES += $(INC)

SOBJFILES = $(SFILES:%.s=${builddir}/%.o)
OBJFILES = $(CFILES:%.c=${builddir}/%.o)
ROBJFILES = $(RFILES:%.c=${builddir}/%.o)

DEPFILES = $(CFILES:%.c=${builddir}/%.d)
DEPFILES += $(RFILES:%.c=${builddir}/%.d)

ALLOBJFILES  = $(SOBJFILES)
ALLOBJFILES += $(OBJFILES)
ALLOBJFILES += $(ROBJFILES)

DEPENDENCIES = $(DEPFILES)

FLAGS += $(SPIFFS_FLAGS) 

# link object files, create binary for flashing
$(BINARY): ${hfile} $(ALLOBJFILES)
	@echo "... build info"
	@if ! test -f $(BUILD_NUMBER_FILE); then echo 0 > $(BUILD_NUMBER_FILE); fi
	@echo $$(($$(cat $(BUILD_NUMBER_FILE)) + 1)) > $(BUILD_NUMBER_FILE)	
	@echo "... linking"
	@${LD} $(LINKEROPTIONS) $(BUILD_NUMBER_LDFLAGS) -T $(LINKERSCRIPT) -Map ${builddir}/$(BINARY).map -o ${builddir}/$(BINARY).elf $(ALLOBJFILES) $(LIBS)
	@echo "... objcopy"
	@${OBJCOPY} $(OBJCOPYOPTIONS_BIN) ${builddir}/$(BINARY).out
	@${OBJCOPY} $(OBJCOPYOPTIONS_HEX) ${builddir}/$(BINARY)$(BINARYEXT) 
	@echo "... disasm"
	@${OBJDUMP} -hd -j .text -j.data -j .bss -j .bootloader_text -j .bootloader_data -d -S ${builddir}/$(BINARY).elf > ${builddir}/$(BINARY)_disasm.s
	@echo "${BINARY}.out is `du -b ${builddir}/${BINARY}.out | sed 's/\([0-9]*\).*/\1/g '` bytes on flash"

-include $(DEPENDENCIES)	   	

# compile assembly files, arm
$(SOBJFILES) : ${builddir}/%.o:%.s
		@echo "... assembly $@"
		@${AS} -c -o $@ $<
		
# compile c files
$(OBJFILES) : ${builddir}/%.o:%.c
		@echo "... compile $@"
		@${CC} -c -o $@ $<

# compile c files deisgnated for ram
$(ROBJFILES) : ${builddir}/%.o:%.c
		@echo "... ram compile $@"
		@${CC} -c -o $@ $< 

# make dependencies
$(DEPFILES) : ${builddir}/%.d:%.c
		@echo "... depend $@"; \
		rm -f $@; \
		${CC} $(COMPILEROPTIONS) -M $< > $@.$$$$; \
		sed 's,\($*\)\.o[ :]*, ${builddir}/\1.o $@ : ,g' < $@.$$$$ > $@; \
		rm -f $@.$$$$

all: info mkdirs ${hfile} $(BINARY)

info:
	@echo "* Building to ${builddir}"
	@echo "* Compiler options:  $(COMPILEROPTIONS)" 
	@echo "* Assembler options: $(ASSEMBLEROPTIONS)" 
	@echo "* Linker options:    $(LINKEROPTIONS)" 
	@echo "* Linker script:     ${LINKERSCRIPT}"
	
mkdirs:
	-@${MKDIR} ${builddir}
	
clean:
	@echo ... removing build files in ${builddir}
	@rm -f ${builddir}/*.o
	@rm -f ${builddir}/*.d
	@rm -f ${builddir}/*.out
	@rm -f ${builddir}/*.hex
	@rm -f ${builddir}/*.elf
	@rm -f ${builddir}/*.map
	@rm -f ${builddir}/*_disasm.s
	@rm -f _stm32flash.script

install: binlen = $(shell stat -c%s ${builddir}/${BINARY}.out)
install: $(BINARY)
	@echo "binary length of install is ${binlen} bytes.."
	@sed 's/BUILDFILE/${builddir}\/${BINARY}.out/;s/LENGTH/${binlen}/' stm32flash.script > _stm32flash.script
	@echo "script _stm32flash.script" | nc localhost $(GDB_PORT)
	@${RM} _stm32flash.script

debug: $(BINARY)
	@${GDB} ${builddir}/${BINARY}.elf -x $(DBG_SCRIPT)
	
${hfile}: ${CONFIG_MAKE}
	@echo "* Generating config header ${hfile}.."
	@echo "// Auto generated file, do not tamper" > ${hfile}
	@echo "#ifdef INCLUDE_CONFIG_HEADER" >> ${hfile}
	@echo "#ifndef _CONFIG_HEADER_H" >> ${hfile}
	@echo "#define _CONFIG_HEADER_H" >> ${hfile}
	@sed -nr 's/([^ \t]*)?[ \t]*=[ \t]*1/#define \1/p' ${CONFIG_MAKE} >> ${hfile}
	@echo "#endif" >> ${hfile}
	@echo "#endif" >> ${hfile}

build-info:
	@echo "*** INCLUDE PATHS"
	@echo "${INC}"
	@echo "*** SOURCE PATHS"
	@echo "${CPATH}"
	@echo "*** ASSEMBLY PATHS"
	@echo "${SPATH}"
	@echo "*** SOURCE FILES"
	@echo "${CFILES}"
	@echo "*** ASSEMBLY FILES"
	@echo "${SFILES}"
	@echo "*** FLAGS"
	@echo "${FLAGS}"
	
ONOFF = 1 0
OFFON = 0 1
flash-sizes:
	@${CC} --version | head -n 1
	@echo Optimizer flags: $(COMPILER_OPTIMIZE_FLAGS)
	@echo
	@echo "|READ_ONLY|SINGLETON|CACHE|IX_MAP|TEMPORAL_FD_CACHE|MAGIC| Binary size |"
	@echo "|---------|---------|-----|------|-----------------|-----|-------------|"
	@for rdonly in $(ONOFF); do \
	for singleton in $(ONOFF); do \
	for cache in $(OFFON); do \
	for ix_map in $(OFFON); do \
	for temporal_cache in $(OFFON); do \
	for magic in $(OFFON); do \
	\
        $(MAKE) clean > /dev/null; \
		$(MAKE) -s GC_SECTION=0 SPIFFS_FLAGS="\
            -DSPIFFS_SINGLETON=$$singleton \
            -DSPIFFS_CACHE=$$cache \
            -DSPIFFS_CACHE_WR=$$cache \
            -DSPIFFS_READ_ONLY=$$rdonly \
            -DSPIFFS_USE_MAGIC=$$magic \
            -DSPIFFS_USE_MAGIC_LENGTH=$$magic \
            -DSPIFFS_TEMPORAL_FD_CACHE=$$temporal_cache \
            -DSPIFFS_IX_MAP=$$ix_map \
            " > /dev/null; \
        spiffsize=`python elfspy.py ${builddir}/${BINARY}.elf -r FLASH -p /src/spiffs | tail -n 1 | sed 's/FLASH[ ]*[0-9,a-f,A-F]*[\\.]*[0-9,a-f,A-F]*[ ]*[0-9]*[ ]*\([0-9]*\).*/\1/'`; \
		echo "|$$rdonly|$$singleton|$$cache|$$ix_map|$$temporal_cache|$$magic|$$spiffsize|"; \
		\
		done || exit 1; \
        done \
        done \
        done \
        done \
        done
	
	
	
############
#
# Build info
#
############

BUILD_NUMBER_LDFLAGS  = --defsym __BUILD_DATE=$$(date +'%Y%m%d')
BUILD_NUMBER_LDFLAGS += --defsym __BUILD_NUMBER=$$(cat $(BUILD_NUMBER_FILE))
