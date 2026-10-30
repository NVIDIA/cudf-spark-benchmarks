
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        c.c_customer_id, d.d_year
),
demographics_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(cs.cs_order_number) AS total_orders_by_demo,
        c.c_customer_id
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, c.c_customer_id
),
final_summary AS (
    SELECT 
        ss.c_customer_id,
        ss.total_quantity,
        ss.total_net_paid,
        ss.avg_sales_price,
        ss.total_orders,
        ds.cd_gender,
        ds.cd_marital_status
    FROM 
        sales_summary ss
    LEFT JOIN 
        demographics_summary ds ON ss.c_customer_id = ds.c_customer_id
)
SELECT 
    fs.c_customer_id,
    fs.total_quantity,
    fs.total_net_paid,
    fs.avg_sales_price,
    fs.total_orders,
    fs.cd_gender,
    fs.cd_marital_status
FROM 
    final_summary fs
ORDER BY 
    fs.total_net_paid DESC
LIMIT 100;
