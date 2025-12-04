#!/bin/bash


start_time=$(date +%s)

echo " --> Going to USB"
cd /Volumes/Data2024/

month=`date +%b`

year=`date +%y`

echo " --> Creating Month docco $month and $year"
timeSec=2

DOCCO='Documents-$month-20$year'

if [ ! -d ${DOCCO} ]; 
then
    mkdir Documents-$month-20$year
    mkdir Documents-$month-20$year/00-kube-shells-00
    mkdir Documents-$month-20$year/00-kube-shells-00/01-kube
    mkdir Documents-$month-20$year/00-kube-shells-00/02-ssh
    mkdir Documents-$month-20$year/00-kube-shells-00/03-shells
    mkdir Documents-$month-20$year/00-kube-shells-00/04-git
    mkdir Documents-$month-20$year/00-kube-shells-00/05-aws
    mkdir Documents-$month-20$year/Desktop
    mkdir Documents-$month-20$year/Pictures
    mkdir Documents-$month-20$year/Movies
    mkdir Documents-$month-20$year/ZZZ-SOFTWARE
else 
    echo " --> Folder exists"
fi

echo " --> Going to Docs"
cd ~/Documents
sleep $timeSec

echo " --> cp .kube config "
cp -R ~/.kube  /Volumes/Data2024/Documents-$month-20$year/00-kube-shells-00/01-kube
cp ~/.kube/*.txt /Volumes/Data2024/Documents-$month-20$year/00-kube-shells-00/01-kube
cp ~/.kube/*.crt /Volumes/Data2024/Documents-$month-20$year/00-kube-shells-00/01-kube
sleep $timeSec

echo " --> cp .ssh "
cp -R ~/.ssh  /Volumes/Data2024/Documents-$month-20$year/00-kube-shells-00/02-ssh
sleep $timeSec

echo " --> cp shells "
cp -R ~/.aliases  /Volumes/Data2024/Documents-$month-20$year/00-kube-shells-00/03-shells
cp -R ~/.bashrc  /Volumes/Data2024/Documents-$month-20$year/00-kube-shells-00/03-shells
cp -R ~/.zshrc  /Volumes/Data2024/Documents-$month-20$year/00-kube-shells-00/03-shells
sleep $timeSec

echo " --> cp git config "
cp -R ~/.gitconfig  /Volumes/Data2024/Documents-$month-20$year/00-kube-shells-00/04-git
cp -R ~/.gitconfig-huit  /Volumes/Data2024/Documents-$month-20$year/00-kube-shells-00/04-git
cp -R ~/.gitconfig-personal  /Volumes/Data2024/Documents-$month-20$year/00-kube-shells-00/04-git
cp -R ~/.gitconfig-work  /Volumes/Data2024/Documents-$month-20$year/00-kube-shells-00/04-git
sleep $timeSec

echo " --> cp .aws "
cp -R ~/.aws  /Volumes/Data2024/Documents-$month-20$year/00-kube-shells-00/04-aws
sleep $timeSec

echo " --> cp passwords "
cp -R ~/Passwords.kdb*  /Volumes/Data2024/Documents-$month-20$year/00-kube-shells-00/
sleep $timeSec

echo " --> Copying 00-docs"
cp -R 00-docs-00 /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copying 00-personal"
cp -R 00-personal-00 /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copying 00-USEFUL"
cp -R 00-USEFUL* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copying 1-PROD*"
cp -R 1-PROD* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copying 2-LZPROD*"
cp -R 2-LZPROD* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copying 3-QA"
cp -R 3-QA* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copying 4-DEV"
cp -R 4-DEV* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copying 5-SANDBOX"
cp -R 5-SAND* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copying A*"
cp -R A* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copying B*"
cp -R B* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copying C*"
cp -R C* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copying D*"
cp -R D* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

# echo " --> Copying 0 txts"
# cp -R 0*.txt /Volumes/Data20$year/Documents-$month-20$year/
# sleep $timeSec

echo " --> Copy DEMO"
cp -R DEMOS /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy E*"
cp -R E* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy F*"
cp -R F* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy GRA*"
cp -R GRA* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy H*"
cp -R H* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy ISTIO"
cp -R ISTIO* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy J*"
cp -R J* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy K*"
cp -R K* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy L*"
cp -R L* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy N*"
cp -R N* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy O*"
cp -R O* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy P*"
cp -R P* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy RKE"
cp -R RKE* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy P*"
cp -R S* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy S*"
cp -R S* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy T*"
cp -R T* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy W*"
cp -R W* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy Zoom"
cp -R Zoom* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy zz-apps-zzz"
cp -R zz-apps-zz* /Volumes/Data2024/Documents-$month-20$year/
sleep $timeSec

echo " --> Copy ZZZ-Software"
cp -R ZZZ-SOFTWAREZ/rebuild-apps/* /Volumes/Data2024/Documents-$month-20$year/ZZZ-SOFTWARE
sleep $timeSec

echo " ###>> Going to Pictures"
cd ~/Pictures
sleep $timeSec

echo " --> Copy 00-BOYZ
cp -R 00-BOY* /Volumes/Data2024/Documents-$month-20$year/Pictures
sleep $timeSec

echo " --> Copy 00-oteemo"
cp -R 00-oteemo* /Volumes/Data2024/Documents-$month-20$year/Pictures
sleep $timeSec

echo " --> Copy 00-personal"
cp -R 00-personal* /Volumes/Data2024/Documents-$month-20$year/Pictures
sleep $timeSec

echo " --> Copy Background"
cp -R Background* /Volumes/Data2024/Documents-$month-20$year/Pictures
sleep $timeSec

echo " --> Copy CICD"
cp -R CICD* /Volumes/Data2024/Documents-$month-20$year/Pictures
sleep $timeSec


echo " --> Copy HARVARD"
cp -R HARVARD* /Volumes/Data2024/Documents-$month-20$year/Pictures
sleep $timeSec

echo " --> Copy ISTIO"
cp -R ISTIO* /Volumes/Data2024/Documents-$month-20$year/Pictures
sleep $timeSec

echo " ###>> Going to Movies"
cd ~/Movies

echo " --> Going to 00-personal"
cp -R 00-personal* /Volumes/Data2024/Documents-$month-20$year/Movies
sleep $timeSec

echo " --> Going to 07"
cp -R 0723* /Volumes/Data2024/Documents-$month-20$year/Movies
sleep $timeSec

echo " --> Going to 08"
cp -R 0823* /Volumes/Data2024/Documents-$month-20$year/Movies
sleep $timeSec

echo " --> Going to 09"
cp -R 09* /Volumes/Data2024/Documents-$month-20$year/Movies
sleep $timeSec

echo " --> Going to HARVARD"
cp -R HAR* /Volumes/Data2024/Documents-$month-20$year/Movies
sleep $timeSec

echo " --> Going to HUMOUR"
cp -R HUM* /Volumes/Data2024/Documents-$month-20$year/Movies
sleep $timeSec

echo " --> Going to LEARNING"
cp -R LEARNING* /Volumes/Data2024/Documents-$month-20$year/Movies
sleep $timeSec

echo " ###>> Going to Desktop"
cd ~/Desktop

echo " --> Going to Desktop"
cp -R * /Volumes/Data2024/Documents-$month-20$year/Desktop
sleep $timeSec

end_time=$(date +%s)

elapsed_time=$(( end_time - start_time ))

# Convert elapsed time to minutes and seconds
elapsed_minutes=$(( elapsed_time / 60 ))
elapsed_seconds=$(( elapsed_time % 60 ))

# Output the result
echo "Elapsed time: $elapsed_minutes minutes and $elapsed_seconds seconds"
