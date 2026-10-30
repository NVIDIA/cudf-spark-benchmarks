WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Account'
            WHEN s.s_acctbal > 5000 THEN 'High Value'
            ELSE 'Low Value'
        END AS AccountCategory
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        MAX(ps.ps_comment) AS MaxComment
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
NationalStats AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS CustomerCount,
        SUM(o.o_totalprice) AS TotalOrders,
        AVG(o.o_totalprice) AS AvgOrderValue
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
)
SELECT 
    r.r_name AS Region,
    p.p_name AS PartName,
    ss.s_name AS SupplierName,
    ns.CustomerCount,
    ns.TotalOrders,
    ns.AvgOrderValue,
    COALESCE(ri.TotalSupplyCost, 0) AS TotalSupplyCost,
    CASE 
        WHEN ns.TotalOrders > 10000 THEN 'High Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN part p ON l.l_partkey = p.p_partkey
JOIN SupplierDetails ss ON ss.s_suppkey = l.l_suppkey
LEFT JOIN PartSupplierInfo ri ON ri.ps_partkey = p.p_partkey
JOIN NationalStats ns ON ns.n_name = n.n_name
WHERE r.r_name LIKE 'A%' 
AND EXISTS (
    SELECT 1 
    FROM RankedOrders ro 
    WHERE ro.o_orderkey = o.o_orderkey 
    AND ro.OrderRank <= 10
)
ORDER BY Region, PartName, SupplierName;
