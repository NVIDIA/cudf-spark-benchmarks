
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpendingCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.total_orders,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                CustomerSales
        )
),
ReturnedProducts AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ProductSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold
    FROM 
        web_sales ws
    LEFT JOIN 
        inventory i ON ws.ws_item_sk = i.inv_item_sk
    WHERE 
        i.inv_quantity_on_hand > 0
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    hcc.c_customer_sk,
    hcc.c_first_name,
    hcc.c_last_name,
    p.i_item_desc,
    COALESCE(ps.total_sold, 0) AS total_sold,
    COALESCE(rp.total_returns, 0) AS total_returns,
    (COALESCE(ps.total_sold, 0) - COALESCE(rp.total_returns, 0)) AS net_sales
FROM 
    HighSpendingCustomers hcc
CROSS JOIN 
    item p
LEFT JOIN 
    ProductSales ps ON p.i_item_sk = ps.ws_item_sk
LEFT JOIN 
    ReturnedProducts rp ON p.i_item_sk = rp.sr_item_sk
WHERE 
    hcc.rank <= 10
ORDER BY 
    hcc.total_spent DESC, net_sales DESC;
