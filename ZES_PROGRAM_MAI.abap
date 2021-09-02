*&---------------------------------------------------------------------*
*&  Include           ZES_PROGRAM_MAI
*&---------------------------------------------------------------------*

START-OF-SELECTION.

  CONDENSE p_desc.
  IF p_op_u EQ 'X'.
    PERFORM process_users.
  ELSEIF p_op_t EQ 'X'.
    PERFORM process_tcodes.
  ENDIF.
  PERFORM alv_display.

END-OF-SELECTION.