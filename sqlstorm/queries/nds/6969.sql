
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND ws.ws_sold_date_sk >= (
            SELECT 
                DENSE_RANK() OVER (ORDER BY d_date DESC) 
            FROM 
                date_dim 
            WHERE 
                d_current_year = '1'
        ) - 12
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        c.total_sales,
        DENSE_RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    tc.first_name,
    tc.last_name,
    tc.total_sales,
    COALESCE(AVG(ws.ws_ext_sales_price), 0) AS avg_sales_price,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_purchased
FROM 
    TopCustomers tc
LEFT JOIN 
    web_sales ws ON tc.customer_sk = ws.ws_bill_customer_sk
WHERE 
    tc.sales_rank <= 10
GROUP BY 
    tc.first_name, tc.last_name, tc.total_sales
ORDER BY 
    tc.total_sales DESC;
