
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(CASE WHEN s.ss_quantity > 0 THEN 1 END) AS purchases
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cs.cd_gender, 
    cs.cd_marital_status, 
    SUM(sd.total_quantity) AS total_quantity,
    SUM(sd.total_sales) AS total_sales,
    SUM(sd.total_discount) AS total_discount,
    SUM(sd.total_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers
FROM 
    SalesData sd
JOIN 
    CustomerStats cs ON sd.ws_item_sk = cs.c_customer_sk
GROUP BY 
    cs.cd_gender, cs.cd_marital_status
ORDER BY 
    total_sales DESC 
LIMIT 10;
