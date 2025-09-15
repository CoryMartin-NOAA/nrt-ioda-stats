#!/bin/bash

export HOMEobsforge=/lfs/h2/emc/da/noscrub/cory.r.martin/sep2025/obsforge/obsforge
export COMIN_obsforge=/lfs/h2/emc/da/noscrub/cory.r.martin/sep2025/obsforge/com/obsforge
export COMOUT_stats=/lfs/h2/emc/da/noscrub/cory.r.martin/sep2025/obsforge/com/stats
export DATAROOT=/lfs/h2/emc/stmp/cory.r.martin/nrt_ioda_stats
export HOMEnrtiodastats=/lfs/h2/emc/da/noscrub/cory.r.martin/sep2025/nrt-ioda-stats
machine=wcoss2
run=gdas
obtypes="prepbufr_adpsfc"

# define other variables
IODAEXE=$HOMEobsforge/build/bin/ioda-stats.x

# load modules
module use $HOMEobsforge/modulefiles
module load obsforge/$machine

# get the current cycle
# we will assume we are lagging by 6.5 hours
export PDY=$(date -u -d '6 hours ago' +%Y%m%d)
export cyc=$(date -u -d '6 hours ago' +%H)
PDYb=$(date -u -d '9 hours ago' +%Y%m%d)
cycb=$(date -u -d '9 hours ago' +%H)
export PDY=20250915
export cyc=06
PDYb=20250915
cycb=03

YYYY=$(echo $PDYb | cut -c1-4)
MM=$(echo $PDYb | cut -c5-6)
DD=$(echo $PDYb | cut -c7-8)

# create a temporary runtime directory
DATA=$DATAROOT/${run}.${PDY}/${cyc}
mkdir -p $DATA
cd $DATA || exit 8

# cat the header for the YAML file
cat > $DATA/ioda_stats.yaml << EOF
time window:
  begin: ${YYYY}-${MM}-${DD}T${cycb}:00:00Z
  length: PT6H
  bound to include: begin
obs spaces:
EOF

# loop over specified ob types
for obtype in $obtypes; do
    # copy files from obsforge
    cp $COMIN_obsforge/${run}.${PDY}/${cyc}/atmos/${run}.t${cyc}z.${obtype}.nc $DATA/${obtype}_in.nc
    if [ $? -ne 0 ]; then
        echo "No ${obtype} data for ${run} at ${PDY} ${cyc}Z"
        continue
    fi
    # cat the YAML file to the full YAML file
    cat $HOMEnrtiodastats/config/${obtype}.yaml >> $DATA/ioda_stats.yaml
done

# run ioda-stats
$IODAEXE $DATA/ioda_stats.yaml
if [ $? -ne 0 ]; then
    echo "ioda-stats failed for ${run} at ${PDY} ${cyc}Z"
    exit 8
fi

# copy output to COMOUT
mkdir -p $COMOUT_stats/${run}.${PDY}/${cyc}/products/atmos/anlmon/
cp $DATA/*_out.nc $COMOUT_stats/${run}.${PDY}/${cyc}/products/atmos/anlmon/.

exit 0
