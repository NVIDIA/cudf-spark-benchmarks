
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), 
FormattedEmails AS (
    SELECT 
        c_customer_sk,
        LOWER(TRIM(CONCAT(SUBSTRING(c_first_name, 1, 1), c_last_name, '@example.com'))) AS email
    FROM 
        customer
), 
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    A.full_address,
    A.ca_city,
    A.ca_state,
    A.ca_zip,
    A.ca_country,
    E.email,
    S.total_orders,
    S.total_sales
FROM 
    AddressParts A
JOIN 
    FormattedEmails E ON A.ca_address_sk = E.c_customer_sk
LEFT JOIN 
    SalesSummary S ON E.c_customer_sk = S.ws_bill_customer_sk
WHERE 
    A.ca_state = 'NY' AND 
    S.total_sales > 1000
ORDER BY 
    S.total_sales DESC, A.full_address;
