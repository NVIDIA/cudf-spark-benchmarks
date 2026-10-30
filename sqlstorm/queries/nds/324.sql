
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank
    FROM
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_current_month = '1')
),
AggregateReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        AVG(wr.wr_return_amt) AS avg_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
StoreSales AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_sales,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM 
        store_sales ss
    LEFT JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    it.i_item_id,
    COALESCE(ss.total_sales, 0) AS sales_total,
    COALESCE(ar.total_returns, 0) AS returns_total,
    rs.ws_quantity AS last_quantity,
    rs.ws_net_paid AS last_net_paid,
    (COALESCE(ss.total_net_paid, 0) - COALESCE(ar.avg_return_amt, 0)) AS net_profit
FROM 
    item it
LEFT JOIN 
    StoreSales ss ON it.i_item_sk = ss.ss_item_sk
LEFT JOIN 
    AggregateReturns ar ON it.i_item_sk = ar.wr_item_sk
LEFT JOIN 
    RankedSales rs ON it.i_item_sk = rs.ws_item_sk AND rs.rank = 1
WHERE 
    (ss.total_sales IS NULL OR ss.total_sales > 50)
    AND (ar.total_returns IS NULL OR ar.total_returns < 5)
ORDER BY 
    net_profit DESC
LIMIT 100;
