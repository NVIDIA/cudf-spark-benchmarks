WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal
    FROM 
        RankedSuppliers s
    WHERE 
        s.rn = 1
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderstatus
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
)
SELECT 
    co.c_name AS CustomerName,
    co.o_orderkey AS OrderID,
    co.o_totalprice AS TotalPrice,
    ts.s_name AS SupplierName,
    ts.s_acctbal AS SupplierAccountBalance
FROM 
    CustomerOrders co
JOIN 
    lineitem l ON co.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    co.o_orderstatus = 'O'
ORDER BY 
    co.o_totalprice DESC, 
    ts.s_acctbal DESC
LIMIT 100;