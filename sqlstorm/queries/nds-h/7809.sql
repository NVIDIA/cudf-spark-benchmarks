WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
RegionalSupplierStats AS (
    SELECT 
        r.r_name AS region_name,
        SUM(total_cost) AS total_region_cost,
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.nation_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.supplier_rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    r.region_name,
    r.total_region_cost,
    r.supplier_count,
    (r.total_region_cost / NULLIF(r.supplier_count, 0)) AS avg_supplier_cost
FROM 
    RegionalSupplierStats r
ORDER BY 
    r.total_region_cost DESC;
