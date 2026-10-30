WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rev_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, o.o_orderstatus
),
FilteredOrders AS (
    SELECT o_orderkey, c_name, total_revenue 
    FROM RankedOrders 
    WHERE rev_rank <= 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CombinedData AS (
    SELECT 
        fo.o_orderkey,
        fo.c_name,
        COALESCE(sd.s_name, 'No Supplier') AS supplier_name,
        sd.part_count,
        fo.total_revenue
    FROM 
        FilteredOrders fo
    FULL OUTER JOIN 
        SupplierDetails sd ON fo.o_orderkey = sd.part_count
)
SELECT 
    c.o_orderkey,
    c.c_name,
    SUM(c.total_revenue) AS total_revenue,
    AVG(CASE WHEN c.part_count IS NOT NULL THEN c.part_count ELSE 0 END) AS avg_parts_provided
FROM 
    CombinedData c
GROUP BY 
    c.o_orderkey, c.c_name
HAVING 
    SUM(c.total_revenue) > 1000 AND COUNT(c.supplier_name) > 1
ORDER BY 
    total_revenue DESC
LIMIT 5;
