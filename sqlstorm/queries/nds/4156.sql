
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 10001 AND 10005
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_customer_sk IN (SELECT c_customer_sk FROM customer_sales)
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
sales_ranks AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)

SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    COALESCE(SUM(CASE WHEN sr.sales_rank <= 10 THEN sr.total_sales END), 0) AS top_10_sales,
    COALESCE(SUM(sr.total_sales), 0) AS total_sales_all
FROM 
    customer_demographics cd
LEFT JOIN sales_ranks sr ON cd.cd_demo_sk = sr.c_customer_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.customer_count
ORDER BY 
    total_sales_all DESC
LIMIT 5;
