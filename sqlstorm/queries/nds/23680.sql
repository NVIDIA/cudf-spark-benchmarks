WITH RecursiveCustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS RankByEstimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number) AS FullAddress,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ca.ca_city) AS AddrRank
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS CustomerSK,
        SUM(ws_sales_price) AS TotalSales,
        COUNT(DISTINCT ws_order_number) AS OrderCount,
        AVG(ws_sales_price) AS AvgOrderValue
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
    GROUP BY 
        ws_bill_customer_sk
),
EnhancedSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_profit) AS TotalStoreProfit,
        SUM(ws.ws_net_profit) AS TotalWebProfit
    FROM 
        store_sales ss
    FULL OUTER JOIN 
        web_sales ws ON ss.ss_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer c ON c.c_customer_sk = 
            COALESCE(ss.ss_customer_sk, ws.ws_bill_customer_sk)
    GROUP BY 
        c.c_customer_sk
)

SELECT 
    rcd.c_customer_sk,
    rcd.c_first_name,
    rcd.c_last_name,
    rcd.cd_gender,
    ca.FullAddress,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    ss.TotalSales,
    ss.OrderCount,
    es.TotalStoreProfit,
    es.TotalWebProfit,
    ROW_NUMBER() OVER (PARTITION BY rcd.cd_gender ORDER BY rcd.RankByEstimate DESC) AS GenderRank
FROM 
    RecursiveCustomerData rcd
LEFT JOIN 
    CustomerAddresses ca ON rcd.c_customer_sk = ca.c_customer_sk AND ca.AddrRank = 1
LEFT JOIN 
    SalesSummary ss ON rcd.c_customer_sk = ss.CustomerSK
LEFT JOIN 
    EnhancedSales es ON rcd.c_customer_sk = es.c_customer_sk
WHERE 
    es.TotalStoreProfit IS NOT NULL OR ss.TotalSales > 1000  
ORDER BY 
    rcd.c_first_name, rcd.c_last_name;