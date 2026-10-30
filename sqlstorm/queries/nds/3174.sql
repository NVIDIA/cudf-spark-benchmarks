
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        wp.wp_creation_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws.ws_item_sk
),
Returns AS (
    SELECT
        cr.cr_item_sk,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_returns
    FROM
        catalog_returns cr
    GROUP BY
        cr.cr_item_sk
),
FinalSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        COALESCE(r.total_returns, 0) AS total_returns,
        (sd.total_net_profit - COALESCE(r.total_returns * (SELECT AVG(ws.ws_net_profit)
                                                              FROM web_sales ws 
                                                              WHERE ws.ws_item_sk = sd.ws_item_sk), 0)) AS net_profit_adjusted
    FROM
        SalesData sd
    LEFT JOIN Returns r ON sd.ws_item_sk = r.cr_item_sk
)
SELECT
    fs.ws_item_sk,
    fs.total_quantity,
    fs.total_net_profit,
    fs.total_returns,
    fs.net_profit_adjusted,
    ROW_NUMBER() OVER (ORDER BY fs.net_profit_adjusted DESC) AS rank
FROM
    FinalSales fs
WHERE
    fs.total_quantity > 0
ORDER BY
    rank
LIMIT 10;
