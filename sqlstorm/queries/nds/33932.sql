
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    HAVING 
        SUM(ws_net_paid) > 100
), item_details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        COALESCE(NULLIF(i_color, ''), 'Unknown') AS item_color,
        CASE 
            WHEN i_formulation IS NULL THEN 'Unspecified'
            ELSE i_formulation 
        END AS formulation_type
    FROM 
        item
), sales_summary AS (
    SELECT 
        sd.ws_sold_date_sk,
        id.i_item_sk,
        id.i_item_desc,
        SUM(sd.total_sales) AS total_sales,
        AVG(id.i_current_price) AS average_price
    FROM 
        sales_data sd
    JOIN 
        item_details id ON sd.ws_item_sk = id.i_item_sk
    GROUP BY 
        sd.ws_sold_date_sk, id.i_item_sk, id.i_item_desc
), top_sales AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    d.d_date AS sales_date,
    ts.i_item_desc,
    ts.total_sales,
    CASE 
        WHEN ts.sales_rank <= 10 THEN 'Top Selling'
        ELSE 'Average'
    END AS sales_category
FROM 
    top_sales ts
JOIN 
    date_dim d ON ts.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = (SELECT MAX(d_year) FROM date_dim) 
    AND (d.d_holiday = 'Y' OR d.d_weekend = 'Y')
ORDER BY 
    ts.total_sales DESC;
