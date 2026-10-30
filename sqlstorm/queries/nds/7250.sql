
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) as sales_rank
    FROM 
        CustomerSales
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10'
        WHEN tc.sales_rank <= 50 THEN 'Top 50'
        ELSE 'Others'
    END AS sales_category
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_sales DESC;
