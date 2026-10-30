
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        cd.cd_gender,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2022
    GROUP BY 
        d.d_year, cd.cd_gender, ca.ca_state
),
ranked_sales AS (
    SELECT 
        sales_year,
        cd_gender,
        ca_state,
        total_orders,
        total_sales,
        total_discount,
        total_net_profit,
        RANK() OVER (PARTITION BY sales_year ORDER BY total_net_profit DESC) AS rank
    FROM 
        sales_summary
)
SELECT 
    sales_year,
    cd_gender,
    ca_state,
    total_orders,
    total_sales,
    total_discount,
    total_net_profit,
    rank
FROM 
    ranked_sales
WHERE 
    rank <= 5
ORDER BY 
    sales_year, rank;
