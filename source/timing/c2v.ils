;(load "~/git/dat/source/c2v.il")
(defvar LOGIC_EXTRACTION_OPTIONS_FORM)

(defun c2vFront ()
  (let (scv ok)
    (setq scv geGetWindowCellView())
    (createOptionsForm2 scv)
    (setq ok
          hiDisplayForm(LOGIC_EXTRACTION_OPTIONS_FORM))
    (when ok
      (setq paramList (getParamsFromOptionsForm2))
      (c2v scv ?flagArvTime (car paramList)))))

(defun c2v (scv @key (flagArvTime "max"))
  (let (out outFileName in inFileName nextLine
            outCtl ctlFileName numError numLatch)
    ;initialize
    (sprintf outFileName "%s_%d_%s.mv" scv~>cellName scv~>currentBias flagArvTime)
    (setq out (outfile outFileName "w"))
    (fprintf out ".model ")
    (fprintf out "%s_%d\n" scv~>cellName scv~>currentBias)
    (fprintf out ".inputs")
    (foreach
      x (setof y scv~>instances (isIpin y))
      (fprintf out " %s" x~>net~>name))
    (fprintf out "\n.outputs")
    (foreach
      x (setof y scv~>instances (isOpin y))
      (fprintf out " %s" x~>net~>name))
    (fprintf out "\n")

    ;ctl
    (sprintf ctlFileName "%s_%d_%s.ctl" scv~>cellName scv~>currentBias flagArvTime)
    (setq outCtl (outfile ctlFileName "w"))

    ;main
    (assignAllCellInputLogics scv)
    (foreach
      x (setof y scv~>instances (isOpin y))
      (fprintf out ".table %s " x~>inputLogic)
      (fprintf out "-> %s\n" x~>net~>name)
      (fprintf out "- =%s\n" x~>inputLogic)
      )
    (foreach
      x (setof y scv~>instances
               (or
                 (greaterp (length (inputTerms y)) 1)
                 (isSource y)))
      (if (logicCellType x)
        (fprintf out ".subckt ")
        (fprintf out ".subckterror%s " x~>cellName)
        )
      (if (logicCellType x)
        (fprintf out "%s" (logicCellType x))
        (fprintf out "error%s_" x~>cellName)
        )
      ;timingViolation
      (when (member (logicCellType x)
                    '("cb" "cbjtlx"
                      ))
        (let ((slackList nil) delayTable perm)
          (setq delayTable (makeDelayTable scv))
          (if (isCBJTLX x)
            (setq perm (permutation 2 (setof y (inputTerms x)
                                             (or (equal y~>name "a")
                                                 (equal y~>name "b")))))
            (setq perm (permutation 2 (inputTerms x))))
          (foreach 
            its perm
            (printf "%s%L \n" x~>name its~>name)
            (setq slackList
                  (append1 slackList 
                           (calcSlack
                             (car its)
                             (cadr its)
                             "arvTimeMin" 
                             "arvTimeMax" 
                             ))))
          (printf "%L\n" slackList)
          (printf "%L\n" (mapcar (lambda (y) y < 0.0) slackList))
          (when (orList (mapcar (lambda (y) y < 0.0) slackList))
            (fprintf out "_timingViolation")
            )))
      ;begin order
      (unless (member (logicCellType x)
                      '("cb" "spljtlx" "spl3jtlx" "source"
                        "cbjtlx" "jtlsink" "jtlx" "jtlxx"
                        "kand" "knimply"
                        ))
        (foreach z (orderInputs x flagArvTime)
                 (fprintf out "_%s" z~>name))
        );unless
      ;end order
      (fprintf out " ")
      (fprintf out "%s " x~>name)
      (foreach z (inputTerms x)
               (fprintf out "%s=%s " z~>name
                        (if z~>inputLogic
                          z~>inputLogic
                          "error")
                        ))
      (foreach z (outputTerms x)
               (fprintf out "%s=%s_%s_%s "
                        z~>name z~>inst~>name
                        (if (logicCellType z~>inst)
                          (logicCellType z~>inst)
                          (let (str)
                            (sprintf str "error%s" z~>inst~>cellName)))
                        z~>name))
      (fprintf out "\n")
      ;make ctl 
      (unless (isSource x)
        numError = (numStates x)
        numLatch = (ceiling numError/2.0)-1
        (unless (equal numError 0)
          (fprintf outCtl "AG(")
          (for
            i 0 numLatch
            (fprintf outCtl "(!(%s.so%d=%d))"
                     x~>name i (mod (difference numError 1) / (expt 2 i) 2))
            (when i!=numLatch (fprintf outCtl " + "))
            )
          (fprintf outCtl ");#%s\n" x~>cellName)
          ))
      );foreach x
    (fprintf out ".end\n\n")
    (foreach
      path getSkillPath()
      (when (isReadable (setq inFileName (buildString list( path "dat/source/cell.mv" ) "/" )))
        (printf "%s" inFileName)
        (setq in (infile inFileName))
        ))
    (when in
      (while (gets nextLine in)
             (fprintf out "%s" nextLine)
             )
      (close in))
    (close outCtl)
    (close out)
    (deleteInputLogics scv)
    ))

(defun orderInputs (inst flagArvTime)
  (let (result its)
    (setq result nil)
    (if (isCBJTLX inst)
      (setq its (setof x (inputTerms inst) x~>name!="d"))
      (setq its (inputTerms inst)))
    (if (equal flagArvTime "max")
      (foreach
        x its
        (if x~>arvTimeMax
          (setq result (cons (list x~>arvTimeMax x) result))))
      (foreach
        x its
        (if x~>arvTimeMin
          (setq result (cons (list x~>arvTimeMin x) result)))))
    (setq result (sortcar result `lessp))
    (mapcar 'cadr result)
    ))

(defun assignAllCellInputLogics (scv)
  (let (rem cur connectedList str)
    (setq rem nil)
    (foreach
      x (setof y scv~>instances
               (or (greaterp (length (inputTerms y)) 1)
                   (isSource y)))
      (setq rem (append rem (outputTerms x))))
    (setq rem (append rem (setof x scv~>instances (isIpin x))))
    (foreach
      cur rem
      (setq connectedList (inputTermsDependLogic cur))
      (if (isIpin cur)
        (sprintf str "%s" cur~>net~>name)
        (sprintf str "%s_%s_%s"
                 cur~>inst~>name
                 (if (logicCellType cur~>inst)
                   (logicCellType cur~>inst)
                   (let (str)
                     (sprintf str "error%s" cur~>inst~>cellName)))
                 cur~>name))
      (foreach
        x connectedList
        x~>inputLogic = str))))

(defun inputTermsDependLogic (outputTerm)
  (let (its it ret)
    (setq its (inputTermsConnected outputTerm))
    (setq its (append its (pinsConnected outputTerm)))
    (setq ret nil)
    (while (setq it (car its))
           (setq its (cdr its))
           (if (isRoutingCell it~>inst)
             (foreach
               x (outputTerms it~>inst)
               (setq its (append its (pinsConnected x)))
               (foreach
                 y (inputTermsConnected x)
                 (setq its (cons y its))))
             (setq ret (cons it ret))))
    ret))

(defun deleteInputLogics (scv)
  (foreach
    x (setof y scv~>instances (greaterp (length (inputTerms y)) 1))
    (foreach
      z (inputTerms x)
      (dbDeletePropByName z "inputLogic")))
  (foreach
    x (setof y scv~>instances (isOpin y))
    (dbDeletePropByName x "inputLogic"))
  )

(defun logicCellType (inst)
  (cond
    ((isT1 inst) "t1")
    ((isD2ff inst) "d2ff")
    ((isRdff inst) "rdff")
    ((isRtff inst) "rtff")
    ((isDffe inst) "dffe")
    ((isDff inst) "dff")
    ((isNdroc inst) "ndroc")
    ((isNdro inst) "ndro")
    ((isTff inst) "tff")
    ((isJnote inst) "jnote")
    ((isJnot inst) "jnot")
    ((isJande inst) "jande")
    ((isJandf inst) "jandf")
    ((isJand inst) "jand")
    ((isJor inst) "jor")
    ((isJxore inst) "jxore")
    ((isJxor inst) "jxor")
    ((isRjxor inst) "rjxor")
    ((isJnor inst) "jnor")
    ((isJnand inst) "jnand")
    ;no order
    ((isKand inst) "kand")
    ((isKnimply inst) "knimply")
    ((isSource inst) "source")
    ((isSPLJTLX inst) "spljtlx")
    ((isSPL3JTLX inst) "spl3jtlx")
    ((isCB inst) "cb")
    ((isCBJTLX inst) "cbjtlx")
    ((isJTL inst)
     (cond 
       ((and (equal (length (inputTerms inst)) 2)
             (equal (length (outputTerms inst)) 1))
        "jtlsink")
       ((leqp 2 (length (inputTerms inst)))
        "jtlx")
       ;((equal (length (inputTerms inst)) 3)
       ; "jtlxx")
       ))))

;;以下、メニュー表示に関する部分

(defun createOptionsForm2 (scv)
  (let (comps)
    (setq comps (append1 comps (hiCreateRadioField 	?name 'minmaxRadioField
                                                        ?choices (list "min" "max")
                                                        ?prompt "min/max"
                                                        ?value "min")))
    (hiCreateAppForm
      ?name 'LOGIC_EXTRACTION_OPTIONS_FORM
      ?fields comps
      ?help "Choose min or max which you want, that's all.")))

(defun getParamsFromOptionsForm2 ()
  (let (result)
    (setq result nil)
    (if LOGIC_EXTRACTION_OPTIONS_FORM~>minmaxRadioField~>value == "min"
      (setq result (append1 result "min"))
      (setq result (append1 result "max")))
    (warn "[DEBUG] #getParamsFromOptionsForm2 params:%L\n" result)
    result))

(defun numStates (inst)
  (cond
    ;((isB3ff inst) 3)
    ;((isB3ffc inst) 3)
    ;((isBina inst) 3)
    ((isD2ff inst) 3)
    ((isDff inst) 3)
    ((isDffe inst) 3)
    ((isJand inst) 5)
    ((isJande inst) 5)
    ((isJnot inst) 3)
    ((isJnote inst) 3)
    ((isJor inst) 3)
    ((isJxor inst) 5)
    ((isJxore inst) 5)
    ;((isMullerc inst) 4)
    ((isNdro inst) 3)
    ((isNdroc inst) 3)
    ((isRdff inst) 3)
    ((isRjxor inst) 5)
    ((isT1 inst) 3)
    ;((isTbina inst) 3)
    ((isCB inst) 2)
    ((isCBJTLX inst) 2)
    (t 0)
    ))
