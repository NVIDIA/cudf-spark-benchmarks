WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate < (cast('1998-10-01' as date) - INTERVAL '1 year')
),
HighValueSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
LastYearOrders AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_orderkey) AS ItemCount
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN (cast('1998-10-01' as date) - INTERVAL '1 year') AND cast('1998-10-01' as date)
    GROUP BY 
        o.o_orderkey
),
PreferredCustomerOrders AS (
    SELECT 
        co.c_custkey,
        co.o_orderkey,
        ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY lo.ItemCount DESC) AS PopularityRank
    FROM 
        CustomerOrders co
    LEFT JOIN 
        LastYearOrders lo ON co.o_orderkey = lo.o_orderkey
)
SELECT 
    DISTINCT n.n_name,
    p.p_name,
    CASE 
        WHEN ps.ps_supplycost > 0 THEN (ps.ps_supplycost * 1.2) 
        ELSE NULL 
    END AS AdjustedSupplyCost,
    pc.PopularityRank
FROM 
    nation n 
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    HighValueSuppliers hv ON s.s_suppkey = hv.ps_suppkey
JOIN 
    partsupp ps ON hv.ps_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    PreferredCustomerOrders pc ON s.s_suppkey = pc.c_custkey
WHERE 
    (pc.PopularityRank IS NULL OR pc.PopularityRank <= 10) 
    AND p.p_retailprice BETWEEN 100 AND 200
UNION ALL
SELECT 
    NULL AS n_name,
    p.p_name,
    SUM(COALESCE(ps.ps_supplycost, 0)) AS AdjustedSupplyCost,
    NULL AS PopularityRank
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size IS NOT NULL
GROUP BY 
    p.p_name
HAVING 
    SUM(ps.ps_availqty) < 100
ORDER BY 
    AdjustedSupplyCost DESC NULLS LAST;