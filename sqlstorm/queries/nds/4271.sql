
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        cs.cs_net_profit AS catalog_net_profit,
        ss.ss_net_profit AS store_net_profit
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
    WHERE 
        ws.ws_quantity > 0
),
TotalSales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_sales_price) AS total_sales_price,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_net_profit,
        COALESCE(SUM(sd.catalog_net_profit), 0) AS total_catalog_net_profit,
        COALESCE(SUM(sd.store_net_profit), 0) AS total_store_net_profit
    FROM 
        SalesData sd
    GROUP BY 
        sd.ws_item_sk
)
SELECT 
    t.ws_item_sk,
    t.total_sales_price,
    t.total_quantity,
    t.total_net_profit,
    t.total_catalog_net_profit,
    t.total_store_net_profit,
    CASE 
        WHEN t.total_net_profit IS NULL THEN 'No Profit'
        WHEN t.total_net_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profitability_status,
    RANK() OVER (ORDER BY t.total_net_profit DESC) AS profit_rank
FROM 
    TotalSales t
ORDER BY 
    t.total_net_profit DESC
LIMIT 10;
