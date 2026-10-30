
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS orders_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        CS.orders_count,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM
        CustomerSales cs
    JOIN
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE
        cs.total_spent IS NOT NULL
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.orders_count,
    p.p_discount_active,
    CASE 
        WHEN tc.total_spent > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    COALESCE(sm.sm_type, 'Not Specified') AS shipping_method,
    CASE
        WHEN tc.orders_count > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS purchase_frequency
FROM
    TopCustomers tc
LEFT JOIN
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE
    tc.sales_rank <= 10
ORDER BY
    tc.total_spent DESC;
