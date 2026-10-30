WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        n.n_name, r.r_name
), SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        SUM(ps.ps_availqty) AS total_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, p.p_name
), CombinedData AS (
    SELECT 
        rs.nation_name,
        rs.region_name,
        sp.supplier_name,
        sp.part_name,
        rs.total_sales,
        sp.total_quantity,
        sp.total_value
    FROM 
        RegionalSales rs
    JOIN 
        SupplierParts sp ON sp.supplier_name IS NOT NULL
)
SELECT 
    nation_name,
    region_name,
    supplier_name,
    part_name,
    total_sales,
    total_quantity,
    total_value
FROM 
    CombinedData
ORDER BY 
    total_sales DESC, total_value DESC
LIMIT 100;