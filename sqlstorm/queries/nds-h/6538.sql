WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_by_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        rs.nation_name,
        rs.s_name,
        rs.total_supply_cost
    FROM RankedSuppliers rs
    WHERE rs.rank_by_cost <= 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.nation_name,
    ts.s_name,
    od.o_orderkey,
    od.o_orderdate,
    od.total_revenue
FROM TopSuppliers ts
JOIN OrderDetails od ON od.total_revenue > 10000
ORDER BY ts.nation_name, od.total_revenue DESC;