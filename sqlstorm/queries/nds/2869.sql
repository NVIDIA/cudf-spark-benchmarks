
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_sales,
        order_count,
        NTILE(4) OVER (ORDER BY total_sales DESC) AS sales_quartile
    FROM 
        CustomerSales
    WHERE 
        total_sales > 0
)
SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    h.total_sales,
    h.order_count,
    COALESCE(a.ca_country, 'Unknown') AS country,
    CASE 
        WHEN h.sales_quartile = 1 THEN 'Top 25%'
        WHEN h.sales_quartile = 2 THEN 'Second 25%'
        WHEN h.sales_quartile = 3 THEN 'Third 25%'
        ELSE 'Bottom 25%'
    END AS sales_category
FROM 
    HighValueCustomers h
LEFT JOIN 
    customer_address a ON h.c_customer_sk = a.ca_address_sk
WHERE 
    a.ca_country IS NOT NULL
ORDER BY 
    h.total_sales DESC
LIMIT 100;
