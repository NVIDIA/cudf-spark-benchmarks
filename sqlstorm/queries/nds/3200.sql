
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        ca.ca_state = 'CA'
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    (SELECT COUNT(*) 
     FROM CustomerSales 
     WHERE total_sales > tc.total_sales) AS rank_position,
    (SELECT AVG(total_sales) FROM CustomerSales) AS avg_sales,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales'
        WHEN tc.total_sales > (SELECT AVG(total_sales) FROM CustomerSales) THEN 'Above Average'
        ELSE 'Below Average' 
    END AS performance_category
FROM 
    TopCustomers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
