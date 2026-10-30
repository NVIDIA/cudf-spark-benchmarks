
WITH  sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales, 
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COALESCE(ib.ib_lower_bound, 0) AS income_lower_bound,
        COALESCE(ib.ib_upper_bound, 0) AS income_upper_bound
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    ci.c_customer_sk, 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.income_lower_bound, 
    ci.income_upper_bound, 
    ss.total_quantity, 
    ss.total_sales
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
WHERE 
    ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
    AND ci.cd_gender = 'M'
ORDER BY 
    ss.total_sales DESC
LIMIT 
    10;
