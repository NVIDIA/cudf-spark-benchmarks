WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        n.n_name AS nation_name, 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_supply_value 
    FROM 
        RankedSuppliers rs
        JOIN nation n ON rs.rank <= 5 AND rs.s_suppkey = n.n_nationkey
        JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ts.region_name, 
    ts.nation_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue 
FROM 
    TopSuppliers ts
    JOIN lineitem l ON l.l_suppkey = ts.s_suppkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    ts.region_name, ts.nation_name
ORDER BY 
    total_revenue DESC, total_orders DESC;
