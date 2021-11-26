(defun fillMoatADP (cellViewId libName)
  (let ( cellbBox
         masterCellViewId
         llX llY urX urY
         lenX lenY
         moatArray
         cellSize xCell yCell corners
         llxCell llyCell urxCell uryCell x y
         (ignoreLibs '( "analogJJ" "basic" ))
         (ignoreCells '( "sfqdc*" "dcsfq*" "ipin" "opin" "^PTL*" "via*" ))
         ( SFQLayoutSymbolUnitLength 0.375)
         )

    (unless libName
      (setq libName
        guessRefLibId( cellViewId )~>name))

    ; check if the moat cell exists
    (if masterCellViewId = 
      (dbOpenCellViewByType
        ;guessRefLibId( cellViewId )~>name
        libName
        "moat"
        "symbol_p"
        nil
        "r")
      then
      ; calculate the number of cells in x and y-axis
      cellbBox = getCellViewbBoxADP( cellViewId SFQLayoutSymbolUnitLength ignoreLibs ignoreCells)
      llX = xCoord( lowerLeft( cellbBox ) )
      llY = yCoord( lowerLeft( cellbBox ) )
      urX = xCoord( upperRight( cellbBox ) )
      urY = yCoord( upperRight( cellbBox ) )

      lenX = floor( (urX - llX) / SFQLayoutSymbolUnitLength )
      lenY = floor( (urY - llY) / SFQLayoutSymbolUnitLength )

      ; declare 2D array for moat filling
      moatArray = makeMoatArray( lenX lenY )
      (for indexY 0 lenY-1
           (for indexX 0 lenX-1
                moatArray[indexX][indexY] = t
                ))

      ; set moatArray t if a cell exists
      (foreach
        inst cellViewId~>instances
        (when !member( inst~>libName ignoreLibs ) &&
          !member( t foreach( mapcar cell ignoreCells
                                     rexMatchp( cell inst~>cellName ) ) )

          ; calculate the lower-left and upper-right coordinates of the instance
          cellbBox = getCellbBoxADP( inst SFQLayoutSymbolUnitLength)
          llxCell = xCoord( lowerLeft( cellbBox ) )
          llyCell = yCoord( lowerLeft( cellbBox ) )
          urxCell = xCoord( upperRight( cellbBox ) )
          uryCell = yCoord( upperRight( cellbBox ) )

          ; set moatArray t in accordnace with the cell coordinates
          (for indexY floor( ( llyCell - llY )/SFQLayoutSymbolUnitLength )
               floor( ( uryCell - llY )/SFQLayoutSymbolUnitLength ) - 1
               (for indexX floor( ( llxCell - llX )/SFQLayoutSymbolUnitLength )
                    floor( ( urxCell - llX )/SFQLayoutSymbolUnitLength ) - 1
                    moatArray[indexX][indexY]=nil
                    ))))

      ; read moatArray and place a moat if moatArray==t
      (for indexY 0 lenY-1
           (for indexX 0 lenX-1
                (when moatArray[indexX][indexY]
                  (dbCreateInst cellViewId
                                masterCellViewId
                                nil
                                llX+indexX*SFQLayoutSymbolUnitLength:
                                llY+indexY*SFQLayoutSymbolUnitLength
                                "R0"
                                ))))
      else
      ; uless a moat cannot find in the cell libaray
      (printf "Error: Cannot find a moat cell in Lib: %s"
              (guessRefLib cellViewId )~>name )
      )))

;   returns the lower-left and upper-right coordinates of the instances
;   in the cellView.
(defun getCellViewbBoxADP (cellViewId SFQLayoutSymbolUnitLength ignoreLibs ignoreCells)
  (let ( ; do not consider cells in ignoreLibs or that matches to ignoreCells
         cellbBox
         llx lly urx ury
         llxCell llyCell urxCell uryCell
         llxInst
         )

    (foreach inst cellViewId~>instances
             (when (null (member inst~>libName ignoreLibs )) &&
               (null (orList (mapcar (lambda (x) (rexMatchp x inst~>cellName ))
                                     ignoreCells)))

               cellbBox = getCellbBoxADP( inst SFQLayoutSymbolUnitLength)
               llxCell = xCoord( lowerLeft( cellbBox ) )
               llyCell = yCoord( lowerLeft( cellbBox ) )
               urxCell = xCoord( upperRight( cellbBox ) )
               uryCell = yCoord( upperRight( cellbBox ) )

               ; initial assignment
               !llx && (llx = llxCell)
               !lly && (lly = llyCell)
               !urx && (urx = urxCell)
               !ury && (ury = uryCell)

               llxCell && llx && llx>llxCell && (llx = llxCell)
               llyCell && lly && lly>llyCell && (lly = llyCell)
               urxCell && urx && urx<urxCell && (urx = urxCell)
               uryCell && ury && ury<uryCell && (ury = uryCell)
               ))
    (list llx:lly urx:ury)
    ))

; declare 2D array
(defun makeMoatArray (nX nY)
  (let ( xArray x )
    (declare xArray[ nX ] )
    (for i 0 nX-1
         declare( x[ nY ] )
         xArray[ i ] = x
         )
    xArray
    ))

; getCellbBoxADP( inst )
; => ( llx:lly urx:ury ) in cellView
(defun getCellbBoxADP ( inst SFQLayoutSymbolUnitLength )
  (let 
    (cellSize xy llxCell llyCell urxCell uryCell)
    (setq cellSize (getCellSizeADP inst~>master))
    ;(printf "debug1%L\n" cellSize)
    (setq xy (plusCoord inst~>xy (offSetCoord cellSize inst~>orient)))
    (setq llxCell (xCoord xy))
    (setq llyCell (yCoord xy))
    (setq urxCell (plus llxCell (xCoord cellSize)))
    (setq uryCell (plus llyCell (yCoord cellSize)))
    list( llxCell:llyCell urxCell:uryCell )
    ))

(defun offSetCoord (size orient)
  ;;R0    , MXR90  ( 0, 0)
  ;;R90   , MY     (-x, 0)
  ;;R180  , MYR90  (-x,-y)
  ;;R270  , MX     ( 0,-y)
  (let (mx my)
    (setq mx (minus (xCoord size)))
    (setq my (minus (yCoord size)))
    (cond 
      ((or (equal orient "R0")
           (equal orient "MXR90"))
       (list 0 0))
      ((or (equal orient "R90")
           (equal orient "MY"))
       (list mx 0))
      ((or (equal orient "R180")
           (equal orient "MYR90"))
       (list mx my))
      ((or (equal orient "R270")
           (equal orient "MX"))
       (list 0 my))
      )))

(defun getCellSizeADP (cellViewId)
  (let ( bBox x y xu yu)
    (when (or (equal cellViewId~>viewName "symbol_p")
              (equal cellViewId~>viewName "symbol_b"))
      (setq bBox (car (setof s cellViewId~>shapes
                             s~>layerName=="instance" &&
                             s~>purpose=="drawing" &&
                             s~>objType=="rect" ))~>bBox)
      x = xCoord( upperRight( bBox ) ) - xCoord( lowerLeft( bBox ) )
      y = yCoord( upperRight( bBox ) ) - yCoord( lowerLeft( bBox ) )
      list( x y )
      )))
