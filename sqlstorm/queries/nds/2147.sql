
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd
    ON 
        c.c_current_cdemo_sk = cd.cd_demo_sk
),
TotalReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns AS sr
    GROUP BY 
        sr.sr_customer_sk
),
BestStore AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_sales
    FROM 
        store_sales AS ss
    GROUP BY 
        ss.ss_store_sk
    ORDER BY 
        total_sales DESC
    LIMIT 1
),
FinalReport AS (
    SELECT 
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        COALESCE(tr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(tr.total_return_amt, 0) AS total_return_amt,
        bs.total_sales AS best_store_sales,
        rc.rnk
    FROM 
        RankedCustomers AS rc
    LEFT JOIN 
        TotalReturns AS tr
    ON 
        rc.c_customer_sk = tr.sr_customer_sk
    CROSS JOIN 
        BestStore AS bs
)
SELECT 
    *,
    CASE 
        WHEN total_return_amt > 100 THEN 'High Return Value'
        WHEN total_return_quantity > 10 THEN 'Frequent Returns'
        ELSE 'Normal Customer'
    END AS customer_status
FROM 
    FinalReport
WHERE 
    rnk = 1
ORDER BY 
    total_return_amt DESC, 
    best_store_sales DESC;
