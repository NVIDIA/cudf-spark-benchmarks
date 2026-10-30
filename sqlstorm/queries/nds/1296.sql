
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CostAndROI AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ss.ss_quantity) AS total_store_sales,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(ss.ss_wholesale_cost) AS total_store_cost,
        CASE 
            WHEN SUM(ss.ss_wholesale_cost) > 0 THEN 
                (SUM(ws.ws_net_profit) / SUM(ss.ss_wholesale_cost)) * 100 
            ELSE 
                NULL 
        END AS roi_percentage
    FROM 
        item i
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_current_price > 10
        AND i.i_category = 'Electronics'
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
ReturnStatistics AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_quantity) AS total_returned,
        AVG(sr_return_amt_inc_tax) AS avg_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    cs.i_item_sk,
    cs.i_item_desc,
    cs.total_store_sales,
    cs.total_web_profit,
    cs.total_store_cost,
    cs.roi_percentage,
    rs.return_count,
    rs.total_returned,
    rs.avg_return_amount
FROM 
    CostAndROI cs
LEFT JOIN 
    ReturnStatistics rs ON cs.i_item_sk = rs.sr_item_sk
WHERE 
    (cs.roi_percentage IS NULL OR cs.roi_percentage >= 0)
ORDER BY 
    cs.total_store_sales DESC,
    cs.total_web_profit DESC;
