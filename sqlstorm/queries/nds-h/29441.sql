WITH RegionStats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(CASE WHEN s.s_acctbal > 10000 THEN 1 ELSE 0 END) AS wealthy_suppliers_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
PartMetrics AS (
    SELECT 
        p.p_mfgr,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        AVG(p.p_retailprice) AS avg_retail_price,
        MAX(LENGTH(p.p_comment)) AS max_comment_length
    FROM 
        part p
    GROUP BY 
        p.p_mfgr
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    rs.region_name,
    rs.nation_count,
    rs.wealthy_suppliers_count,
    pm.p_mfgr,
    pm.part_count,
    pm.avg_retail_price,
    pm.max_comment_length,
    co.c_name,
    co.total_spent,
    co.order_count
FROM 
    RegionStats rs
JOIN 
    PartMetrics pm ON pm.part_count > 10
JOIN 
    CustomerOrders co ON co.total_spent > 5000
ORDER BY 
    rs.region_name, pm.avg_retail_price DESC, co.total_spent DESC;
