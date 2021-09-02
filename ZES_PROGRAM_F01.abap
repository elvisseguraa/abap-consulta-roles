*&---------------------------------------------------------------------*
*&  Include           ZES_PROGRAM_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  get_single_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PR_TCODES     text
*      -->PT_AGR_TCODE  text
*----------------------------------------------------------------------*
FORM get_single_roles  USING    pr_tcodes    TYPE gty_tr_tcode
                       CHANGING pt_agr_tcode TYPE gty_tt_agr_name.

  DATA: lt_tcodes      TYPE susr_t_tcodes,
        ls_tcodes      TYPE susr_tcodes,
        lwa_agr_tcodes TYPE gty_agr_tcode,
        lwa_agr_tcode  TYPE gty_agr_name.

  DATA: ok TYPE c.

  SELECT agr_name tcode INTO TABLE gtd_agr_tcodes
    FROM agr_tcodes
    WHERE type  EQ 'TR'
      AND tcode IN pr_tcodes.

  IF gtd_agr_tcodes[] IS NOT INITIAL.

    SORT: gtd_agr_tcodes    BY agr_name.

    LOOP AT gtd_agr_tcodes INTO lwa_agr_tcodes.
      lwa_agr_tcode-agr_name = lwa_agr_tcodes-agr_name.
      INSERT lwa_agr_tcode INTO TABLE pt_agr_tcode.
    ENDLOOP.

  ENDIF.

  DELETE ADJACENT DUPLICATES FROM pt_agr_tcode COMPARING agr_name.

ENDFORM.                    " GET_SINGLE_ROLES

*&---------------------------------------------------------------------*
*&      Form  get_derived_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PT_AGR_HIER  text
*----------------------------------------------------------------------*
FORM get_derived_roles CHANGING  pt_agr_hier TYPE gty_tt_agr_name.

  DATA: ltd_temp_agr      TYPE gty_tt_agr_name,
        lwa_temp_agr      TYPE gty_agr_name,
        ltd_temp_agr2     TYPE gty_tt_agr_name,
        lwa_agr_hier      TYPE gty_agr_name.

  SELECT agr_name INTO TABLE ltd_temp_agr
    FROM agr_define FOR ALL ENTRIES IN pt_agr_hier
    WHERE parent_agr EQ pt_agr_hier-agr_name.

  IF NOT ltd_temp_agr[] IS INITIAL.

    DO.

      LOOP AT ltd_temp_agr INTO lwa_temp_agr.
        READ TABLE pt_agr_hier WITH KEY agr_name = lwa_temp_agr-agr_name TRANSPORTING NO FIELDS.
        IF sy-subrc NE 0.
          lwa_agr_hier-agr_name = lwa_temp_agr-agr_name.
          INSERT lwa_agr_hier INTO TABLE pt_agr_hier.
        ELSE.
          lwa_agr_hier-agr_name = lwa_temp_agr-agr_name.
          DELETE ltd_temp_agr WHERE agr_name EQ lwa_agr_hier-agr_name.
        ENDIF.
      ENDLOOP.

      IF ltd_temp_agr[] IS INITIAL.
        EXIT.
      ENDIF.

      REFRESH ltd_temp_agr2.

      SELECT agr_name FROM agr_define INTO TABLE ltd_temp_agr2
        FOR ALL ENTRIES IN ltd_temp_agr
        WHERE parent_agr EQ ltd_temp_agr-agr_name.

      SORT ltd_temp_agr2.
      DELETE ADJACENT DUPLICATES FROM ltd_temp_agr2.

      LOOP AT ltd_temp_agr INTO lwa_temp_agr.
        READ TABLE ltd_temp_agr2 WITH KEY agr_name = lwa_temp_agr-agr_name TRANSPORTING NO FIELDS BINARY SEARCH.
        IF sy-subrc EQ 0.
          DELETE ltd_temp_agr2 INDEX sy-tabix.
        ENDIF.
      ENDLOOP.

      REFRESH ltd_temp_agr.
      ltd_temp_agr[] = ltd_temp_agr2[].

      IF ltd_temp_agr[] IS INITIAL.
        EXIT.
      ENDIF.

      SORT ltd_temp_agr BY agr_name.
      DELETE ADJACENT DUPLICATES FROM ltd_temp_agr.

    ENDDO.

  ENDIF.

  CLEAR   ltd_temp_agr.

ENDFORM.                    " GET_DERIVED_ROLES

*&---------------------------------------------------------------------*
*&      Form  get_compsite_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PR_TCODES     text
*      -->PT_AGR_TCODE  text
*----------------------------------------------------------------------*
FORM get_compsite_roles USING    pr_tcodes    TYPE gty_tr_tcode
                        CHANGING pt_agr_tcode TYPE gty_tt_agr_name.

  DATA: ltd_agr_agrs     TYPE gty_tt_agr_name,
        lwa_agr_agrs     TYPE gty_agr_name,
        ltd_tcodes       TYPE susr_t_tcodes,
        lwa_tcodes       LIKE LINE OF ltd_tcodes,
        ltd_agr_tcode    TYPE gty_tt_agr_name,
        lwa_agr_tcode    TYPE gty_agr_name.

  SELECT DISTINCT agr_name FROM agr_agrs
    INTO TABLE ltd_agr_agrs
         WHERE attributes NE 'X'.

  IF ltd_agr_agrs[] IS NOT INITIAL.

    SELECT DISTINCT agr_name FROM agr_tcodes APPENDING TABLE ltd_agr_tcode
      FOR ALL ENTRIES IN ltd_agr_agrs
      WHERE agr_name EQ ltd_agr_agrs-agr_name
        AND type  EQ 'TR'
        AND tcode IN pr_tcodes.

    LOOP AT ltd_agr_agrs INTO lwa_agr_agrs.

      CLEAR ltd_tcodes[].

      READ TABLE ltd_agr_tcode WITH KEY agr_name = lwa_agr_agrs-agr_name TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.

        CALL FUNCTION 'SUSR_ROLE_READ_TRANSACTIONS'
          EXPORTING
            activity_group = lwa_agr_agrs-agr_name
          TABLES
            t_tcodes       = ltd_tcodes
          EXCEPTIONS
            no_data_found  = 1
            OTHERS         = 2.

        IF sy-subrc = 0.
          LOOP AT ltd_tcodes INTO lwa_tcodes WHERE tcode IN s_tcodes.
            lwa_agr_tcode-agr_name = lwa_agr_agrs-agr_name.
            INSERT lwa_agr_tcode INTO TABLE pt_agr_tcode.
            EXIT.
          ENDLOOP.
        ENDIF.

      ENDIF.

    ENDLOOP.

  ENDIF.

  DELETE ADJACENT DUPLICATES FROM pt_agr_tcode COMPARING agr_name.

ENDFORM.                    " GET_COMPSITE_ROLES
*&---------------------------------------------------------------------*
*&      Form  PROCESS_USERS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM process_users .

  DATA: ls_atext TYPE prgn_agr_txt-atext.

  REFRESH: gtd_agr_users.

  "DATA 1: roles por usuario
  SELECT * INTO TABLE gtd_agr_users
    FROM agr_users
    WHERE uname    IN s_users "
      AND from_dat <= sy-datum
      AND to_dat   >= sy-datum
      AND agr_name IN s_roles "
      AND exclude  EQ space .

  DELETE ADJACENT DUPLICATES FROM gtd_agr_users COMPARING agr_name.

  LOOP AT gtd_agr_users ASSIGNING <fs_agr_users>.
    APPEND INITIAL LINE TO gtd_agr_name ASSIGNING <fs_agr_name>.
    <fs_agr_name>-agr_name = <fs_agr_users>-agr_name.
    <fs_agr_name>-langu    = 'S'.  "sy-langu
  ENDLOOP.

  CALL FUNCTION 'PRGN_READ_AGR_STD_TEXTS'
    CHANGING
      agr_name = gtd_agr_name.

  LOOP AT gtd_agr_users ASSIGNING <fs_agr_users>.

    CLEAR ls_atext.
    READ TABLE gtd_agr_name WITH KEY agr_name = <fs_agr_users>-agr_name ASSIGNING <fs_agr_name>.
    IF sy-subrc EQ 0.
      ls_atext = <fs_agr_name>-atext.
    ENDIF.

    IF p_desc IS NOT INITIAL.
      IF ls_atext CS p_desc.
      ELSE.
        CONTINUE.
      ENDIF.
    ENDIF.

    APPEND INITIAL LINE TO gtd_data ASSIGNING <fs_data>.
    <fs_data>-agr_name = <fs_agr_users>-agr_name.
    <fs_data>-atext    = ls_atext.

  ENDLOOP.

  SORT gtd_data ASCENDING BY agr_name.
  DELETE ADJACENT DUPLICATES FROM gtd_data COMPARING agr_name.

ENDFORM.                    " PROCESS_USERS
*&---------------------------------------------------------------------*
*&      Form  PROCESS_TCODES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM process_tcodes .

  "DATA 2: roles por transaccion

  DATA: ltd_agr_text  TYPE agr_texts OCCURS 0 WITH HEADER LINE,
        ltd_agr       TYPE agr_name  OCCURS 0 WITH HEADER LINE,
        ltd_tcodes    TYPE susr_t_tcodes,
        ltd_agr_tcode TYPE gty_tt_agr_name,
        lwa_agr_tcode TYPE gty_agr_name,
        lwa_tcodes    LIKE LINE OF ltd_tcodes,
        lwa_actvgrps  TYPE usagrlangu,
        lwa_agr_name  TYPE prgn_agr_txt,
        ltd_agr_name  TYPE prgn_t_agr_txt,
        ls_atext      TYPE prgn_agr_txt-atext.

  IF s_tcodes IS NOT INITIAL. "filtra roles

    PERFORM get_single_roles USING    s_tcodes[]
                             CHANGING ltd_agr_tcode[].

    IF ltd_agr_tcode[] IS NOT INITIAL.
      PERFORM get_derived_roles CHANGING ltd_agr_tcode[].
    ENDIF.

    PERFORM get_compsite_roles USING  s_tcodes[]
                               CHANGING ltd_agr_tcode[].

  ELSE. "se genera data para el boton

    SELECT agr_name  INTO CORRESPONDING FIELDS OF TABLE gtd_actvgrps
      FROM agr_define.
    IF sy-subrc EQ 0.
      IF gtd_actvgrps[] IS NOT INITIAL.
        LOOP AT gtd_actvgrps INTO lwa_actvgrps.

          MOVE-CORRESPONDING lwa_actvgrps TO lwa_agr_name.
          lwa_agr_name-langu = 'S'.
          APPEND lwa_agr_name TO ltd_agr_name.

          CALL FUNCTION 'SUSR_ROLE_READ_TRANSACTIONS'
            EXPORTING
              activity_group = lwa_actvgrps-agr_name
            TABLES
              t_tcodes       = ltd_tcodes
            EXCEPTIONS
              no_data_found  = 1
              OTHERS         = 2.

          IF sy-subrc = 0.
            IF ltd_tcodes IS NOT INITIAL.
              lwa_agr_tcode-agr_name = lwa_actvgrps-agr_name.
              INSERT lwa_agr_tcode INTO TABLE ltd_agr_tcode.
            ENDIF.
          ENDIF.

        ENDLOOP.
      ENDIF.
    ENDIF.

  ENDIF.

  LOOP AT ltd_agr_tcode INTO lwa_agr_tcode.
    MOVE-CORRESPONDING lwa_agr_tcode TO lwa_agr_name.
    lwa_agr_name-langu = 'S'.
    APPEND lwa_agr_name TO ltd_agr_name.
  ENDLOOP.

  IF s_roles[] IS NOT INITIAL.
    DELETE ltd_agr_name WHERE agr_name NOT IN s_roles.
  ENDIF.

  IF ltd_agr_name IS NOT INITIAL.

    CALL FUNCTION 'PRGN_READ_AGR_STD_TEXTS'
      CHANGING
        agr_name = ltd_agr_name.

    LOOP AT ltd_agr_name INTO lwa_agr_name.

      ls_atext = lwa_agr_name-atext.
      IF p_desc IS NOT INITIAL.
        IF ls_atext CS p_desc.
        ELSE.
          CONTINUE.
        ENDIF.
      ENDIF.

      APPEND INITIAL LINE TO gtd_data ASSIGNING <fs_data>.
      <fs_data>-agr_name = lwa_agr_name-agr_name.
      <fs_data>-atext    = lwa_agr_name-atext.

    ENDLOOP.

  ENDIF.

  SORT gtd_data ASCENDING BY agr_name.
  DELETE ADJACENT DUPLICATES FROM gtd_data COMPARING agr_name.

ENDFORM.                    " PROCESS_TCODES
*&---------------------------------------------------------------------*
*&      Form  CARGA_LAYOUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM carga_layout .
*  MOVE: 'X' TO gwa_layout_o-zebra.
ENDFORM.                    " CARGA_LAYOUT

*&---------------------------------------------------------------------*
*&      Form  ADD_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GTD_FIELDCAT  text
*      -->P_0025   text
*      -->P_0026   text
*      -->P_0027   text
*      -->P_0028   text
*      -->P_0029   text
*      -->P_0030   text
*      -->P_0031   text
*      -->P_0032   text
*      -->P_0033   text
*      -->P_0034   text
*      -->P_0035   text
*      -->P_0036   text
*      -->P_0037   text
*----------------------------------------------------------------------*
FORM add_fieldcat TABLES gdt_fieldcat TYPE lvc_t_fcat
                  USING p_tabname
                        p_fieldname
                        p_scrtext_l
                        p_scrtext_m
                        p_scrtext_s
                        p_outputlen
                        p_reptext
                        p_alvposicion
                        p_icon
                        p_edit
                        p_ref_table
                        p_ref_field
                        p_f4
                        p_no_zero
                        p_key
                        p_do_sum.
*
  FIELD-SYMBOLS <lwa_fieldcat> LIKE LINE OF gdt_fieldcat.
*
  ADD 1 TO gi_alvposicion.
  APPEND INITIAL LINE TO gdt_fieldcat ASSIGNING <lwa_fieldcat>.
  MOVE:
   p_tabname      TO <lwa_fieldcat>-tabname,
   p_fieldname    TO <lwa_fieldcat>-fieldname,
   p_scrtext_l    TO <lwa_fieldcat>-scrtext_l,
   p_scrtext_m    TO <lwa_fieldcat>-scrtext_m,
   p_scrtext_s    TO <lwa_fieldcat>-scrtext_s,
   p_outputlen    TO <lwa_fieldcat>-outputlen,
   p_reptext      TO <lwa_fieldcat>-reptext,
   p_alvposicion  TO <lwa_fieldcat>-col_pos,
   p_icon         TO <lwa_fieldcat>-icon,
   p_edit         TO <lwa_fieldcat>-edit,
   p_ref_table    TO <lwa_fieldcat>-ref_table,
   p_ref_field    TO <lwa_fieldcat>-ref_field,
   p_f4           TO <lwa_fieldcat>-f4availabl,
   p_no_zero      TO <lwa_fieldcat>-no_zero,
   p_key          TO <lwa_fieldcat>-key,
   p_do_sum       TO <lwa_fieldcat>-do_sum.

ENDFORM.                    "add_fieldcat

*&---------------------------------------------------------------------*
*&      Form  ALV_DISPLAY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_display .

  REFRESH gtd_fieldcat.

  PERFORM build_layout_grid.
  PERFORM add_fieldcat_grid:
    TABLES gtd_fieldcat USING 'GTD_DATA' 'AGR_NAME' 'AGR_USERS' 'AGR_NAME' '' '' '' '',
    TABLES gtd_fieldcat USING 'GTD_DATA' 'ATEXT'    'PRGN_AGR_TXT' 'ATEXT' '' '' '' ''.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      it_fieldcat              = gtd_fieldcat[]
      is_layout                = gwa_layout
      i_grid_title             = 'Reporte de Roles'
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'SET_PF_STATUS'
      i_callback_user_command  = 'USER_COMMAND'
    TABLES
      t_outtab                 = gtd_data[]
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

ENDFORM.                    " ALV_DISPLAY
*&---------------------------------------------------------------------*
*&      Form  BUILD_LAYOUT_GRID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_layout_grid .

  CLEAR: gwa_layout.
  gwa_layout-zebra         = 'X'.
  gwa_layout-box_fieldname = 'ZFLAG'.

ENDFORM.                    " BUILD_LAYOUT_GRID
*&---------------------------------------------------------------------*
*&      Form  PROCESS_USERS_DET
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM process_users_det .

  REFRESH: gtd_agr_users, gtd_data_d.

  SELECT * INTO TABLE gtd_agr_users
  FROM agr_users
  WHERE from_dat <= sy-datum
    AND to_dat   >= sy-datum
    AND agr_name IN gr_agr_name "s_roles "
    AND exclude  EQ space .

  LOOP AT gtd_agr_users ASSIGNING <fs_agr_users>.
    APPEND INITIAL LINE TO gtd_data_d ASSIGNING <fs_data_d>.
    <fs_data_d>-value = <fs_agr_users>-uname.
    CONDENSE <fs_data_d>-value.
  ENDLOOP.

  SORT gtd_data_d ASCENDING BY value.
  DELETE ADJACENT DUPLICATES FROM gtd_data_d COMPARING value.


ENDFORM.                    " PROCESS_USERS_DET
*&---------------------------------------------------------------------*
*&      Form  PROCESS_TCODES_DET
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM process_tcodes_det .

  DATA: ltd_agr_agrs     TYPE gty_tt_agr_name,
        ltd_agr_tcode    TYPE gty_tt_agr_name,
        lwa_agr_tcode    TYPE gty_agr_name.

  DATA: ltd_t_tcodes TYPE susr_t_tcodes,
        lwa_t_tcodes TYPE susr_tcodes.

  REFRESH: gtd_data_d, gtd_agr_tcodes, ltd_t_tcodes.

  SELECT agr_name tcode INTO TABLE gtd_agr_tcodes
    FROM agr_tcodes
    WHERE type  EQ 'TR'
      AND agr_name IN gr_agr_name.

  LOOP AT gtd_agr_tcodes INTO gwa_agr_tcodes.
    APPEND INITIAL LINE TO gtd_data_d ASSIGNING <fs_data_d>.
    <fs_data_d>-value = gwa_agr_tcodes-tcode.
  ENDLOOP.

  SELECT DISTINCT agr_name INTO TABLE ltd_agr_agrs
    FROM agr_agrs
    WHERE attributes NE 'X'.

  IF ltd_agr_agrs[] IS NOT INITIAL.
    SELECT DISTINCT agr_name FROM agr_tcodes APPENDING TABLE ltd_agr_tcode
      FOR ALL ENTRIES IN ltd_agr_agrs
      WHERE agr_name EQ ltd_agr_agrs-agr_name
        AND type  EQ 'TR'.
  ENDIF.


  LOOP AT ltd_agr_tcode INTO lwa_agr_tcode WHERE agr_name NOT IN gr_agr_name.

    CALL FUNCTION 'SUSR_ROLE_READ_TRANSACTIONS'
      EXPORTING
        activity_group = lwa_agr_tcode-agr_name
      TABLES
        t_tcodes       = ltd_t_tcodes
      EXCEPTIONS
        no_data_found  = 1
        OTHERS         = 2.

    IF sy-subrc = 0.
      LOOP AT ltd_t_tcodes INTO lwa_t_tcodes.
        APPEND INITIAL LINE TO gtd_data_d ASSIGNING <fs_data_d>.
        <fs_data_d>-value = lwa_t_tcodes-tcode.
        CONDENSE <fs_data_d>-value.
      ENDLOOP.
    ENDIF.

  ENDLOOP.

  SORT gtd_data_d ASCENDING BY value.
  DELETE ADJACENT DUPLICATES FROM gtd_data_d COMPARING value.

ENDFORM.                    " PROCESS_TCODES_DET
*&---------------------------------------------------------------------*
*&      Form  PROCESS_DET
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM process_det .

  REFRESH gr_agr_name.

  LOOP AT gtd_data ASSIGNING <fs_data>.
    IF <fs_data>-zflag EQ 'X'.
      CLEAR: gw_agr_name .
      gw_agr_name-sign   = 'I'.
      gw_agr_name-option = 'EQ'.
      gw_agr_name-low    = <fs_data>-agr_name.
      gw_agr_name-high   = ''.
      APPEND gw_agr_name TO gr_agr_name.
    ENDIF.
  ENDLOOP.

  IF gr_agr_name IS INITIAL.
    MESSAGE 'Seleccionar fila(s).' TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  IF p_op_u EQ 'X'.
    gs_col_title = 'Usuario'.
    PERFORM process_users_det.
  ELSEIF p_op_t EQ 'X'.
    gs_col_title = 'Transacción'.
    PERFORM process_tcodes_det.
  ENDIF.

  IF gtd_data_d[] IS NOT INITIAL.
    CALL SCREEN 0100.
  ENDIF.

ENDFORM.                    " PROCESS_DET


*&---------------------------------------------------------------------*
*&      Form  add_fieldcat
*&---------------------------------------------------------------------*
FORM add_fieldcat_grid TABLES gtd_fieldcat STRUCTURE gwa_fieldcat
                       USING  p_tabname
                              p_fieldname
                              p_ref_tabname
                              p_ref_fieldname
                              p_seltext_l
                              p_seltext_m
                              p_seltext_s
                              p_outputlen.

  FIELD-SYMBOLS <lwa_fieldcat> LIKE LINE OF gtd_fieldcat.

  APPEND INITIAL LINE TO gtd_fieldcat ASSIGNING <lwa_fieldcat>.
  <lwa_fieldcat>-tabname       = p_tabname.
  <lwa_fieldcat>-fieldname     = p_fieldname.
  <lwa_fieldcat>-ref_tabname   = p_ref_tabname.
  <lwa_fieldcat>-ref_fieldname = p_ref_fieldname.
  <lwa_fieldcat>-seltext_l     = p_seltext_l.
  <lwa_fieldcat>-seltext_m     = p_seltext_m.
  <lwa_fieldcat>-seltext_s     = p_seltext_s.
  <lwa_fieldcat>-outputlen     = p_outputlen.

ENDFORM.                    " ADD_FIELDCAT

*&---------------------------------------------------------------------*
*&      Form  set_pf_status
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->RT_EXTAB   text
*----------------------------------------------------------------------*
FORM set_pf_status USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'ZSTANDARD'.
ENDFORM.                    "set_pf_status

*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PV_UCOMM     text
*      -->PS_SELFIELD  text
*      -->LD           text
*----------------------------------------------------------------------*
FORM user_command USING pv_ucomm LIKE sy-ucomm
                        ps_selfield TYPE slis_selfield.

  CASE pv_ucomm.
    WHEN '&DETAIL'.
      PERFORM process_det.
    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    "user_command