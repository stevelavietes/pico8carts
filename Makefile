all: mogulneer_minified.p8

mogulneer_minified.p8: mogulneer.p8
	@cp mogulneer.p8 mogulneer_minified.p8
	@# wc -l mogulneer_minified.p8
	@# Remove leading and trailing whitespace
	@sed -i bak 's/^[[:blank:]]*//;s/[[:blank:]]*$$//' mogulneer_minified.p8
	@# Remove all comments
	@sed -i bak 's:--.*$$::g' mogulneer_minified.p8
	@# Delete empty lines
	@sed -i bak '/^$$/d' mogulneer_minified.p8
	@# wc -l mogulneer_minified.p8
	@echo "Wrote: mogulneer_minified.p8"

clean:
	rm -f mogulneer_minified.p8
