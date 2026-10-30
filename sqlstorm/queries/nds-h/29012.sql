WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_qty,
        SUM(CASE WHEN l.l_returnflag = 'A' THEN l.l_quantity ELSE 0 END) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND l.l_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
)
SELECT 
    si.s_suppkey,
    si.s_name,
    si.nation_name,
    si.region_name,
    si.part_count,
    si.total_returned_qty,
    si.total_available_qty,
    (si.total_available_qty - si.total_returned_qty) AS net_available_qty,
    CASE 
        WHEN si.total_available_qty = 0 THEN 'No Availability' 
        WHEN si.total_returned_qty > (0.1 * si.total_available_qty) THEN 'High Returns' 
        ELSE 'Normal' 
    END AS processing_status
FROM 
    SupplierInfo si
WHERE 
    si.part_count > 0
ORDER BY 
    net_available_qty DESC, total_returned_qty ASC;
