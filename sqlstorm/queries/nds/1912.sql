
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk AS item_sk,
        total_quantity_sold,
        total_sales
    FROM 
        SalesData
    WHERE 
        sales_rank <= 10
),
ReturnsData AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    ti.item_sk,
    ti.total_quantity_sold,
    ti.total_sales,
    COALESCE(tr.total_returns, 0) AS total_returns,
    COALESCE(tr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN ti.total_sales > 0 THEN 
            (COALESCE(tr.total_return_amount, 0) / ti.total_sales) * 100
        ELSE 
            NULL
    END AS return_percentage,
    ROW_NUMBER() OVER (ORDER BY ti.total_sales DESC) AS ranking
FROM 
    TopItems ti
LEFT JOIN 
    ReturnsData tr ON ti.item_sk = tr.sr_item_sk
ORDER BY 
    ti.total_sales DESC;
