WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation,
        rs.total_available_qty,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
),
OrdersSummary AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.c_acctbal,
    os.total_spent,
    os.total_orders,
    ts.s_name AS top_supplier,
    ts.total_available_qty,
    ts.total_cost
FROM 
    customer cs
LEFT JOIN 
    OrdersSummary os ON cs.c_custkey = os.o_custkey
LEFT JOIN 
    TopSuppliers ts ON ts.total_cost = (SELECT MAX(total_cost) FROM TopSuppliers)
WHERE 
    cs.c_acctbal > 1000
ORDER BY 
    os.total_spent DESC, cs.c_name;
