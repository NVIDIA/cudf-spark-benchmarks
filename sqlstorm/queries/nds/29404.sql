
WITH AddressRanked AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_last_name, c.c_first_name) AS rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_city IS NOT NULL
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
HighlightedCustomers AS (
    SELECT 
        ar.c_customer_sk,
        ar.c_first_name,
        ar.c_last_name,
        ar.ca_city,
        ss.total_sales,
        ss.order_count
    FROM 
        AddressRanked ar
    JOIN 
        SalesSummary ss ON ar.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ar.rank = 1 AND ss.total_sales > 1000
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    a.ca_city AS city,
    s.total_sales AS total_sales,
    s.order_count AS order_count
FROM 
    HighlightedCustomers s
JOIN 
    customer_address a ON s.c_customer_sk = a.ca_address_sk
JOIN 
    customer c ON s.c_customer_sk = c.c_customer_sk
ORDER BY 
    s.total_sales DESC;
