WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date,
        MIN(o.o_orderdate) AS first_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(CASE WHEN ps.ps_supplycost IS NULL THEN 0 ELSE ps.ps_supplycost END) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        COALESCE(pa.total_available, 0) AS available_qty
    FROM 
        part p
    LEFT JOIN 
        PartAvailability pa ON p.p_partkey = pa.ps_partkey
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice * 1.1) 
            FROM part p2
            WHERE p2.p_size BETWEEN 5 AND 10
        )
)
SELECT 
    c.c_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(cs.last_order_date) AS latest_order_date,
    COUNT(DISTINCT hp.p_partkey) FILTER (WHERE hp.available_qty > 0) AS available_parts_count,
    CASE 
        WHEN cs.total_spent > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    CustomerOrderStats cs ON c.c_custkey = cs.c_custkey
LEFT JOIN 
    HighValueParts hp ON l.l_partkey = hp.p_partkey
WHERE 
    c.c_acctbal IS NOT NULL AND 
    (c.c_mktsegment = 'BUILDING' OR c.c_mktsegment IS NULL)
GROUP BY 
    c.c_name, cs.total_spent
HAVING 
    (SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000 OR MAX(cs.last_order_date) > cast('1998-10-01' as date) - INTERVAL '30 days')
ORDER BY 
    customer_status DESC, total_revenue DESC;