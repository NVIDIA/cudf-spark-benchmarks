WITH ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        COALESCE(NULLIF(i.i_current_price, 0), NULL) AS adjusted_price,
        i.i_category
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) 
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
),
CustomerReturns AS (
    SELECT 
        sr_count,
        sr_item_sk,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amount,
        COUNT(*) AS return_count
    FROM (
        SELECT 
            sr_item_sk,
            SUM(sr_return_quantity) AS sr_count,
            MAX(sr_return_amt) AS sr_return_amt
        FROM 
            store_returns
        GROUP BY 
            sr_item_sk
    ) AS sr
    GROUP BY 
        sr_count,
        sr_item_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_ext_sales_price) AS total_sales_value,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date)) - 1)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date)))
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        id.i_item_sk,
        id.i_item_id,
        id.i_item_desc,
        sd.total_sales_quantity,
        sd.total_sales_value,
        cd.return_count,
        RANK() OVER (ORDER BY sd.total_sales_value DESC) AS sales_rank
    FROM 
        ItemDetails id
    LEFT JOIN 
        SalesData sd ON id.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        CustomerReturns cd ON id.i_item_sk = cd.sr_item_sk
)
SELECT 
    t.i_item_id,
    t.i_item_desc,
    t.total_sales_quantity,
    t.total_sales_value,
    COALESCE(t.return_count, 0) AS return_count,
    CASE 
        WHEN t.return_count IS NULL THEN 'No Returns'
        WHEN t.return_count > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    RANK() OVER (ORDER BY t.total_sales_value DESC) AS rank_by_sales
FROM 
    TopItems t
WHERE 
    t.sales_rank <= 10
    AND (t.total_sales_value IS NOT NULL OR t.return_count IS NOT NULL)
ORDER BY 
    t.total_sales_value DESC;