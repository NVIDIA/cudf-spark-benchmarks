
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS sales_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
Customer_Items AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ci.ws_item_sk,
        ci.total_sales,
        ci.sales_count
    FROM 
        customer c
    JOIN Sales_CTE ci ON c.c_customer_sk = ci.ws_item_sk
)
SELECT 
    ca.ca_city,
    SUM(ci.total_sales) AS city_sales,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers,
    AVG(ci.sales_count) AS avg_sales_per_customer
FROM 
    customer_address ca
LEFT JOIN 
    customer ce ON ca.ca_address_sk = ce.c_current_addr_sk
JOIN 
    Customer_Items ci ON ci.c_customer_sk = ce.c_customer_sk
WHERE 
    ca.ca_city IS NOT NULL
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ci.total_sales) > (SELECT AVG(total_sales) FROM Sales_CTE)
ORDER BY 
    city_sales DESC
LIMIT 10;
