#!/usr/bin/bash

# written ??? by remy
# updated 2021-01-28 by mza
# last updated 2021-09-04 by mza

# this script sets up the digital Cadence design tools. It currently handles:
#     Xcelium (digital simulator)
#     Genus   (digital synthesis)
#     Innovus (digital layout)
#     Stratus (high-level synthesis)
#     Liberate (library generation)

# setup symlinks so this file uses latest version that works on this server
XCELIUM=xcelium/xcelium
INCISIVE=incisive/incisive
GENUS=genus/genus
INNOVUS=innovus/innovus
STRATUS=stratus/stratus
LIBERATE=liberate/liberate
CONFORMAL=conformal/conformal
JASPER=jasper/jasper
JOULES=joules/joules
TEMPUS=tempus/tempus

# hardcode versions where necessary:
#XCELIUM=xcelium/XCELIUM1809
#INCISIVE=incisive/INCISIVE-15.20.012
#INCISIVE=incisive/INCISIVE-15.20.086
#GENUS=genus/GENUS-19.14.000-ISR4
#INNOVUS=innovus/INNOVUS181
#STRATUS=stratus/STRATUS-20.11.100
#LIBERATE=liberate/LIBERATE151
#CONFORMAL=conformal/CONFRML202
#JASPER=jasper/jasper_2020.12
#JOULES=joules/JLS201
#TEMPUS=tempus/SSV202

# the OA version that we use
#OA_VERSION="22.60.s011"
OA_VERSION="22.60.052"

# the ROOT directory where we store the Cadence tools
export CADENCE_ROOT=/opt/cadence
export CDS_AUTO_64BIT="ALL"

# setup the directory to an OA installation
export OA_HOME=${CADENCE_ROOT}/${TEMPUS}/oa_v${OA_VERSION}

# check for the old IDLab /opt path
if [ -z $OLDPATH ]; then
	export OLDPATH="$PATH"
else
	PATH="$OLDPATH"
fi

# add a USER's LOCAL path to PATH so that we can find cocotb
# and other Python installed binaries
export PATH="${HOME}/.local/bin/:/opt/cadence/${INCISIVE}/tools.lnx86/bin:${PATH}"

# we now define a bunch of the standard functions to check, 
# setup, and print the digital toolsuite versions
function xcelium_check {
	XCELIUM_ROOT="$CADENCE_ROOT/$XCELIUM"
	if [ -e ${XCELIUM_ROOT} ]; then
		PATH=$PATH:$CADENCE_ROOT/$XCELIUM/tools.lnx86/bin:
		export PATH
		echo -n "                       (digital simulator)      Xcelium "
		echo $(xrun -version 2>&1 | awk '{print $3}')
	else
		echo "error:  cannot find \"XCELIUM_ROOT\"" > /dev/stderr
	fi
}

function incisive_check {
	INCISIVE_ROOT="$CADENCE_ROOT/$INCISIVE"
	if [ -e ${INCISIVE_ROOT} ]; then
		PATH=$PATH:$CADENCE_ROOT/$INCISIVE/tools.lnx86/bin:
		export PATH
		echo -n "                       (digital synthesis)     Incisive "
		echo $(imc -version | awk '{ print $2 }' | sed -e "s,:$,,")
	else
		echo "error:  cannot find \"INCISIVE_ROOT\"" > /dev/stderr
	fi
}

function genus_check {
	GENUS_ROOT="$CADENCE_ROOT/$GENUS"
	if [ -e ${GENUS_ROOT} ]; then
		PATH=$PATH:$CADENCE_ROOT/$GENUS/tools.lnx86/bin:
		export PATH
		echo -n "                       (digital synthesis)        Genus "
		echo $(genus -version 2>&1 | awk 'FNR == 2 {print $7}')
	else
		echo "error:  cannot find \"GENUS_ROOT\"" > /dev/stderr
	fi
}

function innovus_check {
	INNOVUS_ROOT="$CADENCE_ROOT/$INNOVUS"
	if [ -e ${INNOVUS_ROOT} ]; then
		PATH=$PATH:$CADENCE_ROOT/$INNOVUS/tools.lnx86/bin:
		export PATH
		echo -n "                       (digital layout)         Innovus "
		echo $(innovus -version 2>&1 | grep Innovus | awk '{print $3}')
	else
		echo "error:  cannot find \"INNOVUS_ROOT\"" > /dev/stderr
	fi
}

function stratus_check {
	STRATUS_ROOT="$CADENCE_ROOT/$STRATUS"
	if [ -e ${STRATUS_ROOT} ]; then
		PATH=$PATH:$CADENCE_ROOT/$STRATUS/tools.lnx86/bin:
		export PATH
		echo -n "                       (high-level synthesis)   Stratus "
		echo $(stratus -version 2>&1 | awk '{print $3}')
	else
		echo "error:  cannot find \"STRATUS_ROOT\"" > /dev/stderr
	fi
}

function liberate_check {
	LIBERATE_ROOT="$CADENCE_ROOT/$LIBERATE"
	if [ -e ${LIBERATE_ROOT} ]; then
	        PATH=$PATH:$CADENCE_ROOT/$LIBERATE/bin:
		#PATH=$PATH:$CADENCE_ROOT/$LIBERATE/tools.lnx86/bin:
		#PATH=$PATH:$CADENCE_ROOT/$LIBERATE/tools/bin:
		export PATH
		echo -n "                       (library generation)    Liberate "
		echo $(liberate -v 2>&1 | tail -n 1 | awk '{print $4}')
	else
		echo "error:  cannot find \"LIBERATE_ROOT\"" > /dev/stderr
	fi
}

function conformal_check {
	CONFORMAL_ROOT="$CADENCE_ROOT/$LIBERATE"
	if [ -e ${CON_ROOT} ]; then
	        PATH=$PATH:$CADENCE_ROOT/$CONFORMAL/tools.lnx86/bin:
	        PATH=$PATH:$CADENCE_ROOT/$CONFORMAL/bin:
		export PATH
		echo -n "                       (logic equivalence)     Conformal "
		echo $(liberate -v 2>&1 | tail -n 1 | awk '{print $4}')
	else
		echo "error:  cannot find \"CONFORMAL_ROOT\"" > /dev/stderr
	fi
}

function jasper_check {
	JASPER_ROOT="$CADENCE_ROOT/$JASPER"
	if [ -e ${CON_ROOT} ]; then
	        PATH=$PATH:$JASPER_ROOT/bin:
		PATH=$PATH:$JASPER_ROOT/tools.lnx86/bin:
		export PATH
		echo -n "                       (formal logic)        JasperGold "
		echo $(jg -version 2>&1 | awk '{print $1}')
	else
		echo "error:  cannot find \"JASPER_ROOT\"" > /dev/stderr
	fi

	# point JG_INSTALL to our cadence tree
	export JG_INSTALL=${JASPER_ROOT}

}

function joules_check {
	JOULES_ROOT="$CADENCE_ROOT/$JOULES"
	if [ -e ${CON_ROOT} ]; then
	        PATH=$PATH:$JOULES_ROOT/bin:
		PATH=$PATH:$JOULES_ROOT/tools.lnx86/bin:
		export PATH
		echo -n "                       (RTL power verif.)        Joules "
		echo $(joules -version 2>&1 | head -n 4 | tail -n 1 | awk '{print $8}')
	else
		echo "error:  cannot find \"JOULES_ROOT\"" > /dev/stderr
	fi
}

function tempus_check {
	TEMPUS_ROOT="$CADENCE_ROOT/$TEMPUS"
	if [ -e ${CON_ROOT} ]; then
	        PATH=$PATH:$TEMPUS_ROOT/bin:
		PATH=$PATH:$TEMPUS_ROOT/tools.lnx86/bin:
		export PATH
		echo -n "                       (timing signoff)          Tempus "
		# TEMPUS breaks bash as it fails to exit raw mode
                # when exitting after checking the version so we have to
                # manually reset the terminal after tempus
		echo $(tempus -version 2>&1 | head -n 1 | awk '{print $6}')
		#reset
		stty echo
	else
		echo "error:  cannot find \"TEMPUS_ROOT\"" > /dev/stderr
	fi
}

# run the functions to setup the tools
xcelium_check
incisive_check
genus_check
innovus_check
stratus_check
liberate_check
jasper_check
#conformal_check
#joules_check
tempus_check

# print a note about our open access version
echo "                       (open access libs)            OA ${OA_VERSION}"

# and make this available to the shell
export PATH
