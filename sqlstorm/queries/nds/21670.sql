
WITH  PriceTrend AS (
    SELECT 
        i_item_sk, 
        i_item_desc, 
        i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY i_rec_start_date) AS rn
    FROM 
        item
    WHERE 
        i_rec_start_date IS NOT NULL
), 
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        d_year
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws_item_sk, d_year
), 
ReturnsData AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
)
SELECT 
    pt.i_item_sk,
    pt.i_item_desc,
    pt.i_current_price,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(rd.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(rd.total_return_amt, 0) AS total_return_amt,
    (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return_amt, 0)) AS net_sales,
    CASE 
        WHEN pt.i_current_price <= 0 THEN NULL
        ELSE (COALESCE(sd.total_sales, 0) / NULLIF(pt.i_current_price, 0))
    END AS sales_to_price_ratio,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return_amt, 0)) DESC) AS sales_rank
FROM 
    PriceTrend pt
LEFT JOIN 
    SalesData sd ON pt.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    ReturnsData rd ON pt.i_item_sk = rd.sr_item_sk
WHERE 
    (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return_amt, 0) > 0 OR pt.i_current_price < 10.00)
    AND pt.rn = 1
ORDER BY 
    sales_rank
LIMIT 100;
