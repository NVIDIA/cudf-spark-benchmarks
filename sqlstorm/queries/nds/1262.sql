
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, 
        ss_sold_date_sk
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
MonthlySales AS (
    SELECT 
        d_month_seq,
        SUM(ws_net_paid) AS total_web_sales,
        SUM(ws_quantity) AS total_web_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_month_seq
)
SELECT 
    d.d_year,
    cs.total_web_sales,
    cs.total_web_quantity,
    r.total_quantity AS store_sales_quantity,
    r.total_profit AS store_total_profit,
    ci.cd_gender,
    ci.cd_marital_status
FROM 
    MonthlySales cs
JOIN 
    date_dim d ON cs.d_month_seq = d.d_month_seq
JOIN 
    RankedSales r ON d.d_year = r.ss_sold_date_sk
LEFT JOIN 
    CustomerInfo ci ON ci.customer_rank = 1
WHERE 
    r.rank <= 10
    AND ci.cd_purchase_estimate IS NOT NULL
    AND (ci.cd_credit_rating LIKE 'A%' OR ci.cd_credit_rating IS NULL)
ORDER BY 
    d.d_year, r.total_profit DESC;
