
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
TotalReturns AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr_store_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.customer_count,
    rc.c_customer_id,
    rc.cd_gender,
    rt.total_returned,
    rt.total_return_amount
FROM 
    AddressInfo a
JOIN 
    RankedCustomers rc ON a.customer_count > (SELECT AVG(customer_count) FROM AddressInfo) 
LEFT JOIN 
    TotalReturns rt ON a.customer_count = rt.total_returned
WHERE 
    a.ca_state IN ('CA', 'NY') 
    AND (a.customer_count IS NOT NULL OR rt.total_return_amount IS NULL)
ORDER BY 
    a.ca_city ASC, a.customer_count DESC
LIMIT 10;
