WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS SupplyRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 10000
),
EligibleParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT l.l_orderkey) AS OrderCount
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        COUNT(DISTINCT l.l_orderkey) > 5
)
SELECT 
    r.s_name AS SupplierName,
    ep.p_name AS PartName,
    ep.OrderCount,
    hvc.TotalSpent,
    COALESCE(r.s_acctbal, 0) AS SupplierAccountBalance
FROM 
    RankedSuppliers r
JOIN 
    EligibleParts ep ON ep.p_partkey = r.s_suppkey
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_custkey = r.s_suppkey
WHERE 
    r.SupplyRank = 1
AND 
    (hvc.TotalSpent IS NOT NULL OR r.s_acctbal > 5000)
ORDER BY 
    ep.OrderCount DESC, SupplierName;
