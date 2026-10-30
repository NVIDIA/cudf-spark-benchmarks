
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
), 
SalesAnalysis AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        sd.total_discount,
        sd.total_orders,
        RANK() OVER (PARTITION BY sd.ws_sold_date_sk ORDER BY sd.total_net_paid DESC) AS revenue_rank,
        DENSE_RANK() OVER (PARTITION BY sd.ws_sold_date_sk ORDER BY sd.total_quantity DESC) AS quantity_rank
    FROM 
        SalesData sd
)
SELECT 
    da.d_date AS Sales_Date,
    i.i_item_id,
    i.i_item_desc,
    sa.total_quantity,
    sa.total_net_paid,
    sa.total_discount,
    sa.total_orders,
    sa.revenue_rank,
    sa.quantity_rank
FROM 
    SalesAnalysis sa
JOIN 
    date_dim da ON sa.ws_sold_date_sk = da.d_date_sk
JOIN 
    item i ON sa.ws_item_sk = i.i_item_sk
WHERE 
    sa.revenue_rank <= 5 OR sa.quantity_rank <= 5
ORDER BY 
    Sales_Date, sa.total_net_paid DESC;
