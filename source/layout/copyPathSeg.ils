(defun copyPathSegs ()
  (let (scv dcv)
    (setq dcv (geGetWindowCellView ))
    (setq scv (dbOpenCellViewByType dcv~>libName dcv~>cellName "layout_backup"))
    (foreach 
      p (setof x scv~>shapes (equal x~>objType "pathSeg"))
      (dbCreatePath
        dcv
        p~>layerName
        (list p~>beginPt p~>endPt)
        p~>width))))

(defun copyVias ()
  (let (scv dcv)
    (setq dcv (geGetWindowCellView ))
    (setq scv (dbOpenCellViewByType dcv~>libName dcv~>cellName "layout_backup"))
    (foreach 
      v scv~>vias
      (dbCreateVia
        dcv
        v~>viaHeader~>viaDef
        v~>origin
        v~>orient))))

