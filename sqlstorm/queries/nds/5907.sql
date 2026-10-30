
WITH CustomerPurchases AS (
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
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001 AND 
        d.d_month_seq IN (1, 2, 3) 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), 
TopCustomers AS (
    SELECT 
        cp.c_customer_id, 
        cp.total_sales,
        cp.order_count,
        ROW_NUMBER() OVER (ORDER BY cp.total_sales DESC) AS rank
    FROM 
        CustomerPurchases cp
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_sales DESC;
