# SolarTom_IDL_Prep_Tools

Dear Philippe,

The main purpose of lasco_mars_prep.pro is to expand the header of the C2 images, adding the ten (10) variables listed below. It also generates visualisation of the image, and other plots. The variables that are created are the ones used by our tomography codes. A similar prep tool exists for other instruments (metis, aspiics, kcor/mk4, etc.), doing a similar job. The idea behind this implementation was to eliminate (nearly all) instrument-based decisions within the tomography codes. Give this one a try and let us know if useful to you. If you would like to have a similar tool for another instrument let us know and we will add it here.

List of variables created by the prep tool.

                       'QLIMB'      ,QLIMB      ,$      (limb darkening factor)
                       'IMSIZE'     ,IMSIZE     ,$      (pixels)
                       'PIXSIZE'    ,PIXSIZE    ,$      (arcsec)
                       'CENTER_X'   ,CENTER_X   ,$      (pixels)
                       'CENTER_Y'   ,CENTER_Y   ,$      (pixels)
                       'ROLL'       ,ROLL       ,$      (deg, positive clockwise) (**)
                       'DSUN_OBS'   ,DSUN_OBS   ,$      (m)
                       'OBSLAT'     ,OBSLAT     ,$      (deg)
                       'CARLONG'    ,CARLONG    ,$      (deg)
                       'PREPUNIT'   ,PREPUNIT    )      (1E-10*Bsun_center)

(**) This is the sign convention adopted in the original tomography codes by Rich, which we kept. As the Legacy C2 image headers use the opposite convention for ROLLANGL, we include the "-1" factor in Ln 162, where ROLL is defined.

The ZIP file in this repo contrains the result of running the example calling sequence on the image 23904500pB.fts (also included in the zip file).