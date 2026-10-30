
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS FullName,
        cd_gender,
        cd_marital_status,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS TotalSales,
        COUNT(ws_order_number) AS OrderCount
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AggregatedData AS (
    SELECT 
        ci.FullName,
        ci.cd_gender,
        ci.cd_marital_status,
        ai.FullAddress,
        sd.TotalSales,
        sd.OrderCount
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
    LEFT JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    COUNT(*) AS CustomerCount,
    AVG(TotalSales) AS AvgSales,
    SUM(OrderCount) AS TotalOrders
FROM 
    AggregatedData
GROUP BY 
    cd_gender, cd_marital_status
ORDER BY 
    cd_gender, cd_marital_status;
