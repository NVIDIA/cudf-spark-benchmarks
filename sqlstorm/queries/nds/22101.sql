
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_quantity,
        cs_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_net_profit DESC) AS rn
    FROM 
        catalog_sales
),
ItemInfo AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price
    FROM 
        item
    WHERE 
        i_rec_start_date <= (SELECT MAX(d_date) FROM date_dim WHERE d_current_year = 'Y')
),
HighProfitSales AS (
    SELECT 
        rs.cs_item_sk,
        SUM(rs.cs_sales_price) AS total_sales,
        SUM(rs.cs_quantity) AS total_quantity,
        MAX(rs.cs_sales_price) AS max_price,
        MIN(rs.cs_sales_price) AS min_price,
        (SUM(rs.cs_sales_price) - SUM(i.i_current_price * rs.cs_quantity)) AS profit
    FROM 
        RankedSales rs
    JOIN 
        ItemInfo i ON rs.cs_item_sk = i.i_item_sk
    WHERE 
        rs.rn <= 5
    GROUP BY 
        rs.cs_item_sk, i.i_item_desc
    HAVING 
        (SUM(rs.cs_sales_price) - SUM(i.i_current_price * rs.cs_quantity)) > 1000
),
AggregateReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalReport AS (
    SELECT 
        hp.cs_item_sk,
        ii.i_item_desc,
        hp.total_sales,
        hp.total_quantity,
        hp.max_price,
        hp.min_price,
        COALESCE(ar.return_count, 0) AS return_count,
        COALESCE(ar.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN ar.total_return_amt IS NULL THEN 'No Returns'
            ELSE 'Returns Exist'
        END AS return_status
    FROM 
        HighProfitSales hp
    JOIN 
        ItemInfo ii ON hp.cs_item_sk = ii.i_item_sk
    LEFT JOIN 
        AggregateReturns ar ON hp.cs_item_sk = ar.sr_item_sk
)
SELECT 
    f.*,
    CONCAT(CAST(f.max_price AS CHAR(10)), '-', CAST(f.min_price AS CHAR(10))) AS price_range,
    CASE 
        WHEN f.total_sales IS NULL THEN 'N/A'
        ELSE CASE 
            WHEN f.total_sales > 5000 THEN 'High'
            WHEN f.total_sales BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END
    END AS sales_category
FROM 
    FinalReport f
ORDER BY 
    f.total_sales DESC;
