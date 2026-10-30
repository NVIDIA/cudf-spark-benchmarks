WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * li.l_quantity) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem li ON ps.ps_partkey = li.l_partkey
    WHERE 
        li.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationSuppliers AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(ss.total_supplycost) AS total_nation_cost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
RegionSpending AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        SUM(ns.total_nation_cost) AS total_region_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        NationSuppliers ns ON n.n_nationkey = ns.n_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
FinalReport AS (
    SELECT 
        r.r_name, 
        ns.n_name, 
        ss.s_name, 
        ss.total_supplycost
    FROM 
        RegionSpending r
    JOIN 
        NationSuppliers ns ON r.r_regionkey = ns.n_nationkey
    JOIN 
        SupplierSales ss ON ns.n_nationkey = ss.s_suppkey
)
SELECT 
    fr.r_name AS Region, 
    fr.n_name AS Nation, 
    fr.s_name AS Supplier, 
    ROUND(fr.total_supplycost, 2) AS Total_Cost 
FROM 
    FinalReport fr
ORDER BY 
    fr.total_supplycost DESC
LIMIT 100;