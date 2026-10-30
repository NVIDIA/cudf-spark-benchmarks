
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) AS max_price,
        MIN(ws.ws_sales_price) AS min_price,
        AVG(ws.ws_sales_price) AS avg_price,
        EXTRACT(YEAR FROM dd.d_date) AS sales_year,
        EXTRACT(MONTH FROM dd.d_date) AS sales_month
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws.ws_item_sk, EXTRACT(YEAR FROM dd.d_date), EXTRACT(MONTH FROM dd.d_date)
),
AggregatedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.sales_year,
        sd.sales_month,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.total_sales) AS total_sales,
        COUNT(DISTINCT sd.total_orders) AS unique_orders,
        COUNT(sd.ws_item_sk) AS total_entries
    FROM 
        SalesData AS sd
    GROUP BY 
        sd.ws_item_sk, sd.sales_year, sd.sales_month
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        CASE 
            WHEN i.i_current_price < 20 THEN 'Low'
            WHEN i.i_current_price BETWEEN 20 AND 100 THEN 'Medium'
            ELSE 'High'
        END AS price_category
    FROM 
        item AS i
)
SELECT 
    id.i_item_sk, 
    id.i_item_desc,
    id.i_brand,
    id.price_category,
    asales.sales_year,
    asales.sales_month,
    asales.total_quantity,
    asales.total_sales,
    asales.unique_orders,
    asales.total_entries
FROM 
    ItemDetails AS id
JOIN 
    AggregatedSales AS asales ON id.i_item_sk = asales.ws_item_sk
ORDER BY 
    asales.total_sales DESC, asales.sales_year DESC, asales.sales_month DESC
LIMIT 100;
