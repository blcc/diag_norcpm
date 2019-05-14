
function fn_mpiexm(case, casedir,component,varname,year,month,modeln)
begin
    ;; get data file name
    ;; very simple one, rewrite if need to expand it

    datadir = casedir+"/outdata/"+component+"/"
    if (component.eq."echam6")then
        yyyymm = year+sprinti("%2.2d",month)
        ;; "_echam_", "_co2_", "_trdiag_"
        fn = case+sprinti("%2.2d",modeln)+"_"+component+"_echam_"+yyyymm+".nc"
    end if
    if (component.eq."mpiom")then
        ;; "_data_2d_dm_", "_data_2d_mm_", "_data_3du_mm_", "_data_3dw_mm_", "_monitorig_ym_", "_timeser_dm_"
        fn = case+"_"+component+"_data_2d_mm_"+year+"0101_"+year+"1231.nc"
    end if

    return casedir+"/outdata/"+component+"/"+fn
end

function read_mpiexm_12m(case, casedir,component,varname,year,modeln)
begin
    ;; read 12 month monthly data 
    ;; modeln: mondel number, if echam6 is more than 1 run
    if(component.eq."echam6")then
        ;; pass now
        fn = fn_mpiexm(case, casedir,component,varname,year,ispan(1,12,1),modeln)
        print(fn)
        print("read_mpiexm_12m(): reading echam6 is not done yet")
        exit
    end if
    if(component.eq."mpiom")then
        fn = fn_mpiexm(case, casedir,component,varname,year,0,modeln)
        f = addfile(fn,"r")
        var = f->$varname$
        if(var@coordinates .eq. "lon lat")then
            var@lat2d = f->lat
            var@lon2d = f->lon
        end if
        return var
    end if
    print("read_mpiexm_12m(): unknown component: "+component)
    exit
end
function read_mpiexm_YMZLL(case, casedir,component,varname,years,modeln)
begin
    ;; frontend of read_mpiexm_12m(), read years
    ;; output var in year,month,(lev,),y,x
    print("read_mpiexm_YMZLL(): need modify metadata")
    exit ;; not done yet

    ny = dimsizes(years)
    var12m = read_mpiexm_12m(case,casedir,component,varname,years(0),modeln)
    dims12m = dimsizes(var12m)
    ndim12m = dimsizes(dims12m)
    dims = array_append_record(ny,dims12m,0)
    varall = conform_dims(dims,var12m,ispan(1,ndim12m,1))

    delete(var12m)
    do y = 1,ny-1
        var12m = read_mpiexm_12m(case,casedir,component,varname,years(y),modeln)
        varall(y,:,:,:,:)  = var12m
        delete(var12m)
    end do

    return varall
end
function read_mpiexm_TZLL(case, casedir,component,varname,years,modeln)
begin
    ;; frontend of read_mpiexm_12m(), read years
    ;; output var in time,(lev,),y,x
    print("read_mpiexm_TZLL(): need modify metadata")
    exit ;; not done yet

    ny = dimsizes(years)
    var12m = read_mpiexm_12m(case,casedir,component,varname,years(0),modeln)
    dims12m = dimsizes(var12m)
    ndim12m = dimsizes(dims12m)
    dims = dims12m
    dims(0) = dims(0)*ny
    varall = new(dims,typeof(var12m))
    time = new(dims(0),typeof(var12m&time))
    varall(0:11,:,:,:) = var12m
    time(0:11) = var12m&time
    tunits = time@units

    delete(var12m)

    do y = 1,ny-1
        var12m = read_mpiexm_12m(case,casedir,component,varname,years(y),modeln)
        varall(y*12:y*12+11,:,:,:)  = var12m
        time(y*12:y*12+11) = cd_convert(var12m&time,tunits) ;; warning:VarVarWrite: lhs has dimension name and rhs doesn't, deleting name of lhs dimension number(0)
        delete(var12m)
    end do
    varall&time = time
    return varall
end

function read_mpiexm_season_YZLL(case, casedir,component,varname,years,imonths,modeln)
begin
    ;; frontend of read_mpiexm_12m(), read yearly average
    ;; output var in year,(lev,),y,x

    if(any(imonths .eq.0))then
        months = ispan(1,12,1)
    else
        months = imonths
    end if

    ny = dimsizes(years)
    nmonth = dimsizes(months)
    var12m = read_mpiexm_12m(case,casedir,component,varname,years(0),modeln)
    dims12m = dimsizes(var12m)
    dims = dims12m
    dims(0) = ny
    varyr = new(dims,typeof(var12m))
    if (nmonth .eq.1)then
        varyr(0,:,:,:) = var12m(months-1,:,:,:)
    else
        varyr(0,:,:,:) = dim_avg_n_Wrap(var12m(months-1,:,:,:),0)
    end if
    delete(var12m)

    do y =  1,ny-1
        var12m = read_mpiexm_12m(case,casedir,component,varname,years(y),modeln)
        if (nmonth .eq.1)then
            varyr(y,:,:,:) = var12m(months-1,:,:,:)
        else
            varyr(y,:,:,:) = dim_avg_n(var12m(months-1,:,:,:),0)
        end if
        delete(var12m)
    end do
    varyr!0 = "year"
    varyr&year = years
    varyr@months = months
    return varyr
end
function read_mpiexm_YZLL(case, casedir,component,varname,years,modeln)
begin
    return read_mpiexm_season_YZLL(case, casedir,component,varname,years,ispan(1,12,1),modeln)
end

