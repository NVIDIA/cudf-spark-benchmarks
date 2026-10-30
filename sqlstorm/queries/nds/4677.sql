
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 100
),
TopSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        SalesData
    WHERE 
        sales_rank <= 10
    GROUP BY 
        ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(ts.total_sales) AS customer_total_sales,
        SUM(ts.total_profit) AS customer_total_profit,
        COUNT(DISTINCT ts.ws_item_sk) AS unique_items_purchased
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        TopSales ts ON ci.c_customer_sk = ts.ws_item_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
)
SELECT 
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.customer_total_sales,
    s.customer_total_profit,
    s.unique_items_purchased,
    CASE 
        WHEN s.customer_total_profit > 1000 THEN 'High Value'
        WHEN s.customer_total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    SalesSummary s
ORDER BY 
    s.customer_total_sales DESC;
