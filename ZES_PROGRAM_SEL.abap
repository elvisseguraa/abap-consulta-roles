*&---------------------------------------------------------------------*
*&  Include           ZES_PROGRAM_SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE text-001.
SELECT-OPTIONS: s_roles FOR agr_texts-agr_name .
PARAMETERS: p_desc TYPE agr_define-agr_name.

SELECTION-SCREEN SKIP.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_op_u RADIOBUTTON GROUP rb0 USER-COMMAND r DEFAULT 'X'.
SELECTION-SCREEN COMMENT 2(15) FOR FIELD p_op_u.

PARAMETERS: p_op_t RADIOBUTTON GROUP rb0.
SELECTION-SCREEN COMMENT 19(15) FOR FIELD p_op_t.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN: BEGIN OF BLOCK b02 WITH FRAME TITLE text-t03.
SELECT-OPTIONS: s_users FOR sy-uname    MODIF ID g1.
SELECT-OPTIONS: s_tcodes FOR tstc-tcode MODIF ID g2.
SELECTION-SCREEN: END OF BLOCK b02.

SELECTION-SCREEN END OF BLOCK b01.

AT SELECTION-SCREEN OUTPUT.
  CASE abap_true.
    WHEN p_op_u.
      PERFORM set_visible USING 'G1'.
    WHEN p_op_t.
      PERFORM set_visible USING 'G2'.
    WHEN OTHERS.
  ENDCASE.
*&---------------------------------------------------------------------*
*&      Form  SET_VISIBLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0100   text
*----------------------------------------------------------------------*
FORM set_visible  USING p_value.

  LOOP AT SCREEN.

    IF screen-group1 = 'G1' AND screen-group1 NE p_value.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.

    IF screen-group1 = 'G2' AND screen-group1 NE p_value.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.

    IF screen-group1 = p_value.
      screen-active = 1.
      MODIFY SCREEN.
    ENDIF.

  ENDLOOP.

ENDFORM.                    " SET_VISIBLE