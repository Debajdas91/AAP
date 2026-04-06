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



ENDCLASS.
