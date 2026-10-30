
WITH  sales_data AS (
    SELECT 
        ss_item_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY 
        ss_item_sk
),
top_sales AS (
    SELECT 
        sd.ss_item_sk,
        sd.total_sales,
        sd.total_transactions,
        i.i_item_desc,
        DENSE_RANK() OVER (ORDER BY sd.total_sales DESC) AS rank
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ss_item_sk = i.i_item_sk
    WHERE 
        sd.sales_rank <= 10
),
customer_activity AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY 
        c.c_customer_sk
),
final_summary AS (
    SELECT 
        cs.c_customer_sk,
        ca.total_orders,
        ca.total_spent,
        ts.total_sales,
        ts.i_item_desc,
        ts.rank
    FROM 
        customer_activity ca
    JOIN 
        top_sales ts ON ts.ss_item_sk = ca.total_orders
    LEFT JOIN 
        customer cs ON cs.c_customer_sk = ca.c_customer_sk
)
SELECT 
    fs.c_customer_sk,
    fs.total_orders,
    fs.total_spent,
    fs.total_sales,
    fs.i_item_desc,
    fs.rank
FROM 
    final_summary fs
WHERE 
    fs.total_spent IS NOT NULL
ORDER BY 
    fs.rank, fs.total_spent DESC;
