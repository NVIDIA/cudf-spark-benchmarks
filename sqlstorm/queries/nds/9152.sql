
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_net_profit) AS max_net_profit,
        MIN(ws.ws_net_profit) AS min_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id
), gender_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        SUM(ss.total_sales) AS total_sales_by_gender,
        AVG(ss.avg_sales_price) AS avg_sales_price_by_gender
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    gs.cd_gender,
    gs.num_customers,
    gs.total_sales_by_gender,
    gs.avg_sales_price_by_gender
FROM 
    gender_summary gs
ORDER BY 
    gs.total_sales_by_gender DESC;
