
WITH sales_summary AS (
    SELECT 
        customer.c_customer_id,
        SUM(store_sales.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT store_sales.ss_ticket_number) AS total_transactions,
        AVG(store_sales.ss_quantity) AS avg_quantity_per_transaction,
        MAX(store_sales.ss_sales_price) AS max_sale_price,
        MIN(store_sales.ss_sales_price) AS min_sale_price,
        EXTRACT(YEAR FROM date_dim.d_date) AS sales_year
    FROM 
        store_sales
    JOIN 
        customer ON store_sales.ss_customer_sk = customer.c_customer_sk
    JOIN 
        date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    WHERE 
        date_dim.d_date BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        customer.c_customer_id, sales_year
), demographic_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    s.c_customer_id AS customer_id,
    d.cd_gender,
    d.cd_marital_status,
    d.ib_lower_bound,
    d.ib_upper_bound,
    s.total_net_profit,
    s.total_transactions,
    s.avg_quantity_per_transaction,
    s.max_sale_price,
    s.min_sale_price
FROM 
    sales_summary s
JOIN 
    demographic_info d ON s.c_customer_id = d.c_customer_id
ORDER BY 
    s.total_net_profit DESC
LIMIT 100;
