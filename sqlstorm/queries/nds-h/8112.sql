
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_available_qty,
        rs.total_revenue
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.revenue_rank <= 5
)

SELECT 
    c.c_name AS customer_name,
    c.c_acctbal AS customer_balance,
    ts.s_name AS supplier_name,
    ts.total_available_qty,
    ts.total_revenue
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE 
    c.c_acctbal > 10000 AND
    o.o_orderstatus = 'O' AND
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    ts.total_revenue DESC, c.c_name
LIMIT 100;
