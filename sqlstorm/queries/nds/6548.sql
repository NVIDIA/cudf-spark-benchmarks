
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk
),
demographics_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd.cd_dep_count) AS avg_dep_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    ss.c_customer_sk,
    ss.total_sales,
    ss.total_orders,
    ss.avg_net_profit,
    ds.customer_count,
    ds.avg_purchase_estimate,
    ds.avg_dep_count
FROM 
    sales_summary ss
JOIN 
    demographics_summary ds ON ss.c_customer_sk = ds.customer_count
WHERE 
    ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY 
    ss.total_sales DESC;
