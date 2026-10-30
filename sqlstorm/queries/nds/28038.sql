
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS FullAddress,
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
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS Gender,
        cd_marital_status AS MaritalStatus,
        cd_education_status AS EducationStatus,
        ia.FullAddress,
        ia.ca_city,
        ia.ca_state,
        ia.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressInfo ia ON c.c_current_addr_sk = ia.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS TotalSales,
        COUNT(ws_order_number) AS TotalOrders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        ci.FullName,
        ci.Gender,
        ci.MaritalStatus,
        ci.EducationStatus,
        sd.TotalSales,
        sd.TotalOrders
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    FullName,
    Gender,
    MaritalStatus,
    EducationStatus,
    TotalSales,
    TotalOrders,
    RANK() OVER (ORDER BY TotalSales DESC) AS SalesRank
FROM 
    CustomerSales
WHERE 
    TotalSales > 1000
ORDER BY 
    TotalSales DESC;
