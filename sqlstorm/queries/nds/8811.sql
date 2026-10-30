
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458820 AND 2458830  
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
DemographicSales AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count,
        AVG(cs.total_sales) AS avg_total_sales,
        AVG(cs.total_orders) AS avg_orders_per_customer,
        AVG(cs.avg_order_value) AS avg_order_value
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.cd_gender = cd.cd_gender AND cs.cd_marital_status = cd.cd_marital_status
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_education_status,
    ds.customer_count,
    ds.avg_total_sales,
    ds.avg_orders_per_customer,
    ds.avg_order_value,
    RANK() OVER (ORDER BY ds.avg_total_sales DESC) AS sales_rank
FROM 
    DemographicSales ds
ORDER BY 
    ds.avg_total_sales DESC
LIMIT 10;
