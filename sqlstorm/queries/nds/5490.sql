
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
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451546 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.customer_index,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        (SELECT 
            ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS customer_index,
            c.c_customer_sk
         FROM 
            CustomerSales cs
         JOIN 
            customer c ON cs.c_customer_sk = c.c_customer_sk
         WHERE 
            cs.total_sales > 0) AS c
    JOIN 
        CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
)

SELECT 
    cu.c_customer_sk AS c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    cu.total_sales,
    t.sales_rank,
    CASE 
        WHEN t.sales_rank <= 10 THEN 'Top 10% Customers'
        WHEN t.sales_rank <= 100 THEN 'Top 1% Customers'
        ELSE 'Regular Customers'
    END AS customer_category
FROM 
    CustomerSales cu
JOIN 
    TopCustomers t ON cu.c_customer_sk = t.customer_index
WHERE 
    cu.total_sales > 1000 
ORDER BY 
    cu.total_sales DESC;
