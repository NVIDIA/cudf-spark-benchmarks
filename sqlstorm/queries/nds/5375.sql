WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600  
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
CustomerRanking AS (
    SELECT 
        c.*, 
        DENSE_RANK() OVER (PARTITION BY c.cd_gender ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerData c
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.cd_gender,
        c.total_sales,
        c.order_count,
        c.sales_rank
    FROM 
        CustomerRanking c
    WHERE 
        c.sales_rank <= 10  
)
SELECT 
    tc.cd_gender,
    COUNT(*) AS top_customer_count,
    SUM(tc.total_sales) AS total_sales_by_gender,
    AVG(tc.order_count) AS avg_orders_per_customer
FROM 
    TopCustomers tc
GROUP BY 
    tc.cd_gender
ORDER BY 
    tc.cd_gender;