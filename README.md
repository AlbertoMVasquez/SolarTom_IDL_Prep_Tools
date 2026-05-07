# SolarTom_IDL_Prep_Tools

Philippe,

The main purpose of lasco_mars_prep.pro is to expand the header of the C2 images, adding the ten (10) variables listed below. These are the ones used by our tomography codes. A similar prep tool exists for other instruments, doing a similar job. The idea behind this implementation was to eliminate (nearly all) instrument-based decisions within the tomography codes. The reason to keep a prep tool for each istrument is that all images are different. The variables are:


                       'QLIMB'      ,QLIMB      ,$	(limb darkening factor)
                       'IMSIZE'     ,IMSIZE     ,$      (pixels)
                       'PIXSIZE'    ,PIXSIZE    ,$      (arcsec)
                       'CENTER_X'   ,CENTER_X   ,$      (pixels)
                       'CENTER_Y'   ,CENTER_Y   ,$      (pixels)
                       'ROLL'       ,ROLL_OFFSET,$      (deg, positive clockwise) (**)
                       'DSUN_OBS'   ,DSUN_OBS   ,$      (m)
                       'OBSLAT'     ,OBSLAT     ,$      (deg)
                       'CARLONG'    ,CARLONG    ,$      (deg)
                       'PREPUNIT'   ,PREPUNIT    )      (1E-10*Bsun_center)

(**) This is the sign convention adopted in the original tomography codes by Rich, which we kept. As the Legacy C2 headers have the opposite convention note we invert its sign in our PREP tool. Philippe: your tomography code of course may assume the opposite convention.  If so you may want to edit this prep tool, specifically eliminate the "-1"factor in Ln 162, where ROLL_OFFSET is defined.