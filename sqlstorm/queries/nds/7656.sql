
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND 
                               (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
customer_summary AS (
    SELECT 
        cn.c_customer_sk,
        cn.c_first_name,
        cn.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_sales,
        cs.total_discount,
        cs.order_count,
        cs.avg_net_paid
    FROM 
        customer cn
    JOIN 
        customer_demographics cd ON cn.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary cs ON cn.c_customer_sk = cs.ws_bill_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.total_sales,
    c.total_discount,
    c.order_count,
    c.avg_net_paid,
    DENSE_RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
FROM 
    customer_summary c
WHERE 
    c.total_sales > 1000
ORDER BY 
    c.total_sales DESC
LIMIT 50;
