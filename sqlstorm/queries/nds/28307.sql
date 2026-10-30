WITH address_summary AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        COUNT(DISTINCT s.s_store_sk) AS store_count,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store s ON s.s_city = ca.ca_city
    GROUP BY 
        ca.ca_city
),
income_analysis AS (
    SELECT 
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cd.cd_dep_count) AS total_dependents,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ib.ib_lower_bound, ib.ib_upper_bound
),
date_range AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    a.ca_city,
    a.customer_count,
    a.store_count,
    a.male_count,
    a.female_count,
    a.avg_purchase_estimate,
    i.ib_lower_bound,
    i.ib_upper_bound,
    i.total_dependents,
    i.customer_count AS income_customer_count,
    d.d_year,
    d.d_month_seq,
    d.total_sales,
    d.total_profit
FROM 
    address_summary a
JOIN 
    income_analysis i ON a.customer_count > 0  
LEFT JOIN 
    date_range d ON a.customer_count > 10  
ORDER BY 
    a.ca_city, i.ib_lower_bound;