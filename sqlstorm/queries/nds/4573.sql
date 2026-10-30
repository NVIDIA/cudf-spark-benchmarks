
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        MIN(d.d_date) AS first_sale_date,
        MAX(d.d_date) AS last_sale_date,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk
), 
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        AVG(ws.ws_net_paid) AS average_spent,
        MAX(ws.ws_ext_sales_price) AS highest_single_purchase
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cs.average_spent,
        cs.highest_single_purchase,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerSummary cs
    WHERE 
        cs.total_spent > 1000
)
SELECT 
    s.ws_item_sk AS item_id,
    s.total_quantity,
    s.total_sales,
    cv.total_orders,
    cv.total_spent,
    cv.average_spent,
    cv.highest_single_purchase,
    CASE 
        WHEN avs.average_spent IS NULL THEN 'No Purchases'
        ELSE 'Has Purchases'
    END AS purchase_status
FROM 
    SalesData s
LEFT JOIN 
    HighValueCustomers cv ON s.ws_item_sk = cv.c_customer_sk
LEFT JOIN 
    (SELECT 
        AVG(total_spent) AS average_spent
     FROM 
        CustomerSummary) avs ON TRUE
WHERE 
    s.total_sales > 5000
ORDER BY 
    s.total_sales DESC;
