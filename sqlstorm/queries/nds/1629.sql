
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 100
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
), 
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.hd_income_band_sk,
        ci.total_catalog_sales,
        COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS total_web_sales
    FROM 
        customer_info ci
    LEFT JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.hd_income_band_sk, ci.total_catalog_sales
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    tc.total_catalog_sales,
    tc.total_web_sales,
    (tc.total_catalog_sales + tc.total_web_sales) AS total_sales,
    MAX(rs.ws_sales_price) AS max_web_sale_price
FROM 
    top_customers tc
LEFT JOIN 
    income_band ib ON tc.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN 
    ranked_sales rs ON tc.c_customer_sk = rs.ws_order_number
WHERE 
    (tc.total_web_sales > 0 OR tc.total_catalog_sales > 0)
    AND (tc.cd_gender IS NOT NULL)
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound, tc.total_catalog_sales, tc.total_web_sales
ORDER BY 
    total_sales DESC
LIMIT 50;
