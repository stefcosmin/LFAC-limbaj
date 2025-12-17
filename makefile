# I set it to g++12 cuz debian is retarded. I have to versions of g++ on it and for some reason
# I compile with g++13 but tries to access g++12 library files(.so)

ifeq ($(USER),"andrei")
	COMPILER=g++-12
else
	COMPILER=g++
endif

FILE=limbaj
TARGET=compiler
SRC_DIR=src



GENERATED_DIR=./build/generated/

all: clean gen debug

clean:
	@echo "--- Cleaning up... "
	@rm -f lex.yy.c
	@rm -f $(FILE).tab.c
	@rm -f $(FILE).tab.h
	@rm -f $(TARGET)
	@echo "--- Done!"
gen:
	@bison -d $(SRC_DIR)/$(FILE).y -Wcounterexamples
	@flex $(SRC_DIR)/$(FILE).l 
debug: 
	@echo "--- Building in debug..."
	$(COMPILER) -std=c++17 -g lex.yy.c  $(FILE).tab.c -o $(TARGET)
	@echo "--- Done building '$(TARGET)' in debug mode!"
release:
	@echo "--- Building in release..."
	@$(COMPILER) -std=c++17 -o2 lex.yy.c  $(FILE).tab.c -o $(TARGET)
	@echo "--- Done building '$(TARGET)' in release mode!"


test: all
	@echo ""
	@echo ""
	@echo "--- Running test 1"
	@./$(TARGET) examples/test1
	@echo ""
	@echo ""
	@echo "--- Running test 2"
	@./$(TARGET) examples/test2
	@echo "Done!"
