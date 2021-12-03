(defun postInstallTriggerSFQLayout (arg)
  (let 
    (mloadLayoutItem
      items)
    (setq items nil)
    ;(setq mloadLayoutItem
    (setq 
      items 
      (append1 items
               (hiCreateMenuItem
                 ?name 'mloadLayoutItem
                 ?itemText "mload ~/git/skill"
                 ?callback "(mload \"~/git/skill\")")))
    ;(setq placeViaItem
    (setq 
      items 
      (append1 items
               (hiCreateMenuItem
                 ?name 'placeViaItem
                 ?itemText "placeVia"
                 ?callback "(placeVia )")))
    ;(setq setq_sel_geGetSelSetItem
    (setq 
      items 
      (append1 items
               (hiCreateMenuItem
                 ?name 'setq_sel_geGetSelSetItem
                 ?itemText "setq_sel_geGetSelSet"
                 ?callback "(setq sel (geGetSelSet ))")))
    ;(setq setq_cv_geGetWindowCellViewItem
    (setq 
      items 
      (append1 items
               (hiCreateMenuItem
                 ?name 'setq_cv_geGetWindowCellViewItem
                 ?itemText "setq_cv_geGetWindowCellView"
                 ?callback "(setq cv (geGetWindowCellView ))")))
    ;(setq deleteAllPathSegsItem
    (setq 
      items 
      (append1 items
               (hiCreateMenuItem
                 ?name 'deleteAllPathSegsItem
                 ?itemText "deleteAllPathSegs"
                 ?callback "(deleteAllPathSegs )")))
    ;(setq deleteAllTrlsItem
    (setq 
      items 
      (append1 items
               (hiCreateMenuItem
                 ?name 'deleteAllTrlsItem
                 ?itemText "deleteAllTrls"
                 ?callback "(deleteAllTrls )")))
    ;(setq deleteAllViasItem
    (setq 
      items 
      (append1 items
               (hiCreateMenuItem
                 ?name 'deleteAllViasItem
                 ?itemText "deleteAllVias"
                 ?callback "(deleteAllVias )")))
    (setq 
      items 
      (append1 items
               (hiCreateMenuItem
                 ?name 'routeFromSToLItem
                 ?itemText "routeFromSToL"
                 ?callback "(routeFromSToL )")))
    (setq sfqLayoutMenu
          (hiCreatePulldownMenu
            'sfqLayoutMenu
            "SFQ-Layout"
            items
            ))
    hiInsertBannerMenu(hiGetCurrentWindow() sfqLayoutMenu 11)
    ))

(when (deViewTypeIsRegistered "maskLayout" )
  (deRegUserTriggers 
    "maskLayout";layout editor L 
    nil 
    nil 
    'postInstallTriggerSFQLayout))

(when deViewTypeIsRegistered( "maskLayoutXL" )
  (deRegUserTriggers 
    "maskLayoutXL";layout editor XL 
    nil 
    nil 
    'postInstallTriggerSFQLayout))
