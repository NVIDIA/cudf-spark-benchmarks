
WITH CustomerAggregates AS (
    SELECT 
        c.c_customer_sk,
        c.c_last_name,
        c.c_first_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_purchased
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_last_name, c.c_first_name, cd.cd_gender, cd.cd_marital_status
),
HighSpenders AS (
    SELECT 
        cagg.c_customer_sk,
        cagg.c_last_name,
        cagg.c_first_name,
        cagg.total_spent
    FROM 
        CustomerAggregates cagg
    WHERE 
        cagg.total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                CustomerAggregates
        )
),
FrequentBuyers AS (
    SELECT 
        cagg.c_customer_sk,
        cagg.c_last_name,
        cagg.c_first_name,
        cagg.total_orders
    FROM 
        CustomerAggregates cagg
    WHERE 
        cagg.total_orders > 5
),
FinalCustomerDetails AS (
    SELECT 
        h.c_customer_sk,
        h.c_last_name,
        h.c_first_name,
        h.total_spent,
        f.total_orders
    FROM 
        HighSpenders h
    JOIN 
        FrequentBuyers f ON h.c_customer_sk = f.c_customer_sk
),
RankedCustomers AS (
    SELECT 
        fcd.c_customer_sk,
        fcd.c_last_name,
        fcd.c_first_name,
        fcd.total_spent,
        fcd.total_orders,
        RANK() OVER (ORDER BY fcd.total_spent DESC) AS spending_rank
    FROM 
        FinalCustomerDetails fcd
)
SELECT 
    rc.c_customer_sk,
    rc.c_last_name,
    rc.c_first_name,
    rc.total_spent,
    rc.total_orders,
    rc.spending_rank,
    COALESCE(NULLIF(rc.total_orders, 0), 1) AS orders_replaced,
    CASE 
        WHEN rc.spending_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    RankedCustomers rc
WHERE 
    rc.total_spent > 1000
ORDER BY 
    rc.spending_rank;
