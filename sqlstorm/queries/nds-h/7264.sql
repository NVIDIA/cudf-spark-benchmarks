WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT *
    FROM RankedSuppliers
    WHERE supplier_rank <= 3
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    os.c_custkey,
    os.c_name,
    os.total_orders,
    os.total_spent,
    os.total_quantity,
    ts.nation,
    ts.s_name AS top_supplier,
    ts.total_avail_qty,
    ts.total_supplycost
FROM 
    OrderSummary os
JOIN 
    TopSuppliers ts ON os.c_custkey % 5 = ts.s_suppkey % 5
ORDER BY 
    os.total_spent DESC, ts.total_avail_qty DESC
LIMIT 10;