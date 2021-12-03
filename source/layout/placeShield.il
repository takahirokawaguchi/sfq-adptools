(defun deleteAllShields ()
  (let (cv)
    (setq cv (geGetWindowCellView))
    (foreach 
      shield (setof x cv~>instances 
                    (or
                      (equal x~>cellName "shieldPTL2DRVREC")
                      (equal x~>cellName "shieldPTL2")
                      (equal x~>cellName "shieldPTL1")
                      ))
      (dbDeleteObject shield))))

(defun placeAllShields ()
  (let (cv net lib layer)
    (setq lib "ptlLayout")
    (setq cv (geGetWindowCellView ))
    (setq layer nil)
    (foreach
      net cv~>nets
      (foreach
        fig (setof x net~>figs (equal x~>objType "line"))
        (placeShield lib cv fig (mapcar 'getInstTermCoord net~>instTerms)))
      )))

(defun placeShield (lib cv fig psInstTerm)
  (let (points)
    (setq 
      pairsPoints 
      (list
        (list
          (car fig~>points)
          (cadr fig~>points))
        (list
          (car (last fig~>points))
          (nth (plus -2 (length fig~>points)) fig~>points)
          )))
    (foreach
      pairP pairsPoints
      (dbCreateInst
        cv 
        (cond
          ((member (car pairP) psInstTerm)
           (dbOpenCellViewByType
             lib
             "shieldPTL2DRVREC"
             "layout"))
          ((equal fig~>layerName "PTL2")
           (dbOpenCellViewByType
             lib
             "shieldPTL2"
             "layout"))
          ((equal fig~>layerName "PTL1")
           (dbOpenCellViewByType
             lib
             "shieldPTL1"
             "layout")))
        nil
        (car pairP)
        (calculateOrientShield pairP)
        ))
    ))

(defun calculateOrientShield (ps)
  (cond ((equal (xCoord (car ps))
                (xCoord (cadr ps)))
         (if (lessp (yCoord (car ps))
                    (yCoord (cadr ps)))
           "R90"
           "R270"
           ))
        ((equal (yCoord (car ps))
                (yCoord (cadr ps)))
         (if (lessp (xCoord (car ps))
                    (xCoord (cadr ps)))
           "R0"
           "R180"
           ))
        (t nil)))
