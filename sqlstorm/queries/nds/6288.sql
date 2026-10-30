
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 10000 AND 10050
    GROUP BY 
        c.c_customer_id
),
AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        CustomerSales cs ON c.c_customer_id = cs.c_customer_id
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state, ca.ca_country
),
SalesRanked AS (
    SELECT 
        ad.ca_address_id,
        ad.ca_city,
        ad.ca_state,
        ad.ca_country,
        ad.customer_count,
        CS.total_sales,
        RANK() OVER (ORDER BY CS.total_sales DESC) AS sales_rank
    FROM 
        AddressDetails ad
    JOIN 
        CustomerSales CS ON ad.customer_count > 0
)
SELECT 
    sr.ca_address_id,
    sr.ca_city,
    sr.ca_state,
    sr.ca_country,
    sr.customer_count,
    sr.total_sales,
    sr.sales_rank
FROM 
    SalesRanked sr
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.total_sales DESC;
