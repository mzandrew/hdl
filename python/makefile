
default:
	@if [ ! -e pypath ]; then python3 -m venv pypath; . ./pypath/bin/activate; pip install pygame spidev adafruit-blinka; fi
	@cd print_string; ../pypath/bin/pip install .
	@cd fastgpio; ../pypath/bin/pip install .

