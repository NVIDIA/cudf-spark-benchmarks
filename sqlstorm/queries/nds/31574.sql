
WITH  sales_trends AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk) AS rn
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
), 
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), 
income_analysis AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales
    FROM 
        household_demographics h
    LEFT JOIN 
        catalog_sales cs ON h.hd_demo_sk = cs.cs_bill_cdemo_sk
    LEFT JOIN 
        web_sales ws ON h.hd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY 
        h.hd_income_band_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_profit,
    cs.total_orders,
    EXISTS (
        SELECT 1 
        FROM sales_trends st 
        WHERE st.ws_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_brand = 'Brand A')
    ) AS has_brand_a_sales,
    ia.total_catalog_sales,
    ia.total_web_sales,
    CASE 
        WHEN cs.total_profit > 1000 THEN 'High Value'
        WHEN cs.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    customer_stats cs
LEFT JOIN 
    income_analysis ia ON cs.c_customer_sk = ia.hd_income_band_sk
WHERE 
    cs.total_orders > 0
ORDER BY 
    cs.total_profit DESC
LIMIT 100;
