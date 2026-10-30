
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk AS order_date,
        ws_item_sk AS item_id,
        ws_quantity AS quantity_sold,
        ws_net_profit AS total_profit,
        cd_gender AS customer_gender,
        p_discount_active AS promo_active,
        d_year AS sales_year
    FROM 
        web_sales
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN 
        promotion ON ws_promo_sk = p_promo_sk
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year >= 2020
),
YearlyPerformance AS (
    SELECT 
        sales_year,
        customer_gender,
        SUM(quantity_sold) AS total_quantity,
        SUM(total_profit) AS total_profit,
        AVG(CASE WHEN promo_active = 'Y' THEN total_profit ELSE NULL END) AS avg_profit_with_promo,
        AVG(CASE WHEN promo_active = 'N' THEN total_profit ELSE NULL END) AS avg_profit_without_promo
    FROM 
        SalesData
    GROUP BY 
        sales_year, customer_gender
)
SELECT 
    sales_year,
    customer_gender,
    total_quantity,
    total_profit,
    avg_profit_with_promo,
    avg_profit_without_promo,
    RANK() OVER (PARTITION BY sales_year ORDER BY total_profit DESC) AS rank_by_profit
FROM 
    YearlyPerformance
ORDER BY 
    sales_year, rank_by_profit;
