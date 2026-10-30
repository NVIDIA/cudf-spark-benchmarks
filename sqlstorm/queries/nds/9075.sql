
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_ext_sales_price) AS avg_order_value,
        MAX(ws.ws_ext_sales_price) AS max_order_value,
        MIN(ws.ws_ext_sales_price) AS min_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales
    FROM 
        customer_demographics cd
    LEFT JOIN 
        catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating 
),
SalesPeriod AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_web_orders
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
)

SELECT 
    cs.c_customer_sk,
    cs.total_sales,
    cs.total_orders,
    cs.avg_order_value,
    cs.max_order_value,
    cs.min_order_value,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_credit_rating,
    d.total_catalog_sales,
    sp.d_year,
    sp.total_net_profit,
    sp.total_web_orders
FROM 
    CustomerSales cs
JOIN 
    Demographics d ON cs.c_customer_sk = d.cd_demo_sk
JOIN 
    SalesPeriod sp ON sp.total_net_profit > 10000
ORDER BY 
    cs.total_sales DESC
LIMIT 1000;
