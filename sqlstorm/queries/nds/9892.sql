
WITH revenue_summary AS (
    SELECT 
        d.d_year AS sales_year,
        i.i_category AS item_category,
        SUM(ws.ws_ext_sales_price) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, i.i_category
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    rs.sales_year,
    rs.item_category,
    rs.total_revenue,
    rs.total_orders,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.customer_count,
    cs.avg_purchase_estimate
FROM 
    revenue_summary rs
JOIN 
    customer_summary cs ON (rs.total_revenue > 10000 AND cs.customer_count > 50)
ORDER BY 
    rs.sales_year, rs.total_revenue DESC;
