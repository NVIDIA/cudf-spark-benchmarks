
WITH CTE_Sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CTE_Returns AS (
    SELECT 
        wr_item_sk,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_return_tax) AS total_return_tax
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
TotalSales AS (
    SELECT 
        s.ws_item_sk,
        COALESCE(s.total_quantity, 0) AS total_sales,
        COALESCE(s.total_net_paid, 0) AS total_net_paid,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_return_tax, 0) AS total_return_tax
    FROM 
        (SELECT 
            ws_item_sk,
            SUM(ws_quantity) AS total_quantity,
            SUM(ws_net_paid) AS total_net_paid
        FROM 
            web_sales
        GROUP BY 
            ws_item_sk) s
    FULL OUTER JOIN 
        CTE_Returns r ON s.ws_item_sk = r.wr_item_sk
),
FinalReport AS (
    SELECT 
        t.ws_item_sk,
        t.total_sales,
        t.total_net_paid,
        t.total_returns,
        t.total_return_amount,
        t.total_return_tax,
        (t.total_net_paid - t.total_return_amount) AS net_profit,
        100 * (CASE WHEN t.total_sales = 0 THEN NULL ELSE CAST(t.total_returns AS DECIMAL) / t.total_sales END) AS return_rate,
        CASE 
            WHEN t.total_sales > 0 THEN 'Positive Sales'
            WHEN t.total_sales = 0 AND t.total_returns = 0 THEN 'No Activity'
            ELSE 'Negative Sales' 
        END AS sales_status
    FROM 
        TotalSales t
)
SELECT 
    *,
    (SELECT COUNT(*) FROM FinalReport) AS total_records
FROM 
    FinalReport
WHERE 
    COALESCE(net_profit, 0) > 0 
    OR return_rate > 10
ORDER BY 
    sales_status DESC, total_net_paid DESC
LIMIT 100;
