
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopProducts AS (
    SELECT 
        ir.i_item_id,
        ir.i_item_desc,
        ir.i_current_price,
        rs.total_quantity,
        rs.total_sales,
        rs.ws_item_sk
    FROM 
        RankedSales rs
    JOIN 
        item ir ON rs.ws_item_sk = ir.i_item_sk
    WHERE 
        rs.sales_rank <= 10
),
SalesData AS (
    SELECT 
        tp.i_item_id,
        tp.total_quantity,
        tp.total_sales,
        da.d_year,
        da.d_month_seq,
        tp.ws_item_sk
    FROM 
        TopProducts tp
    JOIN 
        web_sales ws ON tp.ws_item_sk = ws.ws_item_sk
    JOIN 
        date_dim da ON ws.ws_sold_date_sk = da.d_date_sk
)
SELECT 
    sd.d_year,
    sd.d_month_seq,
    COUNT(sd.i_item_id) AS product_count,
    SUM(sd.total_sales) AS total_revenue,
    AVG(sd.total_sales) AS avg_revenue_per_product
FROM 
    SalesData sd
GROUP BY 
    sd.d_year, 
    sd.d_month_seq
ORDER BY 
    sd.d_year, 
    sd.d_month_seq;
