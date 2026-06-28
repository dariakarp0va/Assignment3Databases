Create FUNCTION calculate_order_total(p_order_id int)
RETURNS Numeric
LANGUAGE sql
AS $$
select COALESCE(
    (SELECT Sum (quantity * price)  FROM order_items WHERE order_id = p_order_id),
        0
);

$$;

CREATE OR REPLACE PROCEDURE create_order(p_customer_id int)
LANGUAGE plpgsql
AS $$
BEGIN
    IF exists (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
    INSERT INTO orders ( customer_id, order_date, total_amount)
    VALUES (
        p_customer_id,
        CURRENT_TIMESTAMP,
        0
        );
    COMMIT;
    else raise EXCEPTION 'there is no customer under this id';
    end if;
END;
$$;

CREATE OR REPLACE PROCEDURE add_product_to_order(
    p_order_id int,
    p_product_id int,
    p_quantity int
)
LANGUAGE plpgsql
AS $$
BEGIN
    if p_quantity > 0 and (select stock_quantity from products where product_id = p_product_id) > p_quantity then
    INSERT INTO order_items ( order_id, product_id, quantity , price)
    VALUES (
            p_order_id,
            p_product_id,
            p_quantity,
            (select price from products where products.product_id = p_product_id));

    update  products
        set stock_quantity = stock_quantity - p_quantity where product_id = p_product_id;
    COMMIT;
    else raise EXCEPTION 'There is not enough products in stock';
    end if;
END;
$$;

CREATE OR REPLACE FUNCTION recalculate_total()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    if tg_op = 'DELETE' then
        Update orders
        set total_amount = calculate_order_total(old.order_id) where order_id = old.order_id;

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

call create_order(11);
call create_order(7);
call create_order(17);

call add_product_to_order(10, 5, 100);


