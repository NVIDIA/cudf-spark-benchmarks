WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
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
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
)
SELECT 
    co.c_name AS customer_name,
    co.o_orderkey,
    co.o_totalprice,
    ts.s_name AS supplier_name,
    ts.total_supply_cost
FROM 
    CustomerOrders co
JOIN 
    lineitem li ON co.o_orderkey = li.l_orderkey
JOIN 
    TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
WHERE 
    li.l_shipdate >= DATE '1997-01-01' AND li.l_shipdate < DATE '1997-12-31'
ORDER BY 
    co.o_totalprice DESC;