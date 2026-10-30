WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        RANK() OVER (ORDER BY CD.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    r.total_return_quantity,
    r.total_return_amt
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedReturns r ON cd.c_customer_sk = r.sr_customer_sk
WHERE 
    cd.purchase_rank <= 10
    AND (r.total_return_quantity IS NULL OR r.total_return_quantity > 5)
ORDER BY 
    cd.c_first_name, cd.c_last_name;