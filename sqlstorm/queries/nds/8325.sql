
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        hd.hd_income_band_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, hd.hd_income_band_sk
),
OrderSummary AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_quantity) AS total_items_sold,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk
),
DateRange AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_month_seq
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
)
SELECT 
    dr.d_date,
    dr.d_month_seq,
    SUM(os.total_items_sold) AS total_items_sold,
    SUM(os.total_revenue) AS total_revenue,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    AVG(cs.avg_order_value) AS avg_order_value,
    COUNT(cs.total_orders) AS total_orders
FROM 
    DateRange dr
LEFT JOIN 
    OrderSummary os ON dr.d_date_sk = os.ws_ship_date_sk
LEFT JOIN 
    CustomerSummary cs ON cs.total_orders > 0
GROUP BY 
    dr.d_date, dr.d_month_seq
ORDER BY 
    dr.d_date;
