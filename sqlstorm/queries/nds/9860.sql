
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS num_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 3000
    GROUP BY 
        ws_bill_customer_sk, 
        ws_sold_date_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_rank AS (
    SELECT 
        ss.ws_bill_customer_sk,
        DENSE_RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    ci.cd_dep_count,
    ss.total_quantity,
    ss.total_sales,
    sr.sales_rank
FROM 
    customer_info ci
JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
JOIN 
    sales_rank sr ON ss.ws_bill_customer_sk = sr.ws_bill_customer_sk
WHERE 
    sr.sales_rank <= 50
ORDER BY 
    ss.total_sales DESC;
