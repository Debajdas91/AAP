class ZBP_R_GE293238_1 definition
  public
  abstract
  final
  for behavior of ZR_GE293238_1 .

public section.
CONSTANTS :

  BEGIN OF order_state,
    saved      TYPE string VALUE 'order_saved',
    new        TYPE string VALUE 'new',
    in_process TYPE string VALUE 'in_process',
    unknown    TYPE string VALUE 'unkown',
    released    type string value 'released',
  END OF order_state,

  BEGIN OF sales_order_state,
    created TYPE string VALUE 'sales_order_created',
    unknown TYPE string VALUE 'unkown',
    failed  TYPE string VALUE 'failed',
    in_process TYPE string VALUE 'in_process',
  END OF sales_order_state.
protected section.
private section.
ENDCLASS.



CLASS ZBP_R_GE293238_1 IMPLEMENTATION.
ENDCLASS.
