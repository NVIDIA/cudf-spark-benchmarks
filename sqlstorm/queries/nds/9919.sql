
WITH sales_summary AS (
    SELECT 
        d.d_year AS sale_year,
        i.i_category AS item_category,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS average_sales_price,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year, i.i_category
),
category_performance AS (
    SELECT 
        sale_year,
        item_category,
        total_quantity_sold,
        total_sales,
        average_sales_price,
        unique_customers,
        RANK() OVER (PARTITION BY sale_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    sale_year,
    item_category,
    total_quantity_sold,
    total_sales,
    average_sales_price,
    unique_customers
FROM 
    category_performance
WHERE 
    sales_rank <= 10
ORDER BY 
    sale_year, total_sales DESC;
