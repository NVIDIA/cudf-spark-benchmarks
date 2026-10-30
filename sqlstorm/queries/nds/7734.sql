WITH SalesAnalysis AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001 AND 
        d.d_moy IN (11, 12)  
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.*,
        sa.total_sales,
        sa.total_orders,
        sa.total_discount,
        sa.avg_net_profit,
        sa.unique_items_purchased,
        RANK() OVER (ORDER BY sa.total_sales DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        SalesAnalysis sa ON c.c_customer_id = sa.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    tc.total_discount,
    tc.avg_net_profit,
    tc.unique_items_purchased
FROM 
    TopCustomers tc
WHERE 
    tc.sales_rank <= 10;