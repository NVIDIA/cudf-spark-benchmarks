
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating
    FROM 
        customer_demographics
),
CombinedData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        coalesce(d.cd_gender, 'N/A') AS gender,
        coalesce(d.cd_marital_status, 'N/A') AS marital_status,
        coalesce(d.cd_education_status, 'N/A') AS education_status,
        coalesce(d.cd_credit_rating, 'N/A') AS credit_rating,
        coalesce(s.total_quantity, 0) AS total_quantity,
        coalesce(s.total_sales, 0) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    gender,
    marital_status,
    education_status,
    credit_rating,
    COUNT(*) AS customer_count,
    SUM(total_quantity) AS total_quantity_sold,
    SUM(total_sales) AS total_sales_value,
    AVG(total_sales) AS average_sales_per_customer
FROM 
    CombinedData
GROUP BY 
    gender, marital_status, education_status, credit_rating
ORDER BY 
    total_sales_value DESC
LIMIT 10;
