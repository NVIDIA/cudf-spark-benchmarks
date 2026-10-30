
WITH RecursiveCustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid) AS total_spent,
        COUNT(ss_ticket_number) AS total_purchases
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(cr.total_returned_quantity, 0) AS total_returns,
    COALESCE(sd.total_spent, 0) AS total_spent,
    CASE 
        WHEN COALESCE(sd.total_spent, 0) = 0 THEN 'No Purchases'
        WHEN COALESCE(cr.total_returned_quantity, 0) = 0 THEN 'No Returns'
        WHEN COALESCE(sd.total_spent, 0) > 1000 THEN 'High Value'
        ELSE 'Regular'
    END AS customer_type
FROM 
    RecursiveCustomerInfo ci
LEFT JOIN 
    CustomerReturns cr ON ci.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ss_customer_sk
WHERE 
    ci.rnk = 1 
    AND (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
    AND ci.c_customer_id NOT IN (
        SELECT 
            c2.c_customer_id
        FROM 
            customer c2
        WHERE 
            c2.c_birth_month BETWEEN 1 AND 6
    )
ORDER BY 
    total_spent DESC NULLS LAST
LIMIT 100;
