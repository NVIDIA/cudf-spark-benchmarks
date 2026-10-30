
WITH AddressInfo AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca.ca_suite_number), '')) AS FullAddress,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS FullName,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
),
CombinedInfo AS (
    SELECT 
        ci.FullName,
        ci.cd_gender,
        ci.cd_marital_status,
        sa.FullAddress,
        sa.ca_city,
        sa.ca_state,
        sa.ca_zip,
        sa.ca_country,
        SUM(si.ws_quantity) AS TotalQuantity,
        SUM(si.ws_ext_sales_price) AS TotalSales,
        SUM(si.ws_net_paid) AS TotalNetPaid
    FROM 
        CustomerInfo ci
    JOIN 
        AddressInfo sa ON ci.c_customer_id = sa.ca_address_id
    LEFT JOIN 
        SalesInfo si ON ci.FullName LIKE '%' || CAST(si.ws_order_number AS STRING) || '%'
    GROUP BY 
        ci.FullName, ci.cd_gender, ci.cd_marital_status, 
        sa.FullAddress, sa.ca_city, sa.ca_state, sa.ca_zip, sa.ca_country
)
SELECT 
    COUNT(*) AS CustomerCount,
    AVG(TotalSales) AS AvgSalesPerCustomer,
    SUM(TotalQuantity) AS TotalUnitsSold,
    MAX(TotalNetPaid) AS MaxNetPaidFromCustomer,
    MIN(TotalNetPaid) AS MinNetPaidFromCustomer
FROM 
    CombinedInfo;
