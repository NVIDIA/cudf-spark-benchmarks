
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_item_sk
), ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.avg_sales_price, 0) AS avg_sales_price
    FROM 
        item i
    LEFT JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
), RankData AS (
    SELECT 
        id.i_item_sk,
        id.i_item_id,
        id.i_item_desc,
        id.i_brand,
        id.i_category,
        id.i_current_price,
        id.total_quantity_sold,
        id.total_sales,
        id.avg_sales_price,
        RANK() OVER (PARTITION BY id.i_category ORDER BY id.total_sales DESC) AS sales_rank
    FROM 
        ItemDetails id
)
SELECT 
    rd.i_item_id,
    rd.i_item_desc,
    rd.i_brand,
    rd.total_quantity_sold,
    rd.total_sales,
    rd.avg_sales_price,
    rd.sales_rank,
    CASE 
        WHEN rd.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular'
    END AS sales_category
FROM 
    RankData rd
WHERE 
    rd.sales_rank <= 10
ORDER BY 
    rd.i_category, rd.sales_rank;
