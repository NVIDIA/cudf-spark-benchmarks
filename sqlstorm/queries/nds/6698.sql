
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_sales_price) AS total_spent,
        COUNT(ss.ss_ticket_number) AS purchase_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.total_spent,
        c.purchase_count,
        ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        customer_summary c
),
high_spending_customers AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_spent,
        tc.purchase_count
    FROM 
        top_customers tc
    WHERE 
        tc.rank <= 10
),
recent_sales AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
)

SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    r.ws_ship_date_sk,
    r.total_quantity_sold,
    r.total_sales,
    d.d_date AS sales_date
FROM 
    high_spending_customers h
JOIN 
    recent_sales r ON h.c_customer_sk = r.ws_item_sk
JOIN 
    date_dim d ON r.ws_ship_date_sk = d.d_date_sk
WHERE 
    d.d_weekend = 'Y'
ORDER BY 
    h.total_spent DESC, r.total_sales DESC;
