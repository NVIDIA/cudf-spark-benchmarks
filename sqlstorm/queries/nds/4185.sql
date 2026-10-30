
WITH RankedReturns AS (
    SELECT 
        cr_returning_customer_sk,
        cr_refunded_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amt_inc_tax) AS total_return_amt,
        DENSE_RANK() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_amt_inc_tax) DESC) AS rank
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk, cr_refunded_customer_sk
),
HighRefundCustomers AS (
    SELECT 
        rr.cr_returning_customer_sk,
        rr.cr_refunded_customer_sk,
        rr.total_return_quantity,
        rr.total_return_amt
    FROM RankedReturns rr
    WHERE rr.rank = 1
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    hrc.total_return_quantity,
    hrc.total_return_amt,
    (CASE 
        WHEN hrc.total_return_amt IS NULL THEN 'No Returns' 
        ELSE CONCAT('Total Returns: ', CAST(hrc.total_return_amt AS VARCHAR(20))) 
    END) AS return_summary,
    DENSE_RANK() OVER (ORDER BY hrc.total_return_amt DESC) AS return_rank
FROM HighRefundCustomers hrc
JOIN customer c ON c.c_customer_sk = hrc.cr_returning_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    (cd.cd_gender = 'M' OR cd.cd_gender = 'F') AND
    (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
ORDER BY 
    return_rank
LIMIT 100;
