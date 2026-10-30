
WITH  categorized_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2459487 AND 2459497 
    GROUP BY
        ws_item_sk
),
top_selling_items AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        cs.total_sales,
        cs.total_orders
    FROM
        categorized_sales cs
    JOIN
        item i ON cs.ws_item_sk = i.i_item_sk
    WHERE
        cs.sales_rank <= 10
),
customer_statistics AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT
    ts.i_item_id,
    ts.i_item_desc,
    ts.total_sales,
    ts.total_orders,
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_spent,
    cs.orders_count
FROM
    top_selling_items ts
LEFT JOIN
    customer_statistics cs ON ts.total_sales > cs.total_spent
WHERE
    ts.total_orders > 0
ORDER BY
    ts.total_sales DESC, cs.total_spent DESC
LIMIT 100;
