WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        wd.d_year AS sales_year,
        ROW_NUMBER() OVER (PARTITION BY wd.d_year ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
    GROUP BY 
        ws.ws_item_sk, wd.d_year
),
returns_data AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
top_selling_items AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_returned_amount, 0) AS total_returned_amount
    FROM 
        sales_data sd
    LEFT JOIN 
        returns_data rd ON sd.ws_item_sk = rd.wr_item_sk
    WHERE 
        sd.sales_rank <= 10 
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    tsi.total_quantity,
    tsi.total_sales,
    tsi.total_returns,
    tsi.total_returned_amount,
    ROUND((tsi.total_returned_amount / NULLIF(tsi.total_sales, 0)) * 100, 2) AS return_percentage,
    CASE 
        WHEN ROUND((tsi.total_returned_amount / NULLIF(tsi.total_sales, 0)) * 100, 2) > 10 THEN 'High Return Rate'
        WHEN ROUND((tsi.total_returned_amount / NULLIF(tsi.total_sales, 0)) * 100, 2) BETWEEN 5 AND 10 THEN 'Moderate Return Rate'
        ELSE 'Low Return Rate'
    END AS return_rate_category
FROM 
    top_selling_items tsi
JOIN 
    item ti ON tsi.ws_item_sk = ti.i_item_sk
ORDER BY 
    tsi.total_sales DESC;