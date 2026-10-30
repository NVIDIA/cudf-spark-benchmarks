
WITH SalesSummary AS (
    SELECT
        d.d_year,
        p.p_promo_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM
        web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
        AND p.p_discount_active = 'Y'
    GROUP BY
        d.d_year, p.p_promo_name
),
TopPromotions AS (
    SELECT
        d_year,
        p_promo_name,
        total_quantity_sold,
        total_net_profit,
        avg_sales_price,
        avg_net_paid,
        RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
    FROM
        SalesSummary
)
SELECT
    d_year,
    p_promo_name,
    total_quantity_sold,
    total_net_profit,
    avg_sales_price,
    avg_net_paid
FROM
    TopPromotions
WHERE
    profit_rank <= 5
ORDER BY
    d_year, total_net_profit DESC;
