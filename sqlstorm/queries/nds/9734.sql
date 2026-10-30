
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        d.d_year,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        c.c_customer_id, ca.ca_city, d.d_year
),
AvgSales AS (
    SELECT 
        ca_city,
        d_year,
        AVG(total_sales) AS avg_sales_per_customer
    FROM 
        SalesSummary
    GROUP BY 
        ca_city, d_year
)
SELECT 
    city_detailed.ca_city,
    city_detailed.total_customers,
    city_detailed.total_transactions,
    avg.avg_sales_per_customer
FROM 
    (SELECT 
         ca.ca_city,
         COUNT(DISTINCT c.c_customer_id) AS total_customers,
         COUNT(ss.ss_ticket_number) AS total_transactions
     FROM 
         customer c
     JOIN 
         customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
     JOIN 
         store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
     GROUP BY 
         ca.ca_city) AS city_detailed
JOIN 
    AvgSales avg ON city_detailed.ca_city = avg.ca_city
ORDER BY 
    avg.avg_sales_per_customer DESC
LIMIT 10;
