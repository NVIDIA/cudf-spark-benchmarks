
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
SalesByGender AS (
    SELECT 
        cd_gender,
        AVG(total_sales) AS avg_sales,
        SUM(total_orders) AS total_orders
    FROM 
        CustomerSales
    GROUP BY 
        cd_gender
)
SELECT 
    s.cd_gender,
    s.avg_sales,
    s.total_orders,
    CASE 
        WHEN s.avg_sales > 1000 THEN 'High Value'
        WHEN s.avg_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    SalesByGender s
ORDER BY 
    avg_sales DESC;
