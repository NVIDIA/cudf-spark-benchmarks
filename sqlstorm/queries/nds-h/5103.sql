WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name, 
        c.c_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) as OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
), 
AverageSupplierCost AS (
    SELECT 
        ps.ps_partkey, 
        AVG(ps.ps_supplycost) as avg_supplycost
    FROM 
        partsupp ps 
    GROUP BY 
        ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        a.avg_supplycost
    FROM 
        supplier s
    JOIN 
        AverageSupplierCost a ON s.s_suppkey = a.ps_partkey
    WHERE 
        s.s_acctbal > 5000
)
SELECT 
    ro.o_orderkey, 
    ro.o_orderdate, 
    ro.o_totalprice, 
    ro.c_name, 
    ts.s_name AS SupplierName, 
    ts.avg_supplycost
FROM 
    RankedOrders ro
JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    ro.OrderRank <= 10
ORDER BY 
    ro.o_orderdate DESC, 
    ro.o_totalprice DESC;
