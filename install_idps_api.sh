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
    c)  rm -rf $HOME/Applications/anaconda3 $HOME/Applications/idps
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
read -e -p "[Script] Select Anaconda3 installation location: " -i "$HOME/Applications/anaconda3" ANACONDA_DIR
read -e -p "[Script] Select IDPS installation location: " -i "$HOME/Applications/idps" IDPS_PATH
mkdir -p $IDPS_PATH
read -e -p "[Script] Select script working location: " -i "$HOME/git" WORK_DIR
mkdir -p $WORK_DIR

# 1. INSTALL ANACONDA3 (SILENT)
echo -e "\n"
echo "[Script] Checking Anaconda3 installation..."
which conda
if [ $? -eq 1 ]; then
   echo "[Script] Installing Anaconda 3..."
   echo "  [DEBUG][Script/anaconda] download"
   wget -O - https://www.anaconda.com/distribution/ 2>/dev/null | sed -ne 's@.*\(https:\/\/repo\.anaconda\.com\/archive\/Anaconda3-.*-Linux-x86_64\.sh\)\">64-Bit (x86) Installer.*@\1@p' | xargs wget -O ./anaconda.sh
   echo "  [DEBUG][Script/anaconda] install + rm"
   bash ./anaconda.sh -b -p $ANACONDA_DIR
   rm ./anaconda.sh
   echo "  [DEBUG][Script/anaconda] init"
   $ANACONDA_DIR/bin/conda init
   echo "  [DEBUG][Script/anaconda] source"
   source ~/.bashrc
fi
echo "[Script] Anaconda3 installed"


# install IDPS
cd $IDPS_PATH
IDPS_DIR=$(find $PWD -iname "Inscopix Data Processing.linux")
if [ -d "$IDPS_DIR" ]; then
   echo "[Script/idps] already exists, skip"
   # TODO: add overwrite
else
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
   echo "  [DEBUG][Script/idps] register"
fi
IDPS_DIR=$(find $PWD -iname "Inscopix Data Processing.linux")
# create isxenv conda environment
API_PATH=$IDPS_DIR/Contents/API/Python/
echo "  [Script/idps] create isxenv environment"
conda env create -f "$API_PATH/isx/environment.yml" -n isxenv
echo $API_PATH > $ANACONDA_DIR/envs/isxenv/lib/python3.6/site-packages/inscopix.pth


# download packages for CNMF_E
cd $WORK_DIR
echo "[Script] CNMF_E matlab..."
if [ -d "CNMF_E" ]; then
  echo "  [Script/CNMF_E] already exists, skip"
  # TODO: add overwrite
else
  echo "  [Script/CNMF_E] clone"
  git clone --recurse-submodules https://github.com/zhoupc/CNMF_E.git 
fi
echo "[Script] CNMF_E...done"

echo "[Script] isx-cnmfe-wrapper..."
if [ -d "isx-cnmfe-wrapper" ]; then
  echo "  [Script/isx-cnmfe-wrapper already exists, skip"
  # TODO: add overwrite
else
  echo "  [Script/isx-cnmfe-wrapper] clone"
  git clone --recurse-submodules https://github.com/inscopix/isx-cnmfe-wrapper.git 
fi
echo "[Script] isx-cnmfe-wrapper...done"



# 3. VERIFICATION
echo -e "\n"
echo "[Script] VERIFICATION"
conda -V
if [ $? -eq 1 ]; then
  echo "[Script] conda installation failed"
else
  echo "[Script] conda installation success"
fi
echo "  [Script/idps] activate isxenv"
source activate isxenv  
python -c "import isx"
if [ $? -eq 1 ]; then
  echo "[Script] IDPS not imported"
else
  echo "[Script] idps success"
fi
conda deactivate

echo -e "\n"
echo "Anaconda is installed at [$ANACONDA_DIR]"
echo "IDPS is installed at [$IDPS_PATH]"
read -p "Press [Enter] key to quit..."
