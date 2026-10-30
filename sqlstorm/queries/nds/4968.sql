
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
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRank AS (
    SELECT 
        c_customer_sk,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
),
TopCustomers AS (
    SELECT 
        csr.c_customer_sk,
        csr.total_sales,
        csr.order_count,
        csr.sales_rank,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        SalesRank csr
    JOIN 
        customer_demographics cd ON csr.c_customer_sk = cd.cd_demo_sk
    WHERE 
        csr.sales_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.total_sales,
    tc.order_count,
    tc.cd_gender,
    tc.cd_marital_status,
    COALESCE(
        (SELECT 
             SUM(sr_return_amt_inc_tax) 
         FROM 
             store_returns sr 
         WHERE 
             sr.sr_customer_sk = tc.c_customer_sk), 
        0.00
    ) AS total_returns,
    ROUND(
        (tc.total_sales - COALESCE(
            (SELECT 
                 SUM(sr_return_amt_inc_tax) 
             FROM 
                 store_returns sr 
             WHERE 
                 sr.sr_customer_sk = tc.c_customer_sk), 
            0.00
        )) / NULLIF(tc.total_sales, 0), 2
    ) AS net_sales_ratio
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_sales DESC;
