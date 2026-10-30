WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    INNER JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_regionkey,
        COUNT(rs.s_suppkey) AS supplier_count
    FROM 
        region r
    LEFT JOIN 
        RankedSuppliers rs ON (r.r_regionkey = rs.s_suppkey) AND rs.rank <= 3
    GROUP BY 
        r.r_regionkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        CASE 
            WHEN o.o_totalprice IS NULL THEN 0 
            ELSE o.o_totalprice / NULLIF(COUNT(DISTINCT l.l_orderkey), 0) 
        END AS price_per_order
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
RegionNation AS (
    SELECT 
        r.r_regionkey,
        n.n_nationkey,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        r.r_regionkey, n.n_nationkey
)
SELECT 
    r.r_name,
    MAX(TopSuppliers.supplier_count) AS max_suppliers,
    AVG(HighValueOrders.price_per_order) AS avg_price_per_order,
    COALESCE(SUM(c.customer_count), 0) AS total_customers
FROM 
    region r
LEFT JOIN 
    TopSuppliers ON r.r_regionkey = TopSuppliers.r_regionkey
LEFT JOIN 
    HighValueOrders ON r.r_regionkey = HighValueOrders.o_orderkey
LEFT JOIN 
    RegionNation c ON r.r_regionkey = c.r_regionkey
GROUP BY 
    r.r_name
HAVING 
    MAX(TopSuppliers.supplier_count) IS NOT NULL 
    AND AVG(HighValueOrders.price_per_order) > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'F')
ORDER BY 
    total_customers DESC;
