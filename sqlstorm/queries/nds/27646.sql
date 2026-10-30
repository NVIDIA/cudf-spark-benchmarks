WITH RankedItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY i.i_current_price DESC) AS price_rank,
        CASE 
            WHEN i.i_current_price < 10 THEN 'Low'
            WHEN i.i_current_price BETWEEN 10 AND 50 THEN 'Medium'
            ELSE 'High'
        END AS price_band
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
),
CustomerPurchaseStats AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_purchases,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cps.c_customer_id,
        cps.total_purchases,
        cps.total_spent,
        ROW_NUMBER() OVER (ORDER BY cps.total_spent DESC) AS customer_rank
    FROM 
        CustomerPurchaseStats cps
    WHERE 
        cps.total_spent > 100
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.i_current_price,
    tc.c_customer_id,
    tc.total_purchases,
    tc.total_spent
FROM 
    RankedItems ti
JOIN 
    TopCustomers tc ON ti.price_band = 
    (SELECT 
        CASE 
            WHEN AVG(i.i_current_price) < 10 THEN 'Low'
            WHEN AVG(i.i_current_price) BETWEEN 10 AND 50 THEN 'Medium'
            ELSE 'High'
        END AS avg_price_band
     FROM 
        RankedItems i 
     WHERE 
        i.price_rank <= 5
     )
WHERE 
    tc.customer_rank <= 10
ORDER BY 
    tc.total_spent DESC, ti.i_current_price ASC;