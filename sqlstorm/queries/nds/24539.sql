
WITH Revenue AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ReturnStats AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        r.ws_item_sk,
        r.total_sales,
        COALESCE(rt.total_returns, 0) AS total_returns,
        COALESCE(rt.return_amount, 0) AS return_amount,
        (r.total_sales - COALESCE(rt.return_amount, 0)) AS net_revenue
    FROM 
        Revenue r
    LEFT JOIN 
        ReturnStats rt ON r.ws_item_sk = rt.wr_item_sk
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY net_revenue DESC) AS revenue_rank
    FROM 
        SalesWithReturns
)
SELECT 
    s.ws_item_sk,
    s.total_sales,
    s.total_returns,
    s.return_amount,
    s.net_revenue,
    sd.i_item_desc,
    sd.i_brand,
    sd.i_category,
    CASE 
        WHEN s.net_revenue IS NULL OR s.net_revenue < 0 THEN 'Negative Revenue'
        WHEN s.net_revenue > 1000 THEN 'High Revenue'
        ELSE 'Moderate Revenue'
    END AS revenue_category
FROM 
    RankedSales s
JOIN 
    item sd ON s.ws_item_sk = sd.i_item_sk
WHERE 
    s.revenue_rank <= 10 
    AND sd.i_category IN (SELECT DISTINCT i_category FROM item WHERE i_manufact IN (SELECT DISTINCT i_manufact FROM item WHERE i_size IS NULL))
ORDER BY 
    s.net_revenue DESC;
