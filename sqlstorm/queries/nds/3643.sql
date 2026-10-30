
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) as sales_rank
    FROM 
        customer_sales cs
),
best_customers AS (
    SELECT *
    FROM top_customers
    WHERE sales_rank <= 10
),
purchase_trends AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS customer_count,
        SUM(ws.ws_ext_sales_price) AS sales_total,
        AVG(ws.ws_ext_sales_price) AS avg_purchase
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    b.c_first_name,
    b.c_last_name,
    b.total_sales,
    pt.customer_count,
    pt.sales_total,
    pt.avg_purchase
FROM 
    best_customers b
LEFT JOIN 
    purchase_trends pt ON b.c_customer_sk = pt.customer_count
ORDER BY 
    b.total_sales DESC;
