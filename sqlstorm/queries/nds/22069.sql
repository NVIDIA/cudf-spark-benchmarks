
WITH  sales_with_dates AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) as rn
    FROM web_sales
    WHERE ws_net_profit IS NOT NULL
),
total_sales AS (
    SELECT 
        swd.ws_item_sk,
        SUM(swd.ws_quantity) AS total_quantity,
        SUM(swd.ws_sales_price) AS total_sales_price,
        AVG(swd.ws_net_profit) AS avg_net_profit
    FROM sales_with_dates swd
    GROUP BY swd.ws_item_sk
),
detailed_sales AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        COALESCE(ROUND(ts.total_sales_price, 2), 0) AS total_sales_price,
        COALESCE(ts.total_quantity, 0) AS total_quantity,
        COALESCE(ts.avg_net_profit, 0) AS avg_profit,
        COUNT(DISTINCT we.wp_web_page_id) AS page_count
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN total_sales ts ON ts.ws_item_sk = c.c_customer_sk
    LEFT JOIN web_page we ON we.wp_customer_sk = c.c_customer_sk
    WHERE (ca.ca_city IS NOT NULL OR c.c_first_name IS NOT NULL)
    AND (c.c_birth_day IS NOT NULL OR c.c_birth_month IS NOT NULL)
    GROUP BY c.c_customer_id, ca.ca_city, ts.total_sales_price, ts.total_quantity, ts.avg_net_profit
),
final_output AS (
    SELECT 
        ds.c_customer_id,
        ds.ca_city,
        ds.total_sales_price,
        ds.total_quantity,
        ds.avg_profit,
        ds.page_count,
        CASE
            WHEN ds.total_sales_price > 10000 THEN 'High Value'
            WHEN ds.total_sales_price BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        CASE 
            WHEN ds.ca_city IS NULL THEN 'City Not Available'
            ELSE ds.ca_city
        END AS adjusted_city
    FROM detailed_sales ds
)
SELECT 
    fo.c_customer_id,
    fo.adjusted_city,
    fo.total_sales_price,
    fo.total_quantity,
    fo.avg_profit,
    fo.page_count,
    fo.customer_value,
    ROW_NUMBER() OVER (ORDER BY fo.total_sales_price DESC) AS sales_rank
FROM final_output fo
WHERE fo.page_count > 0
ORDER BY fo.total_sales_price DESC
LIMIT 100;
