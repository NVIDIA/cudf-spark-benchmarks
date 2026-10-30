
WITH aggregated_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        d_year
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws_item_sk, d_year
), ranked_sales AS (
    SELECT 
        asales.ws_item_sk,
        asales.total_quantity,
        asales.total_sales,
        asales.avg_net_profit,
        DENSE_RANK() OVER (PARTITION BY asales.d_year ORDER BY asales.total_sales DESC) AS sales_rank
    FROM 
        aggregated_sales asales
), top_items AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales,
        rs.avg_net_profit,
        rs.sales_rank
    FROM 
        ranked_sales rs
    WHERE 
        rs.sales_rank <= 10
), item_details AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ti.total_quantity,
        ti.total_sales,
        ti.avg_net_profit,
        ti.ws_item_sk
    FROM 
        top_items ti
    JOIN 
        item i ON ti.ws_item_sk = i.i_item_sk
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.total_quantity,
    id.total_sales,
    id.avg_net_profit,
    dt.d_year
FROM 
    item_details id
JOIN 
    aggregated_sales dt ON id.ws_item_sk = dt.ws_item_sk
ORDER BY 
    dt.d_year, id.total_sales DESC;
