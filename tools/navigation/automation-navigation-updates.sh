#!/bin/bash
# # When called, the process ends.
# Args:
# 	$1: The exit message (print to stderr)
# 	$2: The exit code (default is 1)
# if env var _PRINT_HELP is set to 'yes', the usage is print to stderr (prior to $1)
# Example:
# 	test -f "$_arg_infile" || _PRINT_HELP=yes die "Can't continue, have to supply file as an argument, got '$_arg_infile'" 4
die() {
	local _ret=$2
	echo "$_re  $_ret"
	test -n "$_ret" || _ret=1
	test "$_PRINT_HELP" = yes && print_help >&2
	echo "$1" >&2
	exit ${_ret}
}

# Function that evaluates whether a value passed to it begins by a character
# that is a short option of an argument the script knows about.
# This is required in order to support getopts-like short options grouping.
begins_with_short_option() {
	local first_option all_short_options='tcanh'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_ansible_tower=
_arg_cloudforms=
_arg_cloud_automation_manager=

# Function that prints general usage of the script.
# This is useful if users asks for it, or if there is an argument parsing error (unexpected / spurious arguments)
# and it makes sense to remind the user how the script is supposed to be called.
print_help() {
	printf '%s\n' "This script will update the Cloud Pak for Multicloud Management/Automation Infrastructure navigation menu to include (and/or) Ansible Tower, Cloud Automation Manager and CloudForms navigation links."
	printf '%s\n' "- Kubectl must be installed and authenticated before script is executed."
	printf '%s\n\n' "- JQ must be installed."
	printf 'Usage: %s [-t|--ansible_tower <arg>] [-c|--cloudforms <arg>] [-a|--cloud_automation_manager <arg>] [-n|--namespace <arg>] [-h|--help]\n' "$0"
	printf '\t%s\n' "-t, --ansible_tower: <optional> Namespace"
	printf '\t%s\n' "-c, --cloudforms: CloudForms URL "
	printf '\t%s\n' "-a, --cloud_automation_manager: <optional> Namespace"
	printf '\t%s\n' "-h, --help: Prints help"
}

# The parsing of the command-line
parse_commandline() {
	while test $# -gt 0; do
		_key="$1"
		#echo "$_key -- in while"
		case "$_key" in
		-t | --ansible_tower)
			if test $# -lt 2; then
				_arg_ansible_tower="--999"
			else
				if test $2 != "-c" && test $2 != "-a"; then
					test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
					_arg_ansible_tower="$2"
					shift
				fi
			fi
			;;
		--ansible_tower=*)
			_arg_ansible_tower="${_key##--ansible_tower=}"
			;;
		-t*)
			_arg_ansible_tower="${_key##-t}"
			;;
		-c | --cloudforms)
			test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
			_arg_cloudforms="$2"
			shift
			;;
		--cloudforms=*)
			_arg_cloudforms="${_key##--cloudforms=}"
			;;
		-c*)
			_arg_cloudforms="${_key##-c}"
			;;
		-a | --cloud_automation_manager)
			if test $# -lt 2; then
				_arg_cloud_automation_manager="--999"
			else
				if test $2 != "-c" && test $2 != "-t"; then
					test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
					_arg_cloud_automation_manager="$2"
					shift
				fi
			fi
			;;
		--cloud_automation_manager=*)
			_arg_cloud_automation_manager="${_key##--cloud_automation_manager=}"
			;;
		-a*)
			_arg_cloud_automation_manager="${_key##-a}"
			;;
		-h | --help)
			print_help
			exit 0
			;;
		-h*)
			print_help
			exit 0
			;;
		*)
			_PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
			;;
		esac
		shift
	done
}

#Search for Ansible Tower route use the host as url.
find_tower() {
	svc_info_file="web-route.json"
	if test $_arg_ansible_tower == "--999"; then
		kubectl get routes ansible-tower-web-svc --namespace tower -o json >$svc_info_file
	else
		kubectl get routes ansible-tower-web-svc --namespace "$_arg_ansible_tower" -o json >"$svc_info_file"
	fi
	if [[ $? -ne 0 ]]; then
		echo "Error: Could not get route details for Ansible Tower service instance."
		exit 1
	fi
	_arg_ansible_tower=https://$(jq -r ".spec.host" "$svc_info_file")
}

#Search for Cloud Automation Manager route use the host as url.
find_cam() {
	svc_info_file="web-route.json"
	if test "$_arg_cloud_automation_manager" == "--999"; then
		kubectl get routes cam --namespace services -o json >$svc_info_file
	else
		kubectl get routes cam --namespace $_arg_cloud_automation_manager -o json >"$svc_info_file"
	fi
	if [[ $? -ne 0 ]]; then
		echo "Error: Could not get route details for Cloud Automation Manager instance."
		exit 1
	fi
	_arg_cloud_automation_manager=https://$(jq -r ".spec.host" "$svc_info_file")/cam/templates/\#!/templates
}

# Check for kubectl being installed
check_kubectl_installed() {
	echo "Checking if kubectl is installed..."
	command -v kubectl >/dev/null 2>&1 || {
		echo >&2 "kubectl is not installed... Aborting."
		exit 1
	}
	echo "kubectl is installed"
}
# Call out to MCM and import current CR into file.
import_to_navigation_file() {
	# run kubectl command
	echo "Running kubectl command to retrieve navigation items..."
	echo "*** A backup cr file is stored in ./navconfigurations.orginal"
	feedback=$(bash -c 'kubectl get navconfigurations.foundation.ibm.com multicluster-hub-nav -n kube-system -o yaml > navconfigurations.orginal' 2>&1)
	echo $feedback
	cp navconfigurations.orginal navconfigurations.yaml
	echo "Finished importing into navconfigurations.yaml"
	echo "Verifying..."
	#check if yaml file is valid
	if grep -Fxq "kind: NavConfiguration" navconfigurations.yaml; then
		echo "Navconfigurations.yaml file is valid"
	else
		echo "Failed to validate navconfigurations.yaml. Check above for errors. Ensure kubectl is authenticated."
		exit 1
	fi
}

# Look in the navigation file by id.
check_exist() {
	if grep -iq "id: $id" navconfigurations.yaml; then
		echo "$product_name navigation menu item already exists. Aborting..."
		exit 1
	fi
}

# Add navigation items to file.
add_navigation_items() {
	## add cloudforms
	if [ -n "$_arg_cloudforms" ]; then
		id="cloudforms"
		product_name="CloudForms"
		check_exist
		echo "Adding new navigation items to file..."
		cloudform_nav_item="  - id: cloudforms\n    isAuthorized:\n    - Administrator\n    - ClusterAdministrator\n    - Operator\n    label: CloudForms\n    parentId: automate\n    serviceId: mcm-ui\n    url: $_arg_cloudforms"
		awk_output="$(awk -v cloud="$cloudform_nav_item" '1;/navItems:/{print cloud}' navconfigurations.yaml)"
		echo "$awk_output" >navconfigurations.yaml
	fi
	## add ansible tower
	if [ -n "$_arg_ansible_tower" ]; then
		find_tower
		id="tower"
		product_name="Ansible Tower"
		check_exist
		tower_nav_item="  - id: tower\n    isAuthorized:\n    - Administrator\n    - ClusterAdministrator\n    - Operator\n    label: Ansible automation\n    parentId: automate\n    serviceId: mcm-ui\n    url: $_arg_ansible_tower"
		awk_output="$(awk -v tower="$tower_nav_item" '1;/navItems:/{print tower}' navconfigurations.yaml)"
		echo "$awk_output" >navconfigurations.yaml
	fi
	## add cloud automation manager
	if [ -n "$_arg_cloud_automation_manager" ]; then
		find_cam
		id="cam"
		product_name="Cloud Automation Manager"
		check_exist
		cam_nav_item="  - id: cam\n    isAuthorized:\n    - Administrator\n    - ClusterAdministrator\n    - Operator\n    label: Terraform automation\n    parentId: automate\n    serviceId: mcm-ui\n    url: $_arg_cloud_automation_manager"
		awk_output="$(awk -v cam="$cam_nav_item" '1;/navItems:/{print cam}' navconfigurations.yaml)"
		echo "$awk_output" >navconfigurations.yaml
	fi
	echo "Navigation items added to file"
}

# Update CR with augmented file.
apply_new_items() {
	echo "Updating MCM with new items..."
	feedback=$(bash -c 'kubectl apply -n kube-system -f navconfigurations.yaml' 2>&1)
	if echo $feedback | grep -q 'Error from server (NotFound): the server could not find the requested resource'; then
		echo "Failed running kubectl apply. Error from server (NotFound): the server could not find the requested resource. The kubectl version needs to be updated."
	fi
	echo "Finished updating MCM"

}

# Clean up old files
clean_up() {
	rm -f web-route.json 2>/dev/null
	rm -f navconfigurations.yaml 2>/dev/null
	rm -f navconfigurations.orginal 2>/dev/null
}
# call all the functions defined above that are needed to get the job done
parse_commandline "$@"

if [ -z "$_arg_ansible_tower" ] && [ -z "$_arg_cloudforms" ] && [ -z "$_arg_cloud_automation_manager" ]; then
	print_help
	exit 0
fi

##################################
## Begin mcm-ui cr augmentation ##
##################################
# clean up previous runs
clean_up
# check if kubectl is installed
check_kubectl_installed
# import to navigation file
import_to_navigation_file
# add cloudforms or tower to navigation menu item by updating the cr
add_navigation_items
# apply the updated cr file with new navigation items.
apply_new_items
# Install complete
echo "Success!"
##################################
## End mcm-ui cr augmentation   ##
##################################
