
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2400 AND 2500
    GROUP BY
        ws_item_sk
),
top_sales AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        r.total_quantity,
        r.total_sales
    FROM
        ranked_sales r
    JOIN
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE
        r.sales_rank <= 10
),
customer_stats AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_quantity) AS total_purchased_quantity,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        ws_sold_date_sk BETWEEN 2400 AND 2500
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
best_customers AS (
    SELECT
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_purchased_quantity,
        ROW_NUMBER() OVER (ORDER BY cs.total_purchased_quantity DESC) AS customer_rank
    FROM
        customer_stats cs
)
SELECT
    tc.i_item_id,
    tc.i_item_desc,
    tc.total_quantity,
    tc.total_sales,
    bc.c_customer_id,
    bc.c_first_name,
    bc.c_last_name,
    bc.total_purchased_quantity,
    bc.customer_rank
FROM
    top_sales tc
JOIN
    best_customers bc ON tc.total_quantity = bc.total_purchased_quantity
WHERE
    bc.customer_rank <= 5
ORDER BY
    tc.total_sales DESC, bc.total_purchased_quantity DESC;
