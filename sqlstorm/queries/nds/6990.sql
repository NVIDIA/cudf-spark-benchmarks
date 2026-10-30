
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_price
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) 
        AND i.i_brand = 'BrandX' 
        AND ws.ws_ship_mode_sk IN (SELECT sm.sm_ship_mode_sk FROM ship_mode sm WHERE sm.sm_type = 'AIR')
),
TopSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_net_profit
    FROM 
        RankedSales
    WHERE 
        rank_profit <= 5 OR rank_price <= 5
),
PerformanceMetrics AS (
    SELECT 
        i.i_item_id,
        SUM(ts.ws_sales_price) AS total_sales_price,
        SUM(ts.ws_net_profit) AS total_net_profit,
        COUNT(ts.ws_order_number) AS total_orders
    FROM 
        TopSales ts
    JOIN 
        item i ON ts.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
)

SELECT 
    pm.i_item_id,
    pm.total_sales_price,
    pm.total_net_profit,
    pm.total_orders,
    RANK() OVER (ORDER BY pm.total_net_profit DESC) AS rank_by_profit,
    RANK() OVER (ORDER BY pm.total_sales_price DESC) AS rank_by_sales
FROM 
    PerformanceMetrics pm
ORDER BY 
    pm.total_net_profit DESC, pm.total_sales_price DESC;
