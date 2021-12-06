;(mload "~/git/ptl")
(defun replaceDrvRec ()
  (let 
    (insts drvs recs pspls lib)
    (setq insts (geGetWindowCellView )~>instances)
    (setq drvs (setof x insts (isPTLDrv x)))
    (setq recs (setof x insts (isPTLRec x)))
    (setq pspls (setof x insts (isPspl x)))
    (setq lib "ptlLayout")
    (foreach 
      drv drvs
      (translateDrvRec drv "drvPTL2_mvpin" lib))
    (foreach 
      rec recs
      (translateDrvRec rec "recPTL2_mvpin" lib))
    (foreach 
      pspl pspls
      (translateDrvRec pspl "pspl2_mvpin" lib))
    ))

;(defun translateDrvRec (instance cellName libName)
;  (let (symbolId ret listPinnameNetCoord destCoord origCoord p1 p2)
;    (setq listPinnameNetCoord nil)
;    (foreach 
;      it instance~>instTerms
;      (setq listPinnameNetCoord 
;            (cons (list it~>name it~>net (getInstTermCoord it)) 
;                  listPinnameNetCoord)))
;    (when
;      (setq symbolId 
;            (dbOpenCellViewByType
;              libName
;              cellName
;              "symbol_p"
;              ))
;      (setq ret 
;            (schCreateInst
;              instance~>cellView
;              symbolId
;              nil
;              instance~>xy
;              instance~>orient
;              ))
;      (dbDeleteObject instance)
;
;      ;for net
;      (foreach 
;        it ret~>instTerms
;        (setq destCoord (getInstTermCoord it))
;        (foreach 
;          pnc listPinnameNetCoord 
;          (setq origCoord (caddr pnc))
;          (when 
;            (and 
;              (equal it~>name (car pnc))
;              (nequal destCoord origCoord))
;            (let
;              (net)
;              (setq net (cadr pnc))
;              (foreach 
;                fig net~>figs
;                (setq p1 (car fig~>points))
;                (setq p2 (cadr fig~>points))
;                (when (equal origCoord p1)
;                  fig~>points = (list destCoord p2))
;                (when (equal origCoord p2)
;                  fig~>points = (list p1 destCoord)))
;              (unless net~>figs
;                (dbAddFigToNet
;                  (car (schCreateWire
;                    net~>cellView
;                    "route"
;                    "direct"
;                    (list (getInstTermCoord (car net~>instTerms))
;                          (getInstTermCoord it))
;                    0
;                    0
;                    RINER.PTL2_PATH_WIDTH
;                    RINER.PTL2_COLOR
;                    ))
;                  net)
;                ))))))))
;
