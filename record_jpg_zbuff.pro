pro record_jpg_zbuff,dir,filename

; set graph stuff
;  device, retain     = 2
;  device, true_color = 24
;  device, decomposed = 0

  image24 = TVRD(True=1)
  image2d = Color_Quan(image24, 1, r, g, b)
  write_jpeg,dir+filename,image24,quality=100,true=1
  return
end
