
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales
    FROM catalog_sales
    GROUP BY cs_sold_date_sk, cs_item_sk
),
customer_returns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
complex_calculation AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ss.total_quantity, 0) AS total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        (COALESCE(ss.total_sales, 0) - COALESCE(cr.total_return_amount, 0)) AS net_sales
    FROM customer c
    LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.ws_item_sk
    LEFT JOIN customer_returns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE (c.c_birth_year IS NOT NULL AND EXTRACT(YEAR FROM DATE '2002-10-01') - c.c_birth_year > 18)
      AND (COALESCE(ss.total_sales, 0) - COALESCE(cr.total_return_amount, 0) > 0 OR cr.total_returns IS NOT NULL)
)
SELECT 
    s.s_store_id,
    s.s_store_name,
    SUM(cc.net_sales) AS store_net_sales,
    COUNT(DISTINCT cc.c_customer_sk) AS unique_customers,
    AVG(cc.total_sales) AS avg_sales_per_customer
FROM store s
JOIN complex_calculation cc ON s.s_store_sk = cc.c_customer_sk
WHERE s.s_country = 'USA'
GROUP BY s.s_store_id, s.s_store_name
HAVING SUM(cc.net_sales) > 1000
ORDER BY store_net_sales DESC
LIMIT 10;
