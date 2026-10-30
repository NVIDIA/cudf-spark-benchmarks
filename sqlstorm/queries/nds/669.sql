
WITH sales_summary AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ws.ws_sold_date_sk BETWEEN 10000 AND 10500
      AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
      AND (ca.ca_state = 'CA' OR ca.ca_state IS NULL)
    GROUP BY c.c_customer_id
),
top_customers AS (
    SELECT 
        s.c_customer_id,
        s.total_quantity,
        s.total_sales,
        s.total_orders,
        s.unique_web_pages,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM sales_summary s
)
SELECT 
    tc.c_customer_id,
    tc.total_quantity,
    tc.total_sales,
    tc.total_orders,
    tc.unique_web_pages,
    COALESCE(NULLIF(tc.total_sales, 0), 1) / NULLIF(tc.total_orders, 0) AS avg_sales_per_order,
    CASE 
        WHEN tc.total_orders < 10 THEN 'Low'
        WHEN tc.total_orders < 50 THEN 'Medium'
        ELSE 'High'
    END AS order_volume_category
FROM top_customers tc
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC;
