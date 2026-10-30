WITH RevenueCTE AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
        COUNT(DISTINCT o_orderkey) AS order_count
    FROM lineitem
    JOIN orders ON l_orderkey = o_orderkey
    WHERE l_shipdate >= DATE '1997-01-01' 
    GROUP BY l_partkey
),
SupplierCTE AS (
    SELECT 
        ps_partkey,
        SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM partsupp
    GROUP BY ps_partkey
),
RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(r.total_revenue, 0) AS total_revenue,
        COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
        RANK() OVER (ORDER BY COALESCE(r.total_revenue, 0) DESC) AS revenue_rank
    FROM part p
    LEFT JOIN RevenueCTE r ON p.p_partkey = r.l_partkey
    LEFT JOIN SupplierCTE s ON p.p_partkey = s.ps_partkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.total_revenue,
    rp.total_supply_cost,
    CASE 
        WHEN rp.total_supply_cost > 0 THEN rp.total_revenue / rp.total_supply_cost
        ELSE NULL 
    END AS revenue_to_supply_ratio
FROM RankedParts rp
WHERE rp.revenue_rank <= 10
ORDER BY rp.total_revenue DESC;