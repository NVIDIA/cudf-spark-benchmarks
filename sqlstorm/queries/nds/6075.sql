
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year IN (2022, 2023)
    GROUP BY 
        c.c_customer_id, d.d_year
),
demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cs.c_customer_id
    FROM 
        customer_demographics cd
    JOIN 
        customer cs ON cd.cd_demo_sk = cs.c_current_cdemo_sk
),
ranked_sales AS (
    SELECT 
        ss.c_customer_id,
        ss.d_year,
        ss.total_sales,
        ss.order_count,
        ss.avg_profit,
        RANK() OVER (PARTITION BY ss.d_year ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
)
SELECT 
    rs.c_customer_id,
    rs.total_sales,
    rs.order_count,
    rs.avg_profit,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_purchase_estimate,
    rs.d_year
FROM 
    ranked_sales rs
JOIN 
    demographics d ON rs.c_customer_id = d.c_customer_id
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.d_year, rs.total_sales DESC;
