
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 10000
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
filtered_sales AS (
    SELECT 
        r.c_customer_sk,
        COALESCE(ss.total_sales, 0) AS total_sales,
        ss.order_count,
        r.c_first_name,
        r.c_last_name
    FROM 
        ranked_customers r
    LEFT JOIN 
        sales_summary ss ON r.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        r.purchase_rank <= 5
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.total_sales,
    f.order_count,
    CASE 
        WHEN f.total_sales = 0 THEN 'No Sales'
        ELSE NULL
    END AS sale_status,
    CASE 
        WHEN f.total_sales > 50000 THEN 'High Value Customer'
        WHEN f.total_sales BETWEEN 20000 AND 50000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value
FROM 
    filtered_sales f
ORDER BY 
    f.total_sales DESC
LIMIT 10;
