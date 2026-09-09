PROFILE  := archiso/slate
WORK_DIR := work
OUT_DIR  := out

.PHONY: build clean

build:
	sudo mkarchiso -v -w $(WORK_DIR) -o $(OUT_DIR) $(PROFILE)

clean:
	sudo rm -rf -- $(WORK_DIR) $(OUT_DIR)
