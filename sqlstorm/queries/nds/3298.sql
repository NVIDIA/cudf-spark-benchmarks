
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk, sr_item_sk
),
HighValueItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_paid) > 1000
),
ReturnRate AS (
    SELECT 
        r.rank,
        hvi.ws_item_sk,
        COALESCE(r.total_returned, 0) AS total_returned,
        hvi.total_sales,
        CASE 
            WHEN hvi.total_sales > 0 THEN 
                ROUND(COALESCE(r.total_returned, 0) * 1.0 / hvi.total_sales, 4)
            ELSE 0
        END AS return_rate
    FROM 
        RankedReturns r
    RIGHT JOIN 
        HighValueItems hvi ON r.sr_item_sk = hvi.ws_item_sk
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    item.i_current_price,
    rr.rank,
    rr.total_returned,
    rr.total_sales,
    rr.return_rate
FROM 
    ReturnRate rr
JOIN 
    item ON rr.ws_item_sk = item.i_item_sk
WHERE 
    rr.return_rate > 0.1 OR rr.rank <= 10
ORDER BY 
    rr.return_rate DESC, rr.total_sales DESC;
