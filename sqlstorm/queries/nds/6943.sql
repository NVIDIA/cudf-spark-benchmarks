
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'M' 
        AND cd.cd_purchase_estimate > 5000
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
FinalData AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        sd.total_sales,
        sd.order_count
    FROM 
        CustomerData cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    fd.c_customer_sk,
    fd.c_first_name,
    fd.c_last_name,
    COALESCE(fd.total_sales, 0) AS total_sales,
    COALESCE(fd.order_count, 0) AS order_count,
    RANK() OVER (ORDER BY COALESCE(fd.total_sales, 0) DESC) AS sales_rank
FROM 
    FinalData fd
WHERE 
    fd.order_count > 1
ORDER BY 
    sales_rank
LIMIT 100;
