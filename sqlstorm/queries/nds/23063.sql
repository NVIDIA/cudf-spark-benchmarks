
WITH  sales_summary AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(ws.ws_ext_sales_price), 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), enriched_sales AS (
    SELECT 
        ss.c_customer_sk,
        ss.total_sales,
        ss.order_count,
        ss.sales_rank,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        sales_summary ss
    LEFT JOIN customer_demographics cd ON ss.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    e.c_customer_sk,
    e.total_sales,
    e.order_count,
    e.sales_rank,
    COALESCE(e.cd_gender, 'UNKNOWN') AS gender,
    COALESCE(e.cd_marital_status, 'UNKNOWN') AS marital_status,
    COALESCE(e.hd_income_band_sk, -1) AS income_band,
    CASE 
        WHEN e.order_count = 0 THEN 'NO ORDERS'
        WHEN e.total_sales >= 1000 THEN 'HIGH SPENDER'
        WHEN e.total_sales >= 500 THEN 'MEDIUM SPENDER'
        ELSE 'LOW SPENDER'
    END AS spending_category,
    (SELECT COUNT(*)
     FROM store_sales ss
     WHERE ss.ss_customer_sk = e.c_customer_sk AND ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = DATE '2002-10-01' - INTERVAL '30 days')) AS returns_last_30_days
FROM 
    enriched_sales e
WHERE 
    e.total_sales IS NOT NULL 
ORDER BY 
    e.sales_rank
LIMIT 100;
