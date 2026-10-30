WITH sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2458770 AND 2458777  
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
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk 
),
top_items AS (
    SELECT 
        si.ws_item_sk,
        SUM(si.total_sales) AS total_sales
    FROM 
        sales_data si
    GROUP BY 
        si.ws_item_sk
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ti.ws_item_sk,
    sd.total_quantity,
    sd.total_sales,
    sd.total_profit,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    customer_info ci
JOIN 
    sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
JOIN 
    top_items ti ON sd.ws_item_sk = ti.ws_item_sk
LEFT JOIN 
    income_band ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    total_profit DESC;