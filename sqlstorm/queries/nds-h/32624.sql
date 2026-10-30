
WITH  SalesCTE AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
),
SupplierPart AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 0
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        SupplierPart ps
    JOIN 
        supplier s ON ps.s_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp)
),
RegionSales AS (
    SELECT 
        n.n_regionkey,
        SUM(s.total_sales) AS region_sales
    FROM 
        SalesCTE s
    JOIN 
        customer c ON s.c_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
)
SELECT 
    r.r_name,
    r.r_comment,
    COALESCE(rs.region_sales, 0) AS region_sales,
    hs.total_supply_value
FROM 
    region r
LEFT JOIN 
    RegionSales rs ON r.r_regionkey = rs.n_regionkey
LEFT JOIN 
    HighValueSuppliers hs ON hs.s_suppkey = (SELECT MIN(s.s_suppkey) FROM supplier s WHERE s.s_acctbal IS NOT NULL)
ORDER BY 
    region_sales DESC, hs.total_supply_value ASC;
