
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(ib.ib_lower_bound, 0) AS lower_income_band,
        COALESCE(ib.ib_upper_bound, 9999999) AS upper_income_band
    FROM 
        item i
    LEFT JOIN 
        household_demographics hd ON i.i_item_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), ReturnSummary AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), DetailedReturns AS (
    SELECT 
        ir.sr_item_sk,
        ir.total_returns,
        ir.total_return_amount,
        ir.total_return_tax,
        CASE 
            WHEN ir.total_returns IS NULL THEN 0 
            ELSE ir.total_return_amount / NULLIF(ir.total_returns, 0) 
        END AS avg_return_amount
    FROM 
        ReturnSummary ir
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    rs.total_sales,
    dr.total_returns,
    dr.avg_return_amount,
    id.lower_income_band,
    id.upper_income_band
FROM 
    ItemDetails id
LEFT JOIN 
    RankedSales rs ON id.i_item_sk = rs.ws_item_sk AND rs.rank_sales <= 10
LEFT JOIN 
    DetailedReturns dr ON id.i_item_sk = dr.sr_item_sk
WHERE 
    (id.lower_income_band >= 50000 OR id.upper_income_band <= 100000)
    AND (rs.total_sales IS NOT NULL OR dr.total_returns IS NOT NULL)
ORDER BY 
    rs.total_sales DESC, dr.avg_return_amount ASC
LIMIT 50;
