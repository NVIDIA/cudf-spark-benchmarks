
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_quantity, 
        ws.ws_sales_price, 
        COALESCE(ws.ws_ext_discount_amt, 0) AS discount, 
        (ws.ws_quantity * ws.ws_sales_price - COALESCE(ws.ws_ext_discount_amt, 0)) AS net_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) AS rn 
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN 20200101 AND 20201231
), 
top_selling_items AS (
    SELECT 
        sd.ws_item_sk, 
        SUM(sd.net_sales) AS total_net_sales
    FROM 
        sales_data AS sd
    WHERE 
        sd.rn = 1
    GROUP BY 
        sd.ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ib.ib_lower_bound, 
    ib.ib_upper_bound, 
    tsi.total_net_sales,
    CASE 
        WHEN tsi.total_net_sales IS NULL THEN 'No Sales' 
        ELSE 'Sold' 
    END AS sales_status
FROM 
    top_selling_items AS tsi
JOIN 
    customer_info AS ci ON ci.c_customer_sk IN (
        SELECT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_item_sk = tsi.ws_item_sk
    )
LEFT JOIN 
    income_band AS ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    ci.hd_buy_potential = 'High'
ORDER BY 
    tsi.total_net_sales DESC
LIMIT 50;
