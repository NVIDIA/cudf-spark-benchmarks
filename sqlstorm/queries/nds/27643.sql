
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(ca_country) AS country_length
    FROM 
        customer_address
    WHERE 
        ca_city LIKE 'San%'
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
)
SELECT 
    COALESCE(addr.full_address, 'N/A') AS Address,
    cust.full_name AS Customer,
    cust.cd_gender AS Gender,
    sales.total_sales AS Total_Sales,
    sales.order_count AS Order_Count,
    addr.country_length AS Country_Length
FROM 
    AddressDetails addr
LEFT JOIN 
    CustomerSummary cust ON addr.ca_address_sk = cust.c_customer_sk
LEFT JOIN 
    SalesData sales ON sales.ws_sold_date_sk = addr.ca_address_sk
WHERE 
    addr.country_length > 5
ORDER BY 
    sales.total_sales DESC
LIMIT 10;
