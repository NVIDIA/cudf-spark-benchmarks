
WITH sales_summary AS (
    SELECT 
        cs.cs_bill_customer_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM 
        catalog_sales cs
    JOIN 
        customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND dd.d_year = 2023
    GROUP BY 
        cs.cs_bill_customer_sk
),
top_customers AS (
    SELECT 
        css.cs_bill_customer_sk,
        css.total_quantity,
        css.total_profit,
        ROW_NUMBER() OVER (ORDER BY css.total_profit DESC) AS rank
    FROM 
        sales_summary css
),
high_value_customers AS (
    SELECT 
        tc.cs_bill_customer_sk,
        tc.total_quantity,
        tc.total_profit
    FROM 
        top_customers tc
    WHERE 
        tc.rank <= 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    h.hd_income_band_sk,
    h.hd_buy_potential,
    h.hd_dep_count,
    h.hd_vehicle_count,
    hv.total_quantity,
    hv.total_profit
FROM 
    high_value_customers hv
JOIN 
    customer c ON hv.cs_bill_customer_sk = c.c_customer_sk
JOIN 
    household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
ORDER BY 
    hv.total_profit DESC;
