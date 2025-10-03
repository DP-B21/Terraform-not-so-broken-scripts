IMPORTANT
##############

REMEMBER TO RUN "terraform init" IN THE SAME FILE DIRECTORY AS THE FILES AND "terraform plan" BEFORE HITTING "terraform apply". USE DEBUG AND LOG FILES FOR GUIDANCE

When creating a vm in proxmox there are certain parameters that need to be set for the execution of the script:

In the file provider.tf, the naming for the "proxmox_vm_qemu" resource and vm need to only contain alphanumeric and dashes (not underscores), otherwise it will cause error 400.
In the file provider.tf, variables are set to sensitive so that they are not shown when running certain commands such as "plan" and "apply", this can also be used when any type of sensitive information can be displayed.
A main.tf file is not a requirement. For this project as long you use all 3 files in the same directory, it should be fine.
###############

This script is split into 3 files for better management of the parameters, causing less confusion rather than having one file with all the variables and parameters inside and for easier debugging.

------------------------------------------
KMOWN PROBLEMS

Sometimes the vm may lock upon creation and a restart of the vm should fix the problem.
At times, the script times out or doesn't create the vm (unlikely). Just create a new one.
If the script times out sometimes the main clonable vm is stuck in a cloning loop and doesn't allow the deletion of the clone vm, to fix this just shutdown the clonable vm.

*SECRET TIP*

when producing log files, paste the output to https://beautifier.io/ for better identation and easier readability 
-------------------------------------------------

This README file will be constantly updated to fix any future problems.
