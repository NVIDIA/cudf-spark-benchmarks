
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy IN (6, 7))
    GROUP BY 
        ws_bill_customer_sk
),
demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        ib_income_band_sk
    FROM 
        customer_demographics
    JOIN 
        household_demographics ON hd_demo_sk = cd_demo_sk
    LEFT JOIN 
        income_band ON ib_income_band_sk = hd_income_band_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.ib_income_band_sk,
        s.total_sales,
        s.total_profit,
        s.order_count
    FROM 
        customer c
    JOIN 
        sales_summary s ON c.c_customer_sk = s.ws_bill_customer_sk
    JOIN 
        demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.ib_income_band_sk,
    cs.total_sales,
    cs.total_profit,
    CASE 
        WHEN cs.total_sales > 1000 THEN 'High'
        WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    customer_sales cs
ORDER BY 
    cs.total_profit DESC
LIMIT 100;
