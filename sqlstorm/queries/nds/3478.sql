
WITH SalesSummary AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        AVG(ws_net_paid_inc_tax) AS average_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
),
TopCustomers AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spend
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_paid) > 1000
),
InventoryStatus AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
OrderDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        COALESCE(cr.cr_return_quantity, 0) AS return_quantity,
        COALESCE(cr.cr_return_amount, 0) AS return_amount,
        ws.ws_bill_customer_sk,
        ws.ws_ship_date_sk
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_returns cr ON ws.ws_order_number = cr.cr_order_number AND ws.ws_item_sk = cr.cr_item_sk
)
SELECT 
    DATE_TRUNC('month', dd.d_date) AS order_month,
    COUNT(DISTINCT od.ws_order_number) AS total_orders,
    SUM(od.ws_quantity) AS total_items_sold,
    SUM(od.ws_net_paid) AS total_sales,
    SUM(od.return_quantity) AS total_returns,
    SUM(od.return_amount) AS total_return_amount,
    SUM(COALESCE(tt.total_spend, 0)) AS total_spend_by_top_customers,
    AVG(ss.average_order_value) AS average_order_value_per_day
FROM 
    SalesSummary ss
JOIN 
    OrderDetails od ON ss.ws_ship_date_sk = od.ws_ship_date_sk
JOIN 
    TopCustomers tt ON od.ws_bill_customer_sk = tt.ws_bill_customer_sk
JOIN 
    date_dim dd ON ss.ws_ship_date_sk = dd.d_date_sk
GROUP BY 
    order_month
ORDER BY 
    order_month DESC;
