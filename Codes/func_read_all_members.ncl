undef("assign_ocn_grid")
procedure assign_ocn_grid(var,ocngridfile)
begin
    if(.not.isatt(var,"coordinates"))then ;; not ocn data
        return
    end if
    if(.not.isfilepresent(ocngridfile))then ;; no ocn grid file
        print("assign_ocn_grid(): no ocn grid file: '"+ocngridfile+"'")
        return
    end if

    if (isfilepresent(ocngridfile))then ;; assign lat/lon to ocn variables
        gf = addfile(ocngridfile,"r")
        coords = var@coordinates
        if(coords .eq. "plon plat")then ;; p cell
            lon = gf->plon
            lat = gf->plat
            area= gf->parea
        end if
        if(coords .eq. "ulon ulat")then ;; u cell
            lon = gf->ulon
            lat = gf->ulat
            area= gf->uarea
        end if
        if(coords .eq. "vlon vlat")then ;; v cell
            lon = gf->vlon
            lat = gf->vlat
            area= gf->varea
        end if
        if(coords .eq. "qlon qlat")then ;; q cell
            lon = gf->qlon
            lat = gf->qlat
            area= gf->qarea
        end if
        var@lat2d = lat
        var@lon2d = lon
        var@area2d = area
    end if
end
undef("ls_monthly_nc_files")
function ls_monthly_nc_files(path,component)
begin
    ;; path is the member dir, which contains:
    ;;      path/atm/hist/*.nc
    monfix=""
    if(component.eq."ocn")then
        monfix="hm"
    end if
    if(component.eq."atm")then
        monfix="h0"
    end if

    fns = systemfunc("ls "+path+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n13") ;; only 13 month data, bad idea
    if(any(ismissing(fns)))then
        print("ls_monthly_nc_files(): no file in "+path)
        exit
    end if
    return fns
end

undef("read_all_files_var")
function read_all_files_var(fns[*]:string,varname[1]:string,ocngridfile[1]:string)
begin
    ;; assume one file per member
    ;;     not used in forecast dirs
    ;; read all var in filenames(fns)
    ;; will add a dim to left as members(fns)
    ;; assume var in fns are same dimsizes
    ;; so daily data may not useful (unless read all Jan etc.)
    ;; ocngridfile is necessary when read mpiom data

    nmem = dimsizes(fns)

    ;; get var dims
    f = addfile(fns(0),"r")
    dims = getfilevardimsizes(f,varname)
    alldims = array_append_record(nmem,dims,0)
    nalldim = dimsizes(alldims)

    ;; create var for all members
    vartype = getfilevartypes(f,varname)
    varall = new(alldims,where(vartype.eq."short","float",vartype))

    ;; read them 
    do i = 0, nmem-1
        f = addfile(fns(i),"r")
        var1t = f->$varname$
        if(vartype.eq."short")then ;; extract var from scale and offset
            var1 = short2flt(var1t)
        else
            var1 = var1t
        end if
        delete(var1t)

        ;; assign to varall, the coordinate should be assign automatically
        if(nalldim.eq.5)then ;; (member,t,z,y,x)
            varall(i,:,:,:,:) = var1
        end if
        if(nalldim.eq.4)then ;; (member,t,y,x)
            varall(i,:,:,:) = var1
        end if
        if(nalldim.eq.3)then ;; (member,y,x)
            varall(i,:,:) = var1
        end if
        if(nalldim.eq.2)then ;; (member,t)
            varall(i,:) = var1
        end if
        delete(var1)
    end do
    varall!0 = "members"

    assign_ocn_grid(varall,ocngridfile)
    return varall
end
undef("read_norcpm_forecast_members_var")
function read_norcpm_forecast_members_var(forecastdir[1],component,varname,ocngridfile)
begin
    ;; read members in forecastdir
    memberdirs = systemfunc("ls -d "+forecastdir+"/*mem??")
    nmember = dimsizes(memberdirs)
    fns = ls_monthly_nc_files(memberdirs(0),component)
    fs = addfiles(fns,"r")
    var1m = fs[:]->$varname$
    if(typeof(var1m).eq."short")then
        var1m := short2flt(var1m) ;; apply add_offset and scale_factor
        delete(var1m@valid_range)
        ;delete(var1m@actural_range)
    end if
    dim1m = dimsizes(var1m)
    ndim1 = dimsizes(dim1m)

    varall = conform_dims(array_append_record(nmember,dim1m,0),var1m,ispan(1,ndim1,1))
    delete(fns)
    delete(var1m)
    delete(fs)

    ;; read other members
    do i = 1, nmember-1
        fns = ls_monthly_nc_files(memberdirs(i),component)
        if(any(ismissing(fns)))then
            print("read_all_forecast_members_var(): no data file in "+memberdirs(i))
            exit
        end if

        fs = addfiles(fns,"r")
        var1m = fs[:]->$varname$
        if(typeof(var1m).eq."short")then
            var1m := short2flt(var1m) ;; apply add_offset and scale_factor
            delete(var1m@valid_range)
            ;delete(var1m@actural_range)
        end if
        if(any(dim1m.ne.dimsizes(var1m)))then
            print("dims mismatch in "+memberdirs(i))
            print("varall: "+str_join(dimsizes(varall),","))
            print("var1m: "+str_join(dimsizes(var1m),","))
        end if

        if(ndim1.eq.3)then ;; t,y,x
            varall(i,:,:,:) = var1m
        end if
        if(ndim1.eq.4)then ;; time,lev,y,x
            varall(i,:,:,:,:) = var1m
        end if

        delete(fns)
        delete(var1m)
    end do

    return varall
end
undef("read_norcpm_forecasts_members_var")
function read_norcpm_forecasts_members_var(forecastdirs,component,varname,ocngridfile)
begin
    ;; read all forecasts and members
    ;; 
    ncast = dimsizes(forecastdirs)
    
    ;; read 1st members for dims
    fore1 = read_norcpm_forecast_members_var(forecastdirs(0),component,varname,ocngridfile)
    dims1 = dimsizes(fore1) ;; member,y,x or member,lev,y,x
    ndim1 = dimsizes(dims1)
    if(.not.any(ndim1.eq.(/4,5/)))then
        print("read_norcpm_forecasts_members_var(): ndim1 is not support: "+ndim1)
        print("forecastdirs(0): "+forecastdirs(0))
        exit
    end if

    varall = conform_dims(array_append_record(ncast,dims1,0),fore1,ispan(1,ndim1,1))
    delete(fore1)

    ;; read other forecasts
    do i = 1, ncast-1
        fore1 = read_norcpm_forecast_members_var(forecastdirs(i),component,varname,ocngridfile)
        if(ndim1.eq.4)then ;; forecast,members,time,y,x
            varall(i,:,:,:,:) = fore1
        end if
        if(ndim1.eq.5)then ;; forecast,members,time,lev,y,x
            varall(i,:,:,:,:,:) = fore1
        end if

        delete(fore1)
    end do

    if(component.eq."ocn")then
        assign_ocn_grid(varall,ocngridfile)
    end if
    return varall
end

undef("read_noresm_members_leadseason")
function read_noresm_members_leadseason(dirs,component,vn,lead_season,ocngridfile)
begin
    ;; read var in member dirs with lead_season
    ;; return varall(members, months,lev,y,x)

    ;; lead_season=1 .and. start_ym=198610 => read months=198611,198612,198701
    ;;                                        dmonths    =    +1     +2     +3
    ;; lead_season=2 .and. start_ym=198610 => read months=198702,198703,198704
    ;;                                        dmonths    =    +4     +5     +6
    ;; assume one time per file

    nmember = dimsizes(dirs)

    monfix=""
    if(component.eq."ocn")then
        monfix="hm"
    end if
    if(component.eq."atm")then
        monfix="h0"
    end if

    ;; check first data file name in all memebers
    fn = systemfunc("ls "+dirs(0)+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n1")
    if(ismissing(fn))then
        print("read_noresm_members_leadseason(): no file in "+dirs(0))
        print("cmd: ls "+dirs(0)+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n1")
    end if
    f = addfile(fn,"r")
    t0 = f->time
    t0a = cd_calendar(t0,0) ;; should be only one value in monthly data
    delete(f)

    t0change = False
    do i = 1,nmember-1
        fn = systemfunc("ls "+dirs(i)+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n1")
        f = addfile(fn,"r")
        if(.not.all(t0a.eq.cd_calendar(f->time,0)))then
            newt0 = f->time
            if(t0 .lt. newt0)then
                t0change = True
                t0 := newt0
                t0a = cd_calendar(t0,0)
            end if
        end if
        delete(f)
    end do
    if(t0change)then
        t0s= t0a(0,0)+"-"+t0a(0,1)
        print("time not contsisant: "+fn)
        print("use "+t0s+" as first month")
    end if

    ;; parse forecast months(season) to read
    dmonths  = (/1,2,3/) +((lead_season-1)*3)
    if(component.eq."atm")then ;; wired time coordinate in atm(month+1)
        if(t0a(0,2).eq.1 .and.t0a(0,3).eq.0.and.t0a(0,4).eq.0)then
            dmonths = dmonths-1
        else
            print("check time coordinate in "+dir(0))
        end if
    end if
    ndmon = dimsizes(dmonths)
    needMM = toint(t0a(0,1))+dmonths
    needYY = needMM*0+toint(t0a(0,0))
    needYY = where(needMM.gt.12,needYY+1,needYY)
    needMM = where(needMM.gt.12,needMM-12,needMM)
    needYYMMs = needYY+"-"+sprinti("%2.2d",needMM)
    delete(dmonths)
    
    ;; create var for all members
    fn = systemfunc("ls "+dirs(0)+"/"+component+"/hist/*"+monfix+"."+needYYMMs(0)+".nc")
    f = addfile(fn,"r")
    vartype = getfilevartypes(f,vn)
    dims1 = getfilevardimsizes(f,vn)

    dims1(0) = ndmon ;; set t as dmonth
    varall = new(array_append_record(nmember,dims1,0),where(vartype.eq."short","float",vartype))
    ndim = dimsizes(dims1) +1 ;; ndim of varall

    readTime = new((/nmember,ndmon/),typeof(t0))
    ;; read data
    do m = 0, nmember-1
    do t = 0, ndmon-1
        fn = systemfunc("ls "+dirs(m)+"/"+component+"/hist/*"+monfix+"."+needYYMMs(t)+".nc")
        f = addfile(fn,"r")
        readTime(m,t) = f->time
        if(vartype.eq."short")then
            var1 = short2flt(f->$vn$)
        else
            var1 = f->$vn$
        end if

        if(ndim.eq.5)then ;; member,t=dmonth,z,y,x
            varall(m,t,:,:,:) = var1(0,:,:,:) ;; one time per file
        end if
        if(ndim.eq.4)then ;; member,t=dmonth,y,x
            varall(m,t,:,:) = var1(0,:,:) ;; one time per file
        end if
        delete(f)
        delete(var1)
    end do
    end do

    ;; check read time
    do t = 0, ndmon-1
        if (.not. all(readTime(:,t).eq.readTime(0,t)))then
            print("read_noresm_members_leadseason(): read time wrong")
            print(readTime)
        end if
    end do

    ;; assign coordinate
    varall!0 = "member"
    varall&member = ispan(1,nmember,1)
    varall!1 = "time"
    varall&time = readTime(0,:)
    varall@t0 = t0
    varall@t0units = varall&time@units
    varall@readMM = needMM
    varall@readYY = needYY
    ;; assign grid if ocn grid
    assign_ocn_grid(varall,ocngridfile)
    
    return varall
end

undef("read_noresm_forecasts_members_leadseason")
function read_noresm_forecasts_members_leadseason(forecastDirs,component,vn,lead_season,ocngridfile)
begin
    ;; read forecasts in noresm forecast members
    ;; forecastDirs are directories contain forecast members subdir
    ;; ex. forecastDirs(0)+"/"+memberDirs(0)+"/ocn/hist/"+ncfile

    ;; read data
    nforecast = dimsizes(forecastDirs)
    ;;;; 1st forecast
    memDirs = systemfunc("ls -d "+forecastDirs(0)+"/*")
    ;;;; check memDirs (TBD)
    ;;;; read first forecast
    varF1 = read_noresm_members_leadseason(memDirs,component,vn,lead_season,ocngridfile)
    t0all = varF1@t0
    t0all@units = varF1@t0units
    dims1 = dimsizes(varF1)
    dims = array_append_record(nforecast,dims1,0) 
    ndim = dimsizes(dims)
    varall = conform_dims(dims,varF1,ispan(1,ndim-1,1)) ;; f,m,dmon,z,y,x or f,m,dmon,y,x
    readMM = varF1@readMM ;; the read months of var
    sameReadMM = True

    delete(varF1)
    delete(memDirs)
    
    ;actual_range = varall@actual_range
    ;vaild_range = varall@vaild_range
    do f = 1,nforecast-1
        memDirs = systemfunc("ls -d "+forecastDirs(f)+"/*")
        varF1 = read_noresm_members_leadseason(memDirs,component,vn,lead_season,ocngridfile)
        ;; check read months
        if(any(readMM.ne.varF1@readMM))then
            print("readMM is not consistant, maybe t0 is not at same month?")
            print("1st  readMM: "+str_join(readMM,","))
            print("this readMM: "+str_join(varF1@readMM,","))
            sameReadMM = False
        end if
        ;if(isatt(varF1,"actual_range"))then
        ;    actual_range(0) := min((/varF1@actual_range(0),actual_range(0)/))
        ;    actual_range(1) := max((/varF1@actual_range(1),actual_range(1)/))
        ;end if
        ;if(isatt(varF1,"valid_range"))then
        ;    valid_range(0) := min((/varF1@valid_range(0),valid_range(0)/))
        ;    valid_range(1) := max((/varF1@valid_range(1),valid_range(1)/))
        ;end if
        if(ndim.eq.6);then
            varall(f,:,:,:,:,:) = varF1
        end if
        if(ndim.eq.5);then
            varall(f,:,:,:,:) = varF1
        end if
        t0all := array_append_record(t0all,varF1@t0,0)
        delete(varF1)
        delete(memDirs)
    end do
    t0all@calendar = "noleap"
    varall!0 = "forecast"
    varall&forecast = t0all
    if(sameReadMM)then
        varall@readMM = readMM
    else
        delete(varall@readMM)
    end if
    delete(varall@readYY)
    delete(varall@t0)
    delete(varall@t0units)

    ;varall@actural_range = actural_range
    ;varall@valid_range = valid_range
    return varall
end
