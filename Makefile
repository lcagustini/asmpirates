all:
	mkdir -p bin
	/opt/devkitpro/devkitARM/bin/arm-none-eabi-gcc -mthumb-interwork -specs=gba.specs src/main.s -o bin/main.o -g
	/opt/devkitpro/devkitARM/bin/arm-none-eabi-objcopy -O binary bin/main.o main.gba

run: all
	mgba main.gba -5

clean:
	rm -rf bin main.gba main.sav
