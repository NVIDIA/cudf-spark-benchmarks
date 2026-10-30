
WITH sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk AS customer_demo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    COUNT(ss.customer_demo_sk) AS customer_count,
    AVG(ss.total_sales) AS avg_sales,
    SUM(ss.order_count) AS total_orders
FROM 
    sales_summary ss
JOIN 
    customer_demographics cd ON ss.customer_demo_sk = cd.cd_demo_sk
GROUP BY 
    cd_gender, cd_marital_status
ORDER BY 
    avg_sales DESC;
