
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
)

SELECT 
    cs.c_customer_id, 
    cs.cd_gender,
    cs.total_sales,
    cs.order_count,
    cs.avg_order_value,
    CASE 
        WHEN cs.total_sales > 10000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    CustomerSales cs
WHERE 
    cs.order_count > 5
ORDER BY 
    cs.total_sales DESC
LIMIT 50;
