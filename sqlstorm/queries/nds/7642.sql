
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(ws_order_number) AS order_count,
        CAST(d_date AS DATE) AS sale_date
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        ws_bill_customer_sk, CAST(d_date AS DATE)
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
CombinedData AS (
    SELECT 
        s.ws_bill_customer_sk,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        c.cd_dep_count,
        c.cd_dep_employed_count,
        c.cd_dep_college_count,
        s.total_sales,
        s.total_discount,
        s.order_count,
        s.sale_date
    FROM 
        SalesData s
    JOIN 
        CustomerData c ON s.ws_bill_customer_sk = c.c_customer_sk
)
SELECT 
    cd_gender, 
    cd_marital_status, 
    cd_education_status,
    AVG(total_sales) AS avg_sales,
    AVG(total_discount) AS avg_discount,
    COUNT(DISTINCT ws_bill_customer_sk) AS customer_count
FROM 
    CombinedData
GROUP BY 
    cd_gender, 
    cd_marital_status, 
    cd_education_status
HAVING 
    AVG(total_sales) > 1000
ORDER BY 
    avg_sales DESC;
