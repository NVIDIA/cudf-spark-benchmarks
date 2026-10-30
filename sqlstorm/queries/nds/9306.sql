
WITH CustomerOrderStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_ordered
    FROM 
        customer c
    INNER JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cos.c_customer_sk,
        cos.total_orders,
        cos.total_sales,
        cos.avg_net_profit,
        cos.unique_items_ordered,
        ROW_NUMBER() OVER (ORDER BY cos.total_sales DESC) AS sales_rank
    FROM 
        CustomerOrderStats cos
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cc.cc_name AS call_center_name,
    wa.w_warehouse_name,
    tc.total_orders,
    tc.total_sales,
    tc.avg_net_profit,
    tc.unique_items_ordered
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_customer_sk = c.c_customer_sk
JOIN 
    call_center cc ON c.c_current_hdemo_sk = cc.cc_call_center_sk
JOIN 
    warehouse wa ON c.c_current_addr_sk = wa.w_warehouse_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
