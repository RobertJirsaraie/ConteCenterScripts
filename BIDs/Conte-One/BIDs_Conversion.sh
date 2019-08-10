#!/bin/bash
#$ -N DataStorm
#$ -q ionode,ionode-lp
#$ -ckpt blcr
#$ -m e
###################################################################################################
##########################              CONTE Center 1.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This scripts coverts the raw Conte Center 1.0 data into BIDs Format and subseqent uploads the raw
files onto flywheel for back up.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module purge ; module load anaconda/2.7-4.3.1
module load fsl/6.0.1
module load flywheel/8.5.0
export PATH=$PATH:/data/users/rjirsara/flywheel/linux_amd64
export PATH=$PATH:/dfs3/som/rao_col/bin
source ~/MyPassCodes.txt
fw login ${FLYWHEEL_API_TOKEN}

##########################################################
### Upload Newly Found RawFiles to Flywheel for BackUp ###
##########################################################
ls 
for subject in $NewSubs ; do

  subid=`echo $subject | cut -d '_' -f1`
  ses=`echo $subject | cut -d '_' -f3`
  datatype=`ls /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}_*_${ses}/`

  for data in $datatype ; do

  if [ $data = "DICOMS" ]; then
    echo "Dicoms Detected for $subject"
    dicom_dir=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}_*_${ses}/${data}`
    /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-One/UploadDicoms.exp ${dicom_dir} ${subject}
  fi

  if [ $data = "PARREC" ]; then
    echo "ParRec Files Detected for $subject"
    fw_date=`fw ls "yassalab/Conte-One/${subject}" | head -n1 | awk {'print $5,$6'}`
    parrec_dir=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}_*_${ses}/${data}`
    /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-One/UploadParRecs.exp ${parrec_dir} ${subject} "${fw_date}"
  fi

  if [ $data = "NIFTIS" ]; then
    echo "Nifti Files Detected for $fw_subid"
    nifti_dir=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}_*_${ses}/${data}`
    mkdir ${nifti_dir}/${subject}/
    mv ${nifti_dir}/*.nii.gz ${nifti_dir}/${subject}/
    /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-One/UploadNiftis.exp ${nifti_dir} ${subject}
    mv ${nifti_dir}/${subject}/*.nii.gz ${nifti_dir}/
    rmdir ${nifti_dir}/${subject}/
  fi

  done
done

####################################
### Covert Dicoms To BIDs Format ###
####################################
<<SKIP
subjects=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/*/DICOMS | tr ' ' '\n' | cut -d '/' -f8 | tr '\n' ' '`

for subid in $subjects ; do

  echo 'Converting Dicoms to BIDs for '$subid
  sub=`echo $subid | cut -d '_' -f1`
  ses=`echo $subid | cut -d '_' -f2`
  Dicoms=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}/DICOMS
  Residual=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}/Residual
  mkdir -p $Residual

  dcm2bids -d $Dicoms -p ${sub} -s ${ses} -c \
  /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-One/config_Conte-One.json \
  -o ${Residual} --forceDcm2niix --clobber

done
SKIP
