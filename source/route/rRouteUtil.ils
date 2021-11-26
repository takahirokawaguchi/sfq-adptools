;(load "~/git/route/source/rRouteUtil.il")
;(mload "~/git/route/source/")
(defun createOptionsFormMakePtlWire (scv)
  (let (comps)
    (setq comps (append1 comps (hiCreateRadioField      ?name 'ptlWireRadioField
                                                        ?choices (list "1" "2")
                                                        ?prompt "ptl1 or ptl2"
                                                        ?value "2")))
    (hiCreateAppForm
      ?name 'MAKE_PTL_WIRE_OPTIONS_FORM
      ?fields comps
      ?help "Choose ptl1 or ptl2")))

(defun getParamsFromOptionsFormMakePtlWire ()
  (let (paramList)
    (setq paramList nil)
    (setq paramList (cons 
                      MAKE_PTL_WIRE_OPTIONS_FORM~>ptlWireRadioField~>value
                      paramList))
    ;(warn "[DEBUG] #getParamsFromOptionsFormMakePtlWire params:%L\n" paramList)
    paramList
    ))

(defun makePtlWire ()
  (let (scv paramList figs nets points ok)
    (setq scv (geGetWindowCellView ))
    (setq figs (setof x (geGetSelSet ) (or (equal x~>objType "line")
                                           (equal x~>objType "path")
                                           )))
    (defvar MAKE_PTL_WIRE_OPTIONS_FORM)
    (createOptionsFormMakePtlWire scv)
    (setq ok
          hiDisplayForm(MAKE_PTL_WIRE_OPTIONS_FORM)
          )
    (setq paramList (getParamsFromOptionsFormMakePtlWire ))
    (when ok
      (foreach
        x figs
        (setq points x~>points)
        (dbDeleteObject x)
        (if (equal "1" (car paramList))
          then
          (schCreateWire
            scv
            "route"
            "direct"
            points
            0
            0
            RINER.PTL1_PATH_WIDTH
            RINER.PTL1_COLOR
            )
          else
          (schCreateWire
            scv
            "route"
            "direct"
            points
            0
            0
            RINER.PTL2_PATH_WIDTH
            RINER.PTL2_COLOR
            )
          )))))

(defun createOptionsFormPLA (scv)
  (let (comps)
    (setq comps (append1 comps (hiCreateRadioField      ?name 'strMovRadioField
                                                        ?choices (list "move")
                                                        ?prompt "move only"
                                                        ?value "move")))
    (setq comps (append1 comps (hiCreateFloatField      ?name 'ptlXFloatField
                                                        ?prompt "relative ptl place of x axis"
                                                        ?value 0.)))
    (setq comps (append1 comps (hiCreateFloatField      ?name 'ptlYFloatField
                                                        ?prompt "relative ptl place of y axis"
                                                        ?value 0.)))
    (hiCreateAppForm
      ?name 'ADJUST_INST_OPTIONS_FORM
      ?fields comps
      ?help "Select a method of placing on grids .")))

(defun getParamsFromOptionsFormPLA ()
  (let (paramList)
    (setq paramList nil)
    (setq paramList (cons 
                      ADJUST_INST_OPTIONS_FORM~>strMovRadioField~>value
                      paramList))
    (setq paramList (cons 
                      ADJUST_INST_OPTIONS_FORM~>ptlXFloatField~>value
                      paramList))
    (setq paramList (cons 
                      ADJUST_INST_OPTIONS_FORM~>ptlYFloatField~>value
                      paramList))
    (warn "[DEBUG] #getParamsFromOptionsFormPLA params:%L\n" paramList)
    paramList
    ))

(defun roAdjustAllInsts (cv )
  (let (ok diffLower diffLeft paramList listPairInstTerms listPairPin)
    ;オプションフォームのオブジェクトを格納しておく変数
    (defvar ADJUST_INST_OPTIONS_FORM)
    (createOptionsFormPLA cv)
    (setq ok
          hiDisplayForm(ADJUST_INST_OPTIONS_FORM))
    (setq paramList (getParamsFromOptionsFormPLA ))
    (when ok
      (setq diffLeft 
            (car (lowerLeft cv~>bBox)) - 3 * RINER.SCHEM_GRID_LEN)
      (setq diffLower
            (cadr (lowerLeft cv~>bBox)) - 3 * RINER.SCHEM_GRID_LEN)
      ;cell pin nets to (0 0)
      (foreach
        inst cv~>instances
        inst~>xy = (list
                     (car inst~>xy) - diffLeft
                     (cadr inst~>xy) - diffLower ))
      (setq listPairPin nil)
      (foreach 
        pin (setof x cv~>instances x~>purpose=="pin")
        (setq listPairPin
              (cons (list pin (car pin~>net~>instTerms))
                    listPairPin)))
      (setq listPairInstTerms nil)
      (foreach
        net cv~>nets
        (when net~>figs
          (setq listPairInstTerms
                (cons net~>instTerms listPairInstTerms))
          (foreach fig net~>figs
                   (dbDeleteObject fig))
          ))

      ;adjust
      (foreach inst (setof x cv~>instances x~>purpose!="pin") 
               (roAdjustInst inst 0.0 0.0 paramList))
      (foreach pair listPairInstTerms
               (if (equal (length pair) 2)
                 then
                 (schCreateWire
                   cv
                   "route"
                   "flight"
                   (list
                     (getInstTermCoord (car pair))
                     (getInstTermCoord (cadr pair))
                     )
                   0
                   0
                   0.0
                   )
                 else
                 (let (inputTerms outputTerm)
                   (printf "%L\n" pair~>name)
                   (setq inputTerms (setof x pair (isInputTerm x)))
                   (setq outputTerm (car (setof x pair (isOutputTerm x))))
                   (foreach inputTerm inputTerms
                            (schCreateWire
                              cv
                              "route"
                              "flight"
                              (list
                                (getInstTermCoord inputTerm)
                                (getInstTermCoord outputTerm)
                                )
                              0
                              0
                              0.0
                              )))
                 ;(printf "error: net does not have 2 instTerms\n")
                 )
               )
      (foreach pair listPairPin
               (let (pin)
                 (setq pin (car pair))
                 pin~>xy = 
                 (list 
                   ;(plus
                   (xCoord (getInstTermCoord (cadr pair)))
                   ;(if pin~>cellName=="ipin"
                   ;  0.375/6.0
                   ;  (minus 0.375/6.0)
                   ;  )) 
                   (yCoord (getInstTermCoord (cadr pair))) 
                   )
                 ))
      )))

(defun roAdjustInst (inst diffLower diffLeft paramList)
  (let ( tmp
         coord
         (SFQLayoutSymbolUnitLength 0.375)
         xyDiff
         )
    (setq tmp
          (if (isPTL inst)
            RINER.SCHEM_GRID_LEN
            RINER.SCHEM_GRID_LEN * 2.0
            ))
    (if inst~>purpose!="pin"
      then
      (setq xy (list
                 (xCoord (lowerLeft (getCellbBoxADP inst SFQLayoutSymbolUnitLength)))
                 (yCoord (lowerLeft (getCellbBoxADP inst SFQLayoutSymbolUnitLength)))
                 ))
      (setq xyDiff (list 
                     (difference
                       (xCoord inst~>xy)
                       (xCoord (lowerLeft (getCellbBoxADP inst SFQLayoutSymbolUnitLength))))
                     (difference
                       (yCoord inst~>xy)
                       (yCoord (lowerLeft (getCellbBoxADP inst SFQLayoutSymbolUnitLength))))
                     ))
      else
      (setq xy inst~>xy)
      (setq xyDiff (list 0.0 0.0)))
    (if (or (isIpin inst) (isOpin inst))
      (setq coord (getInstTermCoord (car inst~>net~>instTerms)))
      (progn
        (setq coord (mapcar '(lambda (p) (round p/tmp)) xy))
        (when (isPTL inst)
          (setq coord (list (car coord) + (cadr paramList)
                            (cadr coord) + (car paramList)
                            )))
        (setq coord (mapcar '(lambda (p) p * tmp ) coord))
        ))
    ;inst
    (cond
      ((equal (caddr paramList) "stretch")
       (schStretch (list inst)
                   (list
                     (list
                       (xCoord coord) + (xCoord xyDiff) - (xCoord inst~>xy)
                       (yCoord coord) + (yCoord xyDiff) - (yCoord inst~>xy)
                       )
                     "R0")))
      ((equal (caddr paramList) "move")
       (when (andList coord)
         inst~>xy =
         (list
           (xCoord coord) + (xCoord xyDiff)
           (yCoord coord) + (yCoord xyDiff)
           ))))
    ))

(defun riCenterGrid (gcoord)
  (mapcar 'plus
          (mapcar '(lambda (x)
                     (cond
                       ((mod x 2) == 1 RINER.SCHEM_GRID_OFFSET)
                       (t (RINER.SCHEM_GRID_LEN - RINER.SCHEM_GRID_OFFSET))))
                  gcoord)
          (mapcar '(lambda (x) (x * RINER.SCHEM_GRID_LEN))
                  gcoord)))

(defun riDivideRoute (route)
  (let (subroute subroutes coordBefore)
    (setq coordBefore (car route))
    (setq route (cdr route))
    (foreach
      coord route
      (setq subroute (list coord coordBefore))
      (setq subroutes (cons subroute subroutes))
      (setq coordBefore coord)
      )
    subroutes))

(defun roWriteFile (nets boundary blockage)
  (let ((out (outfile "./out.riner")) (cnt 0))
    (fprintf out (strcat ";; ./out.riner\n"))
    (fprintf out (strcat ";; " (getCurrentTime) "\n"))
    (foreach net nets
             (fprintf out (strcat "net: " (roListToString net) "\n"))
             (setq cnt (cnt + 1)))
    (fprintf out (strcat "boundary: " (roListToString boundary) "\n"))
    (foreach b blockage
             (fprintf out (strcat "blockage: " (roListToString b) "\n")))
    (close out)
    (setq out nil)))

(defun riCreateWire (scv route endPoints)
  (let (color subroutes wires net instrectpair)
    (setq route (mapcar '(lambda (x)
                           (append1
                             (riCenterGrid (list (car x) (cadr x)))
                             (nth 2 x)))
                        route))
    (setq route (cons (append1 (car endPoints) RINER.DEFAULT_PIN_LAYER) route))
    (setq route (append1 route (append1 (cadr endPoints) RINER.DEFAULT_PIN_LAYER)))
    (setq subroutes (riDivideRoute route))
    (setq subroutes (mapcar '(lambda (x) (riCompressPoints x scv)) subroutes))
    ;(printf "%L\n" subroutes)

    (setq wires nil)
    (foreach sr subroutes
             (setq clr_wid
                   (cond
                     ((nth 2 (car sr)) == RINER.LGC (list "purple" RINER.LGC_PATH_WIDTH))
                     ((nth 2 (car sr)) == RINER.PTL2 (list RINER.PTL2_COLOR RINER.PTL2_PATH_WIDTH))
                     ((nth 2 (car sr)) == RINER.PTL1 (list RINER.PTL1_COLOR RINER.PTL1_PATH_WIDTH))
                     (t nil)))
             (setq wires
                   (append (schCreateWire
                             scv
                             ;"draw"
                             "route"
                             ;"full"
                             "direct"
                             ;"flight"
                             (mapcar '(lambda (x) (list (car x) (cadr x))) sr)
                             0
                             0
                             (cadr clr_wid)
                             (car clr_wid)
                             )
                           wires)))
    ;(setq net (dbCreateUniqueNamedNet scv "riner_net" 1))
    ;(printf "debug:%L\n" wires)
    ;(foreach
    ;  ;wire (ruFlatten wires)
    ;  wire wires
    ;  (dbAddFigToNet wire net))
    ;;(recursiveDbMergeNet wires)
    ;(schExtractConn scv)
    wires))

(defun rCreateWireAll (scv fileName nets)
  (let (drouteList wires)
    (setq drouteList (riReadFile fileName))
    ;(printf "%L\n" nets)
    ;(printf "%L\n" drouteList)
    (foreach
      droute drouteList
      ;(printf "droute:%L\n" droute)
      (setq
        droute
        (cons
          (car droute)
          (append1
            (cons
              (append1 (getInstTermGridCoord 
                         (car (nth (car droute) nets)~>instTerms))
                       RINER.PTL2)
              (cdr droute))
            (append1 (getInstTermGridCoord 
                       (cadr (nth (car droute) nets)~>instTerms))
                     RINER.PTL2)
            )))
      ;(printf "droute:%L\n" droute)
      (if (length droute) != 1
        (progn
          (riCreateWire
            scv
            (cdr droute)
            (mapcar 'getInstTermCoord (nth (car droute) nets)~>instTerms)))
        (progn 
          (schCreateWire
            scv
            "route"
            "flight"
            (mapcar 'getInstTermCoord (nth (car droute) nets)~>instTerms)
            0
            0
            0.)))
      ;(schCreateNoteLabel
      ;  scv
      ;  (getInstTermCoord (car (nth (car droute) nets)~>instTerms))
      ;  (sprintf nil "%d" (car droute)) "lowerLeft" "R0" "fixed" 0.1 "normalLabel")
      )))

(defun ruType (obj)
  (cond
    (!(obj~>objType == "inst" || obj~>objType == "path") nil)
    ((equal obj~>objType "path")
     (cond
       (eq obj~>width RINER.PTL2_PATH_WIDTH RINER.PTL2)
       (eq obj~>width RINER.PTL1_PATH_WIDTH RINER.PTL1)
       (t nil)))
    ((equal obj~>objType "inst")
     (cond
       ((rexMatchp "^[P][T][L][2].*"  obj~>cellName) RINER.PTL2)
       ((rexMatchp "^[P][T][L][1].*"  obj~>cellName) RINER.PTL1)
       ((rexMatchp "^[v][i][a].*"  obj~>cellName) RINER.VIA)
       (t RINER.LGC)))
    (t nil)))

procedure(getInstTermBBox(instTerm)
           let((masterTerm masterTermBB)
               cond(
                    (instTerm~>objType != "instTerm"
                                       warn("calcInstTermCoord: object \"%L\" not instTerm."
                                            instTerm ))
                    (null((masterTerm = car(exists(x instTerm~>inst~>master~>terminals
                                                     x~>name == instTerm~>name)))
                          && (masterTermBB = car(masterTerm~>pins)~>fig~>bBox))
                      warn("calcInstTermCoord: cannot get pin \"%s\" coordinate."
                           instTerm~>name))
                    (t
                      dbTransformBBox(masterTermBB
                                       list(instTerm~>inst~>xy instTerm~>inst~>orient))))))

(defun roGetGridsAroundDRVsandRECs (scv bb)
  ;(let (result tmp)
  (let ( gcoord
         gcoordAndPtlLayer
         (result nil)
         )
    (foreach inst (setof x scv~>instances 
                         (or (isPTLDrv x)
                             (isPspl x)
                             (isPTLRec x)
                             (isPTL x)))
             (setq gcoord (getGridCoordPTL inst))
             (setq gcoordAndPtlLayers (getGridCoordBlockage gcoord inst))
             (setq result (append gcoordAndPtlLayers result))
             )
    result
    ))

(defun getGridCoordPTL (instance)
  (let (coord (SFQLayoutSymbolUnitLength 0.375))
    (setq coord
          (mapcar '(lambda (x) (ceiling (x/(RINER.SCHEM_GRID_LEN))))
                  (lowerLeft (getCellbBoxADP instance SFQLayoutSymbolUnitLength))
                  ))
    ))

(defun getGridCoordBlockage (gcoordLL inst)
  (let (coordPTLs coordPTLstrans coordLLPTLs result)
    (cond 
      ((isPTLDrv inst)
       (setq coordPTLs (list (list 1 1))))
      ((equal inst~>cellName "pspl2")
       (setq coordPTLs (list (list 1 1) (list 1 0))))
      ((isPTLRec inst)
       (setq coordPTLs (list (list 0 1))))
      ((isPTL inst)
       (setq coordPTLs (list (list 0 0))))
      )
    (unless (isPTL inst)
      (setq coordPTLstrans
            (mapcar (lambda (x) (car (transformGridCoord x (list 1 1) (cadr inst~>transform))))
                    coordPTLs))
      (setq coordLLPTLs
            (mapcar (lambda (x) 
                      (plusCoord x gcoordLL))
                    coordPTLstrans))
      ;(x y) -> (x y ptl-layer)
      (setq result (mapcar (lambda (x) (list x (list RINER.PTL2)))
                           coordLLPTLs))
      (setq result (append result
                           (mapcar (lambda (x) (list x (list RINER.PTL1)))
                                   coordLLPTLs)))
      )
    (when (isPTL inst)
      (cond 
        ((equal (ptlType inst) "PTL1")
         (setq result (list (list gcoordLL
                                  (list RINER.PTL1))))
         )
        ((equal (ptlType inst) "PTL2")
         (setq result (list (list gcoordLL
                                  (list RINER.PTL2))))
         )
        ((or
           (equal (ptlType inst) "viar")
           (equal (ptlType inst) "via")
           )
         (setq result (list
                        (list gcoordLL
                              (list RINER.PTL1))
                        (list gcoordLL
                              (list RINER.PTL2))
                        ))
         )
        ))
    result
    ))

(defun roPlacedDRVsorRECs (scv gcoord)
  (let (cells)
    (setq cells (mapcar 'car (dbGetOverlaps scv
                                            (ruGCtosSBB gcoord)
                                            RINER.CELL_BNDRY_LPP
                                            0:1)))
    (setq cells (setof tmp cells ((rexMatchp "^drv" tmp~>cellName)
                                  || (rexMatchp "^rec" tmp~>cellName))))
    cells))


(defun getInstTermGridCoord (instTerm)
  (let (instTermBBox refSchPoint)
    (setq instTermBBox (getInstTermBBox instTerm))
    (if (dbProduceOverlap 
          instTerm~>cellView 
          (list (car instTermBBox) (car instTermBBox)) 
          1 
          "PTL2")
      (setq refSchPoint (cadr instTermBBox)))
    (if (dbProduceOverlap
          instTerm~>cellView
          (list (cadr instTermBBox) (cadr instTermBBox))
          1
          "PTL2")
      (setq refSchPoint (car instTermBBox)))
    (when refSchPoint != nil
      (setq 
        refSchPoint 
        (mapcar '(lambda (x) (floor (x / RINER.SCHEM_GRID_LEN))) refSchPoint)
        ))
    refSchPoint))

(defun riReadRouterOut ()
  (let (routerID tmp responce)
    (setq routerID (ipcBeginProcess RINER.ROUTER_COMMAND))
    (ipcWaitForProcess routerID)
    (while (setq tmp (ipcReadProcess routerID 10))
           (setq responce (append1 responce tmp)))
    responce))

(defun riReadFile (fileName)
  (let ((in (infile fileName)) line result)
    (while (setq line (lineread in))
           (setq result (cons (eval line) result)))
    (close in)
    (setq in nil)
    (setof e result (listp e))))

(defun riCompressPoints (segp scv)
  (let (coords lnum)
    (setq coords (mapcar '(lambda (x) (reverse (cdr (reverse x)))) segp))
    (setq lnum (nth 2 (car segp)))
    (setq coords (dbCompressPointArray coords nil scv~>DBUPerUU))
    (mapcar '(lambda (x) (append1 x lnum)) coords)))

(defun ruFlatten (numberList)
  (foreach mapcan element numberList
           (if (listp element )
             (ruFlatten (copy element))
             (ncons element))))

(defun roListToString (alist)
  (let ((sbuffer ""))
    (foreach e (ruFlatten alist)
             (setq sbuffer (strcat sbuffer (sprintf nil "%L " e))))
    sbuffer))

(defun deleteNormalLabel ()
  (setq scv (geGetWindowCellView ))
  (foreach x (setof y scv~>shapes (equal y~>labelType "normalLabel"))
           (dbDeleteObject x)))
