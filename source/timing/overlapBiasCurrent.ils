; (load "../../git/dat/source/overlapBiasCurrent.il")
; (dbOpenCellViewByType (car varDebug)~>master~>libName (car varDebug)~>cellName "layout")

(defun getOverlapBiasLeads ()
  (let (scv fileName out gcs)
    (setq scv (geGetWindowCellView ))
    (sprintf fileName "gridCoordsBiasLeads_%s.txt" scv~>cellName)
    (setq out (outfile fileName "w"))
    (setq gcs nil)
    (foreach
      inst scv~>instances
      (unless 
        (or
          (isPTL inst)
          (isIpin inst)
          (isOpin inst)
          )
        (setq gcs 
              (append gcs
                      (getGridCoordBiasLeads inst)))
        ))
    (setq gcs (sortcar gcs 'lessp))
    (for i (caar gcs) (caar (last gcs))
      (let (listYN)
        (setq listYN nil)
        (foreach gc gcs
                 (when (equal i (car gc)) (setq listYN (cons (cdr gc) listYN))))
        (setq listYN (sortcar listYN 'lessp))
        (for j (caar listYN) (caar (last listYN))
             (let (listN)
               (setq listN nil)
               (foreach YN listYN
                        (when (equal j (car YN)) (setq listN (cons (cadr YN) listN))))
               (when 
                 (orList
                   (mapcar '(lambda (x) (apply 'compareArrivalTime x))
                           (combination 2 listN)))
                 (fprintf out "%d %d %L\n" i j listN~>name))
               ))
        ))
    (close out)
    ))

(defun combination (n list)
  (cond
    ((or (equal n 0) (null list)) nil)
    ((equal n 1) (mapcar '(lambda (res) (cons res nil)) list))
    (t
      (append
        (mapcar '(lambda (res)
                   (cons (car list) res)) (combination (n - 1) (cdr list)))
        (combination n (cdr list))))))

(defun compareArrivalTime (inst1 inst2)
  (let (ls)
    (setq ls nil)
    ;(printf "%L %L" inst1~>name inst2~>name)
    (foreach
      x (outputTerms inst1)
      (foreach
        y (outputTerms inst2)
        (setq
          ls
          (append
            (list
              (lessp (abs (difference x~>arvTimeMax y~>arvTimeMax)) 3.0)
              (lessp (abs (difference x~>arvTimeMin y~>arvTimeMin)) 3.0))
              ls))
        ))
    (orList ls)
    ))

(defun assqList (ls value)
  (if (equal value (car ls))
    (cdr ls)
    nil))


(defun getGridCoordInstLL (instance)
  (let (coord (SFQLayoutSymbolUnitLength 0.375))
    (setq coord
          (mapcar '(lambda (x) (ceiling (x/(RINER.SCHEM_GRID_LEN*2.0))))
                  (lowerLeft (getCellbBoxADP instance SFQLayoutSymbolUnitLength))
                ))
    ))

(defun getGridCoordBiasLeads (instance)
  (let ( instLayout
         coordLL
         coordBCs
         size
         coordBLs
         (SFQLayoutSymbolUnitLength 0.375))
    (setq coordLL (getGridCoordInstLL instance))
    ;(setq size (getCellSize instance~>master SFQLayoutSymbolUnitLength))
    (setq size (getCellSize instance~>master))
    (cond
      ((equal (cadr instance~>transform) "R90")
       (setq coordLL (diffCoord coordLL (list (cadr size) 0))))
      ((equal (cadr instance~>transform) "R180")
       (setq coordLL (diffCoord coordLL size)))
      ((equal (cadr instance~>transform) "R270")
       (setq coordLL (diffCoord coordLL (list 0 (car size)))))
      ((equal (cadr instance~>transform) "MY")
       (setq coordLL (diffCoord coordLL (list (car size) 0))))
      ((equal (cadr instance~>transform) "MYR90")
       (setq coordLL (diffCoord coordLL (list (cadr size) (car size)))))
      ((equal (cadr instance~>transform) "MX")
       (setq coordLL (diffCoord coordLL (list 0 (cadr size)))))
      )
    (setq instLayout
          (dbOpenCellViewByType 
            instance~>master~>libName
            instance~>cellName
            "layout"))
    (setq coordBCs nil)
    (foreach p instLayout~>instances
             (when p~>biasLeads
               (setq coordBCs (cons (mapcar '(lambda (x) (round x / 30.0)) p~>xy)
                                    coordBCs))))
    ;(printf "%L\n" instance~>name)
    ;(printf "%L %L %L\n" coordLL coordBCs size)
    ;(printf "%L\n" (transformGridCoord (car coordBCs) size (cadr instance~>transform)))
    (setq coordBLs
          (mapcar '(lambda (x)
                     (plusCoord coordLL
                                (car (transformGridCoord
                                       x size (cadr instance~>transform)))))
                  coordBCs))
    (mapcar '(lambda (x) (append x  (list instance)))
            coordBLs)
    ))

(defun plusCoord (coord1 coord2)
  (list 
    (plus (car coord1) (car coord2))
    (plus (cadr coord1) (cadr coord2))
    ))
(defun diffCoord (coord1 coord2)
  (list 
    (difference (car coord1) (car coord2))
    (difference (cadr coord1) (cadr coord2))
    ))

(defun transformGridCoord (gridCoord size rotate)
  (cond
    ((equal rotate "R0") (list gridCoord size))
    ((equal rotate "R90")
     (rotateGridCoord
       (list gridCoord size)))
    ((equal rotate "R180")
     (rotateGridCoord
       (rotateGridCoord
         (list gridCoord size))))
    ((equal rotate "R270")
     (rotateGridCoord
       (rotateGridCoord
         (rotateGridCoord
           (list gridCoord size)))))
    ((equal rotate "MY")
     (sideflipGridCoord
       (list gridCoord size)))
    ((equal rotate "MYR90")
     (rotateGridCoord 
       (sideflipGridCoord
         (list gridCoord size))))
    ((equal rotate "MX")
     (rotateGridCoord 
       (rotateGridCoord 
         (sideflipGridCoord
           (list gridCoord size)))))
    ((equal rotate "MXR90")
     (rotateGridCoord 
       (rotateGridCoord 
         (rotateGridCoord 
           (sideflipGridCoord
             (list gridCoord size))))))
    ))


;counterclock
(defun rotateGridCoord (listGCS)
  (let (gridCoord size)
    (setq gridCoord (car listGCS))
    (setq size (cadr listGCS))
    (cond
      ((equal size '(1 1))
       (cond
         ((equal gridCoord '(0 0)) (list '(1 0) '(1 1)))
         ((equal gridCoord '(1 0)) (list '(1 1) '(1 1)))
         ((equal gridCoord '(1 1)) (list '(0 1) '(1 1)))
         ((equal gridCoord '(0 1)) (list '(0 0) '(1 1)))
         ;for blockage of PTL driver and reciever 12
         ;*--* (-1  2) (2  2)
         ;----
         ;----
         ;*--* (-1 -1) (2 -1)
         ((equal gridCoord '( 2  2)) (list '(-1  2) '(1 1)))
         ((equal gridCoord '(-1  2)) (list '(-1 -1) '(1 1)))
         ((equal gridCoord '(-1 -1)) (list '( 2 -1) '(1 1)))
         ((equal gridCoord '( 2 -1)) (list '( 2  2) '(1 1)))
         ;-*-- ( 0  2)
         ;---* ( 2  1)
         ;*--- (-1  0)
         ;--*- ( 1 -1)
         ((equal gridCoord '( 2  1)) (list '( 0   2) '(1 1)))
         ((equal gridCoord '( 0  2)) (list '(-1   0) '(1 1)))
         ((equal gridCoord '(-1  0)) (list '( 1  -1) '(1 1)))
         ((equal gridCoord '( 1 -1)) (list '( 2   1) '(1 1)))
         ;--*- ( 1  2)
         ;*--- (-1  1)
         ;---* ( 2  0)
         ;-*-- ( 0 -1)
         ((equal gridCoord '( 2  0)) (list '( 1  2) '(1 1)))
         ((equal gridCoord '( 1  2)) (list '(-1  1) '(1 1)))
         ((equal gridCoord '(-1  1)) (list '( 0 -1) '(1 1)))
         ((equal gridCoord '( 0 -1)) (list '( 2  0) '(1 1)))
         ))
      ((equal size '(1 2))
       (cond
         ((equal gridCoord '(0 0)) (list '(2 0) '(2 1)))
         ((equal gridCoord '(1 0)) (list '(2 1) '(2 1)))
         ((equal gridCoord '(1 2)) (list '(0 1) '(2 1)))
         ((equal gridCoord '(0 2)) (list '(0 0) '(2 1)))
         ((equal gridCoord '(0 1)) (list '(1 0) '(2 1)))
         ((equal gridCoord '(1 1)) (list '(1 1) '(2 1)))
         ))
      ((equal size '(2 1))
       (cond
         ((equal gridCoord '(0 0)) (list '(1 0) '(1 2)))
         ((equal gridCoord '(2 0)) (list '(1 2) '(1 2)))
         ((equal gridCoord '(2 1)) (list '(0 2) '(1 2)))
         ((equal gridCoord '(0 1)) (list '(0 0) '(1 2)))
         ((equal gridCoord '(1 0)) (list '(1 1) '(1 2)))
         ((equal gridCoord '(1 1)) (list '(0 1) '(1 2)))
         ))
      ((equal size '(2 2))
       (cond
         ((equal gridCoord '(0 0)) (list '(2 0) '(2 2)))
         ((equal gridCoord '(2 0)) (list '(2 2) '(2 2)))
         ((equal gridCoord '(2 2)) (list '(0 2) '(2 2)))
         ((equal gridCoord '(0 2)) (list '(0 0) '(2 2)))
         ((equal gridCoord '(1 0)) (list '(2 1) '(2 2)))
         ((equal gridCoord '(2 1)) (list '(1 2) '(2 2)))
         ((equal gridCoord '(1 2)) (list '(0 1) '(2 2)))
         ((equal gridCoord '(0 1)) (list '(1 0) '(2 2)))
         )))))

(defun sideflipGridCoord (listGCS)
  (let (gridCoord size)
    (setq gridCoord (car listGCS))
    (setq size (cadr listGCS))
    (cond
      ((equal size '(1 1))
       (cond
         ((equal gridCoord '(0 0)) (list '(1 0) '(1 1)))
         ((equal gridCoord '(1 0)) (list '(0 0) '(1 1)))
         ((equal gridCoord '(1 1)) (list '(0 1) '(1 1)))
         ((equal gridCoord '(0 1)) (list '(1 1) '(1 1)))
         ;for blockage of PTL driver and reciever 12
         ;*--*
         ;*--*
         ;*--*
         ;*--*
         ((equal gridCoord '(-1 -1)) (list '( 2 -1) '(1 1)))
         ((equal gridCoord '(-1  0)) (list '( 2  0) '(1 1)))
         ((equal gridCoord '(-1  1)) (list '( 2  1) '(1 1)))
         ((equal gridCoord '(-1  2)) (list '( 2  2) '(1 1)))
         ((equal gridCoord '( 2 -1)) (list '(-1 -1) '(1 1)))
         ((equal gridCoord '( 2  0)) (list '(-1  0) '(1 1)))
         ((equal gridCoord '( 2  1)) (list '(-1  1) '(1 1)))
         ((equal gridCoord '( 2  2)) (list '(-1  2) '(1 1)))
         ;-**-
         ;----
         ;----
         ;-**-
         ((equal gridCoord '( 0  2)) (list '( 1  2) '(1 1)))
         ((equal gridCoord '( 1  2)) (list '( 0  2) '(1 1)))
         ((equal gridCoord '( 0 -1)) (list '( 1 -1) '(1 1)))
         ((equal gridCoord '( 1 -1)) (list '( 0 -1) '(1 1)))
         ))
      ((equal size '(1 2))
       (cond
         ((equal gridCoord '(0 0)) (list '(1 0) '(1 2)))
         ((equal gridCoord '(1 0)) (list '(0 0) '(1 2)))
         ((equal gridCoord '(1 2)) (list '(0 2) '(1 2)))
         ((equal gridCoord '(0 2)) (list '(1 2) '(1 2)))
         ((equal gridCoord '(0 1)) (list '(1 1) '(1 2)))
         ((equal gridCoord '(1 1)) (list '(0 1) '(1 2)))
         ))
      ((equal size '(2 1))
       (cond
         ((equal gridCoord '(0 0)) (list '(2 0) '(2 1)))
         ((equal gridCoord '(2 0)) (list '(0 0) '(2 1)))
         ((equal gridCoord '(2 1)) (list '(0 1) '(2 1)))
         ((equal gridCoord '(0 1)) (list '(2 1) '(2 1)))
         ((equal gridCoord '(1 0)) (list '(1 0) '(2 1)))
         ((equal gridCoord '(1 1)) (list '(1 1) '(2 1)))
         ))
      ((equal size '(2 2))
       (cond
         ((equal gridCoord '(0 0)) (list '(2 0) '(2 2)))
         ((equal gridCoord '(2 0)) (list '(0 0) '(2 2)))
         ((equal gridCoord '(2 2)) (list '(0 2) '(2 2)))
         ((equal gridCoord '(0 2)) (list '(2 2) '(2 2)))
         ((equal gridCoord '(1 0)) (list '(1 0) '(2 2)))
         ((equal gridCoord '(2 1)) (list '(0 1) '(2 2)))
         ((equal gridCoord '(1 2)) (list '(1 2) '(2 2)))
         ((equal gridCoord '(0 1)) (list '(2 1) '(2 2)))
         )))))

