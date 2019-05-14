
;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; MONTHS: 0
    ;; which season in yearly time series 

load "CODEDIR/mpiexm/func_read_mpiexm.ncl"
begin
    figfn = "FIGFILENAME"
    title = "TITLE"
    varname = "VARIABLE"
    component = "COMPONENT"

    case = "CASE"
    casedir = "CASEDIR"
    ybe = (/YEARBE/)
    months = (/MONTHS/)
    if(any(months .eq.0))then
        months := ispan(1,12,1)
    end if

    ccase = "CCASE"
    controldir = "CONTROLDIR"
    cybe = (/CONTROLYEARBE/)

    ;varall = read_mpiexm_TZLL(case,casedir,component,varname,ispan(min(ybe),max(ybe),1),1)
    ;varall = read_mpiexm_YMZLL(case,casedir,component,varname,ispan(min(ybe),max(ybe),1),1)
    ;varall = read_mpiexm_YZLL(case,casedir,component,varname,ispan(min(ybe),max(ybe),1),1)
    varall = read_mpiexm_season_YZLL(case,casedir,component,varname,ispan(min(ybe),max(ybe),1),months,1)
    varcon = read_mpiexm_season_YZLL(ccase,controldir,component,varname,ispan(min(cybe),max(cybe),1),months,1)

    varvar = dim_variance_n_Wrap(varall(:,0,:,:),0)
    convar = dim_variance_n_Wrap(varcon(:,0,:,:),0)
    dvar = varvar
    dvar = varvar / where(convar.eq.0,convar@_FillValue,convar)

    res = True
        res@gsnLeftString = title
        
    PLOTRES

    wks = gsn_open_wks("ps",figfn)

    plot = gsn_csm_contour_map(wks,dvar,res)

end
