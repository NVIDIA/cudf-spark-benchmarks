
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_paid) AS total_sales_amount
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
category_sales AS (
    SELECT 
        i.i_category,
        SUM(sd.total_sales_quantity) AS category_total_quantity,
        SUM(sd.total_sales_amount) AS category_total_amount
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_category
),
ranked_sales AS (
    SELECT 
        cs.i_category,
        cs.category_total_quantity,
        cs.category_total_amount,
        RANK() OVER (ORDER BY cs.category_total_amount DESC) AS sales_rank
    FROM 
        category_sales cs
)
SELECT 
    rs.i_category,
    rs.category_total_quantity,
    rs.category_total_amount,
    rs.sales_rank
FROM 
    ranked_sales rs
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.sales_rank;
