
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c_customer_sk,
        c_first_name || ' ' || c_last_name AS full_name,
        CASE 
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Male'
        END AS gender,
        COALESCE(hd_income_band_sk, 0) AS income_band
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_with_customers AS (
    SELECT 
        cs.ws_item_sk,
        cs.total_quantity,
        cs.total_sales,
        c.full_name,
        c.gender,
        c.income_band
    FROM 
        sales_summary AS cs
    JOIN 
        web_sales AS ws ON cs.ws_item_sk = ws.ws_item_sk
    JOIN 
        customer_info AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY income_band ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_with_customers
)
SELECT 
    ss.ws_item_sk,
    ss.total_quantity,
    ss.total_sales,
    ss.full_name,
    ss.gender,
    ss.income_band
FROM 
    ranked_sales AS ss
WHERE 
    (ss.income_band > 0 AND ss.total_sales > 1000)
    OR (ss.gender = 'Female' AND ss.sales_rank <= 10)
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
