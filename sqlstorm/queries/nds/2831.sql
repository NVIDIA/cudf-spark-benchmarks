
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rank,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band_sk
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
),
store_sales_summary AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales 
    GROUP BY 
        ss_item_sk
),
web_sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
all_sales_summary AS (
    SELECT 
        ss_item_sk AS cs_item_sk, 
        total_quantity, 
        total_profit 
    FROM 
        store_sales_summary
    UNION ALL
    SELECT 
        ws_item_sk AS cs_item_sk, 
        total_quantity, 
        total_profit 
    FROM 
        web_sales_summary
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM 
        item i
    WHERE 
        i.i_current_price IS NOT NULL
)
SELECT 
    cs.c_customer_sk, 
    cs.c_first_name, 
    cs.c_last_name,
    ads.i_item_desc,
    COALESCE(sales.total_quantity, 0) AS total_sales_quantity,
    COALESCE(sales.total_profit, 0) AS total_sales_profit,
    CASE 
        WHEN cs.rank <= 5 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status,
    cs.income_band_sk
FROM 
    customer_stats cs
LEFT JOIN 
    all_sales_summary sales ON cs.c_customer_sk = sales.cs_item_sk
LEFT JOIN 
    item_details ads ON sales.cs_item_sk = ads.i_item_sk
WHERE 
    (cs.cd_gender = 'F' OR cs.cd_gender IS NULL) 
    AND COALESCE(sales.total_profit, 0) > 1000
ORDER BY 
    cs.c_last_name, cs.c_first_name DESC;
