WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
), SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplierCost,
        COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 50
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_brand
), RegionNationSummary AS (
    SELECT 
        r.r_name AS Region,
        n.n_name AS Nation,
        COUNT(DISTINCT c.c_custkey) AS CustomerCount,
        SUM(o.o_totalprice) AS TotalOrderValue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    sps.p_brand,
    sps.TotalSupplierCost,
    sps.SupplierCount,
    rns.Region,
    rns.Nation,
    rns.CustomerCount,
    rns.TotalOrderValue
FROM 
    RankedOrders ro
JOIN 
    SupplierPartStats sps ON ro.o_orderkey = sps.ps_partkey
JOIN 
    RegionNationSummary rns ON ro.o_orderkey = rns.CustomerCount
WHERE 
    ro.OrderRank <= 10
ORDER BY 
    ro.o_orderdate DESC, 
    ro.o_totalprice DESC;