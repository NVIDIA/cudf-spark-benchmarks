
WITH RankedReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(*) AS return_count,
        SUM(cr_return_amount) AS total_return_amount,
        RANK() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_amount) DESC) AS rank_return
    FROM 
        catalog_returns
    WHERE 
        cr_return_quantity > 0 
    GROUP BY 
        cr_returning_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS marital_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    COALESCE(rr.return_count, 0) AS return_count,
    COALESCE(rr.total_return_amount, 0.00) AS total_return,
    ci.gender,
    ci.cd_marital_status,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    (SUM(ws.ws_net_paid) - COALESCE(rr.total_return_amount, 0)) AS net_spent,
    CASE 
        WHEN SUM(ws.ws_net_paid) IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    CONCAT(ci.c_first_name, ' ', ci.c_last_name) AS full_name
FROM 
    CustomerInfo ci
LEFT JOIN 
    RankedReturns rr ON ci.c_customer_sk = rr.cr_returning_customer_sk
LEFT JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    (ci.cd_marital_status IN ('S', 'M') AND rr.total_return_amount > 100) 
    OR (ci.gender = 'F' AND ci.marital_rank = 1)
GROUP BY 
    ci.c_first_name, ci.c_last_name, rr.return_count, rr.total_return_amount, 
    ci.gender, ci.cd_marital_status
HAVING 
    SUM(ws.ws_net_paid) IS NOT NULL
ORDER BY 
    net_spent DESC
LIMIT 10;
