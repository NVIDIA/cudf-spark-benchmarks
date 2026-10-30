
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_ticket_number,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn,
        COALESCE(sr_return_quantity, 0) AS return_quantity,
        COALESCE(sr_return_amt, 0) AS return_amount,
        COALESCE(sr_return_tax, 0) AS return_tax
    FROM store_returns
), 
CustomerSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
DemographicAnalysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(COALESCE(cd_purchase_estimate, 0)) AS total_estimate,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM customer_demographics 
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_gender, cd_marital_status
)
SELECT 
    ca.ca_county,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(CASE 
        WHEN dr.order_count > 5 THEN dr.total_sales * 1.1 
        ELSE dr.total_sales 
    END) AS adjusted_sales,
    AVG(CASE 
        WHEN dmar.customer_count IS NOT NULL 
        THEN dmar.total_estimate 
        ELSE NULL 
    END) AS avg_estimate_by_gender
FROM 
    customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN CustomerSales dr ON dr.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN DemographicAnalysis dmar ON dmar.cd_gender = (CASE WHEN c.c_birth_year < 1980 THEN 'M' ELSE 'F' END)
WHERE 
    ca.ca_state = 'CA' 
    AND ca.ca_country IS NOT NULL 
    AND ('2023-01-01' BETWEEN (SELECT MIN(d_date) FROM date_dim) AND (SELECT MAX(d_date) FROM date_dim))
GROUP BY ca.ca_county
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY adjusted_sales DESC 
LIMIT 10;
