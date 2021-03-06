
;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; MONTHS: 0

load "CODEDIR/mpiexm/func_read_mpiexm.ncl"
begin
    figfn = "FIGFILENAME"
    title = "TITLE"
    varname = "VARIABLE"
    component = "COMPONENT"
    latbe = (/LATBE/)
    lonbe = (/LONBE/)

    case = "CASE"
    casedir = "CASEDIR"
    ybe = (/YEARBE/)
    years = ispan(min(ybe),max(ybe),1)
    months = (/MONTHS/)

    ;varall = read_mpiexm_YZLL(case,casedir,component,varname,years,1)
    varall = read_mpiexm_season_YZLL(case,casedir,component,varname,ispan(min(ybe),max(ybe),1),months,1)

    ;; make time series
    if(component.eq."mpiom")then
        ;; lat2d/lon2d
        lat2d = varall@lat2d
        lon2d = varall@lon2d
        tmask = .not.ismissing(varall(0,0,:,:))  ;; 
        tmask = tmask .and. (lat2d.ge.min(latbe) .and. lat2d.le.max(latbe))
        tmask = tmask .and. (lon2d.ge.min(lonbe) .and. lon2d.le.max(lonbe))
        pi = atan(1.)*4
        wgt2d = cos(lat2d/180*pi)
        wgt2d = where(tmask,wgt2d,0)
        if(False)then ;; check nc file
            system("rm -f tmp.nc")
            f = addfile("tmp.nc","c")
            f->wgt2d = wgt2d
            f->lat2d = lat2d
            f->tmask = where(tmask,1,0)
        end if
        varts = wgt_areaave2(varall,wgt2d,0)
    else
        print("plot_annual_timeseries.ncl: other component not done yet")
        exit
    end if

    varstd = stddev(varts(:,0))
    res = True
        res@gsnLeftString = title
        res@trYMaxF =  0.85
        res@trYMinF = -0.85
        res@trXMaxF = max(years)+1
        res@trXMinF = min(years)-1
        res@vpHeightF = 0.3
        res@vpWidthF = 0.70 
        res@gsnYRefLine = (/-varstd, 0., varstd/)
        res@gsnYRefLineColors = (/"green","red","green"/)
        res@gsnYRefLineDashPatterns  = 1
        res@xyCurveDrawOrder = "PostDraw"
        res@xyLineThicknessF = 3.0
        
        res@gsnFrame = False
        res@gsnDraw = False

        textres = True
            textres@txFontHeightF = 0.01
            textres@txFontColor = "green"
            textres@txJust = "BottomLeft"
    PLOTRES

    wks = gsn_open_wks("ps",figfn)

    vartsano = varts(:,0) - avg(varts)
    plot = gsn_csm_xy(wks,years,vartsano,res)
    gsn_text(wks,plot,"stddev="+sprintf("%2.2f",varstd),years(0)+1,varstd+0.05,textres)

    draw(plot)
    frame(wks)

end
