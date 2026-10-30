
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
    SUM(sd.total_quantity) AS total_sold,
    SUM(sd.total_sales) AS total_revenue,
    AVG(sd.total_profit) AS avg_profit_per_item
FROM 
    CustomerInfo ci
JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_item_sk
GROUP BY 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_education_status
ORDER BY 
    total_revenue DESC
LIMIT 10;
