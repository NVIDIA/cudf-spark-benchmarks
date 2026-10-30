
WITH  demographic_summary AS (
    SELECT 
        cd_marital_status,
        cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependencies,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cd_marital_status IN ('M', 'S')
    GROUP BY 
        cd_marital_status, cd_gender
),
sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales_total
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ds.cd_marital_status,
    ds.cd_gender,
    ds.customer_count,
    ds.avg_purchase_estimate,
    ss.d_year,
    ss.d_month_seq,
    ss.total_sales,
    ss.total_net_profit,
    ws.warehouse_sales_total
FROM 
    demographic_summary ds
JOIN 
    sales_summary ss ON ds.customer_count > 50
JOIN 
    warehouse_sales ws ON ws.warehouse_sales_total > 100000
ORDER BY 
    ds.cd_marital_status, ds.cd_gender, ss.d_year DESC, ss.d_month_seq ASC;
