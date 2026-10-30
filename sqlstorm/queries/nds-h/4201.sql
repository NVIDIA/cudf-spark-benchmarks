
WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCosts,
        COUNT(DISTINCT ps.ps_partkey) AS DistinctParts
    FROM
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        SUM(l.l_quantity) AS TotalQuantity
    FROM
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderstatus = 'O' AND
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY
        o.o_orderkey, o.o_orderdate
)
SELECT
    r.r_name AS RegionName,
    SUM(ods.TotalRevenue) AS TotalRevenue,
    COUNT(DISTINCT ods.o_orderkey) AS TotalOrders,
    COUNT(DISTINCT ss.s_suppkey) AS TotalSuppliers,
    AVG(ss.TotalCosts) AS AvgSupplierCost
FROM 
    region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN OrderDetails ods ON ss.s_suppkey = (SELECT ps.ps_suppkey 
                                               FROM partsupp ps 
                                               WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                                        FROM part p 
                                                                        WHERE p.p_brand = 'Brand#123'))
WHERE
    r.r_name IS NOT NULL
GROUP BY
    r.r_name
HAVING
    SUM(ods.TotalRevenue) > 0
ORDER BY
    TotalRevenue DESC;
