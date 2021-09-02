*&---------------------------------------------------------------------*
*&  Include           ZES_PROGRAM_CLA
*&---------------------------------------------------------------------*

CLASS cl_alv_screen DEFINITION.

  PUBLIC SECTION.

    METHODS:
      constructor
        IMPORTING
          io_alv_grid TYPE REF TO cl_gui_alv_grid OPTIONAL.

ENDCLASS.                    "cl_alv_screen DEFINITION

*----------------------------------------------------------------------*
*       CLASS cl_alv_screen IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS cl_alv_screen IMPLEMENTATION.

  METHOD constructor.

*    IF NOT io_alv_grid IS INITIAL.
*      CREATE OBJECT go_alv_tbmanager
*        EXPORTING
*          io_alv_grid = io_alv_grid.
*    ENDIF.

  ENDMETHOD.                    "constructor

ENDCLASS.                    "cl_alv_screen IMPLEMENTATION