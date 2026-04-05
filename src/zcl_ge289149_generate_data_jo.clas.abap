CLASS zcl_GE289149_generate_data_jo DEFINITION
PUBLIC
FINAL
CREATE PUBLIC .

PUBLIC SECTION.
INTERFACES if_oo_adt_classrun.

PROTECTED SECTION.
PRIVATE SECTION.
METHODS: delete_demo_data.
METHODS: generate_demo_data.

ENDCLASS.

CLASS zcl_GE289149_generate_data_jo IMPLEMENTATION.
METHOD if_oo_adt_classrun~main.

delete_demo_data(  ).
out->write( 'Table entries deleted' ).

generate_demo_data(  ).
out->write( 'Demo data was generated' ).

ENDMETHOD.

METHOD delete_demo_data.
DELETE FROM zGE289149.
COMMIT WORK.
ENDMETHOD.


METHOD generate_demo_data.
    DATA: demo_data_line TYPE zGE289149,
          demo_data      TYPE STANDARD TABLE OF zGE289149.
    DATA long_time_stamp TYPE timestampl.

    "begin of code-snippet
    demo_data_line-client = '100'.
    demo_data_line-order_uuid = xco_cp=>uuid( )->value.
    demo_data_line-order_id = '00000001' .
    demo_data_line-ordered_item = 'HT-1001'.
    demo_data_line-order_quantity =  '0001' .
    demo_data_line-total_price = '10.00'.
    demo_data_line-currency = 'EUR'.
    demo_data_line-requested_delivery_date = xco_cp=>sy->date( )->as( xco_cp_time=>format->abap )->value.
    demo_data_line-created_by = xco_cp=>sy->user( )->name.
    demo_data_line-created_at = long_time_stamp.
    demo_data_line-last_changed_by = xco_cp=>sy->user( )->name.
    demo_data_line-last_changed_at = long_time_stamp.
    demo_data_line-local_last_changed_at = long_time_stamp.
    APPEND demo_data_line TO demo_data.
    "end of code-snippet


    INSERT zGE289149 FROM TABLE @demo_data.
    COMMIT WORK.

    CLEAR demo_data.
ENDMETHOD.

ENDCLASS.
