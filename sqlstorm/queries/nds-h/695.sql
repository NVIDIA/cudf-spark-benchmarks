WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
HighValueSupplies AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        ps.ps_partkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(hvs.TotalSupplyCost, 0) AS TotalSupplyCost
    FROM 
        part p
    LEFT JOIN 
        HighValueSupplies hvs ON p.p_partkey = hvs.ps_partkey
)
SELECT 
    r.r_name,
    pd.p_name,
    pd.p_brand,
    AVG(pd.TotalSupplyCost) AS AvgSupplyCost,
    COUNT(DISTINCT ro.o_orderkey) AS TotalOrders,
    SUM(CASE WHEN ro.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31' THEN ro.o_totalprice ELSE 0 END) AS TotalSales2022
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
LEFT JOIN 
    RankedOrders ro ON pd.p_partkey = ro.o_orderkey
GROUP BY 
    r.r_name, pd.p_name, pd.p_brand
HAVING 
    AVG(pd.TotalSupplyCost) > (SELECT AVG(TotalSupplyCost) FROM HighValueSupplies)
ORDER BY 
    AvgSupplyCost DESC, TotalOrders DESC;