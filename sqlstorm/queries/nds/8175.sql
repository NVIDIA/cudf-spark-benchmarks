
WITH RankedSales AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        dd.d_month_seq,
        dd.d_year,
        RANK() OVER (PARTITION BY dd.d_month_seq, dd.d_year ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.ws_ship_date_sk, dd.d_month_seq, dd.d_year
),
TopSales AS (
    SELECT 
        d_year,
        d_month_seq,
        total_quantity,
        total_sales
    FROM 
        RankedSales
    WHERE 
        rank <= 5
)
SELECT 
    d_year,
    d_month_seq,
    COUNT(*) AS number_of_top_sales,
    AVG(total_sales) AS avg_sales,
    SUM(total_quantity) AS total_quantity_sold
FROM 
    TopSales
GROUP BY 
    d_year, d_month_seq
ORDER BY 
    d_year, d_month_seq;
