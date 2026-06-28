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
        set stock_quantity =- p_quantity where product_id = p_product_id;
    COMMIT;
    end if;
END;
$$;