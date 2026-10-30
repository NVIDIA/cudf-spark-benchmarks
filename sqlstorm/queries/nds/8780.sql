
WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_value,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.ws_item_sk
), 
TopSellingItems AS (
    SELECT 
        ss.ws_item_sk, 
        ss.total_quantity_sold,
        ss.total_sales_value,
        RANK() OVER (ORDER BY ss.total_sales_value DESC) AS sales_rank
    FROM 
        SalesSummary ss
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    tsi.total_quantity_sold,
    tsi.total_sales_value,
    tsi.sales_rank,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_order_count,
    SUM(cs.cs_net_profit) AS catalog_sales_net_profit
FROM 
    TopSellingItems tsi
JOIN 
    item ti ON tsi.ws_item_sk = ti.i_item_sk
LEFT JOIN 
    catalog_sales cs ON tsi.ws_item_sk = cs.cs_item_sk
WHERE 
    tsi.sales_rank <= 10
GROUP BY 
    ti.i_item_id, ti.i_item_desc, tsi.total_quantity_sold, tsi.total_sales_value, tsi.sales_rank
ORDER BY 
    tsi.sales_rank;
