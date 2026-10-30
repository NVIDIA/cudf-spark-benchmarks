
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        n.n_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost,
        n.n_name,
        rs.rank
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.n_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        o.o_orderdate,
        ts.n_name
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, ts.n_name
)
SELECT 
    os.o_orderkey,
    os.revenue,
    os.o_orderdate,
    ts.s_name,
    ts.total_supply_cost,
    ts.n_name,
    ROW_NUMBER() OVER (PARTITION BY ts.n_name ORDER BY os.revenue DESC) AS revenue_rank
FROM 
    OrderSummary os
JOIN 
    TopSuppliers ts ON os.n_name = ts.n_name
WHERE 
    os.revenue > (SELECT AVG(revenue) FROM OrderSummary)
ORDER BY 
    ts.n_name, revenue_rank;
