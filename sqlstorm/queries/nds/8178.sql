
WITH sale_data AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_quantity) AS total_sales_quantity,
        SUM(ss.ss_sales_price) AS total_sales_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        store_sales ss
    JOIN 
        date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        income_band ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE 
        dd.d_year = 2001
        AND dd.d_moy IN (11, 12)
        AND cd.cd_gender = 'M'
    GROUP BY 
        ss.ss_store_sk
),
warehouse_data AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(s.total_sales_quantity) AS warehouse_total_sales_quantity,
        SUM(s.total_sales_price) AS warehouse_total_sales_price,
        SUM(s.total_net_profit) AS warehouse_total_net_profit
    FROM 
        warehouse w
    LEFT JOIN 
        sale_data s ON w.w_warehouse_sk = s.ss_store_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
)
SELECT 
    w.w_warehouse_name AS warehouse_name,
    w.warehouse_total_sales_quantity,
    w.warehouse_total_sales_price,
    w.warehouse_total_net_profit,
    (w.warehouse_total_net_profit / NULLIF(w.warehouse_total_sales_price, 0)) * 100 AS profit_margin_percentage
FROM 
    warehouse_data w
ORDER BY 
    w.warehouse_total_net_profit DESC
LIMIT 10;
