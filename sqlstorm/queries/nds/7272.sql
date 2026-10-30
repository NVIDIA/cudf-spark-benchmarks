
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_ship_mode_sk) AS unique_ship_modes
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2023 AND
        c.c_current_cdemo_sk IN (
            SELECT cd_demo_sk 
            FROM customer_demographics 
            WHERE cd_gender = 'M' AND 
                  cd_marital_status = 'S' AND 
                  cd_purchase_estimate >= 1000
        )
    GROUP BY 
        c.c_customer_id, ca.ca_city, ca.ca_state
),
top_sales AS (
    SELECT 
        c_customer_id,
        total_sales,
        order_count,
        unique_ship_modes,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    c_customer_id,
    total_sales,
    order_count,
    unique_ship_modes
FROM 
    top_sales
WHERE 
    sales_rank <= 10
ORDER BY 
    total_sales DESC;
