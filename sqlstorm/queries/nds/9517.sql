
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ws_ship_mode_sk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws_sold_date_sk, ws_ship_mode_sk
),
MonthlySales AS (
    SELECT 
        d_year,
        d_month_seq,
        sd.ws_ship_mode_sk,
        AVG(sd.total_sales) AS avg_sales,
        SUM(sd.total_orders) AS total_orders
    FROM 
        SalesData sd
    JOIN 
        date_dim dd ON sd.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_year, d_month_seq, sd.ws_ship_mode_sk
),
RankedSales AS (
    SELECT 
        d_year,
        d_month_seq,
        ws_ship_mode_sk,
        avg_sales,
        total_orders,
        RANK() OVER (PARTITION BY d_year ORDER BY avg_sales DESC) AS rank
    FROM 
        MonthlySales
)
SELECT 
    rs.d_year,
    rs.d_month_seq,
    sm.sm_ship_mode_id,
    rs.avg_sales,
    rs.total_orders
FROM 
    RankedSales rs
JOIN 
    ship_mode sm ON rs.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    rs.rank = 1
ORDER BY 
    rs.d_year, rs.d_month_seq;
