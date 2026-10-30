WITH OrderSummaries AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        r.r_name AS region_name
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY o.o_orderkey, o.o_orderdate, r.r_name
),
SupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.total_revenue,
    os.unique_parts,
    ss.total_supply_cost,
    ss.unique_suppliers,
    (os.total_revenue - ss.total_supply_cost) AS profit,
    os.region_name
FROM OrderSummaries os
JOIN SupplierSummary ss ON os.o_orderkey = ss.ps_partkey
WHERE os.total_revenue > 50000
ORDER BY profit DESC, os.o_orderdate
LIMIT 100;