
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS FullName,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS TotalSales,
        COUNT(DISTINCT ws_order_number) AS OrderCount,
        COUNT(DISTINCT ws_web_site_sk) AS DistinctWebSites
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.FullName,
    cd.cd_gender,
    cd.cd_marital_status,
    ap.FullAddress,
    ap.ca_city,
    ap.ca_state,
    ap.ca_zip,
    ap.ca_country,
    si.TotalSales,
    si.OrderCount,
    si.DistinctWebSites,
    CASE 
        WHEN si.TotalSales >= 1000 THEN 'High Roller'
        WHEN si.TotalSales BETWEEN 500 AND 999 THEN 'Average Joe'
        ELSE 'Budget Buyer'
    END AS CustomerCategory
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesInfo si ON cd.c_customer_sk = si.ws_bill_customer_sk
LEFT JOIN 
    AddressParts ap ON cd.c_customer_sk = ap.ca_address_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_purchase_estimate > 200
ORDER BY 
    si.TotalSales DESC, 
    cd.FullName;
