
WITH sales_data AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        AVG(ws.ws_sales_price) AS average_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year >= 1998
        AND cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
        AND ws.ws_sold_time_sk IN (
            SELECT t.t_time_sk 
            FROM time_dim t 
            WHERE t.t_hour BETWEEN 9 AND 17
        )
    GROUP BY 
        d.d_year
),
warehouse_data AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
),
combined_data AS (
    SELECT 
        sd.d_year,
        sd.total_sales,
        sd.total_tax,
        sd.order_count,
        sd.unique_customers,
        sd.average_sales_price,
        wd.w_warehouse_name,
        wd.total_net_profit
    FROM 
        sales_data sd
    LEFT JOIN 
        warehouse_data wd ON sd.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
)
SELECT 
    d_year,
    total_sales,
    total_tax,
    order_count,
    unique_customers,
    average_sales_price,
    w_warehouse_name,
    total_net_profit
FROM 
    combined_data
ORDER BY 
    d_year, total_sales DESC
LIMIT 50;
