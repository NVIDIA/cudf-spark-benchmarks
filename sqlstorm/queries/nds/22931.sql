
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
CustomerReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns
    FROM
        web_returns
    GROUP BY
        wr_item_sk
), 
DetailedSales AS (
    SELECT 
        cs_item_sk,
        cs_ext_sales_price,
        cs_ext_discount_amt,
        cs_net_profit,
        (cs_ext_sales_price - cs_ext_discount_amt) AS net_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
)
SELECT 
    i.i_item_id,
    COALESCE(r.total_sales, 0) AS total_web_sales,
    COALESCE(rt.total_returns, 0) AS total_web_returns,
    COALESCE(d.net_sales, 0) AS total_catalog_net_sales,
    d.cs_ext_sales_price AS total_sales_tax,
    CASE 
        WHEN COALESCE(r.total_sales, 0) > 0 THEN 
            (COALESCE(d.cs_net_profit, 0) / COALESCE(r.total_sales, 0)) * 100 
        ELSE 0 
    END AS profit_margin_percentage,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY i.i_current_price DESC) AS price_rank,
    CASE 
        WHEN i.i_current_price > 100 THEN 'Premium'
        WHEN i.i_current_price <= 100 AND i.i_current_price > 50 THEN 'Mid-range'
        ELSE 'Budget'
    END AS price_category
FROM 
    item i
LEFT JOIN 
    RankedSales r ON i.i_item_sk = r.ws_item_sk
LEFT JOIN 
    CustomerReturns rt ON i.i_item_sk = rt.wr_item_sk
LEFT JOIN 
    DetailedSales d ON i.i_item_sk = d.cs_item_sk
WHERE 
    (i.i_formulation IS NULL OR i.i_formulation LIKE '%gel%')
    AND (i.i_size != 'small' OR i.i_color = 'red')
ORDER BY 
    profit_margin_percentage DESC NULLS LAST;
