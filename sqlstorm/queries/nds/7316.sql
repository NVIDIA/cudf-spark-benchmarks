
WITH SalesData AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ItemDetails AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_brand,
        i_category
    FROM 
        item
),
RankedSales AS (
    SELECT
        sd.ws_item_sk,
        id.i_item_id,
        id.i_brand,
        id.i_category,
        sd.total_quantity,
        sd.total_sales,
        sd.total_orders,
        RANK() OVER (PARTITION BY id.i_category ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        SalesData sd
    JOIN 
        ItemDetails id ON sd.ws_item_sk = id.i_item_sk
)
SELECT 
    rs.i_category,
    rs.i_brand,
    COUNT(*) AS item_count,
    SUM(rs.total_quantity) AS total_quantity,
    SUM(rs.total_sales) AS total_sales,
    AVG(rs.total_orders) AS avg_orders_per_item
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
GROUP BY 
    rs.i_category, rs.i_brand
ORDER BY 
    total_sales DESC;
