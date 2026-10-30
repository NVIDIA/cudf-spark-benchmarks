
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_credit_rating
),
DemographicAnalysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        COUNT(cs.c_customer_id) AS customer_count,
        AVG(cs.total_sales) AS avg_sales,
        AVG(cs.order_count) AS avg_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.cd_gender = cd.cd_gender AND cs.cd_marital_status = cd.cd_marital_status
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_credit_rating
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.cd_education_status,
    da.cd_credit_rating,
    da.customer_count,
    da.avg_sales,
    da.avg_orders,
    CASE 
        WHEN da.avg_sales > 1000 THEN 'High Value'
        WHEN da.avg_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    DemographicAnalysis da
ORDER BY 
    da.avg_sales DESC;
