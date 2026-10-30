
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_quantity, 
        ws.ws_net_paid, 
        i.i_brand, 
        i.i_category, 
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
), 
category_sales AS (
    SELECT 
        brand, 
        category, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid) AS total_revenue
    FROM (
        SELECT 
            i_brand AS brand, 
            i_category AS category, 
            ws_quantity, 
            ws_net_paid 
        FROM 
            sales_data
    ) AS raw_sales
    GROUP BY 
        brand, 
        category
), 
ranking AS (
    SELECT 
        brand, 
        category, 
        total_quantity, 
        total_revenue, 
        ROW_NUMBER() OVER (PARTITION BY brand ORDER BY total_revenue DESC) AS revenue_rank,
        ROW_NUMBER() OVER (PARTITION BY brand ORDER BY total_quantity DESC) AS quantity_rank
    FROM 
        category_sales
)

SELECT 
    brand, 
    category, 
    total_quantity, 
    total_revenue, 
    revenue_rank, 
    quantity_rank
FROM 
    ranking
WHERE 
    revenue_rank <= 5 OR quantity_rank <= 5
ORDER BY 
    brand, 
    total_revenue DESC;
