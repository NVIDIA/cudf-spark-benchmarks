
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_coupon_amt) AS total_coupons_redeemed
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.total_net_profit,
    cd.order_count,
    ms.total_sales,
    ms.total_coupons_redeemed
FROM 
    CustomerDetails cd
JOIN 
    MonthlySales ms ON cd.total_net_profit > 0 AND ms.d_year = EXTRACT(YEAR FROM DATE '2002-10-01') - 1
WHERE 
    cd.total_net_profit > 5000
ORDER BY 
    cd.total_net_profit DESC, ms.total_sales DESC
LIMIT 100;
