
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_sales_price, 
        ws_quantity, 
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS ranking
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
),
TopSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM 
        RankedSales
    WHERE 
        ranking <= 5
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
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_credit_rating, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
    SUM(ts.total_sales) AS total_sales_value
FROM 
    CustomerInfo ci
JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    TopSales ts ON ws.ws_item_sk = ts.ws_item_sk
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_credit_rating
ORDER BY 
    total_sales_value DESC
LIMIT 20;
