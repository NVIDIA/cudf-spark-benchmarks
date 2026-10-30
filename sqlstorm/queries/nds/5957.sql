
WITH SalesData AS (
    SELECT 
        web_sales.ws_sold_date_sk, 
        web_sales.ws_item_sk, 
        SUM(web_sales.ws_quantity) AS total_quantity,
        SUM(web_sales.ws_ext_sales_price) AS total_sales,
        web_sales.ws_ship_mode_sk,
        date_dim.d_year, 
        item.i_brand,
        item.i_category
    FROM 
        web_sales 
    JOIN 
        date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    JOIN 
        item ON web_sales.ws_item_sk = item.i_item_sk
    WHERE 
        date_dim.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        web_sales.ws_sold_date_sk, 
        web_sales.ws_item_sk, 
        web_sales.ws_ship_mode_sk, 
        date_dim.d_year, 
        item.i_brand, 
        item.i_category
),
AggregatedSales AS (
    SELECT 
        d_year, 
        i_brand, 
        i_category, 
        SUM(total_quantity) AS total_quantity,
        SUM(total_sales) AS total_sales
    FROM 
        SalesData
    GROUP BY 
        d_year, 
        i_brand, 
        i_category
)
SELECT 
    d_year, 
    i_brand, 
    i_category, 
    total_quantity, 
    total_sales,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM 
    AggregatedSales
WHERE 
    total_sales > 10000
ORDER BY 
    d_year, 
    sales_rank;
