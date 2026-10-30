
WITH Summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_availqty) DESC) AS availability_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
HighVolumeOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierNation AS (
    SELECT 
        s.s_suppkey,
        n.n_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, n.n_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)

SELECT 
    s.n_name AS supplier_nation,
    s.total_supply_value,
    ho.o_orderkey,
    so.total_available AS available_parts,
    ho.total_revenue
FROM SupplierNation s
LEFT JOIN HighVolumeOrders ho ON s.s_suppkey = ho.o_orderkey
LEFT JOIN Summary so ON so.p_partkey = ho.o_orderkey
WHERE so.availability_rank = 1
   OR ho.revenue_rank <= 10
ORDER BY s.total_supply_value DESC, ho.total_revenue DESC;
