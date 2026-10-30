
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_sales_price) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sales_price) AS highest_sale_price
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023 AND d.d_month_seq IN (11, 12)
    )
    GROUP BY ws.ws_item_sk
),
warehouse_inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    sd.total_sales,
    sd.total_revenue,
    sd.order_count,
    sd.highest_sale_price,
    wi.total_inventory,
    CASE 
        WHEN ci.cd_marital_status = 'S' THEN 'Single' 
        ELSE 'Married' 
    END AS marital_status,
    CASE 
        WHEN ci.cd_credit_rating = 'Excellent' THEN 'High Value' 
        WHEN ci.cd_credit_rating = 'Good' THEN 'Moderate Value'
        ELSE 'Low Value' 
    END AS customer_value
FROM customer_info ci
JOIN sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
JOIN warehouse_inventory wi ON sd.ws_item_sk = wi.inv_item_sk
WHERE wi.total_inventory > 0
  AND (ci.income_band_sk BETWEEN 1 AND 5 OR ci.income_band_sk IS NULL)
ORDER BY total_revenue DESC
LIMIT 100;
