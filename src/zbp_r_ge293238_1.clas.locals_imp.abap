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
