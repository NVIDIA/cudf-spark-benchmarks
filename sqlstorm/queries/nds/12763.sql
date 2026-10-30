
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2457208 AND 2457268
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd_gender,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    SUM(total_orders) AS total_orders
FROM 
    SalesSummary ss
JOIN 
    customer_demographics cd ON ss.ws_bill_customer_sk = cd.cd_demo_sk
GROUP BY 
    cd_gender;
