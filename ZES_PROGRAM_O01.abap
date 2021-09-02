*&---------------------------------------------------------------------*
*&  Include           ZES_PROGRAM_O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.

  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR  'TITLE_0100'.

  IF go_custom_container IS INITIAL.

    REFRESH gtd_fieldcat_o.
    CLEAR: gi_alvposicion.
    PERFORM carga_layout.

    PERFORM add_fieldcat:
      TABLES gtd_fieldcat_o USING 'GTD_DATA_D' 'VALUE' gs_col_title gs_col_title gs_col_title  '30' '' '' '' '' '' '' '' '' '' ''."

    CREATE OBJECT go_custom_container
      EXPORTING
        container_name = gs_container.

    CREATE OBJECT go_grid1
      EXPORTING
        i_parent = go_custom_container.

    CREATE OBJECT go_alv_screen
      EXPORTING
        io_alv_grid = go_grid1.

    CALL METHOD go_grid1->set_table_for_first_display
      EXPORTING
        is_layout       = gwa_layout_o
      CHANGING
        it_fieldcatalog = gtd_fieldcat_o
        it_outtab       = gtd_data_d[].

  ELSE.
    CALL METHOD go_grid1->refresh_table_display.
  ENDIF.

ENDMODULE.                 " STATUS_0100  OUTPUT