
WITH customer_returns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax
    FROM store_returns
    GROUP BY sr_customer_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
),
warehouse_stock AS (
    SELECT 
        iv.inv_warehouse_sk,
        SUM(iv.inv_quantity_on_hand) AS total_stock
    FROM inventory iv
    GROUP BY iv.inv_warehouse_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ca.ca_city) AS city_rank
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
final_report AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.cd_gender,
        hvc.cd_marital_status,
        cr.total_returns,
        cr.total_return_amt_inc_tax,
        ws.total_stock
    FROM high_value_customers hvc
    LEFT JOIN customer_returns cr ON hvc.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN warehouse_stock ws ON ws.inv_warehouse_sk = (SELECT MIN(inv_warehouse_sk) FROM inventory)
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.cd_marital_status,
    COALESCE(f.total_returns, 0) AS total_returns,
    COALESCE(f.total_return_amt_inc_tax, 0) AS total_return_amt_inc_tax,
    f.total_stock,
    CASE 
        WHEN f.total_returns IS NULL THEN 'No Returns'
        WHEN f.total_returns > 5 THEN 'Frequent Returner'
        ELSE 'Occasional Returner'
    END AS return_behavior
FROM final_report f
WHERE f.total_stock > 100
ORDER BY f.total_return_amt_inc_tax DESC;
