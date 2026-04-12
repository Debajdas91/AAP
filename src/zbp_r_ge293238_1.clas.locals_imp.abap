CLASS lsc_zr_ge293238_1 DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zr_ge293238_1 IMPLEMENTATION.

  method save_modified.
  DATA : ShoppingCarts       TYPE STANDARD TABLE OF zGE293238_1,
           ShoppingCart        TYPE                   zGE293238_1,
           events_to_be_raised TYPE TABLE FOR EVENT zr_GE293238_1~statusUpdated.

     IF create-shoppingcart IS NOT INITIAL.
       LOOP AT create-shoppingcart INTO DATA(create_shoppingcart).
         IF create_shoppingcart-%control-OverallStatus = if_abap_behv=>mk-on
           " AND create_shoppingcart-OverallStatus = zbp_r_GE293238=>order_state-in_process.
           AND create_shoppingcart-OverallStatus = zbp_r_GE293238_1=>order_state-saved.
           zcl_GE293238_start_bgpf=>run_via_bgpf_tx_uncontrolled( i_rap_bo_key = create_shoppingcart-OrderUuid ).
         ENDIF.
       ENDLOOP.
     ENDIF.

     "the salesorder and the status is updated via BGPF
     IF update-shoppingcart IS NOT INITIAL.
       LOOP AT update-shoppingcart into data(update_shoppingcart).
         IF update_shoppingcart-%control-SalesOrderStatus = if_abap_behv=>mk-on.
           CLEAR events_to_be_raised.
           APPEND INITIAL LINE TO events_to_be_raised.
           events_to_be_raised[ 1 ] = CORRESPONDING #( update_shoppingcart ).
           RAISE ENTITY EVENT zr_GE293238_1~statusUpdated FROM events_to_be_raised.
         ENDIF.

         IF update_shoppingcart-%control-OverallStatus = if_abap_behv=>mk-on
           "AND update_shoppingcart-OverallStatus = zbp_r_GE293238=>order_state-in_process.
           AND update_shoppingcart-OverallStatus = zbp_r_GE293238_1=>order_state-saved.
           zcl_GE293238_start_bgpf=>run_via_bgpf_tx_uncontrolled( i_rap_bo_key = update_shoppingcart-OrderUuid ).
         ENDIF.
       ENDLOOP.
     ENDIF.
  endmethod.

ENDCLASS.

CLASS LHC_ZR_GE293238_1 DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR ShoppingCart
        RESULT result,
      setStatusToNew FOR DETERMINE ON MODIFY
            IMPORTING keys FOR ShoppingCart~setStatusToNew.

          METHODS calculateOrderID FOR DETERMINE ON SAVE
            IMPORTING keys FOR ShoppingCart~calculateOrderID.

          METHODS setStatusToSaved FOR DETERMINE ON SAVE
            IMPORTING keys FOR ShoppingCart~setStatusToSaved.
          METHODS validateOrderedItem FOR VALIDATE ON SAVE
            IMPORTING keys FOR ShoppingCart~validateOrderedItem.

          METHODS validateOrderQuantity FOR VALIDATE ON SAVE
            IMPORTING keys FOR ShoppingCart~validateOrderQuantity.

          METHODS validateRequestedDeliveryDate FOR VALIDATE ON SAVE
            IMPORTING keys FOR ShoppingCart~validateRequestedDeliveryDate.
          METHODS get_instance_features FOR INSTANCE FEATURES
            IMPORTING keys REQUEST requested_features FOR ShoppingCart RESULT result.
ENDCLASS.

CLASS LHC_ZR_GE293238_1 IMPLEMENTATION.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
  ENDMETHOD.

  METHOD setStatusToNew.

  READ ENTITIES OF ZR_GE293238_1 IN LOCAL MODE
    ENTITY ShoppingCart
      FIELDS ( OverallStatus )
      WITH CORRESPONDING #( keys )
    RESULT DATA(entities).

  " If OverallStatus is already set, do nothing
  DELETE entities WHERE OverallStatus IS NOT INITIAL.
  CHECK entities IS NOT INITIAL.

  " Update OverallStatus to 'new' for all entities
  MODIFY ENTITIES OF ZR_GE293238_1 IN LOCAL MODE
    ENTITY ShoppingCart
      UPDATE FIELDS ( OverallStatus )
      WITH VALUE #(
        FOR entity IN entities (
          %tky          = entity-%tky
          OverallStatus = ZBP_R_GE293238_1=>order_state-new
        )
      ).



  ENDMETHOD.

  METHOD calculateOrderID.
 data lv_semantic_key TYPE string.
  " Read the number of entries in the table ZGE293238_1
  SELECT COUNT( * )  FROM zge293238_1 INTO @DATA(lv_count).

  " Calculate the semantic key based on the count
    lv_semantic_key = |SEM-{ lv_count + 1 }|.

  " Read the entities for which the determination is triggered
  READ ENTITIES OF ZR_GE293238_1 IN LOCAL MODE
    ENTITY ShoppingCart
      FIELDS ( OrderID )
      WITH CORRESPONDING #( keys )
    RESULT DATA(entities).

" Update the OrderID with the calculated semantic key
    LOOP AT entities INTO DATA(entity).
      MODIFY ENTITIES OF zr_GE293238_1 IN LOCAL MODE
        ENTITY ShoppingCart
          UPDATE FIELDS ( OrderID )
          WITH VALUE #(
            ( %tky = entity-%tky
              OrderID = lv_semantic_key )
          ).
      APPEND VALUE #(
          %tky        = entity-%tky
          %state_area = 'Determination'
      ) TO reported-ShoppingCart.
    ENDLOOP.

  ENDMETHOD.

  METHOD setStatusToSaved.

  READ ENTITIES OF ZR_GE293238_1 IN LOCAL MODE
    ENTITY ShoppingCart
      FIELDS ( OverallStatus )
      WITH CORRESPONDING #( keys )
    RESULT DATA(entities).

  " If OverallStatus is already set to 'saved', do nothing
  DELETE entities WHERE OverallStatus = ZBP_R_GE293238_1=>order_state-saved.
  CHECK entities IS NOT INITIAL.

  " Update OverallStatus to 'saved' for all entities
  MODIFY ENTITIES OF ZR_GE293238_1 IN LOCAL MODE
    ENTITY ShoppingCart
      UPDATE FIELDS ( OverallStatus )
      WITH VALUE #(
        FOR entity IN entities (
          %tky          = entity-%tky
          OverallStatus = ZBP_R_GE293238_1=>order_state-saved
        )
      ).

  ENDMETHOD.



  METHOD validateOrderedItem.

  "For your convinience there is a central class ZAX_AC_EXCEPTIONS that is beeing used here.

    READ ENTITIES OF zr_GE293238_1 IN LOCAL MODE
       ENTITY ShoppingCart
         FIELDS (  OrderedItem )
         WITH CORRESPONDING #( keys )
       RESULT DATA(entities).

    LOOP AT entities INTO DATA(entity).
      APPEND VALUE #(  %tky               = entity-%tky
                       %state_area        = 'VALIDATE_ORDERED_ITEM' ) TO reported-shoppingcart.
      IF entity-OrderedItem IS INITIAL.
        APPEND VALUE #( %tky = entity-%tky ) TO failed-shoppingcart.

        APPEND VALUE #( %tky               = entity-%tky
                        %state_area        = 'VALIDATE_ORDERED_ITEM'
                        %msg               = NEW zcx_ac_exceptions(
                                                 textid   = zcx_ac_exceptions=>enter_order_item
                                                 severity = if_abap_behv_message=>severity-error )
                        %element-ordereditem = if_abap_behv=>mk-on ) TO reported-shoppingcart.
      ENDIF.

      "For your convenience there are GLOBAL defined types available:
      DATA product_api TYPE REF TO zcl_AC_PRODUCT_API.
      DATA business_data TYPE zcl_AC_PRODUCT_API=>t_business_data_external.

      "... later on, you will be replacing them with your own types.
      "DATA product_api TYPE REF TO zcl_GE293238_PRODUCT_API.
      "DATA business_data TYPE zcl_GE293238_PRODUCT_API=>t_business_data_external.

      DATA filter_conditions  TYPE if_rap_query_filter=>tt_name_range_pairs .
      DATA ranges_table TYPE if_rap_query_filter=>tt_range_option .

      product_api = NEW #(  ).

      ranges_table = VALUE #(
                              (  sign = 'I' option = 'EQ' low = entity-OrderedItem )
                            ).

      filter_conditions = VALUE #( ( name = 'PRODUCT'  range = ranges_table ) ).

      TRY.
          product_api->get_products(
            EXPORTING
              it_filter_cond    = filter_conditions
              top               =  50
              skip              =  0
            IMPORTING
              et_business_data  = business_data
            ) .

          IF business_data IS INITIAL.
            APPEND VALUE #( %tky               = entity-%tky
                            %state_area        = 'VALIDATE_ORDERED_ITEM'
                            %msg               = NEW zcx_ac_exceptions(
                                                     textid   = zcx_ac_exceptions=>product_unkown
                                                     severity = if_abap_behv_message=>severity-error )
                            %element-ordereditem = if_abap_behv=>mk-on ) TO reported-shoppingcart.
          ENDIF.

        CATCH cx_root INTO DATA(exception).
          ASSERT 1 = 2.
*          out->write( cl_message_helper=>get_latest_t100_exception( exception )->if_message~get_longtext( ) ).
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateOrderQuantity.

  READ ENTITIES OF ZR_GE293238_1 IN LOCAL MODE
    ENTITY ShoppingCart
      FIELDS ( OrderQuantity )
      WITH CORRESPONDING #( keys )
    RESULT DATA(entities).

  LOOP AT entities INTO DATA(entity).
    " Check if OrderQuantity is initial
    IF entity-OrderQuantity IS INITIAL.
      APPEND VALUE #( %tky = entity-%tky ) TO failed-ShoppingCart.
      APPEND VALUE #(
          %tky        = entity-%tky
          %state_area = 'Validation'
          %msg        = new_message_with_text(
                          text     = 'Order Quantity must not be initial.'
                          severity = if_abap_behv_message=>severity-error
                        )
      ) TO reported-ShoppingCart.
    ENDIF.
  ENDLOOP.
  ENDMETHOD.

  METHOD validateRequestedDeliveryDate.

  READ ENTITIES OF ZR_GE293238_1 IN LOCAL MODE
    ENTITY ShoppingCart
      FIELDS ( RequestedDeliveryDate )
      WITH CORRESPONDING #( keys )
    RESULT DATA(entities).

  LOOP AT entities INTO DATA(entity).
    " Check if RequestedDeliveryDate is initial
    IF entity-RequestedDeliveryDate IS INITIAL.
      APPEND VALUE #( %tky = entity-%tky ) TO failed-ShoppingCart.
      APPEND VALUE #(
          %tky        = entity-%tky
          %state_area = 'Validation'
          %msg        = new_message_with_text(
                          text     = 'Requested Delivery Date must not be initial.'
                          severity = if_abap_behv_message=>severity-error
                        )
      ) TO reported-ShoppingCart.
      CONTINUE.
    ENDIF.

    " Check if RequestedDeliveryDate is in the future
    IF entity-RequestedDeliveryDate <= cl_abap_context_info=>get_system_date( ).
      APPEND VALUE #( %tky = entity-%tky ) TO failed-ShoppingCart.
      APPEND VALUE #(
          %tky        = entity-%tky
          %state_area = 'Validation'
          %msg        = new_message_with_text(
                          text     = 'Requested Delivery Date must be in the future.'
                          severity = if_abap_behv_message=>severity-error
                        )
      ) TO reported-ShoppingCart.
    ENDIF.
  ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_features.
   " read relevant shopping cart instance data
 READ ENTITIES OF ZR_GE293238_1 IN LOCAL MODE
   ENTITY ShoppingCart
     FIELDS ( OrderUuid OverallStatus )
     WITH CORRESPONDING #( keys )
   RESULT DATA(entities)
   FAILED failed.

 " evaluate the conditions, set the operation state, and set result parameter
 result = VALUE #( FOR entity IN entities
                 ( %tky                   = entity-%tky

                   %features-%update      = COND #( WHEN entity-OverallStatus = zbp_r_GE293238_1=>order_state-released
                                                    THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled   )
                   %features-%delete      = COND #( WHEN entity-OverallStatus = zbp_r_GE293238_1=>order_state-released
                                                    THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )
                   %action-Edit           = COND #( WHEN entity-OverallStatus = zbp_r_GE293238_1=>order_state-released
                                                    THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )
                 ) ).

 ENDMETHOD.


ENDCLASS.
