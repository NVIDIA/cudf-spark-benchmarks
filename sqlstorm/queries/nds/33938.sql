
WITH  sales_hierarchy AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_order_number, 
        ws_web_site_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT CASE WHEN ws.ws_sales_price > 100 THEN ws.ws_order_number END) AS high_value_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
avg_income AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(CASE 
            WHEN hd.hd_income_band_sk IS NOT NULL THEN ib.ib_upper_bound
            ELSE 0 END) AS avg_income
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk 
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    ch.c_customer_sk,
    ch.total_sales,
    ch.order_count,
    ch.high_value_orders,
    ai.avg_income,
    CASE 
        WHEN ch.total_sales > ai.avg_income THEN 'Above Average'
        ELSE 'Below Average' 
    END AS income_status
FROM 
    customer_purchases ch
INNER JOIN 
    avg_income ai ON ch.c_customer_sk = ai.cd_demo_sk
WHERE 
    ch.total_sales IS NOT NULL
ORDER BY 
    ch.total_sales DESC
LIMIT 100;
