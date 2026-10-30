
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price + ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_store_sales
    FROM 
        CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.sales_rank <= 10
),
SalesSummary AS (
    SELECT 
        COALESCE(ca.ca_city, 'Unknown City') AS city,
        SUM(tc.total_web_sales) AS total_web_sales_by_city,
        SUM(tc.total_store_sales) AS total_store_sales_by_city,
        COUNT(tc.c_customer_sk) AS customer_count
    FROM 
        TopCustomers tc
    LEFT JOIN customer_address ca ON ca.ca_address_sk = tc.c_customer_sk
    GROUP BY 
        ca.ca_city
)

SELECT 
    ss.city,
    ss.total_web_sales_by_city,
    ss.total_store_sales_by_city,
    ss.customer_count
FROM 
    SalesSummary ss
WHERE 
    ss.customer_count > 5
ORDER BY 
    ss.total_web_sales_by_city DESC,
    ss.total_store_sales_by_city DESC;
