WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
    AND 
        p.p_size BETWEEN 18 AND 25
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Completed'
            WHEN o.o_orderstatus IS NULL THEN 'Unknown'
            ELSE 'Pending' 
        END AS order_status
    FROM 
        orders o
    WHERE 
        o.o_orderdate < cast('1998-10-01' as date)
    AND 
        o.o_totalprice IS NOT NULL
),
SubqueryWithJoin AS (
    SELECT 
        fo.o_orderkey, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        fo.order_status
    FROM 
        FilteredOrders fo
    JOIN 
        lineitem li ON fo.o_orderkey = li.l_orderkey
    GROUP BY 
        fo.o_orderkey, fo.order_status
)
SELECT 
    r.r_name, 
    COALESCE(SUM(s.s_acctbal), 0) AS total_acctbal,
    AVG(s.s_acctbal) AS avg_acctbal,
    COUNT(DISTINCT fo.o_orderkey) AS total_orders,
    CASE 
        WHEN SUM(s.s_acctbal) > 100000 THEN 'High Value Region'
        ELSE 'Standard Region' 
    END AS region_value
FROM 
    RankedSuppliers s
FULL OUTER JOIN 
    nation n ON s.s_suppkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SubqueryWithJoin fo ON s.s_suppkey = fo.o_orderkey
WHERE 
    r.r_comment IS NOT NULL 
    AND (r.r_name LIKE 'South%' OR s.s_name IS NULL)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT fo.o_orderkey) > 0
ORDER BY 
    total_acctbal DESC, r.r_name
LIMIT 5 OFFSET 1;