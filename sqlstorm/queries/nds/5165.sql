
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS average_price,
        COUNT(ws.ws_order_number) AS order_count,
        CASE 
            WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Other'
        END AS gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Unknown'
        END AS marital_status,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS unique_ship_dates
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
Customer_Aggregate AS (
    SELECT 
        gender,
        marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(total_sales) AS total_sales,
        AVG(total_sales) AS average_sales_per_customer,
        AVG(order_count) AS average_orders_per_customer,
        SUM(unique_ship_dates) AS total_unique_ship_dates
    FROM 
        Customer_Sales
    GROUP BY 
        gender, marital_status
)
SELECT 
    gender,
    marital_status,
    customer_count,
    total_sales,
    average_sales_per_customer,
    average_orders_per_customer,
    total_unique_ship_dates
FROM 
    Customer_Aggregate
ORDER BY 
    total_sales DESC;
