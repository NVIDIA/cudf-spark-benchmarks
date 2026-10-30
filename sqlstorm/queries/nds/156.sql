
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk, 
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
CustomerHistories AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        SUM(cs.cs_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(cs.cs_net_paid) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate
)
SELECT 
    ch.c_customer_sk,
    ch.cd_gender,
    ch.cd_marital_status,
    ch.order_count,
    ch.total_spent,
    COALESCE(cr.total_return_amount, 0) AS total_return,
    cr.return_count,
    CASE
        WHEN cr.return_count IS NULL THEN 'No Returns'
        WHEN cr.return_count > 3 THEN 'High Returner'
        ELSE 'Regular Returner'
    END AS return_status
FROM 
    CustomerHistories ch
LEFT JOIN 
    CustomerReturns cr ON ch.c_customer_sk = cr.cr_returning_customer_sk
WHERE 
    ch.total_spent > (
        SELECT 
            AVG(total_spent)
        FROM 
            CustomerHistories
        WHERE 
            spending_rank <= 1000
    )
ORDER BY 
    ch.total_spent DESC;
