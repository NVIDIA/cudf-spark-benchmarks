
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(', ', 
            TRIM(ca_street_number), 
            TRIM(ca_street_name), 
            TRIM(ca_street_type), 
            CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT('Suite ', TRIM(ca_suite_number), ', ') ELSE '' END,
            TRIM(ca_city), 
            TRIM(ca_county), 
            TRIM(ca_state), 
            TRIM(ca_zip), 
            TRIM(ca_country)
        ) AS FullAddress
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS FullName,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            WHEN cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS Gender,
        da.FullAddress
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        AddressComponents da ON c.c_current_addr_sk = da.ca_address_sk
)
SELECT 
    c.FullName,
    c.Gender,
    c.FullAddress,
    COUNT(ws.ws_order_number) AS TotalOrders,
    SUM(ws.ws_sales_price) AS TotalSpent,
    AVG(ws.ws_sales_price) AS AvgOrderValue
FROM 
    CustomerInfo c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    c.FullName, c.Gender, c.FullAddress
ORDER BY 
    TotalSpent DESC
LIMIT 10;
