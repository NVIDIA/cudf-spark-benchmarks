
WITH Sales_CTE AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        p.p_promo_name,
        sm.sm_type,
        (ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer AS c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        promotion AS p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN 
        ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        d.d_year = 2023
        AND ws.ws_sales_price > 0
),
Aggregated_Sales AS (
    SELECT 
        d_year,
        d_month_seq,
        d_week_seq,
        cd_gender,
        cd_marital_status,
        SUM(total_sales) AS total_sales_amount,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT c_customer_sk) AS unique_customers
    FROM 
        Sales_CTE
    GROUP BY 
        d_year, d_month_seq, d_week_seq, cd_gender, cd_marital_status
)
SELECT 
    d_year,
    d_month_seq,
    d_week_seq,
    cd_gender,
    cd_marital_status,
    total_sales_amount,
    total_orders,
    unique_customers,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales_amount DESC) AS sales_rank
FROM 
    Aggregated_Sales
ORDER BY 
    d_year, sales_rank
LIMIT 100;
