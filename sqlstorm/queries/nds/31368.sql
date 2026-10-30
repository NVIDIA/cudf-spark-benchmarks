
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
daily_sales AS (
    SELECT 
        dd.d_date,
        ss.ws_item_sk,
        ss.total_sales,
        ss.order_count,
        ROW_NUMBER() OVER (PARTITION BY ss.ws_item_sk ORDER BY dd.d_date) AS daily_rank
    FROM 
        sales_summary ss
    JOIN 
        date_dim dd ON ss.ws_sold_date_sk = dd.d_date_sk
),
item_details AS (
    SELECT 
        i.i_item_sk, 
        i.i_product_name, 
        i.i_current_price, 
        i.i_brand,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_returns
    FROM 
        item i
    LEFT JOIN 
        store_returns sr ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN 
        web_returns wr ON i.i_item_sk = wr.wr_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name, i.i_current_price, i.i_brand
)
SELECT 
    ds.d_date,
    ids.i_item_sk,
    ids.i_product_name,
    ids.i_current_price,
    ids.i_brand,
    ds.total_sales,
    ds.order_count,
    ds.daily_rank,
    ids.total_returns,
    ids.total_web_returns,
    (ids.total_returns + ids.total_web_returns) AS total_return_quantity
FROM 
    daily_sales ds
JOIN 
    item_details ids ON ds.ws_item_sk = ids.i_item_sk
WHERE 
    (ds.total_sales > 100 OR ds.order_count > 2)
    AND ds.daily_rank <= 5
ORDER BY 
    ds.d_date DESC, ds.total_sales DESC;
