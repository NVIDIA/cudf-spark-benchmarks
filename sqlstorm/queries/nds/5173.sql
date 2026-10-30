
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), DailySales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_sales_price) AS total_daily_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
), TopProducts AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.order_count,
    cs.avg_order_value,
    ds.d_date,
    ds.total_daily_sales,
    ds.total_orders,
    ds.unique_customers,
    tp.i_item_id,
    tp.total_quantity_sold
FROM 
    CustomerSales cs
JOIN 
    DailySales ds ON ds.total_daily_sales > 1000
JOIN 
    TopProducts tp ON tp.total_quantity_sold > 50
WHERE 
    cs.total_sales > 5000
ORDER BY 
    cs.total_sales DESC, ds.d_date DESC;
