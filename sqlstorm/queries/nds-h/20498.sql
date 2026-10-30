
WITH  SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_cost,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerMetrics AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        (SELECT COUNT(DISTINCT s.s_suppkey) 
         FROM supplier s 
         WHERE s.s_nationkey = n.n_nationkey) AS supplier_count
    FROM 
        nation n
    WHERE 
        n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
)

SELECT 
    ns.n_name AS nation_name,
    COALESCE(ss.total_parts, 0) AS supplier_parts_count,
    COALESCE(ss.total_cost, 0.00) AS supplier_total_cost,
    COALESCE(cm.order_count, 0) AS customer_order_count,
    COALESCE(cm.total_spent, 0.00) AS customer_total_spent,
    CASE 
        WHEN ns.supplier_count < 5 THEN 'Few Suppliers'
        WHEN ns.supplier_count BETWEEN 5 AND 10 THEN 'Moderate Suppliers'
        ELSE 'Many Suppliers'
    END AS supplier_category
FROM 
    FilteredNations ns
LEFT JOIN 
    SupplierStats ss ON ss.total_parts > 0
LEFT JOIN 
    CustomerMetrics cm ON cm.rank_within_nation = 1
ORDER BY 
    supplier_category DESC, customer_total_spent DESC;
