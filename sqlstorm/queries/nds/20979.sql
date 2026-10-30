
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL
),
StoreSalesSummary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        AVG(ss_sales_price) as avg_sales_price
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY 
        ss_store_sk
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CombinedData AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        ss.total_sales,
        ss.unique_customers,
        rr.total_returns,
        CASE 
            WHEN ss.total_sales IS NULL AND rr.total_returns IS NULL THEN 'No Transactions'
            WHEN ss.total_sales IS NULL THEN 'Returned Only'
            WHEN rr.total_returns IS NULL THEN 'Purchased Only'
            ELSE 'Both Transactions'
        END AS transaction_type
    FROM 
        RankedCustomers r
    LEFT JOIN 
        StoreSalesSummary ss ON r.c_customer_sk = ss.ss_store_sk
    LEFT JOIN 
        CustomerReturns rr ON r.c_customer_sk = rr.sr_customer_sk
    WHERE 
        r.rn = 1
)
SELECT 
    *,
    COALESCE(total_sales, 0) - COALESCE(total_returns, 0) AS net_transaction_value,
    CASE 
        WHEN total_sales IS NULL THEN 'Sale amount unavailable'
        ELSE 'Sale amount available'
    END AS sales_status,
    CONCAT(c_first_name, ' ', c_last_name) AS full_name
FROM 
    CombinedData
WHERE 
    transaction_type != 'No Transactions'
ORDER BY 
    net_transaction_value DESC 
LIMIT 10;
