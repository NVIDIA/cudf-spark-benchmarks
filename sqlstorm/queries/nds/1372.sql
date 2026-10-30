
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) as rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        SUM(RankedSales.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        RankedSales.rank <= 10
    GROUP BY 
        item.i_item_id, item.i_item_desc
)
SELECT 
    d.d_date,
    COALESCE(ss.total_net_profit, 0) AS web_sales_profit,
    COALESCE(cs.total_net_profit, 0) AS catalog_sales_profit,
    COALESCE(ss.total_net_profit, 0) - COALESCE(cs.total_net_profit, 0) AS profit_difference
FROM 
    date_dim d
LEFT JOIN (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk
) ss ON d.d_date_sk = ss.ws_sold_date_sk
FULL OUTER JOIN (
    SELECT 
        cs_sold_date_sk,
        SUM(cs_net_profit) AS total_net_profit
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_sold_date_sk
) cs ON d.d_date_sk = cs.cs_sold_date_sk
WHERE 
    d.d_year = 2023
ORDER BY 
    d.d_date;
