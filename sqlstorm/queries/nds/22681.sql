
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER(PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank,
        RANK() OVER(PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS net_paid_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT 
        r.ws_item_sk,
        COUNT(r.ws_order_number) AS total_sales,
        SUM(r.ws_sales_price) AS total_revenue,
        AVG(r.ws_net_paid) AS avg_net_paid
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 5
    GROUP BY 
        r.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
),
FinalResults AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_sales,
        ss.total_revenue,
        ss.avg_net_paid,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_returned, 0.00) AS total_returned,
        (ss.total_revenue - COALESCE(cr.total_returned, 0.00)) AS net_revenue
    FROM 
        SalesSummary ss
    LEFT JOIN 
        CustomerReturns cr ON ss.ws_item_sk = cr.sr_item_sk
)
SELECT 
    f.ws_item_sk,
    f.total_sales,
    f.total_revenue,
    f.avg_net_paid,
    f.total_returns,
    f.total_returned,
    f.net_revenue,
    CASE 
        WHEN f.net_revenue < 0 THEN 'Loss'
        WHEN f.net_revenue > 0 AND f.total_sales > 100 THEN 'High Profit'
        ELSE 'Moderate Profit / No Loss'
    END AS profit_analysis
FROM 
    FinalResults f
WHERE 
    NOT EXISTS (
        SELECT 
            1 
        FROM 
            customer c
        WHERE 
            c.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)
        AND 
            c.c_current_cdemo_sk IS NULL
    )
ORDER BY 
    f.net_revenue DESC
LIMIT 10;
