
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_type
),
FilteredOrders AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'A') 
    AND l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
    HAVING SUM(l.l_discount) IS NOT NULL
),
TopRegions AS (
    SELECT
        n.n_regionkey,
        r.r_name,
        SUM(ps.ps_supplycost) AS region_total_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_regionkey, r.r_name
    HAVING SUM(ps.ps_supplycost) > 10000
)
SELECT
    o.o_orderkey,
    o.total_revenue,
    COALESCE(r.region_total_supply_cost, 0) AS supply_cost_for_region,
    s.s_name AS top_supplier_name,
    CASE
        WHEN s.rank = 1 THEN 'Prime Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_status
FROM FilteredOrders o
LEFT JOIN RankedSuppliers s ON s.total_supply_cost = (SELECT MAX(total_supply_cost) FROM RankedSuppliers WHERE rank = 1)
LEFT JOIN TopRegions r ON r.region_total_supply_cost = s.total_supply_cost
WHERE o.revenue_rank <= 10
ORDER BY o.total_revenue DESC
LIMIT 20;
