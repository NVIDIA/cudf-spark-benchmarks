
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
store_sales_data AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
combined_sales AS (
    SELECT 
        coalesce(ws.c_customer_id, ss.c_customer_id) AS customer_id,
        coalesce(total_web_sales, 0) AS total_web_sales,
        coalesce(total_store_sales, 0) AS total_store_sales,
        (coalesce(total_web_sales, 0) + coalesce(total_store_sales, 0)) AS grand_total_sales,
        (ws.order_count + coalesce(ss.store_order_count, 0)) AS total_orders
    FROM customer_sales ws
    FULL OUTER JOIN store_sales_data ss ON ws.c_customer_id = ss.c_customer_id
),
ranked_sales AS (
    SELECT 
        customer_id,
        total_web_sales,
        total_store_sales,
        grand_total_sales,
        total_orders,
        RANK() OVER (ORDER BY grand_total_sales DESC) AS sales_rank
    FROM combined_sales
)
SELECT 
    customer_id,
    total_web_sales,
    total_store_sales,
    grand_total_sales,
    total_orders,
    sales_rank
FROM ranked_sales
WHERE sales_rank <= 10
AND (total_web_sales > 1000 OR total_store_sales > 1000)
ORDER BY sales_rank;
