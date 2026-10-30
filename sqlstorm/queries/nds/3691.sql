
WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM
        customer_sales cs
),
most_purchased_items AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity
    FROM
        web_sales ws
    GROUP BY
        ws.ws_item_sk
    HAVING
        SUM(ws.ws_quantity) > 100
),
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price
    FROM
        item i
    WHERE
        i.i_rec_start_date <= DATE('2002-10-01') AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > DATE('2002-10-01'))
),
sales_data AS (
    SELECT
        t1.c_first_name,
        t1.c_last_name,
        t2.i_item_desc,
        t2.i_current_price,
        COALESCE(t3.total_quantity, 0) AS total_quantity
    FROM
        top_customers t1
    LEFT JOIN
        web_sales ws ON t1.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        item_details t2 ON ws.ws_item_sk = t2.i_item_sk
    LEFT JOIN
        most_purchased_items t3 ON t2.i_item_sk = t3.ws_item_sk
)
SELECT
    s.c_first_name AS first_name,
    s.c_last_name AS last_name,
    s.i_item_desc AS item_desc,
    s.i_current_price AS current_price,
    s.total_quantity,
    CASE 
        WHEN s.total_quantity = 0 THEN 'No Purchases' 
        ELSE 'Purchased' 
    END AS purchase_status
FROM
    sales_data s
JOIN
    top_customers tc ON s.c_first_name = tc.c_first_name AND s.c_last_name = tc.c_last_name
WHERE
    tc.rank <= 10
ORDER BY
    s.total_quantity DESC,
    s.i_current_price ASC;
