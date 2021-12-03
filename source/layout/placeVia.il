;(mload "~/git/skill")
(defun placeVia ()
  (let (cv) 
    (setq cv (geGetWindowCellView ))
    ;(setq viac (dbOpenCellViewByType "kitamuraTest" "viac" "layout")) 
    ;delete vias
    (foreach via cv~>vias   
             ;(setq origin via~>origin)   
             ;(setq orient via~>orient)   
             ;(dbCreateInst cv viac nil origin orient)   
             (dbDeleteObject via))
    ;delete via etc intances
    (foreach 
      inst (setof 
             x cv~>instances 
             (or (equal x~>cellName "via")
                 (equal x~>cellName "viac")
                 (equal x~>cellName "PTL1c")
                 (equal x~>cellName "PTL2c")
                 ))
      (dbDeleteObject inst))
    ;routes objects
    (foreach
      route cv~>routes
      (foreach 
        object (setof x route~>objects (equal x~>objType "pathSeg"))
        object~>beginStyle = "variable"
        object~>beginExt = .0
        object~>endStyle = "variable"
        object~>endExt = .0
        (if (equal object~>layerName "PTL1")
          object~>width = 5.5
          object~>width = 4.8
          )))
    ;place vias
    (foreach
      route cv~>routes
      (let (o1 o2 oList origin orient cellName l u r d o1PTL o2PTL)
        (setq oList (setof x route~>objects (equal x~>objType "pathSeg")))
        (while 
          oList
          (setq o1 (car oList))
          (setq oList (cdr oList))
          (setq o2 (car oList))
          (when o2
            (setq origin o1~>endPt)
            (setq l 0);left
            (setq u 0);up
            (setq r 0);right
            (setq d 0);down
            (setq cellName nil)
            (setq orient nil)
            (if (equal o1~>layerName "PTL1")
              (setq o1PTL 1)
              (setq o1PTL 2))
            (if (equal o2~>layerName "PTL1")
              (setq o2PTL 1)
              (setq o2PTL 2))
            (if (equal (xCoord o1~>beginPt) (xCoord origin))
              (if (lessp (yCoord o1~>beginPt) (yCoord origin))
                (setq d o1PTL)
                (setq u o1PTL))
              (if (lessp (xCoord o1~>beginPt) (xCoord origin));else
                (setq l o1PTL)
                (setq r o1PTL)))
            (if (equal (xCoord o2~>endPt) (xCoord origin))
              (if (lessp (yCoord o2~>endPt) (yCoord origin))
                (setq d o2PTL)
                (setq u o2PTL))
              (if (lessp (xCoord o2~>endPt) (xCoord origin))
                (setq l o2PTL)
                (setq r o2PTL)))
            ;via
            (when (equal (list l u r d) (list 1 2 0 0 )) (setq cellName "viac") (setq orient "MYR90"))
            (when (equal (list l u r d) (list 1 0 2 0 )) (setq cellName "via" ) (setq orient "R180"))
            (when (equal (list l u r d) (list 1 0 0 2 )) (setq cellName "viac") (setq orient "R90"))
            (when (equal (list l u r d) (list 0 1 2 0 )) (setq cellName "viac") (setq orient "MY"))
            (when (equal (list l u r d) (list 0 1 0 2 )) (setq cellName "via" ) (setq orient "R90"))
            (when (equal (list l u r d) (list 0 0 1 2 )) (setq cellName "viac") (setq orient "MXR180"))
            (when (equal (list l u r d) (list 2 1 0 0 )) (setq cellName "viac") (setq orient "R0"))
            (when (equal (list l u r d) (list 2 0 1 0 )) (setq cellName "via" ) (setq orient "R0"))
            (when (equal (list l u r d) (list 2 0 0 1 )) (setq cellName "viac") (setq orient "MX"))
            (when (equal (list l u r d) (list 0 2 1 0 )) (setq cellName "viac") (setq orient "R270"))
            (when (equal (list l u r d) (list 0 2 0 1 )) (setq cellName "via" ) (setq orient "R270"))
            (when (equal (list l u r d) (list 0 0 2 1 )) (setq cellName "viac") (setq orient "R180"))
            ;curv PTL1c
            (when (equal (list l u r d) (list 1 1 0 0 )) (setq cellName "PTL1c") (setq orient "R0"))
            ;(when (equal (list l u r d) (list 1 0 1 0 )) (setq cellName "PTL1c") (setq orient ""))
            (when (equal (list l u r d) (list 1 0 0 1 )) (setq cellName "PTL1c") (setq orient "R90"))
            (when (equal (list l u r d) (list 0 1 1 0 )) (setq cellName "PTL1c") (setq orient "R270"))
            ;(when (equal (list l u r d) (list 0 1 0 1 )) (setq cellName "PTL1c") (setq orient ""))
            (when (equal (list l u r d) (list 0 0 1 1 )) (setq cellName "PTL1c") (setq orient "R180"))
            ;curv PTL2c
            (when (equal (list l u r d) (list 2 2 0 0 )) (setq cellName "PTL2c") (setq orient "R0"))
            ;(when (equal (list l u r d) (list 2 0 2 0 )) (setq cellName "PTL2c") (setq orient ""))
            (when (equal (list l u r d) (list 2 0 0 2 )) (setq cellName "PTL2c") (setq orient "R90"))
            (when (equal (list l u r d) (list 0 2 2 0 )) (setq cellName "PTL2c") (setq orient "R270"))
            ;(when (equal (list l u r d) (list 0 2 0 2 )) (setq cellName "PTL2c") (setq orient ""))
            (when (equal (list l u r d) (list 0 0 2 2 )) (setq cellName "PTL2c") (setq orient "R180"))
            ;put via or curv cell
            (when cellName
              (dbCreateInst 
                cv 
                (dbOpenCellViewByType "kitamuraTest" cellName "layout") 
                nil 
                origin 
                orient))
            );when o2
          )))
    ))

