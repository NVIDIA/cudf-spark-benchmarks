
WITH sales_stats AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        i.i_category = 'Electronics'
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.total_profit,
        RANK() OVER (ORDER BY ss.total_profit DESC) AS profit_rank
    FROM 
        sales_stats AS ss
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    ts.total_profit
FROM 
    top_sales AS ts
JOIN 
    item AS i ON ts.ws_item_sk = i.i_item_sk
WHERE 
    ts.profit_rank <= 10
ORDER BY 
    ts.total_profit DESC;
