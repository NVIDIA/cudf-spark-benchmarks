
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
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
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        CustomerSales cs ON cs.c_customer_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        Demographics d ON cs.c_customer_sk = d.cd_demo_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    c.total_sales
FROM 
    TopCustomers c
JOIN 
    Demographics d ON c.c_customer_sk = d.cd_demo_sk
WHERE 
    c.rank <= 10
ORDER BY 
    c.total_sales DESC;
