WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        RANK() OVER (ORDER BY rs.total_supply_cost DESC) AS supplier_rank
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE 
        rs.total_supply_cost > 1000
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
)
SELECT 
    ts.s_suppkey, 
    ts.s_name, 
    cod.c_custkey, 
    cod.c_name, 
    cod.o_orderkey, 
    cod.o_totalprice, 
    cod.o_orderdate
FROM 
    TopSuppliers ts
JOIN 
    lineitem l ON ts.s_suppkey = l.l_suppkey
JOIN 
    CustomerOrderDetails cod ON l.l_orderkey = cod.o_orderkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    ts.s_suppkey, cod.o_orderdate DESC
LIMIT 100;