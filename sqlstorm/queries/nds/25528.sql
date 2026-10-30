
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Apt ', ca_suite_number), '')) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemographicCounts AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(*) AS GenderCount
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk, cd_gender
),
SalesSummary AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_net_paid) AS TotalSales,
        COUNT(ws_order_number) AS TotalOrders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    ad.FullAddress,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    dm.cd_gender,
    dm.GenderCount,
    ss.TotalSales,
    ss.TotalOrders
FROM 
    AddressDetails ad
JOIN 
    customer c ON ad.ca_address_sk = c.c_current_addr_sk
JOIN 
    DemographicCounts dm ON c.c_current_cdemo_sk = dm.cd_demo_sk
LEFT JOIN 
    SalesSummary ss ON ad.ca_address_sk = ss.ws_bill_addr_sk
WHERE 
    ad.ca_state = 'CA'
ORDER BY 
    TotalSales DESC NULLS LAST, 
    ad.ca_city ASC;
