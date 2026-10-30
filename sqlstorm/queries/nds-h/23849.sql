
WITH RegionStats AS (
    SELECT 
        r.r_regionkey, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        MAX(s.s_acctbal) AS max_supplier_acctbal,
        SUM(COALESCE(s.s_acctbal, 0)) AS total_supplier_acctbal
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS row_num
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        STRING_AGG(s.s_name, ', ') AS supplier_names
    FROM 
        partsupp ps
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey, 
    p.p_name,
    p.p_retailprice,
    COALESCE(cs.total_spent, 0) AS total_customer_spending,
    COALESCE(rs.nation_count, 0) AS region_nation_count,
    COALESCE(sps.total_avail_qty, 0) AS total_supplier_avail_qty,
    CASE 
        WHEN cs.order_count > 5 THEN 'High Spender'
        WHEN cs.order_count BETWEEN 3 AND 5 THEN 'Medium Spender'
        ELSE 'Low Spender' 
    END AS spending_category,
    CASE 
        WHEN EXISTS (SELECT 1 FROM orders o WHERE o.o_orderstatus = 'F' AND o.o_custkey = cs.c_custkey) 
        THEN 'Has Frequent Orders' 
        ELSE 'No Frequent Orders' 
    END AS order_status,
    LAG(p.p_retailprice) OVER (ORDER BY p.p_partkey) AS previous_part_price,
    CONCAT_WS(' | ', 
        COALESCE(CAST(rs.nation_count AS STRING), '0'), 
        COALESCE(sps.supplier_names, 'No Suppliers')
    ) AS combined_info
FROM 
    part p
LEFT JOIN 
    CustomerOrderStats cs ON p.p_partkey = cs.c_custkey
LEFT JOIN 
    RegionStats rs ON rs.nation_count IS NOT NULL
LEFT JOIN 
    SupplierPartStats sps ON sps.ps_partkey = p.p_partkey
WHERE 
    (p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) OR NULLIF(cs.order_count, 0) IS NOT NULL)
    AND (sps.total_avail_qty < 100 OR sps.supplier_count = 0)
ORDER BY 
    p.p_partkey;
