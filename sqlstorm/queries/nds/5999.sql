
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        d.d_year,
        d.d_month_seq,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_month_seq ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_sold_date_sk, d.d_year, d.d_month_seq, ws.ws_item_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        ri.d_year,
        ri.d_month_seq,
        ri.total_sales,
        ri.total_profit
    FROM 
        RankedSales ri
    WHERE 
        ri.rank <= 10
)
SELECT 
    ti.d_year,
    ti.d_month_seq,
    COUNT(DISTINCT ti.ws_item_sk) AS number_of_top_items,
    SUM(ti.total_sales) AS total_sales_for_top_items,
    SUM(ti.total_profit) AS total_profit_for_top_items
FROM 
    TopItems ti
GROUP BY 
    ti.d_year, ti.d_month_seq
ORDER BY 
    ti.d_year, ti.d_month_seq;
