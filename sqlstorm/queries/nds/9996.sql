
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_item_sk) AS unique_items_sold
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31'
        )
    GROUP BY 
        ws_bill_customer_sk
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    AVG(sd.total_sales) AS avg_sales,
    AVG(sd.total_orders) AS avg_orders,
    SUM(sd.total_profit) AS total_profit,
    COUNT(DISTINCT cd.c_customer_sk) AS num_customers
FROM 
    SalesData sd
JOIN 
    CustomerData cd ON sd.ws_bill_customer_sk = cd.c_customer_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    total_profit DESC
LIMIT 10;
