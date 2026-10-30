WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS supplier_rank,
        p.p_type
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomersWithHighVolume AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 5 AND SUM(o.o_totalprice) > 1000
),
SubOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        COUNT(*) > 1
),
FilteredRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name
    FROM 
        region r
    WHERE 
        r.r_comment IS NOT NULL 
        AND LENGTH(r.r_comment) > 50
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_acctbal,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    r.r_name AS region_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_discounted_value,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 10 THEN 'Frequent Shopper'
        ELSE 'Occasional Buyer' 
    END AS customer_type
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    RankedSuppliers s ON l.l_suppkey = s.s_suppkey AND s.supplier_rank = 1
JOIN 
    CustomersWithHighVolume cv ON c.c_custkey = cv.c_custkey
JOIN 
    FilteredRegions r ON c.c_nationkey = r.r_regionkey
WHERE 
    o.o_orderstatus IN ('F', 'O')
GROUP BY 
    c.c_custkey, c.c_name, c.c_acctbal, s.s_name, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 500
ORDER BY 
    total_discounted_value DESC NULLS LAST;
