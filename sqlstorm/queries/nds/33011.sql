
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451503 AND 2451567 
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        * 
    FROM 
        sales_hierarchy
    WHERE 
        rank <= 10
),
customer_address_info AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
customer_sales_info AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        cai.ca_city,
        cai.ca_state,
        cai.ca_country
    FROM 
        top_customers tc
    JOIN 
        customer_address_info cai ON tc.c_customer_sk = cai.c_customer_sk
)
SELECT 
    csi.c_first_name,
    csi.c_last_name,
    COALESCE(csi.ca_city, 'N/A') AS city,
    COALESCE(csi.ca_state, 'N/A') AS state,
    COALESCE(csi.ca_country, 'N/A') AS country,
    csi.total_sales AS total_sales,
    CASE 
        WHEN csi.total_sales > 1000 THEN 'High Value'
        WHEN csi.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    customer_sales_info csi
FULL OUTER JOIN 
    (SELECT 
         ca.ca_city, 
         COUNT(*) AS city_count 
     FROM 
         customer_address ca 
     GROUP BY 
         ca.ca_city) city_data ON city_data.ca_city = csi.ca_city
WHERE 
    csi.total_sales IS NOT NULL 
ORDER BY 
    csi.total_sales DESC;
