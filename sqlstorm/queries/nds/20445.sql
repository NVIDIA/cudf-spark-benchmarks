WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1970 AND 1990
        AND (ws.ws_net_paid > 50 OR ws.ws_net_profit < 0)
    GROUP BY
        ws.ws_item_sk, ws.ws_order_number
),
FilteredReturns AS (
    SELECT
        sr.sr_item_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns
    FROM
        store_returns sr
    WHERE
        sr.sr_return_quantity > 0
        AND sr.sr_return_amt_inc_tax > (
            SELECT COALESCE(AVG(cr_return_amt_inc_tax), 0)
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = sr.sr_item_sk
        )
    GROUP BY
        sr.sr_item_sk
),
FinalReport AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_net_profit,
        COALESCE(f.total_returns, 0) AS total_returns,
        (r.total_net_profit - COALESCE(f.total_returns, 0) * 10) AS adjusted_net_profit, 
        CASE 
            WHEN r.total_net_profit > 1000 THEN 'High Profit'
            WHEN r.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END AS profit_category
    FROM 
        RankedSales r
    LEFT JOIN 
        FilteredReturns f ON r.ws_item_sk = f.sr_item_sk
    WHERE 
        r.rn = 1
)
SELECT
    f.ws_item_sk,
    f.total_quantity,
    f.total_net_profit,
    f.total_returns,
    f.adjusted_net_profit,
    f.profit_category,
    CASE 
        WHEN f.adjusted_net_profit IS NULL THEN 'No Profit Recorded'
        ELSE 'Profit Available'
    END AS status
FROM 
    FinalReport f
ORDER BY 
    f.adjusted_net_profit DESC
LIMIT 100;