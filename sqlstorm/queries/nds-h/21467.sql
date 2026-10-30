
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS parts_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 0
),
NationalStats AS (
    SELECT 
        n.n_nationkey,
        COALESCE(SUM(o.total_revenue), 0) AS national_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
    LEFT JOIN 
        RankedOrders o ON n.n_nationkey IN (
            SELECT DISTINCT s.s_nationkey 
            FROM supplier s 
            WHERE s.s_suppkey IN (
                SELECT ps.ps_suppkey 
                FROM partsupp ps 
                WHERE ps.ps_availqty IS NOT NULL
            )
        )
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_name,
    ns.national_revenue,
    ns.order_count,
    ns.national_revenue / NULLIF(ns.order_count, 0) AS average_revenue_per_order,
    CASE 
        WHEN ns.national_revenue > 100000 THEN 'High Revenue'
        WHEN ns.national_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    NationalStats ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    ns.national_revenue IS NOT NULL AND 
    (r.r_name LIKE '%East%' OR r.r_name LIKE '%West%')
ORDER BY 
    average_revenue_per_order DESC, 
    r.r_name;
