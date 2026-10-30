
WITH ranked_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND i.i_current_price > 20.00
        AND ws.ws_sold_date_sk BETWEEN 2458499 AND 2458764
),
aggregated_sales AS (
    SELECT 
        r.ws_sold_date_sk,
        SUM(r.ws_quantity) AS total_quantity,
        AVG(r.ws_sales_price) AS avg_sales_price,
        SUM(r.ws_net_paid) AS total_net_paid
    FROM 
        ranked_sales r
    WHERE 
        r.rank <= 5
    GROUP BY 
        r.ws_sold_date_sk
)
SELECT 
    d.d_date AS sale_date,
    a.total_quantity,
    a.avg_sales_price,
    a.total_net_paid
FROM 
    aggregated_sales a
JOIN 
    date_dim d ON a.ws_sold_date_sk = d.d_date_sk
ORDER BY 
    d.d_date;
