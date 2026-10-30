WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        ps.ps_partkey
    FROM 
        RankedSuppliers rs
    JOIN 
        partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    WHERE 
        rs.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_orderstatus,
    co.o_totalprice,
    co.o_orderdate,
    ts.s_suppkey,
    ts.s_name,
    ts.s_acctbal
FROM 
    CustomerOrders co
JOIN 
    lineitem li ON co.o_orderkey = li.l_orderkey
JOIN 
    TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
WHERE 
    li.l_discount > 0.1
ORDER BY 
    co.o_orderdate DESC, 
    ts.s_acctbal DESC;