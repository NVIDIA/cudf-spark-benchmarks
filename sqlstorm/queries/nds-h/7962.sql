
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY rs.total_cost DESC) AS rnk
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE 
        rs.total_cost > 10000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_name AS customer_name,
    co.total_spent,
    ts.s_name AS supplier_name,
    ts.s_acctbal AS supplier_balance
FROM 
    CustomerOrders co
JOIN 
    TopSuppliers ts ON co.total_spent > 5000
ORDER BY 
    co.total_spent DESC, ts.s_acctbal DESC
LIMIT 10;
