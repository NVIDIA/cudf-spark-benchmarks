
WITH  sales_data AS (
    SELECT 
        ss.ss_item_sk, 
        SUM(ss.ss_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ss.ss_item_sk ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY ss.ss_item_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city AS city,
        COALESCE(ca.ca_state, 'UNKNOWN') AS state,
        ca.ca_zip AS zip,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT OUTER JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_city, ca.ca_state, ca.ca_zip
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS daily_sales
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
    HAVING SUM(ws.ws_ext_sales_price) IS NOT NULL
)
SELECT 
    ai.full_address, 
    ai.city,
    ai.state,
    ai.zip,
    COALESCE(sd.total_sales, 0) AS total_sales,
    ds.daily_sales,
    CASE 
        WHEN ai.customer_count > 0 THEN 'ACTIVE'
        ELSE 'INACTIVE'
    END AS customer_status
FROM address_info ai
FULL OUTER JOIN sales_data sd ON ai.ca_address_sk = sd.ss_item_sk
FULL OUTER JOIN daily_sales ds ON ds.d_date = DATE '2002-10-01'
WHERE (COALESCE(sd.total_sales, 0) > 1000 OR ds.daily_sales > 5000)
AND (ai.customer_count IS NULL OR ai.customer_count > 5)
ORDER BY total_sales DESC, ai.full_address
LIMIT 10;
