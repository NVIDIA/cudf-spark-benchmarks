WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
SupplierRevenue AS (
    SELECT 
        li.l_suppkey, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        lineitem li 
    GROUP BY 
        li.l_suppkey
), 
SupplierDetails AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        r.r_name AS region_name, 
        COALESCE(sr.total_revenue, 0) AS total_revenue,
        rs.part_count
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey 
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        SupplierRevenue sr ON rs.s_suppkey = sr.l_suppkey
)
SELECT 
    sd.s_name,
    sd.region_name,
    sd.total_revenue,
    sd.part_count
FROM 
    SupplierDetails sd
WHERE 
    (sd.total_revenue, sd.part_count) IN (
        SELECT 
            MAX(total_revenue), 
            MAX(part_count) 
        FROM 
            SupplierDetails 
        GROUP BY 
            region_name
    )
ORDER BY 
    sd.region_name;
