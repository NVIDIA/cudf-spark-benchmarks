
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o 
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-01-01'
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (
            SELECT AVG(total_supply_value)
            FROM (
                SELECT 
                    SUM(ps_supplycost * ps_availqty) AS total_supply_value
                FROM 
                    partsupp
                GROUP BY 
                    ps_suppkey
            ) AS avg_supply
        )
),
QualifiedNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name
    FROM 
        nation n 
    WHERE 
        EXISTS (
            SELECT 1 
            FROM supplier s 
            WHERE s.s_nationkey = n.n_nationkey 
            AND s.s_acctbal > (
                SELECT 
                    AVG(s2.s_acctbal) 
                FROM 
                    supplier s2 
                WHERE 
                    s2.s_comment IS NOT NULL
            )
        )
)
SELECT 
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers
FROM 
    RankedOrders o
FULL OUTER JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN QualifiedNations n ON s.s_nationkey = n.n_nationkey
WHERE 
    (o.o_orderdate IS NOT NULL AND (s.s_name NOT LIKE '%obsolete%'))
    OR (o.o_orderdate IS NULL AND l.l_returnflag = 'R')
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_revenue) FROM (
        SELECT 
            SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
        FROM 
            lineitem l 
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey 
        GROUP BY 
            o.o_orderkey
    ) AS revenue_summary)
ORDER BY 
    total_orders DESC;
