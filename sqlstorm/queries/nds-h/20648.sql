WITH  supplier_product_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT l.l_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
), 
region_nation_summary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        COALESCE(SUM(s.s_acctbal), 0) AS total_supplier_balance
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)

SELECT 
    rns.r_name,
    rns.nation_count,
    rns.total_supplier_balance,
    spp.s_name,
    spp.total_avail_qty,
    spp.avg_supply_cost,
    spp.total_orders,
    CASE 
        WHEN spp.total_orders IS NULL THEN 'No orders'
        WHEN spp.total_orders > 100 THEN 'High Volume Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_category,
    ROW_NUMBER() OVER (PARTITION BY rns.r_name ORDER BY spp.avg_supply_cost DESC) AS row_num
FROM 
    region_nation_summary rns
JOIN 
    supplier_product_summary spp ON spp.s_suppkey IN (
        SELECT DISTINCT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem li ON ps.ps_partkey = li.l_partkey
        WHERE li.l_discount > 0.1
    ) OR spp.total_orders > (SELECT AVG(total_orders) FROM supplier_product_summary)
WHERE 
    rns.total_supplier_balance IS NOT NULL
    AND rns.nation_count > 1
ORDER BY 
    rns.r_name, spp.avg_supply_cost DESC;
