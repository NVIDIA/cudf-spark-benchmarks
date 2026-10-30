
WITH RankedSales AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity_sold, 
        SUM(cs_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        r.r_reason_desc,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    JOIN 
        RankedSales rs ON sr.sr_item_sk = rs.cs_item_sk
    JOIN 
        item i ON i.i_item_sk = sr.sr_item_sk
    JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE 
        rs.rank <= 10
    GROUP BY 
        i.i_item_id, r.r_reason_desc
),
ReturnSummary AS (
    SELECT 
        i.i_item_id,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
        SUM(sr.sr_return_quantity) AS total_returned
    FROM 
        store_returns sr
    JOIN 
        item i ON i.i_item_sk = sr.sr_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    ti.i_item_id,
    ti.r_reason_desc,
    ti.total_returns,
    rs.return_transactions,
    rs.total_returned
FROM 
    TopItems ti
JOIN 
    ReturnSummary rs ON ti.i_item_id = rs.i_item_id
ORDER BY 
    ti.total_returns DESC, 
    rs.return_transactions DESC;
