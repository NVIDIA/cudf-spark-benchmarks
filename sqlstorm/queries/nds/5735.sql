
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS purchase_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        d.d_year,
        d.d_month_seq
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020 
        AND d.d_year <= 2023
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        d.d_year, 
        d.d_month_seq
), RankedPurchases AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS rank_within_year
    FROM 
        CustomerPurchases
)
SELECT 
    rp.c_customer_sk,
    rp.c_first_name,
    rp.c_last_name,
    rp.total_profit,
    rp.purchase_count,
    rp.cd_gender,
    rp.cd_marital_status,
    rp.cd_education_status,
    rp.d_year,
    rp.d_month_seq
FROM 
    RankedPurchases AS rp
WHERE 
    rp.rank_within_year <= 10
ORDER BY 
    rp.d_year, 
    rp.total_profit DESC;
