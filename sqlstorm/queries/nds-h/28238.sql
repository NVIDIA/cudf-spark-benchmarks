WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_name ORDER BY s.s_acctbal DESC) AS RN
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 50000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
)
SELECT 
    cu.c_name AS CustomerName,
    cu.o_orderkey AS OrderKey,
    cu.o_totalprice AS TotalPrice,
    s.s_name AS SupplierName,
    p.p_name AS PartName
FROM 
    CustomerOrders cu
JOIN 
    lineitem li ON cu.o_orderkey = li.l_orderkey
JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.RN = 1
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    cu.OrderRank <= 5
ORDER BY 
    cu.c_name, cu.o_orderkey;
