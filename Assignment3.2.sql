CREATE OR REPLACE FUNCTION recalculate_total()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    if tg_op = 'DELETE' then
        Update orders
        set total_amount = calculate_order_total(new.order_id) where order_id = old.order_id;

    RETURN old;
    else
    Update orders
        set total_amount = calculate_order_total(new.order_id) where order_id = new.order_id;
    RETURN NEW;
    end if;
END;
$$;

CREATE TRIGGER recalculate
AFTER  INSERT or UPDATE  or DELETE
ON order_items
FOR EACH ROW
EXECUTE FUNCTION recalculate_total();


CREATE OR REPLACE FUNCTION writing_new_log()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    insert into order_log (order_id, customer_id, action, log_date)
    VALUES (new.order_id, new.customer_id, 'ORDER_CREATED', new.order_date);
    RETURN NEW;

END;
$$;

CREATE TRIGGER new_order
AFTER  INSERT
ON orders
FOR EACH ROW
EXECUTE FUNCTION writing_new_log();
