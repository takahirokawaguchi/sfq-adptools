;(mload "/home2/kawaguti/git/ptl")
(defun deleteAllPathSegs ()
  (let (cv)
    (setq cv (geGetWindowCellView))
    (foreach 
      shape (setof x cv~>shapes (equal x~>objType "pathSeg"))
      (dbDeleteObject shape))))
(defun deleteAllTrls ()
  (let (cv)
    (setq cv (geGetWindowCellView))
    (foreach 
      shape (setof x cv~>shapes (equal x~>objType "line"))
      (dbDeleteObject shape))))

(defun deleteAllVias ()
  (let (cv)
    (setq cv (geGetWindowCellView))
    (foreach 
      via cv~>vias
      (dbDeleteObject via))))

;(defun routeFromSToL ()
;  (let 
;    (cvL cvS route via widthPTL widthPreviousPTL pointsPrevious pointVia) 
;    (setq cvL (dbOpenCellViewByType "kitamuraTest" "4bitcla_zeroskew" "layout"))
;    (setq cvS (dbOpenCellViewByType "kitamuraTest" "4bitcla_zeroskew" "schematic_replaceDrvRec")) 
;    (setq via (techFindViaDefByName (techGetTechFile cvL) "PTL1_PTL2"))
;    (foreach
;      net cvS~>nets
;      (setq widthPreviousPTL 4.8)
;      (setq route (dbCreateRoute cvL (car (setof x cvL~>nets (equal x~>name net~>name)))))
;      (foreach 
;        fig net~>figs
;        (setq widthPTL 0)
;        (when (equal fig~>width RINER.PTL1_PATH_WIDTH)
;          (setq widthPTL 5.5))
;        (when (equal fig~>width RINER.PTL2_PATH_WIDTH)
;          (setq widthPTL 4.8))
;        (when (nequal widthPTL widthPreviousPTL)
;          (setq pointVia nil)
;          (foreach 
;            p1 fig~>points
;            (foreach 
;              p2 pointsPrevious
;              (when (equal p1 p2)
;                (setq pointVia p1))))
;          (when pointVia
;            route~>objects = 
;            (append1 
;              route~>objects 
;              (dbCreateVia
;                cvL
;                via
;                (ptlPointSchToLayout pointVia)
;                "R0"))))
;        (setq widthPreviousPTL widthPTL)
;        (setq pointsPrevious fig~>points)
;        (when (nequal widthPTL 0)
;          (let
;            (ps1 ps2)
;            (setq ps1 (car fig~>points))
;            (setq ps2 (cadr fig~>points))
;            route~>objects =
;            (append1
;              route~>objects
;              (dbCreatePathSeg
;                cvL
;                (if (equal widthPTL 5.5) 
;                  "PTL1"
;                  "PTL2")
;                (ptlPointSchToLayout ps1)
;                (ptlPointSchToLayout ps2)
;                widthPTL
;                "truncate"
;                "truncate")
;              )))))))

(defun routeFromSToL ()
  (let 
    (lib netL cvL cvS via widthPTL widthPreviousPTL pointsPrevious pointVia) 
    (setq lib "ptlLayout")
    (setq cvL (dbOpenCellViewByType lib "4bitcla_zeroskew" "layout"))
    (setq cvS (dbOpenCellViewByType lib "4bitcla_zeroskew" "schematic_replaceDrvRec")) 
    (setq via (techFindViaDefByName (techGetTechFile cvL) "PTL1_PTL2"))
    (foreach
      net cvS~>nets
      (setq widthPreviousPTL 4.8)
      (setq pointsPrevious nil)
      (setq netL (car (setof x cvL~>nets (equal x~>name net~>name))))
      (foreach 
        fig (sortFigs net)
        (setq widthPTL 0)
        (when (equal fig~>width RINER.PTL1_PATH_WIDTH)
          (setq widthPTL 5.5))
        (when (equal fig~>width RINER.PTL2_PATH_WIDTH)
          (setq widthPTL 4.8))
        (when (nequal widthPTL widthPreviousPTL)
          (setq pointVia nil)
          (foreach 
            p1 fig~>points
            (foreach 
              p2 pointsPrevious
              (when (equal p1 p2)
                (setq pointVia p1))))
          (when pointVia
            ;(dbAddFigToNet
              (dbCreateVia
                cvL
                via
                (ptlPointSchToLayout pointVia)
                "R0")
              ;netL)
          ))
        (if (equal widthPTL widthPreviousPTL)
          then
          (let (pMember pUnmembers)
            (setq pUnmembers nil)
            (foreach 
              p fig~>points
              (if (member p pointsPrevious)
                (progn (setq pMember p) 
                       (setq pointsPrevious (remove p pointsPrevious))
                       (setq pointsPrevious (append1 pointsPrevious p)))
                (setq pUnmembers (append1 pUnmembers p))))
            (setq pointsPrevious (append pointsPrevious pUnmembers))
            )
          else
          (when (nequal widthPTL 0)
            (createTrlPtl cvL netL pointsPrevious widthPreviousPTL)
            )
          (setq pointsPrevious fig~>points)
          (setq widthPreviousPTL widthPTL)
          ))
      ;end foreach fig
      (when (nequal widthPTL 0)
        (createTrlPtl cvL netL pointsPrevious widthPreviousPTL))
      )))

(defun sortFigs (net)
  (let (beginPt endPt foundFig rest ret)
    (if (equal (length net~>allInstTerms) 2)
      then
      (setq beginPt (getInstTermCoord (car (setof x net~>allInstTerms (equal x~>direction "input")))))
      (setq rest net~>figs)
      else
      (setq beginPt nil)
      (setq rest nil)
      )
    (while 
      rest
      (setq foundPairPts nil)
      (foreach 
        fig rest
        (when (member beginPt fig~>points)
          (setq foundFig fig)))
      (setq endPt (car (remove beginPt foundFig~>points)))
      foundFig~>points = (list beginPt endPt)
      (setq beginPt endPt)
      (if foundFig
        then
        (setq ret (append1 ret foundFig))
        (setq rest (remove foundFig rest))
        else
        (setq rest nil)))
    ret
    ))

(defun createTrlPtl (cv netL points width) 
  (when  
    (geqp (length points) 2)
    (let (trl)
      (setq 
        trl
        (geCreateTrl
          cv
          (if (equal width 5.5) 
            "PTL1"
            "PTL2")
          (mapcar 'ptlPointSchToLayout points)
          width
          "radial"
          1.0
          1.0
          0.6
          20
          ))
      ;(dbAddFigToNet trl netL)
      ;trl~>net = netL
      )))

(defun ptlPointSchToLayout (point)
  ;schemati(0.375x0.375)
  ;layout(30x30)
  ;schematicPtlDif +1/3 +2/3
  ;layoutPtlDif +8.5 +21.5
  (let (xs ys fxs fys xl yl)
    (setq xs (car point))
    (setq ys (cadr point))
    (setq fxs (floor xs/0.375))
    (setq fys (floor ys/0.375))
    (setq xl 30*fxs)
    (setq yl 30*fys)
    (if (eq fxs (round xs/0.375))
      (setq xl xl+8.5)
      (setq xl xl+21.5))
    (if (eq fys (round ys/0.375))
      (setq yl yl+8.5)
      (setq yl yl+21.5))
    (list xl yl)
    ))
