#!/usr/bin/bash

# plotcan do it without any diag. cmd.

#;DIAG_NORCPM; PARALLEL_J: 12
    # as default value

dirs="INPUTDIRS"
comp="COMPONENT"
vn="VARIABLE"
outpre="OUTPUTPREFIX"
pj="PARALLEL_J"

## for monthly mean files
if [ $comp == 'ocn' ];then
    tag='.hm.'
fi
if [ $comp == 'atm' ];then
    tag='.h0.'
fi

outgridfn="${outpre}_grid.nc"
## do process
for i in $dirs ; do
    case="$(basename $i)"
    outfn="${outpre}_${case}.nc"
    infns=$(ls ${i}/${comp}/hist/*${tag}*.nc)
    if [ -f ${outfn} ];then # if old file exist, skip
        continue
    fi

    rm -f unpack_${vn}_*.nc ## clean unpacked data
    parallel -j "$pj" "ncpdq -v ${vn} -U {}  unpack_${vn}_{/}" ::: $infns  ## cannot do parallel in python subprocess, do not know why
    #for j in $infns ; do
    #    ncpdq -v ${vn} -U $j  'unpack_'${vn}'_'$(basename $j)
        #echo ncpdq processing $j
    #    unpack='unpack_'${vn}'_'$(basename $j)
    #    echo $j | parallel -j 6 ncpdq -v ${vn} -U {}  "${unpack}"
    #done
    wait
    echo "ncrcat processing ${outfn}" $(date)
    ncrcat -F -v ${vn} $(ls unpack_${vn}_*.nc|sort) "${outfn}" && rm unpack_${vn}_*.nc
done
