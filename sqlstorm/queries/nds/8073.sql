
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
CustomerRanked AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_education_status,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    cr.c_customer_sk,
    cr.total_sales,
    cr.order_count,
    cr.cd_gender,
    cr.cd_marital_status,
    cr.cd_education_status
FROM 
    CustomerRanked cr
WHERE 
    cr.sales_rank <= 5
ORDER BY 
    cr.cd_gender, cr.total_sales DESC;
