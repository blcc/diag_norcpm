function read_obs_sst_fram_monthly(datadir[1]:string,varname[1]:string,ybe[2]:integer)
begin
    ;; read monthly sst/sic data on fram
    ;; datadir/YYYY_MM.nc
    ;; ex.
    ;;      /cluster/projects/nn9039k/NorCPM/Obs/SST/NOAA/1981_12.nc
    ;;      /cluster/projects/nn9039k/NorCPM/Obs/SST/HADISST/1870_01.nc
    ;;      /cluster/projects/nn9039k/NorCPM/Obs/SST/HADISST2-1850-2010/2006.nc , ensemble
    ;;

    yb = min(ybe)
    ye = max(ybe)
    years = ispan(yb,ye,1)
    ny = ye-yb+1

    ;; check datadir
    if(.not. isfilepresent(datadir+"/"+min(ybe)+"_01.nc"))
        print("obs data not found in "+datadir)
        return False
    end if

    ;; check data files
    ;;;; file names
    fns = ""
    do y = 0, ny-1
    do m = 1, 12
        yyyy_mm = years(y)+"_"+sprinti("%2.2d",m)+".nc"
        fns := array_append_record(fns,yyyy_mm,0)
    end do
    end do
    fns := fns(1:)

    ;; check filename present
    missingFile = False
    do i = 0, ny*12-1
        if(.not.isfilepresent(datadir+"/"+fns(i)))then
            print("missing data file: "+datadir+"/"+fns(i))
            missingFile = True
        end if
    end do
    if(missingFile)then
        print("data file(s) not found.")
        return False
    end if

    ;; read file
    if(.not.ismissing(str_match(datadir,"HADISST2")))then
        print("HADISST2 not support yet")
        return False
    end if
    fs = addfiles(datadir+"/"+fns,"r")
    var = fs[:]->$varname$
    return var
end

;; test
;var = read_obs_sst_fram_monthly("/cluster/projects/nn9039k/NorCPM/Obs/SST/NOAA/","sst",(/1990,1991/))
;var = read_obs_sst_fram_monthly("/cluster/projects/nn9039k/NorCPM/Obs/SST/HADISST/","sst",(/1990,1991/))
;var = read_obs_sst_fram_monthly("/cluster/projects/nn9039k/NorCPM/Obs/SST/HADISST2/","sst",(/1990,1991/))
;printVarSummary(var)
