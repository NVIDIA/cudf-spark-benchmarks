
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighProfitItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales,
        rs.total_profit,
        CASE 
            WHEN rs.total_profit > 1000 THEN 'High'
            WHEN rs.total_profit BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS profit_category
    FROM 
        RankedSales rs
    WHERE 
        rs.rn = 1
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(*) AS total_store_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
),
CombinedSales AS (
    SELECT 
        hpi.ws_item_sk,
        hpi.total_quantity,
        hpi.total_sales,
        hpi.total_profit,
        COALESCE(sss.total_store_profit, 0) AS total_store_profit,
        COALESCE(sss.total_store_sales, 0) AS total_store_sales
    FROM 
        HighProfitItems hpi
    LEFT JOIN 
        StoreSalesSummary sss ON hpi.ws_item_sk = sss.ss_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.ws_item_sk,
    cs.total_quantity,
    cs.total_sales,
    cs.total_profit,
    cs.total_store_profit,
    CASE 
        WHEN cs.total_store_profit > cs.total_profit THEN 'Store Wins'
        WHEN cs.total_store_profit < cs.total_profit THEN 'Web Wins'
        ELSE 'Equal' 
    END AS profit_winner
FROM 
    customer c
JOIN 
    CombinedSales cs ON c.c_customer_sk = cs.ws_item_sk
WHERE 
    cs.total_sales > 1000 
    AND c.c_current_cdemo_sk IS NOT NULL
ORDER BY 
    cs.total_profit DESC, 
    c.c_first_name ASC
LIMIT 100;
