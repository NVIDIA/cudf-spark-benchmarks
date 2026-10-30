WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS supp_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
RegionInfo AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(COALESCE(ss.total_available, 0)) AS total_inventory
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        SupplierSummary ss ON n.n_nationkey = ss.s_suppkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 100
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ri.r_name AS region_name,
    ri.nation_count,
    ri.total_inventory,
    co.c_name AS customer_name,
    co.order_count,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        ELSE CONCAT('Spent: $', CAST(co.total_spent AS STRING))
    END AS spending_summary
FROM 
    RegionInfo ri
LEFT JOIN 
    CustomerOrders co ON ri.nation_count > 2
ORDER BY 
    ri.total_inventory DESC, co.order_count DESC
LIMIT 10;
