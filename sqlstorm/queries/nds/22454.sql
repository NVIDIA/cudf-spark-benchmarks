
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank_by_quantity,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_by_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopProfitingItems AS (
    SELECT 
        ws_item_sk,
        total_quantity_sold,
        total_net_profit
    FROM 
        RankedSales
    WHERE 
        rank_by_profit = 1
),
TopSellingItems AS (
    SELECT 
        ws_item_sk,
        total_quantity_sold
    FROM 
        RankedSales
    WHERE 
        rank_by_quantity = 1
),
FinalResults AS (
    SELECT 
        tpi.ws_item_sk,
        COALESCE(tpi.total_net_profit / tpsi.total_quantity_sold, 0) AS profit_per_item,
        CASE 
            WHEN tpi.total_net_profit IS NULL THEN 'No Revenue'
            ELSE 'Revenue Generated'
        END AS revenue_status
    FROM 
        TopProfitingItems tpi
    FULL OUTER JOIN 
        TopSellingItems tpsi ON tpi.ws_item_sk = tpsi.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    fr.profit_per_item,
    fr.revenue_status,
    CASE 
        WHEN fr.profit_per_item IS NULL THEN 'Unknown'
        ELSE 'Known'
    END AS profit_status,
    CONCAT('Item: ', i.i_item_desc, ' has a profit per item of ', COALESCE(CAST(fr.profit_per_item AS STRING), 'N/A')) AS profit_details,
    COUNT(cd_dep_count) AS demographic_count
FROM 
    FinalResults fr
JOIN 
    item i ON fr.ws_item_sk = i.i_item_sk
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer WHERE c_first_name LIKE 'A%'))
GROUP BY 
    i.i_item_id, i.i_item_desc, fr.profit_per_item, fr.revenue_status
HAVING 
    COUNT(cd_dep_count) >= 
    (SELECT AVG(cd_dep_count) FROM customer_demographics WHERE cd_dep_count IS NOT NULL)
ORDER BY 
    profit_per_item DESC NULLS LAST;
