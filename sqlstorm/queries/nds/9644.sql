
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_year, d.d_month_seq
),
promotion_summary AS (
    SELECT 
        p.p_promo_name AS promo_name,
        SUM(ws.ws_ext_sales_price) AS promo_sales,
        AVG(ws.ws_net_profit) AS promo_avg_profit
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name
),
customer_demographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS gender_count,
        SUM(ws.ws_ext_sales_price) AS gender_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ss.d_year,
    ss.d_month_seq,
    ss.total_sales,
    ss.total_orders,
    ss.total_quantity,
    ss.avg_net_profit,
    ss.unique_customers,
    ps.promo_name,
    ps.promo_sales,
    ps.promo_avg_profit,
    cd.cd_gender,
    cd.gender_count,
    cd.gender_sales
FROM 
    sales_summary ss
LEFT JOIN 
    promotion_summary ps ON ss.d_month_seq IN (SELECT DISTINCT d_month_seq FROM sales_summary) 
LEFT JOIN 
    customer_demographics cd ON ss.unique_customers = cd.gender_count
ORDER BY 
    ss.d_year, ss.d_month_seq;
