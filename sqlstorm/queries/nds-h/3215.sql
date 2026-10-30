WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TotalOrderValue AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalValue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(tv.TotalValue, 0) AS TotalValue
    FROM 
        customer c
    LEFT JOIN 
        TotalOrderValue tv ON c.c_custkey = tv.o_custkey
    WHERE 
        COALESCE(tv.TotalValue, 0) > 10000
),
SupplierPartCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    COALESCE(spc.TotalSupplyCost, 0) AS SupplyCost,
    SUM(hv.TotalValue) AS TotalCustomerValue
FROM 
    part p
LEFT JOIN 
    SupplierPartCosts spc ON p.p_partkey = spc.ps_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    HighValueCustomers hv ON o.o_custkey = hv.c_custkey
GROUP BY 
    p.p_name, p.p_brand, p.p_type, spc.TotalSupplyCost
HAVING 
    SUM(hv.TotalValue) > (SELECT AVG(TotalValue) FROM TotalOrderValue)
ORDER BY 
    SupplyCost DESC, TotalCustomerValue DESC;
