
WITH  sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        ss_store_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS customer_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        ca.customer_gender,
        ca.marital_status,
        SUM(ca.total_spent) AS aggregate_spending,
        RANK() OVER (PARTITION BY ca.customer_gender ORDER BY SUM(ca.total_spent) DESC) AS spending_rank
    FROM 
        customer_analysis ca
    GROUP BY 
        ca.customer_gender, ca.marital_status
),
store_performance AS (
    SELECT 
        w.w_warehouse_id,
        ss.ss_store_sk,
        ss.total_sales,
        ss.total_transactions,
        t.aggregate_spending
    FROM 
        warehouse w
    JOIN 
        sales_summary ss ON w.w_warehouse_sk = ss.ss_store_sk
    LEFT JOIN 
        top_customers t ON ss.sales_rank = 1
),
final_summary AS (
    SELECT 
        sp.w_warehouse_id,
        sp.total_sales,
        sp.total_transactions,
        COALESCE(sp.aggregate_spending, 0) AS customer_spending,
        CASE 
            WHEN sp.total_sales > 10000 THEN 'High Performer'
            WHEN sp.total_sales BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
            ELSE 'Low Performer'
        END AS performance_category
    FROM 
        store_performance sp
)
SELECT 
    f.w_warehouse_id,
    f.total_sales,
    f.total_transactions,
    f.customer_spending,
    f.performance_category
FROM 
    final_summary f
WHERE 
    f.performance_category = 'High Performer' 
ORDER BY 
    f.total_sales DESC
LIMIT 10;
