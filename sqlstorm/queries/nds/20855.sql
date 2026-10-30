
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn,
        SUM(ws.ws_net_paid) OVER (ORDER BY ws.ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS total_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_quantity > 0
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        r.ws_item_sk,
        r.ws_net_paid,
        COALESCE(c.total_returns, 0) AS total_returns,
        COALESCE(c.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(c.total_return_amt, 0) > 0 THEN (r.ws_net_paid - COALESCE(c.total_return_amt, 0))
            ELSE r.ws_net_paid
        END AS final_net_paid
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns c ON r.ws_item_sk = c.wr_item_sk
    WHERE 
        r.rn = 1
),
HighProfitItems AS (
    SELECT 
        s.ws_item_sk,
        s.final_net_paid,
        DENSE_RANK() OVER (ORDER BY s.final_net_paid DESC) AS profit_rank
    FROM 
        SalesWithReturns s
    WHERE 
        s.final_net_paid > 0
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    hp.final_net_paid,
    hp.profit_rank
FROM 
    HighProfitItems hp
JOIN 
    item ON hp.ws_item_sk = item.i_item_sk
WHERE 
    hp.profit_rank <= 10
UNION ALL
SELECT 
    'RETURN_SUMMARY' AS i_item_id,
    'Summary of Returns' AS i_item_desc,
    SUM(cl.total_return_amt) AS final_net_paid,
    NULL AS profit_rank
FROM 
    CustomerReturns cl
WHERE 
    cl.total_return_amt IS NOT NULL
GROUP BY 
    1, 2
HAVING 
    SUM(cl.total_return_amt) > 1000
ORDER BY 
    final_net_paid DESC;
