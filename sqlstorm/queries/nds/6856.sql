
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c_customer_sk, 
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    customer.c_customer_id,
    customer.c_first_name,
    customer.c_last_name,
    top.total_sales,
    top.order_count
FROM 
    TopCustomers top
JOIN 
    customer customer ON top.c_customer_sk = customer.c_customer_sk
WHERE 
    top.sales_rank <= 10
ORDER BY 
    top.total_sales DESC;
