WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS RankByPrice
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p2.p_size FROM part p2 WHERE p2.p_retailprice > 100.00)
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT s.s_suppkey) AS UniqueSuppliers
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
OrderQuantities AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_quantity) AS TotalQuantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
),
NationRanked AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        ROW_NUMBER() OVER (ORDER BY ss.TotalSupplyCost DESC) AS NationRank
    FROM 
        nation n
    JOIN 
        SupplierStats ss ON n.n_nationkey = ss.s_nationkey
)
SELECT 
    r.r_name,
    COALESCE(p.p_name, 'Unknown Part') AS MostExpensivePart,
    s.TotalSupplyCost,
    o.TotalQuantity,
    nr.NationRank
FROM 
    region r
LEFT JOIN 
    RankedParts p ON p.RankByPrice = 1
JOIN 
    SupplierStats s ON s.s_nationkey = r.r_regionkey
JOIN 
    OrderQuantities o ON o.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderkey IN (SELECT o3.o_orderkey FROM orders o3 WHERE o3.o_orderstatus = 'O' AND o3.o_totalprice > 5000))
JOIN 
    NationRanked nr ON nr.n_nationkey = s.s_nationkey
WHERE 
    s.TotalSupplyCost IS NOT NULL OR o.TotalQuantity IS NOT NULL
ORDER BY 
    s.TotalSupplyCost DESC, o.TotalQuantity ASC
LIMIT 10;
