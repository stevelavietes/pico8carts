all: dead_mans_slope_minified.p8

dead_mans_slope_minified.p8: dead_mans_slope.p8
	@cp dead_mans_slope.p8 dead_mans_slope_minified.p8
	@# wc -l dead_mans_slope_minified.p8
	@# Remove leading and trailing whitespace
	@sed -i bak '8,$$s/^[[:blank:]]*//;s/[[:blank:]]*$$//' dead_mans_slope_minified.p8
	@# Remove all comments
	@sed -i bak '8,$$s:--.*$$::g' dead_mans_slope_minified.p8
	@# Delete empty lines
	@sed -i bak '/^$$/d' dead_mans_slope_minified.p8
	@# wc -l dead_mans_slope_minified.p8
	@echo "Wrote: dead_mans_slope_minified.p8"

clean:
	rm -f dead_mans_slope_minified.p8
