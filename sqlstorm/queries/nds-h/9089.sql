WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_nationkey, 
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
NationRegions AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name 
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
SupplierRegionDetails AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        nr.n_name AS NationName,
        nr.r_name AS RegionName,
        sd.TotalSupplyValue
    FROM SupplierDetails sd
    JOIN NationRegions nr ON sd.s_nationkey = nr.n_nationkey
)
SELECT 
    sr.NationName,
    sr.RegionName,
    COUNT(DISTINCT co.c_custkey) AS UniqueCustomers,
    AVG(co.TotalSpent) AS AvgCustomerSpent,
    SUM(sr.TotalSupplyValue) AS TotalSupplyValueForRegion
FROM SupplierRegionDetails sr
JOIN CustomerOrders co ON sr.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_orderstatus = 'F'))
GROUP BY sr.NationName, sr.RegionName
ORDER BY TotalSupplyValueForRegion DESC, UniqueCustomers DESC;
