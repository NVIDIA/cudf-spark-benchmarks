
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 50.00
),
TopSales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price,
        r.ws_quantity
    FROM 
        RankedSales r
    WHERE 
        r.price_rank <= 10
),
SalesSummary AS (
    SELECT 
        i.i_item_id,
        SUM(ts.ws_sales_price * ts.ws_quantity) AS total_revenue,
        COUNT(ts.ws_order_number) AS total_orders
    FROM 
        TopSales ts
    JOIN 
        item i ON ts.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
),
FinalSummary AS (
    SELECT 
        ss.i_item_id,
        ss.total_revenue,
        ss.total_orders,
        DENSE_RANK() OVER (ORDER BY ss.total_revenue DESC) AS revenue_rank
    FROM 
        SalesSummary ss
)
SELECT 
    fs.i_item_id,
    fs.total_revenue,
    fs.total_orders
FROM 
    FinalSummary fs
WHERE 
    fs.revenue_rank <= 5
ORDER BY 
    fs.total_revenue DESC;
