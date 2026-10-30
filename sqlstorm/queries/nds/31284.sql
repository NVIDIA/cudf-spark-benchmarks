
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(ss.total_quantity) AS total_quantity,
    SUM(ss.total_sales) AS total_sales,
    AVG(ss.total_discount) AS average_discount
FROM 
    customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
LEFT JOIN income_band ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    ci.cd_gender = 'F' 
    AND ci.cd_marital_status = 'M' 
    AND ss.total_sales IS NOT NULL
GROUP BY 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING 
    SUM(ss.total_sales) > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY 
    total_sales DESC;
