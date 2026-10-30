
WITH sales_summary AS (
    SELECT 
        s.s_store_id,
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        AVG(ss.ss_sales_price) AS average_sales_price
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        s.s_store_id, i.i_item_id
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id, cd.cd_gender
)
SELECT 
    ss.s_store_id,
    ss.i_item_id,
    ss.total_quantity,
    ss.total_sales,
    ss.total_discount,
    ss.average_sales_price,
    cs.c_customer_id,
    cs.cd_gender,
    cs.total_spent,
    cs.order_count
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON cs.total_spent > 1000
ORDER BY 
    ss.total_sales DESC, cs.total_spent DESC
LIMIT 100;
