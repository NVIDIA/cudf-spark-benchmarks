
WITH  sale_totals AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
popular_items AS (
    SELECT 
        st.ws_item_sk,
        st.total_sales,
        it.i_item_desc,
        it.i_current_price,
        DENSE_RANK() OVER (ORDER BY st.total_sales DESC) AS item_rank
    FROM 
        sale_totals st
    JOIN 
        item it ON st.ws_item_sk = it.i_item_sk
    WHERE 
        st.rank = 1
),
top_customers AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_paid) > (
            SELECT 
                AVG(total_spent)
            FROM 
                (SELECT 
                     SUM(ws_net_paid) AS total_spent
                 FROM 
                     web_sales
                 GROUP BY 
                     ws_bill_customer_sk) AS avg_spent
        )
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
customer_sales AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.c_email_address,
        SUM(ws.ws_net_paid) AS total_purchases
    FROM 
        web_sales ws
    JOIN 
        customer_details cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY 
        cd.c_customer_sk, cd.c_first_name, cd.c_last_name, cd.c_email_address
),
final AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.c_email_address,
        ci.total_purchases,
        pi.i_item_desc,
        pi.total_sales
    FROM 
        customer_sales ci
    JOIN 
        popular_items pi ON ci.total_purchases > (SELECT AVG(total_sales) FROM popular_items)
    WHERE 
        ci.total_purchases IS NOT NULL
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.c_email_address,
    f.total_purchases,
    f.i_item_desc,
    f.total_sales
FROM 
    final f
ORDER BY 
    f.total_sales DESC
LIMIT 100;
