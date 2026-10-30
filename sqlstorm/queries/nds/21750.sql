
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_net_paid > 0 
        AND ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        rs.ws_item_sk, 
        SUM(rs.ws_net_paid) AS total_net_paid,
        COUNT(rs.ws_quantity) AS total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 5
    GROUP BY 
        rs.ws_item_sk
),
ItemWithReturns AS (
    SELECT 
        i.i_item_sk,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_catalog_returns
    FROM 
        item i
    LEFT JOIN 
        store_returns sr ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN 
        catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    isw.ws_item_sk,
    isw.total_net_paid,
    isw.total_sales,
    ir.total_returns,
    ir.total_catalog_returns,
    (COALESCE(ir.total_returns, 0) + COALESCE(ir.total_catalog_returns, 0)) / NULLIF(isw.total_sales, 0) AS return_rate,
    CASE 
        WHEN (COALESCE(ir.total_returns, 0) + COALESCE(ir.total_catalog_returns, 0)) > 0
        THEN 'High Return'
        ELSE 'Low Return' 
    END AS return_category
FROM 
    TopSales isw
JOIN 
    ItemWithReturns ir ON isw.ws_item_sk = ir.i_item_sk
WHERE 
    (ir.total_returns + ir.total_catalog_returns) IS NOT NULL
ORDER BY 
    return_rate DESC;
