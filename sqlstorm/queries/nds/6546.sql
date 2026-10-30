
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk AS item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        cd.cd_gender AS customer_gender,
        ca.ca_state AS customer_state,
        d.d_year AS sales_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.ws_item_sk, cd.cd_gender, ca.ca_state, d.d_year
),

ranked_sales AS (
    SELECT 
        item_id,
        total_quantity,
        total_revenue,
        customer_gender,
        customer_state,
        sales_year,
        RANK() OVER (PARTITION BY sales_year ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        sales_data
)

SELECT 
    item_id,
    total_quantity,
    total_revenue,
    customer_gender,
    customer_state,
    sales_year
FROM 
    ranked_sales
WHERE 
    revenue_rank <= 10
ORDER BY 
    sales_year, total_revenue DESC;
