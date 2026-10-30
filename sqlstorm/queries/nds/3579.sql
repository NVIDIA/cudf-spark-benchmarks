WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
        AND ws_quantity >= (SELECT AVG(ws_quantity) FROM web_sales)
),
top_sales AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_quantity) AS total_quantity,
        SUM(r.ws_sales_price * r.ws_quantity) AS total_sales
    FROM 
        ranked_sales r
    WHERE 
        r.rn <= 5
    GROUP BY 
        r.ws_item_sk
),
avg_sales AS (
    SELECT 
        i.i_item_sk,
        COALESCE(ts.total_quantity, 0) AS total_quantity,
        COALESCE(ts.total_sales, 0) AS total_sales,
        i.i_current_price,
        i.i_item_desc
    FROM 
        item i
    LEFT JOIN 
        top_sales ts ON i.i_item_sk = ts.ws_item_sk
),
final_report AS (
    SELECT 
        asl.i_item_desc,
        asl.total_quantity,
        asl.total_sales,
        CASE 
            WHEN asl.total_sales > 1000 THEN 'High Performer'
            WHEN asl.total_sales BETWEEN 500 AND 1000 THEN 'Moderate Performer'
            ELSE 'Low Performer'
        END AS performance_category
    FROM 
        avg_sales asl
    WHERE 
        asl.total_sales IS NOT NULL
)
SELECT 
    fr.performance_category,
    COUNT(*) AS item_count,
    SUM(fr.total_sales) AS total_sales_value,
    AVG(fr.total_quantity) AS avg_quantity_sold
FROM 
    final_report fr
GROUP BY 
    fr.performance_category
ORDER BY 
    total_sales_value DESC;