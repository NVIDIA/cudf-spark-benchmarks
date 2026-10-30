
WITH CustomerAddressAnalysis AS (
    SELECT
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        SUM(CASE WHEN ca_city LIKE '%ville%' THEN 1 ELSE 0 END) AS cities_with_ville,
        COUNT(CASE WHEN ca_street_type IN ('St', 'Ave', 'Blvd') THEN 1 END) AS normalized_street_count,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM
        customer_address
    GROUP BY
        ca_state
),
PromotionsSummary AS (
    SELECT
        p.p_promo_name,
        COUNT(cs.cs_order_number) AS total_orders,
        SUM(cs.cs_ext_sales_price) AS total_revenue,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_ext_tax) AS total_tax
    FROM
        promotion p
    LEFT JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY
        p.p_promo_name
),
FinalBenchmark AS (
    SELECT
        ca.ca_state,
        ca.unique_addresses,
        ca.cities_with_ville,
        ca.normalized_street_count,
        ca.avg_gmt_offset,
        ps.p_promo_name,
        ps.total_orders,
        ps.total_revenue,
        ps.total_discount,
        ps.total_tax
    FROM
        CustomerAddressAnalysis ca
    JOIN PromotionsSummary ps ON ps.total_orders IS NOT NULL
    ORDER BY
        ca.ca_state,
        ps.total_revenue DESC
)
SELECT *
FROM FinalBenchmark
WHERE total_orders > 5
AND avg_gmt_offset BETWEEN -5.00 AND 0.00;
