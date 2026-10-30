
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 30
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
aggregate_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
),
top_customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_sales
    FROM 
        aggregate_sales
    WHERE 
        sales_rank <= 10
),
customer_details AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating
    FROM 
        top_customers tc
    LEFT JOIN 
        customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.gender,
    cd.marital_status,
    cd.credit_rating,
    cs.total_sales
FROM 
    customer_details cd
JOIN 
    customer_sales cs ON cd.c_customer_sk = cs.c_customer_sk
ORDER BY 
    cs.total_sales DESC
LIMIT 5;
