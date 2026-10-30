
WITH ItemSales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        i.i_item_id, i.i_item_desc
), TopItems AS (
    SELECT 
        i_item_id,
        i_item_desc,
        total_quantity,
        total_sales,
        avg_net_profit,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        ItemSales
)
SELECT 
    t.i_item_id,
    t.i_item_desc,
    t.total_quantity,
    t.total_sales,
    t.avg_net_profit,
    CASE 
        WHEN t.sales_rank <= 10 THEN 'Top 10'
        WHEN t.sales_rank <= 20 THEN 'Top 20'
        ELSE 'Below Top 20'
    END AS sales_category
FROM 
    TopItems t
ORDER BY 
    t.sales_rank;
