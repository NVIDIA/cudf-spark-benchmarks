
WITH ranked_sales AS (
    SELECT 
        ws_web_site_sk,
        ws_order_number,
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_web_site_sk, ws_order_number
),
top_sales AS (
    SELECT 
        ws_web_site_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(total_sales) AS total_revenue
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
    GROUP BY 
        ws_web_site_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    c.c_email_address,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.cd_purchase_estimate,
    ts.order_count,
    ts.total_revenue
FROM 
    customer_details c
JOIN 
    top_sales ts ON c.c_customer_sk = ts.ws_web_site_sk
ORDER BY 
    ts.total_revenue DESC;
