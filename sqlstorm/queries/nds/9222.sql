
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_web_page_sk) AS pages_visited
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_orders,
        cs.pages_visited,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
CustomerAddress AS (
    SELECT 
        tc.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        tc.total_sales,
        tc.total_orders,
        tc.pages_visited,
        tc.sales_rank
    FROM 
        TopCustomers tc
    JOIN 
        customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
    WHERE 
        tc.sales_rank <= 10
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(tc.c_customer_sk) AS customer_count,
    AVG(tc.total_sales) AS avg_sales,
    AVG(tc.total_orders) AS avg_orders,
    AVG(tc.pages_visited) AS avg_pages_visited
FROM 
    CustomerAddress ca
JOIN 
    TopCustomers tc ON ca.c_customer_sk = tc.c_customer_sk
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    customer_count DESC, avg_sales DESC;
