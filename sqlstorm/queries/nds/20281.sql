
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk, 
        sr_item_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS return_rank,
        SUM(sr_return_quantity) OVER (PARTITION BY sr_customer_sk) AS total_returns
    FROM store_returns
    WHERE sr_return_quantity > 0
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        COUNT(DISTINCT sr.return_rank) AS unique_item_returns
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN RankedReturns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE cd.cd_gender IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ca.ca_city
)
SELECT 
    cd.c_customer_sk, 
    cd.c_first_name, 
    cd.c_last_name,
    cd.cd_gender, 
    cd.cd_marital_status,
    cd.ca_city,
    COALESCE(SUM(CASE WHEN sr.sr_return_quantity IS NULL OR sr.sr_return_quantity <= 0 THEN 0 ELSE sr.sr_return_quantity END), 0) AS total_valid_returns,
    MAX(cd.unique_item_returns) AS max_unique_item_returns,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
    COUNT(DISTINCT CASE WHEN cd.cd_gender = 'F' THEN cd.c_customer_sk END) AS female_customers
FROM CustomerDetails cd 
LEFT JOIN RankedReturns sr ON cd.c_customer_sk = sr.sr_customer_sk AND sr.return_rank = 1
GROUP BY 
    cd.c_customer_sk, 
    cd.c_first_name, 
    cd.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.ca_city
HAVING COUNT(DISTINCT sr.sr_item_sk) > 0 
   OR MAX(cd.unique_item_returns) > 3
ORDER BY total_valid_returns DESC NULLS LAST;
