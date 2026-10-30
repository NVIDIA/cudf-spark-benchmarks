
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_net_paid > 0
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
ItemDemographics AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_category,
        COALESCE(CAST(hd_income_band_sk AS STRING), 'Unknown') AS income_band
    FROM 
        item
    LEFT JOIN 
        household_demographics ON item.i_item_sk = household_demographics.hd_demo_sk
    WHERE 
        i_current_price IS NOT NULL
)
SELECT 
    i.i_product_name,
    i.i_category,
    SUM(rs.ws_quantity) AS total_sold,
    SUM(rs.ws_net_paid) AS total_revenue,
    COALESCE(cr.total_returned, 0) AS total_returns,
    cr.return_count,
    i.income_band,
    CASE 
        WHEN SUM(rs.ws_net_paid) > 1000 THEN 'High Revenue'
        WHEN SUM(rs.ws_net_paid) BETWEEN 500 AND 1000 THEN 'Medium Revenue'
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM 
    RankedSales rs
JOIN 
    ItemDemographics i ON rs.ws_item_sk = i.i_item_sk
LEFT JOIN 
    CustomerReturns cr ON rs.ws_item_sk = cr.wr_item_sk
WHERE 
    rs.rnk = 1
GROUP BY 
    i.i_product_name, i.i_category, cr.total_returned, cr.return_count, i.income_band
HAVING 
    SUM(rs.ws_quantity) > 10
ORDER BY 
    total_revenue DESC;
