;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ＜SFQ回路の配線セル自動配置ツール＞
;;; 機能：virtuosoで配線用のラインが引かれた状態から，
;;; 　　　SetNetCells関数に対象となる配線オブジェクトなどを与えて，
;;; 　　　ラインに沿って配線セルを配置する．
;;;
;;; ＜バグ修正履歴＞
;;; 2010.7.18 配線の最初と最後のセルの配置に不具合が生じるのを解消
;;;           (セルがドライバ上に乗るor最後のセルが上手く配置しない)
;;;
;;; ＜現状わかっている不具合＞
;;; ドライバからレシーバに至る配線以外の配線に本ツールを適用すると動かなくなる
;;;
;;; （情報システム学演習Aの一環として作成）
;;; 製作者：名古屋大学 大学院情報科学研究科
;;;         情報システム学専攻 高田研究室 修士2年 立松知紘(350902178)
;;; 製作年月日：2010年7月18日
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;revising NET2PTL_PTLLIB by kawaguchi takahiro

;PTL1_width = 0.0875
;PTL2_width = 0.075
;Right = 0
;Up = 1
;Left = 2
;Down = 3

;; 配置するPTLセルおよびビアセルが属するライブラリを示すグローバル変数
;;(if (geGetWindowCellView )~>lib~>techLibName
;;  (defvar NET2PTL_PTLLIB (geGetWindowCellView )~>lib~>techLibName)
;;  (defvar NET2PTL_PTLLIB "adp634s")
;;  )

;;; 関数名：GetStartToGoal
;;; 引数：
;;;  NetSegmentDataList：ネットセグメントのオブジェクトIDのリスト
;;;  NetSegmentLineList：ネットセグメントの始点と終点がまとまったリスト
;;;  StartPoint：配線の始点座標
;;; 機能：
;;;  始点座標から終点座標に至るまでの通過座標のリストと，
;;;  通過順に並び替えたネットセグメントオブジェクトのリストが結合されたリストを返す．
;;;  通過座標のリストは，始点座標，配線の向きorレイヤが変わる座標，終点座標の順に格納されている．
;;;  なお，前提としてNetSegmentDataListとNetSegmentLineListは順番が対応しているものとする．
;;; 動作例：
;;;  NetSegmentDataList：(db:0x01 db:0x02 db:0x03)
;;;  NetSegmentLineList：(((1 3) (1 5)) ((0 3) (1 3)) ((1 5) (4 5)))
;;;  StartPoint：(0 3)
;;;  →返り値：(((0 3) (1 3) (1 5) (4 5)) (db:0x02 db:0x01 db:0x03))
procedure( GetStartToGoal( NetSegmentDataList NetSegmentLineList StartPoint )
           let( (NewNetLineList StartToGoalList SearchPoint NetSegment RemoveSegment LineData flag)
               SearchPoint = StartPoint
               StartToGoalList = list(SearchPoint)
               flag = 0

               while( NetSegmentLineList
                      for( i 0 length(NetSegmentLineList)
                             if( flag == 0
                                      then
                                      NetSegment = nth(i NetSegmentLineList)
                                      if( member(SearchPoint NetSegment) != nil
                                                                         then
                                                                         if( nth(0 NetSegment) == SearchPoint
                                                                                               then
                                                                                               SearchPoint = nth(1 NetSegment)
                                                                                               else
                                                                                               SearchPoint = nth(0 NetSegment)
                                                                                               ) ; if
                                                                         LineData = nth(i NetSegmentDataList)
                                                                         ;;;;println(LineData)
                                                                         StartToGoalList = append(StartToGoalList list(SearchPoint))
                                                                         NewNetLineList = append(NewNetLineList list(LineData))
                                                                         RemoveSegment = NetSegment
                                                                         flag = 1
                                                                         ) ; if
                                      ) ; if
                             ) ; for
                      NetSegmentLineList = remd(RemoveSegment NetSegmentLineList)
                      NetSegmentDataList = remd(LineData NetSegmentDataList)
                      flag = 0				
                      ) ; while
               ;;println(NetSegmentDataList)
               cons(StartToGoalList list(NewNetLineList))
               ) ; let
           ) ; procedure


;;; 関数名：GetCornerPointList
;;; 引数：
;;;  StartToGoalList：配線の始点から終点までの通過座標がまとまったリスト
;;; 機能：
;;;  StartToGoalListの中で，配線の向きorレイヤが変わる座標がまとまったリストを返す．
;;;  要は，StartToGoalListから始点座標と終点座標を抜いたものを返せばよい．
;;; 動作例：
;;;  StartToGoalList：((0 3) (1 3) (1 5) (4 5))
;;;  →返り値：((1 3) (1 5))
procedure( GetCornerPointList( StartToGoalList )
           let( (CornerPointList)
               for( i 1 length(StartToGoalList)-2
                      CornerPointList = append(CornerPointList list(nth(i StartToGoalList)))
                      );for
               CornerPointList
               ); let
           ); procedure


;;; 関数名：GetPathTrace
;;; 引数：
;;;  StartToGoalList：配線の始点から終点までの通過座標がまとまったリスト
;;; 機能：
;;;  StartToGoalListから，ポイント間の配線の向きをまとめたリストを返す．
;;;  出力で，0は右向き，1は上向き，2は左向き，3は下向きを指す．
;;; 動作例：
;;;  StartToGoalList：((0 3) (1 3) (1 5) (4 5))
;;;  →返り値：(0 1 0)
procedure( GetPathTrace( StartToGoalList )
           let( (NetVectorList BeforePoint AfterPoint delta_x delta_y)
               for( i 0 length(StartToGoalList)-2
                      BeforePoint = nth(i StartToGoalList)
                      AfterPoint = nth(i+1 StartToGoalList)

                      delta_x = xCoord(AfterPoint) -  xCoord(BeforePoint)
                      delta_y = yCoord(AfterPoint) -  yCoord(BeforePoint)

                      ;delta_x = nth(0 AfterPoint) - nth(0 BeforePoint)
                      ;delta_y = nth(1 AfterPoint) - nth(1 BeforePoint)

                      cond(
                           (delta_x > 0 && delta_y == 0
                                    NetVectorList = append(NetVectorList list(0)))
                           (delta_x == 0 && delta_y > 0
                                    NetVectorList = append(NetVectorList list(1)))
                           (delta_x < 0 && delta_y == 0
                                    NetVectorList = append(NetVectorList list(2)))
                           (delta_x == 0 && delta_y < 0
                                    NetVectorList = append(NetVectorList list(3)))
                           ); cond
                      ); for	
               NetVectorList	
               ); let
           ); procedure


;;; 関数名：ConvertGridCoordTrace
;;; 引数：
;;;  StartToGoalList：配線の始点から終点までの通過座標がまとまったリスト
;;; 機能：
;;;  StartToGoalListから，配線が通過するグリッド座標をまとめたリストを返す．
;;;  グリッドの単位あたりの長さは0.1875としている．
;;; 動作例：
;;;  StartToGoalList：((0 0.375) (0.1875 0.375) (0.1875 0.75))
;;;  →返り値：((0 2) (1 2) (1 3) (1 4))
procedure( ConvertGridCoordTrace( StartToGoalList )
           let( (Point GridPoint TmpGridCoordList BeforePoint AfterPoint GridCoordList)
               for( i 0 length(StartToGoalList)-1
                      Point = nth(i StartToGoalList)
                      GridPoint = list(floor(xCoord(Point)/0.1875) floor(yCoord(Point)/0.1875))
                      TmpGridCoordList = append(TmpGridCoordList list(GridPoint))
                      ); for

               ;;println(TmpGridCoordList)

               for( i 0 length(TmpGridCoordList)-2
                      BeforePoint = nth(i TmpGridCoordList)
                      AfterPoint = nth(i+1 TmpGridCoordList)

                      delta_x = xCoord(AfterPoint) -  xCoord(BeforePoint)
                      delta_y = yCoord(AfterPoint) -  yCoord(BeforePoint)

                      cond(
                           (delta_x > 0 && delta_y == 0
                                    x_Coord = xCoord(BeforePoint)
                                    while(x_Coord != xCoord(AfterPoint)
                                                  GridPoint = list(x_Coord yCoord(BeforePoint))
                                                  GridCoordList = append(GridCoordList list(GridPoint))
                                                  x_Coord++	
                                                  )
                                    )
                           (delta_x == 0 && delta_y > 0
                                    y_Coord = yCoord(BeforePoint)
                                    while(y_Coord != yCoord(AfterPoint)
                                                  GridPoint = list(xCoord(BeforePoint) y_Coord )
                                                  GridCoordList = append(GridCoordList list(GridPoint))
                                                  y_Coord++	
                                                  )
                                    )
                           (delta_x < 0 && delta_y == 0
                                    x_Coord = xCoord(BeforePoint)
                                    while(x_Coord != xCoord(AfterPoint)
                                                  GridPoint = list(x_Coord yCoord(BeforePoint))
                                                  GridCoordList = append(GridCoordList list(GridPoint))
                                                  x_Coord--	
                                                  )
                                    )
                           (delta_x == 0 && delta_y < 0
                                    y_Coord = yCoord(BeforePoint)
                                    while(y_Coord != yCoord(AfterPoint)
                                                  GridPoint = list(xCoord(BeforePoint) y_Coord)
                                                  GridCoordList = append(GridCoordList list(GridPoint))
                                                  y_Coord--
                                                  )
                                    )
                           ); cond
                      ); for	

               GridCoordList = append(GridCoordList list(AfterPoint))
               GridCoordList
               ); let
           ); procedure


;;; 関数名：ConvertGridCornerCoord
;;; 引数：
;;;  CornerPointList：配線の向きorレイヤが変わる座標がまとまったリスト
;;; 機能：
;;;  CornerPointListの座標を，グリッド座標に変換したリストを返す．
;;;  グリッドの単位あたりの長さは0.1875としている．
;;; 動作例：
;;;  CornerPointList：((0.1875 0.375) (0.1875 0.75))
;;;  →返り値：((1 2) (1 4))
procedure( ConvertGridCornerCoord( CornerPointList )
           let( (Point GridPoint GridCoordPointList GridCornerPointList)
               for( i 0 length(CornerPointList)-1
                      Point = nth(i CornerPointList)
                      GridPoint = list(floor(xCoord(Point)/0.1875) floor(yCoord(Point)/0.1875))
                      GridCornerPointList = append(GridCornerPointList list(GridPoint))
                      ); for
               GridCornerPointList
               ); let
           ); procedure


;;; 関数名：PutCell
;;; 引数：
;;;  scv：SchematicCellViewのオブジェクト
;;;  master：配置したいセルのオブジェクト
;;;  Coord：配置したい座標
;;;  Orient：セルの回転・反転の値
;;; 機能：
;;;  セルを配置する．
;;;  座標や回転反転についてはCoordとOrientで指定．
;;;  グリッドの単位あたりの長さは0.1875としている．
;;; 補足：
;;;  schCreateInstのみでは，回転や反転が生じたときに，
;;;  セルの基準となる座標が変わってしまうことがある．
;;;  その問題の対策のために本関数を作成した．
procedure( PutCell( scv master Coord Orient )
           let( (NewCoord)
               case( Orient
                     ( "R0"
                       NewCoord = Coord
                       schCreateInst(scv master nil NewCoord Orient)
                       )
                     ( "R90"
                       NewCoord = xCoord(Coord)+0.1875:yCoord(Coord)
                       schCreateInst(scv master nil NewCoord Orient)
                       )
                     ( "R180"
                       NewCoord = xCoord(Coord)+0.1875:yCoord(Coord)+0.1875
                       schCreateInst(scv master nil NewCoord Orient)
                       )
                     ( "R270"
                       NewCoord = xCoord(Coord):yCoord(Coord)+0.1875
                       schCreateInst(scv master nil NewCoord Orient)
                       )
                     ( "MXR90"
                       NewCoord = Coord
                       schCreateInst(scv master nil NewCoord Orient)
                       )
                     ( "MY"
                       NewCoord = xCoord(Coord)+0.1875:yCoord(Coord)
                       schCreateInst(scv master nil NewCoord Orient)
                       )
                     ( "MYR90"
                       NewCoord = xCoord(Coord)+0.1875:yCoord(Coord)+0.1875
                       schCreateInst(scv master nil NewCoord Orient)
                       )
                     ( "MX"
                       NewCoord = xCoord(Coord):yCoord(Coord)+0.1875
                       schCreateInst(scv master nil NewCoord Orient)
                       )
                     )
               ); let
           ); procedure


;;; 関数名：SetStraightCell
;;; 引数：
;;;  Width：配線の太さ（レイヤを意味することに等しい）
;;;    Vec：配線の向き
;;;  Point：配置するセルのグリッド座標
;;; 機能：
;;;  入力の3情報から適切な直線配線セルを配置する．
procedure( SetStraightCell( Width Vec Point)
           let( (NewPoint)
               NewPoint = list(xCoord(Point)*0.1875 yCoord(Point)*0.1875)
               case( Width
                     ( 0.0875;PTL1_width
                       master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1" "symbol_p")
                       case( Vec
                             ( 0
                               if( mod(yCoord(Point) 2) == 0
                                                        then
                                                        PutCell(scv master NewPoint "MX")
                                                        else
                                                        PutCell(scv master NewPoint "R0")
                                                        ); if	
                               )
                             ( 1
                               if( mod(xCoord(Point) 2) == 0
                                                        then
                                                        PutCell(scv master NewPoint "R90")
                                                        else
                                                        PutCell(scv master NewPoint "MXR90")
                                                        ); if	
                               )
                             ( 2
                               if( mod(yCoord(Point) 2) == 0
                                                        then
                                                        PutCell(scv master NewPoint "R180")
                                                        else
                                                        PutCell(scv master NewPoint "MY")
                                                        ); if
                               )
                             ( 3
                               if( mod(xCoord(Point) 2) == 0
                                                        then
                                                        PutCell(scv master NewPoint "MYR90")
                                                        else
                                                        PutCell(scv master NewPoint "R270")
                                                        ); if
                               )
                             ); case2
                       )
                     ( 0.075;PTL2_width
                       master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2" "symbol_p")
                       case( Vec
                             ( 0
                               if( mod(yCoord(Point) 2) == 0
                                                        then
                                                        PutCell(scv master NewPoint "MX")
                                                        else
                                                        PutCell(scv master NewPoint "R0")
                                                        ); if	
                               )
                             ( 1
                               if( mod(xCoord(Point) 2) == 0
                                                        then
                                                        PutCell(scv master NewPoint "R90")
                                                        else
                                                        PutCell(scv master NewPoint "MXR90")
                                                        ); if	
                               )
                             ( 2
                               if( mod(yCoord(Point) 2) == 0
                                                        then
                                                        PutCell(scv master NewPoint "R180")
                                                        else
                                                        PutCell(scv master NewPoint "MY")
                                                        ); if
                               )
                             ( 3
                               if( mod(xCoord(Point) 2) == 0
                                                        then
                                                        PutCell(scv master NewPoint "MYR90")
                                                        else
                                                        PutCell(scv master NewPoint "R270")
                                                        ); if
                               )
                             ); case2
                       )
                     ); case1
               ) ; let
           );


;;; 関数名：SetCornerCell
;;; 引数：
;;;  CWidth：現在の配線の太さ（レイヤを意味することに等しい）
;;;  NWidth：次の配線の太さ（レイヤを意味することに等しい）
;;;    CVec：現在の配線の向き
;;;    NVec：次の配線の向き
;;;   Point：配置するセルのグリッド座標
;;; 機能：
;;;  入力の5情報から適切な曲がる配線のセルを配置する．
;;;  バグが潜んでいる可能性がかなりある．
procedure( SetCornerCell( CWidth NWidth CVec NVec Point)
           let( (NewPoint)
               NewPoint = list(xCoord(Point)*0.1875 yCoord(Point)*0.1875)
               case( CWidth
                     ( 0.0875
                       case( NWidth
                             ( 0.0875
                               case( CVec
                                     ( 0
                                       case( NVec
                                             ( 1
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1ic" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1hc" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1c" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1icr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R270")
                                                                           )
                                                    );cond
                                               )
                                             ( 3
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1c" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1icr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1ic" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1hc" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    );cond
                                               )
                                             );case4
                                       )
                                     ( 1
                                       case( NVec
                                             ( 0
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1ic" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1c" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1hc" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1icr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    );cond
                                               )
                                             ( 2
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1c" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1ic" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1icr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1hc" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    );cond
                                               )
                                             );case4
                                       )
                                     ( 2
                                       case( NVec
                                             ( 1
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1hc" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1ic" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1icr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1c" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    );cond
                                               )
                                             ( 3
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1icr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1c" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1hc" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1ic" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    );cond
                                               )
                                             );case4
                                       )
                                     ( 3
                                       case( NVec
                                             ( 0
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1hc" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1icr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1ic" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1c" "symbol_p")
                                                                           PutCell(scv master NewPoint "R270")
                                                                           )
                                                    );cond
                                               )
                                             ( 2
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1icr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1hc" "symbol_p")
                                                                           PutCell(scv master NewPoint "R270")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1c" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL1ic" "symbol_p")
                                                                           PutCell(scv master NewPoint "R270")
                                                                           )
                                                    );cond
                                               )
                                             );case4
                                       )
                                     );case3
                               )
                             ( 0.075
                               case( CVec
                                     ( 0
                                       case( NVec
                                             ( 0
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaor" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viar" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaor" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viar" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    );cond
                                               )
                                             ( 1
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaiocr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R270")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahcr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R270")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viacr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaicr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R270")
                                                                           )
                                                    );cond
                                               )
                                             ( 3
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viacr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaicr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaiocr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahcr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    );cond
                                               )
                                             );case4
                                       )
                                     ( 1
                                       case( NVec
                                             ( 0
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaiocr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viacr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahcr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaicr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    );cond
                                               )
                                             ( 1
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaor" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaor" "symbol_p")
                                                                           PutCell(scv master NewPoint "R270")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viar" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viar" "symbol_p")
                                                                           PutCell(scv master NewPoint "R270")
                                                                           )
                                                    );cond
                                               )
                                             ( 2
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viacr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaiocr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaicr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahcr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    );cond
                                               )
                                             );case4
                                       )
                                     ( 2
                                       case( NVec
                                             ( 1
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahcr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaiocr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaicr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viacr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R270")
                                                                           )
                                                    );cond
                                               )
                                             ( 2
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viar" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaor" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viar" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaor" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    );cond
                                               )
                                             ( 3
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaicr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viacr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahcr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaiocr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    );cond
                                               )
                                             );case4
                                       )
                                     ( 3
                                       case( NVec
                                             ( 0
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahcr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaicr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaiocr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viacr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    );cond
                                               )
                                             ( 2
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaicr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahcr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viacr" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaiocr" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    );cond
                                               )
                                             ( 3
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viar" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viar" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaor" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaor" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    );cond
                                               )
                                             );case4
                                       )
                                     );case3
                               )
                             ); case2
                       )
                     ( 0.075
                       case( NWidth
                             ( 0.0875
                               case( CVec
                                     ( 0
                                       case( NVec
                                             ( 0
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "via" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viao" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "via" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viao" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    );cond
                                               )
                                             ( 1
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaic" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahc" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viac" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaioc" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    );cond
                                               )
                                             ( 3
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viac" "symbol_p")
                                                                           PutCell(scv master NewPoint "MX")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaioc" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaic" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahc" "symbol_p")
                                                                           PutCell(scv master NewPoint "R0")
                                                                           )
                                                    );cond
                                               )
                                             );case4
                                       )
                                     ( 1
                                       case( NVec
                                             ( 0
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaic" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viac" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahc" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaioc" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    );cond
                                               )
                                             ( 1
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "via" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "via" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viao" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viao" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    );cond
                                               )
                                             ( 2
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viac" "symbol_p")
                                                                           PutCell(scv master NewPoint "R90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaic" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaioc" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahc" "symbol_p")
                                                                           PutCell(scv master NewPoint "MXR90")
                                                                           )
                                                    );cond
                                               )
                                             );case4
                                       )
                                     ( 2
                                       case( NVec
                                             ( 1
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahc" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaic" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaioc" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viac" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    );cond
                                               )
                                             ( 2
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viao" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "via" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viao" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "via" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    );cond
                                               )
                                             ( 3
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaioc" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viac" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahc" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaic" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    );cond
                                               )
                                             );case4
                                       )
                                     ( 3
                                       case( NVec
                                             ( 0
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahc" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaioc" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaic" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viac" "symbol_p")
                                                                           PutCell(scv master NewPoint "R270")
                                                                           )
                                                    );cond
                                               )
                                             ( 2
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viahc" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaic" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viaioc" "symbol_p")
                                                                           PutCell(scv master NewPoint "R180")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viac" "symbol_p")
                                                                           PutCell(scv master NewPoint "MY")
                                                                           )
                                                    );cond
                                               )
                                             ( 3
                                               cond(
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viao" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "viao" "symbol_p")
                                                                           PutCell(scv master NewPoint "R270")
                                                                           )
                                                    ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "via" "symbol_p")
                                                                           PutCell(scv master NewPoint "MYR90")
                                                                           )
                                                    ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                           master = dbOpenCellViewByType(NET2PTL_PTLLIB "via" "symbol_p")
                                                                           PutCell(scv master NewPoint "R270")
                                                                           )
                                                    );cond
                                               )
                                             );case4
                                       )
                                     );case3
                               )
                             (0.075
                              case( CVec
                                    ( 0
                                      case( NVec
                                            ( 1
                                              cond(
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2ic" "symbol_p")
                                                                          PutCell(scv master NewPoint "MX")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2hc" "symbol_p")
                                                                          PutCell(scv master NewPoint "MX")
                                                                          )
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2c" "symbol_p")
                                                                          PutCell(scv master NewPoint "R0")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2icr" "symbol_p")
                                                                          PutCell(scv master NewPoint "R270")
                                                                          )
                                                   );cond
                                              )
                                            ( 3
                                              cond(
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2c" "symbol_p")
                                                                          PutCell(scv master NewPoint "MX")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2icr" "symbol_p")
                                                                          PutCell(scv master NewPoint "MXR90")
                                                                          )
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2ic" "symbol_p")
                                                                          PutCell(scv master NewPoint "R0")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2hc" "symbol_p")
                                                                          PutCell(scv master NewPoint "R0")
                                                                          )
                                                   );cond
                                              )
                                            );case4
                                      )
                                    ( 1
                                      case( NVec
                                            ( 0
                                              cond(
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2ic" "symbol_p")
                                                                          PutCell(scv master NewPoint "R90")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2c" "symbol_p")
                                                                          PutCell(scv master NewPoint "MXR90")
                                                                          )
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2hc" "symbol_p")
                                                                          PutCell(scv master NewPoint "R90")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2icr" "symbol_p")
                                                                          PutCell(scv master NewPoint "MY")
                                                                          )
                                                   );cond
                                              )
                                            ( 2
                                              cond(
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2c" "symbol_p")
                                                                          PutCell(scv master NewPoint "R90")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2ic" "symbol_p")
                                                                          PutCell(scv master NewPoint "MXR90")
                                                                          )
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2icr" "symbol_p")
                                                                          PutCell(scv master NewPoint "R0")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2hc" "symbol_p")
                                                                          PutCell(scv master NewPoint "MXR90")
                                                                          )
                                                   );cond
                                              )
                                            );case4
                                      )
                                    ( 2
                                      case( NVec
                                            ( 1
                                              cond(
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2hc" "symbol_p")
                                                                          PutCell(scv master NewPoint "R180")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2ic" "symbol_p")
                                                                          PutCell(scv master NewPoint "R180")
                                                                          )
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2icr" "symbol_p")
                                                                          PutCell(scv master NewPoint "MYR90")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2c" "symbol_p")
                                                                          PutCell(scv master NewPoint "MY")
                                                                          )
                                                   );cond
                                              )
                                            ( 3
                                              cond(
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2icr" "symbol_p")
                                                                          PutCell(scv master NewPoint "R90")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2c" "symbol_p")
                                                                          PutCell(scv master NewPoint "R180")
                                                                          )
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2hc" "symbol_p")
                                                                          PutCell(scv master NewPoint "MY")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2ic" "symbol_p")
                                                                          PutCell(scv master NewPoint "MY")
                                                                          )
                                                   );cond
                                              )
                                            );case4
                                      )
                                    ( 3
                                      case( NVec
                                            ( 0
                                              cond(
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2hc" "symbol_p")
                                                                          PutCell(scv master NewPoint "MYR90")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2icr" "symbol_p")
                                                                          PutCell(scv master NewPoint "R180")
                                                                          )
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2ic" "symbol_p")
                                                                          PutCell(scv master NewPoint "MYR90")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2c" "symbol_p")
                                                                          PutCell(scv master NewPoint "R270")
                                                                          )
                                                   );cond
                                              )
                                            ( 2
                                              cond(
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2icr" "symbol_p")
                                                                          PutCell(scv master NewPoint "MX")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) == 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2hc" "symbol_p")
                                                                          PutCell(scv master NewPoint "R270")
                                                                          )
                                                   ( mod(xCoord(Point) 2) == 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2c" "symbol_p")
                                                                          PutCell(scv master NewPoint "MYR90")
                                                                          )
                                                   ( mod(xCoord(Point) 2) != 0 && mod(yCoord(Point) 2) != 0
                                                                          master = dbOpenCellViewByType(NET2PTL_PTLLIB "PTL2ic" "symbol_p")
                                                                          PutCell(scv master NewPoint "R270")
                                                                          )
                                                   );cond
                                              )
                                            );case4
                                      )
                                    );case3
                              )
                             ); case2
                       )
                     ); case1
               ) ; let
           );


;;; 関数名：SetNetCells
;;; 引数：
;;;         scv：現在の配線の太さ（レイヤを意味することに等しい）
;;;      NetTmp：次の配線の太さ（レイヤを意味することに等しい）
;;;  deleteflag：現在の配線の向き
;;; 機能：
;;;  レイアウト上に引かれたラインに沿って適切なセルを配置する．
;;;  仮にdeleteflagがnilではないとき，配線セル配置と同時にラインを消去．
procedure( SetNetCells( scv NetTmp deleteflag)
           let( (NetSegmentDataList NetSegmentLineList outputPin StartPoint 
                                    TmpList StartToGoalList NetNewList NetNewWidthList CornerPointList 
                                    NetVectorList GridCoordList CornerCoordList
                                    GridTmp CurrentNetPart CurrentVec NextNetPart NextNetWidth NextVec)

               ;;; 配線のセグメントのオブジェクトID群をリストにまとめる
               NetSegmentDataList = NetTmp~>figs

               ;;; 配線セグメントの始点終点の座標をまとめたリストを生成
               NetSegmentLineList = NetSegmentDataList~>points

               ;;; 配線の始点をピックアップ
               outputPin = (car (setof it NetTmp~>instTerms it~>direction=="output"))
               StartPoint = (getInstTermCoord outputPin)

               ;;; 始点から終点に至る座標がまとまったリストと，
               ;;; その順に応じて並び替えた配線セグメントオブジェクトを取得
               ;;; GetStartToGoal関数から取得したリストの第一要素が前者で，第二要素が後者なので，上手く分割する．
               TmpList = GetStartToGoal( NetSegmentDataList NetSegmentLineList StartPoint )
               StartToGoalList = nth(0 TmpList)
               NetNewList = nth(1 TmpList)

               ;;; 配線セグメントオブジェクトから各セグメントの幅をまとめたリストを生成
               NetNewWidthList = foreach( mapcar x NetNewList x~>width)

               ;;; 向きorレイヤが変わる座標をまとめたリストの生成
               CornerPointList = GetCornerPointList( StartToGoalList )

               ;;; 配線の向きをまとめたリストの生成
               NetVectorList = GetPathTrace( StartToGoalList )

               ;;; 配線が通過するグリッド座標をまとめたリストの取得
               GridCoordList = ConvertGridCoordTrace( StartToGoalList )

               ;;; 配線が曲がるorレイヤが変わるグリッド座標のリストを取得
               CornerCoordList = ConvertGridCornerCoord( CornerPointList )

               ;;; For Debug
               ;;println(CornerPointList)		
               ;;println(GridCoordList)
               ;;println(CornerCoordList)
               ;;println(StartToGoalList)
               ;;println(NetNewWidthList)
               ;;println(NetVectorList)
               ;;println(StartPoint)
               ;;println(NetTmp~>figs)

               ;;; deleteflagの値に応じて，ラインの消去
               if(deleteflag 
                   for(i 0 length(NetNewList)-1
                         dbDeleteObject(nth(i NetNewList))
                         );for
                   );if

               ;;; 最初のセルの配置．
               ;;; 最初の配線の向きが右から左or上から下の場合，
               ;;; 現在の仕様ではドライバ上にセルを配置してしまうため，それを回避するために，
               ;;; 次のwhileに含めないことにした．
               if( length(GridCoordList) > 1
                                         then
                                         ;;; 処理対象となるグリッド座標を読み取る
                                         ;;; これは，通過するグリッド座標がまとまったリストの先頭を読めばよい
                                         GridTmp = nth(0 GridCoordList)

                                         ;;; 対象のセルが直線のものか曲線のものかの条件分岐
                                         if( member(GridTmp CornerCoordList) == nil
                                                                             then
                                                                             ;;; 現在の配線の幅（レイヤ）の値を取得
                                                                             CurrentNetWidth = nth(0 NetNewWidthList)

                                                                             ;;; 現配線の向きをピックアップ
                                                                             CurrentVec = nth(0 NetVectorList)

                                                                             ;;; 直線のセルを配置　あとは先に宣言した関数に任せる
                                                                             ;;; ただし，左向きor下向きの場合，ドライバ上にセルが配置されてしまうので，
                                                                             ;;; 右向きor上向きの場合のみセルを配置する
                                                                             if( CurrentVec < 2
                                                                                            SetStraightCell(CurrentNetWidth CurrentVec GridTmp)
                                                                                            );if
                                                                             else
                                                                             ;;; 現在の配線の幅と向きを取得
                                                                             CurrentNetWidth = nth(0 NetNewWidthList)
                                                                             CurrentVec = nth(0 NetVectorList)

                                                                             ;;; セグメントが変わるため，リストからこれまでのセグメントの部分を削除
                                                                             NetNewWidthList = cdr(NetNewWidthList)
                                                                             NetVectorList = cdr(NetVectorList)

                                                                             ;;; 次の配線の幅と向きを取得
                                                                             NextNetWidth = nth(0 NetNewWidthList)
                                                                             NextVec = nth(0 NetVectorList)

                                                                             ;;; 曲線のセルを配置　あとは先に宣言した関数に任せる
                                                                             ;;; ただし，左向きor下向きの場合，ドライバ上にセルが配置されてしまうので，
                                                                             ;;; 右向きor上向きの場合のみセルを配置する
                                                                             if( CurrentVec < 2
                                                                                            SetCornerCell(CurrentNetWidth NextNetWidth CurrentVec NextVec GridTmp)
                                                                                            );if

                                                                             ;;; for Debug
                                                                             ;;println(CurrentNetPart)
                                                                             ;;println(NextNetPart)
                                                                             ;;println(CurrentNetWidth)
                                                                             ;;println(NextNetWidth)
                                                                             ;;println(NetNewList)
                                                                             ); if

                                         ;;; すでに処理を終えたグリッド座標を除去
                                         GridCoordList = cdr(GridCoordList)
                                         ); if

               ;;; 最初と最後以外のセルの配置．
               ;;; whileループ内で，まず直線のセルを配置するか，曲線のセルを配置するかの条件を判定する．
               ;;; 次に，各条件に応じて，必要な情報を取得し，取得した情報からセルを配置する関数を呼び出す．
               while( length(GridCoordList) > 1

                                            ;;; 処理対象となるグリッド座標を読み取る
                                            ;;; これは，通過するグリッド座標がまとまったリストの先頭を読めばよい
                                            GridTmp = nth(0 GridCoordList)

                                            ;;; 対象のセルが直線のものか曲線のものかの条件分岐
                                            if( member(GridTmp CornerCoordList) == nil
                                                                                then
                                                                                ;;; 現在の配線の幅（レイヤ）の値を取得
                                                                                CurrentNetWidth = nth(0 NetNewWidthList)

                                                                                ;;; 現配線の向きをピックアップ
                                                                                CurrentVec = nth(0 NetVectorList)

                                                                                ;;; 直線のセルを配置　あとは先に宣言した関数に任せる
                                                                                SetStraightCell(CurrentNetWidth CurrentVec GridTmp)
                                                                                else
                                                                                ;;; 現在の配線の幅と向きを取得
                                                                                CurrentNetWidth = nth(0 NetNewWidthList)
                                                                                CurrentVec = nth(0 NetVectorList)

                                                                                ;;; セグメントが変わるため，リストからこれまでのセグメントの部分を削除
                                                                                NetNewWidthList = cdr(NetNewWidthList)
                                                                                NetVectorList = cdr(NetVectorList)

                                                                                ;;; 次の配線の幅と向きを取得
                                                                                NextNetWidth = nth(0 NetNewWidthList)
                                                                                NextVec = nth(0 NetVectorList)

                                                                                ;;; 曲線のセルを配置　あとは先に宣言した関数に任せる
                                                                                SetCornerCell(CurrentNetWidth NextNetWidth CurrentVec NextVec GridTmp)

                                                                                ;;; for Debug
                                                                                ;;println(CurrentNetPart)
                                                                                ;;println(NextNetPart)
                                                                                ;;println(CurrentNetWidth)
                                                                                ;;println(NextNetWidth)
                                                                                ;;println(NetNewList)
                                                                                ); if

                                            ;;; すでに処理を終えたグリッド座標を除去
                                            GridCoordList = cdr(GridCoordList)
                                            ); while

               ;;; 最後のセルの配置用
               if( length(GridCoordList) == 1
                                         then
                                         ;;; 処理対象となるグリッド座標を読み取る
                                         ;;; これは，通過するグリッド座標がまとまったリストの先頭を読めばよい
                                         GridTmp = nth(0 GridCoordList)

                                         ;;; 対象のセルが直線のものか曲線のものかの条件分岐
                                         if( member(GridTmp CornerCoordList) == nil
                                                                             then
                                                                             ;;; 現在の配線の幅（レイヤ）の値を取得
                                                                             CurrentNetWidth = nth(0 NetNewWidthList)

                                                                             ;;; 現配線の向きをピックアップ
                                                                             CurrentVec = nth(0 NetVectorList)

                                                                             ;;; 直線のセルを配置　あとは先に宣言した関数に任せる
                                                                             ;;; ただし，右向きor上向きの場合，レシーバ上にセルが配置されてしまうので，
                                                                             ;;; 左向きor下向きの場合のみセルを配置する
                                                                             if( CurrentVec > 1
                                                                                            SetStraightCell(CurrentNetWidth CurrentVec GridTmp)
                                                                                            );if
                                                                             else
                                                                             ;;; 現在の配線の幅と向きを取得
                                                                             CurrentNetWidth = nth(0 NetNewWidthList)
                                                                             CurrentVec = nth(0 NetVectorList)

                                                                             ;;; セグメントが変わるため，リストからこれまでのセグメントの部分を削除
                                                                             NetNewWidthList = cdr(NetNewWidthList)
                                                                             NetVectorList = cdr(NetVectorList)

                                                                             ;;; 次の配線の幅と向きを取得
                                                                             NextNetWidth = nth(0 NetNewWidthList)
                                                                             NextVec = nth(0 NetVectorList)

                                                                             ;;; 曲線のセルを配置　あとは先に宣言した関数に任せる
                                                                             ;;; ただし，右向きor上向きの場合，レシーバ上にセルが配置されてしまうので，
                                                                             ;;; 左向きor下向きの場合のみセルを配置する
                                                                             if( NextVec > 1
                                                                                         SetCornerCell(CurrentNetWidth NextNetWidth CurrentVec NextVec GridTmp)
                                                                                         );if

                                                                             ;;; for Debug
                                                                             ;;println(CurrentNetPart)
                                                                             ;;println(NextNetPart)
                                                                             ;;println(CurrentNetWidth)
                                                                             ;;println(NextNetWidth)
                                                                             ;;println(NetNewList)
                                                                             ); if

                                         ;;; すでに処理を終えたグリッド座標を除去
                                         GridCoordList = cdr(GridCoordList)
                                         ); if

               ); let
           )
