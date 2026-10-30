
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales
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
        COUNT(*) AS customer_count,
        SUM(total_sales) AS total_sales
    FROM 
        CustomerSales
    GROUP BY 
        cd_gender
),
SalesByMaritalStatus AS (
    SELECT 
        cd_marital_status,
        COUNT(*) AS customer_count,
        SUM(total_sales) AS total_sales
    FROM 
        CustomerSales
    GROUP BY 
        cd_marital_status
),
SalesSummary AS (
    SELECT 
        'Gender' AS category, 
        cd_gender AS category_value, 
        customer_count, 
        total_sales
    FROM 
        SalesByGender
    UNION ALL 
    SELECT 
        'Marital Status' AS category, 
        cd_marital_status AS category_value, 
        customer_count, 
        total_sales
    FROM 
        SalesByMaritalStatus
)
SELECT 
    category,
    category_value,
    customer_count,
    total_sales,
    total_sales / NULLIF(customer_count, 0) AS average_sales_per_customer
FROM 
    SalesSummary
ORDER BY 
    category, category_value;
