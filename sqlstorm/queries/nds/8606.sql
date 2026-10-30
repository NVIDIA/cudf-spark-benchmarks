
WITH RankedSales AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS purchase_count,
        ROW_NUMBER() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_sales_price) DESC) AS rank
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ss_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        rs.total_sales,
        rs.purchase_count
    FROM 
        RankedSales rs
    JOIN 
        customer c ON rs.ss_customer_sk = c.c_customer_sk
    WHERE 
        rs.rank <= 10
),
SalesByCity AS (
    SELECT 
        ca_city,
        SUM(total_sales) AS city_sales
    FROM 
        TopCustomers tc
    JOIN 
        customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
    GROUP BY 
        ca_city
)
SELECT 
    c.city_sales,
    RANK() OVER (ORDER BY c.city_sales DESC) AS city_rank
FROM 
    SalesByCity c 
ORDER BY 
    city_sales DESC;
