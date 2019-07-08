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


# 2. ADD PACKAGES 

echo "[Script] Checking github repositories..."

# isx_analysis
cd $WORK_DIR
echo "[Script] isx-analysis..."
if [ -d "isx-analysis" ]; then
  echo "  [Script/isx-analysis] already exists, skip"
  # TODO: add overwrite
else
  echo "  [Script/isx_analysis] clone"
  git clone git@github.com:inscopix/isx-analysis.git
  cd isx-analysis
  echo "  [DEBUG][Script/isx-analysis] create isxanaenv"
  conda env create -f environment.yml -n isxanaenv
  echo "  [DEBUG][Script/isx_analysis] activate isxanaenv"
  conda activate isxanaenv
  echo "  [DEBUG][Script/isx_analysis] install"
  python setup.py install
fi
echo "[Script] isx-analysis...done"

# isx_rest_client
cd $WORK_DIR
echo "[Script] isx-rest-client..."
if [ -d "isx-rest-client" ]; then
  echo "  [Script/isx-rest] already exists, skip"
  # TODO: add overwrite
else
  echo "  [DEBUG][Script/isx-rest] clone"
  git clone git@github.com:inscopix/isx-rest-client.git
  cd isx-rest-client/python
  echo "  [DEBUG][Script/isx-rest] install"
  python setup.py install
  echo "[Script] isx-rest-client...done"
fi

# isx_analysis_project
cd $WORK_DIR
echo "[Script] isx-analysis-projects..."
if [ -d "isx-analysis-projects" ]; then
  echo "  [Script/isx-analysis-projects] already exists, skip"
  # TODO: add overwrite
else
  echo "  [DEBUG][Script/isx-analysis-projects] clone"
  git clone git@github.com:inscopix/isx-analysis-projects.git
  echo "[Script] isx-analysis-projects...done"
fi

# isx
cd $IDPS_PATH
echo "[Script] IDPS..."
IDPS_DIR=$(find $PWD -iname "Inscopix Data Processing.linux")
if [ -d "$IDPS_DIR" ]; then
   echo "  [Script/idps] already exists, skip"
   # TODO: add overwrite
else
   echo "  [Script/idps] Installing idps..."
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
ISX_API_PATH=$IDPS_DIR/Contents/API/Python/
echo $ISX_API_PATH > $ANACONDA_DIR/envs/isxanaenv/lib/python3.6/site-packages/inscopix.pth


# 3. VERIFICATION
echo -e "\n"
echo "[Script] VERIFICATION"
conda -V
if [ $? -eq 1 ]; then
  echo "[Script] conda installation failed"
else
  echo "[Script] conda installation success"
fi
echo "  [DEBUG][Script/isx-analysis] activate isxanaenv"
python -c "import isx"
if [ $? -eq 1 ]; then
  echo "[Script] IDPS not imported"
else
  echo "[Script] idps success"
fi
python -c "import isx_rest_client"
if [ $? -eq 1 ]; then
  echo "[Script] isx_rest_client not installed"
 else
  echo "[Script] isx_rest_client success"
fi
python -c "import isx_analysis"
if [ $? -eq 1 ]; then
  echo "[Script] isx_analysis not installed"
else
  echo "[Script] isx_analysis success"
fi


echo -e "\n"
echo "Anaconda is installed at [$ANACONDA_DIR]"
echo "IDPS is installed at [$IDPS_PATH]"
echo "isx-rest-client git code is at [$WORK_DIR/isx-rest-client]"
echo "isx-analysis git code is at [$WORK_DIR/isx-analysis]"
echo "isx-analysis-project git code is at [$WORK_DIR/isx-analysis-project]"

read -p "Press [Enter] key to quit..."
