
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2022
    GROUP BY 
        d.d_year, i.i_category
),
TopCategories AS (
    SELECT 
        d_year,
        i_category,
        total_quantity,
        total_net_profit,
        avg_sales_price,
        total_orders,
        RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS category_rank
    FROM 
        SalesSummary
)
SELECT 
    d_year,
    i_category,
    total_quantity,
    total_net_profit,
    avg_sales_price,
    total_orders
FROM 
    TopCategories
WHERE 
    category_rank <= 10
ORDER BY 
    d_year, total_net_profit DESC;
