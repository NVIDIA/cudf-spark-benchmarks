WITH SalesSummary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '30' DAY)
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date))
    GROUP BY 
        cs_item_sk
),
TopSellingItems AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '30' DAY)
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date))
    GROUP BY 
        ss_item_sk
),
CombinedSales AS (
    SELECT 
        sb.cs_item_sk,
        COALESCE(sb.total_quantity, 0) AS catalog_quantity,
        COALESCE(sb.total_profit, 0) AS catalog_profit,
        COALESCE(tb.total_quantity, 0) AS store_quantity,
        COALESCE(tb.total_profit, 0) AS store_profit
    FROM 
        SalesSummary sb
    FULL OUTER JOIN 
        TopSellingItems tb ON sb.cs_item_sk = tb.ss_item_sk
),
FinalResults AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        cs.catalog_quantity,
        cs.catalog_profit,
        cs.store_quantity,
        cs.store_profit,
        (cs.catalog_profit + cs.store_profit) AS total_profit
    FROM 
        item 
    JOIN 
        CombinedSales cs ON item.i_item_sk = cs.cs_item_sk
    WHERE 
        (cs.catalog_quantity > 0 OR cs.store_quantity > 0)
)
SELECT 
    fr.i_item_id,
    fr.i_product_name,
    fr.catalog_quantity,
    fr.catalog_profit,
    fr.store_quantity,
    fr.store_profit,
    fr.total_profit
FROM 
    FinalResults fr
ORDER BY 
    fr.total_profit DESC
LIMIT 10;