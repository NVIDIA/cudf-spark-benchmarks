
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band_sk
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ws.ws_bill_customer_sk
    FROM web_sales AS ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_bill_customer_sk
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory AS inv
    GROUP BY inv.inv_item_sk
),
joined_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        c.cd_purchase_estimate,
        c.income_band_sk,
        s.ws_item_sk,
        s.total_quantity,
        s.total_net_profit,
        inv.total_quantity_on_hand
    FROM customer_data AS c
    JOIN sales_data AS s ON c.c_customer_sk = s.ws_bill_customer_sk
    JOIN inventory_summary AS inv ON s.ws_item_sk = inv.inv_item_sk
)
SELECT 
    j.c_customer_sk,
    j.c_first_name,
    j.c_last_name,
    j.cd_gender,
    j.cd_marital_status,
    j.cd_education_status,
    j.cd_purchase_estimate,
    j.income_band_sk,
    SUM(j.total_quantity) AS total_units_sold,
    SUM(j.total_net_profit) AS total_profit,
    AVG(j.total_quantity_on_hand) AS avg_inventory
FROM joined_data AS j
GROUP BY 
    j.c_customer_sk,
    j.c_first_name,
    j.c_last_name,
    j.cd_gender,
    j.cd_marital_status,
    j.cd_education_status,
    j.cd_purchase_estimate,
    j.income_band_sk
ORDER BY total_profit DESC
LIMIT 100;
