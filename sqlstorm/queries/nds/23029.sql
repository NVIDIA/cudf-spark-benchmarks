
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        RANK() OVER (ORDER BY COALESCE(cd.cd_purchase_estimate, 0) DESC) AS rank_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
),
ComplexJoin AS (
    SELECT
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        SUM(rs.total_returns) AS total_returns_count,
        SUM(rs.total_return_amt) AS total_return_amount
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        RankedReturns rs ON hvc.c_customer_sk = rs.sr_customer_sk
    WHERE 
        hvc.rank_estimate <= 10
    GROUP BY 
        hvc.c_customer_sk, hvc.c_first_name, hvc.c_last_name
)
SELECT 
    cj.c_customer_sk,
    cj.c_first_name,
    cj.c_last_name,
    COALESCE(cj.total_returns_count, 0) AS returns_count,
    COALESCE(cj.total_return_amount, 0) AS return_amount,
    (CASE WHEN cj.total_return_amount IS NULL OR cj.total_return_amount = 0 
          THEN 'No Returns' 
          ELSE 'Has Returns' 
     END) AS return_status
FROM 
    ComplexJoin cj
FULL OUTER JOIN 
    web_sales ws ON cj.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    COALESCE(ws.ws_sales_price, 0) > 100
    AND (cj.total_returns_count IS NULL OR cj.total_returns_count < 5)
ORDER BY 
    returns_count DESC, return_amount DESC
LIMIT 50;

