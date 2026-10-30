
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
Demographics AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
CombinedData AS (
    SELECT 
        d.c_customer_sk AS ws_bill_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        s.total_sales,
        s.total_orders
    FROM 
        SalesData s
    LEFT JOIN 
        Demographics d ON s.ws_bill_customer_sk = d.c_customer_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COUNT(*) AS num_customers,
    SUM(total_sales) AS total_sales_amount,
    AVG(total_orders) AS avg_orders
FROM 
    CombinedData
GROUP BY 
    cd_gender,
    cd_marital_status,
    cd_education_status
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
