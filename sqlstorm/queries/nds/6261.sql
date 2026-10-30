
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990 
        AND i.i_current_price > 20
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
sales_with_rank AS (
    SELECT 
        ss.ws_sold_date_sk,
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.total_discount,
        RANK() OVER (PARTITION BY ss.ws_item_sk ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
)
SELECT 
    sd.d_date,
    i.i_item_id,
    sr.total_quantity,
    sr.total_sales,
    sr.total_discount
FROM 
    sales_with_rank sr
JOIN 
    date_dim sd ON sr.ws_sold_date_sk = sd.d_date_sk
JOIN 
    item i ON sr.ws_item_sk = i.i_item_sk
WHERE 
    sr.sales_rank <= 5 
ORDER BY 
    sd.d_date ASC, sr.total_sales DESC;
