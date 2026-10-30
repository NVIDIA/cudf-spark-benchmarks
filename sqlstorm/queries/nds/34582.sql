
WITH  top_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
monthly_sales AS (
    SELECT 
        dd.d_year, 
        dd.d_month_seq, 
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year >= 2022
    GROUP BY 
        dd.d_year, dd.d_month_seq
),
state_sales AS (
    SELECT 
        ca.ca_state, 
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.ca_state
),
text_summary AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(NULLIF(hd.hd_buy_potential, ''), 'Unknown') AS buy_potential,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_rank AS (
    SELECT 
        ws.ws_item_sk, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)

SELECT 
    tc.c_customer_sk, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_spent, 
    ms.total_sales,
    ss.total_sales AS state_total_sales,
    ts.full_name,
    ts.buy_potential,
    ts.gender
FROM 
    top_customers tc
LEFT JOIN 
    monthly_sales ms ON tc.total_spent > ms.total_sales
LEFT JOIN 
    state_sales ss ON ss.total_sales IS NOT NULL
LEFT JOIN 
    text_summary ts ON ts.full_name = CONCAT(tc.c_first_name, ' ', tc.c_last_name)
WHERE 
    tc.total_spent IS NOT NULL
ORDER BY 
    tc.total_spent DESC, 
    ms.total_sales DESC;
