
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_street_name) AS address_rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.full_address
    FROM 
        customer c
    JOIN 
        RankedAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 2000
        AND ca.address_rank <= 10
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        FilteredCustomers fc ON ws.ws_bill_customer_sk = fc.c_customer_sk
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    fc.full_name,
    fc.full_address,
    COALESCE(ss.total_sales, 0) AS total_sales
FROM 
    FilteredCustomers fc
LEFT JOIN 
    SalesSummary ss ON fc.c_customer_sk = ss.ws_bill_customer_sk
ORDER BY 
    total_sales DESC
LIMIT 20;
