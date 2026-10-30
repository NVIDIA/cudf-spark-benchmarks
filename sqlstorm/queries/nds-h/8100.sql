
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_per_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
TopSuppliers AS (
    SELECT 
        n.n_name AS nation, 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank_per_nation <= 5
),
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        COUNT(l.l_orderkey) AS line_item_count, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.nation,
    ts.s_name,
    os.o_orderkey,
    os.o_orderdate,
    os.line_item_count,
    os.total_revenue
FROM 
    TopSuppliers ts
JOIN 
    OrderStats os ON ts.s_suppkey = (
        SELECT l.l_suppkey 
        FROM lineitem l 
        WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= DATE '1996-01-01') 
        LIMIT 1
    )
ORDER BY 
    ts.nation, os.total_revenue DESC;
