
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_ship_date_sk) AS active_days
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 90 AND (SELECT MAX(d_date_sk) FROM date_dim) 
    GROUP BY 
        ws_bill_customer_sk
), CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        c.cd_credit_rating,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(sd.active_days, 0) AS active_days
    FROM 
        CustomerData c
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
), AggregateStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS customer_count,
        AVG(total_sales) AS avg_sales,
        SUM(total_orders) AS total_orders
    FROM 
        CustomerSales
    GROUP BY 
        cd_gender, cd_marital_status
)

SELECT 
    cd_gender,
    cd_marital_status,
    customer_count,
    avg_sales,
    total_orders,
    ROUND(AVG(total_orders), 2) AS avg_orders_per_customer
FROM 
    AggregateStats
GROUP BY 
    cd_gender, cd_marital_status, customer_count, avg_sales, total_orders
ORDER BY 
    cd_gender, cd_marital_status;
