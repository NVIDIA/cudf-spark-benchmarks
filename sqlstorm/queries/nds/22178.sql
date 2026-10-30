
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_paid,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_paid
    FROM web_sales
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_net_paid) > 1000
),
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ss.total_quantity,
        ss.total_paid
    FROM customer cs
    JOIN customer_demographics cd ON cs.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F' 
      AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
),
customer_addresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        COALESCE(SUBSTRING(ca.ca_zip FROM 1 FOR 5), 'ZIP NOT FOUND') AS zip_code
    FROM customer_address ca
    WHERE ca.ca_state IN ('CA', 'NY')
),
final_report AS (
    SELECT 
        tc.c_customer_id,
        tc.total_quantity,
        tc.total_paid,
        ca.ca_city,
        ca.zip_code,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY tc.total_paid DESC) as rn
    FROM top_customers tc
    LEFT JOIN customer_addresses ca ON tc.c_customer_id = ca.ca_address_id
)
SELECT 
    fr.c_customer_id,
    fr.total_quantity,
    fr.total_paid,
    fr.ca_city,
    fr.zip_code,
    NULLIF(fr.total_paid / NULLIF(fr.total_quantity, 0), 0) AS average_spent_per_item,
    CASE 
        WHEN fr.total_paid IS NOT NULL AND fr.total_quantity IS NOT NULL THEN 'Valid Sale'
        ELSE 'Invalid Sale'
    END AS sale_status
FROM final_report fr
WHERE fr.rn <= 10
ORDER BY fr.total_paid DESC;
