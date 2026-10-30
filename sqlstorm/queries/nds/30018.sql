
WITH  RevenueGrowth AS (
    SELECT 
        d_year,
        SUM(ws_net_paid) AS total_revenue,
        RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS revenue_rank
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY d_year
),
CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender, cd_marital_status
),
TopStores AS (
    SELECT 
        s_store_name,
        SUM(ss_net_profit) AS total_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ss_net_profit) DESC) AS store_rank
    FROM store
    JOIN store_sales ON s_store_sk = ss_store_sk
    GROUP BY s_store_name
),
Promotions AS (
    SELECT 
        p_promo_id,
        COUNT(DISTINCT ws_order_number) AS orders_placed,
        SUM(ws_net_paid) AS total_revenue
    FROM promotion
    JOIN web_sales ON p_promo_sk = ws_promo_sk
    GROUP BY p_promo_id
),
Combined AS (
    SELECT 
        rg.d_year,
        cs.cd_gender,
        cs.cd_marital_status,
        ts.s_store_name,
        pm.orders_placed,
        pm.total_revenue,
        rg.total_revenue AS annual_revenue,
        RANK() OVER (PARTITION BY rg.d_year ORDER BY rg.total_revenue DESC) AS year_rank
    FROM RevenueGrowth rg
    CROSS JOIN CustomerStats cs
    JOIN TopStores ts ON ts.store_rank <= 5
    JOIN Promotions pm ON pm.total_revenue > 10000
)
SELECT 
    d_year,
    cd_gender,
    cd_marital_status,
    s_store_name,
    orders_placed,
    total_revenue,
    annual_revenue
FROM Combined
WHERE annual_revenue IS NOT NULL 
    AND total_revenue IS NOT NULL
ORDER BY d_year, s_store_name;
