#!/bin/sh

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
    c)  rm -rf $HOME/anaconda3 $HOME/isx_pipeline_script $HOME/IDPS
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
   ssh -T git@github.com
done


# Get required paths
read -p "[Script] Select IDPS installation location [$HOME/IDPS]: " IDPS_PATH
IDPS_PATH=$HOME/IDPS
mkdir -p $IDPS_PATH


# install IDPS
cd $IDPS_PATH
echo "[Script] Installing idps..."
# use guest login (shouldn't)
echo "  [DEBUG][Script/idps] download"
curl -v --basic --request GET http://teamcity.inscopix.com:8111/httpAuth/repository/downloadAll/Mosaic2_NightlyLinux/latest.lastSuccessful?guest=1 --output idps.zip
echo "  [DEBUG][Script/idps] unzip + rm + chmod"
unzip idps.zip
rm idps.zip
chmod +x *.sh
echo "  [Script/idps] Press q if you see --More--"
echo -e "yn" | ./Inscopix\ Data\ Processing\ 1.2.1.sh
echo "  [DEBUG][Script/idps] register"
cd "$(find . -mindepth 1 -maxdepth 1 -type d)/Inscopix Data Processing.linux/Contents/API/Python/"
echo `pwd` > $ANACONDA_DIR/envs/isx_analysis/lib/python3.6/site-packages/inscopix.pth

# 3. VERIFICATION
echo -e "\n"
echo "[Script] VERIFICATION"
conda -V
python -c "import isx"
if [ $? -eq 1 ]; then
  echo "[Script] IDPS not imported"
else
  echo "[Script] idps success"
fi

echo -e "\n"
echo "IDPS is installed at [$IDPS_PATH]"
read -p "Press [Enter] key to quit..."
