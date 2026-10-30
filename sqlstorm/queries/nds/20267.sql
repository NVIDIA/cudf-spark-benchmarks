
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
returns_data AS (
    SELECT 
        sr.sr_item_sk, 
        COUNT(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    COALESCE(sd.total_quantity, 0) AS total_quantity_sold,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    COALESCE(id.total_stock, 0) AS total_stock,
    CASE 
        WHEN COALESCE(rd.total_return_amount, 0) > (COALESCE(sd.total_net_paid, 0) * 0.1)
            THEN 'High Return'
        WHEN COALESCE(sd.total_net_paid, 0) > 1000 AND cd.cd_marital_status = 'M'
            THEN 'High Value - Married'
        ELSE 'Regular'
    END AS customer_classification
FROM customer_data cd
LEFT JOIN sales_data sd ON cd.c_customer_sk = sd.ws_item_sk
LEFT JOIN returns_data rd ON sd.ws_item_sk = rd.sr_item_sk
LEFT JOIN inventory_data id ON sd.ws_item_sk = id.inv_item_sk
WHERE (cd.cd_purchase_estimate > 500 OR cd.cd_gender = 'F')
  AND (cd.income_band <> -1 OR cd.income_band IS NULL)
ORDER BY
    customer_classification DESC,
    cd.c_last_name,
    cd.c_first_name;
