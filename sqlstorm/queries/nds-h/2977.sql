WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_availqty * ps.ps_supplycost) AS TotalSupplyCost,
        COUNT(p.p_partkey) AS TotalParts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS TotalOrderValue,
        COUNT(o.o_orderkey) AS TotalOrders,
        MAX(o.o_orderdate) AS LastOrderDate 
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 100
    GROUP BY 
        c.c_custkey
), RegionNation AS (
    SELECT 
        r.r_regionkey,
        n.n_nationkey,
        r.r_name AS RegionName,
        n.n_name AS NationName
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    rs.*
FROM 
    (SELECT 
        ss.s_suppkey, 
        ss.TotalSupplyCost, 
        cs.TotalOrderValue, 
        cs.LastOrderDate,
        rn.RegionName,
        rn.NationName,
        ROW_NUMBER() OVER (PARTITION BY rn.RegionName ORDER BY ss.TotalSupplyCost DESC) AS Rank
     FROM 
        SupplierStats ss
     LEFT JOIN 
        CustomerOrders cs ON ss.TotalParts > 0
     JOIN 
        RegionNation rn ON ss.s_suppkey = cs.TotalOrders
    ) AS rs
WHERE 
    rs.LastOrderDate > cast('1998-10-01' as date) - INTERVAL '1 year'
    AND (rs.TotalSupplyCost IS NOT NULL OR rs.TotalOrderValue IS NOT NULL)
ORDER BY 
    rs.RegionName, Rank
LIMIT 10;