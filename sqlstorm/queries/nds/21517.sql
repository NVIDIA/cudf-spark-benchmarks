
WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT pd.d_date_sk 
            FROM date_dim pd 
            WHERE pd.d_year IN (2022, 2023)
        )
    GROUP BY 
        ws_item_sk
), StoreSalesSummary AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_store_quantity,
        SUM(ss_net_profit) AS total_store_profit
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
), CombinedSales AS (
    SELECT 
        ss.ws_item_sk,
        COALESCE(ss.total_quantity, 0) AS web_quantity,
        COALESCE(ss.total_profit, 0) AS web_profit,
        COALESCE(sst.total_store_quantity, 0) AS store_quantity,
        COALESCE(sst.total_store_profit, 0) AS store_profit
    FROM 
        SalesSummary ss
    FULL OUTER JOIN StoreSalesSummary sst ON ss.ws_item_sk = sst.ss_item_sk
), Ranking AS (
    SELECT 
        cs.ws_item_sk,
        cs.web_quantity,
        cs.web_profit,
        cs.store_quantity,
        cs.store_profit,
        (cs.web_profit + cs.store_profit) AS combined_profit,
        RANK() OVER (ORDER BY (cs.web_profit + cs.store_profit) DESC) AS combined_profit_rank
    FROM 
        CombinedSales cs
    WHERE 
        (cs.web_quantity > 0 OR cs.store_quantity > 0)
        AND (cs.web_profit IS NOT NULL OR cs.store_profit IS NOT NULL)
)
SELECT 
    r.ws_item_sk,
    r.web_quantity,
    r.web_profit,
    r.store_quantity,
    r.store_profit,
    r.combined_profit,
    CASE 
        WHEN r.combined_profit_rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS profit_category,
    CASE 
        WHEN r.combined_profit IS NULL OR r.combined_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM 
    Ranking r
WHERE 
    r.combined_profit_rank <= 50
ORDER BY 
    r.combined_profit DESC NULLS LAST;
