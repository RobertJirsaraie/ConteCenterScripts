#!/bin/bash
########### 

DIR_TOOLBOX=/dfs2/yassalab/rjirsara/ConteCenterScripts/ToolBox
DIR_PROJECT=/dfs2/yassalab/rjirsara/ConteCenterScripts/Conte-One

mkdir -p ${DIR_PROJECT}/apps/fmriprep ${DIR_PROJECT}/datasets
module purge ; module load anaconda/2.7-4.3.1 singularity/3.3.0 R/3.5.3
source ~/Settings/MyPassCodes.sh
source ~/Settings/MyCondaEnv.sh
conda activate local

#######################################################
### If Missing Build the Fmriprep Singularity Image ###
#######################################################

SINGULARITY_CONTAINER=`echo $DIR_TOOLBOX/bids_apps/dependencies/fmriprep_v*.simg`
if [[ ! -f `echo $SINGULARITY_CONTAINER | cut -d ' ' -f1` && ! -z $DIR_TOOLBOX ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	echo "`basename $SINGULARITY_CONTAINER` Not Found - Building New Container "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  "
	singularity build ${SINGULARITY_CONTAINER} docker://poldracklab/fmriprep:latest
	VERSION=`singularity run $SINGULARITY_CONTAINER --version | cut -d ' ' -f2`
	LABEL=`ls $SINGULARITY_CONTAINER | sed s@'v*'@"${VERSION}"@g`
	mv $SINGULARITY_CONTAINER $LABEL 
	SINGULARITY_CONTAINER=$LABEL
else
	SINGULARITY_CONTAINER=`ls -t $SINGULARITY_CONTAINER  | head -n1`
fi

####################################################################
### If Missing Build Freesurfer License Needed For Preprocessing ###
####################################################################

FREESURFER_LICENSE=`echo $DIR_TOOLBOX/bids_apps/dependencies/freesurfer_license.txt`
if [[ ! -f $FREESURFER_LICENSE && ! -z $DIR_TOOLBOX ]] ; then
	echo ""
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  "
	echo "`basename $FREESURFER_LICENSE` Not Found - Register For One Here: "
	echo "       https://surfer.nmr.mgh.harvard.edu/registration.html       "
	echo "⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  ⚡  #  "
	printf "rjirsara@uci.edu
		40379 
		*CBT0GfF/00EU 
		FSP82KoWQu0tA \n" | grep -v local > $FREESURFER_LICENSE
fi

#############################################
### Submit FMRIPREP Jobs For New Subjects ###
#############################################

SCRIPT_FMRIPREP=${DIR_TOOLBOX}/bids_apps/fmriprep/pipeline_preproc_fmriprep.sh
TEMPLATE_SPACES="T1w MNI152NLin2009cAsym"
OPT_STOP_FIRST_ERROR=FALSE
OPT_ICA_AROMA=TRUE

if [[ -f $SCRIPT_FMRIPREP && ! -z $TEMPLATE_SPACES && -d $DIR_PROJECT ]] ; then
	for SUBJECT in `ls ${DIR_PROJECT}/bids | grep -v dataset | tr '\n' ' ' | sed s@'sub-'@''@g | grep -v 'local'` ; do
		TEMPLATE_SPACES=`echo $TEMPLATE_SPACES | sed s@' '@'#'@g`
		JOBNAME=`echo FP${SUBJECT} | cut -c1-10`
		JOBSTATUS=`qstat -u $USER | grep "${JOBNAME}\b" | awk {'print $5'}`
		OUTDIR=`echo $DIR_PROJECT/apps/fmriprep/sub-${SUBJECT}`
		WORKDIR=`echo $DIR_PROJECT/apps/fmriprep/workflows/fmriprep_wf/single_subject_${SUBJECT}_wf/`
		if [ -z `find $DIR_PROJECT/bids/sub-${SUBJECT} | grep bold.nii.gz | head -n1` ] ; then
			echo ""
			echo "######################################################"
			echo "#${SUBJECT} Does Not Have Functional Scans To Process "
			echo "######################################################"
		elif [[ ! -z "$JOBSTATUS" ]] ; then 
			echo ""
			echo "#######################################################"
			echo "#${SUBJECT} Is Currently Being Processed: ${JOBSTATUS} "
			echo "#######################################################"
		elif [[ ! -d  $WORKDIR && -d $OUTDIR ]] ; then
			echo ""
			echo "#######################################"
			echo "#${SUBJECT} Was Processed Successfully "
			echo "#######################################"
		else
			echo ""
			echo "###############################################"
			echo "Submitting FMRIPREP Job For Subect: ${SUBJECT} "
			echo "###############################################"
			qsub -N $JOBNAME $SCRIPT_FMRIPREP $DIR_TOOLBOX $DIR_PROJECT "${TEMPLATE_SPACES}" $SUBJECT $OPT_ICA_AROMA $OPT_STOP_FIRST_ERROR
		fi
	done
fi

################################################
### Curate and Create Visuals Of Head-Motion ###
################################################

SCRIPT_HEADMOTION=$DIR_TOOLBOX/bids_apps/fmriprep/visualize_motion_artifacts.R

if [[ -f $SCRIPT_HEADMOTION ]] ; then
	echo ""
	echo "####################################################"
	echo "Curating QA Data and Creating Visual of Head Motion "
	echo "####################################################"
	qsub -hold_jid ${JOBNAME} -N HEADMOTION $SCRIPT_HEADMOTION $DIR_PROJECT
fi

###########################################################
### Create Figure of Age-Related Changes in Head Motion ###
###########################################################

SCRIPT_MOTION_DEV=$DIR_PROJECT/scripts/audits/misc/fmriprep_age-motion_visual.R
FILES_QA_EPI="REST_HIPP_AMG"
FILE_DEMO_AGE="AllDataCurated"

if [[ -f $SCRIPT_MOTION_DEV ]] ; then
	echo ""
	echo "###################################################"
	echo "Creating Age-Related Changes in Head-Motion Visual "
	echo "###################################################"
	qsub -hold_jid HEADMOTION -N AGINGMOTION $SCRIPT_MOTION_DEV $DIR_PROJECT/datasets $FILES_QA_EPI $FILE_DEMO_AGE
fi

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
