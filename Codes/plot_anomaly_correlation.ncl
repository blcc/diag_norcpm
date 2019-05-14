;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; BEFOREPLOT: ;; BEFOREPLOT section, empty
;;DIAG_NORCPM; TITLE: Anomaly Correlation
;;DIAG_NORCPM; TITLELEFT: 
;;DIAG_NORCPM; TITLERIGHT: 

load "CODEDIR/func_read_all_members.ncl"
begin
    ;; Anomaly Correlation (AC)
    ;;  is a measure of the association between the 
    ;;      anomalies of (usually) gridpoint forecast and verification values.
    ;;
    ;;  Ref. Predictability and Forecast Skill in NMME
    ;;      Becker etal 2014, doi: 10.1175/JCLI-D-13-00597.1
    ;;      eq.3, but use initial forecast time as year
    ;;          and change bottom term to stddev(should be an error in paper?)
    ;;
    ;; create: 11Apr2019, pgchiu 

    ;; input from diag_norcpm
    dirs=systemfunc("ls -d FORECASTDIRS")
    vn="VARIABLE"
    component="COMPONENT"
    ocngridfile="OCNGRIDFILE"
    lead_season = LEADSEASON
    figfilename = "FIGFILENAME"

    ;; read variable in member dirs, output as (forecast,member,time,y,x)
    ;;      the time here is depend on lead_season and first simulation month
    ;;      ie. simulation start from 1989-01, and lead_season is 1
    ;;          then read time is 1989-02,1989-03,1989-04
    ;;      if lead_season is 2
    ;;          then read time is 1989-05,1989-06,1989-07
    var = read_noresm_forecasts_members_leadseason(dirs,component,vn,lead_season,ocngridfile)
    dims = dimsizes(var)
    ndim = dimsizes(dims)
    if(ndim.gt.5)then
        printVarSummary(var)
        print("variable over 5 dims is not support yet.")
        print("assume data is (forecast,member,dmonth,y,x)")
        print("exit...")
        exit
    end if

    ;; some meta data
    readMM = var@readMM
    monNames = (/"0","J","F","M","A","M","J","J","A","S","O","N","D"/)
    readMonName = str_concat(monNames(readMM))

    ;; homogeneous predictability
    ;;     use forecast index as year (j)
    ;;;; set first member is proxy observation at all forecast
    proxyObs = 0
    modelEns = ispan(1,dims(1)-1,1)
    nEns = dimsizes(modelEns)

    ;; seasonal var (forecast,member,y,x)
    varSea = dim_avg_n_Wrap(var,2)
    dimsSea = dimsizes(varSea)

    ;;;; get climate (average along forecast index)(member,y,x)
    varSeaClm = dim_avg_n_Wrap(varSea,0)

    ;;;; get anomaly (substract varClm)(forecast,member,y,x)
    varSeaAno = varSea ;; create array with coordinate
    varSeaAno = varSea - conform_dims(dimsSea,varSeaClm,(/1,2,3/))

    ;;;; AChom at each grid, along forecast(as year)
    AChom = varSeaAno(0,modelEns,:,:)  ;; create array with no attrs.
    AChom@long_name = "Anomaly correlation"
    AChom@units = ""
    delete(AChom@valid_range)
    delete(AChom@actual_range)
    
    lower_righ = dim_stddev_n(varSeaAno(:,proxyObs,:,:),0)
    do m = 0, nEns-1
        upper_term = dim_avg_n(varSeaAno(:,modelEns(m),:,:) * varSeaAno(:,proxyObs,:,:),0)
        lower_left = dim_stddev_n(varSeaAno(:,modelEns(m),:,:),0)

        lower_term = lower_left * lower_righ
        lower_term = where(lower_term.eq.0,lower_term@_FillValue,lower_term)
        AChom(m,:,:) = upper_term / lower_term
        delete(upper_term)
        delete(lower_left)
        delete(lower_term)
    end do


        AChom = AChom*100

    ;; define color table with paper figure 8
    ;; rgb
    color_map =(/(/255,255,255/), \
                (/  0,  0,  0/), \
                (/255,255,255/), \
                (/255,250,169/), \
                (/255,231,120/), \
                (/200,255,190/), \
                (/150,245,141/), \
                (/ 80,240, 80/), \
                (/220,220,254/) , \
                (/160,140,255/), \
                (/112, 96,220/), \
                (/ 61, 40,181/) /)

    cmap = tofloat(color_map)/255.



    ;; plot AChom figure  
    res = True
        res@cnFillOn    = True
        res@cnLinesOn   = False
        res@cnLevelSelectionMode = "ExplicitLevels"
        res@cnLevels = fspan(10,90,9)
        res@tiMainString  = "TITLE"
        if("TITLELEFT" .eq. "")then
            res@gsnLeftString = readMonName
        else
            res@gsnLeftString = "TITLELEFT"
        end if
        if("TITLERIGHT" .eq. "")then
            res@gsnRightString = "leadSeason="+lead_season
        else
            res@gsnRightString = "TITLERIGHT"
        end if

        res@mpCenterLonF = 180.

    if(isatt(AChom,"lat2d"))then ;; convert coords to 2d, which was reshaped to 1d in netcdf file
        lat2d := onedtond(AChom@lat2d,dimsizes(AChom(0,:,:)))
        lon2d := onedtond(AChom@lon2d,dimsizes(AChom(0,:,:)))
        AChom@lat2d := lat2d
        AChom@lon2d := lon2d
    end if

    BEFOREPLOT

    wks = gsn_open_wks("ps",figfilename)
    gsn_define_colormap(wks,cmap)
    plot = gsn_csm_contour_map(wks,AChom(0,:,:),res)

end

