
WITH  SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        SUM(ss.ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS rank
    FROM 
        customer c
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, hd.hd_income_band_sk, hd.hd_buy_potential
),
FilteredSales AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.hd_income_band_sk,
        sh.hd_buy_potential,
        sh.total_sales
    FROM 
        SalesHierarchy sh
    WHERE 
        sh.rank <= 5 AND 
        sh.total_sales > (SELECT AVG(total_sales) FROM SalesHierarchy)
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.hd_income_band_sk,
    f.hd_buy_potential,
    f.total_sales,
    (SELECT COUNT(DISTINCT ws.ws_order_number) 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = f.c_customer_sk) AS web_sales_count,
    COALESCE((SELECT AVG(ws.ws_net_profit)
              FROM web_sales ws
              WHERE ws.ws_bill_customer_sk = f.c_customer_sk), 0) AS average_web_net_profit
FROM 
    FilteredSales f
ORDER BY 
    f.total_sales DESC
LIMIT 10;
