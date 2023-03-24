*&---------------------------------------------------------------------*
*& Include          ZRMM_TRANSF_PO_YUB2_CLS
*&---------------------------------------------------------------------*
CLASS lc_po_yub2 DEFINITION.

  PUBLIC SECTION.

*--------------------------------------------------------------------*
* TYPES
*--------------------------------------------------------------------*
    TYPES: tr_file TYPE RANGE OF ztbmm00107-zarquivo,
           tr_date TYPE RANGE OF ztbmm00107-zdate,
           tr_stat TYPE RANGE OF ztbmm00107-zstatus,
           tr_time TYPE RANGE OF ztbmm00107-ztime, "YLW - EA - 21/09/2022

           BEGIN OF ty_data,
             a TYPE string,
             b TYPE string,
             c TYPE string,
             d TYPE string,
             e TYPE string,
***YLW - EA - 21/09/2022 - Início
             f TYPE string,
             g TYPE string,
***YLW - EA - 21/09/2022 - Fim
           END OF ty_data,
           ty_t_data TYPE TABLE OF ty_data.

*           BEGIN OF ty_out,
*             id_icon     TYPE icon_d.
*             INCLUDE STRUCTURE ztbmm00107.
*    TYPES: id_icon_msg TYPE icon_d, END OF ty_out.

*--------------------------------------------------------------------*
* INTERNAL TABLE
*--------------------------------------------------------------------*
    DATA:
*          gt_out         TYPE TABLE OF ty_out,
      gt_param_fisia TYPE TABLE OF ztbc_param_fisia.
*      gt_log_msg     TYPE TABLE OF ztbmm00108.

*--------------------------------------------------------------------*
* OBJECT
*--------------------------------------------------------------------*
    DATA: go_grid      TYPE REF TO cl_gui_alv_grid,
          go_splitter  TYPE REF TO cl_gui_splitter_container,
          go_container TYPE REF TO cl_gui_container.

*--------------------------------------------------------------------
* CONSTANTS
*--------------------------------------------------------------------
    CONSTANTS: gc_exec_po  TYPE string VALUE 'Executar PO'.

*--------------------------------------------------------------------*
* METHODS
*--------------------------------------------------------------------*
    METHODS: constructor IMPORTING ir_file   TYPE tr_file
                                   ir_date   TYPE tr_date
                                   ir_time   TYPE tr_time "EA
                                   ir_stat   TYPE tr_stat
                                   iv_upload TYPE c
                                   iv_file   TYPE string,
      main,
      call_alv,
      handle_toolbar
        FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object,
      handle_user_command
        FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,
      handle_hotspot
        FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING
          e_row_id
          es_row_no .

  PRIVATE SECTION.

*--------------------------------------------------------------------*
* VARIABLE
*--------------------------------------------------------------------*
    DATA: gr_file   TYPE tr_file,
          gr_date   TYPE tr_date,
          gr_stat   TYPE tr_stat,
          gr_time   TYPE tr_time, "YLW - EA - 21/09/2022
          gv_upload TYPE c.
*          gv_file   TYPE string.

*--------------------------------------------------------------------*
* INTERNAL TABLE
*--------------------------------------------------------------------*
*    DATA: gt_ekko_ref TYPE TABLE OF ekko,
*          gt_ekpo_ref TYPE TABLE OF ekpo.

*--------------------------------------------------------------------*
* METHODS
*--------------------------------------------------------------------*
    METHODS: select_constants,
      select_info,
      upload_file,
      screen_2000,
      create_fieldcatalog IMPORTING it_table    TYPE ANY TABLE
                          CHANGING  ct_fieldcat TYPE lvc_t_fcat,
      criar_po,
      cria_po_yub2,
      change_po IMPORTING iv_ebeln_yub2 TYPE ebeln
                          is_out        TYPE ty_out.

ENDCLASS.

CLASS lc_po_yub2 IMPLEMENTATION.

  METHOD constructor.

    gr_file   = ir_file.
    gr_date   = ir_date.
    gr_time   = ir_time. "YLW - EA - 21/09/2022
    gr_stat   = ir_stat.
    gv_upload = iv_upload.
    gv_file   = iv_file.

  ENDMETHOD.

  METHOD main.

    FREE gt_log_msg.

    select_constants( ).

    CASE gv_upload.

      WHEN abap_true.

*Realiza leituro do arquivo
        upload_file( ).

      WHEN abap_false.

*Seleciona dados
        select_info( ).

***YLW - EA - 21/09/2022 - Início
        IF p_backg EQ abap_true.

          cria_po_yub2( ).

        ENDIF.
***YLW - EA - 21/09/2022 - Fim

    ENDCASE.

    IF s_time[] IS INITIAL. "Quando JOB, estará preenchido

*Exibe Relatório
      screen_2000( ).

    ELSE.

      PERFORM zf_log_background.

    ENDIF.

  ENDMETHOD.

  METHOD select_constants.

    FREE gt_param_fisia.

    SELECT *
           FROM ztbc_param_fisia
          WHERE process_id EQ 'ZMM_YUB2'
           INTO TABLE @gt_param_fisia.

  ENDMETHOD.

  METHOD upload_file.

    DATA: lt_data TYPE w3mimetabtype,
          ls_out  TYPE ty_out.

    FIELD-SYMBOLS: <lfs_data>  TYPE ty_t_data.

    FREE: gt_ekko_ref,
          gt_ekpo_ref.

    CALL METHOD cl_gui_frontend_services=>gui_upload
      EXPORTING
        filename                = gv_file
        filetype                = 'BIN'
      IMPORTING
        filelength              = DATA(lv_length)
      CHANGING
        data_tab                = lt_data
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        not_supported_by_gui    = 17
        error_no_gui            = 18
        OTHERS                  = 19.

    TRY.

        DATA(l_r_xls) = NEW cl_fdt_xl_spreadsheet(
          document_name = gv_file
          xdocument = cl_fxs_converter=>w3mimetab_to_xstring( iv_w3mimetab = lt_data iv_length = lv_length )
        ).

        l_r_xls->if_fdt_doc_spreadsheet~get_worksheet_names( IMPORTING worksheet_names = DATA(lt_worksheets) ).

        LOOP AT lt_worksheets INTO DATA(lv_worksheets).

          DATA(lo_data_ref) = l_r_xls->if_fdt_doc_spreadsheet~get_itab_from_worksheet( lv_worksheets ).

          ASSIGN lo_data_ref->* TO <lfs_data>.

          LOOP AT <lfs_data> INTO DATA(ls_data).

            CHECK sy-tabix GT 1.

            FREE ls_out.

            ls_out  = VALUE #( id_icon      = icon_green_light
                               zarquivo     = gv_file
                               zdate        = sy-datum
                               ztime        = sy-uzeit
                               matnr        = ls_data-a
                               menge        = ls_data-b
                               werks        = ls_data-c
                               lgort        = ls_data-d
                               ebeln_ref    = ls_data-e
***YLW - EA - 21/09/2022 - Início
                               reslo        = ls_data-f
                               agrup        = ls_data-g ).
***YLW - EA - 21/09/2022 - Fim

            ls_out-id_icon_msg = icon_protocol.

            INSERT ls_out INTO TABLE gt_out.

          ENDLOOP.
        ENDLOOP.

      CATCH cx_fdt_excel_core.
    ENDTRY.

    SORT gt_out BY agrup werks ebeln_ref menge. "YLW - EA - 21/09/2022

    IF line_exists( gt_out[ 1 ] ).

      PERFORM zf_dados_po_ref.

*      SELECT *
*             FROM ekko
*             FOR ALL ENTRIES IN @gt_out
*            WHERE ebeln EQ @gt_out-ebeln_ref
*             INTO TABLE @gt_ekko_ref.
*
*      SELECT *
*             FROM ekpo
*             FOR ALL ENTRIES IN @gt_out
*            WHERE ebeln EQ @gt_out-ebeln_ref
*              AND matnr EQ @gt_out-matnr
*             INTO TABLE @gt_ekpo_ref.
*
      LOOP AT gt_out ASSIGNING FIELD-SYMBOL(<fs_out>).

        TRY.
            <fs_out>-ebelp_ref = gt_ekpo_ref[ ebeln = <fs_out>-ebeln_ref
                                              matnr = <fs_out>-matnr ]-ebelp.
          CATCH cx_root.
        ENDTRY.

      ENDLOOP.

    ENDIF.

  ENDMETHOD.

  METHOD select_info.

    FREE: gt_out,
          gt_log_msg.

*Seleciona tabela LOG de execução
    SELECT *
           FROM ztbmm00107
          WHERE zarquivo IN @gr_file
            AND zdate    IN @gr_date
            AND ztime    IN @gr_time "YLW - EA - 21/09/2022
            AND zstatus  IN @gr_stat
           INTO CORRESPONDING FIELDS OF TABLE @gt_out.

    IF p_backg IS INITIAL. "YLW - EA - 21/09/2022

      IF NOT gt_out IS INITIAL.

        SELECT *
               FROM ztbmm00108
               FOR ALL ENTRIES IN @gt_out
              WHERE zarquivo EQ @gt_out-zarquivo AND
                    zdate    EQ @gt_out-zdate    AND
                    ztime    EQ @gt_out-ztime    AND
                    matnr    EQ @gt_out-matnr
               INTO CORRESPONDING FIELDS OF TABLE @gt_log_msg.

      ENDIF.

      LOOP AT gt_out ASSIGNING FIELD-SYMBOL(<fs_out>).

        CASE <fs_out>-zstatus.
          WHEN abap_true.
            <fs_out>-id_icon = icon_complete.
          WHEN OTHERS.
            <fs_out>-id_icon = icon_yellow_light.
        ENDCASE.

        <fs_out>-id_icon_msg = icon_protocol.

      ENDLOOP.
    ENDIF. "YLW - EA - 21/09/2022

  ENDMETHOD.

  METHOD screen_2000.

    CALL SCREEN 2000.

  ENDMETHOD.

  METHOD call_alv.

    DATA: ls_variant  TYPE disvariant,
          ls_layout   TYPE lvc_s_layo,
          lt_fieldcat TYPE lvc_t_fcat.

    IF go_grid IS INITIAL.

      CREATE OBJECT go_splitter
        EXPORTING
          parent  = cl_gui_container=>default_screen
          rows    = 1
          columns = 1.

      IF sy-subrc = 0.

        CALL METHOD go_splitter->get_container
          EXPORTING
            row       = 1
            column    = 1
          RECEIVING
            container = go_container.

      ENDIF.

      CREATE OBJECT go_grid
        EXPORTING
          i_parent = go_container.

      ls_layout-zebra      = abap_true.
      ls_layout-no_rowins  = abap_true.
      ls_layout-no_rowmark = abap_true. "YLW - EA - 21/09/2022
      ls_layout-sel_mode   = 'A'.

      ls_variant-report = sy-repid.

      create_fieldcatalog( EXPORTING it_table    = gt_out
                           CHANGING  ct_fieldcat = lt_fieldcat ).

      SET HANDLER handle_toolbar      FOR go_grid.
      SET HANDLER handle_user_command FOR go_grid.
      SET HANDLER handle_hotspot      FOR go_grid.

      CALL METHOD go_grid->set_table_for_first_display
        EXPORTING
          is_variant      = ls_variant
          i_save          = 'A'
          is_layout       = ls_layout
        CHANGING
          it_fieldcatalog = lt_fieldcat
          it_outtab       = gt_out.

      CALL METHOD go_grid->set_toolbar_interactive.

    ENDIF.

  ENDMETHOD.

  METHOD create_fieldcatalog.

    DATA:
      lr_tabdescr TYPE REF TO cl_abap_structdescr
    , lr_data     TYPE REF TO data
    , lt_dfies    TYPE ddfields
    , ls_dfies    TYPE dfies
    , ls_fieldcat TYPE lvc_s_fcat
    , lv_cont     TYPE numc2.
    CLEAR ct_fieldcat.
    CREATE DATA lr_data LIKE LINE OF it_table.
    lr_tabdescr ?= cl_abap_structdescr=>describe_by_data_ref( lr_data ).
    lt_dfies = cl_salv_data_descr=>read_structdescr( lr_tabdescr ).
    LOOP AT lt_dfies
    INTO    ls_dfies.
      CLEAR ls_fieldcat.
      MOVE-CORRESPONDING ls_dfies TO ls_fieldcat.

      CASE ls_fieldcat-fieldname.
        WHEN 'MANDT' OR 'ZMG' OR 'ZSEQ'.

          ls_fieldcat-no_out = abap_true.

        WHEN 'ZARQUIVO'.

          ls_fieldcat-scrtext_l = TEXT-t04.
          ls_fieldcat-scrtext_m = TEXT-t04.
          ls_fieldcat-scrtext_s = TEXT-t04.

        WHEN 'ZDATE'.

          ls_fieldcat-scrtext_l = TEXT-t05.
          ls_fieldcat-scrtext_m = TEXT-t05.
          ls_fieldcat-scrtext_s = TEXT-t05.

        WHEN 'ZTIME'.

          ls_fieldcat-scrtext_l = TEXT-t06.
          ls_fieldcat-scrtext_m = TEXT-t06.
          ls_fieldcat-scrtext_s = TEXT-t06.

        WHEN 'EBELN_REF'.

          ls_fieldcat-scrtext_l = TEXT-t07.
          ls_fieldcat-scrtext_m = TEXT-t07.
          ls_fieldcat-scrtext_s = TEXT-t07.

        WHEN 'EBELP_REF'.

          ls_fieldcat-scrtext_l = TEXT-t08.
          ls_fieldcat-scrtext_m = TEXT-t08.
          ls_fieldcat-scrtext_s = TEXT-t08.

        WHEN 'EBELN_YUB2'.

          ls_fieldcat-scrtext_l = TEXT-t09.
          ls_fieldcat-scrtext_m = TEXT-t09.
          ls_fieldcat-scrtext_s = TEXT-t09.

        WHEN 'EBELP_YUB2'.

          ls_fieldcat-scrtext_l = TEXT-t10.
          ls_fieldcat-scrtext_m = TEXT-t10.
          ls_fieldcat-scrtext_s = TEXT-t10.

        WHEN 'ZSTATUS'.

          ls_fieldcat-scrtext_l = TEXT-t11.
          ls_fieldcat-scrtext_m = TEXT-t11.
          ls_fieldcat-scrtext_s = TEXT-t11.

        WHEN 'ID_ICON_MSG'.

          ls_fieldcat-scrtext_l = TEXT-t12.
          ls_fieldcat-scrtext_m = TEXT-t12.
          ls_fieldcat-scrtext_s = TEXT-t12.
          ls_fieldcat-just      = 'C'.
          ls_fieldcat-hotspot   = abap_true.

      ENDCASE.

      APPEND ls_fieldcat TO ct_fieldcat.

    ENDLOOP.

  ENDMETHOD.

  METHOD handle_toolbar.

    DATA: ls_toolbar TYPE stb_button.

    CASE gv_upload.

      WHEN abap_true.

        MOVE: gc_exec_po              TO ls_toolbar-function,
              icon_execute_object     TO ls_toolbar-icon,
              'Executar PO'(001)      TO ls_toolbar-quickinfo,
              gc_exec_po              TO ls_toolbar-text,
              ' '                     TO ls_toolbar-disabled,
              0                       TO ls_toolbar-butn_type.
        APPEND ls_toolbar TO e_object->mt_toolbar.

    ENDCASE.

  ENDMETHOD.

  METHOD handle_user_command.

    CASE e_ucomm.
      WHEN gc_exec_po.

*Cria Pedido de compra DISPO
***YLW - EA - 21/09/2022 - Início
*        criar_po( ).
        cria_po_yub2( ).
***YLW - EA - 21/09/2022 - Fim

        go_grid->refresh_table_display( ).

    ENDCASE.

  ENDMETHOD.

  METHOD handle_hotspot.

    DATA:
      lt_bapiret2 TYPE bapirettab,
      lt_log_msg  TYPE TABLE OF ztbmm00108,
      ls_bapiret2 TYPE bapiret2,
      lv_lines    TYPE sy-tfill.

    READ TABLE gt_out INTO DATA(ls_out) INDEX es_row_no-row_id.
    CHECK sy-subrc EQ 0.

    lt_log_msg = VALUE #( FOR ls_log_msg_aux IN gt_log_msg WHERE ( zarquivo   EQ ls_out-zarquivo   AND
                                                                   zdate      EQ ls_out-zdate      AND
                                                                   ztime      EQ ls_out-ztime      AND
                                                                   matnr      EQ ls_out-matnr      AND
                                                               ebeln_ref      EQ ls_out-ebeln_ref  AND
                                                               ebelp_ref      EQ ls_out-ebelp_ref  AND
                                                                   werks      EQ ls_out-werks      AND
                                                                   agrup      EQ ls_out-agrup )
                           ( ls_log_msg_aux ) ).

    LOOP AT lt_log_msg INTO DATA(ls_log_msg).

      APPEND INITIAL LINE TO lt_bapiret2 ASSIGNING FIELD-SYMBOL(<fs_bapiret2>).
      MOVE-CORRESPONDING ls_log_msg TO <fs_bapiret2>.
      <fs_bapiret2>-number = ls_log_msg-znumber.

    ENDLOOP.

    DESCRIBE TABLE lt_bapiret2 LINES lv_lines.

    IF lv_lines EQ 1.

      READ TABLE lt_bapiret2 INTO ls_bapiret2 INDEX 1.

      IF ls_bapiret2-type EQ 'S'.

        CLEAR ls_bapiret2.

        ls_bapiret2-type       = 'S'.
        ls_bapiret2-id         = 'MM'.
        ls_bapiret2-number     = '899'.
        ls_bapiret2-message    = 'Sucesso ao processar o registro'.
        ls_bapiret2-message_v1 = ls_bapiret2-message.

      ELSE.

        CLEAR ls_bapiret2.

        ls_bapiret2-type       = 'E'.
        ls_bapiret2-id         = 'MM'.
        ls_bapiret2-number     = '899'.
        ls_bapiret2-message    = 'Erro ao processar o registro'.
        ls_bapiret2-message_v1 = ls_bapiret2-message.

      ENDIF.

      INSERT ls_bapiret2 INTO lt_bapiret2 INDEX 1.

    ENDIF.

    CALL METHOD cl_tex_message_handler=>display_bapiret2(
      EXPORTING
        it_bapiret2 = lt_bapiret2 ).

  ENDMETHOD.

*  METHOD criar_po.
*
*    DATA: lt_poitem    TYPE TABLE OF bapimepoitem,
*          lt_poitemx   TYPE TABLE OF bapimepoitemx,
*          lt_return    TYPE TABLE OF bapiret2,
*          ls_poheader  TYPE bapimepoheader,
*          ls_poheaderx TYPE bapimepoheaderx,
*          ls_t058      TYPE ztbmm00107,
*          ls_t059      TYPE ztbmm00108,
*          lv_item      TYPE ebelp,
*          lv_po_number TYPE ebeln.
*
*    go_grid->get_selected_rows( IMPORTING et_row_no = DATA(lt_row_no) ).
*
*    LOOP AT lt_row_no INTO DATA(ls_row_no).
*
*      READ TABLE gt_out ASSIGNING FIELD-SYMBOL(<fs_out>) INDEX ls_row_no-row_id.
*      CHECK sy-subrc EQ 0 AND <fs_out>-id_icon NE icon_complete.
*
*      TRY.
*
*          DATA(ls_ekko_ref) = gt_ekko_ref[ ebeln = <fs_out>-ebeln_ref ].
*
*          TRY.
*
*              DATA(ls_ekpo_ref) = gt_ekpo_ref[ ebeln = <fs_out>-ebeln_ref
*                                               matnr = <fs_out>-matnr ].
*
*              IF <fs_out>-menge GE ls_ekpo_ref-menge.
*
*                <fs_out>-id_icon = icon_red_light.
*                <fs_out>-zstatus = abap_false.
*
*                TRY.
*                    <fs_out>-zmg = |{ 'Quantidade não disponível na PO' } { <fs_out>-ebeln_ref } { 'de Referência' }|.
*                  CATCH cx_root.
*                ENDTRY.
*
*                MOVE-CORRESPONDING <fs_out> TO ls_t058.
*                MODIFY ztbmm00107 FROM ls_t058.
*
*                MOVE-CORRESPONDING ls_t058 TO ls_t059.
*
*                ls_t059-type    = 'E'.
*                ls_t059-id      = 'MM'.
*                ls_t059-znumber = '899'.
*                ls_t059-message = <fs_out>-zmg.
*
*                ADD 1 TO ls_t059-zseq.
*
*                INSERT ls_t059 INTO TABLE gt_log_msg.
*                MODIFY ztbmm00108 FROM ls_t059.
*
*                EXIT.
*
*              ENDIF.
*
*            CATCH cx_root.
*          ENDTRY.
*
*          FREE: lv_item,
*                ls_poheader,
*                ls_poheaderx,
*                lt_poitem,
*                lt_poitemx,
*                lt_return.
*
*          ADD: 10 TO lv_item.
*
**Preenche cabeçalho da BAPI
*          ls_poheader = VALUE #( comp_code  = ls_ekko_ref-bukrs
*                                 creat_date = sy-datum
*                                 created_by = sy-uname
*                                 suppl_plnt = ls_ekko_ref-reswk
*                                 purch_org  = ls_ekko_ref-ekorg
*                                 pur_group  = ls_ekko_ref-ekgrp ).
*
*          TRY.
*              ls_poheader-doc_type = gt_param_fisia[ field_name = 'BSART'
*                                                     active     = abap_true ]-low.
*            CATCH cx_root.
*          ENDTRY.
*
*          TRY.
*              ls_poheader-incoterms1 = gt_param_fisia[ field_name = 'INCO1'
*                                                       active     = abap_true ]-low.
*            CATCH cx_root.
*          ENDTRY.
*
*          TRY.
*              ls_poheader-incoterms2 = gt_param_fisia[ field_name = 'INCO1'
*                                                       active     = abap_true ]-low.
*            CATCH cx_root.
*          ENDTRY.
*
*          ls_poheaderx = VALUE #( comp_code = abap_true
*                                  doc_type   = abap_true
*                                  creat_date = abap_true
*                                  created_by = abap_true
*                                  suppl_plnt = abap_true
*                                  purch_org  = abap_true
*                                  pur_group  = abap_true
*                                  incoterms1 = abap_true
*                                  incoterms2 = abap_true ).
*
**Preenche itens da BAPI
*          APPEND INITIAL LINE TO lt_poitem ASSIGNING FIELD-SYMBOL(<fs_item>).
*          <fs_item> = VALUE #( po_item    = lv_item
*                               ref_doc    = <fs_out>-ebeln_ref
*                               ref_item   = <fs_out>-ebelp_ref ).
*
*          APPEND INITIAL LINE TO lt_poitemx ASSIGNING FIELD-SYMBOL(<fs_itemx>).
*          <fs_itemx> = VALUE #( po_item    = lv_item
*                                ref_doc    = abap_true
*                                ref_item   = abap_true ).
*
*        CATCH cx_root.
*      ENDTRY.
*
*    ENDLOOP.
*
*    CALL FUNCTION 'BAPI_PO_CREATE1'
*      EXPORTING
*        poheader         = ls_poheader
*        poheaderx        = ls_poheaderx
*      IMPORTING
*        exppurchaseorder = lv_po_number
*      TABLES
*        return           = lt_return
*        poitem           = lt_poitem
*        poitemx          = lt_poitemx.
*
*    DELETE lt_return WHERE type EQ 'W'.
*
*    IF lv_po_number IS INITIAL.
*
*      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
*
*      LOOP AT lt_row_no INTO ls_row_no.
*
*        READ TABLE gt_out ASSIGNING <fs_out> INDEX ls_row_no-row_id.
*
*        <fs_out>-id_icon = icon_red_light.
*        <fs_out>-zstatus = abap_false.
*
*        TRY.
*            <fs_out>-zmg = lt_return[ 1 ]-message.
*          CATCH cx_root.
*        ENDTRY.
*
*        MOVE-CORRESPONDING <fs_out> TO ls_t058.
*        MODIFY ztbmm00107 FROM ls_t058.
*
*        MOVE-CORRESPONDING ls_t058 TO ls_t059.
*
*        LOOP AT lt_return INTO DATA(ls_return).
*
*          MOVE-CORRESPONDING ls_return TO ls_t059.
*
*          ls_t059-znumber = ls_return-number.
*          ADD 1 TO ls_t059-zseq.
*
*          INSERT ls_t059 INTO TABLE gt_log_msg.
*          MODIFY ztbmm00108 FROM ls_t059.
*
*        ENDLOOP.
*      ENDLOOP.
*
*    ELSE.
*
*      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
*
*      FREE lv_item.
*
*      LOOP AT lt_row_no INTO ls_row_no.
*
*        READ TABLE gt_out ASSIGNING <fs_out> INDEX ls_row_no-row_id.
*
*        ADD 10 TO lv_item.
*
*        <fs_out>-id_icon     = icon_complete.
*        <fs_out>-ebeln_yub2  = lv_po_number.
*        <fs_out>-ebelp_yub2  = lv_item.
*        <fs_out>-zstatus     = abap_true.
*
*        TRY.
*            <fs_out>-zmg = lt_return[ 1 ]-message.
*          CATCH cx_root.
*        ENDTRY.
*
*        MOVE-CORRESPONDING <fs_out> TO ls_t058.
*        MODIFY ztbmm00107 FROM ls_t058.
*        IF sy-subrc = 0.
*          COMMIT WORK.
*        ENDIF.
*
*        MOVE-CORRESPONDING ls_t058 TO ls_t059.
*
*        LOOP AT lt_return INTO ls_return.
*
*          MOVE-CORRESPONDING ls_return TO ls_t059.
*
*          ls_t059-znumber = ls_return-number.
*          ADD 1 TO ls_t059-zseq.
*
*          INSERT ls_t059 INTO TABLE gt_log_msg.
*          MODIFY ztbmm00108 FROM ls_t059.
*          IF sy-subrc = 0.
*            COMMIT WORK.
*          ENDIF.
*
*        ENDLOOP.
*
*        WAIT UP TO 2 SECONDS.
*
*        change_po( EXPORTING iv_ebeln_yub2 = lv_po_number
*                             is_out        = <fs_out> ).
*
*      ENDLOOP.
*
*    ENDIF.
*
*  ENDMETHOD.
  METHOD criar_po.

    DATA: lt_poitem    TYPE TABLE OF bapimepoitem,
          lt_poitemx   TYPE TABLE OF bapimepoitemx,
          lt_return    TYPE TABLE OF bapiret2,
          ls_poheader  TYPE bapimepoheader,
          ls_poheaderx TYPE bapimepoheaderx,
          ls_t058      TYPE ztbmm00107,
          ls_t059      TYPE ztbmm00108,
          lv_item      TYPE ebelp,
          lv_po_number TYPE ebeln.

    go_grid->get_selected_rows( IMPORTING et_row_no = DATA(lt_row_no) ).

    LOOP AT lt_row_no INTO DATA(ls_row_no).

      READ TABLE gt_out ASSIGNING FIELD-SYMBOL(<fs_out>) INDEX ls_row_no-row_id.
      CHECK sy-subrc EQ 0 AND <fs_out>-id_icon NE icon_complete.

      TRY.

          DATA(ls_ekko_ref) = gt_ekko_ref[ ebeln = <fs_out>-ebeln_ref ].

          TRY.

              DATA(ls_ekpo_ref) = gt_ekpo_ref[ ebeln = <fs_out>-ebeln_ref
                                               matnr = <fs_out>-matnr ].

              IF <fs_out>-menge > ls_ekpo_ref-menge.

                <fs_out>-id_icon = icon_red_light.
                <fs_out>-zstatus = abap_false.

                TRY.
                    <fs_out>-zmg = |{ 'Quantidade não disponível na PO' } { <fs_out>-ebeln_ref } { 'de Referência' }|.
                  CATCH cx_root.
                ENDTRY.

                MOVE-CORRESPONDING <fs_out> TO ls_t058.
                MODIFY ztbmm00107 FROM ls_t058.

                MOVE-CORRESPONDING ls_t058 TO ls_t059.

                ls_t059-type    = 'E'.
                ls_t059-id      = 'MM'.
                ls_t059-znumber = '899'.
                ls_t059-message = <fs_out>-zmg.

                ADD 1 TO ls_t059-zseq.

                INSERT ls_t059 INTO TABLE gt_log_msg.
                MODIFY ztbmm00108 FROM ls_t059.

                EXIT.

              ENDIF.

            CATCH cx_root.
          ENDTRY.

          ADD: 10 TO lv_item.

*Preenche cabeçalho da BAPI
          ls_poheader = VALUE #( comp_code  = ls_ekko_ref-bukrs
                                 creat_date = sy-datum
                                 created_by = sy-uname
                                 suppl_plnt = ls_ekko_ref-reswk
                                 purch_org  = ls_ekko_ref-ekorg
                                 pur_group  = ls_ekko_ref-ekgrp
                                 our_ref    = <fs_out>-ebeln_ref ). "YLW - EA - 21/09/2022

          TRY.
              ls_poheader-doc_type = gt_param_fisia[ field_name = 'BSART'
                                                     active     = abap_true ]-low.
            CATCH cx_root.
          ENDTRY.

          TRY.
              ls_poheader-incoterms1 = gt_param_fisia[ field_name = 'INCO1'
                                                       active     = abap_true ]-low.
            CATCH cx_root.
          ENDTRY.

          TRY.
              ls_poheader-incoterms2 = gt_param_fisia[ field_name = 'INCO1'
                                                       active     = abap_true ]-low.
            CATCH cx_root.
          ENDTRY.

          ls_poheaderx = VALUE #( comp_code = abap_true
                                  doc_type   = abap_true
                                  creat_date = abap_true
                                  created_by = abap_true
                                  suppl_plnt = abap_true
                                  purch_org  = abap_true
                                  pur_group  = abap_true
                                  incoterms1 = abap_true
                                  incoterms2 = abap_true
                                  our_ref    = abap_true ). "YLW - EA - 21/09/2022

*Preenche itens da BAPI
          APPEND INITIAL LINE TO lt_poitem ASSIGNING FIELD-SYMBOL(<fs_item>).
          <fs_item> = VALUE #( po_item    = lv_item
                               ref_doc    = <fs_out>-ebeln_ref
                               ref_item   = <fs_out>-ebelp_ref
                               plant      = <fs_out>-werks
                               stge_loc   = <fs_out>-lgort
                               quantity   = <fs_out>-menge
                               shipping   = 'TR' ).  "YLW - EA - 21/09/2022
*                               suppl_stloc = <fs_out>-reslo ). "YLW - EA - 21/09/2022

          APPEND INITIAL LINE TO lt_poitemx ASSIGNING FIELD-SYMBOL(<fs_itemx>).
          <fs_itemx> = VALUE #( po_item    = lv_item
                                ref_doc    = abap_true
                                ref_item   = abap_true
                                plant      = abap_true
                                stge_loc   = abap_true
                                quantity   = abap_true
                                shipping   = abap_true ). "YLW - EA - 21/09/2022
*                                suppl_stloc = abap_true ). "YLW - EA - 21/09/2022

        CATCH cx_root.
      ENDTRY.

      CLEAR ls_ekpo_ref. "YLW - EA - 21/09/2022

    ENDLOOP.

    CALL FUNCTION 'BAPI_PO_CREATE1'
      EXPORTING
        poheader         = ls_poheader
        poheaderx        = ls_poheaderx
      IMPORTING
        exppurchaseorder = lv_po_number
      TABLES
        return           = lt_return
        poitem           = lt_poitem
        poitemx          = lt_poitemx.

    DELETE lt_return WHERE type EQ 'W'.

    IF lv_po_number IS INITIAL.

      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

      LOOP AT lt_row_no INTO ls_row_no.

        READ TABLE gt_out ASSIGNING <fs_out> INDEX ls_row_no-row_id.

        <fs_out>-id_icon = icon_red_light.
        <fs_out>-zstatus = abap_false.

        TRY.
            <fs_out>-zmg = lt_return[ 1 ]-message.
          CATCH cx_root.
        ENDTRY.

        MOVE-CORRESPONDING <fs_out> TO ls_t058.
        MODIFY ztbmm00107 FROM ls_t058.

        MOVE-CORRESPONDING ls_t058 TO ls_t059.

        LOOP AT lt_return INTO DATA(ls_return).

          MOVE-CORRESPONDING ls_return TO ls_t059.

          ls_t059-znumber = ls_return-number.
          ADD 1 TO ls_t059-zseq.

          INSERT ls_t059 INTO TABLE gt_log_msg.
          MODIFY ztbmm00108 FROM ls_t059.

        ENDLOOP.
      ENDLOOP.

    ELSE.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.

      FREE lv_item.

      LOOP AT lt_row_no INTO ls_row_no.

        READ TABLE gt_out ASSIGNING <fs_out> INDEX ls_row_no-row_id.

        ADD 10 TO lv_item.

        <fs_out>-id_icon     = icon_complete.
        <fs_out>-ebeln_yub2  = lv_po_number.
        <fs_out>-ebelp_yub2  = lv_item.
        <fs_out>-zstatus     = abap_true.

        TRY.
            <fs_out>-zmg = lt_return[ 1 ]-message.
          CATCH cx_root.
        ENDTRY.

        MOVE-CORRESPONDING <fs_out> TO ls_t058.
        MODIFY ztbmm00107 FROM ls_t058.
        IF sy-subrc = 0.
          COMMIT WORK.
        ENDIF.

        MOVE-CORRESPONDING ls_t058 TO ls_t059.

        LOOP AT lt_return INTO ls_return.

          MOVE-CORRESPONDING ls_return TO ls_t059.

          ls_t059-znumber = ls_return-number.
          ADD 1 TO ls_t059-zseq.

          INSERT ls_t059 INTO TABLE gt_log_msg.
          MODIFY ztbmm00108 FROM ls_t059.
          IF sy-subrc = 0.
            COMMIT WORK.
          ENDIF.

        ENDLOOP.

        WAIT UP TO 2 SECONDS.

        change_po( EXPORTING iv_ebeln_yub2 = lv_po_number
                             is_out        = <fs_out> ).

      ENDLOOP.

    ENDIF.

    FREE: lv_item,
          ls_poheader,
          ls_poheaderx,
          lt_poitem,
          lt_poitemx,
          lt_return.

  ENDMETHOD.

***YLW - EA - 21/09/2022 - Início
  METHOD cria_po_yub2.

    DATA: lt_poitem    TYPE TABLE OF bapimepoitem,
          lt_poitemx   TYPE TABLE OF bapimepoitemx,
          lt_return    TYPE TABLE OF bapiret2,
          ls_poheader  TYPE bapimepoheader,
          ls_poheaderx TYPE bapimepoheaderx,
          ls_out       LIKE LINE OF gt_out,
          ls_t058      TYPE ztbmm00107,
          ls_t059      TYPE ztbmm00108,
          ls_ekko_ref  TYPE ekko,
          ls_ekpo_ref  TYPE ekpo,
          ls_tabix     TYPE ty_tabix,
          lv_item      TYPE ebelp,
          lv_agrup     TYPE ztbmm00107-agrup,
          lv_ebeln     TYPE ztbmm00107-ebeln_ref,
          lv_werks     TYPE ztbmm00107-werks,
          lv_tabix     TYPE sy-tabix,
          lv_msg       TYPE bapi_msg,
          lv_quant     TYPE ztbmm00107-menge,
          lv_limite    TYPE ztbmm00107-menge,
          lv_sobra     TYPE ztbmm00107-menge,
          lv_po_number TYPE ebeln.

    IF p_backg EQ abap_true AND s_time[] IS INITIAL.

      PERFORM zf_prepara_job.

    ELSE.

      TRY.
          gv_bsart = gt_param_fisia[ field_name = 'BSART'
                                     active     = abap_true ]-low.
        CATCH cx_root.
      ENDTRY.

      TRY.
          gv_inco1 = gt_param_fisia[ field_name = 'INCO1'
                                     active     = abap_true ]-low.
        CATCH cx_root.
      ENDTRY.

      TRY.
          gv_inco2 = gt_param_fisia[ field_name = 'INCO1'
                                     active     = abap_true ]-low.
        CATCH cx_root.
      ENDTRY.

      PERFORM zf_dados_po_ref.

      REFRESH gt_tabix.

      LOOP AT gt_out ASSIGNING FIELD-SYMBOL(<fs_out>).

        lv_tabix = sy-tabix.

        CHECK <fs_out>-id_icon NE icon_complete.

        IF <fs_out>-lgort IS INITIAL OR <fs_out>-reslo IS INITIAL.

          <fs_out>-id_icon = icon_red_light.
          <fs_out>-zstatus = abap_false.

          <fs_out>-zmg = |{ 'Campo Depósito obrigatório, faltam dados na linha' } { lv_tabix }|.
          MOVE-CORRESPONDING <fs_out> TO ls_t058.
          MODIFY ztbmm00107 FROM ls_t058.

          MOVE-CORRESPONDING ls_t058 TO ls_t059.

          ls_t059-type       = 'E'.
          ls_t059-id         = 'MM'.
          ls_t059-znumber    = '899'.
          ls_t059-message_v1 = <fs_out>-zmg.
          ls_t059-message    = <fs_out>-zmg.

          ADD 1 TO ls_t059-zseq.

          INSERT ls_t059 INTO TABLE gt_log_msg.
          MODIFY ztbmm00108 FROM ls_t059.

          CONTINUE.


        ENDIF.


        READ TABLE gt_ekko_ref WITH KEY ebeln = <fs_out>-ebeln_ref
                                        INTO ls_ekko_ref
                                        BINARY SEARCH.

        IF sy-subrc NE 0.

          <fs_out>-id_icon = icon_red_light.
          <fs_out>-zstatus = abap_false.

          CONCATENATE 'PO de Referência'
                      <fs_out>-ebeln_ref
                      'não encontrada'
                      INTO <fs_out>-zmg
                      SEPARATED BY space.
          MOVE-CORRESPONDING <fs_out> TO ls_t058.
          MODIFY ztbmm00107 FROM ls_t058.

          MOVE-CORRESPONDING ls_t058 TO ls_t059.

          ls_t059-type       = 'E'.
          ls_t059-id         = 'MM'.
          ls_t059-znumber    = '899'.
          ls_t059-message_v1 = <fs_out>-zmg.
          ls_t059-message    = <fs_out>-zmg.

          ADD 1 TO ls_t059-zseq.

          INSERT ls_t059 INTO TABLE gt_log_msg.
          MODIFY ztbmm00108 FROM ls_t059.

          CONTINUE.

        ENDIF.

        READ TABLE gt_ekpo_ref WITH KEY ebeln = <fs_out>-ebeln_ref
                                        matnr = <fs_out>-matnr
                                        INTO ls_ekpo_ref
                                        BINARY SEARCH.

        IF sy-subrc NE 0.

          <fs_out>-id_icon = icon_red_light.
          <fs_out>-zstatus = abap_false.

          CONCATENATE 'Material não encontrado na PO de Referência'
                      <fs_out>-ebeln_ref
                      INTO <fs_out>-zmg
                      SEPARATED BY space.
          MOVE-CORRESPONDING <fs_out> TO ls_t058.
          MODIFY ztbmm00107 FROM ls_t058.

          MOVE-CORRESPONDING ls_t058 TO ls_t059.

          ls_t059-type       = 'E'.
          ls_t059-id         = 'MM'.
          ls_t059-znumber    = '899'.
          ls_t059-message_v1 = <fs_out>-zmg.
          ls_t059-message    = <fs_out>-zmg.

          ADD 1 TO ls_t059-zseq.

          INSERT ls_t059 INTO TABLE gt_log_msg.
          MODIFY ztbmm00108 FROM ls_t059.

          CONTINUE.

        ELSE.

          IF <fs_out>-menge > ls_ekpo_ref-menge.

            <fs_out>-id_icon = icon_red_light.
            <fs_out>-zstatus = abap_false.

            CONCATENATE 'Quantidade não disponível na PO'
                        <fs_out>-ebeln_ref
                        'de Referência'
                        INTO <fs_out>-zmg
                        SEPARATED BY space.

            MOVE-CORRESPONDING <fs_out> TO ls_t058.
            MODIFY ztbmm00107 FROM ls_t058.

            MOVE-CORRESPONDING ls_t058 TO ls_t059.

            ls_t059-type       = 'E'.
            ls_t059-id         = 'MM'.
            ls_t059-znumber    = '899'.
            ls_t059-message_v1 = <fs_out>-zmg.
            ls_t059-message    = <fs_out>-zmg.

            ADD 1 TO ls_t059-zseq.

            INSERT ls_t059 INTO TABLE gt_log_msg.
            MODIFY ztbmm00108 FROM ls_t059.

            CONTINUE.

          ENDIF.

        ENDIF.

        DATA:v_erro TYPE xfeld.
        LOOP AT gt_out ASSIGNING FIELD-SYMBOL(<fs_out_validar>) WHERE agrup     = <fs_out>-agrup     AND
                                                                      ebeln_ref = <fs_out>-ebeln_ref AND
                                                                      werks     = <fs_out>-werks.
          IF <fs_out_validar>-reslo IS INITIAL.
            <fs_out>-id_icon = icon_red_light.
            <fs_out>-zstatus = abap_false.
            CONCATENATE 'Depósito de Saida não Informado '
                        ' Agroup ' <fs_out>-agrup
                        ' Centro ' <fs_out>-werks
                        INTO <fs_out>-zmg
                        SEPARATED BY space.

            MOVE-CORRESPONDING <fs_out> TO ls_t058.
            MODIFY ztbmm00107 FROM ls_t058.

            MOVE-CORRESPONDING ls_t058 TO ls_t059.

            ls_t059-type       = 'E'.
            ls_t059-id         = 'MM'.
            ls_t059-znumber    = '899'.
            ls_t059-message_v1 = <fs_out>-zmg.
            ls_t059-message    = <fs_out>-zmg.

            ADD 1 TO ls_t059-zseq.

            INSERT ls_t059 INTO TABLE gt_log_msg.
            MODIFY ztbmm00108 FROM ls_t059.
            v_erro = abap_true.
            CONTINUE.
          ENDIF.

        ENDLOOP.
        IF v_erro IS NOT INITIAL.
          clear v_erro.
          CONTINUE.
        ENDIF.


        IF lv_agrup IS INITIAL AND
           lv_ebeln IS INITIAL AND
           lv_werks IS INITIAL.

          lv_agrup = <fs_out>-agrup.
          lv_ebeln = <fs_out>-ebeln_ref.
          lv_werks = <fs_out>-werks.

          CLEAR: lv_quant,
                 lv_item.
        ENDIF.

        IF lv_agrup NE <fs_out>-agrup OR
           lv_ebeln NE <fs_out>-ebeln_ref OR
           lv_werks NE <fs_out>-werks.

          PERFORM zf_cria_po TABLES lt_poitem
                                    lt_poitemx
                              USING ls_poheader
                                    ls_poheaderx
                           CHANGING lv_po_number
                                    lv_msg.

          CLEAR: ls_poheader,
                 ls_poheaderx,
                 lv_quant,
                 lv_item.

          REFRESH: lt_poitem,
                   lt_poitemx,
                   gt_tabix.

        ENDIF.

        ADD <fs_out>-menge TO lv_quant.
        ADD 10 TO lv_item.

        ls_tabix-line = lv_tabix.
        ls_tabix-matnr = <fs_out>-matnr.
        APPEND ls_tabix TO gt_tabix.

        IF lv_quant GE 500.

          IF lv_quant GT 500.

            SUBTRACT <fs_out>-menge FROM lv_quant.
            lv_limite = 500 - lv_quant.
            lv_sobra  = <fs_out>-menge - lv_limite.

            MOVE-CORRESPONDING <fs_out> TO ls_out.
            ls_out-menge = lv_sobra.

            ADD 1 TO lv_tabix.
            INSERT ls_out INTO gt_out INDEX lv_tabix.

            <fs_out>-menge = lv_limite.

          ENDIF.

          PERFORM zf_monta_bapi TABLES lt_poitem
                                       lt_poitemx
                                 USING lv_item
                                       ls_ekko_ref
                                       ls_ekpo_ref
                                       <fs_out>-ebeln_ref
                                       <fs_out>-ebelp_ref
                                       <fs_out>-werks
                                       <fs_out>-lgort
                                       <fs_out>-menge
                                       <fs_out>-reslo
                              CHANGING ls_poheader
                                       ls_poheaderx.

          PERFORM zf_cria_po TABLES lt_poitem
                                    lt_poitemx
                              USING ls_poheader
                                    ls_poheaderx
                           CHANGING lv_po_number
                                    lv_msg.

          CLEAR: ls_poheader,
                 ls_poheaderx,
                 lv_quant,
                 lv_item.

          REFRESH: lt_poitem,
                   lt_poitemx,
                   gt_tabix.

        ELSE.

          PERFORM zf_monta_bapi TABLES lt_poitem
                                       lt_poitemx
                                 USING lv_item
                                       ls_ekko_ref
                                       ls_ekpo_ref
                                       <fs_out>-ebeln_ref
                                       <fs_out>-ebelp_ref
                                       <fs_out>-werks
                                       <fs_out>-lgort
                                       <fs_out>-menge
                                       <fs_out>-reslo
                              CHANGING ls_poheader
                                       ls_poheaderx.

        ENDIF.

        lv_agrup = <fs_out>-agrup.
        lv_ebeln = <fs_out>-ebeln_ref.
        lv_werks = <fs_out>-werks.

      ENDLOOP.

      IF NOT lt_poitem[] IS INITIAL.

        PERFORM zf_cria_po TABLES lt_poitem
                                  lt_poitemx
                            USING ls_poheader
                                  ls_poheaderx
                         CHANGING lv_po_number
                                  lv_msg.

        CLEAR: ls_poheader,
               ls_poheaderx,
               lv_quant,
               lv_item.

        REFRESH: lt_poitem,
                 lt_poitemx,
                 gt_tabix.

      ENDIF.
    ENDIF.

  ENDMETHOD.
***YLW - EA - 21/09/2022 - Fim

  METHOD change_po.

    DATA: lt_return    TYPE TABLE OF bapiret2,
          lt_poitem    TYPE TABLE OF bapimepoitem,
          lt_poitemx   TYPE TABLE OF bapimepoitemx,
          lt_schedule  TYPE TABLE OF bapimeposchedule,
          lt_schedulex TYPE TABLE OF bapimeposchedulx,
          lv_menge     TYPE ekpo-menge.

    lt_poitem = VALUE #( ( po_item  = is_out-ebelp_yub2
                           material = is_out-matnr
                           plant    = is_out-werks
                           stge_loc = is_out-lgort
                           quantity	= is_out-menge ) ).

    lt_poitemx = VALUE #( ( po_item  = is_out-ebelp_yub2
                            material = abap_true
                            plant    = abap_true
                            stge_loc = abap_true
                            quantity = abap_true ) ).

    lt_schedule = VALUE #( ( po_item    = is_out-ebelp_yub2
                             sched_line = 1
                             delivery_date = sy-datum ) ).

    lt_schedulex = VALUE #( ( po_item    = is_out-ebelp_yub2
                              po_itemx   = abap_true
                              sched_line = 1
                              delivery_date = abap_true ) ).

    CALL FUNCTION 'BAPI_PO_CHANGE'
      EXPORTING
        purchaseorder = iv_ebeln_yub2
      TABLES
        return        = lt_return
        poitem        = lt_poitem
        poitemx       = lt_poitemx
        poschedule    = lt_schedule
        poschedulex   = lt_schedulex.

    DELETE lt_return WHERE type EQ 'W'.

    IF line_exists( lt_return[ type = 'E' ] ).
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.


      FREE: lt_poitem,
            lt_poitemx,
            lt_schedule,
            lt_schedulex,
            lt_return.
      CLEAR: lv_menge.
      "atualiza PO YUB1
      READ TABLE gt_ekpo_ref INTO DATA(ls_ekpo_ref) WITH KEY ebeln = is_out-ebeln_ref
                                                             ebelp = is_out-ebelp_ref.
      IF sy-subrc = 0.

        lv_menge = ls_ekpo_ref-menge - is_out-menge.

        IF lv_menge < 1.

          lv_menge = '0.001'.

          lt_poitem = VALUE #( ( po_item  = is_out-ebelp_ref
                                 delete_ind = abap_true
                                 quantity	= lv_menge ) ).

          lt_poitemx = VALUE #( ( po_item   = is_out-ebelp_ref
                                  delete_ind = abap_true
                                  quantity  = abap_true ) ).

        ELSE.

          lt_poitem = VALUE #( ( po_item  = is_out-ebelp_ref
                                 quantity	= lv_menge ) ).

          lt_poitemx = VALUE #( ( po_item   = is_out-ebelp_ref
                                  quantity  = abap_true ) ).

        ENDIF.

        CALL FUNCTION 'BAPI_PO_CHANGE'
          EXPORTING
            purchaseorder = is_out-ebeln_ref
          TABLES
            return        = lt_return
            poitem        = lt_poitem
            poitemx       = lt_poitemx.

        DELETE lt_return WHERE type EQ 'W'.

        IF line_exists( lt_return[ type = 'E' ] ).
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        ELSE.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
        ENDIF.

      ENDIF.

    ENDIF.


  ENDMETHOD.

ENDCLASS.

*&---------------------------------------------------------------------*
*& Form zf_cria_po
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_POITEM
*&      --> LS_POHEADER
*&      --> LS_POHEADERX
*&---------------------------------------------------------------------*
FORM zf_cria_po TABLES pt_poitem   TYPE bapimepoitem_tp
                       pt_poitemx  TYPE bapimepoitemx_tp
                 USING p_poheader  TYPE bapimepoheader
                       p_poheaderx TYPE bapimepoheaderx
              CHANGING p_po_number TYPE ebeln
                       p_msg       TYPE bapi_msg.

  DATA: lt_return TYPE TABLE OF bapiret2,
        lt_matnr  TYPE TABLE OF ty_tabix,
        ls_return TYPE bapiret2,
        ls_t058   TYPE ztbmm00107,
        ls_t059   TYPE ztbmm00108,
        ls_tabix  TYPE ty_tabix,
        lv_item   TYPE ebelp.

  CLEAR: p_po_number,
         p_msg.

  lt_matnr = gt_tabix.
  SORT lt_matnr BY matnr.
  DELETE ADJACENT DUPLICATES FROM lt_matnr COMPARING matnr.

  IF sy-subrc EQ 0.

    LOOP AT gt_tabix INTO ls_tabix.

      READ TABLE gt_out ASSIGNING FIELD-SYMBOL(<fs_out>) INDEX ls_tabix-line.

      <fs_out>-id_icon = icon_red_light.
      <fs_out>-zstatus = abap_false.
      <fs_out>-zmg = 'Itens/SKUs duplicados para um mesmo Pedido de Transferência não é permitido'.

      MOVE-CORRESPONDING <fs_out> TO ls_t058.
      MODIFY ztbmm00107 FROM ls_t058.

      MOVE-CORRESPONDING ls_t058 TO ls_t059.
      ls_t059-type       = 'E'.
      ls_t059-id         = 'MM'.
      ls_t059-znumber    = '899'.
      ls_t059-message    = <fs_out>-zmg.
      ls_t059-message_v1 = <fs_out>-zmg.

      ADD 1 TO ls_t059-zseq.
      INSERT ls_t059 INTO TABLE gt_log_msg.
      MODIFY ztbmm00108 FROM ls_t059.

    ENDLOOP.

  ELSE.

    CALL FUNCTION 'BAPI_PO_CREATE1'
      EXPORTING
        poheader         = p_poheader
        poheaderx        = p_poheaderx
      IMPORTING
        exppurchaseorder = p_po_number
      TABLES
        return           = lt_return
        poitem           = pt_poitem
        poitemx          = pt_poitemx.

    DELETE lt_return WHERE type EQ 'W'.

    IF p_po_number IS INITIAL.

      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

      READ TABLE lt_return INTO ls_return INDEX 1.

      IF sy-subrc EQ 0.
        p_msg = ls_return-message.
      ENDIF.

      LOOP AT gt_tabix INTO ls_tabix.

        READ TABLE gt_out ASSIGNING <fs_out> INDEX ls_tabix-line.

        <fs_out>-id_icon = icon_red_light.
        <fs_out>-zstatus = abap_false.

        TRY.
            <fs_out>-zmg = lt_return[ 1 ]-message.
          CATCH cx_root.
        ENDTRY.

        MOVE-CORRESPONDING <fs_out> TO ls_t058.
        MODIFY ztbmm00107 FROM ls_t058.

        MOVE-CORRESPONDING ls_t058 TO ls_t059.

        LOOP AT lt_return INTO ls_return.

          MOVE-CORRESPONDING ls_return TO ls_t059.

          ls_t059-znumber = ls_return-number.
          ADD 1 TO ls_t059-zseq.

          INSERT ls_t059 INTO TABLE gt_log_msg.
          MODIFY ztbmm00108 FROM ls_t059.

        ENDLOOP.

      ENDLOOP.

    ELSE.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = abap_true.

      LOOP AT gt_tabix INTO ls_tabix.

        READ TABLE gt_out ASSIGNING <fs_out> INDEX ls_tabix-line.

        ADD 10 TO lv_item.

        <fs_out>-id_icon     = icon_complete.
        <fs_out>-ebeln_yub2  = p_po_number.
        <fs_out>-ebelp_yub2  = lv_item.
        <fs_out>-zstatus     = abap_true.

        TRY.
            <fs_out>-zmg = lt_return[ 1 ]-message.
          CATCH cx_root.
        ENDTRY.

        MOVE-CORRESPONDING <fs_out> TO ls_t058.
        MODIFY ztbmm00107 FROM ls_t058.
        IF sy-subrc = 0.
          COMMIT WORK.
        ENDIF.

        MOVE-CORRESPONDING ls_t058 TO ls_t059.

        LOOP AT lt_return INTO ls_return WHERE type EQ 'S'.

          MOVE-CORRESPONDING ls_return TO ls_t059.

          ls_t059-znumber = ls_return-number.
          ADD 1 TO ls_t059-zseq.

          INSERT ls_t059 INTO TABLE gt_log_msg.
          MODIFY ztbmm00108 FROM ls_t059.
          IF sy-subrc = 0.
            COMMIT WORK.
          ENDIF.

        ENDLOOP.

        WAIT UP TO 2 SECONDS.

        PERFORM zf_change_po USING p_po_number
                                   p_poheader-suppl_plnt
                                   <fs_out>.

      ENDLOOP.

    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zf_monta_bapi
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_POITEM
*&      --> LT_POITEMX
*&      --> LV_ITEM
*&      <-- LS_POHEADER
*&      <-- LS_POHEADERX
*&---------------------------------------------------------------------*
FORM zf_monta_bapi TABLES pt_poitem   TYPE bapimepoitem_tp
                          pt_poitemx  TYPE bapimepoitemx_tp
                    USING p_item      TYPE ebelp
                          p_ekko      TYPE ekko
                          p_ekpo      TYPE ekpo
                          p_ebeln_ref TYPE ebeln
                          p_ebelp_ref TYPE ebelp
                          p_werks     TYPE werks_d
                          p_lgort     TYPE lgort_d
                          p_menge     TYPE bstmg
                          p_reslo     TYPE reslo
                 CHANGING p_poheader  TYPE bapimepoheader
                          p_poheaderx TYPE bapimepoheaderx.

*Preenche cabeçalho da BAPI
  p_poheader = VALUE #( comp_code  = p_ekko-bukrs
                        creat_date = sy-datum
                        created_by = sy-uname
                        suppl_plnt = p_ekko-reswk
                        purch_org  = p_ekko-ekorg
                        pur_group  = p_ekko-ekgrp
                        doc_type   = gv_bsart
                        incoterms1 = gv_inco1
                        incoterms2 = gv_inco2
                        our_ref    = p_ebeln_ref ). "YLW - EA - 21/09/2022

  p_poheaderx = VALUE #( comp_code  = abap_true
                         doc_type   = abap_true
                         creat_date = abap_true
                         created_by = abap_true
                         suppl_plnt = abap_true
                         purch_org  = abap_true
                         pur_group  = abap_true
                         incoterms1 = abap_true
                         incoterms2 = abap_true
                         our_ref    = abap_true ). "YLW - EA - 21/09/2022

*Preenche itens da BAPI
  APPEND INITIAL LINE TO pt_poitem ASSIGNING FIELD-SYMBOL(<fs_item>).
  <fs_item> = VALUE #( po_item     = p_item
                       ref_doc     = p_ebeln_ref
                       ref_item    = p_ebelp_ref
                       plant       = p_werks
                       stge_loc    = p_lgort
                       quantity    = p_menge
                       shipping    = 'TR' ).   "YLW - EA - 21/09/2022
*                       suppl_stloc = space ). "YLW - EA - 21/09/2022

  APPEND INITIAL LINE TO pt_poitemx ASSIGNING FIELD-SYMBOL(<fs_itemx>).
  <fs_itemx> = VALUE #( po_item     = p_item
                        ref_doc     = abap_true
                        ref_item    = abap_true
                        plant       = abap_true
                        stge_loc    = abap_true
                        quantity    = abap_true
                        shipping    = abap_true ).  "YLW - EA - 21/09/2022
*                        suppl_stloc = abap_true ). "YLW - EA - 21/09/2022

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zf_change_po
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_PO_NUMBER
*&      --> <FS_OUT>
*&---------------------------------------------------------------------*
FORM zf_change_po USING p_po_number TYPE ebeln
                        p_reswk     TYPE reswk
                        p_out       TYPE ty_out.

  DATA: lt_return    TYPE TABLE OF bapiret2,
        lt_poitem    TYPE TABLE OF bapimepoitem,
        lt_poitemx   TYPE TABLE OF bapimepoitemx,
        lt_schedule  TYPE TABLE OF bapimeposchedule,
        lt_schedulex TYPE TABLE OF bapimeposchedulx,
        ls_poheader  TYPE bapimepoheader,
        ls_poheaderx TYPE bapimepoheaderx,
        lv_menge     TYPE ekpo-menge,
        lv_tabix     TYPE sy-tabix.

  lt_poitem = VALUE #( ( po_item  = p_out-ebelp_yub2
                         material = p_out-matnr
                         plant    = p_out-werks
                         stge_loc = p_out-lgort
                         quantity = p_out-menge
                         shipping = 'TR'
                         suppl_stloc = p_out-reslo ) ).

  lt_poitemx = VALUE #( ( po_item  = p_out-ebelp_yub2
                          material = abap_true
                          plant    = abap_true
                          stge_loc = abap_true
                          quantity = abap_true
                          shipping = abap_true
                          suppl_stloc = abap_true ) ).

  lt_schedule = VALUE #( ( po_item    = p_out-ebelp_yub2
                           sched_line = 1
                           delivery_date = sy-datum ) ).

  lt_schedulex = VALUE #( ( po_item    = p_out-ebelp_yub2
                            po_itemx   = abap_true
                            sched_line = 1
                            delivery_date = abap_true ) ).

  ls_poheader-suppl_plnt  = p_reswk.
  ls_poheaderx-suppl_plnt = abap_true.

  CALL FUNCTION 'BAPI_PO_CHANGE'
    EXPORTING
      purchaseorder = p_po_number
      poheader      = ls_poheader
      poheaderx     = ls_poheaderx
    TABLES
      return        = lt_return
      poitem        = lt_poitem
      poitemx       = lt_poitemx
      poschedule    = lt_schedule
      poschedulex   = lt_schedulex.

  DELETE lt_return WHERE type EQ 'W'.

  IF line_exists( lt_return[ type = 'E' ] ).

    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

  ELSE.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.

    FREE: lt_poitem,
          lt_poitemx,
          lt_schedule,
          lt_schedulex,
          lt_return.

    CLEAR: lv_menge.

    "atualiza PO YUB1
    READ TABLE gt_ekpo_ref INTO DATA(ls_ekpo_ref)
      WITH KEY ebeln = p_out-ebeln_ref
               ebelp = p_out-ebelp_ref.

    IF sy-subrc EQ 0.

      lv_tabix = sy-tabix.

      lv_menge = ls_ekpo_ref-menge - p_out-menge.

      IF lv_menge < 1.

        lv_menge = '0.001'.

        lt_poitem = VALUE #( ( po_item    = p_out-ebelp_ref
                               delete_ind = abap_true
                               quantity   = lv_menge ) ).

        lt_poitemx = VALUE #( ( po_item    = p_out-ebelp_ref
                                delete_ind = abap_true
                                quantity   = abap_true ) ).

      ELSE.

        lt_poitem = VALUE #( ( po_item  = p_out-ebelp_ref
                              quantity  = lv_menge ) ).

        lt_poitemx = VALUE #( ( po_item   = p_out-ebelp_ref
                                quantity  = abap_true ) ).

      ENDIF.

      CALL FUNCTION 'BAPI_PO_CHANGE'
        EXPORTING
          purchaseorder = p_out-ebeln_ref
        TABLES
          return        = lt_return
          poitem        = lt_poitem
          poitemx       = lt_poitemx.

      DELETE lt_return WHERE type EQ 'W'.

      IF line_exists( lt_return[ type = 'E' ] ).

        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

      ELSE.

        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = abap_true.

        ls_ekpo_ref-menge = lv_menge.
        MODIFY gt_ekpo_ref FROM ls_ekpo_ref INDEX lv_tabix.

      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zf_prepara_job
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zf_prepara_job.

  DATA: lt_ztbmm00107 TYPE TABLE OF ztbmm00107,
        lr_file       TYPE RANGE OF ztbmm00107-zarquivo,
        lr_date       TYPE RANGE OF ztbmm00107-zdate,
        lr_time       TYPE RANGE OF ztbmm00107-ztime,
        lr_stat       TYPE RANGE OF ztbmm00107-zstatus,
        ls_file       LIKE LINE OF lr_file,
        ls_date       LIKE LINE OF lr_date,
        ls_time       LIKE LINE OF lr_time,
        ls_stat       LIKE LINE OF lr_stat,
        ls_ztbmm00107 TYPE ztbmm00107,
        lv_uzeit      TYPE sy-uzeit,
        lv_item       TYPE ebelp,
        lv_seq        TYPE ztbmm00107-zseq,
        lv_job_name   TYPE tbtcjob-jobname,
        lv_job_count  TYPE tbtcjob-jobcount.

  lv_uzeit = sy-uzeit.

  ls_file = 'IEQ'.
  ls_file-low = gv_file.
  APPEND ls_file TO lr_file.

  ls_date = 'IEQ'.
  ls_date-low  = sy-datum.
  ls_date-high = sy-datum.
  APPEND ls_date TO lr_date.

  ls_time = 'IEQ'.
  ls_time-low  = lv_uzeit.
  ls_time-high = lv_uzeit.
  APPEND ls_time TO lr_time.

  ls_stat = 'IEQ'.
  ls_stat-low = space.
  APPEND ls_stat TO lr_stat.

  LOOP AT gt_out ASSIGNING FIELD-SYMBOL(<fs_out>).

    CLEAR ls_ztbmm00107.
    ADD 1 TO lv_seq.

    <fs_out>-id_icon    = icon_complete.
    <fs_out>-ztime      = lv_uzeit.
    <fs_out>-ebeln_yub2 = 'FISIA BKGR'.
    MOVE-CORRESPONDING <fs_out> TO ls_ztbmm00107.
    ls_ztbmm00107-zseq  = lv_seq.
    APPEND ls_ztbmm00107 TO lt_ztbmm00107.

  ENDLOOP.

  CHECK NOT lt_ztbmm00107 IS INITIAL.

  MODIFY ztbmm00107 FROM TABLE lt_ztbmm00107.

  CHECK sy-subrc EQ 0.

  COMMIT WORK AND WAIT.

*Escalona JOB para criação PO YUB2
  lv_job_name = sy-repid.

  CALL FUNCTION 'JOB_OPEN'
    EXPORTING
      jobname          = lv_job_name
      sdlstrtdt        = sy-datum
      sdlstrttm        = sy-uzeit
    IMPORTING
      jobcount         = lv_job_count
    EXCEPTIONS
      cant_create_job  = 1
      invalid_job_data = 2
      jobname_missing  = 3
      OTHERS           = 4.

  CHECK sy-subrc EQ 0.

  SUBMIT zrmm_transf_po_yub2
    WITH s_file  IN lr_file
    WITH s_date  IN lr_date
    WITH s_time  IN lr_time
    WITH s_stat  IN lr_stat
    WITH p_backg EQ abap_true
    AND RETURN
    VIA JOB lv_job_name
    NUMBER lv_job_count.

  CALL FUNCTION 'JOB_CLOSE'
    EXPORTING
      jobcount             = lv_job_count
      jobname              = lv_job_name
      sdlstrtdt            = sy-datum
      sdlstrttm            = sy-uzeit
    EXCEPTIONS
      cant_start_immediate = 1
      invalid_startdate    = 2
      jobname_missing      = 3
      job_close_failed     = 4
      job_nosteps          = 5
      job_notex            = 6
      lock_failed          = 7
      invalid_target       = 8
      OTHERS               = 9.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zf_dados_po_ref
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zf_dados_po_ref.

  CHECK gt_ekko_ref IS INITIAL.

  SELECT *
    FROM ekko
    FOR ALL ENTRIES IN @gt_out
    WHERE ebeln EQ @gt_out-ebeln_ref
    INTO TABLE @gt_ekko_ref.

  IF sy-subrc EQ 0.
    SORT gt_ekko_ref BY ebeln.
  ENDIF.

  SELECT *
    FROM ekpo
    FOR ALL ENTRIES IN @gt_out
    WHERE ebeln EQ @gt_out-ebeln_ref
    AND matnr EQ @gt_out-matnr
    INTO TABLE @gt_ekpo_ref.

  IF sy-subrc EQ 0.
    SORT gt_ekpo_ref BY ebeln matnr.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zf_log_background
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zf_log_background.

  DATA: ls_out TYPE ty_out.

  WRITE: AT /1(sy-linsz) sy-uline NO-GAP,
         /1 'Status',
          5 sy-vline,
          6 'Arquivo',
         87 sy-vline,
         88 'Data',
         99 sy-vline,
        100 'Hora',
        109 sy-vline,
        110 'Material',
        151 sy-vline,
        152 'Doc.Ref.',
        163 sy-vline,
        164 'Item',
        170 sy-vline,
        171 'Quantidade',
        189 sy-vline,
        190 'Centro',
        196 sy-vline,
        197 'Dep.',
        202 sy-vline,
        203 'PO Criada',
        214 sy-vline,
        215 'Item',
        221 sy-vline,
        222 'Agrupamento',
        243 sy-vline,
        244 'Mensagem',
      AT /1(sy-linsz) sy-uline NO-GAP.

  LOOP AT gt_out INTO ls_out.

    WRITE: /1 ls_out-id_icon,
            5 sy-vline,
            6 ls_out-zarquivo,
           87 sy-vline,
           88 ls_out-zdate,
           99 sy-vline,
          100 ls_out-ztime,
          109 sy-vline,
          110 ls_out-matnr,
          151 sy-vline,
          152 ls_out-ebeln_ref,
          163 sy-vline,
          164 ls_out-ebelp_ref,
          170 sy-vline,
          171 ls_out-menge,
          189 sy-vline,
          190 ls_out-werks,
          196 sy-vline,
          197 ls_out-lgort,
          202 sy-vline,
          203 ls_out-ebeln_yub2,
          214 sy-vline,
          215 ls_out-ebelp_yub2,
          221 sy-vline,
          222 ls_out-agrup,
          243 sy-vline,
          244 ls_out-zmg.

  ENDLOOP.

  WRITE AT /1(sy-linsz) sy-uline NO-GAP.

ENDFORM.
