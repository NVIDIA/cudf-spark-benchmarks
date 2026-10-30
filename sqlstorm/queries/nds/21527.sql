WITH CustomerReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT sr_ticket_number) AS returns_count,
        MAX(sr_return_amt_inc_tax) AS max_return_value
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
ItemPerformance AS (
    SELECT
        iw.i_item_sk,
        iw.i_item_desc,
        iw.i_current_price,
        COALESCE(CR.total_return_quantity, 0) AS total_returns,
        COALESCE(CR.returns_count, 0) AS returns_count,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_profit) AS net_profit,
        CASE
            WHEN COUNT(DISTINCT ws.ws_order_number) = 0 THEN NULL
            ELSE SUM(ws.ws_net_profit) / COUNT(DISTINCT ws.ws_order_number)
        END AS avg_profit_per_sale
    FROM
        item iw
    LEFT JOIN
        web_sales ws ON iw.i_item_sk = ws.ws_item_sk
    LEFT JOIN
        CustomerReturns CR ON iw.i_item_sk = CR.sr_item_sk
    WHERE
        iw.i_current_price > (
            SELECT AVG(i_current_price) FROM item WHERE i_rec_start_date < cast('2002-10-01' as date)
        )
    GROUP BY
        iw.i_item_sk, iw.i_item_desc, iw.i_current_price, CR.total_return_quantity, CR.returns_count 
)
SELECT
    ip.i_item_sk,
    ip.i_item_desc,
    ip.i_current_price,
    ip.total_returns,
    ip.returns_count,
    ip.total_sales,
    ip.net_profit,
    ip.avg_profit_per_sale,
    COUNT(DISTINCT wr.wr_order_number) FILTER (WHERE wr_return_quantity > 0) AS web_returns_count,
    SUM(CASE WHEN wr_return_amt_inc_tax IS NULL THEN 0 ELSE wr_return_amt_inc_tax END) AS total_web_return_value
FROM
    ItemPerformance ip
LEFT JOIN
    web_returns wr ON ip.i_item_sk = wr.wr_item_sk
GROUP BY
    ip.i_item_sk, ip.i_item_desc, ip.i_current_price, ip.total_returns, ip.returns_count, 
    ip.total_sales, ip.net_profit, ip.avg_profit_per_sale
HAVING
    AVG(ip.avg_profit_per_sale) IS NOT NULL OR SUM(ip.total_returns) > 5
ORDER BY
    ip.total_sales DESC NULLS LAST,
    ip.avg_profit_per_sale DESC NULLS FIRST
LIMIT 100;