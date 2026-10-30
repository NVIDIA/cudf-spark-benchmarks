
WITH  sales_data AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        COALESCE(hd.hd_income_band_sk, ib.ib_income_band_sk) AS income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
ship_modes AS (
    SELECT 
        sm.sm_ship_mode_sk,
        sm.sm_type,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_sk, sm.sm_type
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    sd.ws_sold_date_sk, 
    sd.total_quantity, 
    sd.total_profit,
    sm.total_orders,
    CASE 
        WHEN sd.rank <= 5 THEN 'Top Seller'
        ELSE 'Other Seller'
    END AS seller_category
FROM 
    sales_data sd
JOIN 
    customer_info ci ON sd.ws_item_sk = ci.c_customer_sk
JOIN 
    ship_modes sm ON sm.sm_ship_mode_sk = (SELECT MIN(sm_ship_mode_sk) FROM ship_mode)
WHERE 
    sd.total_profit > (
        SELECT AVG(total_profit) FROM sales_data
    )
ORDER BY 
    sd.total_profit DESC
LIMIT 100;
