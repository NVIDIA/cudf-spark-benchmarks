
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ws.ws_ext_sales_price) IS NOT NULL
), customer_state AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        SUM(sh.total_sales) AS total_sales_by_state
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN sales_hierarchy sh ON c.c_customer_sk = sh.c_customer_sk
    GROUP BY ca.ca_state
), monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS month_sales
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT 
    cs.ca_state,
    cs.num_customers,
    cs.total_sales_by_state,
    COALESCE(ms.month_sales, 0) AS total_monthly_sales,
    CASE 
        WHEN cs.total_sales_by_state > 100000 THEN 'High Value'
        WHEN cs.total_sales_by_state > 50000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS sales_category
FROM customer_state cs
LEFT JOIN monthly_sales ms ON cs.total_sales_by_state = ms.month_sales
ORDER BY cs.total_sales_by_state DESC
LIMIT 10;
