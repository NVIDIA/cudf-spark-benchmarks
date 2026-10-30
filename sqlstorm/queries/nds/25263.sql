
WITH CombinedSales AS (
    SELECT 
        ws_item_sk AS item_sk,
        ws_quantity AS quantity,
        ws_net_profit AS net_profit,
        'web_sales' AS sales_type
    FROM web_sales
    UNION ALL
    SELECT 
        cs_item_sk AS item_sk,
        cs_quantity AS quantity,
        cs_net_profit AS net_profit,
        'catalog_sales' AS sales_type
    FROM catalog_sales
    UNION ALL
    SELECT 
        ss_item_sk AS item_sk,
        ss_quantity AS quantity,
        ss_net_profit AS net_profit,
        'store_sales' AS sales_type
    FROM store_sales
),
TotalSales AS (
    SELECT 
        item_sk,
        SUM(quantity) AS total_quantity,
        SUM(net_profit) AS total_net_profit
    FROM CombinedSales
    GROUP BY item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_product_name,
        i_current_price,
        i_brand
    FROM item
),
SalesAnalysis AS (
    SELECT 
        id.i_item_id,
        id.i_product_name,
        id.i_current_price,
        id.i_brand,
        ts.total_quantity,
        ts.total_net_profit,
        CASE WHEN ts.total_net_profit > 0 THEN 'Profitable' ELSE 'Not Profitable' END AS profit_status,
        CASE 
            WHEN ts.total_quantity > 100 THEN 'High Demand'
            WHEN ts.total_quantity BETWEEN 50 AND 100 THEN 'Moderate Demand'
            ELSE 'Low Demand'
        END AS demand_level
    FROM TotalSales ts
    JOIN ItemDetails id ON ts.item_sk = id.i_item_sk
)
SELECT 
    profit_status,
    demand_level,
    COUNT(*) AS item_count,
    AVG(i_current_price) AS average_price
FROM SalesAnalysis
GROUP BY profit_status, demand_level
ORDER BY profit_status DESC, demand_level;
