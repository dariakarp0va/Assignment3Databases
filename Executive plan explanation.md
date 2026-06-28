Executive plan explanation:

First of all joins on hashjoins, then the check of condition  (p.product_id = oi.product_id)

after that the system uses the seq scan on products and seq scan on order_items
filtering (order_id = 1)
 end of execution