
WITH  SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
FilteredSales AS (
    SELECT 
        *,
        CASE 
            WHEN total_sales IS NULL THEN 'No Sales'
            WHEN total_sales > 5000 THEN 'High Value'
            WHEN total_sales > 1000 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS sales_category
    FROM 
        SalesHierarchy
    WHERE 
        sales_rank <= 10
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.total_sales,
    f.sales_category,
    a.ca_city,
    a.ca_state,
    a.ca_country
FROM 
    FilteredSales f
LEFT JOIN 
    CustomerAddress a ON f.c_customer_sk = a.ca_address_sk
ORDER BY 
    f.total_sales DESC
LIMIT 20;
