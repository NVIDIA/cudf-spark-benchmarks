
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        t.t_hour,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        t.t_hour BETWEEN 8 AND 17
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        w.w_warehouse_name, t.t_hour
),
customer_segment AS (
    SELECT 
        hd.hd_income_band_sk AS cd_income_band_sk,
        AVG(ss.total_quantity) AS avg_quantity,
        AVG(ss.total_sales) AS avg_sales,
        COUNT(DISTINCT ss.w_warehouse_name) AS warehouse_count
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.w_warehouse_name = c.c_last_name
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    ib.ib_lower_bound, 
    ib.ib_upper_bound, 
    cs.avg_quantity, 
    cs.avg_sales, 
    cs.warehouse_count
FROM 
    customer_segment cs
JOIN 
    income_band ib ON cs.cd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    ib.ib_lower_bound;
