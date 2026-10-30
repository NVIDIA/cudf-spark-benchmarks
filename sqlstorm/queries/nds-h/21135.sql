WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), OverlappingOrders AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 1
), SupplierAvailability AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty - COALESCE((SELECT SUM(l.l_quantity)
                                    FROM lineitem l
                                    WHERE l.l_partkey = p.p_partkey), 0) AS available_stock
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_supplycost / NULLIF(ps.ps_availqty, 0) < 10 
)
SELECT 
    r.r_name,
    rs.s_name, 
    COALESCE(oa.total_spent, 0) AS total_customer_spend,
    sa.available_stock,
    CASE 
        WHEN sa.available_stock IS NULL THEN 'Out of Stock'
        WHEN sa.available_stock < 50 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM 
    RankedSuppliers rs
LEFT JOIN 
    region r ON rs.rnk = 1
LEFT JOIN 
    OverlappingOrders oa ON rs.s_suppkey = oa.o_custkey
LEFT JOIN 
    SupplierAvailability sa ON rs.s_suppkey = sa.p_partkey
WHERE 
    rs.s_acctbal BETWEEN 1000 AND 5000
ORDER BY 
    r.r_name ASC, total_customer_spend DESC;