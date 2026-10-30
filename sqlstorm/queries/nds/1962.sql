
WITH RankedCustomerSales AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(ss.ss_ticket_number) AS total_purchases,
        RANK() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk
), 
FilteredTopCustomers AS (
    SELECT 
        rcs.c_customer_id, 
        rcs.c_first_name, 
        rcs.c_last_name, 
        rcs.total_spent, 
        rcs.total_purchases
    FROM 
        RankedCustomerSales rcs
    WHERE 
        rcs.rank <= 5
),
CategorySales AS (
    SELECT 
        i.i_category,
        SUM(ss.ss_net_paid) AS total_category_sales
    FROM 
        item i
    JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_category
)
SELECT 
    ftc.c_customer_id,
    ftc.c_first_name,
    ftc.c_last_name,
    ftc.total_spent,
    ftc.total_purchases,
    COALESCE(cs.total_category_sales, 0) AS total_spent_on_category
FROM 
    FilteredTopCustomers ftc
LEFT JOIN 
    CategorySales cs ON cs.total_category_sales > (SELECT AVG(total_spent) FROM FilteredTopCustomers) 
WHERE 
    ftc.total_spent > 1000
ORDER BY 
    ftc.total_spent DESC;
