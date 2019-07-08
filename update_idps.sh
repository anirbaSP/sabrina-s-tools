#!/bin/sh
# -----------------------------------------------------------------------------
# [Author] Pei Sabrina Xu (2019), adapted from Albert Yang
# ----------------------------------------------------------------------------

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

show_help () {
   echo "Usage:"
}

# Initialize our own variables:
verbose=0

while getopts "h?vc" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  verbose=1
        ;;
    c)  rm -rf $HOME/Applications/idps
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift
# TODO: use 'echo -ne' and 'echo "...\r"' to replace debug script [http://linuxcommand.org/lc3_man_pages/echoh.html]


# Check if ssh key is registered on github
ssh -T git@github.com
while [ $? -eq 255 ]; do
   echo "[Script] Please create/add ssh key to the github before continue [https://help.github.com/en/articles/checking-for-existing-ssh-keys]"
   read -p "Press [Enter] key to once this is done..."
   ssh -T git@@github.com
done


# Get required paths
read -e  -p "[Script] Select IDPS installation location: " -i "$HOME/Applications/idps" IDPS_PATH
# IDPS_PATH=${IDPS_PATH:-$HOME/Applications/idps}
mkdir -p $IDPS_PATH
read -e -p "[Script] Provide Anaconda3 location: " -i "$HOME/Applications/anaconda3" ANACONDA_DIR

# install IDPS
cd $IDPS_PATH
IDPS_DIR=$(find $PWD -iname "Inscopix Data Processing.linux")
if [ -d "$IDPS_DIR" ]; then
   read -p "  [Script/idps] $IDPS_DIR already exists, do you want to continue install the latest available version? (y/n)" CONT
   if [ "$CONT" = "y" ]; then
      continue;
   else
      exit 0;
   fi
fi
echo "[Script] Installing idps..."
# use guest login (shouldn't)
echo "  [DEBUG][Script/idps] download"
wget http://teamcity.inscopix.com:8111/httpAuth/repository/downloadAll/Mosaic2_NightlyLinux/latest.lastSuccessful?guest=1 -O ./idps.zip
echo "  [DEBUG][Script/idps] unzip + rm + chmod"
unzip idps.zip
rm idps.zip
chmod +x *.sh
echo "  [Script/idps] Press q if you see --More--"
echo -e "yn" | ./Inscopix\ Data\ Processing\ 1.2.1.sh
echo "  [Script/idps] register"
IDPS_DIR=$(find $PWD -iname "Inscopix Data Processing.linux")
# TODO: take care of the case that more than one versions of idps exist
# create isxenv conda environment
API_PATH=$IDPS_DIR/Contents/API/Python/
echo "  [Script/idps] create isxenv environment"
ISXENV_PATH=$ANACONDA_DIR/envs/isxenv
if [ -d "$ISXENV_PATH" ] ; then
   read -p "  [Script/idps] $ISXENV_PATH already exists, do you want to overwrite it? (y/n)" OVERWRITE
   if [ "$OVERWRITE" = "y" ]; then
      rm -rf $ISXENV_PATH
      conda env create -f "$API_PATH/isx/environment.yml" -n isxenv
   fi
fi
echo $API_PATH > $ANACONDA_DIR/envs/isxenv/lib/python3.6/site-packages/inscopix.pth

ISXANAENV_PATH=$ANACONDA_DIR/envs/isxanaenv
if [ -f "$ISXANAENV_PATH" ] ; then
   echo $API_PATH > $ANACONDA_DIR/envs/isxanaenv/lib/python3.6/site-packages/inscopix.pth
fi

# 3. VERIFICATION
echo -e "\n"
echo "[Script] VERIFICATION"
echo "  [Script/idps] activate isxenv"
source activate $ISXENV_PATH  
python -c "import isx"
if [ $? -eq 1 ]; then
   echo "  [Script] IDPS not imported"
else
   echo "  [Script] idps success"
fi

echo -e "\n"
echo "IDPS is installed at [$IDPS_PATH]"
read -p "Press [Enter] key to quit..."
