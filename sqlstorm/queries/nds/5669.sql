
WITH CustomerData AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        SUM(ws.ws_ext_sales_price) AS total_spent,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_education_status IN ('Bachelor’s Degree', 'Master’s Degree')
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
TopCustomers AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rnk
    FROM 
        CustomerData
)
SELECT 
    tc.c_customer_id, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_spent, 
    tc.avg_discount, 
    tc.total_orders
FROM 
    TopCustomers tc
WHERE 
    tc.rnk <= 10;
