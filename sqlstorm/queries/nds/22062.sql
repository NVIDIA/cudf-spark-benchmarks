
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY COUNT(sr_ticket_number) DESC) AS rn
    FROM
        store_returns
    GROUP BY
        sr_returned_date_sk, sr_item_sk
),
TopReturns AS (
    SELECT
        rr.sr_item_sk,
        rr.return_count,
        rr.total_return_amt_inc_tax,
        i.i_item_desc
    FROM
        RankedReturns rr
    JOIN
        item i ON rr.sr_item_sk = i.i_item_sk
    WHERE
        rr.rn <= 5
),
CustomerPurchases AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_purchases,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_sk
)
SELECT
    t.i_item_desc,
    r.return_count,
    r.total_return_amt_inc_tax,
    cp.c_customer_sk,
    cp.total_purchases,
    cp.orders_count
FROM
    TopReturns r
FULL OUTER JOIN
    CustomerPurchases cp ON r.sr_item_sk = cp.c_customer_sk 
JOIN
    LATERAL (
        SELECT
            ws.ws_item_sk,
            SUM(ws.ws_net_paid_inc_tax) AS revenue
        FROM
            web_sales ws
        WHERE
            ws.ws_item_sk = r.sr_item_sk
        GROUP BY
            ws.ws_item_sk
        HAVING
            SUM(ws.ws_net_paid_inc_tax) > COALESCE(cp.total_purchases, 0)
    ) AS item_revenue ON r.sr_item_sk = item_revenue.ws_item_sk
JOIN
    item t ON r.sr_item_sk = t.i_item_sk
WHERE
    (cp.c_customer_sk IS NULL OR cp.total_purchases < 100)    
    AND (r.return_count IS NOT NULL OR r.total_return_amt_inc_tax IS NULL) 
ORDER BY
    r.total_return_amt_inc_tax DESC, cp.total_purchases ASC;
