
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold, 
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales AS ws 
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk 
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        ws.ws_item_sk
), customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(ss.total_revenue) AS total_revenue_generated,
        COUNT(DISTINCT ss.total_orders) AS orders_count 
    FROM 
        customer AS c 
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    JOIN 
        sales_summary AS ss ON c.c_customer_sk = ss.ws_item_sk 
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
), rank_summary AS (
    SELECT 
        cus.c_customer_sk, 
        cus.cd_gender, 
        cus.cd_marital_status, 
        cus.total_revenue_generated, 
        cus.orders_count,
        RANK() OVER (PARTITION BY cus.cd_gender ORDER BY cus.total_revenue_generated DESC) AS revenue_rank
    FROM 
        customer_summary AS cus
)
SELECT 
    r.cd_gender, 
    r.cd_marital_status,
    AVG(r.total_revenue_generated) AS avg_revenue, 
    SUM(r.orders_count) AS total_orders,
    MAX(r.revenue_rank) AS highest_rank
FROM 
    rank_summary AS r 
WHERE 
    r.revenue_rank <= 10 
GROUP BY 
    r.cd_gender, r.cd_marital_status
ORDER BY 
    avg_revenue DESC;
