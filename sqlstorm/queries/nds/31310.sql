
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
sales_analysis AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.total_sales) AS total_sales,
        COUNT(DISTINCT sd.ws_sold_date_sk) AS sale_days,
        AVG(sd.total_sales) AS avg_sales_per_day,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY SUM(sd.total_sales) DESC) AS sales_rank
    FROM 
        sales_data sd
    GROUP BY 
        sd.ws_item_sk
),
customer_sales AS (
    SELECT 
        cs.ss_item_sk,
        SUM(cs.ss_quantity) AS store_total_quantity,
        SUM(cs.ss_ext_sales_price) AS store_total_sales
    FROM 
        store_sales cs
    WHERE 
        cs.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        cs.ss_item_sk
)
SELECT 
    ia.i_item_id,
    ia.i_product_name,
    sa.total_quantity,
    sa.total_sales,
    sa.sale_days,
    sa.avg_sales_per_day,
    cs.store_total_quantity,
    cs.store_total_sales
FROM 
    sales_analysis sa
JOIN 
    customer_sales cs ON sa.ws_item_sk = cs.ss_item_sk
JOIN 
    item ia ON sa.ws_item_sk = ia.i_item_sk
WHERE 
    sa.sales_rank <= 10
    AND (cs.store_total_sales IS NOT NULL OR cs.store_total_quantity IS NOT NULL)
ORDER BY 
    sa.total_sales DESC;
