
WITH SupplierData AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_by_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
PartSummary AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supply_count,
        AVG(ps.ps_supplycost) AS average_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '3 month'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT sd.s_suppkey) AS supplier_count,
    COALESCE(SUM(ps.supply_count), 0) AS total_parts_supplied,
    COALESCE(MAX(o.total_revenue), 0) AS max_order_revenue,
    AVG(o.total_revenue) AS avg_order_revenue,
    CASE 
        WHEN COUNT(ps.p_partkey) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS supplier_status
FROM 
    SupplierData sd
FULL OUTER JOIN 
    PartSummary ps ON sd.s_suppkey = ps.p_partkey
LEFT JOIN 
    RecentOrders o ON sd.s_suppkey = o.o_custkey
JOIN 
    nation n ON sd.nation_name = n.n_name
WHERE 
    sd.rank_by_acctbal = 1
GROUP BY 
    n.n_name
HAVING 
    SUM(ps.average_supplycost) IS NOT NULL
    AND COUNT(DISTINCT sd.s_suppkey) > 0
ORDER BY 
    n.n_name;
