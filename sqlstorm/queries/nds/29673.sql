
WITH AddressedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        LENGTH(ca.ca_street_name) AS street_name_length,
        LENGTH(ca.ca_suite_number) AS suite_number_length,
        ca.ca_street_name
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year > 1980 
        AND ca.ca_state IN ('CA', 'TX')
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ac.full_name,
    ac.ca_city,
    ac.ca_state,
    ac.ca_zip,
    ss.total_sales,
    ss.order_count,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Purchases'
        WHEN ss.total_sales < 1000 THEN 'Under Threshold'
        ELSE 'Over Threshold'
    END AS sales_category,
    CONCAT(REPEAT('*', ac.street_name_length), ' ', ac.ca_street_name, ' ', REPEAT('*', ac.suite_number_length)) AS obscured_address
FROM 
    AddressedCustomers ac
LEFT JOIN 
    SalesSummary ss ON ac.c_customer_id = ss.c_customer_id
ORDER BY 
    ss.total_sales DESC NULLS LAST
LIMIT 100;
