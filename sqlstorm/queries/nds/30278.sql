WITH  return_summary AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rn
    FROM store_returns
    GROUP BY sr_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROUND(COALESCE(cd.cd_purchase_estimate, 0) / 1000, 2) AS avg_purchase,
        CASE
            WHEN cd.cd_purchase_estimate IS NULL OR cd.cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
dates AS (
    SELECT
        d.d_date,
        d.d_month_seq,
        d.d_year
    FROM date_dim d
    WHERE d.d_date BETWEEN '2000-01-01' AND '2000-12-31'
),
inventory_summary AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)

SELECT
    r.total_returned,
    r.total_return_value,
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.avg_purchase,
    ci.purchase_category,
    i.total_inventory
FROM return_summary r
JOIN customer_info ci ON r.sr_item_sk = ci.c_customer_sk
LEFT JOIN inventory_summary i ON r.sr_item_sk = i.inv_item_sk
JOIN dates d ON d.d_month_seq = (r.total_returned % 12) + 1  
WHERE r.total_returned IS NOT NULL
  AND r.total_return_value > 1000
  AND ci.cd_gender = 'F'
ORDER BY r.total_return_value DESC, ci.avg_purchase ASC
LIMIT 10;