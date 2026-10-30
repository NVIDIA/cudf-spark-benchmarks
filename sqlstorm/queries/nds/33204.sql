
WITH  sales_summary AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT
        item.i_item_sk,
        item.i_item_id,
        item.i_product_name,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        ROUND(COALESCE(s.total_sales, 0), 2) AS total_sales
    FROM
        item
    LEFT JOIN (
        SELECT
            ws_item_sk,
            SUM(total_quantity) AS total_quantity,
            SUM(total_sales) AS total_sales
        FROM
            sales_summary
        WHERE
            sales_rank <= 5
        GROUP BY
            ws_item_sk
    ) s ON item.i_item_sk = s.ws_item_sk
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT
    c.c_first_name,
    c.c_last_name,
    ti.i_product_name,
    ti.total_quantity,
    ti.total_sales,
    cs.total_orders,
    cs.total_spent,
    (CASE 
         WHEN cs.total_spent IS NULL THEN 'No Orders' 
         WHEN cs.total_spent < 100 THEN 'Low Spender' 
         WHEN cs.total_spent BETWEEN 100 AND 500 THEN 'Medium Spender' 
         ELSE 'High Spender' 
     END) AS customer_category
FROM
    top_items ti
JOIN customer_stats cs ON cs.total_orders > 0
JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE
    ti.total_sales > 0
ORDER BY
    ti.total_sales DESC, cs.total_spent DESC
LIMIT 10;
