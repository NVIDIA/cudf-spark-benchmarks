WITH RecursiveCTE AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        part AS p
    JOIN 
        partsupp AS ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), FilteredCTE AS (
    SELECT 
        r.r_name,
        n.n_name,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        region AS r
    JOIN 
        nation AS n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier AS s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem AS l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders AS o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer AS c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND (l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' OR l.l_commitdate IS NULL)
    GROUP BY 
        r.r_name, n.n_name, c.c_name, o.o_orderkey
), FinalResults AS (
    SELECT 
        f.r_name,
        f.n_name,
        f.c_name,
        f.o_orderkey,
        f.net_revenue,
        COALESCE(rc.total_cost, 0) AS supplier_total_cost
    FROM 
        FilteredCTE AS f
    LEFT JOIN 
        RecursiveCTE AS rc ON f.o_orderkey = rc.p_partkey
    WHERE 
        f.net_revenue > (SELECT AVG(net_revenue) FROM FilteredCTE) 
        OR f.n_name LIKE 'A%'
)
SELECT 
    fr.n_name,
    fr.c_name,
    fr.o_orderkey,
    fr.net_revenue,
    CASE 
        WHEN fr.supplier_total_cost > 0 THEN ROUND(fr.net_revenue / fr.supplier_total_cost, 4)
        ELSE NULL
    END AS revenue_to_cost_ratio
FROM 
    FinalResults AS fr
ORDER BY 
    fr.net_revenue DESC
LIMIT 10;