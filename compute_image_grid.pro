;;
;
; Brief Description: Provided an image header and instrument
; specification this routine returns 2D arrays of the radii and polar
; angle of each pixel of the image, and 1D arrays with the x and y
; cartesian position vectors with origin in the disk-center.
;
; INPUTS:
; header:     header structure of the image
; instrument: string specifying the instrument, valid values are:
;             'comp', 'kcor', 'cor1', 'lascoc2_lam', 'lascoc2_nrl', 'euvi', 'aia',
;             'metis_synthetic', 'metis', 'mk4', 'cor2', 'punch'.
;             TBI: 'eit'.
;
; OUTPUTS:
; ra, pa: 2D float arrays of the image size containing the projected
; radii ra [Rsun] and polar angle pa [deg] of each pixel.
; x, y: 1D float arrays with the cartesian coordinates [Rsun] with
; origin in the disk center.
;
; History:  V1.0, Alberto M. Vasquez, CLaSP, Spring-2018.
;           V1.1, Alberto M. Vasquez, IAFE,  Dec-04-2020. Added METIS_Synthetic
;           V1.2, Federico A. Nuevo,  IAFE,  May-03-2022. Added UCoMP
;           V1.3, Alberto M. Vasquez, IAFE,  Dec-26-2022. Added METIS actual data
;           V1.4, Diego G. Lloveras,  Gehme, Jul-25-2023. Added LascoC2_Nrl          
;           V1.5, Alberto M. Vasquez, CLaSP, Sep-19-2023. Added Mk4.
;           V1.6, Alberto M. Vasquez, IAFE,  Oct-10-2024. Added COR2.
;           V1.7, Alberto M. Vasquez, IAFE,  Nov-12-2025. Added PUNCH_NFI.
;           V1.7, Alberto M. Vasquez, IAFE,  Nov-14-2025. Added PROBA3_ASPIICS.
;           V1.8, Alberto M. Vasquez, IAFE,  Mar-06-2026. Added ITI
;;

pro compute_image_grid,hdr=hdr,ra=ra,pa=pa,x=x,y=y,instrument=instrument,Rs=Rs,io=io,fs=fs,imagecenter=imagecenter

  instrument_detected_flag = 0

  if instrument eq 'punch_nfi' then begin
     instrument_detected_flag = 1
     Rs =  hdr.rsun_arc         ; Sun radius in arcsec
     px  = hdr.cdelt1*3600.d    ; Pixel size in arcsec
     Rs  = Rs/px                ; Sun radius in pixels
     px  = 1./Rs                ; Pixel size in Rsun units
     ix0 = hdr.crpix1-1         ; Disk center x-pixel, changed to IDL convention (FITS convention starts with index=1, IDL starts with index=0).
     iy0 = hdr.crpix2-1         ; Disk center y-pixel, changed to IDL convention     
  endif
  
  if instrument eq 'comp' or instrument eq 'ucomp' or instrument eq 'kcor' or instrument eq 'mk4' or $
     instrument eq 'cor1' or instrument eq 'euvi' or instrument eq 'aia' or instrument eq 'iti' or instrument eq 'lascoc2_nrl' or $
     instrument eq 'cor2' or instrument eq 'aspiics' then begin
     instrument_detected_flag = 1
     if instrument eq 'aia' or instrument eq 'iti' or instrument eq 'ucomp' or instrument eq 'aspiics' then begin
        if instrument eq 'aia' or instrument eq 'iti' or instrument eq 'ucomp' then Rs=hdr.rsun_obs ; Sun radius in arcsec
        if instrument eq 'aspiics'                      then Rs=hdr.rsun_arc ; Sun radius in arcsec
     endif else begin
        Rs=hdr.rsun             ; Sun radius in arcsec
     endelse
     px  = hdr.cdelt1           ; Pixel size in arcsec
     Rs  = Rs/px                ; Sun radius in pixels
     px  = 1./Rs                ; Pixel size in Rsun units
     ix0 = hdr.crpix1-1         ; Disk center x-pixel, changed to IDL convention (FITS convention starts with index=1, IDL starts with index=0).
     iy0 = hdr.crpix2-1         ; Disk center y-pixel, changed to IDL convention
     if instrument eq 'cor1' or instrument eq 'cor2' then begin
        ix0 = hdr.sunpix1-1     ; Sun center x-pixel, changed to IDL convention (FITS convention starts with index=1, IDL starts with index=0).
        iy0 = hdr.sunpix2-1     ; Sun center y-pixel, changed to IDL convention
     endif
  endif
  
  if instrument eq 'lascoc2_lam' then begin
     instrument_detected_flag = 1
       Rs  = hdr.rsun_pix         ; Sun radius in pixels
       px  = 1./Rs                ; Pixel size in Rsun units
       ix0 = hdr.xsun_med         ; Disk center x-pixel, which already uses the IDL convention
       iy0 = hdr.ysun_med         ; Disk center y-pixel, which already uses the IDL convention
  endif

  if instrument eq 'metis' then begin
     instrument_detected_flag = 1
     Rs  = hdr.rsun_arc         ; Sun radius in arcsec
     px  = hdr.cdelt1           ; Pixel size in arcsec
     Rs  = Rs/px                ; Sun radius in pixels
     px  = 1./Rs                ; Pixel size in Rsun units
     ix0 = hdr.sunpix1-1        ; Sun center x-pixel, changed to IDL convention (FITS convention starts with index=1, IDL starts with index=0).
     iy0 = hdr.sunpix2-1        ; Sun center y-pixel, changed to IDL convention
     if keyword_set(io) then begin
        ix0 = hdr.iopix1-1    ; IO center x-pixel, changed to IDL convention (FITS convention starts with index=1, IDL starts with index=0).
        iy0 = hdr.iopix2-1    ; IO center y-pixel, changed to IDL convention
     endif
     if keyword_set(fs) then begin
                                ; hdr.fspix1(2) currently stores
                                ; crpix1(2), below a preliminary rule
                                ; provided by Roberto Susino
        ix0 = hdr.fspix1-1 + 42/hdr.nbin1   ; FS center x-pixel, changed to IDL convention (FITS convention starts with index=1, IDL starts with index=0).
        iy0 = hdr.fspix2-1 - 36/hdr.nbin2   ; FS center y-pixel, changed to IDL convention
     endif
     if keyword_set(imagecenter) then begin
        ix0 = hdr.crpix1-1  
        iy0 = hdr.crpix2-1 
     endif
  endif

  if instrument eq 'metis_synthetic' then begin
     instrument_detected_flag = 1
       Rs  = hdr.rsun_px          ; Sun radius in pixels
       px  = 1./Rs                ; Pixel size in Rsun units
       ix0 = hdr.crpix1-1         ; Disk center x-pixel, changed to IDL convention
       iy0 = hdr.crpix2-1         ; Disk center y-pixel, changed to IDL convention
  endif

  if instrument_detected_flag eq 0 then begin
     print,'compute_image_grid.pro: invalid value for instrument.'
     stop
  endif
  
  if instrument ne 'ucomp' then begin
     ; imagen cuadrada (nx = ny)
     x  = px*(findgen(hdr.naxis1) - ix0)
     y  = px*(findgen(hdr.naxis1) - iy0)
     u  = 1. + fltarr(hdr.naxis1)
     xa = x#u
     ya = u#y
     ra = sqrt(xa^2 + ya^2)
     ta    = fltarr(hdr.naxis1,hdr.naxis1)
  endif 
  if instrument eq 'ucomp' then begin
     ; imagen NO cuadrada (nx NE ny)
     x  = px*(findgen(hdr.naxis1) - ix0)
     y  = px*(findgen(hdr.naxis2) - iy0)
     u1  = 1. + fltarr(hdr.naxis1)
     u2  = 1. + fltarr(hdr.naxis2)
     xa = x#u2
     ya = u1#y
     ra = sqrt(xa^2 + ya^2)
     ta    = fltarr(hdr.naxis1,hdr.naxis2)
  endif 

  p     = where(xa gt 0.)
  ta(p) = Acos( ya(p) / ra(p) )
  p     = where(xa lt 0.)
  ta(p) = 2.*!pi - Acos( ya(p) / ra(p) )
  p     = where(xa eq 0. AND ya gt 0.)
  if p(0) ne -1 then ta(p) = 0.
  p     = where(xa eq 0. AND ya lt 0.)
  if p(0) ne -1 then ta(p) = !pi
  ta    = 2.*!pi - ta
  PA    = ta/!dtor

return
end
