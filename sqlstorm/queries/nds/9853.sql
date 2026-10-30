
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), RankedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
), HighValueCustomers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_sales
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    h.total_sales,
    a.ca_city,
    a.ca_state
FROM 
    HighValueCustomers h
JOIN 
    customer_address a ON h.c_customer_sk = a.ca_address_sk
ORDER BY 
    h.total_sales DESC;
