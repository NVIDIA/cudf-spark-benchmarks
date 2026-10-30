
WITH sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_bill_customer_sk
),
demographic_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_purchase_estimate BETWEEN 0 AND 500 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 501 AND 2000 THEN 'Medium'
            WHEN cd.cd_purchase_estimate > 2000 THEN 'High'
            ELSE 'Unknown'
        END AS purchase_level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
final_report AS (
    SELECT 
        dd.c_customer_sk AS ws_bill_customer_sk,
        dd.cd_gender,
        dd.cd_marital_status,
        dd.cd_credit_rating,
        dd.purchase_level,
        sd.total_sales,
        sd.order_count,
        sd.last_purchase_date
    FROM demographic_data dd
    JOIN sales_data sd ON dd.c_customer_sk = sd.ws_bill_customer_sk
    WHERE sd.total_sales > (
        SELECT AVG(total_sales) FROM sales_data
    )
)
SELECT 
    fr.*,
    ROW_NUMBER() OVER (PARTITION BY fr.purchase_level ORDER BY fr.total_sales DESC) AS rank_by_sales,
    CASE 
        WHEN fr.last_purchase_date IS NULL THEN 'No Purchases'
        ELSE 'Recent Purchases'
    END AS purchase_status
FROM final_report fr
LEFT JOIN customer_address ca ON fr.ws_bill_customer_sk = ca.ca_address_sk
WHERE ca.ca_state IN ('CA', 'TX') 
ORDER BY fr.total_sales DESC, fr.purchase_level ASC;
