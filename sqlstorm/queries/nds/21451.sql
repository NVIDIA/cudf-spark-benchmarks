
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity > 0
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependent_count,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Female'
        END AS gender_description
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TotalSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnsAnalysis AS (
    SELECT 
        cd.c_customer_sk,
        SUM(rr.sr_return_quantity) AS total_returns,
        COUNT(rr.sr_item_sk) AS return_count,
        cd.gender_description,
        cs.total_spent,
        cs.total_orders
    FROM RankedReturns rr
    JOIN CustomerDetails cd ON rr.sr_customer_sk = cd.c_customer_sk
    LEFT JOIN TotalSales cs ON cd.c_customer_sk = cs.ws_bill_customer_sk
    GROUP BY cd.c_customer_sk, cd.gender_description, cs.total_spent, cs.total_orders
)
SELECT 
    ra.c_customer_sk,
    ra.total_returns,
    ra.return_count,
    ra.gender_description,
    ra.total_spent,
    ra.total_orders,
    CASE 
        WHEN ra.total_spent IS NULL OR ra.total_orders = 0 THEN 'No Purchases'
        WHEN ra.total_returns > 5 THEN 'Frequent Returner'
        ELSE 'Regular'
    END AS customer_return_category
FROM ReturnsAnalysis ra
WHERE ra.total_spent IS NOT NULL
OR (ra.total_orders IS NULL AND ra.return_count > 0)
ORDER BY ra.total_returns DESC, ra.return_count DESC;
