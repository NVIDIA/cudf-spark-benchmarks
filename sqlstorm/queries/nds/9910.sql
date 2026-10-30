
WITH aggregated_sales AS (
    SELECT 
        ds.d_year AS year,
        ds.d_month_seq AS month,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ds.d_year BETWEEN 2020 AND 2022
        AND c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        ds.d_year, ds.d_month_seq
), ranked_sales AS (
    SELECT 
        year,
        month,
        total_quantity,
        total_sales,
        avg_net_profit,
        RANK() OVER (PARTITION BY year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        aggregated_sales
)
SELECT 
    r.year,
    r.month,
    r.total_quantity,
    r.total_sales,
    r.avg_net_profit
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.year ASC, r.month ASC;
