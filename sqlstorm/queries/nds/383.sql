
WITH SalesSummary AS (
    SELECT 
        ws_web_site_sk,
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_web_site_sk, ws_item_sk
),
ReturnsSummary AS (
    SELECT 
        wr_web_page_sk,
        COUNT(wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns
    GROUP BY wr_web_page_sk
),
FinalSummary AS (
    SELECT 
        s.ws_web_site_sk,
        i.i_item_id,
        s.total_orders,
        s.total_quantity,
        s.total_net_paid,
        r.total_returns,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN s.total_quantity > 0 THEN (COALESCE(r.total_return_amt, 0) / s.total_quantity) * 100
            ELSE 0
        END AS return_rate_percentage,
        s.sales_rank
    FROM SalesSummary s
    JOIN item i ON s.ws_item_sk = i.i_item_sk
    LEFT JOIN ReturnsSummary r ON s.ws_web_site_sk = r.wr_web_page_sk
)
SELECT 
    f.ws_web_site_sk,
    f.i_item_id,
    f.total_orders,
    f.total_quantity,
    f.total_net_paid,
    f.total_returns,
    f.total_return_amt,
    f.return_rate_percentage
FROM FinalSummary f
WHERE f.sales_rank <= 10
ORDER BY f.total_net_paid DESC;
