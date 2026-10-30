WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2000)
    GROUP BY 
        c.c_customer_id
),
FilteredSales AS (
    SELECT 
        *,
        CASE 
            WHEN total_profit > 1000 THEN 'High Profit'
            WHEN total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END AS profit_category
    FROM 
        SalesData
),
TopCustomers AS (
    SELECT 
        f.c_customer_id,
        f.total_quantity,
        f.total_profit,
        f.order_count,
        f.profit_category,
        ROW_NUMBER() OVER (PARTITION BY f.profit_category ORDER BY f.total_profit DESC) AS rank
    FROM 
        FilteredSales f
)
SELECT 
    tc.c_customer_id,
    tc.total_quantity,
    tc.total_profit,
    tc.order_count,
    tc.profit_category,
    COALESCE(wa.w_warehouse_name, 'No Warehouse') AS associated_warehouse,
    (SELECT COUNT(*) FROM store s WHERE s.s_number_employees > 25) AS large_stores_count
FROM 
    TopCustomers tc
LEFT JOIN 
    warehouse wa ON tc.c_customer_id = CAST(wa.w_warehouse_id AS char(16))  
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_profit DESC;