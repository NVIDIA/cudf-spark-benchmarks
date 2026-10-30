WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459930 AND 2459935  
    GROUP BY 
        ws_bill_customer_sk
),
high_value_customers AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        COUNT(cs_order_number) AS catalog_order_count
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 2459930 AND 2459935  
    GROUP BY 
        cs_bill_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        s.total_sales AS online_sales,
        h.total_catalog_sales AS catalog_sales
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_summary AS s ON c.c_customer_sk = s.ws_bill_customer_sk
    LEFT JOIN 
        high_value_customers AS h ON c.c_customer_sk = h.cs_bill_customer_sk
)
SELECT 
    c.c_first_name AS FirstName,
    c.c_last_name AS LastName,
    c.cd_gender AS Gender,
    c.cd_marital_status AS MaritalStatus,
    c.cd_education_status AS EducationStatus,
    COALESCE(c.online_sales, 0) AS OnlineSales,
    COALESCE(c.catalog_sales, 0) AS CatalogSales
FROM 
    customer_details AS c
WHERE 
    (c.online_sales + c.catalog_sales) > 10000  
ORDER BY 
    (c.online_sales + c.catalog_sales) DESC
LIMIT 50;