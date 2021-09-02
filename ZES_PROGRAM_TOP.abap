*&---------------------------------------------------------------------*
*&  Include           ZES_PROGRAM_TOP
*&---------------------------------------------------------------------*

TABLES: agr_texts, agr_define, tstc.

TYPES:
   BEGIN OF gty_agr_name,
     agr_name TYPE agr_name,
     tcode    TYPE agr_tcodes-tcode,
   END OF gty_agr_name,
   gty_tt_agr_name TYPE STANDARD TABLE OF gty_agr_name.

TYPES: gty_tr_tcode TYPE RANGE OF tstc-tcode.

DATA: BEGIN OF gtd_actvgrps OCCURS 30.
        INCLUDE STRUCTURE  usagrlangu.
DATA: END OF gtd_actvgrps.

TYPES:
  BEGIN OF gty_report,
     agr_name TYPE agr_users-agr_name,
     atext    TYPE prgn_agr_txt-atext,
     zflag    TYPE c,
   END OF gty_report,

 BEGIN OF gty_report_d,
    value(30) TYPE c,
  END OF gty_report_d.

TYPES:
  BEGIN OF gty_agr_tcode,
    agr_name TYPE agr_name,
    tcode    TYPE tcode,
  END OF gty_agr_tcode,

tt_agr_tcode TYPE STANDARD TABLE OF gty_agr_tcode.

DATA: gtd_data       TYPE STANDARD TABLE OF gty_report,
      gtd_data_d     TYPE STANDARD TABLE OF gty_report_d,
      gtd_agr_users  TYPE STANDARD TABLE OF agr_users,
      gtd_agr_tcode  TYPE STANDARD TABLE OF gty_agr_tcode,
      gtd_agr_name   TYPE prgn_t_agr_txt,
      gtd_agr_tcodes TYPE tt_agr_tcode,
      gwa_agr_tcodes LIKE LINE OF gtd_agr_tcodes.

DATA: gtd_fieldcat     TYPE slis_t_fieldcat_alv,
      gwa_fieldcat     TYPE slis_fieldcat_alv,
      gwa_layout       TYPE slis_layout_alv,
      gi_alvposicion   TYPE i,
      gs_col_title(30) TYPE c.

CLASS cl_alv_screen DEFINITION DEFERRED.

DATA: gs_container        TYPE scrfname VALUE 'G_CONTAINER_0100',
      go_grid1            TYPE REF TO cl_gui_alv_grid,
      go_alv_screen       TYPE REF TO cl_alv_screen,
      go_custom_container TYPE REF TO cl_gui_custom_container,
      gtd_fieldcat_o      TYPE lvc_t_fcat,
      gwa_layout_o        TYPE lvc_s_layo.

DATA: gr_agr_name TYPE RANGE OF agr_users-agr_name,
      gw_agr_name LIKE LINE OF gr_agr_name.

DATA: it_agr_tcode   TYPE STANDARD TABLE OF gty_agr_name,
      wa_agr_tcode   TYPE gty_agr_name.

FIELD-SYMBOLS: <fs_data>      TYPE gty_report,
               <fs_data_d>    TYPE gty_report_d,
               <fs_agr_users> TYPE agr_users,
               <fs_agr_name>  LIKE LINE OF gtd_agr_name.