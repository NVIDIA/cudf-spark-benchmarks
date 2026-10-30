
WITH sales_data AS (
    SELECT 
        web.ws_sold_date_sk,
        SUM(web.ws_quantity) AS total_quantity,
        SUM(web.ws_net_paid) AS total_sales,
        COUNT(DISTINCT web.ws_order_number) AS total_orders,
        i.i_category
    FROM 
        web_sales AS web
    JOIN 
        item AS i ON web.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim AS d ON web.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2021
    GROUP BY 
        web.ws_sold_date_sk, i.i_category
), category_analysis AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.i_category,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (PARTITION BY sd.i_category ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data AS sd
)
SELECT 
    d1.d_date AS sale_date,
    ca.i_category,
    ca.total_quantity,
    ca.total_sales,
    ca.sales_rank
FROM 
    category_analysis AS ca
JOIN 
    date_dim AS d1 ON ca.ws_sold_date_sk = d1.d_date_sk
WHERE 
    ca.sales_rank <= 5
ORDER BY 
    d1.d_date, ca.i_category;
