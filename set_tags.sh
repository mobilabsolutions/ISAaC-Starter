#!/bin/bash
#--------------------------------------------------------#
# Bash script to replace the TAGS alone in bootstrap.sh  #
# due to following GITHUB issues:                        #
#   1) https://github.com/Azure/azure-cli/issues/13659   #
#   2) https://github.com/Azure/azure-cli/issues/13170   #
#--------------------------------------------------------#
set -e
set -u

# Exit function
fairExit () {
    if [ ${?} -ne 0 ]; then
	    echo "ERROR: $1."; exit 1
	fi
    return 0
}

# Check AzCLI existance
is_azcli_exist () {
    az --version > /dev/null 2>&1 || fairExit "AzCLI not installed"
    return ${?}
}

#------#
# MAIN #
#------#
is_azcli_exist || exit 1
target_file="common-config.yaml"
req_tags=`sed '/tags/,/tfstate/!d;//d' ${target_file} | tr '\n' ' ' | sed 's/: /=/g' | sed 's/ \+ / /g' | sed 's/^ //g'` # Get key-value pairs tags between two patterns as a variable
sed "s/REQUIRED_TAGS/${req_tags}/g" bootstrap.sh > bootstrap_new.sh && chmod 755 bootstrap_new.sh  ## Direct variable substition not supported by --tags attribute in Az CLI with space separated values and multiple keys using BASH; So doing this SED way...
echo "Bootstraping..."
./bootstrap_new.sh || exit $?
rm -f bootstrap_new.sh
echo "done."
exit 0