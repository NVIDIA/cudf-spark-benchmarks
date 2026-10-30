
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
top_sales AS (
    SELECT 
        r.ws_sold_date_sk, 
        r.ws_item_sk,
        r.total_quantity,
        r.rank_sales,
        i.i_current_price,
        (r.total_quantity * i.i_current_price) AS total_revenue
    FROM 
        ranked_sales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank_sales <= 5
),
customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        COALESCE(cd.cd_gender, 'U') AS gender,
        COUNT(DISTINCT ts.ws_order_number) AS total_orders,
        SUM(ts.total_revenue) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT 
            ws_bill_customer_sk, 
            ws_order_number,
            SUM(total_revenue) AS total_revenue
        FROM 
            top_sales
        JOIN 
            web_sales ws ON top_sales.ws_item_sk = ws.ws_item_sk
        GROUP BY 
            ws_bill_customer_sk, ws_order_number
    ) ts ON c.c_customer_sk = ts.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
final_report AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        CASE 
            WHEN cs.total_spent IS NULL THEN 'No Purchases'
            WHEN cs.total_spent > 500 THEN 'High Roller'
            WHEN cs.total_spent BETWEEN 250 AND 500 THEN 'Average Spender'
            ELSE 'Budget Buyer'
        END AS spending_category,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS rank_customer
    FROM 
        customer_summary cs
)
SELECT 
    fr.c_customer_sk, 
    fr.c_first_name, 
    fr.c_last_name, 
    fr.spending_category
FROM 
    final_report fr
WHERE 
    fr.rank_customer BETWEEN 1 AND 100
ORDER BY 
    fr.spending_category, fr.c_customer_sk;
