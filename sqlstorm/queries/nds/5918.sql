
WITH RankedSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        rs.c_customer_sk, 
        rs.c_first_name, 
        rs.c_last_name, 
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        customer_demographics cd ON rs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        rs.sales_rank <= 10 AND 
        cd.cd_marital_status = 'M'
)
SELECT 
    T.c_customer_sk, 
    T.c_first_name, 
    T.c_last_name, 
    T.total_sales, 
    COUNT(DISTINCT ws.ws_order_number) AS order_count, 
    SUM(ws.ws_ext_ship_cost) AS total_shipping_cost
FROM 
    TopCustomers T
JOIN 
    web_sales ws ON T.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    T.c_customer_sk, T.c_first_name, T.c_last_name, T.total_sales
ORDER BY 
    total_sales DESC;
