;;
;
; Description:
;
; This code allows preparation of LAM LASCO-C2 images for tomography,
; producing also JPG visualizations of them, and plots of
; intensity-versus-PA at user-provided elongations.
;
; This code calls other routines contained in this same file.
; Compile '.r lasco_mars_prep' before use, to make all routines user-available.
;
; Calling sequence example:
; lasco_mars_prep,data_dir='/data1/tomography/DATA/c2/Test_Philippe/',file_list='list.txt',/pB
;
; Explanation:
;
; Data must be stored in directory 'data_dir', where the file list
; 'file_list' contains the number of data files in the first line
; followed by all their filenames (one per line).
;
; Specify /pB or /Bk (simply for image title purposes). There is no default value.
;
; Specify a 1D array 'r0' with the elongations [Rs] at which intensity-versus-PA
; plots will be generated. Default value is r0 = [2.5,6.0].
;
; Specify suitable MINI and MAXI intensity values to be enforced accross
; the visualization of all images in the list, to share a common color scale.
; Default values are mini = 0.1, maxi = 50.
;
; Optionally, choose to /rotate to get *prep.fts images with north-up.  
;
; Optionally, define mask=[xmin,ymin,xmax,ymax] (in Rs units) to mask out a squared piece
; of the image, x being the horizontal axis and y the vertical one, with x=y=0 in the Disk center. 
;
; OUTPUT of this code: In the same directory where the data is located, the
; new data (*_preptom.fts) and list file (*_preptom.txt), as well as
; *preptom.jpg images and *preptom*eps plots, are generated.
;
; The '*_preptom.fts' images are the ones we use for tomography.
;
; Note that the ORDER of the prepared image filenames in the '*_preptom.txt'
; follows the order of the original files in list.txt, typically not chronological.
; The filenames of the &preptom.fts files produced by this tool start with
; DATE+UT. After running this tool, a chronologically ordered list can be simply
; generated with the terminal command line:
; ls *_prep.fts > list_prep.txt
;
; HISTORY:  V1.0, Alberto M. Vasquez, IAFE, September-2019.
;           V1.1, Alberto M. Vasquez, IAFE, August-2020.
;           V1.2, Alberto M. Vasquez, IAFE, September-2020.
;           V1.3, Alberto M. Vasquez, IAFE, February-2026.
;           V1.4, Alberto M. Vasquez, IAFE, May-2026.
;;

; Main routine:
pro lasco_mars_prep,data_dir=data_dir,file_list=file_list,r0=r0,mini=mini,maxi=maxi,rotate=rotate,mask=mask,pB=pB,Bk=Bk
  if not keyword_set(r0)   then r0 = [2.5,6.0]
  if not keyword_set(mini) then mini = 0.1
  if not keyword_set(maxi) then maxi = 50.

  N=0
  filename=''
  openr,1,data_dir+file_list
  readf,1,N
  new_file_list = strmid(file_list,0,strlen(file_list)-4)+'_preptom.txt'
   openw,2,data_dir+new_file_list
  printf,2,N  

  for i = 0,N-1 do begin
     readf,1,filename
     mreadfits,data_dir+filename,hdr,img
     new_filename = strmid(hdr.date_obs,0,4)+strmid(hdr.date_obs,5,2)+strmid(hdr.date_obs,8,2)+$
                    'UT'+$
                    strmid(hdr.time_obs,0,2)+strmid(hdr.time_obs,3,2)+strmid(hdr.time_obs,6,2)+$
                    '_'+$
                    strmid(filename,0,strlen(filename)-4);+'_prep.fts'

     if keyword_set(rotate) then begin
        print,'original roll angle offset: ',hdr.rollangl
        new_filename = new_filename+'_NorthUp'      
        img     = rot(img,hdr.rollangl,1,hdr.xsun_med,hdr.ysun_med,/pivot,missing=-1.e8) 
        hdr.rollangl = 0.
     endif 
     new_filename = new_filename+'_preptom.fts'
     print,'roll angle offset: ',hdr.rollangl

     prep_image_and_header,hdr=hdr,img=img
     if keyword_set(mask) then begin
        compute_image_grid,hdr=hdr,ra=ra,pa=pa,x=x,y=y,instrument='lascoc2_lam'
        u  = 1. + fltarr(hdr.naxis1)
        xa = x#u
        ya = u#y
        x1 = mask[0]
        y1 = mask[1]
        x2 = mask[2]
        y2 = mask[3]
        index = where( xa ge x1 and xa le x2 and ya ge y1 and ya le y2)
        if index[0] ne -1 then img(index) = -666.
     endif
     mwritefits,hdr,img,outfile=data_dir+new_filename
     printf,2,new_filename
     lasco_mars_inspect,hdr=hdr,img=img,r0=r0,data_dir=data_dir,filename=new_filename,mini=mini,maxi=maxi,pB=pB,Bk=Bk
  endfor
  close,/all
  return
end

;; Sub-routines follow ----------------------------------------------------------------------

pro prep_image_and_header,hdr=hdr,img=img
  ; To get DSUN [m] use the classical (not IAU 2016) value of the solar photospheric radius
  ; Rsun = 695,990 km, according to the LASCO-C2 Legacy documentation:
  ; http://idoc-lasco.ias.u-psud.fr/sitools/client-portal/doc/
  RSUN_CLASSIC_VALUE = 6.9599e8 ; m
; Assign SOHO_SUN [m] distance to DSUN:
  DSUN = hdr.R_SOHO * RSUN_CLASSIC_VALUE ; m  (from Legacy-C2 header info) 
  geocentric_sun_ephemeris = get_sun(hdr.TIME_OBS+' '+hdr.DATE_OBS)
  DISK_CENTER_LON = geocentric_sun_ephemeris[10]
  DISK_CENTER_LAT = geocentric_sun_ephemeris[11]
; Get sub-soho Carr Lat and Lon from spice kernels
  load_sunspice_soho            
  DATE = hdr.date_obs+'T'+hdr.time_obs
  SOHO_POS  = get_sunspice_lonlat(DATE, 'SOHO', system='Carrington', /meters, /degrees)
  Dsun_soho = SOHO_POS[0]       ; m  (from spice kernels)
  Lon_soho  = SOHO_POS[1]       ; deg
  Lat_soho  = SOHO_POS[2]       ; deg
  hdr  = create_struct(hdr          ,      $
                       'DSUN'       ,DSUN_SOHO ,$ ; m
                       'CRLN_OBS'   ,LON_SOHO  ,$
                       'CRLT_OBS'   ,LAT_SOHO   )
; Check that Sun-SOHO distance from Legacy and spice match reasonably well. Stop if not.
  factor = 0.98999622
  rL1 = geocentric_sun_ephemeris[ 0] * factor * 149.5978707e9 ; m
  print,'==> Relative difference between rSOHO and rL1 =',100.*(DSUN-rL1)/rL1,' %'
  if 100.*(DSUN-rL1)/rL1 ge 0.2 then begin
     print, 'which is larger than 0.2%. Is this okay?'
     stop
  endif
  
  ; Define C-named variables, even if redundant 
  IMSIZE      = double(HDR.NAXIS1)
 ;Calculation of PIXSIZE:
  Rsun_rad    = (1./hdr.R_SOHO)
  Rsun_deg    = Rsun_rad/!dtor
  Rsun_arcsec = Rsun_deg * 3600.
  Rsun_px     = hdr.rsun_pix
  px_arcsec   = Rsun_arcsec / Rsun_px
  px_arcsec_ref = 23.8 ; reference value
  percent_difference = 100.*(px_arcsec-px_arcsec_ref)/px_arcsec_ref
  print, '==> PIXSIZE =', px_arcsec,' arcsec, differing from the reference value by',percent_difference,' %'
  if percent_difference ge 0.01 then begin
     print, 'which is larger than 0.01%. Something is not correct.'
     stop
  endif

  PIXSIZE  = PX_ARCSEC_REF
  CENTER_X = HDR.XSUN_MED + 1     ; LAM uses start-by-0 convention, while the tom codes expect the start-by-1 FITS convention. 
  CENTER_Y = HDR.YSUN_MED + 1     ; LAM uses start-by-0 convention, while the tom codes expect the start-by-1 FITS convention. 
  ROLL     = HDR.ROLLANGL * (-1.) ; LAM uses for their hdr.rollangl keyword the opposite convention to the one expected by our tomography code.
  DSUN_OBS = HDR.DSUN
  OBSLAT   = HDR.CRLT_OBS 
  CARLONG  = HDR.CRLN_OBS 
  QLIMB    = 0.54 ; limb-darkening coeff for C2 (580-640 nm band) 

; Change image units from their original [1E-10*Bsun_mean] units to the tomography codes expected [1E-10*Bsun_center] units:
  IMG         = (1.-QLIMB/3) * IMG
  PREPUNIT    = '1e-10 Bsun_center'

; Expand Header to include the 10 variables required by oir tomography codes
  hdr  = create_struct(hdr          ,            $
                       'QLIMB'      ,QLIMB      ,$
                       'IMSIZE'     ,IMSIZE     ,$
                       'PIXSIZE'    ,PIXSIZE    ,$
                       'CENTER_X'   ,CENTER_X   ,$
                       'CENTER_Y'   ,CENTER_Y   ,$
                       'ROLL'       ,ROLL       ,$
                       'DSUN_OBS'   ,DSUN_OBS   ,$
                       'OBSLAT'     ,OBSLAT     ,$
                       'CARLONG'    ,CARLONG    ,$
                       'PREPUNIT'   ,PREPUNIT    )

  return
end

pro lasco_mars_inspect,hdr=hdr,img=img,r0=r0,data_dir=data_dir,filename=filename,mini=mini,maxi=maxi,pB=pB,Bk=Bk

; Compute the image grid
  compute_image_grid,hdr=hdr,ra=ra,pa=pa,x=x,y=y,instrument='lascoc2_lam'

; Image for display:
  img2  = img
  RMIN  = 2.2
  RMAX  = 6.5
  block = where(ra lt RMIN or RA gt RMAX)
  img2(block) = 0.
  dr=0.05         ; 0.025
  for ir=0,n_elements(r0)-1 do begin
     ring = where(ra ge r0[ir]-dr/2. and ra le r0[ir]+dr/2.)
     img2(ring) = maxi          ;max(img)
    ps1,data_dir+filename+'_PA_profile.'+strmid(string(r0[ir]),6,5)+'.eps',0
    display_PA_profiles,height=r0[ir],hdr=hdr,img=img,ra=ra,pa=pa,x=x,y=y,pB=pB,Bk=Bk
    ps2
  endfor

; Set up Z Device
  SET_PLOT,'Z'  
  dev=     'Z'
  Device, Decomposed=0, Set_Pixel_Depth=24, Set_Resolution=[hdr.naxis1,hdr.naxis1]

; Load color table
  loadct,39

; Set common MINI and MAXI values for visualization of all images, and assign MAXI to all pixels in the disk. 
  img2(0,0) = mini
  img2(0,1) = maxi
  disk       = where(ra le 1.)
  img2(disk) = maxi
  tvscl, alog10(img2 > mini < mai), 0

 AU   = 149.597870700e9         ; m 
 dsun = hdr.dsun/AU             ; au 
 crln = hdr.crln_obs            ; deg
 crlt = hdr.crlt_obs            ; deg

; Round numbers to be displayed in the image visualization. 
 f1 = 10.d
 f2 = 100.d
 dsun = round(dsun*f2)/f2
 crln = round(crln*f1)/f1
 crlt = round(crlt*f1)/f1

 date_string = strmid(hdr.date_obs,0,4)+'-'+strmid(hdr.date_obs,5,2)+'-'+strmid(hdr.date_obs,8,2)+$
                'UT'+$
                strmid(hdr.time_obs,0,2)+':'+strmid(hdr.time_obs,3,2)+':'+strmid(hdr.time_obs,6,2)
                    
 if hdr.crln_obs lt 10.                          then  lon_string = strmid(string(crln),7,3)
 if hdr.crln_obs gt 10. and hdr.crln_obs lt 100. then  lon_string = strmid(string(crln),7,4)
 if hdr.crln_obs gt 100.                         then  lon_string = strmid(string(crln),7,5)
 
 if abs(hdr.crlt_obs) lt 10. then lat_string = strmid(string(abs(crlt)),7,3)
 if abs(hdr.crlt_obs) gt 10. then lat_string = strmid(string(abs(crlt)),7,4)

 if hdr.crlt_obs gt 0. then sg_lat_string = '+'
 if hdr.crlt_obs lt 0. then sg_lat_string = '-'
 
 dsun_str = strmid(string(dsun),6,4)

 xyouts,0.01,0.95,date_string,charsize=2,/normal,charthick=2,font=1
 xyouts,0.65,0.95,'D!DSUN!N = '+dsun_str+' au',charsize=2,/normal,charthick=2,font=1
 xyouts,0.01,0.01,'Lat = '+sg_lat_string+lat_string+' deg',charsize=2,/normal,charthick=2,font=1
 xyouts,0.62,0.01,'Lon = '+lon_string+' deg',charsize=2,/normal,charthick=2,font=1
 nname = strlen(filename)
 record_jpg_zbuff,data_dir,strmid(filename,0,nname-4)+'.jpg'

; Go back to X Device
  SET_PLOT,'X'
  dev=     'X'
  Device, retain = 2, true_color = 24, decomposed = 0
 return
end

pro display_PA_profiles,height=height,hdr=hdr,img=img,ra=ra,pa=pa,x=x,y=y,pB=pB,Bk=Bk

if not keyword_set(height) then begin
   print,'please specify height.'
   stop 
endif

img_data = img

Nt=180
t0a = 2.*!pi*findgen(Nt)/float(Nt-1)

da = fltarr(Nt)

for it=0,Nt-1 do begin
   t0     =  t0a(it)
   y0     = -height*sin(t0)
   z0     =  height*cos(t0)
   da(it) = findval(img_data, x, y, y0, z0)
endfor

 mini = max([min(da),-1.])
 maxi = max(da)

 if keyword_set(pB) then radiance_type = 'pB'
 if keyword_set(Bk) then radiance_type = 'Bk'

 !p.charsize=1
 plot,t0a/!dtor,da ,xstyle=1,yr=[mini,maxi],/nodata,$
      xtitle = 'PA [deg]',$
      title  = 'LASCO-C2 LAM '+radiance_type+' ['+hdr.PREPUNIT+'] at '+strmid(string(height),6,4)+' R!DSUN!N'
 loadct,12
 blue  = 100
 red   = 200
 green =  20
 oplot,t0a/!dtor,da,th=3,color=blue
 loadct,0
 
return
end
