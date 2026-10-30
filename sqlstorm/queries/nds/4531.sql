WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rnk
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001
    GROUP BY 
        ws.ws_sold_date_sk
),
top_sales AS (
    SELECT 
        s.ws_sold_date_sk,
        s.total_quantity,
        s.total_sales,
        s.total_profit,
        COALESCE(s2.total_profit, 0) AS previous_profit
    FROM 
        sales_summary s
    LEFT JOIN 
        sales_summary s2 ON s.ws_sold_date_sk = s2.ws_sold_date_sk - 1
    WHERE 
        s.rnk = 1
),
warehouse_info AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(DISTINCT s.s_store_sk) AS total_store_count,
        SUM(COALESCE(ss.total_sales, 0)) AS warehouse_sales
    FROM 
        warehouse w
    LEFT JOIN 
        store s ON w.w_warehouse_sk = s.s_company_id 
    LEFT JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk
    LEFT JOIN 
        sales_summary ss ON ws.ws_sold_date_sk = ss.ws_sold_date_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    w.w_warehouse_sk,
    w.total_store_count,
    w.warehouse_sales,
    ts.total_quantity,
    ts.total_sales,
    ts.total_profit,
    ts.previous_profit,
    (CASE 
        WHEN ts.previous_profit = 0 THEN NULL
        ELSE (ts.total_profit - ts.previous_profit) / ts.previous_profit 
    END) AS profit_growth_rate
FROM 
    warehouse_info w
JOIN 
    top_sales ts ON w.warehouse_sales > 0
ORDER BY 
    w.warehouse_sales DESC;