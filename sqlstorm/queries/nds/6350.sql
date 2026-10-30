
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        dt.d_year,
        dt.d_month_seq
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dt ON ws.ws_sold_date_sk = dt.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, dt.d_year, dt.d_month_seq
),
RankedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders,
        cs.cd_gender,
        cs.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cs.cd_gender, cs.cd_marital_status ORDER BY cs.total_spent DESC) AS rank_within_group
    FROM 
        CustomerSales cs
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_spent,
    r.total_orders,
    r.cd_gender,
    r.cd_marital_status
FROM 
    RankedSales r
WHERE 
    r.rank_within_group <= 10
ORDER BY 
    r.cd_gender, r.cd_marital_status, r.total_spent DESC;
