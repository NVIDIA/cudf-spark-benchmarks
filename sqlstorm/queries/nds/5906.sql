
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.ws_order_number, ws.ws_sold_date_sk
),
TopDailySales AS (
    SELECT 
        d.d_date AS sale_date,
        r.total_quantity,
        r.total_sales
    FROM 
        RankedSales r
    JOIN 
        date_dim d ON r.ws_sold_date_sk = d.d_date_sk
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    sale_date,
    AVG(total_quantity) AS avg_quantity,
    SUM(total_sales) AS total_sales_volume,
    COUNT(*) AS transaction_count
FROM 
    TopDailySales
GROUP BY 
    sale_date
ORDER BY 
    sale_date ASC;
