
WITH RankedReturns AS (
    SELECT 
        cr_returning_customer_sk,
        cr_item_sk,
        COUNT(*) AS total_returns,
        SUM(cr_return_amount) AS total_refunded,
        ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_amount) DESC) AS rn
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk, cr_item_sk
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_purchase_estimate IS NOT NULL
    AND 
        cd_purchase_estimate > (
            SELECT AVG(cd_purchase_estimate)
            FROM customer_demographics
        )
),
SalesSummary AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_net_paid) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    d.d_date AS sale_date,
    ss.total_sales,
    ss.total_quantity,
    hc.full_name AS high_value_customer,
    rr.total_returns,
    rr.total_refunded
FROM 
    date_dim d
LEFT JOIN 
    SalesSummary ss ON d.d_date_sk = ss.ws_ship_date_sk
LEFT JOIN 
    HighValueCustomers hc ON hc.gender_rank = 1
LEFT JOIN 
    RankedReturns rr ON rr.cr_returning_customer_sk = hc.c_customer_sk 
WHERE 
    d.d_year = 2023
ORDER BY 
    sale_date DESC, ss.total_sales DESC
LIMIT 100;
