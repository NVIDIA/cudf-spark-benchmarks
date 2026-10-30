
WITH customer_order_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity_ordered,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451546   
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
)
SELECT 
    cos.c_customer_sk,
    cos.c_first_name,
    cos.c_last_name,
    cd.gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cos.total_quantity_ordered,
    cos.total_sales,
    cos.order_count
FROM 
    customer_order_stats cos
JOIN 
    customer_demographics cd ON cos.c_customer_sk = cd.cd_demo_sk
WHERE 
    cos.rank <= 10   
ORDER BY 
    cos.total_sales DESC;
