
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_ext_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_profit DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30
),
TopSales AS (
    SELECT 
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        RankedSales
    WHERE 
        rn <= 10
    GROUP BY 
        ws_order_number
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        t.total_sales,
        t.total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        TopSales t ON c.c_customer_sk = t.ws_order_number
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    COUNT(*) AS number_of_orders,
    SUM(ci.total_sales) AS total_sales_value,
    AVG(ci.total_profit) AS average_profit
FROM 
    CustomerInfo ci
GROUP BY 
    ci.c_customer_id, ci.cd_gender, ci.cd_marital_status, ci.cd_education_status
HAVING 
    SUM(ci.total_sales) > 1000
ORDER BY 
    total_sales_value DESC
LIMIT 100;
