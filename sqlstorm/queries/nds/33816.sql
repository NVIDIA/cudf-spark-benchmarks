
WITH  sales_totals AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_paid) DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        st.total_sales,
        st.order_count,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_totals st ON c.c_customer_sk = st.customer_sk
    WHERE 
        st.total_sales > (SELECT AVG(total_sales * 0.5) FROM sales_totals) 
        AND cd.cd_gender IS NOT NULL
),
store_summary AS (
    SELECT 
        s.s_store_id,
        SUM(ss_net_paid) AS store_sales,
        COUNT(ss_ticket_number) AS transaction_count
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_id
),
final_report AS (
    SELECT 
        hvc.c_customer_id,
        hvc.cd_gender,
        hvc.marital_status,
        COALESCE(ss.store_sales, 0) AS total_store_sales,
        COALESCE(ss.transaction_count, 0) AS total_transactions,
        (SELECT COUNT(*) FROM store) AS total_stores
    FROM 
        high_value_customers hvc
    LEFT JOIN 
        store_summary ss ON ss.store_sales > 0
)
SELECT 
    fr.c_customer_id,
    fr.cd_gender,
    fr.marital_status,
    fr.total_store_sales,
    fr.total_transactions,
    fr.total_stores,
    CASE 
        WHEN fr.total_store_sales > 10000 THEN 'High Spender'
        WHEN fr.total_store_sales BETWEEN 5000 AND 10000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS customer_spending_category
FROM 
    final_report fr
ORDER BY 
    fr.total_store_sales DESC;
