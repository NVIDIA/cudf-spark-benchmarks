
WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank,
        s.s_nationkey
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.total_supply_cost
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.supplier_rank <= 5
),
OrderStats AS (
    SELECT 
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
)
SELECT 
    ts.region_name,
    ts.nation_name,
    ts.supplier_name,
    ts.total_supply_cost,
    os.total_orders,
    os.total_revenue
FROM TopSuppliers ts
CROSS JOIN OrderStats os
ORDER BY ts.region_name, ts.nation_name, ts.total_supply_cost DESC;
