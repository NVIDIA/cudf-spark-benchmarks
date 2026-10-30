
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000 
        AND i.i_current_price BETWEEN 10.00 AND 100.00
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
), 
RankedSales AS (
    SELECT 
        sd.ws_sold_date_sk, 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_revenue,
        sd.avg_sales_price,
        sd.total_orders,
        RANK() OVER (PARTITION BY sd.ws_sold_date_sk ORDER BY sd.total_revenue DESC) AS revenue_rank
    FROM 
        SalesData sd
)
SELECT 
    dd.d_date AS sales_date,
    i.i_item_id,
    i.i_item_desc,
    rs.total_quantity,
    rs.total_revenue,
    rs.avg_sales_price,
    rs.total_orders
FROM 
    RankedSales rs
JOIN 
    date_dim dd ON rs.ws_sold_date_sk = dd.d_date_sk
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
WHERE 
    rs.revenue_rank <= 5
ORDER BY 
    sales_date, total_revenue DESC;
