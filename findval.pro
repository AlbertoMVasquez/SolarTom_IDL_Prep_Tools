; Explicación:

; Sea el ARRAY 2D "ima" de NxM

; Sean los ARRAYS 1D "ya", "za", que definen la grilla,
; en la cual está dado el array "ima", es decir:
; "ya" es de N componentes, "za" es de M componentes.
; (nota: llamo "ya" al eje horizontal y "za" al vertical).

; Sean los escalars y0 y z0 en los cuales deseo conocer el valor de la
; interpolación bi-lineal de ima.

; Entonces, el valor deseado se otiene con esta llamada:
; valor_deseado = findval(ima,ya,za,y0,z0)

function findval, ima, ya, za, y0, z0
  Df=0.
  if y0 ge max(ya) or y0 le min(ya) then goto,fin
  if z0 ge max(za) or y0 le min(za) then goto,fin
  iyA=max(where(ya le y0))
  izA=max(where(za le z0))
  if iyA eq -1 or izA eq -1 then goto,fin
  iyB=iyA+1
  izB=izA+1
  if iyA eq n_elements(ya)-1 then iyB=iyA
  if izA eq n_elements(za)-1 then izB=izA
  D1=ima(iyA,izA) 
  D2=ima(iyB,izA) 
  D4=ima(iyA,izB) 
  D5=ima(iyB,izB)
  if iyA lt iyB AND izA lt izB then begin
     D3=D1+(D2-D1)*(y0-yA(iyA))/(yA(iyB)-yA(iyA))
     D6=D4+(D5-D4)*(y0-yA(iyA))/(yA(iyB)-yA(iyA))
     Df=D3+(D6-D3)*(z0-zA(izA))/(zA(izB)-zA(izA))
  endif
  if iyA lt iyB AND izA eq izB then Df=D1+(D2-D1)*(y0-yA(iyA))/(yA(iyB)-yA(iyA))
  if iyA eq iyB AND izA lt izB then Df=D1+(D4-D1)*(z0-zA(izA))/(zA(izB)-zA(izA))
  if iyA eq iyB AND izA eq izB then Df=D1
  fin:
  return,Df
end

