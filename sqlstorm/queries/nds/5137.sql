
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        it.i_item_id,
        it.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item it ON rs.ws_item_sk = it.i_item_sk
    WHERE 
        rs.rank_sales <= 10
),
DateSales AS (
    SELECT
        dd.d_date,
        SUM(ws.ws_ext_sales_price) AS sales_by_date
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_date
    ORDER BY 
        dd.d_date
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ds.sales_by_date
FROM 
    TopItems ti
JOIN 
    DateSales ds ON ti.total_sales = ds.sales_by_date
ORDER BY 
    ti.total_sales DESC, ds.sales_by_date DESC
LIMIT 50;
