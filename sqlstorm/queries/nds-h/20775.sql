
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
RegionSummary AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
)

SELECT 
    r.r_name AS region_name,
    rs.s_name AS top_supplier,
    cs.c_name AS top_customer,
    COALESCE(rs.total_cost, 0) AS supplier_total_cost,
    COALESCE(cs.total_orders, 0) AS customer_total_orders,
    CASE 
        WHEN rs.rnk = 1 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS supplier_status,
    NULLIF(cs.order_count, 0) AS non_zero_order_count
FROM 
    RegionSummary r
FULL OUTER JOIN 
    RankedSuppliers rs ON r.nation_count = 1
FULL OUTER JOIN 
    CustomerOrders cs ON rs.s_suppkey = cs.c_custkey
WHERE 
    r.nation_count IS NOT NULL OR rs.rnk IS NOT NULL
ORDER BY 
    r.r_name, rs.total_cost DESC, cs.total_orders DESC;
