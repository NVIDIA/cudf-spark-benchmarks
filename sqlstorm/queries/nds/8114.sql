
WITH sales_summary AS (
    SELECT 
        d.d_year,
        i.i_category,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, i.i_category
),
customer_segment AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(s.total_sales) AS segment_sales,
        COUNT(DISTINCT s.total_orders) AS segment_orders
    FROM 
        sales_summary s
    JOIN 
        customer c ON s.total_orders = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.segment_sales,
    cs.segment_orders,
    RANK() OVER (ORDER BY cs.segment_sales DESC) AS sales_rank
FROM 
    customer_segment cs
ORDER BY 
    cs.segment_sales DESC
LIMIT 10;
