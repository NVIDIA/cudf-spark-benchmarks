
WITH SalesSummary AS (
    SELECT 
        ws.ws_web_site_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 AND
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_web_site_sk
),
WarehouseSummary AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(ws.ws_order_number) AS total_orders_warehouse,
        SUM(ws.ws_ext_sales_price) AS total_sales_warehouse,
        SUM(ws.ws_net_profit) AS total_profit_warehouse
    FROM 
        warehouse AS w
    JOIN 
        web_sales AS ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
),
CombinedSummary AS (
    SELECT 
        ss.ws_web_site_sk,
        ss.total_orders,
        ss.total_sales,
        ss.total_profit,
        COALESCE(ws.total_orders_warehouse, 0) AS total_orders_warehouse,
        COALESCE(ws.total_sales_warehouse, 0) AS total_sales_warehouse,
        COALESCE(ws.total_profit_warehouse, 0) AS total_profit_warehouse
    FROM 
        SalesSummary AS ss
    LEFT JOIN 
        WarehouseSummary AS ws ON ss.ws_web_site_sk = ws.w_warehouse_sk
)
SELECT 
    cs.ws_web_site_sk,
    cs.total_orders,
    cs.total_sales,
    cs.total_profit,
    cs.total_orders_warehouse,
    cs.total_sales_warehouse,
    cs.total_profit_warehouse
FROM 
    CombinedSummary AS cs
ORDER BY 
    cs.total_profit DESC
LIMIT 10;
